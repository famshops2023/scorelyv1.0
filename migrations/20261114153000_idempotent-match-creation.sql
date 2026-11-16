-- ============================================================
-- Migration: 20261114153000_idempotent-match-creation.sql
-- Description: Adds creation_request_id column, unique constraint, and
--              atomic create_or_get_pending_match RPC to public.pending_matches.
-- ============================================================

-- 1. Add creation_request_id column to pending_matches
ALTER TABLE public.pending_matches
ADD COLUMN IF NOT EXISTS creation_request_id UUID;

-- 2. Partial unique index to enforce idempotency on creation_request_id
CREATE UNIQUE INDEX IF NOT EXISTS idx_pending_matches_creation_request_id
ON public.pending_matches (creation_request_id)
WHERE creation_request_id IS NOT NULL;

-- 3. Atomic create-or-get function for idempotent match creation
CREATE OR REPLACE FUNCTION public.create_or_get_pending_match(
    p_creation_request_id UUID,
    p_match_id UUID,
    p_creator_id UUID,
    p_match_data JSONB,
    p_status TEXT DEFAULT 'pending'
)
RETURNS JSONB AS $$
DECLARE
    v_existing RECORD;
    v_inserted RECORD;
    v_caller UUID := auth.uid();
BEGIN
    -- If caller is authenticated, verify creator ID matches
    IF v_caller IS NOT NULL AND p_creator_id IS NOT NULL AND p_creator_id <> v_caller THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized creator ID');
    END IF;

    -- 1. Idempotency check: see if a match with this creation_request_id already exists
    IF p_creation_request_id IS NOT NULL THEN
        SELECT * INTO v_existing
        FROM public.pending_matches
        WHERE creation_request_id = p_creation_request_id;

        IF FOUND THEN
            RETURN jsonb_build_object(
                'success', true,
                'is_duplicate', true,
                'match_id', v_existing.id,
                'status', v_existing.status,
                'match_data', v_existing.match_data
            );
        END IF;
    END IF;

    -- 2. Check by match_id directly
    IF p_match_id IS NOT NULL THEN
        SELECT * INTO v_existing
        FROM public.pending_matches
        WHERE id = p_match_id;

        IF FOUND THEN
            RETURN jsonb_build_object(
                'success', true,
                'is_duplicate', true,
                'match_id', v_existing.id,
                'status', v_existing.status,
                'match_data', v_existing.match_data
            );
        END IF;
    END IF;

    -- 3. Atomic insert of new pending match
    INSERT INTO public.pending_matches (
        id,
        creation_request_id,
        created_by_profile_id,
        match_data,
        status,
        created_at,
        updated_at
    ) VALUES (
        COALESCE(p_match_id, uuid_generate_v4()),
        p_creation_request_id,
        COALESCE(p_creator_id, v_caller),
        p_match_data,
        COALESCE(p_status, 'pending'),
        NOW(),
        NOW()
    )
    RETURNING * INTO v_inserted;

    RETURN jsonb_build_object(
        'success', true,
        'is_duplicate', false,
        'match_id', v_inserted.id,
        'status', v_inserted.status,
        'match_data', v_inserted.match_data
    );
EXCEPTION
    WHEN unique_violation THEN
        -- Handle concurrent race condition gracefully
        IF p_creation_request_id IS NOT NULL THEN
            SELECT * INTO v_existing
            FROM public.pending_matches
            WHERE creation_request_id = p_creation_request_id;

            IF FOUND THEN
                RETURN jsonb_build_object(
                    'success', true,
                    'is_duplicate', true,
                    'match_id', v_existing.id,
                    'status', v_existing.status,
                    'match_data', v_existing.match_data
                );
            END IF;
        END IF;

        RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 4. Support distinct 'abandoned' status in pending_matches (Point 15 Q7)
ALTER TABLE public.pending_matches
    DROP CONSTRAINT IF EXISTS pending_matches_status_check;

ALTER TABLE public.pending_matches
    ADD CONSTRAINT pending_matches_status_check
    CHECK (status IN ('pending', 'live', 'completed', 'abandoned'));

-- Freeze abandoned rows from client updates just like completed rows
DROP POLICY IF EXISTS "pending_matches_update" ON public.pending_matches;

CREATE POLICY "pending_matches_update" ON public.pending_matches
FOR UPDATE TO authenticated
USING (
    status NOT IN ('completed', 'abandoned')
    AND (
        (status = 'pending' AND created_by_profile_id = auth.uid())
        OR active_scorer_id = auth.uid()
    )
)
WITH CHECK (
    (status = 'pending' AND created_by_profile_id = auth.uid())
    OR active_scorer_id = auth.uid()
);

-- 5. Revoke anonymous access on scorer_assignment_requests (Point 15 Q14)
REVOKE ALL ON public.scorer_assignment_requests FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.scorer_assignment_requests TO authenticated;

-- 6. Purge completed and abandoned pending_matches older than 7 days (Option A)
-- This frees up database JSONB storage while preserving a safe 7-day recovery buffer.
CREATE OR REPLACE FUNCTION public.purge_old_completed_pending_matches(p_days_retention integer DEFAULT 7)
RETURNS integer AS $$
DECLARE
    v_deleted integer;
BEGIN
    DELETE FROM public.pending_matches
    WHERE status IN ('completed', 'abandoned')
      AND updated_at < (NOW() - (p_days_retention || ' days')::INTERVAL);

    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN v_deleted;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Allow authenticated callers and maintenance workers to execute the purge
GRANT EXECUTE ON FUNCTION public.purge_old_completed_pending_matches(integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.purge_old_completed_pending_matches(integer) TO anon;



