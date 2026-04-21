# Blood Donor Receiver

A Flutter app that helps people find blood donors — fast — when someone they love needs it.

The idea is simple: people lose their lives every year because the chain of "who knows a donor" is slow and ad-hoc. This app collapses that chain. Open the app, register yourself as a donor in a minute, or register a patient and see compatible donors nearby with a way to reach them. No paperwork, no phone trees.

Built as a college capstone Review 1 prototype. Local-only persistence for the demo (Hive), with the architecture already shaped so we can swap to Firebase Auth + Firestore for Review 2 without rewriting screens.

> **The code walkthrough lives in [CODEBASE.md](CODEBASE.md).** Read that if you want to understand how it all fits together or how to add features.

---

## What the app does

Here's what you can actually do, step by step:

**As a new user**
1. Open the app — you see a splash screen with the logo for about 2 seconds.
2. Sign up with your name, email, and a password. There's a strength meter: weak, medium, strong. We reject weak.
3. Fill in a short profile — location (type it in or tap the GPS button), phone, DOB. Save.
4. You land on the home screen with two cards: *Donate blood* and *Receive blood*. You can do either, or switch between them.

**As a donor**
- Tap *Donate blood*, fill in the form (your profile prefills most of it), pick a blood group, tap save.
- A **donor token** is created with an ID like `DNR-20260421-001`. Receivers nearby can now see your token.
- Later, when someone sends you a request, it shows up in your Profile → Donor tokens tab. Tap the token to see who's asking, accept or decline.
- After accepting, you walk through a 4-step progress tracker: *Accepted → Patient contacted → Blood arranged → Donated*. Mark as completed when done.

**As a receiver (or someone registering on behalf of a patient)**
- Tap *Receive blood*, fill in the patient's details, pick a cause from the dropdown (Accident, Surgery, Anemia, etc.), how many units needed, required blood group.
- A **receiver token** is created. You're taken straight to a list of **compatible donors** — the list auto-filters by blood group (O+ patient sees O+ and O- donors; AB+ sees everyone).
- Donors in your city get a small **Nearby** tag. You can sort by Newest / Nearby / Blood group.
- Tap *Send request* on a donor card. You're taken to a status tracker: *Request sent → Accepted → Blood arranged → Received*.
- You can withdraw before the donor accepts. After that, you watch the progress and mark as received when the transfusion happens.

**Profile**
- Your details live there, with an *Edit* button for name / phone / DOB / location.
- Two tabs: **Tokens (N)** — your donor registrations, with pending-request counts — and **Requests (N)** — everything you've sent out with their live status.
- Logout button in the top right.

---

## Tech stack

| Layer | Choice | Why |
|---|---|---|
| UI | **Flutter 3.41** (Material 3) | Single codebase; Android for Review 1, iOS later if needed |
| Language | **Dart 3.11** | Sound null safety, switch expressions, modern records |
| State | **Provider** | Officially recommended, minimal boilerplate, plays nicely with Hive streams |
| Local DB | **Hive** with dynamic boxes | Mirrors Firestore's document shape; zero `build_runner`; survives restarts |
| Location | **geolocator + geocoding** | Real GPS reverse-geocoding with graceful fallback to manual text entry |
| Fonts | **Google Fonts** (Fraunces + Inter + JetBrains Mono) | Editorial, not the generic Roboto default |
| Hashing | **crypto** (SHA-256 + per-user salt) | Demo-grade password storage; Firebase Auth takes over in Review 2 |

**What we chose not to use:**
- **Riverpod / Bloc** — Provider is enough for 4 entities
- **Drift / SQLite** — Hive matches the document-per-token model better
- **Google Maps SDK** — needs a billing-enabled API key; reverse-geocoded text serves the demo

---

## Getting the app on your phone

### Option 1: install the debug APK directly

