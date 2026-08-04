import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../models/topology_model.dart';

/// Contract interface for Topology Canvas Repository
abstract class ITopologyRepository {
  Stream<TopologyModel?> watchTopology(String topologyId);
  Future<TopologyModel> getTopology(String topologyId);
  Future<void> saveTopology(TopologyModel topology);
}

/// Firebase & Cloud Firestore implementation of Topology Repository
class FirebaseTopologyRepository implements ITopologyRepository {
  final FirebaseFirestore _firestore;

  FirebaseTopologyRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<TopologyModel?> watchTopology(String topologyId) {
    return _firestore
        .collection(AppConstants.topologiesCollection)
        .doc(topologyId)
        .snapshots()
        .map((snap) => snap.exists && snap.data() != null
            ? TopologyModel.fromJson(snap.data()!)
            : null);
  }

  @override
  Future<TopologyModel> getTopology(String topologyId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.topologiesCollection)
          .doc(topologyId)
          .get();
      if (!doc.exists || doc.data() == null) {
        throw const ServerFailure('Topology canvas not found.');
      }
      return TopologyModel.fromJson(doc.data()!);
    } catch (e) {
      throw ServerFailure('Failed to load topology canvas: $e');
    }
  }

  @override
  Future<void> saveTopology(TopologyModel topology) async {
    try {
      await _firestore
          .collection(AppConstants.topologiesCollection)
          .doc(topology.topologyId)
          .set(topology.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw ServerFailure('Failed to save topology canvas: $e');
    }
  }
}
