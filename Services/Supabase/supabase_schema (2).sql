-- ✅ CLEANED VERSION of Supabase Schema with Errors Fixed

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable Row Level Security globally (grant default privileges)
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role;

-- 🔧 FIXED FUNCTION: update_updated_at_column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 🔧 FIXED FUNCTION: check_streak_break
CREATE OR REPLACE FUNCTION check_streak_break()
RETURNS TRIGGER AS $$
BEGIN
    IF (OLD.is_completed = true AND NEW.is_completed = false) OR
       (NEW.date < CURRENT_DATE AND NEW.is_completed = false) THEN
        UPDATE user_profiles 
        SET current_streak = 0, updated_at = NOW()
        WHERE user_id = NEW.user_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 🔧 FIXED FUNCTION: generate_weekly_summary
CREATE OR REPLACE FUNCTION generate_weekly_summary(user_uuid UUID, week_start DATE)
RETURNS UUID AS $$
DECLARE
    summary_id UUID;
    challenges_count INTEGER;
    checkin_count INTEGER;
    dominant_mood TEXT;
    summary_text TEXT;
BEGIN
    SELECT COUNT(*) INTO challenges_count
    FROM daily_challenges
    WHERE user_id = user_uuid
    AND date >= week_start
    AND date < week_start + INTERVAL '7 days'
    AND is_completed = true;
    
    SELECT COUNT(*) INTO checkin_count
    FROM ai_checkins
    WHERE user_id = user_uuid
    AND date >= week_start
    AND date < week_start + INTERVAL '7 days'
    AND user_response IS NOT NULL;
    
    SELECT mood INTO dominant_mood
    FROM ai_checkins
    WHERE user_id = user_uuid
    AND date >= week_start
    AND date < week_start + INTERVAL '7 days'
    AND mood IS NOT NULL
    GROUP BY mood
    ORDER BY COUNT(*) DESC
    LIMIT 1;
    
    summary_text := format(
        'This week you completed %s challenges and had %s check-ins. Your dominant mood was %s.',
        challenges_count,
        checkin_count,
        COALESCE(dominant_mood, 'not recorded')
    );
    
    INSERT INTO weekly_summaries (
        user_id,
        week_start_date,
        week_end_date,
        summary,
        challenges_completed,
        checkin_streak
    ) VALUES (
        user_uuid,
        week_start,
        week_start + INTERVAL '6 days',
        summary_text,
        challenges_count,
        checkin_count
    ) RETURNING id INTO summary_id;
    
    RETURN summary_id;
END;
$$ LANGUAGE plpgsql;

