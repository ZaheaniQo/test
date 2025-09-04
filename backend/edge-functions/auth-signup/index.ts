import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.0.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Note: This function uses the SERVICE_ROLE_KEY to create a user and set claims.
    // It should be treated as highly sensitive.
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 1. Validate input
    const { email, password, invitation_token, display_name, phone } = await req.json()
    if (!email || !password || !invitation_token || !display_name) {
      return new Response(JSON.stringify({ error: '`email`, `password`, `invitation_token`, and `display_name` are required.' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // 2. Create the user in auth.users
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: email,
      password: password,
      email_confirm: true, // Auto-confirm email for simplicity in this flow
    })

    if (authError) {
      return new Response(JSON.stringify({ error: `Auth error: ${authError.message}` }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }
    const newUser = authData.user;
    if (!newUser) {
        throw new Error("User creation failed unexpectedly.");
    }

    // 3. Call the PostgreSQL function to handle the rest of the signup logic in a transaction
    const { error: rpcError } = await supabaseAdmin.rpc('handle_new_user_signup', {
        invitation_token_input: invitation_token,
        new_user_id: newUser.id,
        display_name_input: display_name,
        phone_input: phone || null
    })

    if (rpcError) {
        // If the RPC function fails, we should delete the user we just created to clean up.
        await supabaseAdmin.auth.admin.deleteUser(newUser.id);
        return new Response(JSON.stringify({ error: `Signup failed: ${rpcError.message}` }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // 4. Return success
    // The user can now log in with their email and password.
    return new Response(JSON.stringify({ success: true, user_id: newUser.id }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 201, // Created
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
