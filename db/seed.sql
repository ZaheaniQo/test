-- School Bus App Seed Data
-- version 1.0

-- This script uses hardcoded UUIDs for consistency.
-- In a real-world scenario, you might use variables or functions to generate them.

-- Clear existing data (optional, for clean runs)
-- DELETE FROM users WHERE email LIKE '%@schoolbus.sa';
-- ... add more deletes if needed

-- 1. Create Settings
INSERT INTO public.settings (key, value, description) VALUES
('approach_radius_m', '{"value": 200}', 'Radius in meters to trigger the "approaching" notification.'),
('school_radius_m', '{"value": 120}', 'Default geofence radius in meters for schools.'),
('location_data_retention_days', '{"value": 14}', 'Number of days to keep granular location data.')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- 2. Create School
-- Using a fixed UUID for the school for predictability
DO $$
DECLARE
    school_id UUID := 'a8a5b4b0-3c1c-4e8d-8a2e-5c6a8b7c9d0e';
BEGIN
    INSERT INTO public.schools (id, name, lat, lng, radius_m) VALUES
    (school_id, 'مدارس الأفق', 24.7136, 46.6753, 120)
    ON CONFLICT(id) DO NOTHING;
END $$;


-- 3. Create Users (Driver, Parent)
-- We are not creating auth users here, only the public profiles.
-- The auth users would be created via Supabase Auth UI or API.
-- We assume the `auth_id`s are pre-existing.
DO $$
DECLARE
    driver_user_id UUID := 'b8b6c5c1-4d2d-5f9e-9b3f-6d7a9c8b0e1f';
    parent_user_id UUID := 'c9c7d6d2-5e3e-6a0f-0c4a-7e8b0d9c1f2a';
    -- Dummy auth UUIDs. Replace with actual auth.uid() from your test users.
    driver_auth_id UUID := 'd0d8e7e3-6f4f-7b1a-1d5b-8f9c1e0d2g3b';
    parent_auth_id UUID := 'e1e9f8f4-7a5a-8c2b-2e6c-9aa02f1e3h4c';
BEGIN
    -- Driver: أبو فهد
    INSERT INTO public.users (id, auth_id, role, full_name, phone_number) VALUES
    (driver_user_id, driver_auth_id, 'driver', 'أبو فهد', '+966501234567')
    ON CONFLICT(id) DO NOTHING;

    -- Parent: أم ليان ومازن (Mother of Layan and Mazen)
    INSERT INTO public.users (id, auth_id, role, full_name, phone_number) VALUES
    (parent_user_id, parent_auth_id, 'parent', 'أم ليان ومازن', '+966557654321')
    ON CONFLICT(id) DO NOTHING;

    -- General Supervisor: المشرف العام
    INSERT INTO public.users (id, role, full_name, phone_number) VALUES
    ('d3d4e5e6-f7f8-9a0b-1c2d-3e4f5a6b7c8d', 'general_supervisor', 'المشرف العام', '+966530001122')
    ON CONFLICT(id) DO NOTHING;

    -- Bus Supervisor: مشرف ١
    INSERT INTO public.users (id, role, full_name, phone_number) VALUES
    ('e4e5f6g7-h8i9-j0k1-l2m3-n4o5p6q7r8s9', 'bus_supervisor', 'مشرف ١', '+966541112233')
    ON CONFLICT(id) DO NOTHING;
END $$;


-- 4. Create Students and Link to Parent
DO $$
DECLARE
    school_id UUID := 'a8a5b4b0-3c1c-4e8d-8a2e-5c6a8b7c9d0e';
    parent_user_id UUID := 'c9c7d6d2-5e3e-6a0f-0c4a-7e8b0d9c1f2a';
    layan_id UUID := 'd1d8e7e3-6f4f-7b1a-1d5b-8f9c1e0d2g3b';
    mazen_id UUID := 'e2e9f8f4-7a5a-8c2b-2e6c-9aa02f1e3h4c';
BEGIN
    -- Student 1: ليان الزهراني
    INSERT INTO public.students (id, full_name, school_id, home_lat, home_lng) VALUES
    (layan_id, 'ليان الزهراني', school_id, 24.7236, 46.6853)
    ON CONFLICT(id) DO NOTHING;

    -- Student 2: مازن الزهراني
    INSERT INTO public.students (id, full_name, school_id, home_lat, home_lng) VALUES
    (mazen_id, 'مازن الزهراني', school_id, 24.7186, 46.6803)
    ON CONFLICT(id) DO NOTHING;

    -- Link students to parent
    INSERT INTO public.parents_students (parent_id, student_id) VALUES
    (parent_user_id, layan_id),
    (parent_user_id, mazen_id)
    ON CONFLICT(parent_id, student_id) DO NOTHING;
