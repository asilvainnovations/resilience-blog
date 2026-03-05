-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================================
-- ENUMS
-- ==========================================

CREATE TYPE user_role AS ENUM ('admin', 'editor', 'reader');
CREATE TYPE post_status AS ENUM ('draft', 'published', 'archived');
CREATE TYPE comment_status AS ENUM ('pending', 'approved', 'rejected', 'spam');
CREATE TYPE email_status AS ENUM ('queued', 'sent', 'failed', 'bounced', 'opened', 'clicked');
CREATE TYPE media_type AS ENUM ('image', 'document', 'video', 'audio');
CREATE TYPE newsletter_frequency AS ENUM ('daily', 'weekly', 'monthly');

-- ==========================================
-- PROFILES & AUTHENTICATION (Supabase Auth Compatible)
-- ==========================================

-- Main profiles table (works with Supabase Auth)
-- Note: id matches auth.users.id via trigger or manual insert
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) UNIQUE NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    
    -- Profile info
    username VARCHAR(50) UNIQUE,
    full_name VARCHAR(255),
    avatar_url TEXT,
    bio TEXT,
    
    -- Role-based access control
    role user_role DEFAULT 'reader',
    
    -- Security
    last_sign_in_at TIMESTAMP WITH TIME ZONE,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP WITH TIME ZONE,
    
    -- Newsletter preferences
    newsletter_subscribed BOOLEAN DEFAULT true,
    newsletter_frequency newsletter_frequency DEFAULT 'weekly',
    social_links JSONB DEFAULT '{}'::jsonb,
    
    -- Preferences
    preferences JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE -- Soft delete
);

-- API Keys for external integrations (SendGrid, etc.)
CREATE TABLE public.api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    service_name VARCHAR(50) NOT NULL, -- 'sendgrid', 'openai', etc.
    key_name VARCHAR(100),
    encrypted_key TEXT NOT NULL,
    key_prefix VARCHAR(10),
    
    permissions JSONB DEFAULT '[]'::jsonb,
    rate_limit INTEGER DEFAULT 1000,
    last_used_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Partial unique index for active keys per service (corrected syntax)
CREATE UNIQUE INDEX idx_unique_active_api_key 
ON public.api_keys (user_id, service_name) 
WHERE is_active = TRUE;

-- User sessions for tracking
CREATE TABLE public.user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    ip_address INET,
    user_agent TEXT,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- NEWSLETTER SYSTEM
-- ==========================================

CREATE TABLE public.subscribers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name TEXT,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'unsubscribed', 'bounced')),
    unsubscribed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- CATEGORIES & TAGS
-- ==========================================

CREATE TABLE public.categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    short_name VARCHAR(50),
    description TEXT,
    
    -- Styling (matches HTML structure)
    color_class VARCHAR(100) DEFAULT 'bg-slate-100 text-slate-800',
    icon_class VARCHAR(50) DEFAULT 'fa-folder',
    
    -- External links
    external_url TEXT,
    
    -- SEO
    meta_title VARCHAR(255),
    meta_description TEXT,
    
    -- Hierarchy
    parent_id UUID REFERENCES public.categories(id),
    sort_order INTEGER DEFAULT 0,
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE public.tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    
    -- SEO
    meta_title VARCHAR(255),
    meta_description TEXT,
    
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- ARTICLES (BLOG POSTS)
-- ==========================================

CREATE TABLE public.articles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Content
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    excerpt TEXT,
    content TEXT NOT NULL,
    
    -- Relationships
    author_id UUID NOT NULL REFERENCES public.profiles(id),
    category_id UUID REFERENCES public.categories(id),
    
    -- Media
    featured_image TEXT DEFAULT 'https://asilvainnovations.com/assets/apps/user_1097/app_13212/draft/icon/app_logo.png?1769949231',
    featured_image_alt TEXT,
    
    -- Publishing
    status post_status DEFAULT 'draft',
    published_at TIMESTAMP WITH TIME ZONE,
    scheduled_publish_at TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    views INTEGER DEFAULT 0,
    reading_time INTEGER DEFAULT 5,
    tags TEXT[] DEFAULT '{}',
    
    -- SEO
    meta_title VARCHAR(255),
    meta_description TEXT,
    og_image TEXT,
    canonical_url TEXT,
    
    -- Versioning
    version INTEGER DEFAULT 1,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Many-to-many: Articles <-> Tags (normalized)
