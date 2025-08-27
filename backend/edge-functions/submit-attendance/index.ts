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

    // 1. Get user and check if they are a parent
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const { data: profile } = await supabase.from('users').select('id, role').eq('auth_id', user.id).single()
    if (!profile || profile.role !== 'parent') {
      return new Response(JSON.stringify({ error: 'Forbidden: User is not a parent' }), { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // 2. Validate input
    const { student_id, date, status } = await req.json()
    if (!student_id || !date || !status || !['confirmed', 'absent'].includes(status)) {
      return new Response(JSON.stringify({ error: 'Missing or invalid parameters: `student_id`, `date`, and `status` are required.' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // 3. Verify parent is linked to the student (Security Check)
    const { data: link, error: linkError } = await supabase
      .from('parents_students')
      .select('parent_id')
      .eq('parent_id', profile.id)
      .eq('student_id', student_id)
      .single()

    if (linkError || !link) {
      return new Response(JSON.stringify({ error: 'Forbidden: You are not authorized to confirm attendance for this student.' }), { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // 4. Update the attendance confirmation record
    const { data: updatedRecord, error: updateError } = await supabase
      .from('attendance_confirmations')
      .update({
        status: status,
        updated_at: new Date().toISOString()
      })
      .eq('student_id', student_id)
      .eq('trip_date', date)
      .select()
      .single()

    if (updateError) {
        // This could happen if the record for that student/date doesn't exist yet.
        // We can either throw an error or create it on the fly.
        // For robustness, let's return a specific error.
        return new Response(JSON.stringify({ error: 'Record not found. Ensure the daily notification job has run.' }), { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    return new Response(JSON.stringify(updatedRecord), {
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
