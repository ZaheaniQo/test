-- RLS Policies for Organization-centric Schema (v2.0)
-- These policies are designed for the new schema and rely on JWT custom claims.

-- Helper function to get a claim from the current user's JWT
CREATE OR REPLACE FUNCTION auth.get_my_claim(claim TEXT)
RETURNS JSONB AS $$
    SELECT coalesce(current_setting('request.jwt.claims', true)::jsonb->>claim, null)::jsonb;
$$ LANGUAGE sql STABLE;

-- Helper function to get the organization_id of the current user
CREATE OR REPLACE FUNCTION public.get_my_org_id()
RETURNS UUID AS $$
    SELECT (auth.get_my_claim('organization_id')->>0)::UUID;
$$ LANGUAGE sql STABLE;

-- Helper function to get the role of the current user
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT AS $$
    SELECT auth.get_my_claim('app_role')->>0;
$$ LANGUAGE sql STABLE;


--==============================================================
-- Enable RLS on all relevant tables
--==============================================================
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.children ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.child_guardians ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.buses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bus_supervisors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.route_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_confirmations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;

--==============================================================
-- RLS Policies
--==============================================================

-- -------------------------------------------------------------
-- Table: organizations & branches
-- -------------------------------------------------------------
-- Users can only see the organization they belong to.
CREATE POLICY "Allow users to see their own organization" ON public.organizations
    FOR SELECT USING (id = get_my_org_id());
CREATE POLICY "Allow users to see branches in their organization" ON public.branches
    FOR SELECT USING (organization_id = get_my_org_id());
-- Only admins can manage orgs/branches.
CREATE POLICY "Allow admins to manage organizations" ON public.organizations
    FOR ALL USING (get_my_role() = 'admin');
CREATE POLICY "Allow admins to manage branches" ON public.branches
    FOR ALL USING (get_my_role() = 'admin');


-- -------------------------------------------------------------
-- Table: user_profiles
-- -------------------------------------------------------------
-- Users can see their own profile.
CREATE POLICY "Allow users to see their own profile" ON public.user_profiles
    FOR SELECT USING (user_id = auth.uid());
-- Admins can see all profiles within their organization.
CREATE POLICY "Allow admins to see org profiles" ON public.user_profiles
    FOR SELECT USING (organization_id = get_my_org_id() AND get_my_role() = 'admin');


-- -------------------------------------------------------------
-- Table: children & child_guardians
-- -------------------------------------------------------------
-- Parents (guardians) can see their own children.
CREATE POLICY "Parents can see their own children" ON public.children
    FOR SELECT USING (id IN (SELECT child_id FROM public.child_guardians WHERE guardian_id = auth.uid()));
-- Admins/Supervisors can see all children in their organization.
CREATE POLICY "Admins and supervisors can see org children" ON public.children
    FOR SELECT USING (organization_id = get_my_org_id() AND get_my_role() IN ('admin', 'general_supervisor', 'bus_supervisor'));

-- For child_guardians junction table
CREATE POLICY "Parents can see their own guardian links" ON public.child_guardians
    FOR SELECT USING (guardian_id = auth.uid());
CREATE POLICY "Admins can manage guardian links in their org" ON public.child_guardians
    FOR ALL USING (
        get_my_role() = 'admin' AND
        EXISTS (SELECT 1 FROM children WHERE id = child_id AND organization_id = get_my_org_id())
    );


-- -------------------------------------------------------------
-- Table: trips
-- -------------------------------------------------------------
-- Users can only see trips within their own organization.
CREATE POLICY "Organization-level access for trips" ON public.trips
    FOR ALL USING (organization_id = get_my_org_id())
    WITH CHECK (organization_id = get_my_org_id());

-- Role-specific SELECT policies
CREATE POLICY "Parents can see their childrens trips" ON public.trips
    FOR SELECT USING (id IN (
        SELECT t.id FROM trips t
        JOIN route_stops rs ON t.route_id = rs.route_id
        JOIN child_guardians cg ON rs.child_id = cg.child_id
        WHERE cg.guardian_id = auth.uid()
    ));

CREATE POLICY "Drivers can see their own trips" ON public.trips
    FOR SELECT USING (driver_id = auth.uid());

CREATE POLICY "Bus supervisors can see their bus trips" ON public.trips
    FOR SELECT USING (bus_id IN (
        SELECT b.id FROM buses b
        JOIN bus_supervisors bs ON b.id = bs.bus_id
        WHERE bs.supervisor_id = auth.uid()
    ));

-- Management is restricted to admins/supervisors
CREATE POLICY "Admins and supervisors can manage trips" ON public.trips
    FOR ALL USING (get_my_role() IN ('admin', 'general_supervisor'));

-- Note: More specific policies for INSERT/UPDATE/DELETE can be added if needed,
-- but the above provides a strong baseline.
-- For example, a driver should only be able to UPDATE the status of their OWN trip.
CREATE POLICY "Drivers can update their own trip status" ON public.trips
    FOR UPDATE USING (driver_id = auth.uid())
    WITH CHECK (driver_id = auth.uid());