END $$;

-- 5. Create Bus and Assign to Driver
DO $$
DECLARE
    driver_user_id UUID := 'b8b6c5c1-4d2d-5f9e-9b3f-6d7a9c8b0e1f';
    bus_id UUID := 'f3fa0a0b-8b6b-9d3c-3f7d-0ab12c3d4e5f';
BEGIN
    -- Bus 1, assigned to a driver
    INSERT INTO public.buses (id, driver_id, plate_number, model) VALUES
    (bus_id, driver_user_id, 'ح ب أ-1234', 'Toyota Coaster')
    ON CONFLICT(id) DO NOTHING;

    -- Bus 2, spare bus, unassigned
    INSERT INTO public.buses (id, driver_id, plate_number, model) VALUES
    ('a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', NULL, 'ن ق ل-9876', 'Mercedes-Benz Sprinter')
    ON CONFLICT(id) DO NOTHING;
END $$;

-- 6. Create Route and Stops
DO $$
DECLARE
    school_id UUID := 'a8a5b4b0-3c1c-4e8d-8a2e-5c6a8b7c9d0e';
    bus_id UUID := 'f3fa0a0b-8b6b-9d3c-3f7d-0ab12c3d4e5f';
    layan_id UUID := 'd1d8e7e3-6f4f-7b1a-1d5b-8f9c1e0d2g3b';
    mazen_id UUID := 'e2e9f8f4-7a5a-8c2b-2e6c-9aa02f1e3h4c';
    morning_route_id UUID := 'a0a1b2b3-4c5d-6e7f-8a9b-0c1d2e3f4g5h';
BEGIN
    -- The Route
    INSERT INTO public.routes (id, name, bus_id, school_id) VALUES
    (morning_route_id, 'Morning Route - Al-Ofuq', bus_id, school_id)
    ON CONFLICT(id) DO NOTHING;

    -- Stop 1: Layan's home
    INSERT INTO public.route_stops (route_id, student_id, lat, lng, sequence, eta) VALUES
    (morning_route_id, layan_id, 24.7236, 46.6853, 1, '06:30:00')
    ON CONFLICT(route_id, sequence) DO NOTHING;

    -- Stop 2: Mazen's home
    INSERT INTO public.route_stops (route_id, student_id, lat, lng, sequence, eta) VALUES
    (morning_route_id, mazen_id, 24.7186, 46.6803, 2, '06:45:00')
    ON CONFLICT(route_id, sequence) DO NOTHING;
END $$;


-- 7. Create a Trip for Today
DO $$
DECLARE
    morning_route_id UUID := 'a0a1b2b3-4c5d-6e7f-8a9b-0c1d2e3f4g5h';
    bus_id UUID := 'f3fa0a0b-8b6b-9d3c-3f7d-0ab12c3d4e5f';
    driver_user_id UUID := 'b8b6c5c1-4d2d-5f9e-9b3f-6d7a9c8b0e1f';
BEGIN
    INSERT INTO public.trips (route_id, bus_id, driver_id, trip_date, status) VALUES
    (morning_route_id, bus_id, driver_user_id, current_date, 'scheduled')
    ON CONFLICT(route_id, trip_date) DO NOTHING;
END $$;

-- 8. Assign Supervisor to a Bus
DO $$
DECLARE
    bus_id UUID := 'f3fa0a0b-8b6b-9d3c-3f7d-0ab12c3d4e5f'; -- Bus 'ح ب أ-1234'
    supervisor_id UUID := 'e4e5f6g7-h8i9-j0k1-l2m3-n4o5p6q7r8s9'; -- User 'مشرف ١'
BEGIN
    INSERT INTO public.bus_supervisors (bus_id, supervisor_id) VALUES
    (bus_id, supervisor_id)
    ON CONFLICT(bus_id) DO NOTHING;
END $$;

-- 9. Create a sample Onboarding Request
DO $$
DECLARE
    parent_user_id UUID := 'c9c7d6d2-5e3e-6a0f-0c4a-7e8b0d9c1f2a'; -- Parent 'أم ليان ومازن'
BEGIN
    INSERT INTO public.students_onboarding_requests (parent_id, student_data, status) VALUES
    (parent_user_id, '{
        "full_name": "نورة",
        "grade": "1",
        "home_lat": 24.7300,
        "home_lng": 46.6900,
        "father_phone": "+966501231234",
        "mother_phone": "+966551231234"
    }', 'pending')
    ON CONFLICT(id) DO NOTHING;
END $$;


-- Seed script finished.
SELECT 'Seed data loaded successfully.' as result;
