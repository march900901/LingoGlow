-- Create the vocabulary words table
CREATE TABLE IF NOT EXISTS public.words (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    word TEXT NOT NULL,
    definition TEXT NOT NULL,
    synonyms TEXT[] NOT NULL DEFAULT '{}',
    antonyms TEXT[] NOT NULL DEFAULT '{}',
    sample_sentence TEXT,
    
    -- SRS Metadata (SuperMemo-2 parameters)
    repetitions INTEGER NOT NULL DEFAULT 0,
    interval INTEGER NOT NULL DEFAULT 0, -- in days
    ease_factor DOUBLE PRECISION NOT NULL DEFAULT 2.5,
    next_review_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.words ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only select their own vocabulary
CREATE POLICY "Users can view their own words" 
ON public.words FOR SELECT 
TO authenticated 
USING (auth.uid() = user_id);

-- Policy: Users can only insert their own vocabulary
CREATE POLICY "Users can insert their own words" 
ON public.words FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can only update their own vocabulary
CREATE POLICY "Users can update their own words" 
ON public.words FOR UPDATE 
TO authenticated 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can only delete their own vocabulary
CREATE POLICY "Users can delete their own words" 
ON public.words FOR DELETE 
TO authenticated 
USING (auth.uid() = user_id);

-- Create a helper function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create a trigger to update the updated_at timestamp
CREATE OR REPLACE TRIGGER update_words_updated_at
    BEFORE UPDATE ON public.words
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
