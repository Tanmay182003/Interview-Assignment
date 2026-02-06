-- ============================================================================
-- NeverGone Demo - Initial Database Schema
-- ============================================================================
-- This migration creates the core tables for the NeverGone chat application:
-- - profiles: User profile data linked to auth.users
-- - chat_sessions: Individual chat conversations
-- - chat_messages: Messages within chat sessions
-- - memories: Long-term memory summaries generated from sessions
--
-- All tables have Row Level Security (RLS) enabled with policies ensuring
-- users can only access their own data.
-- ============================================================================

-- Note: PostgreSQL 17+ has gen_random_uuid() built-in, no extension needed

-- ============================================================================
-- PROFILES TABLE
-- ============================================================================
-- Stores user profile information, linked to Supabase Auth users.
-- Created automatically via trigger when a new user signs up.

CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    display_name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policies: Users can only view and update their own profile
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Trigger to auto-create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, display_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1))
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- CHAT_SESSIONS TABLE
-- ============================================================================
-- Represents individual chat conversations owned by a user.

CREATE TABLE public.chat_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL DEFAULT 'New Chat',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for efficient user session lookups
CREATE INDEX idx_chat_sessions_user_id ON public.chat_sessions(user_id);
CREATE INDEX idx_chat_sessions_updated_at ON public.chat_sessions(updated_at DESC);

-- Enable RLS
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;

-- Policies: Users can only access their own sessions
CREATE POLICY "Users can view own sessions"
    ON public.chat_sessions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create own sessions"
    ON public.chat_sessions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own sessions"
    ON public.chat_sessions FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own sessions"
    ON public.chat_sessions FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================================
-- CHAT_MESSAGES TABLE
-- ============================================================================
-- Individual messages within a chat session.
-- Role can be 'user' or 'assistant'.

CREATE TYPE public.message_role AS ENUM ('user', 'assistant');

CREATE TABLE public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES public.chat_sessions(id) ON DELETE CASCADE,
    role public.message_role NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for efficient message lookups by session
CREATE INDEX idx_chat_messages_session_id ON public.chat_messages(session_id);
CREATE INDEX idx_chat_messages_created_at ON public.chat_messages(session_id, created_at);

-- Enable RLS
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- Policies: Users can access messages in their own sessions
-- This requires a join to chat_sessions to verify ownership
CREATE POLICY "Users can view messages in own sessions"
    ON public.chat_messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.chat_sessions
            WHERE chat_sessions.id = chat_messages.session_id
            AND chat_sessions.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert messages in own sessions"
    ON public.chat_messages FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.chat_sessions
            WHERE chat_sessions.id = chat_messages.session_id
            AND chat_sessions.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete messages in own sessions"
    ON public.chat_messages FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.chat_sessions
            WHERE chat_sessions.id = chat_messages.session_id
            AND chat_sessions.user_id = auth.uid()
        )
    );

-- ============================================================================
-- MEMORIES TABLE
-- ============================================================================
-- Long-term memory summaries generated from chat sessions.
-- Used to capture important information for future reference.

CREATE TABLE public.memories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    session_id UUID REFERENCES public.chat_sessions(id) ON DELETE SET NULL,
    summary TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for efficient memory lookups
CREATE INDEX idx_memories_user_id ON public.memories(user_id);
CREATE INDEX idx_memories_session_id ON public.memories(session_id);
CREATE INDEX idx_memories_created_at ON public.memories(user_id, created_at DESC);

-- Enable RLS
ALTER TABLE public.memories ENABLE ROW LEVEL SECURITY;

-- Policies: Users can only access their own memories
CREATE POLICY "Users can view own memories"
    ON public.memories FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own memories"
    ON public.memories FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own memories"
    ON public.memories FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to profiles
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Apply updated_at trigger to chat_sessions
CREATE TRIGGER update_chat_sessions_updated_at
    BEFORE UPDATE ON public.chat_sessions
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- GRANTS
-- ============================================================================
-- Grant necessary permissions to authenticated and anon roles

GRANT USAGE ON SCHEMA public TO anon, authenticated;

GRANT SELECT ON public.profiles TO anon, authenticated;
GRANT INSERT, UPDATE ON public.profiles TO authenticated;

GRANT ALL ON public.chat_sessions TO authenticated;
GRANT ALL ON public.chat_messages TO authenticated;
GRANT ALL ON public.memories TO authenticated;
