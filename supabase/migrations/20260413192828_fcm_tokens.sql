CREATE TABLE public.user_device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS
ALTER TABLE public.user_device_tokens ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view only their own tokens
CREATE POLICY "Users can view their own tokens" 
    ON public.user_device_tokens FOR SELECT 
    USING (auth.uid() = user_id);

-- Allow authenticated users to insert/update their own tokens
CREATE POLICY "Users can insert their own tokens" 
    ON public.user_device_tokens FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own tokens" 
    ON public.user_device_tokens FOR UPDATE 
    USING (auth.uid() = user_id);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_user_device_tokens_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_device_tokens_updated_at
BEFORE UPDATE ON public.user_device_tokens
FOR EACH ROW EXECUTE FUNCTION update_user_device_tokens_updated_at();

-- Index for fast token lookups by user (used heavily by edge functions)
CREATE INDEX idx_user_device_tokens_user_id ON public.user_device_tokens(user_id);