CREATE TABLE public.article_tags (
    article_id UUID NOT NULL REFERENCES public.articles(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES public.tags(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    PRIMARY KEY (article_id, tag_id)
);

-- Article revisions for version history
CREATE TABLE public.article_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    article_id UUID NOT NULL REFERENCES public.articles(id) ON DELETE CASCADE,
    editor_id UUID NOT NULL REFERENCES public.profiles(id),
    
    title VARCHAR(255),
    content TEXT,
    excerpt TEXT,
    
    change_summary TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- COMMENTS
-- ==========================================

CREATE TABLE public.comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Relationships
    article_id UUID NOT NULL REFERENCES public.articles(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
    
    -- Author (registered or guest)
    author_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    author_name TEXT,
    author_email TEXT,
    author_website TEXT,
    
    -- Content
    content TEXT NOT NULL,
    
    -- Moderation
    status comment_status DEFAULT 'pending',
    moderated_by UUID REFERENCES public.profiles(id),
    moderated_at TIMESTAMP WITH TIME ZONE,
    moderation_reason TEXT,
    
    -- Metadata
    ip_address INET,
    user_agent TEXT,
    
    -- Engagement
    likes_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- MEDIA ASSETS
-- ==========================================

CREATE TABLE public.media_assets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- File info
    original_filename VARCHAR(255) NOT NULL,
    storage_path TEXT NOT NULL,
    public_url TEXT NOT NULL,
    
    -- Metadata
    file_type media_type DEFAULT 'image',
    mime_type VARCHAR(100),
    file_size_bytes BIGINT,
    dimensions JSONB,
    
    -- Usage tracking
    uploaded_by UUID NOT NULL REFERENCES public.profiles(id),
    usage_count INTEGER DEFAULT 0,
    
    -- Alt text and captions
    alt_text TEXT,
    caption TEXT,
    
    -- Processing
    processing_status VARCHAR(50) DEFAULT 'completed',
    variants JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Link media to articles
CREATE TABLE public.article_media (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    article_id UUID NOT NULL REFERENCES public.articles(id) ON DELETE CASCADE,
    media_id UUID NOT NULL REFERENCES public.media_assets(id) ON DELETE CASCADE,
    
    context VARCHAR(50) DEFAULT 'content',
    sort_order INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- EMAIL SYSTEM (SendGrid Integration)
-- ==========================================

CREATE TABLE public.email_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    name VARCHAR(255) UNIQUE NOT NULL,
    subject_template TEXT NOT NULL,
    body_template_html TEXT NOT NULL,
    body_template_text TEXT,
    
    variables JSONB DEFAULT '[]'::jsonb,
    
    from_name VARCHAR(255),
    from_email VARCHAR(255),
    reply_to_email VARCHAR(255),
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE public.email_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    template_id UUID REFERENCES public.email_templates(id),
    
    to_email VARCHAR(255) NOT NULL,
    to_name VARCHAR(255),
    cc_emails JSONB DEFAULT '[]'::jsonb,
    bcc_emails JSONB DEFAULT '[]'::jsonb,
    
    subject TEXT NOT NULL,
    body_html TEXT,
    body_text TEXT,
    
    status email_status DEFAULT 'queued',
    provider_message_id VARCHAR(255),
    
    sent_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    opened_at TIMESTAMP WITH TIME ZONE,
    clicked_at TIMESTAMP WITH TIME ZONE,
    bounce_reason TEXT,
    
    metadata JSONB,
    ip_address INET,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE public.email_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email_log_id UUID REFERENCES public.email_logs(id),
    
    event_type VARCHAR(50) NOT NULL,
    provider_event_id VARCHAR(255),
    
    event_data JSONB,
    occurred_at TIMESTAMP WITH TIME ZONE NOT NULL,
    
    processed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- SITE SETTINGS
-- ==========================================

CREATE TABLE public.site_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    key VARCHAR(100) UNIQUE NOT NULL,
    value JSONB NOT NULL,
    data_type VARCHAR(50),
    
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    
    updated_by UUID REFERENCES public.profiles(id),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- ANALYTICS & AUDIT
-- ==========================================

CREATE TABLE public.page_views (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    viewable_type VARCHAR(50) NOT NULL,
    viewable_id UUID NOT NULL,
    
    user_id UUID REFERENCES public.profiles(id),
    session_id VARCHAR(255),
    ip_address INET,
    
    user_agent TEXT,
    referrer TEXT,
    url_path TEXT,
    
    viewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE public.audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    user_id UUID REFERENCES public.profiles(id),
    action VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID,
    
    old_values JSONB,
    new_values JSONB,
    
    ip_address INET,
    user_agent TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- INDEXES FOR PERFORMANCE
-- ==========================================

-- Profiles
CREATE INDEX idx_profiles_email ON public.profiles(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_profiles_role ON public.profiles(role);

-- Articles
CREATE INDEX idx_articles_slug ON public.articles(slug) WHERE deleted_at IS NULL;
CREATE INDEX idx_articles_status ON public.articles(status);
CREATE INDEX idx_articles_published ON public.articles(published_at DESC) WHERE status = 'published';
CREATE INDEX idx_articles_author ON public.articles(author_id);
CREATE INDEX idx_articles_category ON public.articles(category_id);
CREATE INDEX idx_articles_search ON public.articles USING gin(to_tsvector('english', title || ' ' || COALESCE(excerpt, '') || ' ' || COALESCE(content, '')));

-- Comments
CREATE INDEX idx_comments_article ON public.comments(article_id);
CREATE INDEX idx_comments_status ON public.comments(status);
CREATE INDEX idx_comments_parent ON public.comments(parent_id);

-- Media
CREATE INDEX idx_media_uploaded_by ON public.media_assets(uploaded_by);
CREATE INDEX idx_media_type ON public.media_assets(file_type);

-- Email logs
CREATE INDEX idx_email_logs_to ON public.email_logs(to_email);
CREATE INDEX idx_email_logs_status ON public.email_logs(status);
CREATE INDEX idx_email_logs_provider_id ON public.email_logs(provider_message_id);

-- Analytics
CREATE INDEX idx_page_views_viewable ON public.page_views(viewable_type, viewable_id);
CREATE INDEX idx_page_views_date ON public.page_views(viewed_at);

-- ==========================================
-- FUNCTIONS & TRIGGERS
-- ==========================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to all tables with updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON public.categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tags_updated_at BEFORE UPDATE ON public.tags FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_articles_updated_at BEFORE UPDATE ON public.articles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON public.comments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_media_assets_updated_at BEFORE UPDATE ON public.media_assets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_email_templates_updated_at BEFORE UPDATE ON public.email_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_email_logs_updated_at BEFORE UPDATE ON public.email_logs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_site_settings_updated_at BEFORE UPDATE ON public.site_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Increment tag usage count
CREATE OR REPLACE FUNCTION increment_tag_usage()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.tags SET usage_count = usage_count + 1 WHERE id = NEW.tag_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_increment_tag_usage
AFTER INSERT ON public.article_tags
FOR EACH ROW EXECUTE FUNCTION increment_tag_usage();

-- Decrement tag usage count
CREATE OR REPLACE FUNCTION decrement_tag_usage()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.tags SET usage_count = usage_count - 1 WHERE id = OLD.tag_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_decrement_tag_usage
AFTER DELETE ON public.article_tags
FOR EACH ROW EXECUTE FUNCTION decrement_tag_usage();

-- Auto-create profile on auth signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, email_verified, role)
    VALUES (
        NEW.id, 
        NEW.email,
        COALESCE(NEW.email_confirmed_at IS NOT NULL, false),
        COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'reader')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on signup (run this after setting up auth)
-- CREATE TRIGGER on_auth_user_created
-- AFTER INSERT ON auth.users
-- FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==========================================
-- VIEWS FOR CONVENIENCE
-- ==========================================

-- Published articles with author and category info
CREATE VIEW public.published_articles AS
SELECT 
    a.*,
    p.full_name as author_name,
    p.avatar_url as author_avatar,
    c.name as category_name,
    c.slug as category_slug,
    c.color_class as category_color,
    c.icon_class as category_icon,
    c.external_url as category_external_url
FROM public.articles a
LEFT JOIN public.profiles p ON a.author_id = p.id
LEFT JOIN public.categories c ON a.category_id = c.id
WHERE a.status = 'published' AND a.deleted_at IS NULL;

-- Article statistics
CREATE VIEW public.article_stats AS
SELECT 
    a.id,
    a.title,
    a.views,
    COUNT(DISTINCT c.id) as comments_count,
    COUNT(DISTINCT at.tag_id) as tags_count
FROM public.articles a
LEFT JOIN public.comments c ON a.id = c.article_id AND c.status = 'approved'
LEFT JOIN public.article_tags at ON a.id = at.article_id
WHERE a.deleted_at IS NULL
GROUP BY a.id, a.title, a.views;

-- ==========================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==========================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.article_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscribers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.media_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_keys ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can read their own, admins can read all
CREATE POLICY "Profiles are viewable by everyone" 
    ON public.profiles FOR SELECT 
    USING (true);

CREATE POLICY "Users can update own profile" 
    ON public.profiles FOR UPDATE 
    USING (auth.uid() = id);

CREATE POLICY "Admins can update any profile" 
    ON public.profiles FOR UPDATE 
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- Articles: Public can read published, authors can manage their own, admins/editors can manage all
CREATE POLICY "Anyone can read published articles" 
    ON public.articles FOR SELECT 
    USING (status = 'published' AND deleted_at IS NULL);

CREATE POLICY "Authors can view own articles" 
    ON public.articles FOR SELECT 
    USING (author_id = auth.uid());

CREATE POLICY "Admins/Editors can view all articles" 
    ON public.articles FOR SELECT 
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'editor')));

CREATE POLICY "Authors can insert articles" 
    ON public.articles FOR INSERT 
    WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Authors can update own articles" 
    ON public.articles FOR UPDATE 
    USING (author_id = auth.uid());

CREATE POLICY "Admins/Editors can update any article" 
    ON public.articles FOR UPDATE 
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'editor')));

