import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../enums/app_enums.dart';
import '../../data/models/topology_model.dart';

/// Free Practice Level Bootstrapping Service for VirtuaNetLab
///
/// Executed during application launch in `main.dart`, mirroring
/// [AdminSeedService]'s check-then-create pattern: query whether any
/// published Free Practice level already exists, and only write the
/// starter set if none do. Without this, a fresh (or newly cleared)
/// Firestore project has no practice levels at all — the Free Practice
/// screen stays permanently empty until a lecturer manually authors levels
/// one at a time through the canvas.
///
/// Each seeded level gets a real solution topology, not just title text —
/// `TopologyGrader` needs one to grade against, so a level without one would
/// show up on the list but silently fail every Check Connection with
/// "answer key isn't set up yet."
/// What a seeding run actually did — returned rather than swallowed so the
/// caller can tell "nothing to do" apart from "every write was rejected",
/// which previously looked identical (an empty Free Practice list).
class PracticeSeedOutcome {
  final int seededCount;

  /// First failure encountered, verbatim. Surfaced in the UI because the
  /// realistic causes (Firestore rules rejecting the write, a missing
  /// index) are invisible from inside the app otherwise.
  final String? error;

  const PracticeSeedOutcome({this.seededCount = 0, this.error});

  bool get seededAnything => seededCount > 0;
}

abstract class IPracticeLevelSeedService {
  Future<PracticeSeedOutcome> bootstrapPracticeLevels();
}

class PracticeLevelSeedService implements IPracticeLevelSeedService {
  final FirebaseFirestore _firestore;

  PracticeLevelSeedService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static String docIdForLevel(int practiceLevel) =>
      'practice_seed_level_$practiceLevel';

  /// Bumped whenever `_starterLevels` changes in a way already-seeded
  /// databases need to pick up.
  ///
  /// The original check was "does this doc exist? then skip", which made the
  /// starter set effectively write-once: the four levels seeded on day one
  /// could never be corrected or extended, because every later run saw them
  /// and did nothing. Version 2 renamed the levels (dropping the redundant
  /// "Level N:" title prefix) and grew the set from 4 to 16, none of which
  /// would have reached an existing project. Version 3 grew the set again,
  /// to 20, and restored the original levels 1–4 that version 2 had
  /// renamed out from under students mid-progression.
  static const int seedVersion = 3;

  /// Marks a level as still being the untouched seeded copy. A level whose
  /// `authorUid` is anything else has been taken over by a real lecturer
  /// through the authoring tab, and is never overwritten by a version bump —
  /// their edits outrank the starter data.
  static const String seedAuthorUid = 'system_seed';

  /// Records which [seedVersion] a project has fully applied.
  ///
  /// Lives in the exercises collection but can never surface as one: the
  /// student-facing query filters on `isPublished == true` and
  /// `practiceLevel > 0`, and this document carries neither field.
  static const String seedMetaDocId = 'practice_seed_meta';

