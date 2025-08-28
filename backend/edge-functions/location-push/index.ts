import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.0.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Haversine distance function
function getDistanceInMeters(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371e3 // metres
  const φ1 = lat1 * Math.PI / 180 // φ, λ in radians
  const φ2 = lat2 * Math.PI / 180
  const Δφ = (lat2 - lat1) * Math.PI / 180
  const Δλ = (lon2 - lon1) * Math.PI / 180

  const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
            Math.cos(φ1) * Math.cos(φ2) *
            Math.sin(Δλ / 2) * Math.sin(Δλ / 2)
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

  return R * c // in metres
}

async function handleGeofencing(supabase: SupabaseClient, trip: any, currentLocation: any) {
    // 1. Get route stops and school details
    const { data: stops, error: stopsError } = await supabase
        .from('route_stops')
        .select('id, student_id, lat, lng, sequence')
        .eq('route_id', trip.route_id)
        .order('sequence', { ascending: true })

    if (stopsError || !stops) return;

    const { data: school } = await supabase
        .from('schools')
        .select('lat, lng, radius_m')
        .eq('id', trip.routes.school_id)
        .single();

    // 2. Get settings for geofence radius
    const { data: settings } = await supabase
        .from('settings')
        .select('value')
        .eq('key', 'approach_radius_m')
        .single();
    const approachRadius = settings?.value?.value || 200; // Default 200m

    // Find next stop
    // A simple approach: find the first stop for which 'picked_up' or 'absent' event does not exist.
    const { data: tripEvents } = await supabase.from('events').select('stop_id, event_type').eq('trip_id', trip.id);
    const completedStopIds = tripEvents?.filter(e => e.event_type === 'picked_up' || e.event_type === 'absent').map(e => e.stop_id) || [];
    const nextStop = stops.find(s => !completedStopIds.includes(s.id));

    // 3. Check proximity to the next stop
    if (nextStop) {
        const distanceToNextStop = getDistanceInMeters(currentLocation.lat, currentLocation.lng, nextStop.lat, nextStop.lng);
        if (distanceToNextStop <= approachRadius) {
            // Check if 'approaching' event was already sent for this stop
            const approachingEventExists = tripEvents?.some(e => e.stop_id === nextStop.id && e.event_type === 'approaching');
            if (!approachingEventExists) {
                await supabase.from('events').insert({
                    trip_id: trip.id,
                    stop_id: nextStop.id,
                    student_id: nextStop.student_id,
                    event_type: 'approaching',
                    meta: { distance: Math.round(distanceToNextStop) }
                });
                // TODO: Send FCM to parent
            }
        }
    }

    // 4. Check proximity to the school (final destination)
    if (school) {
        const distanceToSchool = getDistanceInMeters(currentLocation.lat, currentLocation.lng, school.lat, school.lng);
        if (distanceToSchool <= school.radius_m) {
            const schoolEventExists = tripEvents?.some(e => e.event_type === 'school_entered');
            if (!schoolEventExists) {
                 await supabase.from('events').insert({
                    trip_id: trip.id,
                    event_type: 'school_entered',
                    meta: { 'school_radius_m': school.radius_m }
                });
                // TODO: Send FCM to all parents on this trip
            }
        }
    }
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

    const { trip_id, location } = await req.json()
    if (!trip_id || !location || !location.lat || !location.lng) {
      return new Response(JSON.stringify({ error: '`trip_id` and `location` object are required.' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // Fetch trip details in one go
    const { data: trip, error: tripError } = await supabase
        .from('trips')
        .select(`
            id, bus_id, status, route_id,
            routes ( school_id )
        `)
        .eq('id', trip_id)
        .eq('status', 'in_progress')
        .single();

    if(tripError || !trip) {
        return new Response(JSON.stringify({ error: 'Active trip not found or access denied.' }), { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // Insert location data
    await supabase.from('locations').insert({
      trip_id,
      bus_id: trip.bus_id,
      lat: location.lat,
      lng: location.lng,
      speed: location.speed || 0,
      ts: new Date().toISOString(),
    })

    // Asynchronously handle geofencing logic without blocking the response
    handleGeofencing(supabase, trip, location).catch(err => console.error("Geofencing Error:", err));

    return new Response(JSON.stringify({ success: true, message: 'Location received' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 202, // Accepted
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
