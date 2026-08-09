<<<<<<< HEAD
# VirtuaNetLab

A web-based network topology lab. Students build networks on a drag-and-drop
canvas; lecturers author exercises and grade; admins manage users and roles.

Flutter (web) front end, Firebase back end. There is **no separate backend
server to run** — the Python simulation engine that earlier versions used has
been retired, and everything now runs on Firebase.

---

## 1. How the system fits together

```
    Browser (Flutter Web)
            |
            |  Firebase SDK (auth token on every request)
            v
    +-------------------------------------------+
    |  Firebase project: backend-testing-d4ece  |
    |                                           |
    |  Auth        -- email/password login      |
    |  Firestore   -- all app data              |
    |  Storage     -- uploaded files            |
    |  Functions   -- 2 server-side functions   |
    |  Hosting     -- serves the built web app  |
    +-------------------------------------------+
```

**The client talks only to Firebase.** No custom API, no Cloud Run service, no
HMAC secret to manage.

### The two Cloud Functions

Both live in `functions/src/` and exist for one reason: **only a server can set
custom auth claims.** A browser cannot grant itself a role.

| Function | Type | What it does |
|---|---|---|
| `onUserCreated` | Auth trigger | Fires on registration. Reads the new user's Firestore doc, sets custom claims `{ role, vnl_auth, departmentId }` on their Auth token. Defaults role to `student`. |
| `setAdminUserRole` | Callable | An admin calls it to change someone's role. Verifies the caller's token claim is `admin`, then updates both the Firestore doc and the target's custom claims. |

Custom claims land in the user's ID token, which is what Firestore rules read.
That's the whole authorisation chain.

### Where data lives

Everything is namespaced under a single root, `virtuanetlab/app/...`, so this
Firebase project can host other projects without collisions. Paths are defined
once in `lib/core/constants/app_constants.dart` — use those getters, never
hard-coded strings.

Main collections: `users`, `classes`, `courses`, `exercises`, `topologies`,
`student_progress`, `topics` (with nested `levels`), `device_catalogue`.

### Front-end layout (`lib/`)

| Path | Contents |
|---|---|
| `main.dart` | Entrypoint: init Firebase, seed root admin, run app |
| `app/` | `app.dart` (providers + MaterialApp), `app_routes.dart` (go_router + role guards), `theme/` |
| `core/` | constants, enums, failures, services, utils, shared widgets |
| `data/models/` | Freezed models — **`.freezed.dart` / `.g.dart` are generated, never edit by hand** |
| `data/repositories/` | All Firestore reads/writes (auth, exercise, topology) |
| `features/` | One folder per area: `auth`, `dashboard`, `admin`, `lecturer`, `exercises`, `topology` |

The canvas is `features/topology/` — `canvas_builder_screen.dart` plus the
painters, device palette, and node property inspector.

Routing is role-guarded in `app_routes.dart`: not logged in → `/login`; logged
in → dashboard for your role; `/admin-dashboard` requires `admin`,
`/lecturer-dashboard` requires `lecturer` or `admin`.

---

## 2. Local development

### Prerequisites

Flutter SDK (Dart `^3.12.2`), Node.js 20, and the Firebase CLI
(`npm install -g firebase-tools`).

Node 20 specifically — `functions/package.json` pins `"engines": { "node": "20" }`,
and deploying from a different major version causes runtime mismatches.

### First-time setup

```bash
flutter pub get
npm --prefix functions install
firebase login
```

### Windows: if `firebase` won't run in PowerShell

You may see this:

```
firebase : File C:\Users\<you>\AppData\Roaming\npm\firebase.ps1 cannot be
loaded because running scripts is disabled on this system.
```

Nothing is wrong with the Firebase CLI. npm installs a PowerShell shim
(`firebase.ps1`), and Windows blocks unsigned local scripts by default when the
execution policy is `Restricted`/`Undefined`. Fix it for your user account only
— no admin rights needed, and the machine-wide policy is untouched:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

