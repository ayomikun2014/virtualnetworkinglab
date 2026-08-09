import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtuanetlab/core/enums/app_enums.dart';
import 'package:virtuanetlab/data/models/topology_model.dart';
import 'package:virtuanetlab/data/models/user_model.dart';

/// Walks a `toJson()` result and fails on anything Cloud Firestore's
/// `set()` would reject.
///
/// Firestore accepts only primitives, `Map`, `List`, and a handful of its
/// own types (`Timestamp`, `GeoPoint`, `DocumentReference`, `Blob`,
/// `FieldValue`). A nested model instance that wasn't converted to a Map
/// throws `[cloud_firestore/invalid-argument] Unsupported field value: a
/// custom _$FooImpl object` — at runtime, on the real backend, which is the
/// worst place to find out.
void expectFirestoreSafe(Object? value, String path) {
  if (value == null ||
      value is String ||
      value is num ||
      value is bool ||
      value is Timestamp ||
      value is GeoPoint ||
      value is Blob ||
      value is DocumentReference ||
      value is FieldValue) {
    return;
  }

  if (value is Map) {
    value.forEach((k, v) => expectFirestoreSafe(v, '$path.$k'));
    return;
  }

  if (value is List) {
    for (var i = 0; i < value.length; i++) {
      expectFirestoreSafe(value[i], '$path[$i]');
    }
    return;
  }

  fail(
    'Firestore cannot store $path — it is a ${value.runtimeType}, not a '
    'primitive/Map/List. This usually means json_serializable\'s '
    'explicit_to_json is off (see build.yaml), so a nested model was '
    'emitted as a raw object instead of a Map.',
  );
}

void main() {
  group('Firestore-safe serialization', () {
    test('a topology with devices, cables and ACLs is fully serializable', () {
      final topology = TopologyModel(
        topologyId: 't1',
        ownerUid: 'u1',
        name: 'Test',
        nodes: [
          DeviceNode(
            nodeId: 'fw1',
            label: 'Firewall1',
            type: DeviceType.firewall,
            model: 'ASA',
            position: const Position(x: 10, y: 20),
            interfaces: const [
              // Exercises the deepest nesting the schema allows:
              // TopologyModel > DeviceNode > InterfaceConfig > AclRule.
              InterfaceConfig(
                name: 'eth0',
                ip: '10.0.0.1',
                acls: [AclRule(action: 'deny', protocol: 'icmp')],
              ),
            ],
          ),
          DeviceNode(
            nodeId: 'pc1',
            label: 'PC1',
            type: DeviceType.pc,
            model: 'Ubuntu',
            position: const Position(x: 30, y: 40),
            interfaces: const [InterfaceConfig(name: 'eth0')],
          ),
        ],
        edges: const [
          CableEdge(
            edgeId: 'e1',
            sourceNodeId: 'fw1',
            sourceInterface: 'eth0',
            targetNodeId: 'pc1',
            targetInterface: 'eth0',
            cableType: 'Ethernet',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expectFirestoreSafe(topology.toJson(), 'TopologyModel');
    });

    test('an empty topology is serializable', () {
      // This is the case that USED to work while every populated canvas
      // silently failed — an empty list has no nested objects to mis-emit,
      // which is what made the bug look intermittent instead of total.
      final topology = TopologyModel(
        topologyId: 't2',
        ownerUid: 'u1',
        name: 'Empty',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expectFirestoreSafe(topology.toJson(), 'TopologyModel');
    });

    test('nested nodes really are Maps, not model instances', () {
      final topology = TopologyModel(
        topologyId: 't3',
        ownerUid: 'u1',
        name: 'Test',
        nodes: [
          DeviceNode(
            nodeId: 'pc1',
            label: 'PC1',
            type: DeviceType.pc,
            model: 'Ubuntu',
            position: const Position(x: 0, y: 0),
            interfaces: const [InterfaceConfig(name: 'eth0')],
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = topology.toJson();
      expect(json['nodes'], isA<List>());
      expect((json['nodes'] as List).first, isA<Map<String, dynamic>>());

      final node = (json['nodes'] as List).first as Map<String, dynamic>;
      expect(node['position'], isA<Map<String, dynamic>>());
      expect(node['interfaces'], isA<List>());
      expect((node['interfaces'] as List).first, isA<Map<String, dynamic>>());
    });

    test('a user profile is serializable', () {
      final user = UserModel(
        uid: 'u1',
        email: 'a@b.edu',
        displayName: 'Test',
        departmentId: 'dept_net',
        enrolledCourseIds: const ['NET201'],
        lastLoginAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        stats: const {'completedExercises': 0},
      );

      expectFirestoreSafe(user.toJson(), 'UserModel');
    });

    test('a topology survives a full write/read round trip', () {
      final original = TopologyModel(
        topologyId: 't4',
        ownerUid: 'u1',
        name: 'Round trip',
        nodes: [
          DeviceNode(
            nodeId: 'pc1',
            label: 'PC1',
            type: DeviceType.pc,
            model: 'Ubuntu',
            position: const Position(x: 120, y: 160),
            interfaces: const [InterfaceConfig(name: 'eth0', ip: '10.0.0.5')],
          ),
        ],
        edges: const [
          CableEdge(
            edgeId: 'e1',
            sourceNodeId: 'pc1',
            sourceInterface: 'eth0',
            targetNodeId: 'pc1',
            targetInterface: 'eth0',
            cableType: 'Ethernet',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final restored = TopologyModel.fromJson(original.toJson());

      expect(restored.nodes.single.label, 'PC1');
      expect(restored.nodes.single.type, DeviceType.pc);
      expect(restored.nodes.single.position.x, 120);
      expect(restored.nodes.single.interfaces.single.ip, '10.0.0.5');
      expect(restored.edges.single.cableType, 'Ethernet');
    });
  });
}
