import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';

/// Contract interface for Simulation Queue & Execution Results Repository
abstract class ISimulationRepository {
  Future<String> enqueueSimulationJob({
    required String topologyId,
    required String userId,
    String? exerciseId,
    String? levelId,
    String? topicId,
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
///
/// DISPATCH MODEL — read before changing.
///
/// Writing the queue document is the ONLY thing the client does to start a
/// simulation. The `onSimulationQueueCreated` Cloud Function trigger picks the
/// document up, signs the payload with HMAC-SHA256 and POSTs it to the FastAPI
/// engine. That function is the single dispatcher.
///
/// This class used to ALSO POST straight to `http://localhost:8080`, which
/// meant two simulations ran for every click. They raced on the same queue
/// document and produced two result documents. The direct path was also
/// unsigned (it only worked because the engine allows missing signatures when
/// ENV=development) and hard-coded localhost, so it was dead in any deployed
/// build. It has been removed deliberately. Do not reintroduce it: the client
/// must never hold the HMAC secret or know the engine's address.
///
/// GRADING CRITERIA ARE NOT SENT FROM HERE, ON PURPOSE. The client only names
/// which level it is attempting (`levelId`). The Cloud Function loads that
/// level's success criteria and pass mark from Firestore itself. If the client
/// supplied the criteria, a student could submit an empty list and pass every
/// level instantly.
class FirebaseSimulationRepository implements ISimulationRepository {
  final FirebaseFirestore _firestore;

  FirebaseSimulationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> enqueueSimulationJob({
    required String topologyId,
    required String userId,
    String? exerciseId,
    String? levelId,
    String? topicId,
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
        'levelId': ?levelId,
        'topicId': ?topicId,
        'pingSource': ?pingSource,
        'pingTarget': ?pingTarget,
        'status': 'queued',
        'priority': 1,
        'requestedAt': FieldValue.serverTimestamp(),
      };

      // Single write. The Cloud Function trigger takes it from here.
      await docRef.set(payload);

      return queueId;
    } catch (e) {
      throw ServerFailure('Failed to enqueue simulation job: $e');
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
