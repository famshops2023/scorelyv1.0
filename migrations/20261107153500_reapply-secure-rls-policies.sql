-- Migration: 20261107153500_reapply-secure-rls-policies.sql
-- Description: Re-applies hardened RLS policies across all 10 tables in Scorely database.

-- Ensure player_profile_ids column exists on matches
ALTER TABLE public.matches ADD COLUMN IF NOT EXISTS player_profile_ids JSONB DEFAULT '[]'::jsonb;
CREATE INDEX IF NOT EXISTS idx_matches_player_profile_ids ON public.matches USING gin (player_profile_ids);

-- ============================================================
-- 1. DROP PERMISSIVE POLICIES
-- ============================================================
DROP POLICY IF EXISTS "profiles_select" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update" ON public.profiles;
DROP POLICY IF EXISTS "profiles_delete" ON public.profiles;

DROP POLICY IF EXISTS "teams_select" ON public.teams;
DROP POLICY IF EXISTS "teams_insert" ON public.teams;
DROP POLICY IF EXISTS "teams_update" ON public.teams;
DROP POLICY IF EXISTS "teams_delete" ON public.teams;

DROP POLICY IF EXISTS "players_select" ON public.players;
DROP POLICY IF EXISTS "players_insert" ON public.players;
DROP POLICY IF EXISTS "players_update" ON public.players;
DROP POLICY IF EXISTS "players_delete" ON public.players;

DROP POLICY IF EXISTS "matches_select" ON public.matches;
DROP POLICY IF EXISTS "matches_insert" ON public.matches;
DROP POLICY IF EXISTS "matches_update" ON public.matches;
DROP POLICY IF EXISTS "matches_delete" ON public.matches;

DROP POLICY IF EXISTS "innings_select" ON public.innings;
DROP POLICY IF EXISTS "innings_insert" ON public.innings;
DROP POLICY IF EXISTS "innings_update" ON public.innings;
DROP POLICY IF EXISTS "innings_delete" ON public.innings;

DROP POLICY IF EXISTS "balls_select" ON public.balls;
DROP POLICY IF EXISTS "balls_insert" ON public.balls;
DROP POLICY IF EXISTS "balls_update" ON public.balls;
DROP POLICY IF EXISTS "balls_delete" ON public.balls;

DROP POLICY IF EXISTS "ball_events_select" ON public.ball_events;
DROP POLICY IF EXISTS "ball_events_insert" ON public.ball_events;
DROP POLICY IF EXISTS "ball_events_update" ON public.ball_events;
DROP POLICY IF EXISTS "ball_events_delete" ON public.ball_events;

DROP POLICY IF EXISTS "player_match_stats_select" ON public.player_match_stats;
DROP POLICY IF EXISTS "player_match_stats_insert" ON public.player_match_stats;
DROP POLICY IF EXISTS "player_match_stats_update" ON public.player_match_stats;
DROP POLICY IF EXISTS "player_match_stats_delete" ON public.player_match_stats;

DROP POLICY IF EXISTS "scorer_assignment_requests_select" ON public.scorer_assignment_requests;
DROP POLICY IF EXISTS "scorer_assignment_requests_insert" ON public.scorer_assignment_requests;
DROP POLICY IF EXISTS "scorer_assignment_requests_update" ON public.scorer_assignment_requests;
DROP POLICY IF EXISTS "scorer_assignment_requests_delete" ON public.scorer_assignment_requests;

DROP POLICY IF EXISTS "pending_matches_select" ON public.pending_matches;
DROP POLICY IF EXISTS "pending_matches_insert" ON public.pending_matches;
DROP POLICY IF EXISTS "pending_matches_update" ON public.pending_matches;
DROP POLICY IF EXISTS "pending_matches_delete" ON public.pending_matches;

-- ============================================================
-- 2. TABLE 1: PROFILES
-- ============================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_select_own" ON public.profiles
FOR SELECT TO authenticated
USING (auth.uid() = id);

CREATE POLICY "profiles_insert_own" ON public.profiles
FOR INSERT TO authenticated
WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_own" ON public.profiles
FOR UPDATE TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_delete_own" ON public.profiles
FOR DELETE TO authenticated
USING (auth.uid() = id);

-- ============================================================
-- 3. TABLE 2: TEAMS
-- ============================================================
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;

