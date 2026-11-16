-- Enable UUID extension if not exists
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create tables
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    role VARCHAR(100),
    location VARCHAR(255),
    association VARCHAR(255),
    date_of_birth DATE,
    mobile VARCHAR(20),
    playing_role VARCHAR(50),
    batting_style VARCHAR(50),
    bowling_style VARCHAR(50),
    gender VARCHAR(20),
    profile_image_url TEXT,
    last_login TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE public.teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    logo_url TEXT,
    matches_played INTEGER DEFAULT 0,
    matches_won INTEGER DEFAULT 0,
    matches_lost INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE public.players (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    profile_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    playing_role VARCHAR(50),
    is_captain BOOLEAN DEFAULT FALSE,
    is_admin BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE public.matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    team_a_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    team_b_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    venue VARCHAR(255),
    match_date TIMESTAMPTZ,
    toss_winner_team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
    toss_decision VARCHAR(20) CHECK (toss_decision IN ('Bat', 'Bowl')),
    total_overs INTEGER,
    status VARCHAR(20) CHECK (status IN ('scheduled', 'live', 'completed', 'abandoned')),
    match_result_summary TEXT,
    winner_team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
    win_margin INTEGER,
    win_margin_type VARCHAR(20) CHECK (win_margin_type IN ('runs', 'wickets')),
    player_of_the_match_id UUID REFERENCES public.players(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE public.innings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID REFERENCES public.matches(id) ON DELETE CASCADE,
    innings_number INTEGER CHECK (innings_number IN (1, 2)),
    batting_team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    bowling_team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    total_runs INTEGER DEFAULT 0,
    total_wickets INTEGER DEFAULT 0,
    overs_bowled DECIMAL(5,1) DEFAULT 0.0,
    extras INTEGER DEFAULT 0,
    run_rate DECIMAL(5,2) DEFAULT 0.00,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.balls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    innings_id UUID REFERENCES public.innings(id) ON DELETE CASCADE,
    over_number INTEGER NOT NULL,
    ball_number INTEGER NOT NULL,
    bowler_id UUID REFERENCES public.players(id) ON DELETE SET NULL,
    striker_id UUID REFERENCES public.players(id) ON DELETE SET NULL,
    non_striker_id UUID REFERENCES public.players(id) ON DELETE SET NULL,
    runs_scored INTEGER DEFAULT 0,
    extras INTEGER DEFAULT 0,
    extra_type VARCHAR(20) CHECK (extra_type IN ('wd', 'nb', 'lb', 'b', 'pen')),
    is_wicket BOOLEAN DEFAULT FALSE,
    wicket_type VARCHAR(50),
    player_out_id UUID REFERENCES public.players(id) ON DELETE SET NULL,
    commentary TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.player_match_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID REFERENCES public.matches(id) ON DELETE CASCADE,
    innings_id UUID REFERENCES public.innings(id) ON DELETE CASCADE,
    player_id UUID REFERENCES public.players(id) ON DELETE CASCADE,
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    batting_position INTEGER,
    runs_scored INTEGER DEFAULT 0,
    balls_faced INTEGER DEFAULT 0,
    fours INTEGER DEFAULT 0,
    sixes INTEGER DEFAULT 0,
    is_out BOOLEAN DEFAULT FALSE,
    dismissal_type VARCHAR(50),
    dismissed_by_id UUID REFERENCES public.players(id) ON DELETE SET NULL,
    caught_by_id UUID REFERENCES public.players(id) ON DELETE SET NULL,
    overs_bowled DECIMAL(5,1) DEFAULT 0.0,
    maidens INTEGER DEFAULT 0,
    runs_conceded INTEGER DEFAULT 0,
    wickets_taken INTEGER DEFAULT 0,
    wides_bowled INTEGER DEFAULT 0,
    no_balls_bowled INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create Indexes
CREATE INDEX idx_teams_owner ON public.teams(owner_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_players_team ON public.players(team_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_matches_creator ON public.matches(creator_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_matches_teams ON public.matches(team_a_id, team_b_id);
CREATE INDEX idx_innings_match ON public.innings(match_id);
CREATE INDEX idx_balls_innings ON public.balls(innings_id, over_number, ball_number);
CREATE INDEX idx_player_stats_match ON public.player_match_stats(match_id, team_id);

-- ============================================================
-- V2 SCORER HANDOVER & ASSIGNMENT EXTENSIONS
-- ============================================================

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

