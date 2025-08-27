-- School Bus App RLS Policies
-- version 1.0

-- Helper function to get the role of the current user
CREATE OR REPLACE FUNCTION get_my_role()
RETURNS TEXT AS $$
DECLARE
    role TEXT;
BEGIN
    SELECT raw_user_meta_data->>'role' INTO role
    FROM auth.users
    WHERE id = auth.uid();
    RETURN role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to get the user ID from our public users table
CREATE OR REPLACE FUNCTION get_my_user_id()
RETURNS UUID AS $$
DECLARE
    user_id UUID;
BEGIN
    SELECT id INTO user_id
    FROM public.users
    WHERE auth_id = auth.uid();
    RETURN user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


--==============================================================
-- Enable RLS on all tables
--==============================================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parents_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.buses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.route_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

--==============================================================
-- RLS Policies
--==============================================================

-- -------------------------------------------------------------
-- Table: users
-- -------------------------------------------------------------
-- Admins can do anything.
CREATE POLICY "Allow admin full access on users" ON public.users
    FOR ALL USING (get_my_role() = 'admin');
-- Users can view their own profile.
CREATE POLICY "Allow users to view their own profile" ON public.users
    FOR SELECT USING (auth_id = auth.uid());
-- Parents can see the driver of the bus their child is on today.
CREATE POLICY "Allow parents to see their child's driver" ON public.users
    FOR SELECT USING (
        get_my_role() = 'parent' AND
        role = 'driver' AND
        EXISTS (
            SELECT 1
            FROM trips t
            JOIN route_stops rs ON t.route_id = rs.route_id
            JOIN parents_students ps ON rs.student_id = ps.student_id
            WHERE t.driver_id = users.id
              AND ps.parent_id = get_my_user_id()
              AND t.trip_date = current_date
        )
    );

-- -------------------------------------------------------------
-- Table: students & parents_students
-- -------------------------------------------------------------
CREATE POLICY "Allow admin full access on students" ON public.students
    FOR ALL USING (get_my_role() = 'admin');
CREATE POLICY "Allow parents to see their own children" ON public.students
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM parents_students ps
        WHERE ps.student_id = students.id AND ps.parent_id = get_my_user_id()
    ));
-- Drivers can see students on the routes assigned to them.
CREATE POLICY "Allow drivers to see students on their routes" ON public.students
    FOR SELECT USING (
        get_my_role() = 'driver' AND
        EXISTS (
            SELECT 1 FROM route_stops rs
            JOIN routes r ON rs.route_id = r.id
            JOIN buses b ON r.bus_id = b.id
            WHERE rs.student_id = students.id AND b.driver_id = get_my_user_id()
        )
    );
CREATE POLICY "Allow admin full access on parents_students" ON public.parents_students
    FOR ALL USING (get_my_role() = 'admin');
CREATE POLICY "Allow parents to see their own links" ON public.parents_students
    FOR SELECT USING (parent_id = get_my_user_id());


-- -------------------------------------------------------------
-- Table: schools
-- -------------------------------------------------------------
CREATE POLICY "Allow admin full access on schools" ON public.schools
    FOR ALL USING (get_my_role() = 'admin');
-- Any authenticated user can see the list of schools.
CREATE POLICY "Allow authenticated users to view schools" ON public.schools
    FOR SELECT USING (auth.role() = 'authenticated');

-- -------------------------------------------------------------
-- Table: buses
-- -------------------------------------------------------------
CREATE POLICY "Allow admin and general supervisors to manage buses" ON public.buses
    FOR ALL USING (get_my_role() IN ('admin', 'general_supervisor'));
CREATE POLICY "Allow authenticated users to view buses" ON public.buses
    FOR SELECT USING (auth.role() = 'authenticated');


-- -------------------------------------------------------------
-- Table: trips, routes, route_stops, locations
-- Table: routes & route_stops (Assignments)
-- -------------------------------------------------------------
-- Only General Supervisors and Admins can create, update, or delete routes and stops.
CREATE POLICY "Allow high-level users to manage routes" ON public.routes
    FOR ALL USING (get_my_role() IN ('admin', 'general_supervisor'));
CREATE POLICY "Allow high-level users to manage route stops" ON public.route_stops
    FOR ALL USING (get_my_role() IN ('admin', 'general_supervisor'));

-- Drivers, Parents, and Supervisors need read access.
CREATE POLICY "Allow drivers to see their assigned routes" ON public.routes
    FOR SELECT USING (bus_id IN (SELECT id FROM buses WHERE driver_id = get_my_user_id()));
CREATE POLICY "Allow drivers to see stops on their routes" ON public.route_stops
    FOR SELECT USING (route_id IN (SELECT id FROM routes WHERE bus_id IN (SELECT id FROM buses WHERE driver_id = get_my_user_id())));

