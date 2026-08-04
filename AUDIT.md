# VirtuaNetLab — Project Audit

Date: 2026-08-04
Scope: Flutter app (`lib/`), Firebase Cloud Functions (`functions/`), Python simulation engine (`simulation_engine/`)
Build health: `flutter analyze` → **0 errors, 4 infos** (deprecated `withOpacity`)

---

## 1. What has been built

### 1.1 Flutter client (Dart, Provider + go_router + Freezed)
| Area | Status |
|---|---|
| Auth (login/register, `AuthProvider`, `auth_repository`) | Implemented |
| Role-based routing guards (`app_routes.dart`) — student / lecturer / admin | Implemented |
| Dashboards: student, lecturer, admin (+ sidebars, tabs, analytics charts) | Implemented |
| Admin area: overview, students, lecturers, courses, audit logs, provisioning service | Implemented |
| Lecturer area: overview, class management, exercise authoring, grading centre | Implemented |
| Free-practice progression screen (Levels 1–4, gated by `user.freePracticeLevel`) | Implemented (UI only) |
| **Topology canvas builder** | Implemented (see §2) |
| Data models (Freezed + json_serializable): user, class, exercise, simulation, topology | Implemented, codegen committed |
| Repositories: auth, exercise, topology, simulation | Implemented |
| Theming, logo/credits widgets, validators, timestamp converter, failures | Implemented |
| Root-admin bootstrap seeding on app launch | Implemented |
| Device Preview wrapper for cross-device testing | Implemented |

### 1.2 Firebase Cloud Functions (TypeScript, v2)
- `onUserCreated` auth trigger.
- `onSimulationQueueCreated` Firestore trigger on `virtuanetlab/app/simulation_queue/{queueId}`: sets `processing`, loads topology + private exercise solution key, signs payload with HMAC-SHA256, POSTs to the FastAPI engine, marks `failed` on error.
- `setAdminUserRole` callable.
- HMAC util, secret param (`HMAC_SECRET_KEY` via Secret Manager), Jest config present.

### 1.3 Python simulation engine (FastAPI, NetworkX, Scapy)
- `/health` and `/api/v1/simulate` endpoints, HMAC dependency, CORS, Dockerfile (Cloud Run ready).
- `graph_parser.py` → topology JSON to `nx.DiGraph` (duplex edges, interface dict, OSPF flag).
- `packet_tracer.py` → synthesizes a Scapy ICMP echo packet, shortest-path hop walk, per-hop latency, interface `status` check, ACL evaluation, packet-stream frames for animation, RTT.
- `auto_grader.py` → criteria types: `ping_reachability`, `vlan_tagging`, `ospf_adjacency`, `interface_status`; weighted score, 70% pass mark.
- `storage_service.py` → uploads `summary.json`, `stdout.log`, `stderr.log`, `packet_stream.json` to Storage; writes `simulation_results/{id}` and updates the queue doc to `completed`/`failed` with `resultId`.
- Pytest suite: graph parser, HMAC auth, main, packet tracer, storage service.

### 1.4 Data architecture
Single namespaced root `virtuanetlab/app/...` with ~25 collection path getters in `AppConstants` (users, classes, exercises, topologies, simulation_queue/results/logs, progress, leaderboards, time-partitioned activity logs, etc.).

---

## 2. Canvas audit — how it actually works

### 2.1 Render pipeline (`canvas_builder_screen.dart`)
A 5-layer stack inside an `InteractiveViewer` (pan/zoom, scale 0.2–3.0, 2000px boundary margin) over a fixed **3000 × 2000** logical surface:

| Layer | Content |
|---|---|
| 0 | `assets/images/lab_bg.png` (`BoxFit.cover`, fallback to solid colour) |
| 1 | `CanvasGridPainter` — dot-matrix grid, 20 px pitch |
| 2 | `CablePainter` — cubic-Bézier cables, colour by medium (Ethernet=cyan, Fiber=amber, Serial=crimson), white + thicker when attached to the selected node |
| 3 | `Positioned` device nodes (90×90 glass cards, icon + label + port count, cyan glow when selected) with two PictoBlox-style port handles at `left:-10` / `right:-10` |
| 4 | Chrome: 60px horizontally-scrollable toolbar + loading overlay |