CREATE POLICY "teams_select_public" ON public.teams
FOR SELECT TO public
USING (deleted_at IS NULL);

CREATE POLICY "teams_insert_authenticated" ON public.teams
FOR INSERT TO authenticated
WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "teams_update_owner_or_admin" ON public.teams
FOR UPDATE TO authenticated
USING (
    auth.uid() = owner_id
    OR EXISTS (
        SELECT 1 FROM public.players p
        WHERE p.team_id = teams.id 
          AND p.profile_id = auth.uid() 
          AND (p.is_admin = TRUE OR p.is_captain = TRUE)
    )
)
WITH CHECK (
    auth.uid() = owner_id
    OR EXISTS (
        SELECT 1 FROM public.players p
        WHERE p.team_id = teams.id 
          AND p.profile_id = auth.uid() 
          AND (p.is_admin = TRUE OR p.is_captain = TRUE)
    )
);

CREATE POLICY "teams_delete_owner" ON public.teams
FOR DELETE TO authenticated
USING (auth.uid() = owner_id);

-- ============================================================
-- 4. TABLE 3: PLAYERS
-- ============================================================
ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;

CREATE POLICY "players_select_public" ON public.players
FOR SELECT TO public
USING (deleted_at IS NULL);

CREATE POLICY "players_insert_authorized" ON public.players
FOR INSERT TO authenticated
WITH CHECK (
    (team_id IS NULL AND profile_id = auth.uid())
    OR (
        team_id IS NOT NULL AND (
            EXISTS (SELECT 1 FROM public.teams t WHERE t.id = players.team_id AND t.owner_id = auth.uid())
            OR EXISTS (SELECT 1 FROM public.players p WHERE p.team_id = players.team_id AND p.profile_id = auth.uid() AND (p.is_admin = TRUE OR p.is_captain = TRUE))
        )
    )
);

CREATE POLICY "players_update_authorized" ON public.players
FOR UPDATE TO authenticated
USING (
    profile_id = auth.uid()
    OR (
        team_id IS NOT NULL AND (
            EXISTS (SELECT 1 FROM public.teams t WHERE t.id = players.team_id AND t.owner_id = auth.uid())
            OR EXISTS (SELECT 1 FROM public.players p WHERE p.team_id = players.team_id AND p.profile_id = auth.uid() AND (p.is_admin = TRUE OR p.is_captain = TRUE))
        )
    )
)
WITH CHECK (
    profile_id = auth.uid()
    OR (
        team_id IS NOT NULL AND (
            EXISTS (SELECT 1 FROM public.teams t WHERE t.id = players.team_id AND t.owner_id = auth.uid())
            OR EXISTS (SELECT 1 FROM public.players p WHERE p.team_id = players.team_id AND p.profile_id = auth.uid() AND (p.is_admin = TRUE OR p.is_captain = TRUE))
        )
    )
);

CREATE POLICY "players_delete_authorized" ON public.players
FOR DELETE TO authenticated
USING (
    profile_id = auth.uid()
    OR (
        team_id IS NOT NULL AND (
            EXISTS (SELECT 1 FROM public.teams t WHERE t.id = players.team_id AND t.owner_id = auth.uid())
            OR EXISTS (SELECT 1 FROM public.players p WHERE p.team_id = players.team_id AND p.profile_id = auth.uid() AND (p.is_admin = TRUE OR p.is_captain = TRUE))
        )
    )
);

-- ============================================================
-- 5. TABLE 4: MATCHES
-- ============================================================
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "matches_select_public" ON public.matches
FOR SELECT TO public
USING (deleted_at IS NULL);

CREATE POLICY "matches_insert_authorized" ON public.matches
FOR INSERT TO authenticated
WITH CHECK (
    creator_id = auth.uid()
    OR active_scorer_id = auth.uid()
);

CREATE POLICY "matches_update_authorized" ON public.matches
FOR UPDATE TO authenticated
USING (
    creator_id = auth.uid()
    OR active_scorer_id = auth.uid()
)
WITH CHECK (
    creator_id = auth.uid()
    OR active_scorer_id = auth.uid()
);

CREATE POLICY "matches_delete_creator" ON public.matches
FOR DELETE TO authenticated
USING (creator_id = auth.uid());