`RemoteSigned` still blocks unsigned scripts *downloaded from the internet*; it
only permits locally-created ones like npm's shims. Verify with
`Get-ExecutionPolicy -List`.

Alternatively, avoid it entirely by running Firebase commands from **cmd.exe**,
which doesn't use the `.ps1` shim.


### If you change a Freezed model

Generated files are committed, so you only need this after editing a
`*_model.dart`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Run the app

```bash
flutter run -d chrome
```

### Check your work before deploying

```bash
flutter analyze                              # Dart: 0 errors expected
npm --prefix functions run lint               # TypeScript typecheck (tsc --noEmit)
flutter test                                  # Dart tests
```

> `npm --prefix functions test` currently reports **"No tests found"** — there
> are no test files under `functions/`. That is expected, not a failure.

### Optional: emulators

Runs Auth, Firestore, Storage, Functions and Hosting locally so you never touch
live data:

```bash
firebase emulators:start
```

Ports are set in `firebase.json` (Auth 9099, Firestore 8085, Storage 9199,
Functions 5001, Hosting 5000, plus the emulator UI).

---

## 3. Going live — do these in order

### Step 1 — Confirm the target project

`.firebaserc` pins the default project to `backend-testing-d4ece`, so a fresh
clone deploys to the right place without any extra setup. Confirm it:

```bash
firebase use
```

That should print `backend-testing-d4ece`. If you're not logged in yet, run
`firebase login`, and `firebase projects:list` to see what your account can
reach.

The project ID is also baked into `lib/firebase_options.dart` and `firebase.json`.
**Switching to a different project means re-running `flutterfire configure`** —
changing `.firebaserc` alone would deploy the site to the new project while the
app inside it still authenticates against the old one.

### Step 2 — Decide your security rules (read this properly)

`firestore.rules` and `storage.rules` are currently **wide open**:

```
allow read, write: if true;
```

Anyone who opens the browser console can read and overwrite any document —
including changing their own `role` to `admin`, marking every level passed, and
reading other students' work. The rules files say this was a deliberate choice
for a small private demo.

The hardened, deny-by-default rules are preserved as `firestore.rules.production`
and `storage.rules.production`. To switch to them:

```bash
copy firestore.rules.production firestore.rules
copy storage.rules.production storage.rules
firebase deploy --only firestore:rules,storage:rules
```

Then **log in as each role and click through** — student, lecturer, admin. The
hardened rules make `student_progress` server-write-only and block self-role
changes, so anything that quietly depended on open access will start failing
with `permission-denied`. Find that now, not in front of an audience.

> If the app will be reachable by anyone outside your test group, treat the
> hardened rules as mandatory.

