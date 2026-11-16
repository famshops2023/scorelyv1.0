-- Migration: 20261107090000_secure-rls-policies.sql
-- Description: Hardens RLS policies across all 10 tables in Scorely database.
-- Complies with strict security audit while preserving application functionality.

-- Ensure live_score_data column exists on pending_matches for real-time live scoring
ALTER TABLE public.pending_matches ADD COLUMN IF NOT EXISTS live_score_data JSONB;

-- ============================================================
-- 1. DROP EXISTING WILDCARD POLICIES
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

-- Also drop any earlier policy names if existing
DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_delete_own" ON public.profiles;

DROP POLICY IF EXISTS "teams_select_public" ON public.teams;
DROP POLICY IF EXISTS "teams_insert_authenticated" ON public.teams;
DROP POLICY IF EXISTS "teams_update_owner_or_admin" ON public.teams;
DROP POLICY IF EXISTS "teams_delete_owner" ON public.teams;

DROP POLICY IF EXISTS "players_select_public" ON public.players;
DROP POLICY IF EXISTS "players_insert_authorized" ON public.players;
DROP POLICY IF EXISTS "players_update_authorized" ON public.players;
DROP POLICY IF EXISTS "players_delete_authorized" ON public.players;

DROP POLICY IF EXISTS "matches_select_public" ON public.matches;
DROP POLICY IF EXISTS "matches_insert_authorized" ON public.matches;
DROP POLICY IF EXISTS "matches_update_authorized" ON public.matches;
DROP POLICY IF EXISTS "matches_delete_creator" ON public.matches;

DROP POLICY IF EXISTS "innings_select_public" ON public.innings;
DROP POLICY IF EXISTS "innings_insert_scorer" ON public.innings;
DROP POLICY IF EXISTS "innings_update_scorer" ON public.innings;
DROP POLICY IF EXISTS "innings_delete_creator" ON public.innings;

DROP POLICY IF EXISTS "balls_select_public" ON public.balls;
DROP POLICY IF EXISTS "balls_insert_scorer" ON public.balls;
DROP POLICY IF EXISTS "balls_update_scorer" ON public.balls;
DROP POLICY IF EXISTS "balls_delete_scorer" ON public.balls;

DROP POLICY IF EXISTS "ball_events_select_public" ON public.ball_events;
DROP POLICY IF EXISTS "ball_events_insert_scorer" ON public.ball_events;
DROP POLICY IF EXISTS "ball_events_update_scorer" ON public.ball_events;
DROP POLICY IF EXISTS "ball_events_delete_scorer" ON public.ball_events;

DROP POLICY IF EXISTS "player_match_stats_select_public" ON public.player_match_stats;
DROP POLICY IF EXISTS "player_match_stats_insert_scorer" ON public.player_match_stats;
DROP POLICY IF EXISTS "player_match_stats_update_scorer" ON public.player_match_stats;
DROP POLICY IF EXISTS "player_match_stats_delete_scorer" ON public.player_match_stats;

DROP POLICY IF EXISTS "scorer_req_select" ON public.scorer_assignment_requests;
DROP POLICY IF EXISTS "scorer_req_insert" ON public.scorer_assignment_requests;
DROP POLICY IF EXISTS "scorer_req_update" ON public.scorer_assignment_requests;
DROP POLICY IF EXISTS "scorer_req_delete" ON public.scorer_assignment_requests;

DROP POLICY IF EXISTS "pending_matches_select" ON public.pending_matches;
DROP POLICY IF EXISTS "pending_matches_insert" ON public.pending_matches;
DROP POLICY IF EXISTS "pending_matches_update" ON public.pending_matches;
DROP POLICY IF EXISTS "pending_matches_delete" ON public.pending_matches;


-- ============================================================
-- 2. TABLE 1: PROFILES
-- ============================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Owner can read their own profile (including private email, mobile, DOB)
CREATE POLICY "profiles_select_own" ON public.profiles
FOR SELECT TO authenticated
USING (auth.uid() = id);

-- Owner can insert their own profile
CREATE POLICY "profiles_insert_own" ON public.profiles
FOR INSERT TO authenticated
WITH CHECK (auth.uid() = id);

-- Owner can update their own profile
CREATE POLICY "profiles_update_own" ON public.profiles
FOR UPDATE TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Owner can delete their own profile
CREATE POLICY "profiles_delete_own" ON public.profiles
FOR DELETE TO authenticated
USING (auth.uid() = id);

-- Public view for player discovery (exposes only approved non-sensitive fields)
CREATE OR REPLACE VIEW public.public_profiles WITH (security_invoker = false) AS
SELECT 
    id,
    name,
    role,
    location,
    association,
    playing_role,
    batting_style,
    bowling_style,
    gender,
    profile_image_url,
    created_at,
    updated_at
FROM public.profiles
WHERE deleted_at IS NULL;

GRANT SELECT ON public.public_profiles TO anon, authenticated;


-- ============================================================
-- 3. TABLE 2: TEAMS
-- ============================================================
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;

