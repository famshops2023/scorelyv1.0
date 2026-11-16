ALTER TABLE public.scorer_assignment_requests
ADD COLUMN IF NOT EXISTS payload JSONB;
