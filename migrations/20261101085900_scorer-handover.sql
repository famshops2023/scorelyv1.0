-- Active scorer tracking on matches and innings
ALTER TABLE public.matches 
ADD COLUMN IF NOT EXISTS active_scorer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

ALTER TABLE public.innings 
ADD COLUMN IF NOT EXISTS active_scorer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

-- Scorer assignment request state
CREATE TABLE IF NOT EXISTS public.scorer_assignment_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
    innings_id UUID REFERENCES public.innings(id) ON DELETE SET NULL,
    requested_by_user_id UUID NOT NULL REFERENCES public.profiles(id),
    requested_scorer_user_id UUID NOT NULL REFERENCES public.profiles(id),
    current_scorer_user_id UUID NOT NULL REFERENCES public.profiles(id),
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'accepted', 'declined', 'cancelled', 'expired')) DEFAULT 'pending',
    response_reason TEXT,
    notification_id VARCHAR(255),
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    responded_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '10 minutes')
);

CREATE INDEX IF NOT EXISTS idx_scorer_req_match ON public.scorer_assignment_requests(match_id);
CREATE INDEX IF NOT EXISTS idx_scorer_req_recipient ON public.scorer_assignment_requests(requested_scorer_user_id, status);
CREATE INDEX IF NOT EXISTS idx_scorer_req_requester ON public.scorer_assignment_requests(requested_by_user_id, status);

-- Enable RLS and permissive policies for scorer requests
ALTER TABLE public.scorer_assignment_requests ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'scorer_assignment_requests' AND policyname = 'Allow select scorer_assignment_requests'
    ) THEN
        CREATE POLICY "Allow select scorer_assignment_requests" ON public.scorer_assignment_requests FOR SELECT USING (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'scorer_assignment_requests' AND policyname = 'Allow insert scorer_assignment_requests'
    ) THEN
        CREATE POLICY "Allow insert scorer_assignment_requests" ON public.scorer_assignment_requests FOR INSERT WITH CHECK (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'scorer_assignment_requests' AND policyname = 'Allow update scorer_assignment_requests'
    ) THEN
        CREATE POLICY "Allow update scorer_assignment_requests" ON public.scorer_assignment_requests FOR UPDATE USING (true);
    END IF;
END $$;

-- Atomic server-side acceptance function
CREATE OR REPLACE FUNCTION public.accept_scorer_assignment(
    p_request_id UUID,
    p_user_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_req RECORD;
BEGIN
    SELECT * INTO v_req 
    FROM public.scorer_assignment_requests
    WHERE id = p_request_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Request not found');
    END IF;

    IF v_req.status != 'pending' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Request already ' || v_req.status);
    END IF;

    IF NOW() > v_req.expires_at THEN
        UPDATE public.scorer_assignment_requests 
        SET status = 'expired', responded_at = NOW() 
        WHERE id = p_request_id;
        
        RETURN jsonb_build_object('success', false, 'error', 'Request has expired');
    END IF;

    IF v_req.requested_scorer_user_id != p_user_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized user');
    END IF;

    UPDATE public.scorer_assignment_requests
    SET status = 'accepted', responded_at = NOW(), version = version + 1
    WHERE id = p_request_id;

    UPDATE public.matches
    SET active_scorer_id = p_user_id, updated_at = NOW()
    WHERE id = v_req.match_id;

    IF v_req.innings_id IS NOT NULL THEN
        UPDATE public.innings
        SET active_scorer_id = p_user_id, updated_at = NOW()
        WHERE id = v_req.innings_id;
    END IF;

    UPDATE public.scorer_assignment_requests
    SET status = 'cancelled', responded_at = NOW()
    WHERE match_id = v_req.match_id AND id != p_request_id AND status = 'pending';

    RETURN jsonb_build_object('success', true, 'match_id', v_req.match_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