  @override
  Future<PracticeSeedOutcome> bootstrapPracticeLevels() async {
    var seeded = 0;
    String? firstError;

    final metaRef = _firestore
        .collection(AppConstants.exercisesCollection)
        .doc(seedMetaDocId);

    // Fast path. Now that this runs on every session rather than only
    // against an empty database, the overwhelmingly common outcome is
    // "nothing to do" — and paying one read to establish that beats paying
    // one per level, every session, for every student.
    try {
      final meta = await metaRef.get();
      if ((meta.data()?['seedVersion'] as num?)?.toInt() == seedVersion) {
        return const PracticeSeedOutcome();
      }
    } catch (e) {
      // Fall through to the per-level checks below, which are the real
      // source of truth — a missing or unreadable marker must never be the
      // thing that stops the curriculum being installed.
      debugPrint('PracticeLevelSeedService: seed marker unreadable: $e');
    }

    for (final level in _starterLevels) {
      try {
        // A direct document read by id, NOT a query.
        //
        // This previously used `where(isPublished ==) + where(practiceLevel
        // ==)`. Since each level is written to a deterministic doc id
        // anyway, fetching that id is strictly simpler and removes the
        // whole class of query-time failures (composite-index
        // requirements, index-merge edge cases) from the one code path
        // whose entire job is to make the app work on an empty database.
        // It also reads correctly when the collection doesn't exist yet.
        final ref = _firestore
            .collection(AppConstants.exercisesCollection)
            .doc(docIdForLevel(level.practiceLevel));

        final snap = await ref.get();
        if (snap.exists && !_needsRewrite(snap.data())) continue;

        await _writeLevel(level);
        seeded++;
      } catch (e) {
        // One level failing shouldn't stop the others in this same run —
        // each is independently retried next time regardless.
        firstError ??= e.toString();
        debugPrint(
          'PracticeLevelSeedService: failed to seed level '
          '${level.practiceLevel}: $e',
        );
      }
    }

    // Only mark the version applied if every level landed. A partial run
    // that stamped the marker anyway would make the next session take the
    // fast path above and skip the levels that failed, stranding them.
    if (firstError == null) {
      try {
        await metaRef.set({
          'seedVersion': seedVersion,
          'levelCount': _starterLevels.length,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // Costs a redundant re-check next session, nothing more.
        debugPrint('PracticeLevelSeedService: could not write marker: $e');
      }
    }

    return PracticeSeedOutcome(seededCount: seeded, error: firstError);
  }

  /// Whether an already-present level document should be refreshed from the
  /// current starter data. Public behaviour, private helper: exposed to tests
  /// through [shouldRewriteExistingLevel].
  static bool _needsRewrite(Map<String, dynamic>? data) {
    // A lecturer has adopted this level — leave their version alone.
    if (data?['authorUid'] != seedAuthorUid) return false;

    // Absent on everything written before versioning existed, which is
    // exactly the generation that needs rewriting.
    final existing = (data?['seedVersion'] as num?)?.toInt() ?? 1;
    return existing < seedVersion;
  }

  /// Test hook for [_needsRewrite] — the upgrade rules decide whether a
  /// student's existing levels get corrected or silently stay stale, which is
  /// worth asserting directly rather than only through a live Firestore.
  static bool shouldRewriteExistingLevel(Map<String, dynamic>? data) =>
      _needsRewrite(data);

  Future<void> _writeLevel(_SeedLevel level) async {
    final now = DateTime.now();

    // Deterministic id, not auto-generated: makes this an idempotent upsert
    // in its own right, as a second line of defence if the existence check
    // above ever raced with another seed/authoring write.
    final exerciseRef = _firestore
        .collection(AppConstants.exercisesCollection)
        .doc(docIdForLevel(level.practiceLevel));
    final solutionTopologyId = '${exerciseRef.id}_solution';

    final solution = TopologyModel(
      topologyId: solutionTopologyId,
      ownerUid: 'system_seed',
      name: '${level.title} — Solution',
      nodes: level.nodes,
      edges: level.edges,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection(AppConstants.topologiesCollection)
        .doc(solutionTopologyId)
        .set(solution.toJson());

    await exerciseRef.set({
      'exerciseId': exerciseRef.id,
      'title': level.title,
      'description': level.description,
      'categoryId': 'free_practice',
      'courseTitle': 'Free Practice',
      'exerciseType': 'switching',
      'difficulty': level.difficulty.name,
      'maxScore': 100,
      'initialTopologyId': '',
      'practiceLevel': level.practiceLevel,
      'authorUid': seedAuthorUid,
      'seedVersion': seedVersion,
      'isPublished': true,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });

    await exerciseRef.collection('private').doc('solution_key').set({
      'solutionTopologyId': solutionTopologyId,
      'targetCriteria': const <String, dynamic>{},
      'updatedAt': now.toIso8601String(),
    });
  }

  /// The solution topology each starter level would write, without touching
  /// Firestore. `_starterLevels` is private to this file (as it should be —
  /// it's seed data, not part of this service's API), so this is the hook
  /// tests use to check it's well-formed: e.g. that `TopologyGrader` would
  /// actually pass a canvas built to spec, which a typo'd node id in an edge
  /// would silently fail on the first student who tried that level.
  /// The curriculum's shape — level number and title per starter level, in
  /// order. Lets tests assert the progression is contiguous and that titles
  /// don't re-state the level number the UI already renders as a badge.
  static List<({int level, String title})> starterLevelSummariesForTest() {
    return _starterLevels
        .map((level) => (level: level.practiceLevel, title: level.title))
        .toList();
  }

  static List<TopologyModel> starterSolutionTopologiesForTest() {
    final now = DateTime.now();
    return _starterLevels
        .map(
          (level) => TopologyModel(
            topologyId: 'test_${level.practiceLevel}',
            ownerUid: 'system_seed',
            name: level.title,
            nodes: level.nodes,
            edges: level.edges,
            createdAt: now,
            updatedAt: now,
          ),
        )
        .toList();
  }
}

class _SeedLevel {
  final int practiceLevel;
  final String title;
  final String description;
  final DifficultyLevel difficulty;
  final List<DeviceNode> nodes;
  final List<CableEdge> edges;

  const _SeedLevel({
    required this.practiceLevel,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.nodes,
    required this.edges,
  });
}

DeviceNode _node(String id, String label, DeviceType type, double x, double y) {
  final portCount = switch (type) {
    DeviceType.pc => 1,
    DeviceType.server => 1,
    DeviceType.router => 2,
    DeviceType.firewall => 2,
    DeviceType.switchDevice => 4,
    DeviceType.cloud => 1,
  };

  return DeviceNode(
    nodeId: id,
    label: label,
    type: type,
    model: 'Generic',
    position: Position(x: x, y: y),
    interfaces: List.generate(portCount, (i) => InterfaceConfig(name: 'eth$i')),
  );
}

CableEdge _edge(String id, String from, String to, {String cableType = 'Ethernet'}) {
  return CableEdge(
    edgeId: id,
    sourceNodeId: from,
    sourceInterface: 'eth0',
    targetNodeId: to,
    targetInterface: 'eth0',
    cableType: cableType,
  );
}

/// The 20-level Free Practice curriculum.
///
/// Levels 1–4 are the original starter set, kept exactly as they were —
/// students partway through them keep their progress and see the same
/// titles. Levels 5–20 extend the progression from there.
///
/// Ordered to follow the sequence a networking course actually teaches in:
/// end-to-end link → star LAN → gateway → segmentation → redundancy and
/// media → VLAN trunking → internet edge and perimeter security → WAN →
/// hierarchical campus design. That mirrors the CCNA blueprint's own
/// progression, where Layer 2 switching (VLANs, trunking, spanning tree)
/// is taught before IP connectivity, static routing and edge/WAN topics.
///
/// Every level is graded on physical build only — devices placed and cables
/// drawn, including the cable medium — because that is all `TopologyGrader`
/// inspects. So each level differs from the one before it in *topology*, not
/// in configuration: a level whose only difference was "now assign VLAN 10"
/// would be ungradeable here and is deliberately not in the set. The
/// addressing/VLAN theory each level is teaching lives in its description,
/// which the canvas shows as the task brief.
///
/// Titles are the bare topic — no "Level N:" prefix. The level number is
/// rendered as its own badge on every card and tile, so putting it in the
/// title too showed the word "Level" twice.
final List<_SeedLevel> _starterLevels = [
  _SeedLevel(
    practiceLevel: 1,
    title: 'Connect Two PCs',
    description:
        'The smallest possible network. Drag two PCs onto the canvas and '
        'join them with a single Ethernet cable, then press Check '
        'Connection. Two directly cabled hosts on the same subnet can talk '
        'without any switch or router at all.',
    difficulty: DifficultyLevel.beginner,
    nodes: [
      _node('pc1', 'PC1', DeviceType.pc, 140, 200),
      _node('pc2', 'PC2', DeviceType.pc, 460, 200),
    ],
    edges: [_edge('e1', 'pc1', 'pc2')],
  ),
  _SeedLevel(
    practiceLevel: 2,
    title: 'Build a Star Network',
    description:
        'Direct cabling stops scaling at two hosts. Add a switch and run an '
        'Ethernet cable from each of PC1, PC2 and PC3 to it. This star '
        'topology is how essentially every real LAN is wired: one failed '
        'cable takes down one host, not the whole network.',
    difficulty: DifficultyLevel.beginner,
    nodes: [
      _node('pc1', 'PC1', DeviceType.pc, 140, 120),
      _node('pc2', 'PC2', DeviceType.pc, 140, 320),
      _node('pc3', 'PC3', DeviceType.pc, 140, 520),
      _node('sw1', 'Switch1', DeviceType.switchDevice, 460, 320),
    ],
    edges: [
      _edge('e1', 'pc1', 'sw1'),
      _edge('e2', 'pc2', 'sw1'),
      _edge('e3', 'pc3', 'sw1'),
    ],
  ),
  _SeedLevel(
    practiceLevel: 3,
    title: 'Switch to Router',
    description:
        'A switch only moves frames inside one subnet. Cable PC1 and PC2 to '
        'Switch1, then uplink Switch1 to Router1 — the default gateway every '
        'host sends off-subnet traffic to.',
    difficulty: DifficultyLevel.beginner,
    nodes: [
      _node('pc1', 'PC1', DeviceType.pc, 140, 140),
      _node('pc2', 'PC2', DeviceType.pc, 140, 340),
      _node('sw1', 'Switch1', DeviceType.switchDevice, 440, 240),
      _node('r1', 'Router1', DeviceType.router, 740, 240),
    ],
    edges: [
      _edge('e1', 'pc1', 'sw1'),
      _edge('e2', 'pc2', 'sw1'),
      _edge('e3', 'sw1', 'r1'),
    ],
  ),
  _SeedLevel(
    practiceLevel: 4,
    title: 'Add a Server',
    description:
        'Put a shared resource on the LAN. Connect PC1, PC2 and Server1 all '
        'to Switch1, and uplink Switch1 to Router1. Traffic between the PCs '
        'and the server stays local to the switch and never touches the '
        'router.',
    difficulty: DifficultyLevel.beginner,
    nodes: [
      _node('pc1', 'PC1', DeviceType.pc, 140, 120),
      _node('pc2', 'PC2', DeviceType.pc, 140, 320),
      _node('srv1', 'Server1', DeviceType.server, 140, 520),
      _node('sw1', 'Switch1', DeviceType.switchDevice, 440, 320),
      _node('r1', 'Router1', DeviceType.router, 740, 320),
    ],
    edges: [
      _edge('e1', 'pc1', 'sw1'),
      _edge('e2', 'pc2', 'sw1'),
      _edge('e3', 'srv1', 'sw1'),
      _edge('e4', 'sw1', 'r1'),
    ],
  ),
  _SeedLevel(
    practiceLevel: 5,
    title: 'Two LANs, One Router',
    description:
        'Split the network in two. Cable PC1 and PC2 to Switch1, PC3 and PC4 '
        'to Switch2, then connect both switches to Router1. Each switch is '
        'its own broadcast domain and subnet, and Router1 is the only path '
        'between them.',
    difficulty: DifficultyLevel.intermediate,
    nodes: [
      _node('pc1', 'PC1', DeviceType.pc, 140, 100),
      _node('pc2', 'PC2', DeviceType.pc, 140, 280),
      _node('pc3', 'PC3', DeviceType.pc, 140, 480),
      _node('pc4', 'PC4', DeviceType.pc, 140, 660),
      _node('sw1', 'Switch1', DeviceType.switchDevice, 440, 190),
      _node('sw2', 'Switch2', DeviceType.switchDevice, 440, 570),
      _node('r1', 'Router1', DeviceType.router, 760, 380),
    ],
    edges: [
      _edge('e1', 'pc1', 'sw1'),
      _edge('e2', 'pc2', 'sw1'),
      _edge('e3', 'pc3', 'sw2'),
      _edge('e4', 'pc4', 'sw2'),
      _edge('e5', 'sw1', 'r1'),
      _edge('e6', 'sw2', 'r1'),
    ],
  ),
  _SeedLevel(
    practiceLevel: 6,
    title: 'Extended Star Uplink',
    description:
        'Grow the LAN by stacking switches instead of buying a bigger one. '
        'Cable PC1 and PC2 to Switch2 (the access switch), uplink Switch2 to '
        'Switch1 (the distribution switch), and uplink Switch1 to Router1. '
        'This extended star is the shape real wiring closets take.',
    difficulty: DifficultyLevel.intermediate,
    nodes: [
      _node('pc1', 'PC1', DeviceType.pc, 140, 160),
      _node('pc2', 'PC2', DeviceType.pc, 140, 380),
      _node('sw1', 'Switch1', DeviceType.switchDevice, 720, 270),
      _node('sw2', 'Switch2', DeviceType.switchDevice, 440, 270),
      _node('r1', 'Router1', DeviceType.router, 1000, 270),
    ],
    edges: [
      _edge('e1', 'pc1', 'sw2'),
      _edge('e2', 'pc2', 'sw2'),
      _edge('e3', 'sw2', 'sw1'),
      _edge('e4', 'sw1', 'r1'),
    ],
  ),
  _SeedLevel(
    practiceLevel: 7,
    title: 'Daisy-Chain the Wiring Closets',
    description:
        'Three floors, three closets. Cable PC1 to Switch1, then chain '
        'Switch1 to Switch2 and Switch2 to Switch3, and uplink Switch3 to '
        'Router1. A cascade like this is quick to wire but every switch '
        'depends on the one before it — which is what the next redundancy '
        'levels fix.',
    difficulty: DifficultyLevel.intermediate,
    nodes: [
      _node('pc1', 'PC1', DeviceType.pc, 140, 280),
      _node('sw1', 'Switch1', DeviceType.switchDevice, 400, 280),
      _node('sw2', 'Switch2', DeviceType.switchDevice, 640, 280),
      _node('sw3', 'Switch3', DeviceType.switchDevice, 880, 280),
      _node('r1', 'Router1', DeviceType.router, 1120, 280),
    ],
    edges: [
      _edge('e1', 'pc1', 'sw1'),
      _edge('e2', 'sw1', 'sw2'),
      _edge('e3', 'sw2', 'sw3'),
      _edge('e4', 'sw3', 'r1'),
    ],
  ),
  _SeedLevel(
    practiceLevel: 8,
    title: 'Server Farm',
    description:
        'Consolidate the services. Connect Server1, Server2 and Server3 to '
        'Switch1, add PC1 as the client, then uplink Switch1 to Router1. '
        'Grouping servers behind one switch is what lets them share high-'
        'speed local links and a single security boundary.',
    difficulty: DifficultyLevel.intermediate,
    nodes: [
      _node('pc1', 'PC1', DeviceType.pc, 140, 320),
      _node('srv1', 'Server1', DeviceType.server, 700, 100),
      _node('srv2', 'Server2', DeviceType.server, 700, 300),
      _node('srv3', 'Server3', DeviceType.server, 700, 500),
      _node('sw1', 'Switch1', DeviceType.switchDevice, 420, 320),
      _node('r1', 'Router1', DeviceType.router, 420, 560),
    ],
    edges: [
      _edge('e1', 'pc1', 'sw1'),
      _edge('e2', 'srv1', 'sw1'),
      _edge('e3', 'srv2', 'sw1'),
      _edge('e4', 'srv3', 'sw1'),
      _edge('e5', 'sw1', 'r1'),
    ],
  ),
  _SeedLevel(
    practiceLevel: 9,
    title: 'Redundant Switch Ring',
    description:
        'Build a loop on purpose. Cable Switch1 to Switch2, Switch2 to '
        'Switch3 and Switch3 back to Switch1, then hang PC1 off Switch1 and '
        'PC2 off Switch2. Any one link can now fail without isolating a '
        'switch — and Spanning Tree Protocol is what stops the ring '
        'broadcast-storming itself.',
    difficulty: DifficultyLevel.intermediate,
    nodes: [
      _node('pc1', 'PC1', DeviceType.pc, 140, 140),
      _node('pc2', 'PC2', DeviceType.pc, 140, 500),
      _node('sw1', 'Switch1', DeviceType.switchDevice, 440, 140),
      _node('sw2', 'Switch2', DeviceType.switchDevice, 440, 500),
      _node('sw3', 'Switch3', DeviceType.switchDevice, 760, 320),
    ],
    edges: [
      _edge('e1', 'pc1', 'sw1'),
      _edge('e2', 'pc2', 'sw2'),
      _edge('e3', 'sw1', 'sw2'),
      _edge('e4', 'sw2', 'sw3'),
      _edge('e5', 'sw3', 'sw1'),
    ],
  ),
  _SeedLevel(
    practiceLevel: 10,
    title: 'Dual-Homed Server',
    description:
        'Protect the server, not just the switches. Cable PC1 to Switch1 and '
        'PC2 to Switch2, link Switch1 to Switch2, then connect Server1 to '
        'BOTH switches. With two network cards on two different switches, '
        'the server survives losing either one.',
    difficulty: DifficultyLevel.intermediate,
    nodes: [
      _node('pc1', 'PC1', DeviceType.pc, 140, 140),
      _node('pc2', 'PC2', DeviceType.pc, 140, 480),
      _node('srv1', 'Server1', DeviceType.server, 760, 310),
      _node('sw1', 'Switch1', DeviceType.switchDevice, 440, 140),
      _node('sw2', 'Switch2', DeviceType.switchDevice, 440, 480),
    ],
    edges: [
      _edge('e1', 'pc1', 'sw1'),
      _edge('e2', 'pc2', 'sw2'),
      _edge('e3', 'sw1', 'sw2'),
      _edge('e4', 'srv1', 'sw1'),
      _edge('e5', 'srv1', 'sw2'),
    ],
  ),
  _SeedLevel(
    practiceLevel: 11,
    title: 'Fiber Backbone',
    description:
        'Copper runs out of reach at about 100 metres. Cable PC1 and PC2 to '
        'Switch1 with Ethernet, then link Switch1 to Switch2 with a Fibre '
        'cable — the between-buildings backbone run — and connect Switch2 to '
        'Router1 with Ethernet. Pick the cable medium from the toolbar '
        'before you draw each link.',
    difficulty: DifficultyLevel.intermediate,
    nodes: [
      _node('pc1', 'PC1', DeviceType.pc, 140, 160),
      _node('pc2', 'PC2', DeviceType.pc, 140, 380),
      _node('sw1', 'Switch1', DeviceType.switchDevice, 440, 270),
      _node('sw2', 'Switch2', DeviceType.switchDevice, 760, 270),
      _node('r1', 'Router1', DeviceType.router, 1040, 270),
    ],
    edges: [
      _edge('e1', 'pc1', 'sw1'),
      _edge('e2', 'pc2', 'sw1'),
      _edge('e3', 'sw1', 'sw2', cableType: 'Fiber'),
      _edge('e4', 'sw2', 'r1'),
    ],
  ),
  _SeedLevel(
    practiceLevel: 12,
    title: 'Router on a Stick',
    description:
        'One router interface, several VLANs. Cable PC1 through PC4 to '
        'Switch1, then run a single Ethernet uplink from Switch1 to Router1. '
        'That one link is the 802.1Q trunk: the router sub-interfaces on it '
        'route between the VLANs the four PCs sit in.',
    difficulty: DifficultyLevel.intermediate,
    nodes: [
      _node('pc1', 'PC1', DeviceType.pc, 140, 100),
      _node('pc2', 'PC2', DeviceType.pc, 140, 280),
      _node('pc3', 'PC3', DeviceType.pc, 140, 460),
      _node('pc4', 'PC4', DeviceType.pc, 140, 640),
      _node('sw1', 'Switch1', DeviceType.switchDevice, 480, 370),
      _node('r1', 'Router1', DeviceType.router, 800, 370),
    ],
    edges: [
      _edge('e1', 'pc1', 'sw1'),
      _edge('e2', 'pc2', 'sw1'),
      _edge('e3', 'pc3', 'sw1'),
      _edge('e4', 'pc4', 'sw1'),
      _edge('e5', 'sw1', 'r1'),
    ],
  ),
  _SeedLevel(
    practiceLevel: 13,
    title: 'Reach the Internet',
    description:
        'Give the LAN a way out. Cable PC1 and PC2 to Switch1, uplink '
        'Switch1 to Router1, then connect Router1 to Cloud1 — the ISP. '
        'Router1 is now the border between your private addresses and the '
        'public internet.',
    difficulty: DifficultyLevel.intermediate,
    nodes: [
      _node('pc1', 'PC1', DeviceType.pc, 140, 160),
      _node('pc2', 'PC2', DeviceType.pc, 140, 380),
      _node('sw1', 'Switch1', DeviceType.switchDevice, 440, 270),
      _node('r1', 'Router1', DeviceType.router, 740, 270),
      _node('cloud1', 'Cloud1', DeviceType.cloud, 1020, 270),
    ],
    edges: [
      _edge('e1', 'pc1', 'sw1'),
      _edge('e2', 'pc2', 'sw1'),
      _edge('e3', 'sw1', 'r1'),
      _edge('e4', 'r1', 'cloud1'),
    ],
  ),
  _SeedLevel(
    practiceLevel: 14,
    title: 'Firewall at the Edge',
    description:
        'Put a security device in the path. Cable PC1 and PC2 to Switch1, '
        'Switch1 to Firewall1, Firewall1 to Router1 and Router1 to Cloud1. '
        'Every packet leaving the LAN now crosses the firewall, so inbound '
        'traffic can be filtered before it ever reaches a host.',
    difficulty: DifficultyLevel.advanced,
    nodes: [
      _node('pc1', 'PC1', DeviceType.pc, 140, 160),
      _node('pc2', 'PC2', DeviceType.pc, 140, 380),
      _node('sw1', 'Switch1', DeviceType.switchDevice, 420, 270),
      _node('fw1', 'Firewall1', DeviceType.firewall, 700, 270),
      _node('r1', 'Router1', DeviceType.router, 980, 270),
      _node('cloud1', 'Cloud1', DeviceType.cloud, 1240, 270),
    ],
    edges: [
      _edge('e1', 'pc1', 'sw1'),
      _edge('e2', 'pc2', 'sw1'),
      _edge('e3', 'sw1', 'fw1'),
      _edge('e4', 'fw1', 'r1'),
      _edge('e5', 'r1', 'cloud1'),
    ],
  ),
  _SeedLevel(
    practiceLevel: 15,
    title: 'Build a DMZ',
    description:
        'Public servers do not belong on the internal LAN. Cable PC1 and PC2 '
        'to Switch1 and Switch1 to Firewall1, then hang Server1 off '
        'Firewall1 on its own leg — the DMZ. Finish with Firewall1 to '
        'Router1 and Router1 to Cloud1. A compromised public server now has '
        'no direct path to the internal PCs.',
    difficulty: DifficultyLevel.advanced,
    nodes: [
      _node('pc1', 'PC1', DeviceType.pc, 140, 160),
      _node('pc2', 'PC2', DeviceType.pc, 140, 380),
      _node('srv1', 'Server1', DeviceType.server, 700, 560),
      _node('sw1', 'Switch1', DeviceType.switchDevice, 420, 270),
      _node('fw1', 'Firewall1', DeviceType.firewall, 700, 270),
      _node('r1', 'Router1', DeviceType.router, 980, 270),
      _node('cloud1', 'Cloud1', DeviceType.cloud, 1240, 270),
    ],
    edges: [
      _edge('e1', 'pc1', 'sw1'),
      _edge('e2', 'pc2', 'sw1'),
      _edge('e3', 'sw1', 'fw1'),
      _edge('e4', 'fw1', 'srv1'),
      _edge('e5', 'fw1', 'r1'),
      _edge('e6', 'r1', 'cloud1'),
    ],
  ),
  _SeedLevel(
    practiceLevel: 16,
    title: 'Branch Office WAN Link',
    description:
        'Join two sites. Build the head office as PC1 to Switch1 to Router1, '
        'the branch as PC2 to Switch2 to Router2, then join Router1 to '
        'Router2 with a Serial cable — the leased WAN line. Serial is a '
        'different medium from Ethernet, so switch cable type in the toolbar '
        'before drawing that link.',
    difficulty: DifficultyLevel.advanced,
    nodes: [
      _node('pc1', 'PC1', DeviceType.pc, 140, 160),
      _node('pc2', 'PC2', DeviceType.pc, 140, 500),
      _node('sw1', 'Switch1', DeviceType.switchDevice, 420, 160),
      _node('sw2', 'Switch2', DeviceType.switchDevice, 420, 500),
      _node('r1', 'Router1', DeviceType.router, 720, 160),
      _node('r2', 'Router2', DeviceType.router, 720, 500),
    ],
    edges: [
      _edge('e1', 'pc1', 'sw1'),
      _edge('e2', 'sw1', 'r1'),
      _edge('e3', 'pc2', 'sw2'),
      _edge('e4', 'sw2', 'r2'),
      _edge('e5', 'r1', 'r2', cableType: 'Serial'),
    ],
  ),
  _SeedLevel(
    practiceLevel: 17,
    title: 'Hub-and-Spoke WAN',
    description:
        'One head office, two branches. Build the hub as PC1 to Switch1 to '
        'Router1, then give Router2 and Router3 a PC each through Switch2 '
        'and Switch3. Join both spokes back to Router1 with Serial cables. '
        'Branch-to-branch traffic has to transit the hub — that is the '
        'trade-off this design makes.',
    difficulty: DifficultyLevel.advanced,
    nodes: [
      _node('pc1', 'PC1', DeviceType.pc, 140, 320),
      _node('pc2', 'PC2', DeviceType.pc, 1120, 120),
      _node('pc3', 'PC3', DeviceType.pc, 1120, 520),
      _node('sw1', 'Switch1', DeviceType.switchDevice, 400, 320),
      _node('sw2', 'Switch2', DeviceType.switchDevice, 900, 120),
      _node('sw3', 'Switch3', DeviceType.switchDevice, 900, 520),
      _node('r1', 'Router1', DeviceType.router, 640, 320),
      _node('r2', 'Router2', DeviceType.router, 680, 120),
      _node('r3', 'Router3', DeviceType.router, 680, 520),
    ],
    edges: [
      _edge('e1', 'pc1', 'sw1'),
      _edge('e2', 'sw1', 'r1'),
      _edge('e3', 'pc2', 'sw2'),
      _edge('e4', 'sw2', 'r2'),
      _edge('e5', 'pc3', 'sw3'),
      _edge('e6', 'sw3', 'r3'),
      _edge('e7', 'r1', 'r2', cableType: 'Serial'),
      _edge('e8', 'r1', 'r3', cableType: 'Serial'),
    ],
  ),
  _SeedLevel(
    practiceLevel: 18,
    title: 'Redundant Gateways',
    description:
        'One router is a single point of failure. Cable PC1 and PC2 to '
        'Switch1, then uplink Switch1 to both Router1 and Router2, and '
        'connect each router to Cloud1. First-hop redundancy protocols like '
        'HSRP let the two routers share one virtual gateway address, so if '
        'one dies the hosts never notice.',
    difficulty: DifficultyLevel.advanced,
    nodes: [
      _node('pc1', 'PC1', DeviceType.pc, 140, 200),
      _node('pc2', 'PC2', DeviceType.pc, 140, 440),
      _node('sw1', 'Switch1', DeviceType.switchDevice, 440, 320),
      _node('r1', 'Router1', DeviceType.router, 760, 160),
      _node('r2', 'Router2', DeviceType.router, 760, 480),
      _node('cloud1', 'Cloud1', DeviceType.cloud, 1060, 320),
    ],
    edges: [
      _edge('e1', 'pc1', 'sw1'),
      _edge('e2', 'pc2', 'sw1'),
      _edge('e3', 'sw1', 'r1'),
      _edge('e4', 'sw1', 'r2'),
      _edge('e5', 'r1', 'cloud1'),
      _edge('e6', 'r2', 'cloud1'),
    ],
  ),
  _SeedLevel(
    practiceLevel: 19,
    title: 'Three-Tier Campus',
    description:
        'The standard enterprise design. Access layer: PC1 and PC2 to '
        'Switch1, PC3 and PC4 to Switch2. Distribution/core: link both '
        'access switches up to Switch3 with Fibre. Then Switch3 to Router1 '
        'and Router1 to Cloud1. Access, distribution and core each have one '
        'clear job.',
    difficulty: DifficultyLevel.advanced,
    nodes: [
      _node('pc1', 'PC1', DeviceType.pc, 140, 100),
      _node('pc2', 'PC2', DeviceType.pc, 140, 280),
      _node('pc3', 'PC3', DeviceType.pc, 140, 480),
      _node('pc4', 'PC4', DeviceType.pc, 140, 660),
      _node('sw1', 'Switch1', DeviceType.switchDevice, 440, 190),
      _node('sw2', 'Switch2', DeviceType.switchDevice, 440, 570),
      _node('sw3', 'Switch3', DeviceType.switchDevice, 740, 380),
      _node('r1', 'Router1', DeviceType.router, 1020, 380),
      _node('cloud1', 'Cloud1', DeviceType.cloud, 1280, 380),
    ],
    edges: [
      _edge('e1', 'pc1', 'sw1'),
      _edge('e2', 'pc2', 'sw1'),
      _edge('e3', 'pc3', 'sw2'),
      _edge('e4', 'pc4', 'sw2'),
      _edge('e5', 'sw1', 'sw3', cableType: 'Fiber'),
      _edge('e6', 'sw2', 'sw3', cableType: 'Fiber'),
      _edge('e7', 'sw3', 'r1'),
      _edge('e8', 'r1', 'cloud1'),
    ],
  ),
  _SeedLevel(
    practiceLevel: 20,
    title: 'Enterprise Network Capstone',
    description:
        'Everything at once. Access: PC1 and PC2 to Switch1, PC3 to '
        'Switch2. Core: both access switches to Switch3 over Fibre. '
        'Perimeter: Switch3 to Firewall1, Server1 off Firewall1 as the DMZ, '
        'Firewall1 to Router1, and Router1 to Cloud1. Get the media right — '
        'the two core uplinks are Fibre, everything else Ethernet.',
    difficulty: DifficultyLevel.advanced,
    nodes: [
      _node('pc1', 'PC1', DeviceType.pc, 140, 120),
      _node('pc2', 'PC2', DeviceType.pc, 140, 300),
      _node('pc3', 'PC3', DeviceType.pc, 140, 520),
      _node('srv1', 'Server1', DeviceType.server, 1020, 620),
      _node('sw1', 'Switch1', DeviceType.switchDevice, 440, 210),
      _node('sw2', 'Switch2', DeviceType.switchDevice, 440, 520),
      _node('sw3', 'Switch3', DeviceType.switchDevice, 740, 360),
      _node('fw1', 'Firewall1', DeviceType.firewall, 1020, 360),
      _node('r1', 'Router1', DeviceType.router, 1300, 360),
      _node('cloud1', 'Cloud1', DeviceType.cloud, 1560, 360),
    ],
    edges: [
      _edge('e1', 'pc1', 'sw1'),
      _edge('e2', 'pc2', 'sw1'),
      _edge('e3', 'pc3', 'sw2'),
      _edge('e4', 'sw1', 'sw3', cableType: 'Fiber'),
      _edge('e5', 'sw2', 'sw3', cableType: 'Fiber'),
      _edge('e6', 'sw3', 'fw1'),
      _edge('e7', 'fw1', 'srv1'),
      _edge('e8', 'fw1', 'r1'),
      _edge('e9', 'r1', 'cloud1'),
    ],
  ),
];
