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
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const { data: profile } = await supabase.from('users').select('id, role').eq('auth_id', user.id).single()

    if (!profile || profile.role !== 'driver') {
      return new Response(JSON.stringify({ error: 'Forbidden: User is not a driver' }), { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const { trip_id, stop_id, student_id, event_type } = await req.json()
    const validEventTypes = ['arrived', 'picked_up', 'absent']

    if (!trip_id || !student_id || !event_type || !validEventTypes.includes(event_type)) {
      return new Response(JSON.stringify({ error: 'Missing or invalid parameters: `trip_id`, `student_id`, `event_type` are required.' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // Verify driver is assigned to this trip
    const { data: trip } = await supabase.from('trips').select('id').eq('id', trip_id).eq('driver_id', profile.id).single()
    if(!trip) {
        return new Response(JSON.stringify({ error: 'Forbidden: Driver is not assigned to this trip or trip not found.' }), { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // Insert the event
    const eventToInsert = {
      trip_id,
      stop_id: stop_id || null, // stop_id is optional
      student_id,
      event_type,
      meta: { created_by: 'driver' }
    }

    const { data: newEvent, error: insertError } = await supabase
      .from('events')
      .insert(eventToInsert)
      .select()
      .single()

    if (insertError) {
      throw insertError
    }

    // TODO: Trigger FCM push notification to the parent(s) of the student.
    // This would involve:
    // 1. Finding the parent user(s) for the student_id.
    // 2. Retrieving their FCM token(s) (which we need to add to the `users` table).
    // 3. Sending the notification via FCM.

    return new Response(JSON.stringify(newEvent), {
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
