# School Bus Tracking App (MVP)

This repository contains the full-stack solution for a production-ready MVP of a school bus tracking application. The system connects Parents and Drivers, providing live bus tracking, chat, and automated geofence-based notifications for key events in a student's journey.

## Monorepo Structure

The project is organized as a monorepo with the following structure:

- `/apps/driver-app`: Flutter application for Drivers.
- `/apps/parent-app`: Flutter application for Parents.
- `/apps/admin-web`: Next.js application for the Admin dashboard.
- `/backend/edge-functions`: TypeScript Deno functions for the Supabase backend.
- `/db`: Contains all database-related SQL scripts.
- `/docs`: Project documentation, including architecture and privacy notes.

## Tech Stack

- **Backend**: Supabase (PostgreSQL, Auth, Realtime, Edge Functions)
- **Mobile Apps**: Flutter (or FlutterFlow)
- **Admin Panel**: Next.js (React)
- **Maps & Geofencing**: Google Maps SDK
- **Notifications**: Firebase Cloud Messaging (FCM)

---

## Milestone 1: Database Setup

This milestone covers the complete setup of the Supabase PostgreSQL database, including the schema, row-level security (RLS) policies, and initial seed data for a demo scenario.

### Prerequisites

1. A Supabase account ([app.supabase.com](https://app.supabase.com)).
2. A new Supabase project created.

### Setup Instructions

Follow these steps to initialize your Supabase project's database.

1.  **Create a New Project**:
    - Go to your Supabase dashboard and create a new project.
    - Save your **Project URL**, **anon key**, and **service_role key**. You will need these later for the applications and edge functions.

2.  **Run the Database Scripts**:
    - In your Supabase project, navigate to the **SQL Editor**.
    - Click **+ New query**.
    - You will run the scripts from the `/db` directory in the following order. Copy the content of each file, paste it into the SQL Editor, and click **RUN**.

    a. **`db/schema.sql`**
        - This script creates all the necessary tables, types, and indexes.
        - **Action**: Copy the entire content of `db/schema.sql`, paste it into the editor, and run it.

    b. **`db/policies.sql`**
        - This script first defines helper functions and then enables Row-Level Security (RLS) on all tables. It proceeds to create the specific access policies for each role (`admin`, `driver`, `parent`).
        - **Important**: RLS is critical for the security of the app. Do not skip this step.
        - **Action**: Copy the entire content of `db/policies.sql`, paste it into the editor, and run it.

    c. **`db/seed.sql`**
        - This script populates the database with the required demo data, including a school, a driver, a parent, two students, a bus, a route, and a scheduled trip for the current day.
        - This data is essential for testing the end-to-end flow.
        - **Action**: Copy the entire content of `db/seed.sql`, paste it into the editor, and run it.

3.  **Verify the Setup**:
    - After running all scripts, go to the **Table Editor** in your Supabase dashboard.
    - You should see all the created tables (e.g., `users`, `students`, `trips`).
    - Click on the `schools` table and verify that "مدارس الأفق" is listed.
    - Check the `users` table to see the "أبو فهد" (driver) and "أم ليان ومازن" (parent) users.

### Next Steps

The database is now ready. The subsequent milestones will focus on building the backend logic with Edge Functions and connecting the frontend applications. You will need to configure the following keys in your application's environment:

- `SUPABASE_URL`: Your project's URL.
- `SUPABASE_ANON_KEY`: Your project's public anonymous key.
- `GOOGLE_MAPS_API_KEY`: To be obtained from Google Cloud Console.
- `FCM_SERVER_KEY`: To be obtained from Firebase Console.

---
*This README will be updated as each milestone is completed.*
