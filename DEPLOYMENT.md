# VirtuaNetLab — Deployment Guide

Getting the whole app running on Google Cloud, with nothing pointing at your
laptop. Written to be followed top to bottom the first time. Later deploys are
just Part 8.

**Project ID used throughout:** `backend-testing-d4ece`
(from `lib/firebase_options.dart`. If yours differs, substitute it everywhere.)

### What runs where, when you're done

| Piece | Runs on | Talks to |
|---|---|---|
| Flutter web app | Firebase Hosting | Firestore + Auth directly |
| `onSimulationQueueCreated` | Cloud Functions | Firestore → Cloud Run engine |
| FastAPI simulation engine | **Cloud Run** | Firestore + Storage (Admin SDK) |

The browser never calls Cloud Run. It writes a queue document to Firestore; the
Cloud Function notices, signs the payload with HMAC and forwards it to Cloud
Run. That is why there is no engine URL anywhere in the Flutter code, and why
the app has no `localhost` dependency once deployed.

```
Browser → Firestore (queue doc) → Cloud Function → [HMAC] → Cloud Run engine
                    ↑                                              │
                    └────────── results written back ──────────────┘
```

---

## Part 0 — Install the tools (once)

```bash
node --version      # need 20.x — Functions are pinned to node 20
python --version    # need 3.11+
flutter --version
```

Then:

```bash
npm install -g firebase-tools
```

Install the **gcloud CLI** from https://cloud.google.com/sdk/docs/install
(Windows: run the installer, then reopen your terminal so `gcloud` is on PATH.)

Log in to both:

```bash
firebase login
gcloud auth login
gcloud config set project backend-testing-d4ece
```

---

## Part 1 — Enable billing and the APIs

Cloud Run and Cloud Build both need billing enabled. The free tier is generous
and a project this size will realistically cost nothing, but the card has to be
on file or step 4 fails with `PERMISSION_DENIED`.

1. https://console.cloud.google.com/billing → link a billing account to
   `backend-testing-d4ece`.
2. Enable the APIs:

```bash
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com secretmanager.googleapis.com
```

This takes a minute or two. It is safe to re-run.

---

## Part 2 — Rotate the leaked service-account key

**Do this before anything else.** `HANDOVER.md` flagged it and it is still
outstanding: `simulation_engine/backend-testing-d4ece-firebase-adminsdk-*.json`
is a live private key that has been sitting unprotected on disk.

1. https://console.cloud.google.com/iam-admin/serviceaccounts → pick the
   `firebase-adminsdk-...` account → **Keys**.
2. Delete the existing key.
3. Delete the local file:

```bash
del simulation_engine\backend-testing-d4ece-firebase-adminsdk-fbsvc-67f703bd0d.json
```

You do **not** need to create a replacement key. On Cloud Run the engine
authenticates with its runtime service account automatically — that is what
`_ensure_firebase_app()` in `storage_service.py` relies on when it calls
`initialize_app()` with no credentials. Key files are only for local runs.

> It is already in `.gitignore`, and `.dockerignore` / `.gcloudignore` now keep
> it out of the container image and the Cloud Build upload as well.

---

## Part 3 — Generate the HMAC secret

One value, shared by exactly two places. It is the only thing authenticating
the engine, so if they don't match you get `401 Invalid HMAC signature` on
every simulation.

```bash
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

Copy the output somewhere temporary. You'll paste it twice: Part 4 (Cloud Run)
and Part 6 (Cloud Function).

---

## Part 4 — Deploy the engine to Cloud Run

```bash
cd simulation_engine

gcloud run deploy virtuanetlab-engine ^
  --source . ^
  --region europe-west2 ^
  --allow-unauthenticated ^
  --memory 1Gi ^
  --timeout 60 ^
  --set-env-vars "ENV=production,FIREBASE_STORAGE_BUCKET=backend-testing-d4ece.firebasestorage.app,HMAC_SECRET_KEY=PASTE_YOUR_SECRET_HERE"