CREATE POLICY "Allow bus supervisors to see their bus routes" ON public.routes
    FOR SELECT USING (bus_id IN (SELECT bus_id FROM bus_supervisors WHERE supervisor_id = get_my_user_id()));
CREATE POLICY "Allow bus supervisors to see stops on their bus routes" ON public.route_stops
    FOR SELECT USING (route_id IN (SELECT id FROM routes WHERE bus_id IN (SELECT bus_id FROM bus_supervisors WHERE supervisor_id = get_my_user_id())));

CREATE POLICY "Allow parents to see their child's route information" ON public.routes
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM route_stops rs
        JOIN parents_students ps ON ps.student_id = rs.student_id
        WHERE rs.route_id = routes.id AND ps.parent_id = get_my_user_id()
    ));

-- -------------------------------------------------------------
-- Table: trips & locations (Live Data)
-- -------------------------------------------------------------
CREATE POLICY "Allow admin full access on trips" ON public.trips FOR ALL USING (get_my_role() = 'admin');
CREATE POLICY "Allow admin full access on locations" ON public.locations FOR ALL USING (get_my_role() = 'admin');

-- Drivers can see their own trips and post locations.
CREATE POLICY "Allow drivers to see their own trips" ON public.trips FOR SELECT USING (driver_id = get_my_user_id());
CREATE POLICY "Allow drivers to insert their location" ON public.locations FOR INSERT
    WITH CHECK (EXISTS (SELECT 1 FROM trips WHERE id = locations.trip_id AND driver_id = get_my_user_id()));

-- Parents and Supervisors can see live data for relevant trips.
CREATE POLICY "Allow parents to see their child's trip" ON public.trips
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM route_stops rs
        JOIN parents_students ps ON ps.student_id = rs.student_id
        WHERE rs.route_id = trips.route_id AND ps.parent_id = get_my_user_id()
    ));

CREATE POLICY "Allow parents to see location of their child's bus" ON public.locations
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM trips t
        JOIN route_stops rs ON t.route_id = rs.route_id
        JOIN parents_students ps ON ps.student_id = rs.student_id
        WHERE t.id = locations.trip_id AND ps.parent_id = get_my_user_id()
    ));

CREATE POLICY "Allow bus supervisors to see trips for their bus" ON public.trips
    FOR SELECT USING (bus_id IN (SELECT bus_id FROM bus_supervisors WHERE supervisor_id = get_my_user_id()));

CREATE POLICY "Allow bus supervisors to see locations for their bus" ON public.locations
    FOR SELECT USING (bus_id IN (SELECT bus_id FROM bus_supervisors WHERE supervisor_id = get_my_user_id()));

-- -------------------------------------------------------------
-- Table: events
-- -------------------------------------------------------------
CREATE POLICY "Allow admin full access on events" ON public.events
    FOR ALL USING (get_my_role() = 'admin');
-- Drivers can see all events for their trips.
CREATE POLICY "Allow drivers to see events on their trips" ON public.events
    FOR SELECT USING (trip_id IN (SELECT id FROM trips WHERE driver_id = get_my_user_id()));
-- Parents can only see events for their own children.
CREATE POLICY "Allow parents to see events for their children" ON public.events
    FOR SELECT USING (student_id IN (SELECT student_id FROM parents_students WHERE parent_id = get_my_user_id()));
-- Bus supervisors can see all events for their assigned bus's trips.
CREATE POLICY "Allow bus supervisors to see events on their bus trips" ON public.events
    FOR SELECT USING (trip_id IN (SELECT id FROM trips WHERE bus_id IN (SELECT bus_id FROM bus_supervisors WHERE supervisor_id = get_my_user_id())));


-- -------------------------------------------------------------
-- Table: chats
-- -------------------------------------------------------------
CREATE POLICY "Allow admin full access on chats" ON public.chats
    FOR ALL USING (get_my_role() = 'admin');
-- Users can see their own chats
CREATE POLICY "Allow users to access their own chats" ON public.chats
    FOR ALL USING (sender_id = get_my_user_id() OR recipient_id = get_my_user_id());


-- -------------------------------------------------------------
-- Table: settings and audit_logs (Admin only)
-- -------------------------------------------------------------
CREATE POLICY "Allow admin full access on settings" ON public.settings
    FOR ALL USING (get_my_role() = 'admin');
CREATE POLICY "Allow admin full access on audit_logs" ON public.audit_logs
    FOR ALL USING (get_my_role() = 'admin');
-- A more permissive policy could allow reading of non-sensitive keys
-- CREATE POLICY "Allow authenticated users to read some settings" ON public.settings
--     FOR SELECT USING (auth.role() = 'authenticated' AND value->>'is_sensitive' = 'false');
