-- ==========================================
-- SEED DATA FOR TESTING
-- ==========================================

-- Categories (matching the HTML structure)
INSERT INTO categories (slug, name, short_name, description, color_class, icon_class, external_url, sort_order) VALUES
('strategic', 'Systems & Strategic Thinking', 'StratPlan Pro', 'Systems thinking methodologies and strategic planning tools for uncertain times', 'bg-sky-100 text-sky-800 dark:bg-sky-900 dark:text-sky-200', 'fa-chess', 'https://asilvainnovations.com/strat-planner-pro', 1),
('drr', 'DRR-CCA', 'DDRiVE-M', 'Disaster Risk Reduction and Climate Change Adaptation platform', 'bg-cyan-100 text-cyan-800 dark:bg-cyan-900 dark:text-cyan-200', 'fa-shield-halved', 'https://asilvainnovations.com/ddrive-m', 2),
('leadership', 'Real-Time Leadership', 'RTL', 'Emergency and Resilience Leadership Framework', 'bg-amber-100 text-amber-800 dark:bg-amber-900 dark:text-amber-200', 'fa-bolt', 'https://asilvainnovations.com/rtl', 3);

-- Tags
INSERT INTO tags (slug, name, description) VALUES
('systems-thinking', 'Systems Thinking', 'Holistic approach to analysis that focuses on the way system components interact'),
('resilience', 'Resilience', 'Ability to withstand and recover from difficulties'),
('climate-adaptation', 'Climate Adaptation', 'Adjustments in ecological, social, or economic systems in response to climate change'),
('disaster-risk', 'Disaster Risk', 'Potential loss of life, injury, or destroyed assets due to disasters'),
('strategy', 'Strategy', 'Plan of action designed to achieve long-term or overall aims'),
('foresight', 'Foresight', 'Ability to predict or the action of predicting future events'),
('leadership', 'Leadership', 'Action of leading a group or organization'),
('emergency-management', 'Emergency Management', 'Organization and management of resources for dealing with emergencies'),
('vuca', 'VUCA', 'Volatility, Uncertainty, Complexity, and Ambiguity'),
('innovation', 'Innovation', 'New methods, ideas, or products');

-- Admin user (password should be hashed by application)
INSERT INTO users (email, username, full_name, role, bio, preferences) VALUES
('admin@asilvainnovations.com', 'asilva', 'ASilva', 'admin', 'Systems thinker and resilience strategist', 
 '{"notifications": {"email": true, "push": false}, "theme": "system"}'::jsonb);

-- Sample posts
WITH admin_user AS (SELECT id FROM users WHERE username = 'asilva' LIMIT 1),
     drr_cat AS (SELECT id FROM categories WHERE slug = 'drr' LIMIT 1),
     strat_cat AS (SELECT id FROM categories WHERE slug = 'strategic' LIMIT 1)
     
INSERT INTO posts (title, slug, excerpt, content, author_id, category_id, status, published_at, featured_image_url, views, meta_title, meta_description)
SELECT 
    'Architecting Resilience: Systems Thinking in DRR-CCA',
    'architecting-resilience-systems-thinking-drr-cca',
    'How integrated systems approaches can transform disaster risk reduction and climate adaptation strategies.',
    '<h2>The Interconnected Nature of Risk</h2><p>Disaster Risk Reduction (DRR) and Climate Change Adaptation (CCA) are no longer siloed disciplines. Through the <strong>DDRiVE-M</strong> platform, we explore how systems thinking creates resilient communities.</p><p>Understanding the <a href="https://asilvainnovations.com/ddrive-m">feedback loops</a> between environmental, social, and economic systems is crucial for preventing systemic collapse.</p><img src="https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=1200&q=80" alt="Resilience"><h3>Key Frameworks</h3><ul><li>Multi-hazard detection</li><li>Vulnerability mapping</li><li>Adaptive capacity building</li></ul>',
    admin_user.id,
    drr_cat.id,
    'published',
    '2026-03-01',
    'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=1200&q=80',
    1240,
    'Architecting Resilience: Systems Thinking in DRR-CCA | ASilva Innovations',
    'Explore how integrated systems approaches transform disaster risk reduction and climate adaptation strategies.'
FROM admin_user, drr_cat;

WITH admin_user AS (SELECT id FROM users WHERE username = 'asilva' LIMIT 1),
     strat_cat AS (SELECT id FROM categories WHERE slug = 'strategic' LIMIT 1)
     
INSERT INTO posts (title, slug, excerpt, content, author_id, category_id, status, published_at, featured_image_url, views, meta_title, meta_description)
SELECT 
    'Strat Planner Pro: Strategic Foresight in Uncertain Times',
    'strat-planner-pro-strategic-foresight',
    'Leveraging systems thinking methodologies to anticipate disruptions and build robust strategic plans.',
    '<h2>Beyond Traditional Planning</h2><p>Traditional strategic planning fails in VUCA environments. <strong>StratPlan Pro</strong> introduces dynamic scenario modeling and AI-supported strategic options generation.</p><blockquote>"The best way to predict the future is to create it with systems thinking."</blockquote><p>Our platform enables structured strategy mapping with balanced scorecard integration.</p>',
    admin_user.id,
    strat_cat.id,
    'published',
    '2026-02-28',
    'https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=1200&q=80',
    1850,
    'Strat Planner Pro: Strategic Foresight | ASilva Innovations',
    'Leverage systems thinking methodologies to anticipate disruptions and build robust strategic plans.'
