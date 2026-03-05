// Supabase Client Configuration
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_KEY

export const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true
  },
  db: {
    schema: 'public'
  }
})

// Auth helpers
export const auth = {
  // Sign up with email/password
  signUp: async (email, password, metadata) => {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: metadata,
        emailRedirectTo: `${process.env.SITE_URL}/auth/callback`
      }
    })
    if (error) throw error
    
    // Create user profile in our users table
    if (data.user) {
      await supabase.from('users').insert({
        auth_id: data.user.id,
        email: data.user.email,
        full_name: metadata.full_name,
        role: 'reader' // Default role
      })
    }
    return data
  },

  // Sign in
  signIn: async (email, password) => {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    })
    if (error) throw error
    return data
  },

  // Get current user with profile
  getUser: async () => {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return null
    
    const { data: profile } = await supabase
      .from('users')
      .select('*')
      .eq('auth_id', user.id)
      .single()
    
    return { ...user, profile }
  },

  // Set role (admin only)
  setRole: async (userId, role) => {
    return await supabase
      .from('users')
      .update({ role })
      .eq('id', userId)
  },

  // Middleware to check roles
  requireRole: (roles) => async (req, res, next) => {
    const user = await auth.getUser()
    if (!user || !roles.includes(user.profile.role)) {
      return res.status(403).json({ error: 'Insufficient permissions' })
    }
    next()
  }
}

// Database helpers with RLS context
export const db = {
  // Set current user for RLS policies
  setUserContext: async (authId) => {
    await supabase.rpc('set_config', {
      parameter: 'app.current_user_id',
      value: authId
    })
  },

  // Posts
  posts: {
    list: async ({ status, category, tag, page = 1, limit = 9, search }) => {
      let query = supabase
        .from('published_posts')
        .select('*', { count: 'exact' })
      
      if (status) query = query.eq('status', status)
      if (category) query = query.eq('category_slug', category)
      if (tag) {
        query = query.contains('tags', [{ slug: tag }])
      }
      if (search) {
        query = query.or(`title.ilike.%${search}%,excerpt.ilike.%${search}%`)
      }
      
      const from = (page - 1) * limit
      const to = from + limit - 1
      
      const { data, error, count } = await query
        .order('published_at', { ascending: false })
        .range(from, to)
      
      return { data, error, pagination: {
        current_page: page,
        total_pages: Math.ceil(count / limit),
        total_items: count
      }}
    },

    getBySlug: async (slug) => {
      const { data, error } = await supabase
        .from('posts')
        .select(`
          *,
          author:author_id (*),
          category:category_id (*),
          tags:post_tags(tag:tag_id(*))
        `)
        .eq('slug', slug)
        .single()
      
      // Increment views
      if (data) {
        await supabase.rpc('increment_post_views', { post_id: data.id })
      }
      
      return { data, error }
    },

    create: async (postData, userId) => {
      const { data, error } = await supabase
        .from('posts')
        .insert({ ...postData, author_id: userId })
        .select()
        .single()
      
      // Handle tags
      if (data && postData.tags?.length > 0) {
        const tagLinks = postData.tags.map(tagId => ({
          post_id: data.id,
          tag_id: tagId
        }))
        await supabase.from('post_tags').insert(tagLinks)
      }
      
      return { data, error }
    }
  },

  // Comments
  comments: {
    listByPost: async (postId, status = 'approved') => {
      const { data, error } = await supabase
        .from('comments')
        .select(`
          *,
          author:user_id (*),
          replies:comments!parent_id (*)
        `)
        .eq('post_id', postId)
        .eq('status', status)
        .is('parent_id', null)
        .order('created_at', { ascending: false })
      
      return { data, error }
    },

    create: async (commentData) => {
      return await supabase
        .from('comments')
        .insert(commentData)
        .select()
        .single()
    }
  }
}
