-- Migration Rollback: 20261107090001_rollback-secure-rls-policies.sql
-- Description: Reverts Scorely database policies back to initial permissive state if needed.

-- Drop hardened policies
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

-- Recreate initial permissive policies
CREATE POLICY "profiles_select" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "profiles_insert" ON public.profiles FOR INSERT WITH CHECK (true);
CREATE POLICY "profiles_update" ON public.profiles FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "profiles_delete" ON public.profiles FOR DELETE USING (true);

CREATE POLICY "teams_select" ON public.teams FOR SELECT USING (true);
CREATE POLICY "teams_insert" ON public.teams FOR INSERT WITH CHECK (true);
CREATE POLICY "teams_update" ON public.teams FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "teams_delete" ON public.teams FOR DELETE USING (true);

CREATE POLICY "players_select" ON public.players FOR SELECT USING (true);
CREATE POLICY "players_insert" ON public.players FOR INSERT WITH CHECK (true);
CREATE POLICY "players_update" ON public.players FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "players_delete" ON public.players FOR DELETE USING (true);

CREATE POLICY "matches_select" ON public.matches FOR SELECT USING (true);
CREATE POLICY "matches_insert" ON public.matches FOR INSERT WITH CHECK (true);
CREATE POLICY "matches_update" ON public.matches FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "matches_delete" ON public.matches FOR DELETE USING (true);

CREATE POLICY "innings_select" ON public.innings FOR SELECT USING (true);
CREATE POLICY "innings_insert" ON public.innings FOR INSERT WITH CHECK (true);
CREATE POLICY "innings_update" ON public.innings FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "innings_delete" ON public.innings FOR DELETE USING (true);

CREATE POLICY "balls_select" ON public.balls FOR SELECT USING (true);
CREATE POLICY "balls_insert" ON public.balls FOR INSERT WITH CHECK (true);
CREATE POLICY "balls_update" ON public.balls FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "balls_delete" ON public.balls FOR DELETE USING (true);

CREATE POLICY "ball_events_select" ON public.ball_events FOR SELECT USING (true);
CREATE POLICY "ball_events_insert" ON public.ball_events FOR INSERT WITH CHECK (true);
CREATE POLICY "ball_events_update" ON public.ball_events FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "ball_events_delete" ON public.ball_events FOR DELETE USING (true);

CREATE POLICY "player_match_stats_select" ON public.player_match_stats FOR SELECT USING (true);
CREATE POLICY "player_match_stats_insert" ON public.player_match_stats FOR INSERT WITH CHECK (true);
CREATE POLICY "player_match_stats_update" ON public.player_match_stats FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "player_match_stats_delete" ON public.player_match_stats FOR DELETE USING (true);

CREATE POLICY "scorer_assignment_requests_select" ON public.scorer_assignment_requests FOR SELECT USING (true);
CREATE POLICY "scorer_assignment_requests_insert" ON public.scorer_assignment_requests FOR INSERT WITH CHECK (true);
CREATE POLICY "scorer_assignment_requests_update" ON public.scorer_assignment_requests FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "scorer_assignment_requests_delete" ON public.scorer_assignment_requests FOR DELETE USING (true);

CREATE POLICY "pending_matches_select" ON public.pending_matches FOR SELECT USING (true);
CREATE POLICY "pending_matches_insert" ON public.pending_matches FOR INSERT WITH CHECK (true);
CREATE POLICY "pending_matches_update" ON public.pending_matches FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "pending_matches_delete" ON public.pending_matches FOR DELETE USING (true);

