-- School Bus App MVP Schema
-- version 1.0

-- Extensions
-- It's good practice to enable extensions in a separate script or via Supabase dashboard.
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- CREATE EXTENSION IF NOT EXISTS "postgis"; -- For advanced geo-queries

-- Custom Types
CREATE TYPE user_role AS ENUM ('parent', 'driver', 'admin', 'bus_supervisor', 'general_supervisor');
CREATE TYPE trip_status AS ENUM ('scheduled', 'in_progress', 'completed', 'cancelled');
CREATE TYPE event_type AS ENUM ('approaching', 'arrived', 'picked_up', 'school_entered', 'absent');

-- Tables

-- Users table to store basic user information. Links to Supabase Auth.
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_id UUID UNIQUE, -- Foreign key to auth.users(id)
    role user_role NOT NULL,
    full_name TEXT,
    phone_number TEXT UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE users IS 'Stores user profile information, linked to Supabase authentication.';
COMMENT ON COLUMN users.auth_id IS 'Link to the corresponding user in Supabase auth.users table.';

-- Schools table
CREATE TABLE schools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    radius_m INTEGER NOT NULL, -- Geofence radius for the school
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE schools IS 'Represents schools with their location and geofence radius.';

-- Students table
CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name TEXT NOT NULL,
    school_id UUID REFERENCES schools(id) ON DELETE SET NULL,
    home_lat DOUBLE PRECISION,
    home_lng DOUBLE PRECISION,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE students IS 'Stores information about each student.';

-- Junction table for many-to-many relationship between Parents and Students
CREATE TABLE parents_students (
    parent_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    PRIMARY KEY (parent_id, student_id)
);
COMMENT ON TABLE parents_students IS 'Links parents from the users table to their children in the students table.';

-- Buses table
CREATE TABLE buses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID UNIQUE REFERENCES users(id) ON DELETE SET NULL,
    plate_number TEXT NOT NULL UNIQUE,
    model TEXT,
    capacity INTEGER,
    created_at TIMESTAMTz NOT NULL DEFAULT now()
);
COMMENT ON TABLE buses IS 'Represents a bus, optionally assigned to a driver.';
COMMENT ON COLUMN buses.driver_id IS 'A bus can only be assigned to one driver at a time.';

-- Routes table
CREATE TABLE routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    bus_id UUID REFERENCES buses(id) ON DELETE SET NULL,
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE routes IS 'Defines a specific route, including a series of stops.';

-- Route stops table, defining the sequence of pickups
CREATE TABLE route_stops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    student_id UUID REFERENCES students(id) ON DELETE CASCADE, -- Each stop is for a student
    lat DOUBLE PRECISION NOT NULL, -- Denormalized from student's home for historical accuracy
    lng DOUBLE PRECISION NOT NULL,
    sequence INTEGER NOT NULL,
    eta TIME,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (route_id, sequence),
    UNIQUE (route_id, student_id) -- A student can only be a stop once per route
);
COMMENT ON TABLE route_stops IS 'Represents an individual stop along a route, usually a student''s home.';

-- Trips table to log each journey
CREATE TABLE trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID NOT NULL REFERENCES routes(id),
    bus_id UUID NOT NULL REFERENCES buses(id),
    driver_id UUID NOT NULL REFERENCES users(id),
    trip_date DATE NOT NULL DEFAULT current_date,
    status trip_status NOT NULL DEFAULT 'scheduled',
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    UNIQUE (route_id, trip_date)
);
COMMENT ON TABLE trips IS 'A specific instance of a route being executed on a given day.';

-- Locations table for granular bus location tracking
-- This table will be heavily written to.
CREATE TABLE locations (
    id BIGSERIAL PRIMARY KEY,
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    bus_id UUID NOT NULL REFERENCES buses(id),
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    speed REAL,
    ts TIMESTAMPTZ NOT NULL
);
-- Create a hyper-table for TimescaleDB if available, for performance.
-- SELECT create_hypertable('locations', 'ts');
COMMENT ON TABLE locations IS 'Stores time-series location data for buses during trips.';

-- Events table for geofence-triggered and manual events
CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    student_id UUID REFERENCES students(id), -- Nullable for school-wide events
    stop_id UUID REFERENCES route_stops(id), -- Nullable for non-stop related events
    event_type event_type NOT NULL,
    meta JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE events IS 'Logs significant events like geofence triggers or student pickups.';
COMMENT ON COLUMN events.meta IS 'Stores extra data, e.g., distance from stop when ''approaching'' event fired.';

-- Chat messages table
CREATE TABLE chats (
    id BIGSERIAL PRIMARY KEY,
    trip_id UUID REFERENCES trips(id) ON DELETE SET NULL,
    sender_id UUID NOT NULL REFERENCES users(id),
    recipient_id UUID NOT NULL REFERENCES users(id),
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE chats IS 'Stores chat messages between parents and drivers.';

-- Settings table for configurable values
CREATE TABLE settings (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ
);
COMMENT ON TABLE settings IS 'A key-value store for application-wide settings like geofence radii.';

-- Audit logs for tracking important actions
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    action TEXT NOT NULL,
    target_entity TEXT,
    target_id TEXT,
    details JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE audit_logs IS 'Records important actions performed by users for auditing purposes.';

-- Indexes for performance
CREATE INDEX ON locations (trip_id, ts DESC);
CREATE INDEX ON events (trip_id);
CREATE INDEX ON chats (trip_id);
CREATE INDEX ON users (role);
CREATE INDEX ON parents_students (student_id, parent_id);
CREATE INDEX ON route_stops (route_id);
CREATE INDEX ON trips (driver_id, trip_date);
CREATE INDEX ON trips (bus_id, trip_date);
