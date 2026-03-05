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

-- ==========================================
-- USERS & AUTHENTICATION
-- ==========================================

-- Main users table (works with Supabase Auth)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- Supabase Auth integration fields
    auth_id UUID UNIQUE, -- Links to supabase auth.users
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
    
    -- Preferences
    preferences JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE -- Soft delete
);

-- API Keys for external integrations (OpenAI, SendGrid, etc.)
CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    service_name VARCHAR(50) NOT NULL, -- 'openai', 'sendgrid', 'stripe', etc.
    key_name VARCHAR(100),
    encrypted_key TEXT NOT NULL, -- Encrypted at application level
    key_prefix VARCHAR(10), -- Last 4 chars for identification
    
    permissions JSONB DEFAULT '[]', -- Array of allowed operations
    rate_limit INTEGER DEFAULT 1000, -- Requests per hour
    last_used_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT unique_active_key_per_service UNIQUE (user_id, service_name, is_active) 
    WHERE is_active = TRUE
);

-- User sessions for tracking
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    ip_address INET,
    user_agent TEXT,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- CATEGORIES & TAGS
-- ==========================================

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    short_name VARCHAR(50),
    description TEXT,
    
    -- Styling (matches HTML structure)
    color_class VARCHAR(100), -- e.g., 'bg-sky-100 text-sky-800'
    icon_class VARCHAR(50), -- e.g., 'fa-chess'
    
    -- External links
    external_url TEXT,
    
    -- SEO
    meta_title VARCHAR(255),
    meta_description TEXT,
    
    -- Hierarchy
    parent_id UUID REFERENCES categories(id),
    sort_order INTEGER DEFAULT 0,
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    
    -- SEO
    meta_title VARCHAR(255),
    meta_description TEXT,
    
    usage_count INTEGER DEFAULT 0, -- Cached count for performance
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- POSTS (BLOG ARTICLES)
-- ==========================================

CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Content
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    excerpt TEXT, -- Brief summary
    content TEXT NOT NULL, -- HTML content from rich editor
    
    -- Relationships
    author_id UUID NOT NULL REFERENCES users(id),
    category_id UUID REFERENCES categories(id),
    
    -- Media
    featured_image_url TEXT,
    featured_image_alt TEXT,
    
    -- Publishing
    status post_status DEFAULT 'draft',
    published_at TIMESTAMP WITH TIME ZONE,
    scheduled_publish_at TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    views INTEGER DEFAULT 0,
    read_time_minutes INTEGER, -- Calculated or manual
    
    -- SEO
    meta_title VARCHAR(255),
    meta_description TEXT,
    canonical_url TEXT,
    
    -- Versioning
    version INTEGER DEFAULT 1,
    previous_version_id UUID REFERENCES posts(id),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE -- Soft delete
);

-- Many-to-many: Posts <-> Tags
CREATE TABLE post_tags (
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    PRIMARY KEY (post_id, tag_id)
);

-- Post revisions for version history
CREATE TABLE post_revisions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    editor_id UUID NOT NULL REFERENCES users(id),
    
    title VARCHAR(255),
    content TEXT,
    excerpt TEXT,
    
    change_summary TEXT, -- Brief description of changes
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- COMMENTS
-- ==========================================

CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Relationships
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES comments(id), -- For nested replies
    
    -- Author (can be registered user or guest)
    user_id UUID REFERENCES users(id),
    guest_name VARCHAR(255),
    guest_email VARCHAR(255),
    guest_website VARCHAR(255),
    
    -- Content
    content TEXT NOT NULL,
    
    -- Moderation
    status comment_status DEFAULT 'pending',
    moderated_by UUID REFERENCES users(id),
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