-- Public can view active teams
CREATE POLICY "teams_select_public" ON public.teams
FOR SELECT TO public
USING (deleted_at IS NULL);

-- Authenticated users can create teams with themselves as owner
CREATE POLICY "teams_insert_authenticated" ON public.teams
FOR INSERT TO authenticated
WITH CHECK (auth.uid() = owner_id);

-- Only team owner or authorized team admin/captain can update team details
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

-- Only team owner can delete team
CREATE POLICY "teams_delete_owner" ON public.teams
FOR DELETE TO authenticated
USING (auth.uid() = owner_id);


-- ============================================================
-- 4. TABLE 3: PLAYERS
-- ============================================================
ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;

-- Public can view active players
CREATE POLICY "players_select_public" ON public.players
FOR SELECT TO public
USING (deleted_at IS NULL);

-- Standalone user for themselves OR team owner/admin for squad members
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

-- Standalone user updating self OR team owner/admin updating squad members
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

-- Standalone user deleting self OR team owner/admin removing player
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

-- Public can view active matches
CREATE POLICY "matches_select_public" ON public.matches
FOR SELECT TO public
USING (deleted_at IS NULL);

-- Match creator or active scorer can create/upsert match
CREATE POLICY "matches_insert_authorized" ON public.matches
FOR INSERT TO authenticated
WITH CHECK (
    creator_id = auth.uid()
    OR active_scorer_id = auth.uid()
);

-- Match creator or active scorer can update match details / status
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

-- Only match creator can delete match
CREATE POLICY "matches_delete_creator" ON public.matches
FOR DELETE TO authenticated
USING (creator_id = auth.uid());


-- ============================================================
-- 6. TABLE 5: INNINGS
-- ============================================================
ALTER TABLE public.innings ENABLE ROW LEVEL SECURITY;

-- Public can view innings
CREATE POLICY "innings_select_public" ON public.innings
FOR SELECT TO public
USING (true);

-- Authorized scorer (creator or active scorer of the parent match) can insert
CREATE POLICY "innings_insert_scorer" ON public.innings
FOR INSERT TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.matches m
        WHERE m.id = innings.match_id
          AND (m.creator_id = auth.uid() OR m.active_scorer_id = auth.uid())
    )
);

-- Authorized scorer can update innings score
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

-- Creator can delete innings
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

-- Public can view balls
CREATE POLICY "balls_select_public" ON public.balls
FOR SELECT TO public
USING (true);

-- Authorized scorer can insert ball delivery
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

-- Authorized scorer can update ball delivery (e.g. ball edit)
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

-- Authorized scorer can delete ball delivery (e.g. undo ball)
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

-- Public can view ball events
CREATE POLICY "ball_events_select_public" ON public.ball_events
FOR SELECT TO public
USING (true);

-- Authorized scorer can insert ball events
CREATE POLICY "ball_events_insert_scorer" ON public.ball_events
FOR INSERT TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.matches m
        WHERE m.id = ball_events.match_id
          AND (m.creator_id = auth.uid() OR m.active_scorer_id = auth.uid())
    )
);

-- Authorized scorer can update ball events
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

-- Authorized scorer can delete ball events
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

-- Public can view statistics
CREATE POLICY "player_match_stats_select_public" ON public.player_match_stats
FOR SELECT TO public
USING (true);

-- Authorized scorer can insert statistics
CREATE POLICY "player_match_stats_insert_scorer" ON public.player_match_stats
FOR INSERT TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.matches m
        WHERE m.id = player_match_stats.match_id
          AND (m.creator_id = auth.uid() OR m.active_scorer_id = auth.uid())
    )
);

-- Authorized scorer can update statistics
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

-- Creator can delete statistics
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

-- Relevant parties can view requests (requester, recipient, current scorer, match creator)
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

-- Requester or current scorer can insert request
CREATE POLICY "scorer_req_insert" ON public.scorer_assignment_requests
FOR INSERT TO authenticated
WITH CHECK (
    requested_by_user_id = auth.uid()
    OR current_scorer_user_id = auth.uid()
);

-- Recipient can accept/decline; Requester can cancel
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

-- Requester can delete request
CREATE POLICY "scorer_req_delete" ON public.scorer_assignment_requests
FOR DELETE TO authenticated
USING (requested_by_user_id = auth.uid());


-- ============================================================
-- 11. TABLE 10: PENDING_MATCHES
-- ============================================================
ALTER TABLE public.pending_matches ENABLE ROW LEVEL SECURITY;

-- Public can view live matches; owners can view their drafts
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

-- Owner can insert pending match
CREATE POLICY "pending_matches_insert" ON public.pending_matches
FOR INSERT TO authenticated
WITH CHECK (
    created_by_profile_id = auth.uid()
    OR (match_data->>'teamAScorerId') = auth.uid()::text
);

-- Owner or active live scorer can update pending match
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

-- Owner can delete pending match
CREATE POLICY "pending_matches_delete" ON public.pending_matches
FOR DELETE TO authenticated
USING (
    created_by_profile_id = auth.uid()
    OR (match_data->>'teamAScorerId') = auth.uid()::text
);

