import 'dart:async';
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

  TopologyProvider({
    ITopologyRepository? repository,
    ISimulationRepository? simulationRepository,
  })  : _repository = repository ?? FirebaseTopologyRepository(),
        _simulationRepository = simulationRepository ?? FirebaseSimulationRepository();

  // Getters
  TopologyModel? get activeTopology => _activeTopology;
  String? get selectedNodeId => _selectedNodeId;
  bool get isDragging => _isDragging;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DeviceNode? get selectedNode {
    if (_activeTopology == null || _selectedNodeId == null) return null;
    try {
      return _activeTopology!.nodes.firstWhere((node) => node.nodeId == _selectedNodeId);
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
    _topologySubscription = _repository.watchTopology(topologyId).listen(
      (topology) {
        _activeTopology = topology ?? TopologyModel(
          topologyId: topologyId,
          ownerUid: 'sandbox_user',
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

  /// Updates node position optimistically for smooth 60 FPS canvas repaints
  void updateNodePosition(String nodeId, double rawX, double rawY, {bool isPanEnd = false}) {
    if (_activeTopology == null) return;

    final snapped = snapToGrid(Offset(rawX, rawY));
    _isDragging = !isPanEnd;

    final updatedNodes = _activeTopology!.nodes.map((node) {
      if (node.nodeId == nodeId) {
        return node.copyWith(
          position: Position(x: snapped.dx, y: snapped.dy),
        );
      }
      return node;
    }).toList();

    _activeTopology = _activeTopology!.copyWith(
      nodes: updatedNodes,
      updatedAt: DateTime.now(),
    );

    notifyListeners();

    // Auto-persist topology to Cloud Firestore when dragging ends
    if (isPanEnd) {
      saveCurrentCanvas();
    }
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

    final updatedNodes = List<DeviceNode>.from(_activeTopology!.nodes)..add(node);
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

    final updatedEdges = List<CableEdge>.from(_activeTopology!.edges)..add(edge);
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

    final updatedNodes = _activeTopology!.nodes.where((n) => n.nodeId != nodeId).toList();
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

  /// Persists current canvas state to Cloud Firestore
  Future<void> saveCurrentCanvas() async {
    if (_activeTopology == null) return;

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
    _topologySubscription?.cancel();
    super.dispose();
  }
}
