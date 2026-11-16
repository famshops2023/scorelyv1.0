-- ============================================================
-- Match lifecycle: pending -> live -> completed
--
-- Canonical values in public.pending_matches.status are:
--   pending | live | completed
--
-- This migration:
--   1. Ensures the lifecycle columns exist.
--   2. Normalises legacy status values.
--   3. Backfills creator / scorer / player association columns.
--   4. Replaces the permissive pending_matches RLS policies with
--      association-based access (no more "everyone can read live rows").
--   5. Replaces the scorer handover RPCs with atomic versions that also
--      update pending_matches and never leave two active scorers.
-- ============================================================

-- ------------------------------------------------------------
-- 1. Table + columns
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.pending_matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    status TEXT NOT NULL DEFAULT 'pending',
    match_data JSONB,
    live_score_data JSONB,
    created_by_profile_id UUID,
    active_scorer_id UUID,
    player_profile_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
    result_summary TEXT,
    winner TEXT,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.pending_matches
    ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending',
    ADD COLUMN IF NOT EXISTS match_data JSONB,
    ADD COLUMN IF NOT EXISTS live_score_data JSONB,
    ADD COLUMN IF NOT EXISTS created_by_profile_id UUID,
    ADD COLUMN IF NOT EXISTS active_scorer_id UUID,
    ADD COLUMN IF NOT EXISTS player_profile_ids JSONB DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS result_summary TEXT,
    ADD COLUMN IF NOT EXISTS winner TEXT,
    ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- ------------------------------------------------------------
-- 2. Normalise legacy statuses
-- ------------------------------------------------------------
UPDATE public.pending_matches
SET status = lower(trim(status))
WHERE status IS NOT NULL AND status <> lower(trim(status));

UPDATE public.pending_matches
SET status = 'pending'
WHERE lower(coalesce(status, '')) IN (
    '', 'draft', 'created', 'scheduled', 'waiting_for_team_b',
    'waiting_for_squad', 'ready_for_toss', 'setup'
);

UPDATE public.pending_matches
SET status = 'live'
WHERE lower(coalesce(status, '')) IN ('in_progress', 'scoring', 'started');

UPDATE public.pending_matches
SET status = 'completed'
WHERE lower(coalesce(status, '')) IN ('finished', 'complete', 'abandoned');

-- Anything else unknown becomes pending rather than accidentally live.
UPDATE public.pending_matches
SET status = 'pending'
WHERE status IS NULL OR lower(status) NOT IN ('pending', 'live', 'completed');

-- Every row is normalised by now, so the invariant can be enforced.
ALTER TABLE public.pending_matches
    ALTER COLUMN status SET DEFAULT 'pending',
    ALTER COLUMN status SET NOT NULL;

-- Re-create the constraint even when an older definition exists (for example
-- one that still allowed 'abandoned' or the legacy setup statuses).
ALTER TABLE public.pending_matches
    DROP CONSTRAINT IF EXISTS pending_matches_status_check;

ALTER TABLE public.pending_matches
    ADD CONSTRAINT pending_matches_status_check
    CHECK (status IN ('pending', 'live', 'completed'));

-- ------------------------------------------------------------
-- 3. Backfill association columns
-- ------------------------------------------------------------
-- Legacy rows may hold non-UUID text in these fields, so only cast values
-- that actually look like UUIDs. `creator_id` from the live score blob is the
-- last-resort fallback for very old rows.
UPDATE public.pending_matches
SET created_by_profile_id = CASE
        WHEN (match_data->>'creatorProfileId') ~*
             '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
            THEN (match_data->>'creatorProfileId')::uuid
        WHEN (live_score_data->>'creator_id') ~*
             '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
            THEN (live_score_data->>'creator_id')::uuid
        ELSE NULL
    END
