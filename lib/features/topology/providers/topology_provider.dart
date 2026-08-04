import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/errors/failures.dart';
import '../../../data/models/topology_model.dart';
import '../../../data/repositories/simulation_repository.dart';
import '../../../data/repositories/topology_repository.dart';

/// State Management Provider for Interactive Topology Builder Canvas Engine
class TopologyProvider extends ChangeNotifier {
  final ITopologyRepository _repository;
  StreamSubscription<TopologyModel?>? _topologySubscription;

  final ISimulationRepository _simulationRepository;

  TopologyModel? _activeTopology;
  String? _selectedNodeId;
  bool _isDragging = false;
  bool _isLoading = false;
  String? _errorMessage;

  /// Live, UNSNAPPED position of the node being dragged.
  ///
  /// The pointer position is kept raw here for the whole gesture and only
  /// snapped to the grid once, on pan end. Snapping on every frame made the
  /// node stick to grid intersections and lag behind the cursor, because each
  /// frame's delta was applied to an already-rounded value and the rounding
  /// error accumulated.
  Offset? _dragPosition;

  /// Pending debounced Firestore write.
  Timer? _saveDebounce;
  static const _saveDebounceDelay = Duration(milliseconds: 600);

  TopologyProvider({
    ITopologyRepository? repository,
    ISimulationRepository? simulationRepository,
  }) : _repository = repository ?? FirebaseTopologyRepository(),
       _simulationRepository =
           simulationRepository ?? FirebaseSimulationRepository();

  // Getters
  TopologyModel? get activeTopology => _activeTopology;
  String? get selectedNodeId => _selectedNodeId;
  bool get isDragging => _isDragging;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Unsnapped position of the node currently being dragged, if any. The canvas
  /// paints from this so the node tracks the cursor exactly.
  Offset? get dragPosition => _dragPosition;