FROM admin_user, strat_cat;

-- Link posts to tags
WITH post1 AS (SELECT id FROM posts WHERE slug = 'architecting-resilience-systems-thinking-drr-cca' LIMIT 1),
     post2 AS (SELECT id FROM posts WHERE slug = 'strat-planner-pro-strategic-foresight' LIMIT 1),
     tag_systems AS (SELECT id FROM tags WHERE slug = 'systems-thinking' LIMIT 1),
     tag_resilience AS (SELECT id FROM tags WHERE slug = 'resilience' LIMIT 1),
     tag_climate AS (SELECT id FROM tags WHERE slug = 'climate-adaptation' LIMIT 1),
     tag_strategy AS (SELECT id FROM tags WHERE slug = 'strategy' LIMIT 1),
     tag_foresight AS (SELECT id FROM tags WHERE slug = 'foresight' LIMIT 1)
     
INSERT INTO post_tags (post_id, tag_id)
SELECT post1.id, tag_systems.id FROM post1, tag_systems
UNION ALL SELECT post1.id, tag_resilience.id FROM post1, tag_resilience
UNION ALL SELECT post1.id, tag_climate.id FROM post1, tag_climate
UNION ALL SELECT post2.id, tag_strategy.id FROM post2, tag_strategy
UNION ALL SELECT post2.id, tag_foresight.id FROM post2, tag_foresight
UNION ALL SELECT post2.id, tag_systems.id FROM post2, tag_systems;

-- Sample comments
WITH post1 AS (SELECT id FROM posts WHERE slug = 'architecting-resilience-systems-thinking-drr-cca' LIMIT 1)
INSERT INTO comments (post_id, guest_name, guest_email, content, status, created_at)
SELECT 
    post1.id,
    'Maria Santos',
    'maria@example.com',
    'This is exactly what our LGU needs. The systems approach to DRR is revolutionary.',
    'approved',
    NOW() - INTERVAL '2 days'
FROM post1;

-- Site settings
INSERT INTO site_settings (key, value, data_type, description, is_public) VALUES
('site_name', '"ASilva Innovations"', 'string', 'Website name', true),
('site_description', '"Building Resilient Communities Through Technology"', 'string', 'Meta description', true),
('site_logo_url', '"https://asilvainnovations.com/assets/apps/user_1097/app_13212/draft/icon/app_logo.png"', 'string', 'Logo URL', true),
('seo_default_image', '"https://asilvainnovations.com/assets/og-image.jpg"', 'string', 'Default OG image', true),
('posts_per_page', '9', 'number', 'Number of posts per page', true),
('comments_moderation', 'true', 'boolean', 'Require approval for comments', false),
('email_from_name', '"ASilva Innovations"', 'string', 'Default sender name', false),
('email_from_address', '"noreply@asilvainnovations.com"', 'string', 'Default sender email', false),
('theme_primary_color', '"#0284c7"', 'string', 'Primary brand color', true),
('analytics_google_id', 'null', 'string', 'Google Analytics ID', false);

-- Email templates
INSERT INTO email_templates (name, subject_template, body_template_html, from_name, from_email, variables) VALUES
('welcome_user', 
 'Welcome to {{site_name}} - Start Building Resilience', 
 '<html><body><h1>Welcome {{user_name}}!</h1><p>Thank you for joining {{site_name}}. Start exploring insights on systems thinking and resilience.</p><a href="{{site_url}}/blog" style="background:#0284c7;color:white;padding:12px 24px;text-decoration:none;border-radius:6px;">Explore Insights</a></body></html>',
 'ASilva Innovations',
 'noreply@asilvainnovations.com',
 '["site_name", "user_name", "site_url"]'),

('new_comment_notification',
 'New comment on "{{post_title}}"',
 '<html><body><p>Hello {{author_name}},</p><p>A new comment has been posted on your article "{{post_title}}":</p><blockquote>{{comment_content}}</blockquote><p><a href="{{post_url}}">View and respond</a></p></body></html>',
 'ASilva Innovations',
 'noreply@asilvainnovations.com',
 '["author_name", "post_title", "comment_content", "post_url"]'),

('post_published',
 'Your article "{{post_title}}" is now live!',
 '<html><body><h1>Congratulations {{author_name}}!</h1><p>Your article "{{post_title}}" has been published and is now live on {{site_name}}.</p><p><a href="{{post_url}}" style="background:#0284c7;color:white;padding:12px 24px;text-decoration:none;border-radius:6px;">View Article</a></p></body></html>',
 'ASilva Innovations',
 'noreply@asilvainnovations.com',
 '["author_name", "post_title", "site_name", "post_url"]');
