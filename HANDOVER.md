# VirtuaNetLab — Handover

Blockers 1–5 from the build plan are done and committed. Items 6–10 and the
polish list are not started. This document is the spec for whoever picks it up.

> **Deploying?** See `DEPLOYMENT.md` — step-by-step for Cloud Run + Firebase
> Hosting, written to be followed start to finish.
>
> **Note on security rules.** `firestore.rules` and `storage.rules` are now
> deliberately wide open (`allow read, write: if true`) because this is a
> private coursework demo for a handful of known students. The hardened,
> deny-by-default versions described in section 5 below are preserved verbatim
> as `firestore.rules.production` / `storage.rules.production` and are restored
> with a file copy. The reasoning and the exact trade-off are documented in the
> header of each file.


---

## Part 1 — What was done

### 1. Edge schema mismatch (fixed)

`simulation_engine/app/core/graph_parser.py` only looked for `fromNode` /
`source` / `sourceNode`, but the Flutter client serialises
`sourceNodeId` / `targetNodeId`. Since no key matched, **every edge was silently
dropped**, the graph came out with N nodes and 0 edges, and every ping failed
with `NO_PHYSICAL_ROUTE`. This was the single reason nothing worked end to end.

- Added `sourceNodeId` / `targetNodeId` (and `sourceInterface` /
  `targetInterface`) to the parser's fallback key lists.
- Interface normalisation now also reads `status`, `vlan` and `acls`.
- Regression test: `tests/test_graph_parser_flutter_payload.py`, fed from
  `tests/fixtures/flutter_payloads.py`, which holds a **verbatim** Flutter
  payload rather than a hand-written one. A fixture written to match the parser
  would have passed against the bug, which is exactly how it survived this long.

### 2. Double simulation dispatch (fixed)

The client POSTed straight to the engine **and** wrote the queue document that
fires `onSimulationQueueCreated`, which POSTed again — two simulations per
click, racing on the same queue doc and producing two result documents. The
direct POST was also unsigned and hard-coded to `http://localhost:8080`, so it
was dead in any deployed build.

- Removed the direct-POST path and the `http` dependency from
  `simulation_repository.dart`. The queue write is now the only action.
- The Cloud Function is the single signed dispatcher.
- **Grading criteria are now resolved server-side** in `onSimulationQueue.ts`
  from the level document. The client names the level but never supplies the
  criteria — otherwise a student could submit an empty criteria list and pass
  every level automatically.
- The function throws if `HMAC_SECRET_KEY` is unset or still the published
  default, rather than silently signing with a known secret.

### 3. Property inspector (added)

`lib/features/topology/widgets/node_property_inspector.dart`. Edits IP, subnet
mask, default gateway, VLAN id, interface up/down, and firewall ACL allow/deny
rules. Fields shown depend on device type (gateway on hosts, ACLs on firewalls,
OSPF on routers). Without this, no criterion beyond "is there a cable" could
ever pass.

Model changes (`topology_model.dart`, Freezed regenerated): `InterfaceConfig`
gained `status`, `vlan`, `acls`; new `AclRule`; `DeviceNode` gained
`ospfEnabled`.

Two deliberate behaviour changes:

- **Devices now spawn with no IP address.** They previously got
  `192.168.1.<n>` automatically. That handed students the answer to most of the
  addressing levels and quietly put every device on one subnet, so unrelated
  levels passed by accident.
- **Port counts are realistic** (PC 1, router 2, switch 4) instead of two
  interfaces on everything, and labels are per-type sequential (`PC1`, `PC2`,
  `Router1`) because level criteria reference devices by label.

### 4. Drag correctness (fixed)

- Raw pointer position is held unsnapped in `_dragPosition` for the whole
  gesture; the grid snap happens once on pan end. Snapping every frame applied
  each delta to an already-rounded value, so error accumulated and the node
  lagged the cursor.
- `watchTopology` ignores stream events while `_isDragging`, so the echo of our
  own save cannot reset a node mid-drag.
- **Separate bug found and fixed:** `onPanEnd` read `node.position` from a stale
  build closure, which holds pre-drag coordinates — the node jumped back to
  where the gesture started. It now uses the live drag position.
- Firestore saves debounced (600 ms); `RepaintBoundary` per node.

### 5. Security baseline (added)

`firestore.rules`, `storage.rules`, `firestore.indexes.json`, all wired into
`firebase.json`. There were no rules files at all, so both services ran on
console defaults with client-side route guards as the only control — and those
only decide which screen to draw.

