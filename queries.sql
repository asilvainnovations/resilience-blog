-- ==========================================
-- COMMON OPERATIONS QUERIES
-- ==========================================

-- 1. FETCH POSTS BY TAG (with pagination)
-- Usage: Get all published posts tagged with 'resilience'
WITH tag_info AS (
    SELECT id FROM tags WHERE slug = 'resilience'
)
SELECT 
    p.id,
    p.title,
    p.slug,
    p.excerpt,
    p.featured_image_url,
    p.published_at,
    p.views,
    u.full_name as author_name,
    u.avatar_url as author_avatar,
    c.name as category_name,
    c.slug as category_slug,
    c.color_class as category_color
FROM posts p
JOIN post_tags pt ON p.id = pt.post_id
JOIN tag_info t ON pt.tag_id = t.id
LEFT JOIN users u ON p.author_id = u.id
LEFT JOIN categories c ON p.category_id = c.id
WHERE p.status = 'published' 
  AND p.deleted_at IS NULL
ORDER BY p.published_at DESC
LIMIT 9 OFFSET 0;

-- 2. FETCH COMMENTS BY POST (nested structure)
-- Usage: Get approved comments for a specific post
WITH RECURSIVE comment_tree AS (
    -- Base case: top-level comments
    SELECT 
        c.id,
        c.content,
        c.created_at,
        c.parent_id,
        c.user_id,
        c.guest_name,
        u.full_name as user_name,
        u.avatar_url as user_avatar,
        0 as depth,
        ARRAY[c.id] as path
    FROM comments c
    LEFT JOIN users u ON c.user_id = u.id
    WHERE c.post_id = 'POST_UUID_HERE'
      AND c.parent_id IS NULL
      AND c.status = 'approved'
    
    UNION ALL
    
    -- Recursive case: replies
    SELECT 
        c.id,
        c.content,
        c.created_at,
        c.parent_id,
        c.user_id,
        c.guest_name,
        u.full_name as user_name,
        u.avatar_url as user_avatar,
        ct.depth + 1,
        ct.path || c.id
    FROM comments c
    JOIN comment_tree ct ON c.parent_id = ct.id
    LEFT JOIN users u ON c.user_id = u.id
    WHERE c.status = 'approved'
)
SELECT * FROM comment_tree
ORDER BY path;

-- 3. USER AUTHENTICATION (with role check)
-- Usage: Validate login credentials
SELECT 
    u.id,
    u.email,
    u.full_name,
    u.role,
    u.avatar_url,
    u.preferences,
    u.last_sign_in_at,
    (u.locked_until IS NOT NULL AND u.locked_until > NOW()) as is_locked
FROM users u
WHERE u.email = 'user@example.com'
  AND u.deleted_at IS NULL;

-- Update last sign in
UPDATE users 
SET last_sign_in_at = NOW(), 
    failed_login_attempts = 0
WHERE id = 'USER_UUID';

-- 4. FULL-TEXT SEARCH POSTS
-- Usage: Search posts by title, excerpt, and content
SELECT 
    p.id,
    p.title,
    p.slug,
    p.excerpt,
    p.featured_image_url,
    ts_rank(
        to_tsvector('english', p.title || ' ' || COALESCE(p.excerpt, '') || ' ' || COALESCE(p.content, '')),
        plainto_tsquery('english', 'systems thinking')
    ) as relevance
FROM posts p
WHERE p.status = 'published'
  AND p.deleted_at IS NULL
  AND to_tsvector('english', p.title || ' ' || COALESCE(p.excerpt, '') || ' ' || COALESCE(p.content, '')) 
      @@ plainto_tsquery('english', 'systems thinking')
ORDER BY relevance DESC, p.published_at DESC
LIMIT 10;

-- 5. DASHBOARD STATISTICS
-- Usage: Get overview stats for admin dashboard
SELECT 
    (SELECT COUNT(*) FROM posts WHERE deleted_at IS NULL) as total_posts,
    (SELECT COUNT(*) FROM posts WHERE status = 'published' AND deleted_at IS NULL) as published_posts,
    (SELECT COUNT(*) FROM posts WHERE status = 'draft' AND deleted_at IS NULL) as draft_posts,
    (SELECT COUNT(*) FROM users WHERE deleted_at IS NULL) as total_users,
    (SELECT COUNT(*) FROM comments WHERE status = 'pending') as pending_comments,
    (SELECT COALESCE(SUM(views), 0) FROM posts WHERE deleted_at IS NULL) as total_views;

-- 6. CREATE POST WITH TAGS (transaction)
BEGIN;
    -- Insert post
    WITH new_post AS (
        INSERT INTO posts (
            title, slug, excerpt, content, author_id, 
            category_id, featured_image_url, status, published_at
        ) VALUES (
            'New Article Title',
            'new-article-slug',
            'Brief excerpt...',
            '<p>HTML content...</p>',
            'AUTHOR_UUID',
            'CATEGORY_UUID',
            'https://image.url.jpg',
            'published',
            NOW()
        )
        RETURNING id
    )
    -- Link tags
    INSERT INTO post_tags (post_id, tag_id)
    SELECT 
        new_post.id,
        t.id
    FROM new_post
    CROSS JOIN (SELECT id FROM tags WHERE slug IN ('tag1', 'tag2')) t;
COMMIT;

-- 7. UPDATE POST VIEW COUNT (atomic)
UPDATE posts 
SET views = views + 1 
WHERE id = 'POST_UUID'
RETURNING views;

-- 8. GET POSTS BY CATEGORY WITH AUTHOR INFO
SELECT 
    p.id,
    p.title,
    p.slug,
    p.excerpt,
    p.featured_image_url,
    p.published_at,
    p.views,
    json_build_object(
        'id', u.id,
        'name', u.full_name,
        'avatar', u.avatar_url
    ) as author,
    json_build_object(
        'id', c.id,
        'name', c.name,
        'color', c.color_class,
        'icon', c.icon_class
    ) as category,
    json_agg(
        DISTINCT jsonb_build_object(
            'id', t.id,
            'name', t.name,
            'slug', t.slug
        )
    ) FILTER (WHERE t.id IS NOT NULL) as tags
FROM posts p
LEFT JOIN users u ON p.author_id = u.id
LEFT JOIN categories c ON p.category_id = c.id
LEFT JOIN post_tags pt ON p.id = pt.post_id
LEFT JOIN tags t ON pt.tag_id = t.id
WHERE c.slug = 'strategic'
  AND p.status = 'published'
  AND p.deleted_at IS NULL
GROUP BY p.id, u.id, c.id
ORDER BY p.published_at DESC
LIMIT 9;

-- 9. EMAIL QUEUE PROCESSING
-- Usage: Get pending emails to send via SendGrid
SELECT 
    id,
    to_email,
    to_name,
    subject,
    body_html,
    body_text,
    metadata
FROM email_logs
WHERE status = 'queued'
  AND (scheduled_at IS NULL OR scheduled_at <= NOW())
ORDER BY created_at ASC
LIMIT 10;

-- Mark as sent
UPDATE email_logs 
SET status = 'sent', 
    sent_at = NOW(),
    provider_message_id = 'sendgrid_msg_id'
WHERE id = 'EMAIL_UUID';

-- 10. AUDIT LOG QUERY
-- Usage: Track changes to a specific post
SELECT 
    a.action,
    a.entity_type,
    a.old_values,
    a.new_values,
    a.created_at,
    u.full_name as performed_by
FROM audit_logs a
LEFT JOIN users u ON a.user_id = u.id
WHERE a.entity_type = 'post'
  AND a.entity_id = 'POST_UUID'
ORDER BY a.created_at DESC;