```

> The `^` line continuations are for Windows `cmd`. In PowerShell use a
> backtick `` ` ``; in bash use `\`. Or just put it all on one line.

When it asks about creating an Artifact Registry repository, say yes.
First build takes 3–5 minutes.

It finishes by printing:

```
Service URL: https://virtuanetlab-engine-xxxxxxxxxx.europe-west2.run.app
```

**Copy that URL.** You need it in Part 6.

### Notes on those flags

- `ENV=production` — deliberate. In `development`, `hmac_auth.py` accepts
  requests with **no signature at all**, which would leave the endpoint wide
  open to the internet. `config.py` also hard-exits in production if
  `HMAC_SECRET_KEY` is missing, so a bad deploy fails fast instead of running
  insecurely.
- `--allow-unauthenticated` — this exposes the URL publicly, but the HMAC
  signature still gates `/api/v1/simulate`, so an unsigned request gets a 401.
  This is the one place where the "open rules" decision does *not* apply; leave
  the HMAC on.
- `--region` — `europe-west2` is London. Any region works; just use the same
  one consistently.

### Check it

```bash
curl https://YOUR-SERVICE-URL/health
```

Expect `{"status":"healthy",...,"environment":"production"}`.

If instead you get "container failed to start and listen on the port defined by
the PORT environment variable", the Dockerfile `CMD` is not expanding `$PORT` —
that is fixed in the current Dockerfile, so make sure you deployed the latest.

---

## Part 5 — Deploy Firestore rules, indexes and Storage rules

```bash
cd ..
firebase use backend-testing-d4ece
firebase deploy --only firestore:rules,firestore:indexes,storage
```

⚠️ **These rules are wide open on purpose.** `firestore.rules` and
`storage.rules` currently allow read and write to anyone, matching what you
already set in the console. That is a deliberate choice for a small private
school project and the reasoning — plus exactly what it gives up — is written
at the top of both files.

The hardened versions are preserved as `firestore.rules.production` and
`storage.rules.production`. If the site is ever opened up:

```bash
copy firestore.rules.production firestore.rules
copy storage.rules.production storage.rules
firebase deploy --only firestore:rules,storage
```

---

## Part 6 — Point the Cloud Function at Cloud Run

Two settings: the URL (plain env var) and the secret (Secret Manager).

**a) The URL.** Create `functions/.env` — copy `functions/.env.example` and
paste the Cloud Run URL from Part 4:

```
FASTAPI_ENGINE_URL=https://virtuanetlab-engine-xxxxxxxxxx.europe-west2.run.app
```

No trailing slash, and no `/api/v1/simulate` — the code appends that.

**b) The secret.** Same value as Part 4:

```bash
firebase functions:secrets:set HMAC_SECRET_KEY
```

Paste the secret at the prompt. It goes into Secret Manager, not into any file.

**c) Deploy:**

```bash
firebase deploy --only functions
```

If it warns about the secret not being accessible, grant it and redeploy —
Firebase usually offers to fix this itself.

---

## Part 7 — Build and deploy the Flutter web app

```bash
flutter build web --release
firebase deploy --only hosting
```

Your site is live at:

- https://backend-testing-d4ece.web.app
- https://backend-testing-d4ece.firebaseapp.com

`firebase.json` now has a `hosting` block serving `build/web` with a SPA
rewrite (everything → `index.html`), which go_router needs — without it, a
refresh on `/dashboard` returns a 404 from Hosting rather than loading the app.

---

## Part 8 — Redeploying later

You rarely need all of it. Deploy only what changed:

| Changed | Command |
|---|---|
| Flutter code | `flutter build web --release && firebase deploy --only hosting` |
| Cloud Function | `firebase deploy --only functions` |
| Python engine | `cd simulation_engine && gcloud run deploy virtuanetlab-engine --source . --region europe-west2` |
| Rules | `firebase deploy --only firestore:rules,storage` |
| Everything Firebase | `firebase deploy` |

Cloud Run keeps existing env vars across `gcloud run deploy`, so you don't need
to repeat `--set-env-vars` unless a value changed.

---

## Part 9 — End-to-end test

1. Open https://backend-testing-d4ece.web.app and register an account.
2. Open the canvas builder, drop **two PCs**, cable them together.
3. Press **Run**.
4. Expected: the queue dialog goes `queued → processing → completed` and shows
   a ping result.

Watch it happen server-side:

```bash
firebase functions:log --only onSimulationQueueCreated
gcloud run services logs read virtuanetlab-engine --region europe-west2 --limit 50
```

### If it stays "queued"

The Cloud Function never fired. Check it deployed: `firebase functions:list`.

### If it goes "failed"

Read the `error` field on the queue document in the Firestore console. It is
written there verbatim by the trigger's catch block:

| Error text | Cause | Fix |
|---|---|---|
| `FASTAPI_ENGINE_URL is not configured...` | `functions/.env` missing or wrong | Part 6a, redeploy functions |
| `401 Invalid HMAC signature` | The two secrets don't match | Re-set both, Part 4 and Part 6b |
| `HMAC_SECRET_KEY is unset or still the default` | Secret never set | Part 6b |
| `timeout of 45000ms exceeded` | Cold start on a big topology | Retry; consider `--min-instances 1` |

### If the ping fails but everything else works

That's the app, not the deployment. See "What's still outstanding" below —
reachability is currently pure graph connectivity, and endpoints are hard-coded
to first→last node.

---

## Part 10 — Local development (optional)

Deployment does not stop you working locally.

**Engine:**

```bash
cd simulation_engine
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
python main.py
```

Leave `ENV=development` in the local `.env`. That relaxes the signature check
so you can `curl` the engine by hand — which is exactly why it must never be
the setting on Cloud Run.

**Flutter:** `flutter run -d chrome` — it talks to the real cloud Firestore, so
simulations still run on Cloud Run. That's usually what you want.

---

## Cost

Realistically £0 for a project this size. Cloud Run bills only while a request
is being handled and scales to zero; a few students clicking Run is far inside
the free tier. Firestore, Hosting and Functions likewise.

The two things that could cost money: leaving `--min-instances 1` set (keeps a
container warm 24/7), and the missing Storage size caps now that
`storage.rules` is open. Neither matters over a demo period, but check the
billing dashboard if you leave it deployed for months.

---

## What's still outstanding (not deployment issues)

The app deploys and runs, but from `HANDOVER.md` these are unfinished. In the
suggested order:

1. **Level-defined endpoints (item 10).** `_handleRunSimulation` hard-codes
   `nodes.first → nodes.last`. Small fix, and it blocks everything below it.
2. **Topic / Level data model (item 6).** Firestore collections, Freezed
   models, `LevelRepository`, `LevelProvider`. Also needs the new
   `ping_must_fail` grader criterion.
3. **Progression (item 7).** `student_progress`, written by the Cloud Function
   after grading.
4. **Level loop on the canvas (item 9).** Brief, restricted palette, pass/fail
   dialogs.
5. **Dashboard (item 8).** Topic cards → vertical level path.

Then the polish list: cable geometry, edge deletion, the grid painter's 15,000
`drawCircle` calls, and — the big one — **simulation realism**. Right now
reachability is pure graph connectivity, so two hosts in different subnets ping
successfully. Topics 3 and 4 in the build plan cannot teach anything until
subnet matching and VLAN segmentation are actually enforced.

None of these block deploying. Deploy now, keep building against the live
stack.
