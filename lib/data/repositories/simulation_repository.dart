import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';

/// Contract interface for Simulation Queue & Execution Results Repository
abstract class ISimulationRepository {
  Future<String> enqueueSimulationJob({
    required String topologyId,
    required String userId,
    String? exerciseId,
    String? pingSource,
    String? pingTarget,
  });

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchSimulationQueue(
    String queueId,
  );
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchSimulationResult(
    String resultId,
  );
}

/// Firebase & Cloud Firestore implementation of Simulation Repository
class FirebaseSimulationRepository implements ISimulationRepository {
  final FirebaseFirestore _firestore;

  FirebaseSimulationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> enqueueSimulationJob({
    required String topologyId,
    required String userId,
    String? exerciseId,
    String? pingSource,
    String? pingTarget,
  }) async {
    try {
      final docRef = _firestore
          .collection(AppConstants.simulationQueueCollection)
          .doc();
      final queueId = docRef.id;

      final payload = {
        'queueId': queueId,
        'topologyId': topologyId,
        'userId': userId,
        'exerciseId': ?exerciseId,
        'pingSource': ?pingSource,
        'pingTarget': ?pingTarget,
        'status': 'queued',
        'priority': 1,
        'requestedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(payload);

      // Direct Local Dispatch to Python FastAPI Simulation Engine
      _dispatchDirectToPythonEngine(
        queueId: queueId,
        topologyId: topologyId,
        userId: userId,
        pingSource: pingSource,
        pingTarget: pingTarget,
      );

      return queueId;
    } catch (e) {
      throw ServerFailure('Failed to enqueue simulation job: $e');
    }
  }

  /// Direct HTTP POST dispatch to local Python FastAPI Engine
  void _dispatchDirectToPythonEngine({
    required String queueId,
    required String topologyId,
    required String userId,
    String? pingSource,
    String? pingTarget,
  }) async {
    try {
      // Fetch topology graph JSON from Firestore
      final topSnap = await _firestore
          .collection(AppConstants.topologiesCollection)
          .doc(topologyId)
          .get();
      final topData = topSnap.data() ?? {};

      final reqPayload = {
        'queueId': queueId,
        'userId': userId,
        'topologyData': topData['topologyData'] ?? topData,
        'targetCriteria': [],
        'pingSource': pingSource,
        'pingTarget': pingTarget,
      };

      final url = Uri.parse('http://localhost:8080/api/v1/simulate');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(reqPayload),
      );

      if (response.statusCode != 200) {
        // Fallback try 127.0.0.1
        final altUrl = Uri.parse('http://127.0.0.1:8080/api/v1/simulate');
        await http.post(
          altUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(reqPayload),
        );
      }
    } catch (e) {
      // If direct HTTP POST fails, job remains in Firestore queue for Cloud Function worker
    }
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchSimulationQueue(
    String queueId,
  ) {
    return _firestore
        .collection(AppConstants.simulationQueueCollection)
        .doc(queueId)
        .snapshots();
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchSimulationResult(
    String resultId,
  ) {
    return _firestore
        .collection(AppConstants.simulationResultsCollection)
        .doc(resultId)
        .snapshots();
  }
}
