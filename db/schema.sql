-- School Bus App Schema (v2.0 - Organization-centric)
-- This schema reflects the unified application architecture.

-- Extensions
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- CREATE EXTENSION IF NOT EXISTS "postgis";

-- Custom Types
CREATE TYPE user_role AS ENUM ('parent', 'driver', 'admin', 'bus_supervisor', 'general_supervisor');
CREATE TYPE trip_status AS ENUM ('scheduled', 'in_progress', 'completed', 'cancelled');
CREATE TYPE event_type AS ENUM ('approaching', 'arrived', 'picked_up', 'school_entered', 'absent');
CREATE TYPE attendance_status AS ENUM ('confirmed', 'absent', 'no_response');

-- Core Multi-tenancy Tables
CREATE TABLE public.organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.branches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- User and Auth Tables
CREATE TABLE public.user_profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES public.branches(id) ON DELETE SET NULL,
    role user_role NOT NULL,
    display_name TEXT,
    phone TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    role user_role NOT NULL,
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES public.branches(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'expired')),
    invited_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    token TEXT NOT NULL UNIQUE DEFAULT extensions.uuid_generate_v4()::text,
    expires_at TIMESTAMPTZ NOT NULL DEFAULT now() + interval '7 days',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Child and Guardian Tables
CREATE TABLE public.children (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    grade TEXT,
    photo_url TEXT,
    home_photo_url TEXT,
    home_lat DOUBLE PRECISION,
    home_lng DOUBLE PRECISION,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.child_guardians (
    child_id UUID NOT NULL REFERENCES public.children(id) ON DELETE CASCADE,
    guardian_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    PRIMARY KEY (child_id, guardian_id)
);

-- Core Operational Tables
CREATE TABLE public.buses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    driver_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL,
    plate_number TEXT NOT NULL,
    model TEXT,
    capacity INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.bus_supervisors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bus_id UUID NOT NULL REFERENCES public.buses(id) ON DELETE CASCADE,
    supervisor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT unique_bus_supervisor UNIQUE (bus_id)
);

CREATE TABLE public.routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    bus_id UUID REFERENCES public.buses(id) ON DELETE SET NULL,
    branch_id UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE, -- Route is for a specific school/branch
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.route_stops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
    child_id UUID REFERENCES public.children(id) ON DELETE CASCADE,
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    sequence INTEGER NOT NULL,
    eta TIME,
    UNIQUE (route_id, sequence),
    UNIQUE (route_id, child_id)
);

CREATE TABLE public.trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    route_id UUID NOT NULL REFERENCES public.routes(id),
    bus_id UUID NOT NULL REFERENCES public.buses(id),
    driver_id UUID NOT NULL REFERENCES auth.users(id),
    trip_date DATE NOT NULL DEFAULT current_date,
    status trip_status NOT NULL DEFAULT 'scheduled',
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    UNIQUE (route_id, trip_date)
);

-- Data and Event Tables
CREATE TABLE public.locations (
    id BIGSERIAL PRIMARY KEY,
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    bus_id UUID NOT NULL REFERENCES public.buses(id),
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    speed REAL,
    ts TIMESTAMPTZ NOT NULL
);

CREATE TABLE public.events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    child_id UUID REFERENCES public.children(id),
    stop_id UUID REFERENCES public.route_stops(id),
    event_type event_type NOT NULL,
    meta JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.attendance_confirmations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL REFERENCES public.children(id) ON DELETE CASCADE,
    guardian_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    trip_date DATE NOT NULL,
    status attendance_status NOT NULL DEFAULT 'no_response',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_child_date_confirmation UNIQUE (child_id, trip_date)
);

CREATE TABLE public.chats (
    id BIGSERIAL PRIMARY KEY,
    trip_id UUID REFERENCES public.trips(id) ON DELETE SET NULL,
    sender_id UUID NOT NULL REFERENCES auth.users(id),
    recipient_id UUID NOT NULL REFERENCES auth.users(id),
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.settings (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    organization_id UUID REFERENCES public.organizations(id), -- Settings can be org-specific
    description TEXT
);
-- A unique constraint for global (NULL organization_id) or org-specific keys
ALTER TABLE public.settings ADD CONSTRAINT unique_key_org UNIQUE (key, organization_id);

-- Indexes for performance
CREATE INDEX ON locations (trip_id, ts DESC);
CREATE INDEX ON events (trip_id);
CREATE INDEX ON chats (trip_id);
CREATE INDEX ON user_profiles (organization_id, role);
CREATE INDEX ON child_guardians (guardian_id, child_id);
CREATE INDEX ON route_stops (route_id);
CREATE INDEX ON trips (driver_id, trip_date);
CREATE INDEX ON trips (bus_id, trip_date);
CREATE INDEX ON attendance_confirmations (child_id, trip_date);
