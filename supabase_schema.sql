-- Run this SQL in your Supabase SQL Editor

-- Create child_profiles table
CREATE TABLE IF NOT EXISTS public.child_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    guardian_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    age INTEGER NOT NULL CHECK (age >= 0 AND age <= 18),
    avatar_url TEXT,
    preferences TEXT[] DEFAULT '{}',
    custom_rules TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security
ALTER TABLE public.child_profiles ENABLE ROW LEVEL SECURITY;

-- Create policies for child_profiles
CREATE POLICY "Users can view their own child profiles"
    ON public.child_profiles FOR SELECT
    USING (auth.uid() = guardian_id);

CREATE POLICY "Users can create their own child profiles"
    ON public.child_profiles FOR INSERT
    WITH CHECK (auth.uid() = guardian_id);

CREATE POLICY "Users can update their own child profiles"
    ON public.child_profiles FOR UPDATE
    USING (auth.uid() = guardian_id);

CREATE POLICY "Users can delete their own child profiles"
    ON public.child_profiles FOR DELETE
    USING (auth.uid() = guardian_id);

-- Create custom_rules table
CREATE TABLE IF NOT EXISTS public.custom_rules (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    child_profile_id UUID NOT NULL REFERENCES public.child_profiles(id) ON DELETE CASCADE,
    rule_type TEXT NOT NULL CHECK (rule_type IN ('screen_time', 'content_filter', 'age_restriction')),
    rule_value JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.custom_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage rules for their children"
    ON public.custom_rules FOR ALL
    USING (
        child_profile_id IN (
            SELECT id FROM public.child_profiles WHERE guardian_id = auth.uid()
        )
    );

-- Create viewing_history table
CREATE TABLE IF NOT EXISTS public.viewing_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    child_profile_id UUID NOT NULL REFERENCES public.child_profiles(id) ON DELETE CASCADE,
    video_id TEXT NOT NULL,
    video_title TEXT NOT NULL,
    duration_watched INTEGER NOT NULL, -- in seconds
    watched_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.viewing_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view history for their children"
    ON public.viewing_history FOR ALL
    USING (
        child_profile_id IN (
            SELECT id FROM public.child_profiles WHERE guardian_id = auth.uid()
        )
    );

-- Create playlists table
CREATE TABLE IF NOT EXISTS public.playlists (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    child_profile_id UUID NOT NULL REFERENCES public.child_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    video_ids TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.playlists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage playlists for their children"
    ON public.playlists FOR ALL
    USING (
        child_profile_id IN (
            SELECT id FROM public.child_profiles WHERE guardian_id = auth.uid()
        )
    );

-- Create alerts table
CREATE TABLE IF NOT EXISTS public.alerts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    child_profile_id UUID NOT NULL REFERENCES public.child_profiles(id) ON DELETE CASCADE,
    alert_type TEXT NOT NULL CHECK (alert_type IN ('inappropriate_content', 'screen_time_exceeded', 'other')),
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view alerts for their children"
    ON public.alerts FOR ALL
    USING (
        child_profile_id IN (
            SELECT id FROM public.child_profiles WHERE guardian_id = auth.uid()
        )
    );

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_child_profiles_updated_at
    BEFORE UPDATE ON public.child_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER update_custom_rules_updated_at
    BEFORE UPDATE ON public.custom_rules
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER update_playlists_updated_at
    BEFORE UPDATE ON public.playlists
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Create indexes for better performance
CREATE INDEX idx_child_profiles_guardian_id ON public.child_profiles(guardian_id);
CREATE INDEX idx_custom_rules_child_profile_id ON public.custom_rules(child_profile_id);
CREATE INDEX idx_viewing_history_child_profile_id ON public.viewing_history(child_profile_id);
CREATE INDEX idx_playlists_child_profile_id ON public.playlists(child_profile_id);
CREATE INDEX idx_alerts_child_profile_id ON public.alerts(child_profile_id);
CREATE INDEX idx_alerts_is_read ON public.alerts(is_read);
