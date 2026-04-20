# Blood Donor Receiver

A Flutter Android app that connects blood donors with receivers in real-time. People lose lives every year waiting on blood. This app collapses that friction to a few taps: **register as a donor**, or **register a patient and find compatible donors nearby**, send a request, track the donation end-to-end.

Built as a Review 1 working prototype — **local-only** persistence via Hive for the demo, with the architecture pre-shaped for a Firebase Auth + Firestore swap-in when the project graduates past Review 1.

---

## Table of contents

1. [Problem statement](#problem-statement)
2. [What the app does](#what-the-app-does)
3. [Tech stack & why](#tech-stack--why)
4. [Project structure](#project-structure)
5. [Running locally](#running-locally)
6. [Demo script](#demo-script)
7. [Data model](#data-model)
8. [Token ID format](#token-id-format)
9. [Blood group compatibility matrix](#blood-group-compatibility-matrix)
10. [Request status state machine](#request-status-state-machine)
11. [Design system](#design-system)
12. [Screens](#screens)
13. [Swapping Hive for Firestore later](#swapping-hive-for-firestore-later)
14. [Known caveats](#known-caveats)
15. [Review 1 deliverable checklist](#review-1-deliverable-checklist)

---

## Problem statement

Finding blood donors at crucial times is a critical, life-or-death problem. Multiple cases are reported every year where people lose their lives because blood wasn't available in time. Hospitals call around; families ping WhatsApp groups; word-of-mouth chains break. The process is ad-hoc, high-friction, and slow.

**We reduce that friction to a single app.** Anyone can volunteer to donate, or find donors nearby on behalf of a patient, or do both in the same session. No intermediaries, no paperwork, no phone-tree.

---

## What the app does

- **Sign up / log in** with email + password (3-tier password strength meter: weak → medium → strong).
- **Set up a profile** once — name, location, phone, DOB. The profile prefills donor and receiver forms so re-registering for someone else is one tap lighter.
- **Donate**: register a donor token (yours, or on someone's behalf) — name, blood group, area, phone, last donation date. The token lives on the "Find Donor" board until accepted.
- **Receive**: register a patient — name, blood group, cause (dropdown), units needed, phone, location. Instantly see a list of **compatibility-filtered** donors with a NEARBY tag on donors in your city.
- **Send a request** to a donor. Track status end-to-end. Withdraw before acceptance. Once accepted, the donor token drops off the public board.
- **Donor-side inbox**: Accept or decline incoming requests. After acceptance, walk through a 4-stage tracker (Accepted → Contacted patient → Blood arranged → Donated).
- **Receiver-side tracker**: Sent → Accepted → Blood arranged → Received. The donor-internal "Contacted" step is folded into "Blood arranged" so the tracker never feels stuck.
- **Profile** with two tabs: your donor tokens (with pending-request counts) and your sent requests (with status pills).
- **Location**: text field with autocomplete over a curated list of Indian cities, plus a GPS button that reverse-geocodes your current coordinates.
- **Seed data**: 6 donor tokens across blood groups (O+, O-, A+, B+, B-, AB+) and cities (Bengaluru, Chennai, Mumbai, Hyderabad, Kochi, Pune) so the "Find Donor" screen is never empty on first launch.

---

## Tech stack & why

| Layer | Choice | Why |
|---|---|---|
| UI framework | **Flutter** (stable, Material 3) | Single codebase; target is Android for Review 1. |
| Language | **Dart 3** (switch expressions, records) | Null-safe; expressive without getting cute. |
| State | **Provider** (`ChangeNotifier`) | Officially recommended, minimal boilerplate, plays nicely with Hive streams. |
| Local DB | **Hive** (dynamic boxes, stream listeners) | Mirrors Firestore's document shape; zero build_runner; survives app restarts. |
| Location | **geolocator + geocoding** | Real GPS reverse-geocoding; graceful fallback to manual text entry. |
| Fonts | **google_fonts** (Fraunces + Inter + JetBrains Mono) | Editorial look; not the generic Roboto default everyone ships. |
| Hashing | **crypto** (SHA-256 + per-user salt) | Demo-grade password storage. Not PBKDF2/Argon2 — fine for local-only Review 1. |
| Firebase | **Dormant** | Swap-in planned; architecture ready (see [Swapping Hive for Firestore](#swapping-hive-for-firestore-later)). |

Strategic calls we didn't take:
- **Riverpod / Bloc** — Provider is simpler and sufficient for a 4-entity domain.
- **SQLite / Drift** — Hive matches our document-per-token model better; less schema ceremony.
- **Google Maps SDK** — requires API key + billing setup; reverse-geocoded text is enough for Review 1.

---

## Project structure

```
blood_donor_receiver/
├── pubspec.yaml
├── analysis_options.yaml
├── README.md (this file)
└── lib/
    ├── main.dart                    # Entry: Hive init → SeedData → MultiProvider → runApp
    ├── app.dart                     # MaterialApp, theme, text-scale clamping, no-glow scroll
    │
    ├── core/
    │   ├── theme/                   # Colors, text styles (Fraunces / Inter / JetBrains Mono), ThemeData
    │   ├── constants/               # Blood group list, Indian city autocomplete list, Cause options
    │   └── utils/
    │       ├── id_generator.dart    # DNR-YYYYMMDD-### tokens with per-day sequence
    │       ├── blood_compatibility.dart  # Full 8×8 donor-recipient matrix
    │       ├── password_strength.dart    # Weak / Medium / Strong classifier
    │       ├── password_hash.dart        # SHA-256 + random salt
    │       └── validators.dart           # Email, phone, name, units, required
    │
    ├── data/
    │   ├── models/                  # AppUser, DonorToken, ReceiverToken, BloodRequest
    │   ├── local/
    │   │   ├── hive_boxes.dart      # Opens all boxes on boot
    │   │   └── seed_data.dart       # One-time 6-donor seed (guarded by a meta flag)
    │   └── repositories/            # Single seam for Firestore swap — no UI code imports Hive directly
    │       ├── auth_repository.dart
    │       ├── donor_repository.dart
    │       ├── receiver_repository.dart
    │       └── request_repository.dart
    │
    ├── state/                       # ChangeNotifiers: auth, donor, receiver, request
    │                                #   — each subscribes to its Hive box's watch() stream
    │                                #   so cross-provider mutations propagate automatically.
    │
    ├── features/
    │   ├── splash/                  # 2-sec auto-advance; routes by auth/profile-complete state
    │   ├── auth/                    # Login, Signup, Profile Setup + shared maroon AuthLayout
    │   ├── dashboard/               # Welcome + location + two role cards + activity tiles
    │   ├── donor/                   # Registration, token-request inbox, status tracker
    │   ├── receiver/                # Registration, search (compatibility + sort), status tracker
    │   └── profile/                 # Welcome card + tabs (donor tokens / requests sent) + edit sheet
    │
    └── shared/widgets/              # The editorial design language, reusable
        ├── app_button.dart          # 5 variants: primary, onDark, outline, ghost, danger
        ├── app_text_field.dart      # Underline-style label-above input
        ├── app_header.dart          # Maroon top strip w/ back button + eyebrow + title + logomark
        ├── app_bottom_nav.dart      # 3-item nav (Donate / Profile-center / Receive)
        ├── blood_drop.dart          # CustomPaint teardrop — no emoji, no image asset
        ├── blood_group_selector.dart# 8-chip picker
        ├── location_field.dart      # Autocomplete + GPS reverse-geocode
        ├── password_strength_indicator.dart
        ├── status_tracker.dart      # Vertical dot-and-line 4-step tracker
        ├── confirm_exit_dialog.dart # Discard-progress confirmation
        ├── token_id_chip.dart       # Monospace pill for DNR-/RCV-/REQ- IDs
        ├── detail_row.dart          # Receipt-style key/value
        ├── empty_state.dart         # Outlined-drop empty state
        └── card_shell.dart          # Flat 1px-border card (no shadows, no glow)
```

---

## Running locally

Requires the Flutter SDK (≥ 3.22) and an Android device or emulator.

```bash
cd "blood_donor_receiver"

# 1. First-time only — scaffold native Android shell (pubspec.yaml + lib/ stay untouched)
flutter create --project-name blood_donor_receiver --org com.blooddonor --platforms=android .

# 2. Fetch dependencies
flutter pub get

# 3. Patch android/app/src/main/AndroidManifest.xml — add three permissions
#    inside <manifest> and ABOVE the <application> tag:
#
#    <uses-permission android:name="android.permission.INTERNET"/>
#    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
#    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

# 4. Connect a device (or start an emulator), then run
flutter run
```

First launch fetches Google Fonts over the network; subsequent launches are fully offline-capable.

---

## Demo script

A clean one-person Review 1 walkthrough (~3 minutes):

1. **Splash** — 2-sec auto-advance to Login.
2. **Sign up** fresh with `suraj@demo.in` / `Demo@12345` — watch the strength bar jump Weak → Medium → Strong as you type.
3. **Profile setup** — type "Bengaluru" and pick from autocomplete, or tap the GPS button. Fill phone, DOB. Save.
4. **Dashboard** — two role cards, location ribbon, activity counters.
5. **Receive flow** — tap the Receive card. Register a patient: your name, B+, 2 units, Cause = Surgery. Save.
6. **Search Donors** — ribbon at top explains you're looking for 2 units of B+. The list auto-filters to compatible donors (O+, O-, B+, B-). NEARBY tag appears on donors in Bengaluru.
7. **Send request** to Divya Sharma (B+, Mumbai). You're taken to the receiver status tracker: Request sent is current, everything else pending.
8. **Back → Profile → Requests sent** — your request is there with a "Awaiting donor" pill.
9. **Donate flow** — back → Dashboard → Donate card. Register yourself as a donor, AB+. Save. Token ID like `DNR-20260421-001`.
10. **Profile → Donor tokens** — your token appears, status "Active".
11. **Tap the token** to see its request inbox (empty — no one's pinged it yet).

To demonstrate the donor-side accept flow, **log out → sign up as a second user (`priya@demo.in`)** → register as a receiver → send a request to yourself (AB+ donor) → log out → log back in as `suraj@demo.in` → Profile → Donor tokens → tap token → Accept. Walk through Contacted → Arranged → Mark as completed.

---

## Data model

Four entities. All stored as `Map<String, dynamic>` in Hive boxes keyed by primary ID.

### `AppUser` — `users` box, keyed by email

| Field | Type | Notes |
|---|---|---|
| `email` | String | Primary key, lowercased |
| `name` | String | |
| `passwordHash` | String | SHA-256(salt::password) |
| `passwordSalt` | String | 16 bytes, base64url-encoded |
| `phone` | String | 10-digit, no prefix |
| `dob` | String | dd/MM/yyyy |
| `location` | String | "City, State" |
| `createdAt` | ISO8601 | |
| `profileComplete` | bool | True after Profile Setup finishes |

### `DonorToken` — `donors` box, keyed by token ID

| Field | Type | Notes |
|---|---|---|
| `id` | String | `DNR-YYYYMMDD-###` |
| `ownerEmail` | String | Links back to the registering user |
| `name`, `bloodGroup`, `location`, `phone` | String | |
| `lastDonationDate` | String | Optional, dd/MM/yyyy |
| `createdAt` | ISO8601 | |
| `closed` | bool | True once a request is accepted on this token |
| `acceptedRequestId` | String? | The request that closed it |

### `ReceiverToken` — `receivers` box, keyed by token ID

| Field | Type | Notes |
|---|---|---|
| `id` | String | `RCV-YYYYMMDD-###` |
| `ownerEmail`, `name`, `bloodGroup`, `location`, `phone` | String | |
| `cause` | String | One of 7 dropdown options |
| `causeOther` | String | Free text when `cause == 'Other'` |
| `unitsNeeded` | int | 1–20 |
| `createdAt`, `closed` | | |

### `BloodRequest` — `requests` box, keyed by request ID

| Field | Type | Notes |
|---|---|---|
| `id` | String | `REQ-YYYYMMDD-###` |
| `donorTokenId`, `receiverTokenId` | String | FKs |
| `senderEmail` | String | Who sent (receiver) |
| `recipientEmail` | String | Who received (donor token owner) |
| `status` | enum | See state machine below |
| `createdAt`, `updatedAt` | ISO8601 | |

---

## Token ID format

`PREFIX-YYYYMMDD-###`

- `DNR-20260421-001` — first donor token on 2026-04-21
- `RCV-20260421-001` — first receiver token same day
- `REQ-20260421-001` — first blood request same day

Sequence counters live in a session Hive box (`seq_DNR_20260421` etc.) and persist across app restarts. On the next UTC day, counters reset to `001`.

Readable, sortable, debuggable. No UUIDs you can't read out loud.

---

## Blood group compatibility matrix

Auto-filter on the "Find Donor" screen uses a full 8×8 matrix (`lib/core/utils/blood_compatibility.dart`). Receiver picks their blood group → donors are filtered to the compatible subset:

| Receiver | Compatible donors |
|---|---|
| O+  | O+, O- |
| O-  | O- |
| A+  | A+, A-, O+, O- |
| A-  | A-, O- |
| B+  | B+, B-, O+, O- |
| B-  | B-, O- |
| AB+ | all 8 (universal recipient) |
| AB- | O-, A-, B-, AB- |

The filter can be toggled off ("show all donors") with a pill on the filter bar.

---

## Request status state machine

```
           ┌───────── declined ─────────┐
           │                            │
   pending ─► accepted ─► contacted ─► arranged ─► completed
           │                                                  
           └──────── withdrawn ─────────┐                     
                                        │                     
                                   (terminal)                 
```

| Status | Set by | Visible to receiver as | Visible to donor as |
|---|---|---|---|
| `pending` | Receiver sends | "Request sent" (current) | "Awaiting response" |
| `accepted` | Donor accepts | "Request accepted" (current) | "Accepted" (step 1/4) |
| `contacted` | Donor | "Blood arranged" (current) — folded | "Patient contacted" (step 2/4) |
| `arranged` | Donor | "Blood arranged" (current) | "Blood arranged" (step 3/4) |
| `completed` | Either | "Received" (current) | "Donated" (step 4/4) |
| `declined` | Donor | Terminal message | — |
| `withdrawn` | Receiver (only before acceptance) | Terminal message | — |

The donor's internal "contacted" phase is folded into the receiver's "Blood arranged" stage — this keeps the receiver's tracker feeling alive during the window where the donor has accepted but hasn't finished arranging the transfusion.

**On acceptance**, the repository layer closes the donor token (`closed = true`), which drops it off the "Find Donor" search list automatically via the Hive stream listener.

---

## Design system

**Palette** (from `lib/core/theme/app_colors.dart`):

```
maroon       #6B0F1A   Primary brand, buttons, focus rings
maroonDeep   #4A0A12   Auth backdrop blooms
red          #B01E2F   Logomark fill, sale-like accents
ink          #1A1517   Body text
inkMuted     #6C6460   Secondary text
surface      #FFFFFF   Cards, content surface
surfaceMuted #F5F3F1   Section fills, passive states
hairline     #E3DDD8   1px borders — used everywhere instead of shadows
success      #2E5A3B   Completed status, NEARBY tag
danger       #8B1A1A   Destructive buttons, errors
```

**Typography** (Google Fonts):
- **Fraunces** — serif display. Used for big moments: splash title, screen headlines, role cards.
- **Inter** — body UI, buttons, labels. Tight, readable, the app's workhorse.
- **JetBrains Mono** — token IDs only. Monospace rhythm makes a list of DNR-/RCV-/REQ- IDs scannable.

**Radii**: 0–2px across every surface. Deliberately sharp — this app isn't a toy.

**Shadows**: none. A 1px hairline border gives a card enough depth without the generic "glowing card" look.

**Decoration**: one custom-painted teardrop (`blood_drop.dart`) used for the app logomark, splash background blooms, and empty-state marks. No emoji. No image assets.

**No**: gradients (except the near-invisible maroon splash blooms), glow effects, glassmorphism, shimmer loaders, pill-shaped CTAs, emoji icons.

---

## Screens

14 distinct screens, each a file in `lib/features/<feature>/`:

| # | Screen | File |
|---|---|---|
| 1 | Splash | `splash/splash_screen.dart` |
| 2 | Login | `auth/login_screen.dart` |
| 3 | Signup | `auth/signup_screen.dart` |
| 4 | Profile Setup | `auth/profile_setup_screen.dart` |
| 5 | Dashboard | `dashboard/dashboard_screen.dart` |
| 6 | Location change (bottom sheet) | `dashboard/location_sheet.dart` |
| 7 | Donor Registration | `donor/donor_registration_screen.dart` |
| 8 | Donor Token — Incoming Requests | `donor/donor_token_requests_screen.dart` |
| 9 | Donor Status Tracker | `donor/donor_status_screen.dart` |
| 10 | Receiver Registration | `receiver/receiver_registration_screen.dart` |
| 11 | Search Donors | `receiver/search_donors_screen.dart` |
| 12 | Receiver Status Tracker | `receiver/receiver_status_screen.dart` |
| 13 | Profile (tabs) | `profile/profile_screen.dart` |
| 14 | Edit Profile (bottom sheet) | `profile/edit_profile_sheet.dart` |

Navigation is imperative (`Navigator.push` / `pushReplacement`) — no `go_router` dependency added. Page transitions are the Flutter Material defaults.

---

## Swapping Hive for Firestore later

All four repositories in `lib/data/repositories/` are the single seam between storage and the rest of the app. Providers and screens never import `package:hive` directly — they only call repository methods.

To graduate past Review 1:

1. Add Firebase to `pubspec.yaml` (`firebase_core`, `firebase_auth`, `cloud_firestore`).
2. `flutterfire configure` to generate `firebase_options.dart`.
3. Replace method bodies in:
   - `AuthRepository` → `FirebaseAuth.instance.signInWithEmailAndPassword(...)`, `createUserWithEmailAndPassword(...)`.
   - `DonorRepository` / `ReceiverRepository` / `RequestRepository` → `FirebaseFirestore.instance.collection(...).add/update/snapshots(...)`.
4. Change the Provider listener source from `Hive.box(...).watch()` to `collection.snapshots()`.
5. Delete `hive_boxes.dart`, `seed_data.dart`, and the `hive` / `hive_flutter` dependencies.

Everything else — models, screens, Provider surface — stays identical. Estimated swap: half a day.

---

## Known caveats

- **Passwords** are SHA-256 + random 16-byte salt. Fine for local-only demo; will be replaced by Firebase Auth in Review 2.
- **Seed donor tokens** have `ownerEmail = seed@community.local` — not a real user. Sending requests to seed donors stays "Awaiting donor" forever (no one can accept on the seed's behalf). To demo accept/decline, create a second real user.
- **Google Fonts on first launch** fetches from the network. Offline first launch silently falls back to the default system sans-serif; all styles still apply.
- **Hive data persists** between runs. To reset for a clean demo: uninstall and reinstall the app, or call `HiveBoxes.clearAll()` from a debug button.
- **Location GPS** requires the AndroidManifest permissions listed above. If denied, the autocomplete text field still works — no hard dependency on GPS.
- **Deprecation warnings** — `Color.withOpacity` is marked deprecated in Flutter 3.27+ in favor of `withValues(alpha:)`. Works; just lint noise.

---

## Review 1 deliverable checklist

- [x] Sign up / log in with email + password
- [x] Password strength check (3-tier)
- [x] Profile setup with location + DOB
- [x] Dashboard with per-session role pick
- [x] Donor registration form → token generation
- [x] Receiver registration form → token generation
- [x] Search donors with blood-group auto-filter
- [x] Send request → donor-side inbox
- [x] Accept / decline / withdraw with correct state transitions
- [x] 4-stage status trackers (both sides)
- [x] "Mark as completed" closes the token
- [x] Profile with donor tokens tab + requests sent tab
- [x] Unique token IDs (DNR / RCV / REQ, date + sequence)
- [x] Back-button discard-progress confirmation on forms
- [x] Bottom nav on every screen except Profile
- [x] Dynamic, interactive location with autocomplete + GPS
- [x] Responsive across phone sizes via `ConstrainedBox` maxWidths and `MediaQuery.textScaler` clamping
- [x] Seed data so the search screen demos well on first launch
- [x] No generic AI UI (no glow, no gradients, no emoji icons, no stock clip-art)

Firebase integration is deferred to Review 2 per brief; the repository seam is in place.

---

## Credits

Built for a college capstone review by [Suraj-B12](https://github.com/Suraj-B12) and team. UI mockups done in Figma. Implementation in Flutter + Dart 3.
