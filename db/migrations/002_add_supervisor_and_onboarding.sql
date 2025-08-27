-- Migration 002: Add Supervisor Roles and Student Onboarding
-- This migration introduces new user roles and the necessary tables for student onboarding.

-- Use a transaction to ensure all changes are applied together.
BEGIN;

-- 1. Add new user roles to the existing ENUM
-- Note: This command cannot be run inside a transaction block in older PostgreSQL versions.
-- In Supabase (Postgres 14+), this is generally safe.
-- We add them one by one.
ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'bus_supervisor';
ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'general_supervisor';


-- 2. Create the bus_supervisors table
CREATE TABLE IF NOT EXISTS public.bus_supervisors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bus_id UUID NOT NULL REFERENCES public.buses(id) ON DELETE CASCADE,
    supervisor_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- A supervisor can be assigned to multiple buses, but a bus should have one main supervisor.
    -- If a bus can have multiple supervisors, this constraint should be removed.
    CONSTRAINT unique_bus_supervisor UNIQUE (bus_id),
    -- A supervisor can only be assigned to a bus once.
    CONSTRAINT unique_supervisor_assignment UNIQUE (supervisor_id, bus_id)
);
COMMENT ON TABLE public.bus_supervisors IS 'Links users with the bus_supervisor role to specific buses.';


-- 3. Create the students_onboarding_requests table
CREATE TABLE IF NOT EXISTS public.students_onboarding_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    student_data JSONB NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    reviewed_by UUID REFERENCES public.users(id), -- The admin/supervisor who reviewed it
    reviewed_at TIMESTAMPTZ
);
COMMENT ON TABLE public.students_onboarding_requests IS 'Stores student registration requests submitted by parents for review.';
COMMENT ON COLUMN public.students_onboarding_requests.student_data IS 'Contains all submitted student details: name, grade, photos, phone numbers etc.';


-- 4. Add new columns to the students table
ALTER TABLE public.students
    ADD COLUMN IF NOT EXISTS grade TEXT,
    ADD COLUMN IF NOT EXISTS photo_url TEXT,
    ADD COLUMN IF NOT EXISTS home_photo_url TEXT,
    ADD COLUMN IF NOT EXISTS father_phone TEXT,
    ADD COLUMN IF NOT EXISTS mother_phone TEXT;

COMMIT;

-- After the transaction, set up RLS for the new tables.
-- It's often safer to do this outside the main transaction.

-- Enable RLS for new tables
ALTER TABLE public.bus_supervisors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students_onboarding_requests ENABLE ROW LEVEL SECURITY;

-- RLS for bus_supervisors
CREATE POLICY "Allow admin and general supervisors to manage bus supervisors"
    ON public.bus_supervisors FOR ALL
    USING (get_my_role() IN ('admin', 'general_supervisor'));

CREATE POLICY "Allow bus supervisors to see their own assignments"
    ON public.bus_supervisors FOR SELECT
    USING (supervisor_id = get_my_user_id());

-- RLS for students_onboarding_requests
CREATE POLICY "Allow general supervisors and admins to manage onboarding requests"
    ON public.students_onboarding_requests FOR ALL
    USING (get_my_role() IN ('admin', 'general_supervisor'));

CREATE POLICY "Allow parents to create and view their own onboarding requests"
    ON public.students_onboarding_requests FOR ALL
    USING (parent_id = get_my_user_id())
    WITH CHECK (parent_id = get_my_user_id());


SELECT 'Migration 002 completed successfully.' as result;
