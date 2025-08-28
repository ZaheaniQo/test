import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.0.0'

// CORS headers for preflight requests and error responses
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle preflight OPTIONS request
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create a Supabase client with the service role key
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    // 1. Get user and check role
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401,
      })
    }

    // The user's role is now determined by JWT claims, but we can verify against the profile.
    const userRole = (await supabase.auth.getUser()).data.user?.app_metadata?.app_role;
    if (userRole !== 'driver') {
         return new Response(JSON.stringify({ error: 'Forbidden: User is not a driver' }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 403,
        });
    }

    // 2. Get and validate trip_id from request body
    const { trip_id } = await req.json()
    if (!trip_id) {
      return new Response(JSON.stringify({ error: '`trip_id` is required' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    // 3. Fetch the trip and verify ownership and status
    const { data: trip, error: tripError } = await supabase
      .from('trips')
      .select('id, driver_id, status')
      .eq('id', trip_id)
      .single()

    if (tripError || !trip) {
      return new Response(JSON.stringify({ error: 'Trip not found' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 404,
      })
    }

    if (trip.driver_id !== user.id) {
        return new Response(JSON.stringify({ error: 'Forbidden: Trip does not belong to this driver' }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 403,
        })
    }

    if (trip.status !== 'scheduled') {
      return new Response(JSON.stringify({ error: `Trip cannot be started, status is already '${trip.status}'` }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 409, // Conflict
      })
    }

    // 4. Update the trip status and start time
    const { data: updatedTrip, error: updateError } = await supabase
      .from('trips')
      .update({
        status: 'in_progress',
        started_at: new Date().toISOString(),
      })
      .eq('id', trip_id)
      .select()
      .single()

    if (updateError) {
      throw updateError
    }

    // 5. Return success response
    return new Response(JSON.stringify(updatedTrip), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
