-- Drop foreign key constraint on match_id in scorer_assignment_requests
-- so that requests can be created for live matches before they are synced to matches table
ALTER TABLE public.scorer_assignment_requests DROP CONSTRAINT IF EXISTS fk_scorer_request_match;
ALTER TABLE public.scorer_assignment_requests DROP CONSTRAINT IF EXISTS scorer_assignment_requests_match_id_fkey;

-- Ensure RLS allows authenticated users to read/insert/update
GRANT ALL ON public.scorer_assignment_requests TO authenticated;
GRANT ALL ON public.scorer_assignment_requests TO anon;
