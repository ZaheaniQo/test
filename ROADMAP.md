# Project Roadmap & Proposed Improvements

This document outlines the strategic roadmap and suggested improvements for the School Bus Tracking application, based on user feedback.

## 1. Documentation

- **Environment Variables**:
  - Add `.env.example` file to `apps/admin-web` (`NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `GOOGLE_MAPS_API_KEY`, `FCM_KEY`).
  - Add `.env.example` file to `backend/edge-functions` (`SUPABASE_URL`, `SERVICE_ROLE_KEY`, `FCM_SERVER_KEY`).
- **Standard Repository Files**:
  - `CONTRIBUTING.md`: Guidelines for contributions.
  - `SECURITY.md`: Instructions for reporting security vulnerabilities.
  - `CODE_OF_CONDUCT.md`: Code of Conduct for the community.
  - `LICENSE`: Project license file.
- **README Updates**:
  - Add detailed local setup and run steps for each application.
  - Include a simplified architecture diagram (`apps ↔ backend ↔ DB`).

## 2. Database & RLS

- **Schema Extensions**:
  - `user_profiles`: For supplementary data post-authentication.
  - `invitations`: To handle invites with pre-assigned roles.
  - `organizations / branches`: To support multi-school or multi-branch setups.
- **Database Views**:
  - Create a view for a summary of the day's trips (for Admins).
  - Create a view for student statuses on a trip (for Drivers).
- **RLS Policies**:
  - Enhance policies to be strictly role-based (e.g., Parent sees only their children, Driver sees only their trip).
  - Add organization-level RLS for multi-school support.
- **Testing**:
  - Implement RLS tests using `pgTAP`.

## 3. Edge Functions (Logic)

- **`auth-signup`**: A new function to handle sign-ups, check for invitations, set custom JWT claims for the user's role, and create a user profile.
- **`trip-start` / `trip-end`**: Enhance functions to manage the full trip lifecycle and save historical records.
- **`notify-geofence`**: A dedicated function to handle sending FCM notifications to parents based on geofence events.
- **`alerts`**: A function to generate alerts for trip delays or other incidents.

## 4. Frontend Applications

- **Unified Mobile App (Flutter) `/apps/mobile`**:
  - **Driver Features**: Implement trip start/end screen, periodic location broadcasting (with offline batching), student check-in/check-out list, and an emergency (SOS) button.
  - **Parent Features**: Implement the live map with bus tracking, notifications for geofence events, and a daily attendance history screen.
- **Admin Web (Next.js) `/apps/admin-web`**:
  - **Dashboard**: Live trips, live map, and an alerts list.
  - **Invitation Management**: A UI for creating and managing user invitations.
  - **Organization Settings**: A UI for managing schools, routes, and default times.

## 5. CI/CD & Quality (DevOps)

- **GitHub Actions**:
  - Set up a CI pipeline to lint, test, and build each application on push/PR.
  - Add a workflow to apply database migrations to a test environment before merging.
- **Versioning**:
  - Implement `release-please` for automated release versioning.
- **Code Quality**:
  - Enforce ESLint/Prettier in all projects.
- **Type Generation**:
  - Use `supabase gen types typescript --local` to keep TypeScript types in sync with the database schema.

## 6. Security & Privacy

- **Authentication**:
  - Enforce 2FA for Admin and General Supervisor accounts.
- **Privacy Policy**:
  - Create a formal privacy policy detailing data retention periods and deletion procedures.
- **Privacy by Design**:
  - Implement coordinate anonymization or generalization for trips after they are completed.

## 7. Monitoring & Observability

- **Logging**:
  - Integrate Edge Functions with a logging provider (e.g., Supabase Logs, Logflare).
- **Alerting**:
  - Configure GitHub Actions to send alerts on deployment failures.
- **Dashboards**:
  - Set up simple monitoring dashboards (using Grafana, Metabase, or Supabase's built-in dashboards) to track key metrics: number of trips, delay times, SOS alerts.

## 8. UX / UI

- **Design System**:
  - Establish a unified design system (colors, icons, buttons) for all applications.
- **Localization**:
  - Ensure full i18n support for Arabic and English across all UIs.
- **Onboarding**:
  - Improve the first-time user experience with guided onboarding screens.
