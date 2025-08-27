-- Migration 003: Create PostgreSQL function to approve onboarding requests
-- This function encapsulates the logic for approving a student request in a single transaction.

CREATE OR REPLACE FUNCTION public.approve_student_onboarding(
    request_id_input UUID,
    bus_id_input UUID,
    reviewer_id_input UUID
)
RETURNS TABLE (new_student_id UUID) -- Return the ID of the newly created student
LANGUAGE plpgsql
SECURITY DEFINER -- Run with the permissions of the function owner (postgres)
AS $$
DECLARE
    onboarding_req RECORD;
    student_info JSONB;
    created_student_id UUID;
    associated_route_id UUID;
BEGIN
    -- 1. Get the onboarding request and lock it for update
    SELECT * INTO onboarding_req
    FROM public.students_onboarding_requests
    WHERE id = request_id_input AND status = 'pending'
    FOR UPDATE;

    -- If no pending request found, raise an exception
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pending onboarding request not found for id %', request_id_input;
    END IF;

    -- 2. Extract student data
    student_info := onboarding_req.student_data;

    -- 3. Create the new student
    INSERT INTO public.students (full_name, school_id, home_lat, home_lng, grade, photo_url, home_photo_url, father_phone, mother_phone, created_at)
    VALUES (
        student_info->>'full_name',
        (student_info->>'school_id')::UUID,
        (student_info->>'home_lat')::DOUBLE PRECISION,
        (student_info->>'home_lng')::DOUBLE PRECISION,
        student_info->>'grade',
        student_info->>'photo_url',
        student_info->>'home_photo_url',
        student_info->>'father_phone',
        student_info->>'mother_phone',
        now()
    ) RETURNING id INTO created_student_id;

    -- 4. Assign student to the bus's route
    -- This is a simplified logic: it finds the first route for the given bus.
    SELECT id INTO associated_route_id
    FROM public.routes
    WHERE bus_id = bus_id_input
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No route found for bus id %', bus_id_input;
    END IF;

    -- Add student as a new stop on the route.
    -- We need to determine the next sequence number.
    INSERT INTO public.route_stops (route_id, student_id, lat, lng, sequence)
    SELECT
        associated_route_id,
        created_student_id,
        (student_info->>'home_lat')::DOUBLE PRECISION,
        (student_info->>'home_lng')::DOUBLE PRECISION,
        COALESCE(MAX(sequence), 0) + 1
    FROM public.route_stops
    WHERE route_id = associated_route_id;

    -- 5. Update the original request to 'approved'
    UPDATE public.students_onboarding_requests
    SET
        status = 'approved',
        reviewed_by = reviewer_id_input,
        reviewed_at = now()
    WHERE id = request_id_input;

    -- 6. Return the new student's ID
    new_student_id := created_student_id;
    RETURN QUERY SELECT new_student_id;

END;
$$;

SELECT 'Migration 003 completed successfully.' as result;
