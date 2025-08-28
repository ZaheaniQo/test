-- SQL Views for easier data access (v2.0)

-- 1. View for Admins/Supervisors to get a summary of today's trips
CREATE OR REPLACE VIEW public.admin_today_trips_v AS
SELECT
    t.id AS trip_id,
    t.status,
    r.name AS route_name,
    b.plate_number,
    p.display_name AS driver_name,
    t.started_at,
    t.finished_at,
    (SELECT count(*) FROM public.route_stops WHERE route_id = r.id) AS total_stops,
    (SELECT count(*) FROM public.events WHERE trip_id = t.id AND event_type = 'picked_up') AS stops_completed,
    t.organization_id
FROM
    public.trips t
JOIN
    public.routes r ON t.route_id = r.id
JOIN
    public.buses b ON t.bus_id = b.id
LEFT JOIN
    public.user_profiles p ON t.driver_id = p.user_id
WHERE
    t.trip_date = current_date;

COMMENT ON VIEW public.admin_today_trips_v IS 'Provides a daily summary of all trips for admins and supervisors.';


-- 2. View for Drivers to get their picklist for the active trip
-- This view shows the students, their stop sequence, and their attendance confirmation.
CREATE OR REPLACE VIEW public.driver_picklist_v AS
SELECT
    rs.sequence,
    c.full_name AS child_name,
    c.grade,
    ac.status AS attendance_status,
    t.id AS trip_id,
    t.driver_id
FROM
    public.trips t
JOIN
    public.route_stops rs ON t.route_id = rs.route_id
JOIN
    public.children c ON rs.child_id = c.id
LEFT JOIN
    public.attendance_confirmations ac ON c.id = ac.child_id AND t.trip_date = ac.trip_date
WHERE
    t.status = 'in_progress' -- Only show for the active trip
ORDER BY
    rs.sequence;

COMMENT ON VIEW public.driver_picklist_v IS 'Shows the ordered list of students for a driver''s currently active trip.';

SELECT 'Views created successfully.' as result;