### 2.2 Interaction model
- **Add device:** tap a tile in `DevicePalette` (6 types: router, switch, firewall, PC, server, cloud) → node auto-placed in a 5-per-row grid at 160 px spacing, auto-named `TYPE_n`, given two interfaces (`eth0` = 192.168.1.n, `eth1` = 10.0.0.n) → immediately persisted.
- **Move:** `onPanUpdate` divides the raw delta by `TransformationController` scale (zoom-correct), then `snapToGrid(20px)`; `onPanEnd` flips `isDragging` off and saves.
- **Select:** tap → cyan border/glow, highlights attached cables, reveals the delete button.
- **Connect:** two paths — (a) click port handle A then port handle B (source turns emerald, snackbar guidance, creates a `CableEdge` with real interface names); (b) toolbar dialog picking source/target node + medium (always `eth0`↔`eth0`).
- **Delete:** removes the node *and* all attached edges.
- **Persistence:** `TopologyProvider.watchTopology()` opens a live Firestore snapshot stream; every mutation optimistically updates local state, `notifyListeners()`, then `saveTopology()` (`set` + merge). If the doc doesn't exist a blank topology is synthesised in memory.
- **Simulate:** saves canvas → writes a queue doc → *also* HTTP-POSTs directly to `http://localhost:8080` → opens a modal `StreamBuilder` on the queue doc, then nests a second `StreamBuilder` on the result doc, showing ping status, grading score and a log panel.

### 2.3 Canvas issues found

**Blocking**
1. **Cables never reach the engine (schema mismatch).** Flutter serialises edges as `sourceNodeId` / `targetNodeId` (confirmed in `topology_model.g.dart`), but `graph_parser.py` only accepts `fromNode` / `source` / `sourceNode` (and `fromInterface` / `sourceInterface`). Every edge is therefore skipped → the graph has nodes but **zero edges** → every ping returns `NO_PHYSICAL_ROUTE`. The parser's own tests only use `fromNode`, so this is invisible to CI.
2. **Double dispatch / race.** `simulation_repository` POSTs directly to the engine *and* the queue write fires `onSimulationQueueCreated`, which POSTs again. Two simulations run per click, producing two result docs and racing writes on the same queue doc. The direct POST also sends no `X-VNL-Signature` (only works because the engine returns `True` for missing signatures when `ENV=development`) and hard-codes `localhost`, so it is dead in any deployed build.
3. **Drag is lossy at sub-grid distances.** `updateNodePosition` snaps to a 20 px grid on *every* pan event, so per-frame deltas < 10 px round back to the same cell and are discarded. Slow drags stick/jitter; only fast drags move the node. Fix: keep an unsnapped drag position in state and snap once on `onPanEnd`.
4. **Stream echo can fight the user.** `watchTopology`'s listener overwrites `_activeTopology` with the server copy unconditionally. `_isDragging` is tracked but never used to suppress it, so a snapshot landing mid-drag (or mid-edit) resets node positions.

**Correctness / UX**
5. `CablePainter` offsets endpoints by `+40` for "80×80 nodes", but nodes are **90×90** — every cable is 5 px off-centre, and cables anchor to the card centre rather than to the clicked port handle, so the Bézier ignores which side the port is on.
6. Only **two ports** are ever rendered (hard-coded `eth0`/`eth1`); the toolbar dialog always wires `eth0`↔`eth0` regardless of what's free, so double-booked ports are possible. No duplicate-link or self-link validation.
7. **No node property editor.** IPs are auto-assigned (`192.168.1.n` / `10.0.0.n`) and can never be changed from the UI — no subnet, gateway, MAC, VLAN, ACL or interface-status editing. The grader supports `vlan_tagging`, `interface_status` and ACL drops, but the canvas cannot produce that data, so those criteria can never legitimately pass.
8. **No edge deletion, no undo/redo, no multi-select, no copy/paste, no zoom-to-fit/reset**, no keyboard shortcuts (Delete key).
9. `TopologyModel.version` is written but never incremented, and `AppConstants.topologyVersionsCollection` is unused — versioning is declared, not implemented.
10. New topologies are created with `ownerUid: 'sandbox_user'` instead of the signed-in UID, so ownership-based access control is impossible for canvases created via the fallback path.
11. `_handleRunSimulation` always pings `nodes.first` → `nodes.last` (insertion order), which is arbitrary rather than user-chosen.
12. `_addDeviceToCanvas` derives IDs/labels from `nodes.length + 1`, so after deletions labels and IPs collide.

