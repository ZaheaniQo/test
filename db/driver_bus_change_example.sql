-- Example Script: Handling a Driver Bus Change
-- This script is for illustrative purposes and is not meant to be run as a migration.
-- It demonstrates the steps an admin would take to switch a driver to a different bus.

-- SCENARIO:
-- Driver 'أبو فهد' (Abu Fahad) needs to switch from his usual bus ('ح ب أ-1234')
-- to the spare bus ('ن ق ل-9876') for today's trip.

-- Step 0: Identify the relevant UUIDs (these are from seed.sql)
-- Driver ID ('أبو فهد'): 'b8b6c5c1-4d2d-5f9e-9b3f-6d7a9c8b0e1f'
-- Old Bus ID ('ح ب أ-1234'): 'f3fa0a0b-8b6b-9d3c-3f7d-0ab12c3d4e5f'
-- New Bus ID ('ن ق ل-9876'): 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d'
-- Route ID ('Morning Route - Al-Ofuq'): 'a0a1b2b3-4c5d-6e7f-8a9b-0c1d2e3f4g5h'

-- It's best to wrap these changes in a transaction to ensure atomicity.
BEGIN;

-- Step 1: Un-assign the driver from the old bus.
-- This makes the old bus available.
UPDATE public.buses
SET driver_id = NULL
WHERE id = 'f3fa0a0b-8b6b-9d3c-3f7d-0ab12c3d4e5f';

-- Step 2: Assign the driver to the new bus.
-- The driver is now officially linked to the new bus.
UPDATE public.buses
SET driver_id = 'b8b6c5c1-4d2d-5f9e-9b3f-6d7a9c8b0e1f'
WHERE id = 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d';

-- Step 3: Re-link the route(s) to the new bus.
-- This is a critical step. All routes that were supposed to use the old bus
-- for this driver must now point to the new bus.
UPDATE public.routes
SET bus_id = 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d'
WHERE id = 'a0a1b2b3-4c5d-6e7f-8a9b-0c1d2e3f4g5h';
-- In a real application, you might find all routes for the driver:
-- WHERE bus_id = 'f3fa0a0b-8b6b-9d3c-3f7d-0ab12c3d4e5f';

-- The changes are now logically complete. The driver's trips will now be
-- associated with the new bus. Existing trips for the day might also need
-- to be updated if they have already been created.
-- For example, if a trip for today was already scheduled:
UPDATE public.trips
SET bus_id = 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d'
WHERE route_id = 'a0a1b2b3-4c5d-6e7f-8a9b-0c1d2e3f4g5h' AND trip_date = current_date;

COMMIT;

-- The system is now updated. When the driver starts their trip, the new bus
-- will be tracked, and parents will see the correct information. The RLS policies
-- will ensure the driver can see the students on this route regardless of the bus change.
SELECT 'Example script created successfully. Review the comments for explanation.' as result;