WHERE created_by_profile_id IS NULL
  AND (
        (match_data->>'creatorProfileId') ~*
            '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        OR (live_score_data->>'creator_id') ~*
            '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      );

UPDATE public.pending_matches
SET active_scorer_id = CASE
        WHEN (live_score_data->>'scorer_id') ~*
             '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
            THEN (live_score_data->>'scorer_id')::uuid
        WHEN (match_data->>'teamAScorerId') ~*
             '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
            THEN (match_data->>'teamAScorerId')::uuid
        ELSE NULL
    END
WHERE active_scorer_id IS NULL
  AND status IN ('live', 'completed')
  AND (
        (live_score_data->>'scorer_id') ~*
            '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        OR (match_data->>'teamAScorerId') ~*
            '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      );

UPDATE public.pending_matches
SET player_profile_ids = (
    SELECT COALESCE(jsonb_agg(DISTINCT pid), '[]'::jsonb)
    FROM (
        SELECT elem->>'profileId' AS pid
        FROM jsonb_array_elements(
            CASE
                WHEN jsonb_typeof(match_data->'teamAPlayers') = 'array'
                    THEN match_data->'teamAPlayers'
                ELSE '[]'::jsonb
            END
        ) AS elem
        UNION
        SELECT elem->>'profileId' AS pid
        FROM jsonb_array_elements(
            CASE
                WHEN jsonb_typeof(match_data->'teamBPlayers') = 'array'
                    THEN match_data->'teamBPlayers'
                ELSE '[]'::jsonb
            END
        ) AS elem
    ) AS ids
    WHERE pid IS NOT NULL AND pid <> ''
)
WHERE player_profile_ids IS NULL
   OR jsonb_typeof(player_profile_ids) <> 'array'
   OR jsonb_array_length(player_profile_ids) = 0;

CREATE INDEX IF NOT EXISTS idx_pending_matches_status
    ON public.pending_matches(status);
CREATE INDEX IF NOT EXISTS idx_pending_matches_creator
    ON public.pending_matches(created_by_profile_id);
CREATE INDEX IF NOT EXISTS idx_pending_matches_active_scorer
    ON public.pending_matches(active_scorer_id);
CREATE INDEX IF NOT EXISTS idx_pending_matches_player_ids
    ON public.pending_matches USING GIN (player_profile_ids);

-- ------------------------------------------------------------
-- 4. Association-based RLS
-- ------------------------------------------------------------
ALTER TABLE public.pending_matches ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pending_matches_select" ON public.pending_matches;
DROP POLICY IF EXISTS "pending_matches_insert" ON public.pending_matches;
DROP POLICY IF EXISTS "pending_matches_update" ON public.pending_matches;
DROP POLICY IF EXISTS "pending_matches_delete" ON public.pending_matches;

-- Read: creator, active scorer, or an associated signed-in player only.
-- Pending matches are never exposed to unrelated signed-in users.
CREATE POLICY "pending_matches_select" ON public.pending_matches
FOR SELECT TO authenticated
USING (
    created_by_profile_id = auth.uid()
    OR active_scorer_id = auth.uid()
    OR player_profile_ids @> to_jsonb(auth.uid()::text)
);

-- Insert: the creator, or the already-selected active scorer (needed because
-- the scorer's live updates use an upsert, which also evaluates this policy).
CREATE POLICY "pending_matches_insert" ON public.pending_matches
FOR INSERT TO authenticated
WITH CHECK (
    (created_by_profile_id = auth.uid() OR active_scorer_id = auth.uid())
    AND (
        active_scorer_id IS NULL
        OR active_scorer_id = auth.uid()
        OR player_profile_ids @> to_jsonb(active_scorer_id::text)
    )
);

-- Update: while pending the creator may edit setup; once live only the
-- single active scorer may write. This is what makes handover meaningful.
-- Completed rows are frozen for clients: `USING` evaluates the existing row,
-- so the live -> completed transition still succeeds while later writes to a
-- completed match update zero rows.
CREATE POLICY "pending_matches_update" ON public.pending_matches
FOR UPDATE TO authenticated
USING (
    status <> 'completed'
    AND (
        (status = 'pending' AND created_by_profile_id = auth.uid())
        OR active_scorer_id = auth.uid()
    )
)
WITH CHECK (
    (status = 'pending' AND created_by_profile_id = auth.uid())
    OR active_scorer_id = auth.uid()
);

CREATE POLICY "pending_matches_delete" ON public.pending_matches
FOR DELETE TO authenticated
USING (created_by_profile_id = auth.uid());

-- ------------------------------------------------------------
-- 5. Atomic accept / decline RPCs
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.accept_scorer_assignment(
    p_request_id UUID,
    p_user_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_req RECORD;
    v_pm RECORD;
    v_is_authorized BOOLEAN := FALSE;
    v_previous_scorer UUID;
    v_match_found BOOLEAN := FALSE;
    v_match_table TEXT := 'pending_matches';
    v_caller UUID := auth.uid();
BEGIN
    -- Never trust a client-supplied identity: only the authenticated caller
    -- can accept a handover.
    IF v_caller IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized user');
    END IF;
    IF p_user_id IS NOT NULL AND p_user_id <> v_caller THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized user');
    END IF;

    -- Discover the match without locking the request first: all accepts for
    -- the same match must take locks in the same order (match, then request)
    -- to avoid deadlocks when competing requests are revoked.
    SELECT * INTO v_req
    FROM public.scorer_assignment_requests
    WHERE id = p_request_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Request not found');
    END IF;

    SELECT * INTO v_pm
    FROM public.pending_matches
    WHERE id = v_req.match_id
    FOR UPDATE;

    IF FOUND THEN
        v_match_found := TRUE;
        v_match_table := 'pending_matches';
    ELSE
        -- Fall back to the synced matches table (legacy rows).
        SELECT * INTO v_pm
        FROM public.matches
        WHERE id = v_req.match_id
        FOR UPDATE;
        IF FOUND THEN
            v_match_found := TRUE;
            v_match_table := 'matches';
        END IF;
    END IF;

    -- Now lock and re-read the request. A competing accept may have completed
    -- while we waited for the match lock, in which case this request has been
    -- cancelled and must not steal the active scorer role.
    SELECT * INTO v_req
    FROM public.scorer_assignment_requests
    WHERE id = p_request_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Request not found');
    END IF;

    IF v_req.status <> 'pending' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Request already ' || v_req.status);
    END IF;

    IF NOW() > v_req.expires_at THEN
        UPDATE public.scorer_assignment_requests
        SET status = 'expired', responded_at = NOW()
        WHERE id = p_request_id;

        RETURN jsonb_build_object('success', false, 'error', 'Request has expired');
    END IF;

    -- Authorisation: direct profile id, players row, or email match.
    IF v_req.requested_scorer_user_id = v_caller THEN
        v_is_authorized := TRUE;
    ELSIF EXISTS (
        SELECT 1 FROM public.players
        WHERE id = v_req.requested_scorer_user_id
          AND profile_id = v_caller
    ) THEN
        v_is_authorized := TRUE;
    ELSIF v_req.requested_scorer_email IS NOT NULL AND EXISTS (
        SELECT 1 FROM auth.users
        WHERE id = v_caller
          AND email = v_req.requested_scorer_email
    ) THEN
        v_is_authorized := TRUE;
    END IF;

    IF NOT v_is_authorized THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized user');
    END IF;

    IF v_match_found THEN
        IF v_match_table = 'pending_matches' AND v_pm.status = 'completed' THEN
            RETURN jsonb_build_object('success', false, 'error', 'Match already completed');
        END IF;

        v_previous_scorer := v_pm.active_scorer_id;

        IF v_match_table = 'pending_matches' THEN
            UPDATE public.pending_matches
            SET active_scorer_id = v_caller,
                live_score_data = jsonb_set(
                    COALESCE(live_score_data, '{}'::jsonb),
                    '{scorer_id}',
                    to_jsonb(v_caller::text),
                    true
                ),
                updated_at = NOW()
            WHERE id = v_req.match_id;
        ELSE
            UPDATE public.matches
            SET active_scorer_id = v_caller, updated_at = NOW()
            WHERE id = v_req.match_id;
        END IF;
    END IF;

    IF v_req.innings_id IS NOT NULL THEN
        UPDATE public.innings
        SET active_scorer_id = v_caller, updated_at = NOW()
        WHERE id = v_req.innings_id;
    END IF;

    -- Accept this request and revoke any competing pending requests.
    UPDATE public.scorer_assignment_requests
    SET status = 'accepted', responded_at = NOW(), version = version + 1
    WHERE id = p_request_id;

    UPDATE public.scorer_assignment_requests
    SET status = 'cancelled', responded_at = NOW()
    WHERE match_id = v_req.match_id
      AND id <> p_request_id
      AND status = 'pending';

    RETURN jsonb_build_object(
        'success', true,
        'request_id', p_request_id,
        'match_id', v_req.match_id,
        'innings_id', v_req.innings_id,
        'previous_scorer_id', v_previous_scorer,
        'new_scorer_id', v_caller
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.decline_scorer_assignment(
    p_request_id UUID,
    p_user_id UUID,
    p_reason TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_req RECORD;
    v_is_authorized BOOLEAN := FALSE;
    v_caller UUID := auth.uid();
BEGIN
    IF v_caller IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized user');
    END IF;
    IF p_user_id IS NOT NULL AND p_user_id <> v_caller THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized user');
    END IF;

    SELECT * INTO v_req
    FROM public.scorer_assignment_requests
    WHERE id = p_request_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Request not found');
    END IF;

    IF v_req.status <> 'pending' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Request already ' || v_req.status);
    END IF;

    IF v_req.requested_scorer_user_id = v_caller THEN
        v_is_authorized := TRUE;
    ELSIF EXISTS (
        SELECT 1 FROM public.players
        WHERE id = v_req.requested_scorer_user_id
          AND profile_id = v_caller
    ) THEN
        v_is_authorized := TRUE;
    ELSIF v_req.requested_scorer_email IS NOT NULL AND EXISTS (
        SELECT 1 FROM auth.users
        WHERE id = v_caller
          AND email = v_req.requested_scorer_email
    ) THEN
        v_is_authorized := TRUE;
    END IF;

    IF NOT v_is_authorized THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized user');
    END IF;

    -- Declining never touches the active scorer or the match state.
    UPDATE public.scorer_assignment_requests
    SET status = 'declined',
        responded_at = NOW(),
        response_reason = COALESCE(p_reason, 'Declined by recipient'),
        version = version + 1
    WHERE id = p_request_id;

    RETURN jsonb_build_object(
        'success', true,
        'request_id', p_request_id,
        'match_id', v_req.match_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
