# Privacy Note (PDPL-Aware)

This document outlines our approach to privacy and data protection, with consideration for the Saudi Personal Data Protection Law (PDPL).

## Core Privacy Principles

Our platform is built with privacy as a core consideration. We are committed to processing personal data lawfully, transparently, and securely.

### 1. Lawful Basis and Consent
The primary lawful basis for processing location data is the **explicit consent** of the parents (data subjects).
- **Action**: Consent is obtained during the onboarding process within the Parent App before any tracking begins. Parents are clearly informed that their child's journey will be tracked for safety and communication purposes during school trips.

### 2. Data Minimization
We only collect personal data that is strictly necessary to provide the service.
- **Location Data**: We collect latitude, longitude, speed, and timestamps only when a trip is `in_progress`. We do not collect location data at any other time.
- **Personal Information**: We collect names and contact details of parents and drivers, and names of students, as essential information for the service to function.

### 3. Purpose Limitation
The data collected is used exclusively for the following purposes:
- To provide live location of the school bus to authorized parents during a trip.
- To automatically notify parents of the bus's approach, arrival, and school entry.
- To allow drivers to confirm student pickups.
- To facilitate direct chat communication between a parent and their assigned driver during a trip.
- To generate attendance reports for administrative purposes.

Personal data will not be used for any other purpose, such as marketing or profiling, without additional explicit consent.

### 4. Data Retention and Deletion
We adhere to a strict data retention schedule to ensure we do not hold personal data for longer than necessary.
- **Granular Location Data**: Individual GPS coordinates (`locations` table) are considered sensitive. This data is hard-deleted from our database automatically after **14 days**.
- **Event & Trip Data**: Anonymized or aggregated trip data (e.g., attendance records, event timestamps) may be retained for longer periods for statistical analysis, but without the granular location history.

### 5. Data Security and Access Control
We have implemented robust technical measures to protect personal data.
- **Row-Level Security (RLS)**: Our database is architected with strict RLS policies. This ensures that:
  - A parent can *only* see location data and events related to their own child's trip.
  - A driver can *only* see information relevant to their assigned route and trip.
  - No user can see data they are not explicitly authorized to view.
- **Secure Communication**: All data is encrypted in transit (TLS) and at rest.

### 6. User Rights
In line with PDPL, users (parents) have the right to access, correct, or request the deletion of their personal data. These requests can be managed through the application's settings or by contacting our support.
