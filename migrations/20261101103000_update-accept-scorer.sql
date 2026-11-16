CREATE OR REPLACE FUNCTION public.accept_scorer_assignment(
    p_request_id UUID,
    p_user_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_req RECORD;
    v_is_authorized BOOLEAN := FALSE;
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

    -- Check authorization: direct match OR player row match OR email match
    IF v_req.requested_scorer_user_id = p_user_id THEN
        v_is_authorized := TRUE;
    ELSIF EXISTS (
        SELECT 1 FROM public.players 
        WHERE id = v_req.requested_scorer_user_id AND profile_id = p_user_id
    ) THEN
        v_is_authorized := TRUE;
    ELSIF v_req.requested_scorer_email IS NOT NULL AND EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = p_user_id AND email = v_req.requested_scorer_email
    ) THEN
        v_is_authorized := TRUE;
    END IF;

    IF NOT v_is_authorized THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized user');
    END IF;

    -- Update request status
    UPDATE public.scorer_assignment_requests
    SET status = 'accepted', responded_at = NOW(), version = version + 1
    WHERE id = p_request_id;

    -- Update match active scorer
    UPDATE public.matches
    SET active_scorer_id = p_user_id, updated_at = NOW()
    WHERE id = v_req.match_id;

    RETURN jsonb_build_object(
        'success', true,
        'request_id', p_request_id,
        'match_id', v_req.match_id,
        'innings_id', v_req.innings_id,
        'new_scorer_id', p_user_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