The most recent build is in this repo as [`blood-donor-receiver-debug.apk`](./blood-donor-receiver-debug.apk) — *(if you cloned the repo; note that the APK is `.gitignore`d, so it'll only appear after a local build)*.

```bash
# Connect your Android phone with USB debugging on, then:
adb install -r blood-donor-receiver-debug.apk
```

Or sideload it directly on the phone: copy the APK to your phone, open it in the file manager, allow "install from unknown sources" if prompted.

### Option 2: build it yourself

Requires **Flutter SDK ≥ 3.22** and the **Android SDK** (command-line tools + platform-34 + build-tools 34.0.0 + platform-tools). `flutter doctor` must be green for the Android toolchain.

```bash
# Clone the repo
git clone https://github.com/kiitto/Blood-donor-app.git
cd Blood-donor-app

# First-time only: scaffold the native Android/iOS shell
flutter create --project-name blood_donor_receiver --org com.blooddonor --platforms=android .

# Fetch packages
flutter pub get

# The AndroidManifest already has INTERNET + location permissions patched in
# (see android/app/src/main/AndroidManifest.xml)

# Run on a connected device or emulator
flutter run
```

On first launch, Google Fonts downloads Fraunces + Inter over the network and caches them. Later launches are fully offline.

### Option 3: just the debug APK (one-liner)

```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

Size: about 150 MB debug. A release build (`flutter build apk --release`) shrinks that to ~35 MB with tree-shaking, but needs a release keystore.

---

## Demo walkthrough (3 min, one phone)

Great for a Review 1 presentation:

1. **Splash → Login** — auto-advances.
2. **Sign up** with something like `suraj@demo.in` / `Demo@12345`. Watch the strength meter hit "Strong" as you type.
3. **Profile setup** — type `Bengaluru` and pick from the autocomplete dropdown. Fill phone, DOB. Save.
4. **Dashboard** — point out the two role cards and the location ribbon.
5. **Receive flow** — tap Receive. Register a patient: name, `B+`, 2 units, Cause = Surgery. Save.
6. **Search Donors** — the ribbon at the top explains you're looking for 2 units of B+. The list auto-filters to compatible donors (O+, O−, B+, B−). Point out the **Nearby** tag on the Bengaluru donor.
7. **Send request** to a seed donor (e.g. Divya Sharma, B+, Mumbai). The receiver status tracker opens.
8. **Profile → Requests** — your request is there with an "Awaiting donor" pill.
9. **Back → Dashboard → Donate** — register yourself as a donor, AB+. Token ID appears in a confirmation dialog: `DNR-20260421-001`.
10. **Profile → Tokens** — your token is there, status "Active". Tap it to see the (empty) inbox.

To show the donor-side accept flow in a one-person demo, sign out → sign up as a second user → register a receiver → send a request back to yourself → sign out → sign back in as the first user → Profile → Tokens → tap → Accept → walk through the status stages.

---

## Tests

**108 unit tests** covering password strength classifier, blood compatibility matrix, validators, password hashing, token ID generation (including concurrent-mint uniqueness), model round-trips, and all four repositories end-to-end against a temp Hive dir.

```bash
flutter test test/unit/
# 00:03 +108: All tests passed!
```

Widget tests were deferred in this commit — they were drafted against an earlier version of the UI and need rewriting now that labels, eyebrows, and nav treatment have been tightened. Tracked as the next follow-up.

**Static analysis:**

```bash
flutter analyze
# No errors, no warnings (info-level style hints only)
```

---

## Repository layout

```
blood_donor_receiver/
├── README.md                 # this file
├── CODEBASE.md               # deep walk-through of the code
├── pubspec.yaml              # dependencies
├── analysis_options.yaml     # lints
├── android/                  # native Android shell (generated by flutter create)
├── lib/                      # all Dart code
│   ├── main.dart             # entry point: Hive init → Providers → runApp
│   ├── app.dart              # MaterialApp + theme + scroll behaviour
│   ├── core/                 # theme, constants, utilities
│   ├── data/                 # models + Hive boxes + repositories
│   ├── state/                # Provider ChangeNotifiers
│   ├── features/             # 14 screens across splash/auth/dashboard/donor/receiver/profile
│   └── shared/widgets/       # reusable UI primitives
└── test/
    ├── helpers/              # HiveTestHarness + pump helpers
    └── unit/                 # 108 passing tests
```

For a detailed tour of what each of these does and how they talk to each other, read [CODEBASE.md](CODEBASE.md).

---

## Design choices worth pointing out

This is a serious app about a serious thing — we went for editorial, not "modern dashboard."

- **Fraunces serif** for display (splash title, screen headlines, role cards) — warm, a little literary, not tech-bro sans-serif
- **Inter** for body text and UI chrome — the workhorse
- **JetBrains Mono** exclusively for token IDs (`DNR-20260421-001`) — the monospace rhythm makes lists of IDs scannable
- **0–2px border radii** across every surface — sharp, intentional
- **No shadows anywhere**. A 1px hairline border gives a card enough depth without the glowing-card AI cliché
- **One hand-painted teardrop** (`lib/shared/widgets/blood_drop.dart`) used for the logomark, splash decoration, and empty states — no emoji, no image assets
- **Palette**: `#6B0F1A` maroon primary, `#B01E2F` red accent, warm off-white cards (`#F5F3F1`), charcoal ink (`#1A1517`). No purples, no pastels

The first review pass (`0bab318`) had some conventional AI-design patterns: stacked all-caps eyebrows on every section, a centered-giant-title splash layout, a FAB-style circular Profile button in the bottom nav, faux-glass status pills. Those got audited and cut in this commit. The result is warmer, denser, and less generic.

---

## Token IDs — why they look like that

`PREFIX-YYYYMMDD-###`

- `DNR-20260421-001` — first donor token on April 21, 2026
- `RCV-20260421-001` — first receiver token same day
- `REQ-20260421-001` — first blood request same day

Sequence counters persist per day per prefix in a session Hive box. The minter is serialized through a Future lock chain so two rapid taps can never read-then-write the same counter and produce duplicate IDs. On the next UTC day, counters reset to `001`.

Readable, sortable, easy to say out loud when someone's describing a problem on the phone. No UUIDs.

---

## Blood group compatibility

Full 8×8 donor-recipient matrix in `lib/core/utils/blood_compatibility.dart`. Used to auto-filter the Find Donors screen:

| Receiver | Compatible donors |
|---|---|
| O+  | O+, O− |
| O−  | O− |
| A+  | A+, A−, O+, O− |
| A−  | A−, O− |
| B+  | B+, B−, O+, O− |
| B−  | B−, O− |
| AB+ | everyone (universal recipient) |
| AB− | O−, A−, B−, AB− |

There's a "Show all donors" toggle if the receiver wants to browse outside the compatible set.

---

## Request status state machine

```
  ┌───── declined ──────┐
  │                     ▼
pending ─► accepted ─► contacted ─► arranged ─► completed
  │
  └── withdrawn ──► (terminal)
```

| Status | Set by | Receiver sees | Donor sees |
|---|---|---|---|
| `pending` | Receiver sends | "Request sent" (current) | "Awaiting response" |
| `accepted` | Donor accepts | "Request accepted" (current) | Step 1/4 |
| `contacted` | Donor | Folded into "Blood arranged" (current) | Step 2/4 |
| `arranged` | Donor | "Blood arranged" (current) | Step 3/4 |
| `completed` | Either | "Received" (done) | "Donated" (done) |
| `declined` | Donor | Terminal message | — |
| `withdrawn` | Receiver (before acceptance) | Terminal message | — |

The donor's internal `contacted` phase is folded into the receiver's "Blood arranged" step on the tracker. This keeps the receiver's progress bar advancing while the donor is still arranging the transfusion, rather than showing a static screen for an unknown duration.

**On acceptance**, the repository closes the donor token (`closed: true`) before writing the accepted request. This means two things: the donor token drops off the search list for everyone else (via the Hive box.watch() stream that all providers subscribe to), and even if the request write somehow fails, we never end up with an "accepted request + open donor" state that's hard to reconcile.

---

## Swapping Hive for Firestore later

All four repositories in `lib/data/repositories/` are the single seam between storage and the rest of the app. Providers and screens never import `package:hive` directly — they only call repository methods.

To graduate past Review 1:

1. Add Firebase: `firebase_core`, `firebase_auth`, `cloud_firestore`.
2. Run `flutterfire configure` to generate `firebase_options.dart`.
3. Replace method bodies in the four repositories:
   - `AuthRepository` → `FirebaseAuth.instance.signInWithEmailAndPassword(...)` etc.
   - The three token repositories → `FirebaseFirestore.instance.collection(...).snapshots()` etc.
4. Change the Provider listener source from `Hive.box(...).watch()` to `collection.snapshots()`.
5. Delete `hive_boxes.dart`, `seed_data.dart`, and the Hive dependencies.

Everything else stays identical. Estimated migration: half a day.

---

## Known caveats (things to know before the demo)

- **Passwords** are SHA-256 with a per-user random salt. Fine for a local-only demo; Firebase Auth replaces this in Review 2.
- **Seed donors** have `ownerEmail = seed@community.local` — not a real user. Requests sent to seeds stay "Awaiting donor" forever. To demo accept/decline, create a second real account.
- **Google Fonts on first launch** needs network for ~100 KB. Subsequent launches are offline.
- **Hive data persists** between runs. To reset for a clean demo: uninstall and reinstall, or hook `HiveBoxes.clearAll()` to a dev-only debug button.
- **Location GPS** needs the runtime permission granted once. If denied, the autocomplete text field still works perfectly — there's no hard dependency on GPS.

---

## Contributing / how to add a feature

The short version: pick the feature, figure out what data it needs, add the model, add the repository method, wire it through a provider, drop it in a screen.

Longer version lives in [CODEBASE.md](CODEBASE.md#how-to-add-a-feature).

---

## Credits

Built as a college capstone project by [Suraj-B12](https://github.com/Suraj-B12) and team. UI mockups in Figma, implementation in Flutter + Dart 3. Review 1 submission.