-- ============================================================
-- 6. TABLE 5: INNINGS
-- ============================================================
ALTER TABLE public.innings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "innings_select_public" ON public.innings
FOR SELECT TO public
USING (true);

CREATE POLICY "innings_insert_scorer" ON public.innings
FOR INSERT TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.matches m
        WHERE m.id = innings.match_id
          AND (m.creator_id = auth.uid() OR m.active_scorer_id = auth.uid())
    )
);

CREATE POLICY "innings_update_scorer" ON public.innings
FOR UPDATE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.matches m
        WHERE m.id = innings.match_id
          AND (m.creator_id = auth.uid() OR m.active_scorer_id = auth.uid())
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.matches m
        WHERE m.id = innings.match_id
          AND (m.creator_id = auth.uid() OR m.active_scorer_id = auth.uid())
    )
);

CREATE POLICY "innings_delete_creator" ON public.innings
FOR DELETE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.matches m
        WHERE m.id = innings.match_id
          AND m.creator_id = auth.uid()
    )
);

-- ============================================================
-- 7. TABLE 6: BALLS
-- ============================================================
ALTER TABLE public.balls ENABLE ROW LEVEL SECURITY;

CREATE POLICY "balls_select_public" ON public.balls
FOR SELECT TO public
USING (true);

CREATE POLICY "balls_insert_scorer" ON public.balls
FOR INSERT TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.innings i
        JOIN public.matches m ON m.id = i.match_id
        WHERE i.id = balls.innings_id
          AND (m.creator_id = auth.uid() OR m.active_scorer_id = auth.uid())
    )
);

CREATE POLICY "balls_update_scorer" ON public.balls
FOR UPDATE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.innings i
        JOIN public.matches m ON m.id = i.match_id
        WHERE i.id = balls.innings_id
          AND (m.creator_id = auth.uid() OR m.active_scorer_id = auth.uid())
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.innings i
        JOIN public.matches m ON m.id = i.match_id
        WHERE i.id = balls.innings_id
          AND (m.creator_id = auth.uid() OR m.active_scorer_id = auth.uid())
    )
);

CREATE POLICY "balls_delete_scorer" ON public.balls
FOR DELETE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.innings i
        JOIN public.matches m ON m.id = i.match_id
        WHERE i.id = balls.innings_id
          AND (m.creator_id = auth.uid() OR m.active_scorer_id = auth.uid())
    )
);

-- ============================================================
-- 8. TABLE 7: BALL_EVENTS
-- ============================================================
ALTER TABLE public.ball_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ball_events_select_public" ON public.ball_events
FOR SELECT TO public
USING (true);

CREATE POLICY "ball_events_insert_scorer" ON public.ball_events
FOR INSERT TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.matches m
        WHERE m.id = ball_events.match_id
          AND (m.creator_id = auth.uid() OR m.active_scorer_id = auth.uid())
    )
);

CREATE POLICY "ball_events_update_scorer" ON public.ball_events
FOR UPDATE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.matches m
        WHERE m.id = ball_events.match_id
          AND (m.creator_id = auth.uid() OR m.active_scorer_id = auth.uid())
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.matches m
        WHERE m.id = ball_events.match_id
          AND (m.creator_id = auth.uid() OR m.active_scorer_id = auth.uid())
    )
);

CREATE POLICY "ball_events_delete_scorer" ON public.ball_events
FOR DELETE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.matches m
        WHERE m.id = ball_events.match_id
          AND (m.creator_id = auth.uid() OR m.active_scorer_id = auth.uid())
    )
);

-- ============================================================
-- 9. TABLE 8: PLAYER_MATCH_STATS
-- ============================================================
ALTER TABLE public.player_match_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "player_match_stats_select_public" ON public.player_match_stats
FOR SELECT TO public
USING (true);

CREATE POLICY "player_match_stats_insert_scorer" ON public.player_match_stats
FOR INSERT TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.matches m
        WHERE m.id = player_match_stats.match_id
          AND (m.creator_id = auth.uid() OR m.active_scorer_id = auth.uid())
    )
);

CREATE POLICY "player_match_stats_update_scorer" ON public.player_match_stats
FOR UPDATE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.matches m
        WHERE m.id = player_match_stats.match_id
          AND (m.creator_id = auth.uid() OR m.active_scorer_id = auth.uid())
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.matches m
        WHERE m.id = player_match_stats.match_id
          AND (m.creator_id = auth.uid() OR m.active_scorer_id = auth.uid())
    )
);

