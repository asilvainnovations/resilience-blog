import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase';

export async function GET(request: NextRequest) {
  // Handle OAuth callback from Supabase
  const requestUrl = new URL(request.url);
  const code = requestUrl.searchParams.get('code');
  const error = requestUrl.searchParams.get('error');
  const errorDescription = requestUrl.searchParams.get('error_description');

  if (error) {
    return NextResponse.redirect(
      `${requestUrl.origin}/?error=${encodeURIComponent(errorDescription || error)}`
    );
  }

  if (code) {
    const supabase = createClient();
    const { data, error: exchangeError } = await supabase.auth.exchangeCodeForSession(code);

    if (exchangeError) {
      return NextResponse.redirect(
        `${requestUrl.origin}/?error=${encodeURIComponent(exchangeError.message)}`
      );
    }

    // Set session cookie
    const response = NextResponse.redirect(`${requestUrl.origin}/app/page.js`);
    
    if (data.session) {
      response.cookies.set('auth-session', data.session.refresh_token, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'lax',
        maxAge: 60 * 60 * 24 * 7, // 7 days
        path: '/',
      });
    }

    return response;
  }

  return NextResponse.redirect(`${requestUrl.origin}/`);
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { type, email, password, metadata, access_token, refresh_token } = body;

    const supabase = createClient();

    // Handle email signup
    if (type === 'signup') {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: metadata,
          emailRedirectTo: `${request.headers.get('origin')}/app/auth/callback`,
        },
      });

      if (error) throw error;

      return NextResponse.json({
        message: 'Signup successful. Please check your email.',
        user: data.user,
      });
    }

    // Handle OAuth token exchange (from frontend)
    if (type === 'oauth_callback' && access_token) {
      const { data, error } = await supabase.auth.setSession({
        access_token,
        refresh_token: refresh_token || '',
      });

      if (error) throw error;

      return NextResponse.json({
        message: 'OAuth callback successful',
        session: data.session,
        user: data.user,
      });
    }

    return NextResponse.json(
      { message: 'Invalid request type' },
      { status: 400 }
    );

  } catch (error: any) {
    console.error('Callback error:', error);
    return NextResponse.json(
      { message: error.message || 'Operation failed' },
      { status: 500 }
    );
  }
}