  DeviceNode? get selectedNode {
    if (_activeTopology == null || _selectedNodeId == null) return null;
    try {
      return _activeTopology!.nodes.firstWhere(
        (node) => node.nodeId == _selectedNodeId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Subscribes to real-time Cloud Firestore topology updates
  void watchTopology(String topologyId) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _topologySubscription?.cancel();
    _topologySubscription = _repository
        .watchTopology(topologyId)
        .listen(
          (topology) {
            // Ignore server echoes mid-gesture. Our own debounced save comes back
            // through this stream, and applying it while the student is still
            // dragging snapped the node back to its last-saved position.
            if (_isDragging) return;

            _activeTopology =
                topology ??
                TopologyModel(
                  topologyId: topologyId,
                  // Never 'sandbox_user': that made every topology look like it
                  // belonged to one shared account, so ownership checks in the
                  // security rules could not tell students apart.
                  ownerUid: FirebaseAuth.instance.currentUser?.uid ?? '',
                  name: 'Network Topology',
                  nodes: [],
                  edges: [],
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Topology stream error: $error';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Enqueues simulation job in Firestore queue
  Future<String> enqueueSimulation({
    required String userId,
    String? exerciseId,
    String? pingSource,
    String? pingTarget,
  }) async {
    if (_activeTopology == null) {
      throw const ServerFailure('No active topology to simulate');
    }

    await saveCurrentCanvas();

    return await _simulationRepository.enqueueSimulationJob(
      topologyId: _activeTopology!.topologyId,
      userId: userId,
      exerciseId: exerciseId,
      pingSource: pingSource,
      pingTarget: pingTarget,
    );
  }

  /// Sets or clears currently selected canvas device node
  void selectNode(String? nodeId) {
    if (_selectedNodeId != nodeId) {
      _selectedNodeId = nodeId;
      notifyListeners();
    }
  }

  /// Updates node position optimistically for smooth 60 FPS canvas repaints.
  ///
  /// During the gesture the raw pointer position is stored unsnapped, so the
  /// node follows the cursor precisely. The single grid snap happens on pan
  /// end, which is also the only point we persist.
  void updateNodePosition(
    String nodeId,
    double rawX,
    double rawY, {
    bool isPanEnd = false,
  }) {
    if (_activeTopology == null) return;

    final raw = Offset(rawX, rawY);

    if (!isPanEnd) {
      _isDragging = true;
      _dragPosition = raw;
      _applyNodePosition(nodeId, raw);
      notifyListeners();
      return;
    }

    // Pan end: snap once, clear drag state, then persist.
    final snapped = snapToGrid(raw);
    _isDragging = false;
    _dragPosition = null;
    _applyNodePosition(nodeId, snapped);
    notifyListeners();

    saveCurrentCanvas();
  }

  void _applyNodePosition(String nodeId, Offset position) {
    final updatedNodes = _activeTopology!.nodes.map((node) {
      if (node.nodeId == nodeId) {
        return node.copyWith(
          position: Position(x: position.dx, y: position.dy),
        );
      }
      return node;
    }).toList();

    _activeTopology = _activeTopology!.copyWith(
      nodes: updatedNodes,
      updatedAt: DateTime.now(),
    );
  }

  /// Replaces a node wholesale. Used by the property inspector when the
  /// student edits an IP, mask, gateway, VLAN, interface status or ACL rule.
  void updateNode(DeviceNode updated) {
    if (_activeTopology == null) return;

    final updatedNodes = _activeTopology!.nodes
        .map((node) => node.nodeId == updated.nodeId ? updated : node)
        .toList();

    _activeTopology = _activeTopology!.copyWith(
      nodes: updatedNodes,
      updatedAt: DateTime.now(),
    );

    notifyListeners();
    // Debounced: a student tabbing through several fields shouldn't cause a
    // Firestore write per field.
    _scheduleSave();
  }

  /// Snaps raw canvas touch coordinates to dynamic 20px grid
  Offset snapToGrid(Offset rawPosition, {double gridSize = 20.0}) {
    final snappedX = (rawPosition.dx / gridSize).round() * gridSize;
    final snappedY = (rawPosition.dy / gridSize).round() * gridSize;
    return Offset(snappedX, snappedY);
  }

  /// Adds a new network hardware device node to the canvas
  void addDeviceNode(DeviceNode node) {
    if (_activeTopology == null) return;

    final updatedNodes = List<DeviceNode>.from(_activeTopology!.nodes)
      ..add(node);
    _activeTopology = _activeTopology!.copyWith(
      nodes: updatedNodes,
      updatedAt: DateTime.now(),
    );

    selectNode(node.nodeId);
    saveCurrentCanvas();
  }

  /// Adds a new cable edge connection between device interfaces
  void addCableEdge(CableEdge edge) {
    if (_activeTopology == null) return;

    final updatedEdges = List<CableEdge>.from(_activeTopology!.edges)
      ..add(edge);
    _activeTopology = _activeTopology!.copyWith(
      edges: updatedEdges,
      updatedAt: DateTime.now(),
    );

    notifyListeners();
    saveCurrentCanvas();
  }

  /// Removes a device node and all attached cable connections
  void deleteNode(String nodeId) {
    if (_activeTopology == null) return;

    final updatedNodes = _activeTopology!.nodes
        .where((n) => n.nodeId != nodeId)
        .toList();
    final updatedEdges = _activeTopology!.edges
        .where((e) => e.sourceNodeId != nodeId && e.targetNodeId != nodeId)
        .toList();

    if (_selectedNodeId == nodeId) {
      _selectedNodeId = null;
    }

    _activeTopology = _activeTopology!.copyWith(
      nodes: updatedNodes,
      edges: updatedEdges,
      updatedAt: DateTime.now(),
    );

    notifyListeners();
    saveCurrentCanvas();
  }

  /// Coalesces rapid edits into a single Firestore write.
  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(_saveDebounceDelay, saveCurrentCanvas);
  }

  /// Persists current canvas state to Cloud Firestore
  Future<void> saveCurrentCanvas() async {
    if (_activeTopology == null) return;

    // A queued debounce would otherwise fire straight after this write.
    _saveDebounce?.cancel();

    try {
      await _repository.saveTopology(_activeTopology!);
    } on Failure catch (f) {
      _errorMessage = f.message;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to save topology: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _topologySubscription?.cancel();
    super.dispose();
  }
}
