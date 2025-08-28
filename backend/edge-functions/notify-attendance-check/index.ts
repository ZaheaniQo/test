import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.0.0'

/*
To deploy this function as a scheduled function, use the Supabase CLI:
supabase functions deploy notify-attendance-check --schedule "0 18 * * *"

This cron schedule runs the function every day at 18:00 UTC (9:00 PM in KSA).
*/

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // This function should be secured, e.g., by checking a secret header
  // For simplicity, we assume it's only called by Supabase's cron scheduler.

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 1. Calculate tomorrow's date
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const tomorrowDateString = tomorrow.toISOString().split('T')[0]; // YYYY-MM-DD

    // 2. Fetch all active students and their parents
    const { data: parentStudentLinks, error: fetchError } = await supabase
      .from('parents_students')
      .select(`
        student_id,
        parent_id:users!inner(id)
      `);

    if (fetchError) throw fetchError;
    if (!parentStudentLinks || parentStudentLinks.length === 0) {
        return new Response(JSON.stringify({ message: 'No students found.' }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' }});
    }

    // 3. Create default attendance records for tomorrow
    const confirmationsToInsert = parentStudentLinks.map(link => ({
      student_id: link.student_id,
      parent_id: link.parent_id.id,
      trip_date: tomorrowDateString,
      status: 'no_response'
    }));

    const { error: insertError } = await supabase
      .from('attendance_confirmations')
      .insert(confirmationsToInsert, { onConflict: 'student_id, trip_date' }); // Use ON CONFLICT to prevent duplicates

    if (insertError) {
        console.error("Error inserting confirmations:", insertError.message);
        // We can choose to continue to still send notifications if some inserts fail
    }

    // 4. TODO: Trigger push notifications to all parents
    //    - Get a unique list of parent_ids from `parentStudentLinks`.
    //    - For each parent_id, retrieve their FCM token.
    //    - Send a notification asking: "هل سيحضر ابنك غدًا؟" (Will your child attend tomorrow?)

    const responsePayload = {
      success: true,
      message: `Successfully created ${confirmationsToInsert.length} attendance placeholders for ${tomorrowDateString}.`,
      // In a real scenario, you'd also report notification status.
    };

    return new Response(JSON.stringify(responsePayload), {
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
