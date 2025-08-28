-- Migration 001: Create attendance_confirmations table
-- This migration adds the ability to track daily student attendance confirmations from parents.

-- 1. Create a new ENUM type for the confirmation status
CREATE TYPE attendance_status AS ENUM ('confirmed', 'absent', 'no_response');

-- 2. Create the attendance_confirmations table
CREATE TABLE public.attendance_confirmations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    parent_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    trip_date DATE NOT NULL,
    status attendance_status NOT NULL DEFAULT 'no_response',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Ensure that there is only one confirmation per student per day
    CONSTRAINT unique_student_date_confirmation UNIQUE (student_id, trip_date)
);

-- 3. Add comments for clarity
COMMENT ON TABLE public.attendance_confirmations IS 'Stores daily attendance confirmations from parents.';
COMMENT ON COLUMN public.attendance_confirmations.status IS 'Status of the attendance confirmed by the parent. Defaults to "no_response".';

-- 4. Enable RLS for the new table
ALTER TABLE public.attendance_confirmations ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS policies for the new table
-- Admins have full access.
CREATE POLICY "Allow admin full access on attendance_confirmations"
    ON public.attendance_confirmations FOR ALL
    USING (get_my_role() = 'admin');

-- Parents can view and update confirmations for their own children.
CREATE POLICY "Allow parents to manage confirmations for their children"
    ON public.attendance_confirmations FOR ALL
    USING (parent_id = get_my_user_id())
    WITH CHECK (parent_id = get_my_user_id());

-- Drivers can read the confirmations for students on their assigned trips for the day.
CREATE POLICY "Allow drivers to read confirmations for their daily trips"
    ON public.attendance_confirmations FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM trips t
        JOIN route_stops rs ON t.route_id = rs.route_id
        WHERE t.driver_id = get_my_user_id()
          AND t.trip_date = attendance_confirmations.trip_date
          AND rs.student_id = attendance_confirmations.student_id
    ));

-- 6. Add an index for faster lookups
CREATE INDEX idx_attendance_confirmations_student_date ON public.attendance_confirmations (student_id, trip_date);

SELECT 'Migration 001 completed successfully.' as result;
