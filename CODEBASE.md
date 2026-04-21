# How the codebase works

This is a walkthrough of the app's code, written as if we were sitting next to you explaining it. No dry reference docs — the idea is that after reading this, you could open any file and know why it's there and what it talks to.

Read the [README](README.md) first if you haven't — it covers *what the app does*. This file covers *how the code makes it do that*.

---

## Table of contents

1. [The mental model](#the-mental-model)
2. [A tour of the folders](#a-tour-of-the-folders)
3. [The four layers, from outside in](#the-four-layers-from-outside-in)
4. [The data: what we store and where](#the-data-what-we-store-and-where)
5. [State management: Provider + Hive streams](#state-management-provider--hive-streams)
6. [The UI layer: screens and shared widgets](#the-ui-layer-screens-and-shared-widgets)
7. [A worked example: what happens when you send a request](#a-worked-example-what-happens-when-you-send-a-request)
8. [The theme and design system](#the-theme-and-design-system)
9. [Token IDs, done properly](#token-ids-done-properly)
10. [How to add a feature](#how-to-add-a-feature)
11. [How to swap Hive for Firestore later](#how-to-swap-hive-for-firestore-later)
12. [Tests: what's covered, what isn't](#tests-whats-covered-what-isnt)
13. [Things that caused bugs and how we fixed them](#things-that-caused-bugs-and-how-we-fixed-them)

---

## The mental model

Before we dive in, here's the shape of the app in one paragraph:

> Two people use the app. Alice registers as a **donor** — she fills a form and a `DonorToken` gets saved. Bob needs blood for his mother, so he registers as a **receiver** — his `ReceiverToken` gets saved. Bob opens the search screen and sees Alice's token (filtered by blood group compatibility). He taps "Send request" — a `BloodRequest` document ties the two tokens together. Alice sees the request in her Profile, taps Accept, and walks through four status stages until the blood is donated.

That's it. Four domain objects: **User**, **DonorToken**, **ReceiverToken**, **BloodRequest**. Everything the app does is CRUD on those plus a status state machine on the last one.

---

## A tour of the folders

```
lib/
├── main.dart          # app entry point
├── app.dart           # MaterialApp + theme wiring
│
├── core/              # things with no UI, no state — pure support
│   ├── theme/         # colors, text styles, ThemeData
│   ├── constants/     # blood groups, Indian cities, cause options
│   └── utils/         # id_generator, blood_compatibility, password stuff, validators
│
├── data/              # everything about storage — models and DB access
│   ├── models/        # plain Dart classes for the 4 domain objects
│   ├── local/         # Hive box setup + seed data for the demo
│   └── repositories/  # the CRUD API — the one place screens talk to the DB
│
├── state/             # Provider ChangeNotifiers that sit on top of repositories
│
├── features/          # one folder per feature, each with its screens
│   ├── splash/
│   ├── auth/          # login, signup, profile setup
│   ├── dashboard/     # home screen with role cards
│   ├── donor/         # register, incoming requests, status
│   ├── receiver/      # register, search donors, status
│   └── profile/       # welcome card + tabs + edit sheet
│
└── shared/widgets/    # reusable UI primitives used by multiple features
```

The logic here is: **core** has no dependencies on anything. **data** depends on core. **state** depends on data + core. **features** depend on everything. And **shared/widgets** depends only on core. So there's no circularity and no cross-feature coupling.

---

## The four layers, from outside in

### Layer 1: Screens (features/)

These are what the user sees. Each screen is a `StatefulWidget` (or `StatelessWidget` for trivial ones) that listens to state providers via `context.watch<>()`.

Screens never import `package:hive/...` directly. They don't even know Hive exists. They just ask a provider for some data.

### Layer 2: Providers (state/)

Each provider is a `ChangeNotifier` that holds the latest list of domain objects for one concern: `AuthProvider`, `DonorProvider`, `ReceiverProvider`, `RequestProvider`.

Providers have two jobs:
1. Expose the current data to screens (just getters)
2. Listen to the underlying Hive box via `box.watch()` so when any repository writes, the provider automatically re-reads and notifies subscribers

This is the magic that makes the UI feel live without any explicit refresh calls. If the `RequestRepository` marks a request as accepted, the `RequestProvider` picks it up from the box stream within a tick. If that acceptance also closed a donor token, the `DonorProvider` (subscribed to the donors box) also notifies. Every screen watching those providers rebuilds.

### Layer 3: Repositories (data/repositories/)

Four of them, one per domain object. Each one has plain async methods — `create`, `byId`, `byOwner`, `updateStatus`, etc. — and that's the entire storage API the app knows about.

This is the seam. If we later swap Hive for Firestore, we rewrite the *insides* of these four files. Nothing else changes.

### Layer 4: Hive boxes (data/local/)

Hive is a key-value document store. We use six boxes:
- `users` — keyed by email
- `donors`, `receivers`, `requests` — keyed by token ID
- `session` — stores the current user's email + ID generator sequence counters
- `meta` — stores the "seed data was inserted" flag

We store `Map<String, dynamic>` values (not typed objects), which means no `build_runner`, no `.g.dart` files, no generated adapters. Each model has a `toMap()` / `fromMap()` pair and that's all the serialization we need.

---

## The data: what we store and where

### `AppUser` — `users` box

```dart
{
  email: 'alice@example.com',       // lowercased, primary key
  name: 'Alice Ramanathan',
  passwordHash: '...',              // SHA-256(salt::password)
  passwordSalt: '...',              // 16 random bytes, base64url
  phone: '9876543210',
  dob: '12/03/1992',
  location: 'Bengaluru, Karnataka',
  createdAt: '2026-04-21T06:15:00.000Z',
  profileComplete: true,
}
```

### `DonorToken` — `donors` box, keyed by `DNR-YYYYMMDD-###`

```dart
{
  id: 'DNR-20260421-003',
  ownerEmail: 'alice@example.com', // who registered this token
  name: 'Alice Ramanathan',
  bloodGroup: 'O+',
  location: 'Bengaluru, Karnataka',
  phone: '9876543210',
  lastDonationDate: '10/01/2026',
  createdAt: '2026-04-21T06:15:00.000Z',
  closed: false,                    // true once someone's request gets accepted
  acceptedRequestId: null,          // points to the request that closed it
}
```

### `ReceiverToken` — `receivers` box, keyed by `RCV-YYYYMMDD-###`

```dart
{
  id: 'RCV-20260421-001',
  ownerEmail: 'bob@example.com',
  name: 'Ranjan Kumar',             // the patient — may not be Bob himself
  bloodGroup: 'B+',
  location: 'Bengaluru, Karnataka',
  phone: '9876543211',
  cause: 'Surgery',                 // from dropdown
  causeOther: '',                   // free text when cause == 'Other'
  unitsNeeded: 2,
  createdAt: '...',
  closed: false,
}
```

### `BloodRequest` — `requests` box, keyed by `REQ-YYYYMMDD-###`

```dart
{
  id: 'REQ-20260421-001',
  donorTokenId: 'DNR-20260421-003',
  receiverTokenId: 'RCV-20260421-001',
  senderEmail: 'bob@example.com',     // receiver-side user
  recipientEmail: 'alice@example.com',// donor-side user
  status: 'pending',                  // enum: pending / accepted / contacted / arranged / completed / declined / withdrawn
  createdAt: '...',
  updatedAt: '...',
}
```

That's the whole data model. Four entities. No joins, no foreign-key constraints, no migrations. Lookups happen by iterating the box and filtering in Dart — which works fine because a demo catalog has maybe dozens of items, and in production Firestore gives us indexed queries for free.

---

## State management: Provider + Hive streams

Here's the pattern, in full:

```dart
class DonorProvider extends ChangeNotifier {
  final DonorRepository _repo = DonorRepository();
  StreamSubscription<BoxEvent>? _sub;

  List<DonorToken> _all = const [];
  List<DonorToken> get all => _all;
  List<DonorToken> get available => _all.where((d) => !d.closed).toList();

  void init() {
    _all = _repo.all();
    _sub = HiveBoxes.donorsBox().watch().listen((_) {
      _all = _repo.all();
      notifyListeners();
    });
    notifyListeners();
  }
  // ...
}
```

Three things to notice:

1. **The provider subscribes to the box.** `HiveBoxes.donorsBox().watch()` gives us a `Stream<BoxEvent>` that fires every time someone writes to the `donors` box. When it fires, we re-read the whole thing and notify all listening widgets.
2. **Mutation goes through the repository, not the provider.** Screens call `DonorRepository.create(...)` (usually via a thin wrapper on the provider), which writes to the box. The box fires an event, the provider sees it, the UI rebuilds. The data flows in a circle.
3. **Cross-provider updates are automatic.** When `RequestRepository.updateStatus(id, accepted)` closes a donor token as part of the accept flow, the `DonorProvider` — subscribed to the donors box — sees the write independently and updates the search list. No manual coordination between providers.

The four providers (`AuthProvider`, `DonorProvider`, `ReceiverProvider`, `RequestProvider`) are registered at the top of the widget tree in `main.dart` using `MultiProvider`. They live for the life of the app.

### Why not Riverpod or Bloc?

Honestly? For four entities and a small state machine, Provider is exactly enough. Riverpod is cleaner for complex graphs of derived state, and Bloc is better for apps with heavy async flows — neither of which we have. Provider also plays nicely with `ChangeNotifier` which Flutter's built-in listeners understand natively.

---

## The UI layer: screens and shared widgets

### Screens

14 screens, organized by feature. Most are `StatefulWidget` because they hold form controllers or local "is submitting" booleans. The ones that don't — splash, the token detail view — are stateless.

Navigation is imperative (`Navigator.push` / `pushReplacement`) rather than declarative (`go_router`). This keeps the dependency graph small and there's no shared URL-based state worth routing through.

**Pattern: every screen that submits a form**

- Defines `TextEditingController`s in `initState`, disposes them in `dispose`
- Has a `GlobalKey<FormState>` for validation
- Has a `bool _saving = false` that disables the submit button while the async op is in flight (so double-taps don't fire twice)
- Guards `context.mounted` after every `await` before calling Navigator or ScaffoldMessenger

**Pattern: every screen with a status tracker**

- Reads the current `BloodRequest` from the provider
- Computes a list of `StatusStep`s based on the current status
- Renders them via the shared `StatusTracker` widget (a vertical dot-and-line pattern)
- Shows a primary action button ("Mark patient contacted", "Mark as received") that advances the state machine

### Shared widgets

Everything in `lib/shared/widgets/` is either reused by multiple features or it's a shared design primitive. If it's only used once, it lives inside the feature folder (e.g. `_RoleCard` is a private widget inside `dashboard_screen.dart`).

Notable ones:

- **`AppButton`** — 5 variants: primary (maroon bg), onDark (white bg for maroon backdrops), outline, ghost, danger. Fixed 2px radius, no elevation.
- **`AppTextField`** — the editorial underline-style input with a sentence-case label above. Used everywhere on white backgrounds.
- **`BloodDrop`** — a hand-painted teardrop via `CustomPaint`. No PNG asset, no emoji. Used for the logomark, splash decoration, empty state marks.
- **`StatusTracker`** — dot-and-line progress indicator, not the built-in Material `Stepper`. Three dot states: done (filled circle with check), current (ringed circle), pending (hairline outline).
- **`TokenIdChip`** — a small monospace pill for `DNR-20260421-001` style IDs. Uses JetBrains Mono so the rhythm of prefix-date-sequence lines up cleanly when stacked in a list.
- **`CardShell`** — the one and only card primitive. Flat surface, 1px hairline border, 2px radius, zero shadows. Every piece of content on a white background uses this.

---

## A worked example: what happens when you send a request

Let's trace the code path end-to-end for one user action. Bob is a receiver; he's looking at Alice's donor card on the search screen; he taps "Send request."

**1. The tap handler** ([`search_donors_screen.dart`](lib/features/receiver/search_donors_screen.dart))

```dart
onSend: () async {
  final user = context.read<AuthProvider>().current;
  if (user == null) return;

  // Re-check activeBetween inside the callback — defends against a
  // rapid double-tap where the parent build thought there was no request.
  final already = context.read<RequestProvider>().activeBetween(
    donorTokenId: d.id,
    receiverTokenId: receiver.id,
  );
  if (already != null) return;

  final req = await context.read<RequestProvider>().send(
    donorTokenId: d.id,
    receiverTokenId: receiver.id,
    senderEmail: user.email,
    recipientEmail: d.ownerEmail,
  );
  // navigate to the status screen...
}
```

**2. The provider method** ([`request_provider.dart`](lib/state/request_provider.dart))

```dart
Future<BloodRequest> send(...) => _repo.create(...);
```

A thin pass-through. No explicit state update here — the box.watch() listener catches it.

**3. The repository method** ([`request_repository.dart`](lib/data/repositories/request_repository.dart))

```dart
Future<BloodRequest> create(...) async {
  final id = await IdGenerator.request();  // serialized through a lock chain
  final req = BloodRequest(
    id: id,
    donorTokenId: ...,
    status: RequestStatus.pending,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    // ...
  );
  await HiveBoxes.requestsBox().put(req.id, req.toMap());
  return req;
}
```

Three steps: mint an ID, build the object, write to Hive.

**4. The ID generator** ([`id_generator.dart`](lib/core/utils/id_generator.dart))

```dart
static Future<String> _mint(String prefix) {
  final completer = Completer<String>();
  _lock = _lock.then((_) async {
    final today = DateFormat('yyyyMMdd').format(DateTime.now());
    final key = 'seq_${prefix}_$today';
    final box = Hive.box(_sessionBox);
    final next = ((box.get(key) as int?) ?? 0) + 1;
    await box.put(key, next);
    completer.complete('$prefix-$today-${next.toString().padLeft(3, '0')}');
  });
  return completer.future;
}
```

The `_lock` is a static `Future<void>` that every call chains onto. Two concurrent calls never read the same counter value — they queue.

**5. The Hive write fires a `BoxEvent`**

Every `ChangeNotifier` subscribed to the requests box (there's just one: `RequestProvider`) re-reads and calls `notifyListeners()`.

**6. Widgets rebuild**

Any widget that called `context.watch<RequestProvider>()` in its build method rebuilds. That includes:
- The `SearchDonorsScreen` itself — the card that Bob just sent a request from now shows "Track status" / "Withdraw" buttons instead of "Send request"
- Bob's `ProfileScreen` → Requests tab — the new request appears in the list

Bob's UI updates live without anyone explicitly telling it to. The full round trip is: tap → repository.create → box.put → box.watch fires → provider.notifyListeners → widgets rebuild. All happens in the same tick.

**7. When Alice accepts it later**

Alice's UI calls `RequestProvider.advance(id, RequestStatus.accepted)` which calls `RequestRepository.updateStatus`, which does **two writes in sequence**:

```dart
// Close the donor token FIRST.
if (status == RequestStatus.accepted) {
  await _donorRepo.closeOnAcceptance(existing.donorTokenId, existing.id);
}
// Then update the request.
await HiveBoxes.requestsBox().put(id, updated.toMap());
```

The order matters. If the donor close succeeds and the request update fails, we end up with a "closed donor, pending request" — recoverable; the donor just won't show up in searches and a human can fix it. If we did it the other way round and the donor close failed, we'd have an "accepted request + open donor in the search list" — which is much harder to explain to a user who keeps seeing Alice in the results and thinks they can still send her a request.

This reorder was the output of the bug-hunt static review. The original code had it backwards.

---

## The theme and design system

All the visual tokens live in `lib/core/theme/`.

### `app_colors.dart`

A flat list of `const Color` constants. No `MaterialColor` swatches, no dark-mode variants yet. The full palette is 10 colors:

```dart
maroon       #6B0F1A   // primary brand
maroonDeep   #4A0A12   // auth backdrop bloom
red          #B01E2F   // logomark
ink          #1A1517   // body text
inkMuted     #6C6460   // secondary text
inkFaint     #A39C97   // disabled text, placeholders
surface      #FFFFFF   // cards, content
surfaceMuted #F5F3F1   // section fills
hairline     #E3DDD8   // 1px borders everywhere
success      #2E5A3B   // completed statuses, NEARBY tag
danger       #8B1A1A   // destructive buttons, errors
```

That's it. Every color used in the app is one of these.

### `app_text_styles.dart`

Seven type roles — display, headline, title, body, bodyStrong, caption, label — plus a `monoTag` for token IDs and a `button` for action text. Each is a factory that takes an optional `color` and `size` override.

The fonts come from `google_fonts`: Fraunces for display/headline, Inter for everything else, JetBrains Mono for the IDs.

### `app_theme.dart`

A single `ThemeData.light()` factory that wires the colors + text styles into Material 3's expected slots. Notable tweaks:
- `elevation: 0` and `scrolledUnderElevation: 0` on AppBar — no shadow-on-scroll
- Underline-style input decoration (no filled boxes)
- `SnackBar` with 2px corner radius and dark ink background
- Splash factory set to `InkSparkle.splashFactory`

The whole theme is maybe 80 lines. Editorial restraint is cheaper to maintain than elaborate theming.

---

## Token IDs, done properly

The format is `PREFIX-YYYYMMDD-###`. Example: `DNR-20260421-003`.

We chose this over UUIDs because:
- **Readable** — a user can describe their token over the phone
- **Sortable** — alphabetical order = chronological order within a prefix
- **Debuggable** — a support person looking at `RCV-20260421-015` immediately knows "15th receiver token on April 21st"

The implementation is in `lib/core/utils/id_generator.dart`. It uses a static `Future<void> _lock` that every mint call chains onto — serializing all ID creation through a single queue. This matters because without it, two rapid donor creates could both read `seq_DNR_20260421 = 5` and both write `6`, producing duplicate `DNR-20260421-006` IDs that silently overwrite each other in Hive.

The original code didn't serialize, which was caught by the bug-hunt review. The fix is in this commit — and there's a unit test that mints 10 IDs concurrently and asserts they're all unique.

---

## How to add a feature

Let's say you want to add a "donation history" view on the profile — a list of completed donations the user has done.

**Step 1. Do you need new data?**

Look at `BloodRequest`. A completed request where `recipientEmail == currentUser.email && status == completed` is a donation the current user completed. So no, you don't need new data.

**Step 2. Do you need a new repository method?**

Yes — something like `RequestRepository.completedDonationsByUser(email)`. But actually, `byRecipient(email)` already exists, and you can filter in the provider or screen. If the filter is used in multiple places, hoist it to the repository. If it's a one-off view, do it in the screen.

**Step 3. Where does it go in the UI?**

Probably a new tab on the profile, or a card in the welcome block. If it's a full screen, put it in `lib/features/profile/donation_history_screen.dart` and route to it from the existing profile.

**Step 4. How do you make it live?**

It's automatic — if you use `context.watch<RequestProvider>()` and filter the list, it rebuilds whenever the requests box changes.

That's the whole loop: figure out where the data lives, add a method if needed, drop a screen in `features/`, watch the provider. No boilerplate to invent.

---

## How to swap Hive for Firestore later

The four files in `lib/data/repositories/` are the seam. Each file is ~80 lines. Replace the bodies:

**Before (Hive):**

```dart
Future<DonorToken> create(...) async {
  final id = await IdGenerator.donor();
  final token = DonorToken(id: id, ...);
  await HiveBoxes.donorsBox().put(token.id, token.toMap());
  return token;
}
```

**After (Firestore):**

```dart
Future<DonorToken> create(...) async {
  final id = await IdGenerator.donor();
  final token = DonorToken(id: id, ...);
  await FirebaseFirestore.instance
      .collection('donors')
      .doc(token.id)
      .set(token.toMap());
  return token;
}
```

The provider layer also needs a switch — the `box.watch()` stream listener becomes `collection.snapshots()`:

**Before:**

```dart
_sub = HiveBoxes.donorsBox().watch().listen((_) {
  _all = _repo.all();
  notifyListeners();
});
```

**After:**

```dart
_sub = FirebaseFirestore.instance
    .collection('donors')
    .snapshots()
    .listen((snap) {
  _all = snap.docs.map((d) => DonorToken.fromMap(d.data())).toList();
  notifyListeners();
});
```

Estimated effort: half a day. The screens don't change at all.

---

## Tests: what's covered, what isn't

**108 unit tests pass** (see `test/unit/`). They cover:

- **`password_strength_test.dart`** — 17 cases: empty / short / weak / medium / strong, `isAcceptable` bar, meta getters
- **`blood_compatibility_test.dart`** — 12 cases: all 8 receiver groups, AB+ universal recipient, O- universal donor, incompatibility
- **`validators_test.dart`** — 29 cases: email, phone (Indian 10-digit starting 6–9), name (letters only), password (≥8), units (1–20)
- **`password_hash_test.dart`** — 7 cases: determinism with same salt, different hashes with different salts, verify true/false
- **`id_generator_test.dart`** — 6 cases including a concurrent-mint test that fires 10 simultaneous `donor()` calls and asserts all 10 IDs are unique
- **`models_test.dart`** — 9 cases: `toMap → fromMap` round-trips for all four models, `copyWith`, status flowIndex + isTerminal
- **`auth_repository_test.dart`** — 9 cases: sign up, duplicate email, case-insensitive email, login success/wrong password/unknown email, profile update, logout
- **`donor_repository_test.dart`** — 7 cases: create, byId, byOwner, available excludes closed, closeOnAcceptance pins the request ID, sort by createdAt desc
- **`request_repository_test.dart`** — 10 cases: create, accepted status closes the donor token, non-accepted updates don't, `activeBetween` returns null for completed/withdrawn/declined, sender/recipient filters

All repository tests use a `HiveTestHarness` helper (in `test/helpers/test_app.dart`) that spins up Hive against a fresh temp directory per test and tears it down after. No mocks — these are real integration tests against real Hive storage.

**Widget tests are deferred.** They were authored in the first pass against the pre-tightening UI (stacked eyebrows, different labels, emphasized Profile FAB) and need rewriting now that the UI settled. Follow-up.

To run the tests:

```bash
flutter test test/unit/
# 00:03 +108: All tests passed!
```

---

## Things that caused bugs and how we fixed them

Four parallel static-review agents audited the code before we built the APK. Here's what they caught and what we did.

### UI/AI-smell audit

Found **0 "red flag" AI cliches** (no gradients, no glows, no emoji, no rainbow pills) but **13 questionable patterns** — overuse of ALL-CAPS eyebrow labels, a centered-giant-title splash template, a FAB-style circular Profile item in the bottom nav, Material-3 chip-style status pills with `color@0.08` fill + `color@0.35` border, a decorative glossy notch on the blood drop.

Fixed in this commit: dropped `HOME`, `YOUR ACTIVITY`, `ONE`, `TWO` eyebrows; removed `.toUpperCase()` from form labels; simplified the splash backdrop from 5 circles to 1; left-aligned the auth title at size 38 instead of centered at 44; flattened the bottom nav so Profile looks identical to the other items; replaced the status pill gradient with a flat hairline border; removed the blood drop's highlight notch.

### Layout / responsive audit

Found **3 CRITICAL** overflow risks (Profile TabBar labels on 360px, Dashboard role card text without ellipsis, DetailRow value column) and **10 HIGH** risks (various list card names without `maxLines`, no tablet `maxWidth` constraints).

Fixed: shortened the TabBar to "Tokens (N)" / "Requests (N)"; added `maxLines` + `ellipsis` on role card title/body; added the same on DetailRow values; wrapped Dashboard, Profile, and status screens in `Center + ConstrainedBox(maxWidth: 560)` so they don't stretch edge-to-edge on tablets.

### Bug hunt

Found **2 CRITICAL** correctness bugs:

1. **Non-atomic ID minting.** Two concurrent `IdGenerator.donor()` calls could read the same sequence counter, write it back incremented, and produce duplicate `DNR-YYYYMMDD-###` IDs that silently overwrote each other in Hive. Fixed by serializing all mint calls through a static `Future<void> _lock` chain.

2. **Non-atomic accept → close transition.** The request was written as `accepted` before the donor was closed. If the donor close failed (or the app crashed between the two writes), we'd be left with an accepted request whose donor was still in the search list — a state that's hard to reconcile and will confuse every user who keeps seeing the same donor. Fixed by swapping the order: close the donor first, then write the accepted request. The inverse failure (closed donor with pending request) is far easier to recover from.

**7 HIGH-severity** bugs: `current!` null-bangs on the session user in form submit paths (replaced with null-check + snackbar), double-submit hazards on status advance and accept/decline buttons (converted screens to StatefulWidget with `_busy` guards), unhandled errors in `AuthProvider.init()` that would crash the whole app on a corrupt cached session (wrapped in try/catch — now it clears the session and routes to login), `showDatePicker` with an initial date outside the allowed range (clamping added).

**7 MEDIUM** and **6 LOW** issues tracked but deferred — mostly style hints, idempotence nits on provider `init()` calls, and `withOpacity` deprecation warnings.

### Testing

No bugs found — the test agent wrote 108 unit tests covering every utility and every repository, and they all pass. The concurrent-mint test specifically catches any regression in the ID generator's serialization lock.

---

## One more thing: the design principle we kept coming back to

Typography does the work.

Everywhere we were tempted to add a colored chip, a shadow card, a gradient, an icon badge — we asked: can a font weight, a size change, or a one-line eyebrow carry the same meaning?

Usually yes. And the result reads as intentional rather than decorated. Every time we shipped a new component, we reviewed it for whether it was doing something the existing type scale couldn't, and if not, we deleted it.

That's how the codebase ended up with one button widget, one card widget, one text field, one status tracker, and a lot of consistently-tuned Text + color + spacing combinations. Fewer moving parts means fewer ways for things to go wrong — and means a new developer can predict what a screen looks like before they open the file.
