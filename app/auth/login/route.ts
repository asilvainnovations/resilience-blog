import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { email, password, provider, type, rememberMe } = body;

    const supabase = createClient();

    // Handle OAuth initiation
    if (type === 'oauth' && provider) {
      const { data, error } = await supabase.auth.signInWithOAuth({
        provider,
        options: {
          redirectTo: `${request.headers.get('origin')}/app/auth/callback`,
        },
      });

      if (error) throw error;

      return NextResponse.json({ url: data.url });
    }

    // Handle email/password login
    if (!email || !password) {
      return NextResponse.json(
        { message: 'Email and password are required' },
        { status: 400 }
      );
    }

    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) throw error;

    // Set session cookie if remember me
    const response = NextResponse.json({
      message: 'Login successful',
      session: data.session,
      user: data.user,
    });

    if (rememberMe && data.session) {
      response.cookies.set('auth-session', data.session.refresh_token, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'lax',
        maxAge: 60 * 60 * 24 * 30, // 30 days
        path: '/',
      });
    }

    return response;

  } catch (error: any) {
    console.error('Login error:', error);
    return NextResponse.json(
      { message: error.message || 'Authentication failed' },
      { status: 401 }
    );
  }
}
