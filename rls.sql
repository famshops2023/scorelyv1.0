-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.innings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.balls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.player_match_stats ENABLE ROW LEVEL SECURITY;

-- Profiles Policies
CREATE POLICY "Public profiles are viewable by everyone." 
ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile." 
ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile." 
ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Teams Policies
CREATE POLICY "Teams are viewable by everyone." 
ON public.teams FOR SELECT USING (deleted_at IS NULL);

CREATE POLICY "Users can insert teams." 
ON public.teams FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners can update their teams." 
ON public.teams FOR UPDATE USING (auth.uid() = owner_id);

-- Players Policies
CREATE POLICY "Players are viewable by everyone." 
ON public.players FOR SELECT USING (deleted_at IS NULL);

CREATE POLICY "Users can insert players into their teams." 
ON public.players FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid())
);

CREATE POLICY "Owners can update players in their teams." 
ON public.players FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid())
);

-- Matches Policies
CREATE POLICY "Matches are viewable by everyone." 
ON public.matches FOR SELECT USING (deleted_at IS NULL);

CREATE POLICY "Users can insert matches." 
ON public.matches FOR INSERT WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Creators can update their matches." 
ON public.matches FOR UPDATE USING (auth.uid() = creator_id);

-- Innings Policies
CREATE POLICY "Innings are viewable by everyone." 
ON public.innings FOR SELECT USING (true);

CREATE POLICY "Match creators can insert innings." 
ON public.innings FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.matches WHERE id = match_id AND creator_id = auth.uid())
);

CREATE POLICY "Match creators can update innings." 
ON public.innings FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.matches WHERE id = match_id AND creator_id = auth.uid())
);

-- Balls Policies
CREATE POLICY "Balls are viewable by everyone." 
ON public.balls FOR SELECT USING (true);

CREATE POLICY "Match creators can insert balls." 
ON public.balls FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.innings i
        JOIN public.matches m ON i.match_id = m.id
        WHERE i.id = innings_id AND m.creator_id = auth.uid()
    )
);

-- Player Match Stats Policies
CREATE POLICY "Stats are viewable by everyone." 
ON public.player_match_stats FOR SELECT USING (true);

CREATE POLICY "Match creators can insert/update stats." 
ON public.player_match_stats FOR ALL USING (
    EXISTS (SELECT 1 FROM public.matches WHERE id = match_id AND creator_id = auth.uid())
);
