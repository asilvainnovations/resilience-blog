import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase';

export async function POST(request: NextRequest) {
  try {
    const supabase = createClient();
    
    // Get current session
    const { data: { session } } = await supabase.auth.getSession();
    
    if (session) {
      await supabase.auth.signOut();
    }

    // Clear cookies
    const response = NextResponse.json({ message: 'Logged out successfully' });
    response.cookies.delete('auth-session');
    
    return response;

  } catch (error: any) {
    console.error('Logout error:', error);
    return NextResponse.json(
      { message: error.message || 'Logout failed' },
      { status: 500 }
    );
  }
}
