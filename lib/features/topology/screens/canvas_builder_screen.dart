import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/enums/app_enums.dart';
import '../../../data/models/topology_model.dart';
import '../../../data/repositories/simulation_repository.dart';
import '../providers/topology_provider.dart';
import '../widgets/cable_painter.dart';
import '../widgets/canvas_grid_painter.dart';
import '../widgets/device_palette.dart';
import '../widgets/node_property_inspector.dart';

/// 5-Layer Interactive Topology Canvas Engine Workspace Screen
class CanvasBuilderScreen extends StatefulWidget {
  final String topologyId;

  const CanvasBuilderScreen({super.key, required this.topologyId});

  @override
  State<CanvasBuilderScreen> createState() => _CanvasBuilderScreenState();
}

class _CanvasBuilderScreenState extends State<CanvasBuilderScreen> {
  final TransformationController _transformationController =
      TransformationController();
  bool _showDevicePalette = true;
  String? _connectSourceNodeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final topologyProvider = Provider.of<TopologyProvider>(
        context,
        listen: false,
      );
      topologyProvider.watchTopology(widget.topologyId);
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundMidnight,
      body: Consumer<TopologyProvider>(
        builder: (context, provider, _) {
          final topology = provider.activeTopology;

          return Column(
            children: [
              // Top Control Toolbar
              _buildTopToolbar(context, provider, topology),

              Expanded(
                child: Row(
                  children: [
                    // Hardware Library Sidebar
                    if (_showDevicePalette)
                      DevicePalette(
                        onDeviceSelected: (type, model) =>
                            _addDeviceToCanvas(provider, type, model),
                      ),

                    // Interactive Canvas Viewport
                    Expanded(
                      child: Stack(
                        children: [
                          // 5-Layer Stack Substrate inside InteractiveViewer
                          InteractiveViewer(
                            transformationController: _transformationController,
                            boundaryMargin: const EdgeInsets.all(2000),
                            minScale: 0.2,
                            maxScale: 3.0,
                            child: SizedBox(
                              width: 3000,
                              height: 2000,
                              child: Stack(
                                children: [
                                  // Layer 0: High-Tech Cyber Laboratory Background Image
                                  Positioned.fill(
                                    child: Image.asset(
                                      'assets/images/lab_bg.png',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color:
                                                  AppTheme.backgroundMidnight,
                                            );
                                          },
                                    ),
                                  ),

                                  // Layer 1: Subtle Dot-Matrix Grid Overlay
                                  const CustomPaint(
                                    size: Size(3000, 2000),
                                    painter: CanvasGridPainter(),
                                  ),

                                  // Layer 2: Cable Links CustomPainter
                                  if (topology != null)
                                    CustomPaint(
                                      size: const Size(3000, 2000),
                                      painter: CablePainter(
                                        edges: topology.edges,
                                        nodes: topology.nodes,
                                        selectedNodeId: provider.selectedNodeId,
                                      ),
                                    ),

                                  // Layer 3: Interactive Positioned Device Nodes
                                  //
                                  // RepaintBoundary per node so dragging one
                                  // device doesn't repaint the whole node layer.
                                  if (topology != null)
                                    ...topology.nodes.map((node) {
                                      return RepaintBoundary(
                                        child: _buildInteractiveNode(
                                          provider,
                                          node,
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),
                          ),

                          // Floating Loading Indicator
                          if (provider.isLoading)
                            Container(
                              color: AppTheme.backgroundMidnight.withValues(
                                alpha: 0.5,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryCyan,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Property inspector for the selected device. This is what
                    // lets a student set IP / mask / gateway / VLAN / status /
                    // ACLs, which the grader's criteria depend on.
                    if (provider.selectedNode != null)
                      NodePropertyInspector(
                        node: provider.selectedNode!,
                        onNodeChanged: provider.updateNode,
                        onClose: () => provider.selectNode(null),
                        onDeleteNode: () =>
                            provider.deleteNode(provider.selectedNode!.nodeId),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Top Canvas Toolbar — Horizontally Scrollable for Mobile Phone Overflow Protection
  Widget _buildTopToolbar(
    BuildContext context,
    TopologyProvider provider,
    TopologyModel? topology,
  ) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceGlass,
        border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                _showDevicePalette ? Icons.menu_open : Icons.menu,
                color: AppTheme.primaryCyan,
              ),
              tooltip: 'Toggle Device Palette',
              onPressed: () =>
                  setState(() => _showDevicePalette = !_showDevicePalette),
            ),
            const SizedBox(width: 8),
            Text(
              topology?.name ?? 'Topology Canvas',
              style: const TextStyle(
                color: AppTheme.textBright,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'v${topology?.version ?? 1}',
                style: const TextStyle(
                  color: AppTheme.primaryCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 24),

            // Cable Connect Tool
            IconButton(
              icon: Icon(
                Icons.cable,
                color: _connectSourceNodeId != null
                    ? AppTheme.accentEmerald
                    : AppTheme.textBright,
              ),
              tooltip: 'Connect Cable Link',
              onPressed: () => _handleCableConnectionDialog(provider),
            ),

            // Delete Selected Node Button
            if (provider.selectedNodeId != null)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.accentCrimson,
                ),
                tooltip: 'Delete Selected Node',
                onPressed: () => provider.deleteNode(provider.selectedNodeId!),
              ),

            const SizedBox(width: 8),

            // Save Canvas Button
            ElevatedButton.icon(
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save Canvas'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await provider.saveCurrentCanvas();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Topology canvas saved successfully'),
                    backgroundColor: AppTheme.accentEmerald,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),

            // Trigger Async Simulation Queue Button
            OutlinedButton.icon(
              icon: const Icon(
                Icons.play_arrow,
                color: AppTheme.accentEmerald,
                size: 18,
              ),
              label: const Text(
                'Simulate Network',
                style: TextStyle(color: AppTheme.accentEmerald),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.accentEmerald),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onPressed: () => _handleRunSimulation(provider),
            ),
          ],
        ),
      ),
    );
  }

  /// Interactive Positioned Node Widget with PictoBlox-style Port Connector Handles
  Widget _buildInteractiveNode(TopologyProvider provider, DeviceNode node) {
    final isSelected = provider.selectedNodeId == node.nodeId;
    final isSourceConnect = _connectSourceNodeId == node.nodeId;

    return Positioned(
      left: node.position.x,
      top: node.position.y,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Device Card Body
          GestureDetector(
            onTap: () => provider.selectNode(node.nodeId),
            onPanUpdate: (details) {
              final scale = _transformationController.value.getMaxScaleOnAxis();
              final deltaX = details.delta.dx / scale;
              final deltaY = details.delta.dy / scale;

              final newX = node.position.x + deltaX;
              final newY = node.position.y + deltaY;

              provider.updateNodePosition(
                node.nodeId,
                newX,
                newY,
                isPanEnd: false,
              );
            },
            onPanEnd: (_) {
              // Use the provider's live unsnapped drag position, not
              // `node.position` from this closure: `node` was captured when the
              // widget was built, so it holds the pre-drag coordinates and the
              // device would jump back to where the gesture started.
              final finalPos =
                  provider.dragPosition ??
                  Offset(node.position.x, node.position.y);

              provider.updateNodePosition(
                node.nodeId,
                finalPos.dx,
                finalPos.dy,
                isPanEnd: true,
              );
            },
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.surfaceGlass,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSourceConnect
                      ? AppTheme.accentEmerald
                      : isSelected
                      ? AppTheme.primaryCyan
                      : AppTheme.borderSubtle,
                  width: isSelected || isSourceConnect ? 2.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryCyan.withValues(alpha: 0.3),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getDeviceIcon(node.type),
                    color: _getDeviceColor(node.type),
                    size: 34,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    node.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textBright,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${node.interfaces.length} Ports',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // PictoBlox-style Port Connector Handle Dots (Left & Right Port Attachments)
          // Port 0 (Left Side Handle)
          Positioned(
            left: -10,
            top: 35,
            child: Tooltip(
              message: node.interfaces.isNotEmpty
                  ? '${node.interfaces.first.name} (${node.interfaces.first.ip ?? "No IP"})'
                  : 'Port eth0',
              child: InkWell(
                onTap: () => _handlePortClick(
                  provider,
                  node.nodeId,
                  node.interfaces.isNotEmpty
                      ? node.interfaces.first.name
                      : 'eth0',
                ),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSourceConnect
                        ? AppTheme.accentEmerald
                        : AppTheme.primaryCyan,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.backgroundMidnight,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isSourceConnect
                                    ? AppTheme.accentEmerald
                                    : AppTheme.primaryCyan)
                                .withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.cable,
                    color: AppTheme.backgroundMidnight,
                    size: 10,
                  ),
                ),
              ),
            ),
          ),

          // Port 1 (Right Side Handle)
          Positioned(
            right: -10,
            top: 35,
            child: Tooltip(
              message: node.interfaces.length > 1
                  ? '${node.interfaces[1].name} (${node.interfaces[1].ip ?? "No IP"})'
                  : 'Port eth1',
              child: InkWell(
                onTap: () => _handlePortClick(
                  provider,
                  node.nodeId,
                  node.interfaces.length > 1 ? node.interfaces[1].name : 'eth1',
                ),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSourceConnect
                        ? AppTheme.accentEmerald
                        : AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.backgroundMidnight,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isSourceConnect
                                    ? AppTheme.accentEmerald
                                    : AppTheme.primaryBlue)
                                .withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.cable,
                    color: AppTheme.backgroundMidnight,
                    size: 10,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _connectSourcePort;

  void _handlePortClick(
    TopologyProvider provider,
    String nodeId,
    String portName,
  ) {
    if (_connectSourceNodeId == null) {
      setState(() {
        _connectSourceNodeId = nodeId;
        _connectSourcePort = portName;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selected source port $portName on $nodeId. Click target port on another device to connect cable.',
          ),
          backgroundColor: AppTheme.primaryCyan,
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (_connectSourceNodeId == nodeId) {
      setState(() {
        _connectSourceNodeId = null;
        _connectSourcePort = null;
      });
    } else {
      final edge = CableEdge(
        edgeId: 'edge_${DateTime.now().millisecondsSinceEpoch}',
        sourceNodeId: _connectSourceNodeId!,
        sourceInterface: _connectSourcePort ?? 'eth0',
        targetNodeId: nodeId,
        targetInterface: portName,
        cableType: 'Ethernet',
      );

      provider.addCableEdge(edge);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connected cable between $_connectSourceNodeId ($_connectSourcePort) and $nodeId ($portName)!',
          ),
          backgroundColor: AppTheme.accentEmerald,
        ),
      );

      setState(() {
        _connectSourceNodeId = null;
        _connectSourcePort = null;
      });
    }
  }

  void _addDeviceToCanvas(
    TopologyProvider provider,
    DeviceType type,
    String model,
  ) {
    final existingNodes = provider.activeTopology?.nodes ?? [];
    final count = existingNodes.length + 1;

    // Arrange nodes neatly side-by-side in rows of 5
    final col = (count - 1) % 5;
    final row = (count - 1) ~/ 5;

    final startX = 120.0 + (col * 160.0);
    final startY = 120.0 + (row * 160.0);

    final newNode = DeviceNode(
      nodeId: 'node_${DateTime.now().millisecondsSinceEpoch}',
      label: _defaultLabelFor(type, existingNodes),
      type: type,
      model: model,
      position: Position(x: startX, y: startY),
      interfaces: _defaultInterfacesFor(type),
    );

    provider.addDeviceNode(newNode);
  }

  /// Port count per device type.
  ///
  /// Interfaces deliberately start with NO IP address. Addressing is the thing
  /// the student is being taught, so pre-filling 192.168.1.x would hand them
  /// the answer to most of the addressing levels (and quietly put every device
  /// on the same subnet, which made unrelated levels pass by accident).
  static List<InterfaceConfig> _defaultInterfacesFor(DeviceType type) {
    final portCount = switch (type) {
      DeviceType.pc => 1,
      DeviceType.server => 1,
      DeviceType.router => 2,
      DeviceType.firewall => 2,
      DeviceType.switchDevice => 4,
      DeviceType.cloud => 1,
    };

    return List.generate(portCount, (i) => InterfaceConfig(name: 'eth$i'));
  }

  /// Human-friendly, per-type sequential name: PC1, PC2, Router1, ...
  /// Level criteria refer to devices by these labels, so they must be stable
  /// and predictable rather than based on total node count.
  static String _defaultLabelFor(DeviceType type, List<DeviceNode> existing) {
    final prefix = switch (type) {
      DeviceType.pc => 'PC',
      DeviceType.server => 'Server',
      DeviceType.router => 'Router',
      DeviceType.switchDevice => 'Switch',
      DeviceType.firewall => 'Firewall',
      DeviceType.cloud => 'Cloud',
    };

    final sameType = existing.where((n) => n.type == type).length;
    return '$prefix${sameType + 1}';
  }

  void _handleCableConnectionDialog(TopologyProvider provider) {
    final nodes = provider.activeTopology?.nodes ?? [];
    if (nodes.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least 2 nodes required to connect a cable link'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        String sourceId = nodes.first.nodeId;
        String targetId = nodes.length > 1
            ? nodes[1].nodeId
            : nodes.first.nodeId;
        String cableType = 'Ethernet';

        return AlertDialog(
          backgroundColor: AppTheme.surfaceGlass,
          title: const Text(
            'Add Cable Connection',
            style: TextStyle(color: AppTheme.textBright),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: sourceId,
                decoration: const InputDecoration(labelText: 'Source Node'),
                items: nodes
                    .map(
                      (n) => DropdownMenuItem(
                        value: n.nodeId,
                        child: Text(n.label),
                      ),
                    )
                    .toList(),
                onChanged: (val) => sourceId = val!,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: targetId,
                decoration: const InputDecoration(labelText: 'Target Node'),
                items: nodes
                    .map(
                      (n) => DropdownMenuItem(
                        value: n.nodeId,
                        child: Text(n.label),
                      ),
                    )
                    .toList(),
                onChanged: (val) => targetId = val!,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: cableType,
                decoration: const InputDecoration(
                  labelText: 'Cable Medium Type',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Ethernet',
                    child: Text('Ethernet (Copper)'),
                  ),
                  DropdownMenuItem(
                    value: 'Fiber',
                    child: Text('Fiber (Optical)'),
                  ),
                  DropdownMenuItem(
                    value: 'Serial',
                    child: Text('Serial (WAN Link)'),
                  ),
                ],
                onChanged: (val) => cableType = val!,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final edge = CableEdge(
                  edgeId: 'edge_${DateTime.now().millisecondsSinceEpoch}',
                  sourceNodeId: sourceId,
                  sourceInterface: 'eth0',
                  targetNodeId: targetId,
                  targetInterface: 'eth0',
                  cableType: cableType,
                );

                provider.addCableEdge(edge);
                Navigator.pop(context);
              },
              child: const Text('Connect'),
            ),
          ],
        );
      },
    );
  }

  void _handleRunSimulation(TopologyProvider provider) async {
    final activeTop = provider.activeTopology;
    if (activeTop == null || activeTop.nodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add at least 1 node to the canvas before running simulation.',
          ),
          backgroundColor: AppTheme.accentCrimson,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'anonymous_student';

    try {
      final queueId = await provider.enqueueSimulation(
        userId: userId,
        pingSource: activeTop.nodes.isNotEmpty
            ? activeTop.nodes.first.nodeId
            : null,
        pingTarget: activeTop.nodes.length > 1
            ? activeTop.nodes.last.nodeId
            : null,
      );

      if (!mounted) return;

      final simRepo = FirebaseSimulationRepository();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: simRepo.watchSimulationQueue(queueId),
            builder: (context, snapshot) {
              final queueData = snapshot.data?.data() ?? {};
              final status = queueData['status'] ?? 'queued';
              final resultId = queueData['resultId'] as String?;
              final errorMessage = queueData['error'] as String?;

              if (status == 'completed' && resultId != null) {
                return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: simRepo.watchSimulationResult(resultId),
                  builder: (context, resSnapshot) {
                    final resData = resSnapshot.data?.data() ?? {};
                    final summary =
                        resData['summary'] as Map<String, dynamic>? ?? {};
                    final pingResult =
                        summary['pingResult'] as Map<String, dynamic>? ?? {};
                    final grading =
                        summary['grading'] as Map<String, dynamic>? ?? {};

                    return AlertDialog(
                      backgroundColor: AppTheme.surfaceGlass,
                      title: Row(
                        children: const [
                          Icon(
                            Icons.check_circle,
                            color: AppTheme.accentEmerald,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Simulation Completed',
                            style: TextStyle(color: AppTheme.textBright),
                          ),
                        ],
                      ),
                      content: SizedBox(
                        width: 450,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ping Status: ${pingResult['success'] == true ? "SUCCESS" : "FAILED / UNREACHABLE"}',
                              style: TextStyle(
                                color: pingResult['success'] == true
                                    ? AppTheme.accentEmerald
                                    : AppTheme.accentCrimson,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (grading.isNotEmpty) ...[
                              Text(
                                'Auto-Grading Score: ${grading['totalScore'] ?? 0} / ${grading['maxScore'] ?? 100} (${grading['percentage'] ?? 0}%)',
                                style: const TextStyle(
                                  color: AppTheme.primaryCyan,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            const Text(
                              'Execution Logs:',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundMidnight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Processed Nodes: ${summary['nodesCount'] ?? 0}\nProcessed Edges: ${summary['edgesCount'] ?? 0}\nWorker: Python FastAPI Simulation Engine',
                                style: const TextStyle(
                                  color: AppTheme.textBright,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    );
                  },
                );
              }

              if (status == 'failed') {
                return AlertDialog(
                  backgroundColor: AppTheme.surfaceGlass,
                  title: Row(
                    children: const [
                      Icon(Icons.error_outline, color: AppTheme.accentCrimson),
                      SizedBox(width: 10),
                      Text(
                        'Simulation Failed',
                        style: TextStyle(color: AppTheme.textBright),
                      ),
                    ],
                  ),
                  content: Text(
                    errorMessage ??
                        'Unknown error during Python engine execution.',
                    style: const TextStyle(color: AppTheme.accentCrimson),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Dismiss'),
                    ),
                  ],
                );
              }

              return AlertDialog(
                backgroundColor: AppTheme.surfaceGlass,
                title: Row(
                  children: const [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryCyan,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Simulating Network...',
                      style: TextStyle(color: AppTheme.textBright),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Status: ${status.toString().toUpperCase()}',
                      style: const TextStyle(
                        color: AppTheme.primaryCyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Dispatching payload to Python FastAPI Engine via Firebase Cloud Functions...',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start simulation: $e'),
            backgroundColor: AppTheme.accentCrimson,
          ),
        );
      }
    }
  }

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.router:
        return Icons.router;
      case DeviceType.switchDevice:
        return Icons.swap_horiz;
      case DeviceType.firewall:
        return Icons.security;
      case DeviceType.pc:
        return Icons.desktop_windows;
      case DeviceType.server:
        return Icons.dns;
      case DeviceType.cloud:
        return Icons.cloud_queue;
    }
  }

  Color _getDeviceColor(DeviceType type) {
    switch (type) {
      case DeviceType.router:
        return AppTheme.primaryCyan;
      case DeviceType.switchDevice:
        return AppTheme.primaryBlue;
      case DeviceType.firewall:
        return AppTheme.accentCrimson;
      case DeviceType.pc:
        return AppTheme.accentEmerald;
      case DeviceType.server:
        return Colors.purpleAccent;
      case DeviceType.cloud:
        return Colors.amber;
    }
  }
}