-- Function to get user's current streak
CREATE OR REPLACE FUNCTION get_user_current_streak(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
    streak_count INTEGER := 0;
    check_date DATE := CURRENT_DATE;
    has_challenge BOOLEAN;
BEGIN
    LOOP
        SELECT EXISTS(
            SELECT 1 FROM daily_challenges 
            WHERE user_id = user_uuid 
            AND date = check_date 
            AND is_completed = true
        ) INTO has_challenge;
        
        IF NOT has_challenge THEN
            EXIT;
        END IF;
        
        streak_count := streak_count + 1;
        check_date := check_date - INTERVAL '1 day';
    END LOOP;
    
    RETURN streak_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- MARK: - User Profiles Table
CREATE TABLE public.user_profiles (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
    selected_path TEXT NOT NULL CHECK (selected_path IN ('discipline', 'clarity', 'confidence', 'purpose', 'authenticity')),
    join_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    current_streak INTEGER DEFAULT 0 NOT NULL,
    longest_streak INTEGER DEFAULT 0 NOT NULL,
    total_challenges_completed INTEGER DEFAULT 0 NOT NULL,
    subscription_tier TEXT DEFAULT 'free' CHECK (subscription_tier IN ('free', 'pro')),
    streak_bank_days INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- RLS Policies for user_profiles
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

-- MARK: - Daily Challenges Table
CREATE TABLE public.daily_challenges (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    path TEXT NOT NULL CHECK (path IN ('discipline', 'clarity', 'confidence', 'purpose', 'authenticity')),
    difficulty TEXT DEFAULT 'micro' CHECK (difficulty IN ('micro', 'standard', 'advanced')),
    date DATE NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    
    -- Ensure one challenge per user per day
    UNIQUE(user_id, date)
);

-- Indexes for performance
CREATE INDEX idx_daily_challenges_user_date ON public.daily_challenges(user_id, date DESC);
CREATE INDEX idx_daily_challenges_path ON public.daily_challenges(path);

-- RLS Policies for daily_challenges
ALTER TABLE public.daily_challenges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own challenges" ON public.daily_challenges
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own challenges" ON public.daily_challenges
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own challenges" ON public.daily_challenges
    FOR UPDATE USING (auth.uid() = user_id);

-- MARK: - AI Check-ins Table
CREATE TABLE public.ai_checkins (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    date DATE NOT NULL,
    time_of_day TEXT NOT NULL CHECK (time_of_day IN ('morning', 'evening')),
    prompt TEXT NOT NULL,
    user_response TEXT,
    ai_response TEXT,
    mood TEXT CHECK (mood IN ('low', 'neutral', 'good', 'great', 'excellent')),
    effort_level INTEGER CHECK (effort_level >= 1 AND effort_level <= 5),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    
    -- Ensure one check-in per user per time of day per date
    UNIQUE(user_id, date, time_of_day)
);

-- Indexes for performance
CREATE INDEX idx_ai_checkins_user_date ON public.ai_checkins(user_id, date DESC);
CREATE INDEX idx_ai_checkins_mood ON public.ai_checkins(mood);

-- RLS Policies for ai_checkins
ALTER TABLE public.ai_checkins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own checkins" ON public.ai_checkins
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own checkins" ON public.ai_checkins
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own checkins" ON public.ai_checkins
    FOR UPDATE USING (auth.uid() = user_id);

-- MARK: - Journal Entries Table
CREATE TABLE public.journal_entries (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    date DATE NOT NULL,
    content TEXT NOT NULL,
    prompt TEXT,
    mood TEXT CHECK (mood IN ('low', 'neutral', 'good', 'great', 'excellent')),
    tags TEXT[] DEFAULT '{}',
    is_saved_to_self BOOLEAN DEFAULT FALSE,
    is_marked_for_reread BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Indexes for performance
CREATE INDEX idx_journal_entries_user_date ON public.journal_entries(user_id, date DESC);
CREATE INDEX idx_journal_entries_tags ON public.journal_entries USING GIN(tags);
CREATE INDEX idx_journal_entries_saved ON public.journal_entries(user_id, is_saved_to_self) WHERE is_saved_to_self = TRUE;

-- RLS Policies for journal_entries
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own journal entries" ON public.journal_entries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own journal entries" ON public.journal_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own journal entries" ON public.journal_entries
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own journal entries" ON public.journal_entries
    FOR DELETE USING (auth.uid() = user_id);

-- MARK: - Book Recommendations Table (Global content)
CREATE TABLE public.book_recommendations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    path TEXT NOT NULL CHECK (path IN ('discipline', 'clarity', 'confidence', 'purpose', 'authenticity')),
    summary TEXT NOT NULL,
    key_insight TEXT NOT NULL,
    daily_action TEXT NOT NULL,
    cover_image_url TEXT,
    amazon_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    priority_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Indexes for performance
CREATE INDEX idx_book_recommendations_path_active ON public.book_recommendations(path, is_active, priority_order DESC);

-- RLS Policies for book_recommendations (public read)
ALTER TABLE public.book_recommendations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active book recommendations" ON public.book_recommendations
    FOR SELECT USING (is_active = TRUE);

-- MARK: - User Book Interactions Table
CREATE TABLE public.user_book_interactions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    book_id UUID REFERENCES public.book_recommendations(id) ON DELETE CASCADE NOT NULL,
    is_saved BOOLEAN DEFAULT FALSE,
    is_read BOOLEAN DEFAULT FALSE,
    reading_progress DECIMAL(3,2) DEFAULT 0.0 CHECK (reading_progress >= 0.0 AND reading_progress <= 1.0),
    personal_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    
    -- Ensure one interaction record per user per book
    UNIQUE(user_id, book_id)
);

-- Indexes for performance
CREATE INDEX idx_user_book_interactions_user ON public.user_book_interactions(user_id);
CREATE INDEX idx_user_book_interactions_saved ON public.user_book_interactions(user_id, is_saved) WHERE is_saved = TRUE;

-- RLS Policies for user_book_interactions
ALTER TABLE public.user_book_interactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own book interactions" ON public.user_book_interactions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own book interactions" ON public.user_book_interactions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own book interactions" ON public.user_book_interactions
    FOR UPDATE USING (auth.uid() = user_id);

-- ✅ ADDED MISSING TABLE: weekly_summaries
CREATE TABLE public.weekly_summaries (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    week_start_date DATE NOT NULL,
    week_end_date DATE NOT NULL,
    summary TEXT NOT NULL,
    key_themes TEXT[] DEFAULT '{}',
    challenges_completed INTEGER DEFAULT 0,
    checkin_streak INTEGER DEFAULT 0,
    recommended_focus TEXT CHECK (recommended_focus IN ('discipline', 'clarity', 'confidence', 'purpose', 'authenticity')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    
    -- Ensure one summary per user per week
    UNIQUE(user_id, week_start_date)
);

-- Indexes for performance
CREATE INDEX idx_weekly_summaries_user_date ON public.weekly_summaries(user_id, week_start_date DESC);

-- RLS Policies for weekly_summaries
ALTER TABLE public.weekly_summaries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own weekly summaries" ON public.weekly_summaries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own weekly summaries" ON public.weekly_summaries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- MARK: - Challenge Templates Table (For content scaling)
CREATE TABLE public.challenge_templates (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    path TEXT NOT NULL CHECK (path IN ('discipline', 'clarity', 'confidence', 'purpose', 'authenticity')),
    difficulty TEXT NOT NULL CHECK (difficulty IN ('micro', 'standard', 'advanced')),
    category TEXT, -- e.g., 'physical', 'mental', 'social', 'spiritual'
    estimated_time_minutes INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    usage_count INTEGER DEFAULT 0,
    success_rate DECIMAL(3,2) DEFAULT 0.0,
    created_by UUID REFERENCES auth.users(id), -- For user-generated content
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Indexes for challenge templates
CREATE INDEX idx_challenge_templates_path_difficulty ON public.challenge_templates(path, difficulty, is_active);
CREATE INDEX idx_challenge_templates_category ON public.challenge_templates(category);

-- RLS Policies for challenge_templates
ALTER TABLE public.challenge_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active challenge templates" ON public.challenge_templates
    FOR SELECT USING (is_active = TRUE);

CREATE POLICY "Users can create challenge templates" ON public.challenge_templates
    FOR INSERT WITH CHECK (auth.uid() = created_by);

-- MARK: - User Achievements Table
CREATE TABLE public.user_achievements (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    achievement_type TEXT NOT NULL, -- e.g., 'streak_milestone', 'path_completion', 'consistency'
    achievement_data JSONB, -- Flexible storage for achievement details
    earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    is_claimed BOOLEAN DEFAULT FALSE,
    
    -- Prevent duplicate achievements
    UNIQUE(user_id, achievement_type, achievement_data)
);

-- Indexes for achievements
CREATE INDEX idx_user_achievements_user ON public.user_achievements(user_id, earned_at DESC);
CREATE INDEX idx_user_achievements_type ON public.user_achievements(achievement_type);

-- RLS Policies for user_achievements
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own achievements" ON public.user_achievements
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can insert achievements" ON public.user_achievements
    FOR INSERT WITH CHECK (true); -- Controlled by backend logic

-- MARK: - User Sessions Table (For analytics)
CREATE TABLE public.user_sessions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    session_start TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    session_end TIMESTAMP WITH TIME ZONE,
    actions_taken JSONB DEFAULT '[]', -- Track user interactions
    device_info JSONB, -- Device type, OS version, etc.
    app_version TEXT
);

-- Indexes for sessions
CREATE INDEX idx_user_sessions_user_date ON public.user_sessions(user_id, session_start DESC);

-- RLS Policies for user_sessions
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own sessions" ON public.user_sessions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sessions" ON public.user_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- MARK: - Subscription Management Table
CREATE TABLE public.user_subscriptions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
    subscription_tier TEXT DEFAULT 'free' CHECK (subscription_tier IN ('free', 'pro')),
    subscription_status TEXT DEFAULT 'active' CHECK (subscription_status IN ('active', 'canceled', 'expired', 'trial')),
    trial_start_date TIMESTAMP WITH TIME ZONE,
    trial_end_date TIMESTAMP WITH TIME ZONE,
    subscription_start_date TIMESTAMP WITH TIME ZONE,
    subscription_end_date TIMESTAMP WITH TIME ZONE,
    payment_provider TEXT, -- 'apple', 'stripe', etc.
    external_subscription_id TEXT, -- ID from payment provider
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Indexes for subscriptions
CREATE INDEX idx_user_subscriptions_status ON public.user_subscriptions(subscription_status, subscription_end_date);

-- RLS Policies for user_subscriptions
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own subscription" ON public.user_subscriptions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own subscription" ON public.user_subscriptions
    FOR UPDATE USING (auth.uid() = user_id);

-- Apply the trigger to relevant tables
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON public.user_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_ai_checkins_updated_at BEFORE UPDATE ON public.ai_checkins FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_journal_entries_updated_at BEFORE UPDATE ON public.journal_entries FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_book_recommendations_updated_at BEFORE UPDATE ON public.book_recommendations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_book_interactions_updated_at BEFORE UPDATE ON public.user_book_interactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_challenge_templates_updated_at BEFORE UPDATE ON public.challenge_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_subscriptions_updated_at BEFORE UPDATE ON public.user_subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Apply streak break trigger
CREATE TRIGGER check_streak_break_trigger 
    AFTER UPDATE ON daily_challenges 
    FOR EACH ROW 
    EXECUTE FUNCTION check_streak_break();

-- MARK: - Sample Data for Testing

-- Insert sample book recommendations
INSERT INTO public.book_recommendations (title, author, path, summary, key_insight, daily_action, priority_order) VALUES
('Can''t Hurt Me', 'David Goggins', 'discipline', 'Former Navy SEAL shares his journey from obesity to becoming one of the world''s toughest endurance athletes.', 'Mental toughness is built through deliberately choosing discomfort.', 'Do something that makes you uncomfortable for 10 minutes.', 1),
('Atomic Habits', 'James Clear', 'discipline', 'A comprehensive guide to building good habits and breaking bad ones through small, incremental changes.', 'Success is the product of daily habits, not once-in-a-lifetime transformations.', 'Stack a new 2-minute habit onto an existing routine.', 2),
('The Power of Now', 'Eckhart Tolle', 'clarity', 'A guide to spiritual enlightenment through present-moment awareness.', 'The present moment is the only time over which we have any power.', 'Take 3 conscious breaths when you feel stressed.', 1),
('Mindset', 'Carol Dweck', 'confidence', 'Explores how beliefs about ability and intelligence impact success and relationships.', 'People with a growth mindset believe abilities can be developed through dedication and hard work.', 'Replace "I can''t do this" with "I can''t do this yet."', 1),
('Man''s Search for Meaning', 'Viktor Frankl', 'purpose', 'Holocaust survivor''s insights on finding meaning in suffering and life''s challenges.', 'Those who have a why to live can bear almost any how.', 'Write down one thing that gives your life meaning.', 1),
('The Gifts of Imperfection', 'Brené Brown', 'authenticity', 'A guide to cultivating courage, compassion, and connection through embracing vulnerability.', 'Authenticity is the daily practice of letting go of who we think we''re supposed to be.', 'Share one authentic thought or feeling with someone you trust.', 1);

-- Insert sample challenge templates
INSERT INTO public.challenge_templates (title, description, path, difficulty, category, estimated_time_minutes) VALUES
('No Social Media Morning', 'Don''t check social media until after lunch', 'discipline', 'micro', 'digital', 2),
('Cold Shower Finish', 'End your shower with 30 seconds of cold water', 'discipline', 'micro', 'physical', 2),
('Gratitude Journal', 'Write down 3 things you''re grateful for', 'clarity', 'micro', 'mental', 5),
('Compliment a Stranger', 'Give a genuine compliment to someone you don''t know', 'confidence', 'micro', 'social', 2),
('Values Check', 'Spend 5 minutes reviewing your core values', 'purpose', 'micro', 'spiritual', 5),
('Authentic Expression', 'Share one genuine thought or feeling with someone', 'authenticity', 'micro', 'social', 3);

-- Create indexes for full-text search on journal entries and check-ins
CREATE INDEX idx_journal_entries_content_search ON public.journal_entries USING gin(to_tsvector('english', content));
CREATE INDEX idx_ai_checkins_response_search ON public.ai_checkins USING gin(to_tsvector('english', user_response));

-- MARK: - Views for Analytics

-- View for user engagement metrics
CREATE VIEW user_engagement_metrics AS
SELECT 
    up.user_id,
    up.current_streak,
    up.longest_streak,
    up.total_challenges_completed,
    COUNT(DISTINCT dc.date) as total_challenge_days,
    COUNT(DISTINCT ac.date) as total_checkin_days,
    COUNT(DISTINCT je.date) as total_journal_days,
    AVG(CASE 
        WHEN ac.mood = 'excellent' THEN 5
        WHEN ac.mood = 'great' THEN 4
        WHEN ac.mood = 'good' THEN 3
        WHEN ac.mood = 'neutral' THEN 2
        WHEN ac.mood = 'low' THEN 1
    END) as avg_mood_score,
    MAX(dc.date) as last_challenge_date,
    MAX(ac.date) as last_checkin_date
FROM user_profiles up
LEFT JOIN daily_challenges dc ON up.user_id = dc.user_id AND dc.is_completed = true
LEFT JOIN ai_checkins ac ON up.user_id = ac.user_id AND ac.user_response IS NOT NULL
LEFT JOIN journal_entries je ON up.user_id = je.user_id
GROUP BY up.user_id, up.current_streak, up.longest_streak, up.total_challenges_completed;

-- View for content popularity
CREATE VIEW content_popularity AS
SELECT 
    ct.path,
    ct.difficulty,
    ct.category,
    COUNT(dc.id) as usage_count,
    AVG(CASE WHEN dc.is_completed THEN 1.0 ELSE 0.0 END) as completion_rate,
    ct.title as template_title
FROM challenge_templates ct
LEFT JOIN daily_challenges dc ON ct.title = dc.title
WHERE ct.is_active = true
GROUP BY ct.id, ct.path, ct.difficulty, ct.category, ct.title
ORDER BY usage_count DESC, completion_rate DESC;

COMMENT ON TABLE public.user_profiles IS 'Core user profile data and progress tracking';
COMMENT ON TABLE public.daily_challenges IS 'Daily challenges assigned to users';
COMMENT ON TABLE public.ai_checkins IS 'Morning and evening AI-powered check-ins';
COMMENT ON TABLE public.journal_entries IS 'User reflection journal entries';
COMMENT ON TABLE public.book_recommendations IS 'Curated book content for different paths';
COMMENT ON TABLE public.user_book_interactions IS 'User interactions with recommended books';
COMMENT ON TABLE public.weekly_summaries IS 'AI-generated weekly progress summaries';
COMMENT ON TABLE public.challenge_templates IS 'Template library for generating daily challenges';
COMMENT ON TABLE public.user_achievements IS 'Gamification and milestone tracking';
COMMENT ON TABLE public.user_sessions IS 'Analytics and usage tracking';
COMMENT ON TABLE public.user_subscriptions IS 'Subscription and billing management';