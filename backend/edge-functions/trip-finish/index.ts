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
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401,
      })
    }

    const { data: profile } = await supabase
      .from('users')
      .select('id, role')
      .eq('auth_id', user.id)
      .single()

    if (!profile || profile.role !== 'driver') {
      return new Response(JSON.stringify({ error: 'Forbidden: User is not a driver' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 403,
      })
    }

    const { trip_id } = await req.json()
    if (!trip_id) {
      return new Response(JSON.stringify({ error: '`trip_id` is required' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

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

    if (trip.driver_id !== profile.id) {
        return new Response(JSON.stringify({ error: 'Forbidden: Trip does not belong to this driver' }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 403,
        })
    }

    if (trip.status !== 'in_progress') {
      return new Response(JSON.stringify({ error: `Trip cannot be finished, status is '${trip.status}'` }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 409,
      })
    }

    const { data: updatedTrip, error: updateError } = await supabase
      .from('trips')
      .update({
        status: 'completed',
        finished_at: new Date().toISOString(),
      })
      .eq('id', trip_id)
      .select()
      .single()

    if (updateError) {
      throw updateError
    }

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
