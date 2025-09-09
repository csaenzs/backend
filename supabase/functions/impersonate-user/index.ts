import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    );

    // Get the authorization header from the request
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('No authorization header');
    }

    // Verify the current user is a superadmin
    const jwt = authHeader.replace('Bearer ', '');
    const { data: { user: currentUser }, error: userError } = await supabaseClient.auth.getUser(jwt);

    if (userError || !currentUser) {
      throw new Error('Invalid token');
    }

    // Check if user is superadmin
    if (currentUser.app_metadata?.role !== 'superadmin') {
      throw new Error('Insufficient permissions. Only superadmins can impersonate users.');
    }

    const { targetUserId } = await req.json();

    if (!targetUserId) {
      throw new Error('Target user ID is required');
    }

    // Get target user details
    const { data: targetUser, error: targetError } = await supabaseClient.auth.admin.getUserById(targetUserId);

    if (targetError || !targetUser.user) {
      throw new Error('Target user not found');
    }

    // Create a new session for the target user with impersonation metadata
    const { data: sessionData, error: sessionError } = await supabaseClient.auth.admin.generateLink({
      type: 'magiclink',
      email: targetUser.user.email!,
      options: {
        redirectTo: `${req.headers.get('origin')}/app`
      }
    });

    if (sessionError || !sessionData.properties?.access_token) {
      throw new Error('Failed to generate session for target user');
    }

    // Update the target user's metadata to mark as being impersonated
    await supabaseClient.auth.admin.updateUserById(targetUserId, {
      app_metadata: {
        ...targetUser.user.app_metadata,
        is_impersonating: true,
        impersonated_by: currentUser.id,
        impersonated_at: new Date().toISOString()
      }
    });

    // Create session object for the impersonated user
    const impersonatedSession = {
      access_token: sessionData.properties.access_token,
      refresh_token: sessionData.properties.refresh_token || '',
      token_type: 'bearer',
      expires_in: 3600,
      expires_at: Math.floor(Date.now() / 1000) + 3600,
      user: {
        ...targetUser.user,
        app_metadata: {
          ...targetUser.user.app_metadata,
          is_impersonating: true,
          impersonated_by: currentUser.id
        }
      }
    };

    return new Response(
      JSON.stringify({ 
        session: impersonatedSession,
        message: 'Impersonation started successfully'
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );

  } catch (error) {
    return new Response(
      JSON.stringify({ 
        error: error.message || 'An unexpected error occurred'
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    );
  }
});