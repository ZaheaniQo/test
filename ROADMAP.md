# 📌 Project Roadmap

## 🎯 Vision
Build a secure, multi-tenant school bus management system with a unified **mobile app** (Parents & Drivers) and a **web-based Admin dashboard**. Ensure **data security, privacy by design, and role-based access** at all levels.

---

## 🚀 Roadmap by Priority

### 🟥 P0 – Critical (Q1–Q2)

| Area              | Task                                                                 | Timeline | KPIs / Acceptance Criteria |
|-------------------|----------------------------------------------------------------------|----------|----------------------------|
| **RLS Testing**   | Add **pgTAP** coverage for all role-specific policies                | Q1       | 100% SELECT/INSERT/UPDATE/DELETE coverage per role |
| **Data Migration**| Create scripts to migrate legacy `users/students` → new schema       | Q1       | ≥99% data migrated successfully + rollback plan |
| **Edge Functions**| Refactor (`auth-signup`, `trip-start`, `trip-end`, `notify-geofence`, `alerts`) to org-centric model | Q1–Q2    | All functions working with `organization_id` + RLS enforced |
| **JWT Claims**    | Support **multi-role** (`app_roles: []`)                             | Q2       | Users with multiple roles handled correctly |
| **CI/CD**         | Add **staging pipeline** (schema + pgTAP + build checks)             | Q2       | All commits validated in staging before `main` |
| **Naming Rules**  | Define naming conventions across DB, API, and UI                     | Q2       | Linting/pre-commit check prevents violations |

---

### 🟨 P1 – Important (Q2–Q3)

| Area              | Task                                                                 | Timeline | KPIs / Acceptance Criteria |
|-------------------|----------------------------------------------------------------------|----------|----------------------------|
| **Views**         | Optimize `admin_today_trips_v` & `driver_picklist_v` with indexes    | Q2       | <100ms response under 100k records |
| **Privacy**       | Blur/approximate location outside trip windows                       | Q2–Q3    | No raw location exposed outside trip hours |
| **Admin Web**     | Add **Invitations console** (CRUD, Resend, Revoke)                   | Q2       | Full invitation workflow functional |
| **Admin Web**     | Add **Live Ops Dashboard** (Trips + Alerts + Map)                    | Q3       | Real-time updates + filtering |
| **Mobile**        | Driver: Location streaming (batch + offline queue)                   | Q2–Q3    | ≤5% data loss in bad network |
| **Mobile**        | Parent: Geofence notifications + preferences                         | Q2–Q3    | Alerts delivered only to relevant guardians |
| **Code Quality**  | Generate Supabase Types + enforce ESLint/Prettier                    | Q2       | No lint errors in CI |

---

### 🟩 P2 – Enhancements (Q3–Q4)

| Area              | Task                                                                 | Timeline | KPIs / Acceptance Criteria |
|-------------------|----------------------------------------------------------------------|----------|----------------------------|
| **Security**      | Enable **Admin 2FA** + session/lockout policies                      | Q3       | 2FA enforced for all Admin users |
| **Logging**       | Add correlation IDs + centralized logging (Logflare/Grafana)         | Q3–Q4    | End-to-end traceability per request |
| **Backups**       | Daily backups + **PITR** + quarterly restore tests                   | Q4       | Successful restore ≤30 days |
| **Docs**          | Update `ARCHITECTURE.md`, `PRIVACY.md`, `SECURITY.md` + diagrams     | Q4       | Docs aligned with final schema & flows |

---

## 📊 KPIs (Key Performance Indicators)

- ✅ 100% pgTAP coverage for RLS policies
- ✅ ≥99% successful migration of legacy data
- ✅ <100ms response time for critical views
- ✅ ≤5% data loss in mobile location streaming
- ✅ No raw location exposure outside trip windows
- ✅ 2FA enforced for Admin accounts
- ✅ Daily backups + quarterly restore tests passed

---

## 📅 High-Level Timeline

| Quarter | Focus Areas                                                                 |
|---------|------------------------------------------------------------------------------|
| **Q1**  | Schema finalization, pgTAP tests, data migration                             |
| **Q2**  | Edge Functions refactor, CI/CD staging, mobile role-based routing            |
| **Q3**  | Privacy features, performance optimizations, Admin dashboard enhancements    |
| **Q4**  | Security hardening (2FA, PITR), observability, full documentation refresh    |

---