CREATE TABLE media_assets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- File info
    original_filename VARCHAR(255) NOT NULL,
    storage_path TEXT NOT NULL, -- Path in storage bucket
    public_url TEXT NOT NULL,
    
    -- Metadata
    file_type media_type DEFAULT 'image',
    mime_type VARCHAR(100),
    file_size_bytes BIGINT,
    dimensions JSONB, -- {width: 1200, height: 800} for images
    
    -- Usage tracking
    uploaded_by UUID NOT NULL REFERENCES users(id),
    usage_count INTEGER DEFAULT 0, -- How many posts use this
    
    -- Alt text and captions
    alt_text TEXT,
    caption TEXT,
    
    -- Processing status
    processing_status VARCHAR(50) DEFAULT 'completed', -- 'uploading', 'processing', 'completed', 'failed'
    variants JSONB, -- Thumbnails, optimized versions: {thumbnail: 'url', medium: 'url'}
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Link media to posts (many-to-many with context)
CREATE TABLE post_media (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    media_id UUID NOT NULL REFERENCES media_assets(id) ON DELETE CASCADE,
    
    context VARCHAR(50), -- 'featured', 'content', 'gallery'
    sort_order INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- EMAIL SYSTEM (SendGrid Integration)
-- ==========================================

CREATE TABLE email_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    name VARCHAR(255) UNIQUE NOT NULL,
    subject_template TEXT NOT NULL,
    body_template_html TEXT NOT NULL,
    body_template_text TEXT,
    
    variables JSONB DEFAULT '[]', -- List of available template variables
    
    from_name VARCHAR(255),
    from_email VARCHAR(255),
    reply_to_email VARCHAR(255),
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE email_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Template reference (optional)
    template_id UUID REFERENCES email_templates(id),
    
    -- Recipients
    to_email VARCHAR(255) NOT NULL,
    to_name VARCHAR(255),
    cc_emails JSONB DEFAULT '[]',
    bcc_emails JSONB DEFAULT '[]',
    
    -- Content
    subject TEXT NOT NULL,
    body_html TEXT,
    body_text TEXT,
    
    -- Tracking
    status email_status DEFAULT 'queued',
    provider_message_id VARCHAR(255), -- SendGrid message ID
    
    -- Engagement tracking
    sent_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    opened_at TIMESTAMP WITH TIME ZONE,
    clicked_at TIMESTAMP WITH TIME ZONE,
    bounce_reason TEXT,
    
    -- Metadata
    metadata JSONB, -- Custom data for tracking (user_id, post_id, etc.)
    ip_address INET,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Email events webhook log (for SendGrid events)
CREATE TABLE email_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email_log_id UUID REFERENCES email_logs(id),
    
    event_type VARCHAR(50) NOT NULL, -- 'delivered', 'open', 'click', 'bounce', etc.
    provider_event_id VARCHAR(255),
    
    event_data JSONB, -- Raw event data from provider
    occurred_at TIMESTAMP WITH TIME ZONE NOT NULL,
    
    processed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- SITE SETTINGS
-- ==========================================

CREATE TABLE site_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    key VARCHAR(100) UNIQUE NOT NULL,
    value JSONB NOT NULL,
    data_type VARCHAR(50), -- 'string', 'number', 'boolean', 'json', 'array'
    
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE, -- Can be exposed to frontend
    
    updated_by UUID REFERENCES users(id),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- ANALYTICS & AUDIT
-- ==========================================

CREATE TABLE page_views (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- What was viewed
    viewable_type VARCHAR(50) NOT NULL, -- 'post', 'category', 'page'
    viewable_id UUID NOT NULL,
    
    -- Viewer info
    user_id UUID REFERENCES users(id),
    session_id VARCHAR(255),
    ip_address INET,
    
    -- Request details
    user_agent TEXT,
    referrer TEXT,
    url_path TEXT,
    
    -- Timing
    viewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    user_id UUID REFERENCES users(id),
    action VARCHAR(50) NOT NULL, -- 'create', 'update', 'delete', 'login', etc.
    entity_type VARCHAR(50) NOT NULL, -- 'post', 'user', 'comment', etc.
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

-- Users
CREATE INDEX idx_users_email ON users(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_auth_id ON users(auth_id);
CREATE INDEX idx_users_role ON users(role);

-- Posts
CREATE INDEX idx_posts_slug ON posts(slug) WHERE deleted_at IS NULL;
CREATE INDEX idx_posts_status ON posts(status);
CREATE INDEX idx_posts_published_at ON posts(published_at) WHERE status = 'published';
CREATE INDEX idx_posts_author ON posts(author_id);
CREATE INDEX idx_posts_category ON posts(category_id);
CREATE INDEX idx_posts_search ON posts USING gin(to_tsvector('english', title || ' ' || COALESCE(excerpt, '') || ' ' || COALESCE(content, '')));

-- Comments
CREATE INDEX idx_comments_post ON comments(post_id);
CREATE INDEX idx_comments_status ON comments(status);
CREATE INDEX idx_comments_parent ON comments(parent_id);

-- Media
CREATE INDEX idx_media_uploaded_by ON media_assets(uploaded_by);
CREATE INDEX idx_media_type ON media_assets(file_type);

-- Email logs
CREATE INDEX idx_email_logs_to ON email_logs(to_email);
CREATE INDEX idx_email_logs_status ON email_logs(status);
CREATE INDEX idx_email_logs_provider_id ON email_logs(provider_message_id);

-- Analytics
CREATE INDEX idx_page_views_viewable ON page_views(viewable_type, viewable_id);
CREATE INDEX idx_page_views_date ON page_views(viewed_at);

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
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tags_updated_at BEFORE UPDATE ON tags FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_media_assets_updated_at BEFORE UPDATE ON media_assets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_email_templates_updated_at BEFORE UPDATE ON email_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_email_logs_updated_at BEFORE UPDATE ON email_logs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_site_settings_updated_at BEFORE UPDATE ON site_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Increment tag usage count
CREATE OR REPLACE FUNCTION increment_tag_usage()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE tags SET usage_count = usage_count + 1 WHERE id = NEW.tag_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_increment_tag_usage
AFTER INSERT ON post_tags
FOR EACH ROW EXECUTE FUNCTION increment_tag_usage();

-- Decrement tag usage count
CREATE OR REPLACE FUNCTION decrement_tag_usage()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE tags SET usage_count = usage_count - 1 WHERE id = OLD.tag_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_decrement_tag_usage
AFTER DELETE ON post_tags
FOR EACH ROW EXECUTE FUNCTION decrement_tag_usage();

-- ==========================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==========================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE media_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;

-- Users: Users can read their own data, admins can read all
CREATE POLICY users_select_own ON users FOR SELECT
    USING (auth_id = current_setting('app.current_user_id')::UUID OR 
           EXISTS (SELECT 1 FROM users WHERE auth_id = current_setting('app.current_user_id')::UUID AND role = 'admin'));

-- Posts: Public can read published, authors can manage their own, admins/editors can manage all
CREATE POLICY posts_select_public ON posts FOR SELECT
    USING (status = 'published' AND deleted_at IS NULL OR 
           EXISTS (SELECT 1 FROM users WHERE auth_id = current_setting('app.current_user_id')::UUID AND role IN ('admin', 'editor')) OR
           author_id = (SELECT id FROM users WHERE auth_id = current_setting('app.current_user_id')::UUID));

CREATE POLICY posts_insert ON posts FOR INSERT
    WITH CHECK (EXISTS (SELECT 1 FROM users WHERE auth_id = current_setting('app.current_user_id')::UUID AND role IN ('admin', 'editor')));

CREATE POLICY posts_update_own ON posts FOR UPDATE
    USING (author_id = (SELECT id FROM users WHERE auth_id = current_setting('app.current_user_id')::UUID) OR
           EXISTS (SELECT 1 FROM users WHERE auth_id = current_setting('app.current_user_id')::UUID AND role = 'admin'));

-- Comments: Public can read approved, authors can manage their own
CREATE POLICY comments_select_public ON comments FOR SELECT
    USING (status = 'approved' OR 
           user_id = (SELECT id FROM users WHERE auth_id = current_setting('app.current_user_id')::UUID) OR
           EXISTS (SELECT 1 FROM users WHERE auth_id = current_setting('app.current_user_id')::UUID AND role IN ('admin', 'editor')));

-- ==========================================
-- VIEWS FOR CONVENIENCE
-- ==========================================

-- Published posts with author and category info
CREATE VIEW published_posts AS
SELECT 
    p.*,
    u.full_name as author_name,
    u.avatar_url as author_avatar,
    c.name as category_name,
    c.slug as category_slug,
    c.color_class as category_color,
    c.icon_class as category_icon
FROM posts p
LEFT JOIN users u ON p.author_id = u.id
LEFT JOIN categories c ON p.category_id = c.id
WHERE p.status = 'published' AND p.deleted_at IS NULL;

-- Post statistics
CREATE VIEW post_stats AS
SELECT 
    p.id,
    p.title,
    p.views,
    COUNT(DISTINCT c.id) as comments_count,
    COUNT(DISTINCT pt.tag_id) as tags_count
FROM posts p
LEFT JOIN comments c ON p.id = c.post_id AND c.status = 'approved'
LEFT JOIN post_tags pt ON p.id = pt.post_id
WHERE p.deleted_at IS NULL
GROUP BY p.id, p.title, p.views;
