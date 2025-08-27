# System Architecture

This document outlines the high-level architecture of the School Bus Tracking MVP.

## 1. Monorepo and Technology Stack

The project is developed within a single monorepo to streamline development, dependency management, and code sharing.

- **Frontend (Mobile)**: Two Flutter applications, `driver-app` and `parent-app`, designed for iOS and Android. They share a common business logic but have role-specific UIs.
- **Frontend (Web)**: A minimal Next.js (React) application, `admin-web`, for administrative tasks.
- **Backend**: Supabase serves as the primary backend-as-a-service (BaaS).
  - **Database**: Supabase Postgres for data storage.
  - **Authentication**: Supabase Auth for managing users (parents, drivers, admins).
  - **Realtime**: Supabase Realtime for live data synchronization (e.g., bus location on the parent's map).
  - **Serverless Logic**: Supabase Edge Functions (Deno, TypeScript) for secure, server-side operations.
- **Infrastructure**: The entire backend is hosted on Supabase Cloud.

## 2. Core Components

### `db`
Contains the master SQL scripts for the database.
- `schema.sql`: Defines the entire database schema, including tables, relationships, and custom types.
- `policies.sql`: Implements Row-Level Security (RLS) to ensure users can only access data they are permitted to see. This is the core of our security model.
- `seed.sql`: Populates the database with initial demo data for testing and demonstration.

### `backend/edge-functions`
These are serverless TypeScript functions that execute custom business logic. They are invoked securely from the client applications.
- `/trip-start`, `/trip-finish`: Manage the lifecycle of a trip.
- `/event-driver`: Allow drivers to manually log events like "picked_up".
- `/location-push`: The core of the tracking system. It receives location updates, stores them, and performs geofence calculations to trigger automated events.

### `apps`
- `driver-app`: Allows drivers to start/end trips, view their ordered list of stops, and manually mark student pickups. It is responsible for background location streaming to the `/location/push` function.
- `parent-app`: Allows parents to see the live location of the bus on a map, view their child's status, receive notifications, and chat with the driver.
- `admin-web`: A simple dashboard for administrators to perform CRUD operations on users, routes, schools, and settings, and to view attendance reports.

## 3. Data Flow Example: Approaching Notification

1.  **Driver App**: The driver starts a trip. The app begins sending the bus's location (`lat`, `lng`, `speed`) to the `/location/push` Edge Function every X seconds.
2.  **Edge Function (`/location/push`)**:
    - The function receives the location data and authenticates the driver.
    - It saves the raw location data to the `locations` table.
    - It fetches the trip's route, the list of remaining stops, and the `approach_radius_m` setting.
    - It calculates the Haversine distance from the current location to the next stop.
    - If `distance <= approach_radius_m` and an "approaching" event for this stop hasn't been created yet, it proceeds.
3.  **Database (`events` table)**:
    - The Edge Function inserts a new row into the `events` table with `event_type = 'approaching'`.
4.  **Push Notification (FCM)**:
    - The Edge Function (or a database trigger listening to the `events` table) would be responsible for constructing and sending a push notification via Firebase Cloud Messaging (FCM) to the parent(s) of the student at that stop.
5.  **Parent App**:
    - The parent receives the push notification on their device.
    - The app's UI might also update in realtime to show a status change, e.g., "Bus is 200m away". This can be powered by Supabase Realtime listening for changes on the `events` table.
