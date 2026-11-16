-- Migration: 20261107153000_add-player-profile-ids-to-matches.sql
-- Description: Adds player_profile_ids column to matches to link all participating signed-in players.

ALTER TABLE public.matches ADD COLUMN IF NOT EXISTS player_profile_ids JSONB DEFAULT '[]'::jsonb;
CREATE INDEX IF NOT EXISTS idx_matches_player_profile_ids ON public.matches USING gin (player_profile_ids);