Deny-by-default throughout. Worth knowing:

- Students cannot change their own role. A self-`PATCH` to `admin` was
  otherwise possible and would have exposed every staff screen and every other
  student's data.
- `student_progress`, `simulation_results` and topology versions are
  **server-write-only**, so a student cannot mark levels passed without
  building anything. Cloud Functions use the Admin SDK and bypass rules, so the
  grader still writes fine.
- `simulation_queue` creates must be for yourself and start `status='queued'`.
- `exercises/{id}/private/**` (solution key) is staff-only.
- Reference collections are listed individually, not by wildcard: an extra
  wildcard match would OR with the specific rules and silently re-open the
  collections they protect.

`config.py` no longer defaults `HMAC_SECRET_KEY` to the published value —
production hard-exits, development generates a random per-process key and warns.

### ⚠️ Action required by the owner

The service-account JSON and `.env` were excluded before `git init`, so they are
**not** in history. But the key sat unprotected on disk for some time.
**Rotate it in the Google Cloud console.** Then generate a real HMAC secret:

```bash
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

Set it as `HMAC_SECRET_KEY` for both the engine and the Cloud Function — the
signature only verifies if the two match.

### Verification

- `flutter analyze` — 0 errors (4 pre-existing `withOpacity` deprecation infos).
- Engine tests — **30 passed**.
  `pytest` is not on the system Python; use the venv:
  ```
  simulation_engine\venv\Scripts\python.exe simulation_engine\run_tests.py
  ```

---

## Part 2 — What is left

### 6. Topic / Level data model

Firestore collections `virtuanetlab/app/topics` and `.../levels` (rules and
indexes for both already exist).

```
Topic  { id, title, order, description }

Level  {
  id, topicId, order, title, brief,
  starterTopology: { nodes: [...], edges: [...] } | null,
  allowedDeviceTypes: ['pc', 'switch', ...],
  successCriteria: [ ... ],
  passMark: 70 | 100          // configurable per level
}
```

Add Freezed models in `lib/data/models/`, a `LevelRepository` alongside the
existing repositories, and a `LevelProvider`. Match the existing patterns.

**New grader criterion needed: `ping_must_fail`.** Several levels teach that two
hosts *should not* reach each other (different subnets, different VLANs). Treat
a successful ping as a failure of the criterion. Every new criterion needs a
test using a real Flutter payload — see the note in item 1 about why
hand-written fixtures are not good enough.

### 7. Progression

```
student_progress/{uid} = {
  topics: { topic1: { highestLevelUnlocked: 2, passedLevels: ['l1'] } }
}
```

Server-write-only, so this must be written by the Cloud Function after grading,
**not** by the client. Passing the last level of a topic unlocks the next topic.

### 8. Dashboard

Topics as cards; opening one shows levels as a vertical path (level 1 top),
completed ticked, current highlighted, future locked.

### 9. Level loop on the canvas

`CanvasBuilderScreen` needs an optional `levelId`. When set: show the brief,
restrict `DevicePalette` to `allowedDeviceTypes`, and on Run save → enqueue one
signed simulation → evaluate. Pass: success dialog, mark passed, unlock next,
offer "Next level" / "Back to topic". Fail: show the grader's specific reason
("PC1 cannot reach PC2 — check the cable path"). Unlimited retries.

### 10. Level-defined endpoints

`_handleRunSimulation` currently hard-codes `nodes.first → nodes.last`, which is
meaningless once a level has more than two devices. Endpoints must come from the
level's criteria. **This is required for items 6–9 to work at all.**

### Polish

- **Cable geometry** — nodes are 90×90 and port handles sit at `top: 35`,
  `left/right: -10`. `cable_painter.dart` uses a `+40` centre offset, so cables
  do not meet the handles. Anchor to the handles.
- **Edges** — no deletion, no duplicate/self-link validation, and the same
  interface can be double-booked.
- **Grid painter** — ~15,000 `drawCircle` calls per frame; use `drawPoints`.
- **Simulation realism** — currently reachability is pure graph connectivity.
  For the levels to teach anything it needs subnet/mask matching (different
  subnets must **not** ping without a router), default-gateway logic, and real
  VLAN segmentation. OSPF can stay simple but should build a route between two
  routers. Document what is and isn't modelled so the scope is defensible.

### Suggested order

10 → 6 → 7 → 9 → 8, then polish. Item 10 is small and unblocks the rest; the
realism work is the largest piece and is what makes the levels meaningful.