CREATE POLICY "Authors can delete own articles" 
    ON public.articles FOR DELETE 
    USING (author_id = auth.uid());

CREATE POLICY "Admins/Editors can delete any article" 
    ON public.articles FOR DELETE 
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'editor')));

-- Article versions
CREATE POLICY "Admins/Editors can view all versions" 
    ON public.article_versions FOR SELECT 
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'editor')));

CREATE POLICY "Authors can view own article versions" 
    ON public.article_versions FOR SELECT 
    USING (editor_id = auth.uid() OR EXISTS (SELECT 1 FROM public.articles a WHERE a.id = article_id AND a.author_id = auth.uid()));

CREATE POLICY "Authors can insert article versions" 
    ON public.article_versions FOR INSERT 
    WITH CHECK (editor_id = auth.uid());

-- Comments
CREATE POLICY "Anyone can view approved comments" 
    ON public.comments FOR SELECT 
    USING (status = 'approved');

CREATE POLICY "Authors can view own comments" 
    ON public.comments FOR SELECT 
    USING (author_id = auth.uid());

CREATE POLICY "Anyone can insert comments" 
    ON public.comments FOR INSERT 
    WITH CHECK (
        (author_id = auth.uid() OR (author_name IS NOT NULL AND author_email IS NOT NULL))
        AND status = 'pending'
    );

CREATE POLICY "Admins/Editors can manage comments" 
    ON public.comments FOR ALL 
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'editor')));

-- Subscribers
CREATE POLICY "Public can join newsletter" 
    ON public.subscribers FOR INSERT 
    WITH CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

CREATE POLICY "Admins/Editors can manage subscribers" 
    ON public.subscribers FOR ALL 
    USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'editor')));

-- Media assets
CREATE POLICY "Users can view own media" 
    ON public.media_assets FOR SELECT 
    USING (uploaded_by = auth.uid());

CREATE POLICY "Public can view media" 
    ON public.media_assets FOR SELECT 
    USING (true);

CREATE POLICY "Users can upload media" 
    ON public.media_assets FOR INSERT 
    WITH CHECK (uploaded_by = auth.uid());

-- API Keys (users can only see their own)
CREATE POLICY "Users can view own API keys" 
    ON public.api_keys FOR SELECT 
    USING (user_id = auth.uid());

CREATE POLICY "Users can manage own API keys" 
    ON public.api_keys FOR ALL 
    USING (user_id = auth.uid());