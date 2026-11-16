ALTER TABLE public.scorer_assignment_requests 
ADD COLUMN IF NOT EXISTS requested_by_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS requested_scorer_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS requested_scorer_email VARCHAR(255),
ADD COLUMN IF NOT EXISTS match_title VARCHAR(255);