CREATE POLICY "player_match_stats_delete_scorer" ON public.player_match_stats
FOR DELETE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.matches m
        WHERE m.id = player_match_stats.match_id
          AND m.creator_id = auth.uid()
    )
);

-- ============================================================
-- 10. TABLE 9: SCORER_ASSIGNMENT_REQUESTS
-- ============================================================
ALTER TABLE public.scorer_assignment_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "scorer_req_select" ON public.scorer_assignment_requests
FOR SELECT TO authenticated
USING (
    requested_by_user_id = auth.uid()
    OR requested_scorer_user_id = auth.uid()
    OR current_scorer_user_id = auth.uid()
    OR EXISTS (
        SELECT 1 FROM public.players p
        WHERE p.id = scorer_assignment_requests.requested_scorer_user_id
          AND p.profile_id = auth.uid()
    )
    OR EXISTS (
        SELECT 1 FROM auth.users u
        WHERE u.id = auth.uid()
          AND u.email = scorer_assignment_requests.requested_scorer_email
    )
    OR EXISTS (
        SELECT 1 FROM public.matches m
        WHERE m.id = scorer_assignment_requests.match_id
          AND (m.creator_id = auth.uid() OR m.active_scorer_id = auth.uid())
    )
);

CREATE POLICY "scorer_req_insert" ON public.scorer_assignment_requests
FOR INSERT TO authenticated
WITH CHECK (
    requested_by_user_id = auth.uid()
    OR current_scorer_user_id = auth.uid()
);

CREATE POLICY "scorer_req_update" ON public.scorer_assignment_requests
FOR UPDATE TO authenticated
USING (
    requested_by_user_id = auth.uid()
    OR requested_scorer_user_id = auth.uid()
    OR EXISTS (
        SELECT 1 FROM public.players p
        WHERE p.id = scorer_assignment_requests.requested_scorer_user_id
          AND p.profile_id = auth.uid()
    )
    OR EXISTS (
        SELECT 1 FROM auth.users u
        WHERE u.id = auth.uid()
          AND u.email = scorer_assignment_requests.requested_scorer_email
    )
)
WITH CHECK (
    requested_by_user_id = auth.uid()
    OR requested_scorer_user_id = auth.uid()
    OR EXISTS (
        SELECT 1 FROM public.players p
        WHERE p.id = scorer_assignment_requests.requested_scorer_user_id
          AND p.profile_id = auth.uid()
    )
    OR EXISTS (
        SELECT 1 FROM auth.users u
        WHERE u.id = auth.uid()
          AND u.email = scorer_assignment_requests.requested_scorer_email
    )
);

CREATE POLICY "scorer_req_delete" ON public.scorer_assignment_requests
FOR DELETE TO authenticated
USING (requested_by_user_id = auth.uid());

-- ============================================================
-- 11. TABLE 10: PENDING_MATCHES
-- ============================================================
ALTER TABLE public.pending_matches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pending_matches_select" ON public.pending_matches
FOR SELECT TO public
USING (
    status = 'live'
    OR (
        auth.uid() IS NOT NULL
        AND (
            created_by_profile_id = auth.uid()
            OR (match_data->>'teamAScorerId') = auth.uid()::text
        )
    )
);

CREATE POLICY "pending_matches_insert" ON public.pending_matches
FOR INSERT TO authenticated
WITH CHECK (
    created_by_profile_id = auth.uid()
    OR (match_data->>'teamAScorerId') = auth.uid()::text
);

CREATE POLICY "pending_matches_update" ON public.pending_matches
FOR UPDATE TO authenticated
USING (
    created_by_profile_id = auth.uid()
    OR (match_data->>'teamAScorerId') = auth.uid()::text
    OR status = 'live'
)
WITH CHECK (
    created_by_profile_id = auth.uid()
    OR (match_data->>'teamAScorerId') = auth.uid()::text
    OR status = 'live'
);

CREATE POLICY "pending_matches_delete" ON public.pending_matches
FOR DELETE TO authenticated
USING (
    created_by_profile_id = auth.uid()
    OR (match_data->>'teamAScorerId') = auth.uid()::text
);