### Step 3 — Deploy rules and indexes

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage:rules
```

Composite indexes come from `firestore.indexes.json`. Deploy them **before**
the app goes live — a missing index makes queries fail at runtime with a
console link, which is a poor way to discover it.

### Step 4 — Deploy the Cloud Functions

```bash
firebase deploy --only functions
```

`firebase.json` has a predeploy hook that runs `npm --prefix functions run build`
(i.e. `tsc`), so a TypeScript error stops the deploy before anything ships.

Verify both appear:

```bash
firebase functions:list
```

You should see `onUserCreated` and `setAdminUserRole`.

### Step 5 — Build the web app

```bash
flutter build web --release
```

Output goes to `build/web`, which is exactly what `firebase.json` serves as
Hosting `public`.

`DevicePreview` (the device-frame wrapper in `main.dart`) is gated on
`!kReleaseMode`, so a release build automatically excludes it. Don't ship a
debug build — you'd get the preview chrome in production.

### Step 6 — Preview, then deploy Hosting

Check it on a real URL before going live:

```bash
firebase hosting:channel:deploy preview
```

That gives a temporary URL. Once it looks right:

```bash
firebase deploy --only hosting
```

Or ship everything at once:

```bash
firebase deploy
```

### Step 7 — Create the real root admin

This step matters, because the app's automatic seeding is **not** a real
account.

On launch, `AdminSeedService` writes a Firestore user document with the literal
UID `root_admin_seed` if no admin exists. That document has **no matching
Firebase Auth identity** — nobody can log in as it. It only stops the admin
screens looking empty.

To get a working administrator:

1. Register normally through the app UI with your real email.
2. In the Firebase console → Firestore, open `virtuanetlab/app/users/{yourUid}`
   and set `role` to `admin`.
3. **Sign out and sign back in.** Custom claims are refreshed when the ID token
   is reissued; until then Firestore rules still see your old role.
4. From then on, use the in-app admin screens (backed by `setAdminUserRole`) to
   promote everyone else — that path updates the Firestore doc *and* the custom
   claims together, which manual console edits do not.

> After step 3 works, delete the `root_admin_seed` document. Under the hardened
> rules a placeholder admin doc with no owner is exactly the kind of thing you
> don't want lying around.

### Step 8 — Post-deploy smoke test

On the live URL:

- [ ] Register a new account → lands on the student dashboard
- [ ] In the console, confirm custom claims were set (proves `onUserCreated` ran)
- [ ] Open the canvas, add devices, drag them, connect a cable
- [ ] Reload the page — the topology persists
- [ ] Edit a node in the property inspector; confirm it saves
- [ ] Log in as admin → admin dashboard loads
- [ ] As a student, try navigating directly to `/admin-dashboard` → redirected
- [ ] Check `firebase functions:log` for errors

### Rolling back

```bash
firebase hosting:rollback
```

Functions have no one-command rollback — redeploy from a known-good commit.

---

## 4. Things worth knowing before you change code

**`main.dart` swallows startup errors.** Both the Firebase init and the admin
seed are wrapped in `try`/`catch` with empty handlers. If Firebase is
misconfigured the app boots anyway and fails later in a confusing place. When
debugging a blank or broken page, print inside those catches first.

**Route guards are cosmetic.** `app_routes.dart` decides which screen to draw.
It does not stop anyone calling the Firestore REST API directly with a valid
token. Real enforcement is in the rules file — which is why step 2 matters.

**Generated model files are committed.** After editing any `*_model.dart`, run
`build_runner`, or the `.freezed.dart` / `.g.dart` files go stale and produce
confusing serialisation bugs.

**Never commit secrets.** `.gitignore` already excludes service-account JSON
and `.env` files. If a service-account key was ever exposed on disk, rotate it
in the Google Cloud console.

**`functions/tsconfig.json` uses `module`/`moduleResolution: node16`.** These
must stay in sync — setting one to `node16` and the other to `commonjs`/`node`
is a compile error. (`node` alias = `node10`, deprecated and removed in
TypeScript 7.)

---

## 5. Command reference

| Task | Command |
|---|---|
| Install Dart deps | `flutter pub get` |
| Install Functions deps | `npm --prefix functions install` |
| Regenerate models | `dart run build_runner build --delete-conflicting-outputs` |
| Run locally | `flutter run -d chrome` |
| Analyze Dart | `flutter analyze` |
| Typecheck Functions | `npm --prefix functions run lint` |
| Run Dart tests | `flutter test` |
| Emulators | `firebase emulators:start` |
| Build for production | `flutter build web --release` |
| Deploy everything | `firebase deploy` |
| Deploy one part | `firebase deploy --only hosting` (or `functions`, `firestore:rules`) |
| Preview channel | `firebase hosting:channel:deploy preview` |
| Function logs | `firebase functions:log` |
| Roll back hosting | `firebase hosting:rollback` |
=======
# virtualnetworkinglab
>>>>>>> 9cb052fd51a09395c12472e5dbfba610cbcaa36c
