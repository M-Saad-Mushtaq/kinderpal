-- Add birthdate column to child_profiles table

-- Add the birthdate column
ALTER TABLE public.child_profiles 
ADD COLUMN IF NOT EXISTS birthdate DATE;

-- Add a check constraint to ensure birthdate is reasonable (within last 18 years)
ALTER TABLE public.child_profiles 
ADD CONSTRAINT check_birthdate_valid 
CHECK (birthdate IS NULL OR (birthdate >= CURRENT_DATE - INTERVAL '18 years' AND birthdate <= CURRENT_DATE));

-- Add an index for better query performance
CREATE INDEX IF NOT EXISTS idx_child_profiles_birthdate ON public.child_profiles(birthdate);