**Performance / code quality**
13. `CanvasGridPainter` draws 150 × 100 = **15,000 `drawCircle` calls** on every repaint of a full-size canvas; it should use `drawPoints` or a repeating `ImageShader`.
14. The whole node layer is rebuilt on every `notifyListeners()` (i.e. every pan frame) because the canvas subtree isn't isolated behind `Selector`/`RepaintBoundary`.
15. `canvas_grid_painter.dart` declares a private duplicate palette class `AppConstantsTheme` instead of importing `AppTheme` — colour drift waiting to happen.
16. `dispose()` on the provider is fine, but `saveCurrentCanvas()` is fired on *every* add/delete/pan-end with no debounce → chatty Firestore writes (billing + rate limits).

---

## 3. Wider risks outside the canvas

1. **No `firestore.rules` / `storage.rules` anywhere in the repo, and `firebase.json` declares only `functions`.** The entire data layer is unprotected by version-controlled rules; role guards exist only client-side in `app_routes.dart` and are trivially bypassed.
2. **Secrets committed:** `simulation_engine/backend-testing-d4ece-firebase-adminsdk-fbsvc-67f703bd0d.json` (service-account private key) and `simulation_engine/.env` sit in the tree, and `.gitignore` excludes neither. Rotate the key and ignore both.
3. **Default HMAC secret** (`vnl-default-secret-key-change-in-production`) is the fallback in *both* `config.py` and the Cloud Function.
4. **Dev-mode auth bypass:** missing signature ⇒ allowed when `ENV=development`; if the Cloud Run service is deployed without `ENV` set, the simulate endpoint is fully open (and CORS is `*`).
5. **The project is not a git repository** (`git log` → "not a git repository") — no history, no rollback, no review trail.
6. **Simulation realism is shallow:** reachability is pure physical shortest-path plus ACL/interface checks. There is no subnet/mask matching, no routing table, no default-gateway logic, no ARP/MAC learning, no VLAN segmentation enforcement, and OSPF is a boolean flag rather than a protocol. Two hosts in different subnets connected by a cable will "ping" successfully.
7. **Test coverage is thin on the client:** only `validators_test.dart` and a small `widget_test.dart` (constants + timestamp converter). Nothing covers `TopologyProvider`, snapping, edge creation or the repositories. Python side has 5 test files; the graph-parser tests encode the *wrong* edge schema (see §2.3.1).
8. `main.dart` swallows Firebase init and admin-seed failures silently; `AdminSeedService` writes a `root_admin_seed` user document from the **client**, which is both a rules hazard and a fake account with no Auth identity.
9. 37 dependencies are behind (go_router 14→17, freezed 2→3), and `withOpacity` is deprecated in 4 places.

---

## 4. Recommended fix order

1. Align the edge schema — either emit `fromNode`/`toNode`/`fromInterface`/`toInterface` from Dart, or (safer) add `sourceNodeId`/`targetNodeId`/`sourceInterface`/`targetInterface` to `graph_parser.py`'s key fallbacks, and add a regression test using a real Flutter payload.
2. Delete `_dispatchDirectToPythonEngine` and let the Cloud Function be the only dispatcher (single, signed, deployable path).
3. Add `firestore.rules` + `storage.rules`, wire them into `firebase.json`, and enforce role/ownership server-side; set `ownerUid` to the real UID.
4. Rotate and gitignore the service-account key and `.env`; require a non-default `HMAC_SECRET_KEY`; set `ENV=production` on Cloud Run.
5. Fix drag: track unsnapped position during pan, snap on release, and ignore stream updates while `_isDragging`.
6. Build a node/interface property inspector (IP, mask, gateway, VLAN, status, ACLs) so the grader's criteria become reachable.
7. Correct cable geometry (`+45`, anchor to port handles), add edge deletion and duplicate-link validation.
8. Debounce Firestore saves; optimise the grid painter; add `RepaintBoundary` around the node layer.
9. `git init` + commit; add provider/widget tests for the canvas.
