import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/enums/app_enums.dart';
import '../../../data/models/topology_model.dart';

/// Side-panel inspector for the selected device.
///
/// This is what makes the grader's criteria reachable. Without it, IPs were
/// auto-assigned and there was no way at all to set a subnet mask, gateway,
/// VLAN, interface status or ACL rule from the UI — so the `vlan_tagging`,
/// `interface_status` and ACL-drop criteria could never legitimately pass.
///
/// Editing model:
///   * Text fields commit on focus-loss and on submit, NOT on every keystroke,
///     so we don't write to Firestore on every character typed.
///   * Toggles and dropdowns commit immediately.
///   * Fields are shown per device type: gateway only on hosts, ACLs only on
///     firewalls, OSPF only on routers.
class NodePropertyInspector extends StatefulWidget {
  const NodePropertyInspector({
    super.key,
    required this.node,
    required this.onNodeChanged,
    required this.onClose,
    this.onDeleteNode,
  });

  final DeviceNode node;

  /// Called with the fully-updated node whenever the student commits a change.
  final ValueChanged<DeviceNode> onNodeChanged;
  final VoidCallback onClose;
  final VoidCallback? onDeleteNode;

  @override
  State<NodePropertyInspector> createState() => _NodePropertyInspectorState();
}

class _NodePropertyInspectorState extends State<NodePropertyInspector> {
  /// Index of the interface currently expanded in the accordion.
  int _expandedInterface = 0;

  bool get _isHost =>
      widget.node.type == DeviceType.pc ||
      widget.node.type == DeviceType.server;
  bool get _isRouter => widget.node.type == DeviceType.router;
  bool get _isFirewall => widget.node.type == DeviceType.firewall;

  void _updateInterface(int index, InterfaceConfig updated) {
    final interfaces = List<InterfaceConfig>.from(widget.node.interfaces);
    interfaces[index] = updated;
    widget.onNodeChanged(widget.node.copyWith(interfaces: interfaces));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF12182B),
        border: Border(left: BorderSide(color: Colors.white24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const Divider(height: 1, color: Colors.white24),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildDeviceSection(),
                const SizedBox(height: 16),
                _buildInterfacesSection(),
                if (_isFirewall) ...[
                  const SizedBox(height: 16),
                  _buildAclSection(),
                ],
                const SizedBox(height: 24),
                if (widget.onDeleteNode != null)
                  OutlinedButton.icon(
                    onPressed: widget.onDeleteNode,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete device'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Icon(_iconForType(widget.node.type), color: AppTheme.primaryCyan),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.node.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.node.type.jsonValue.toUpperCase(),
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
            onPressed: widget.onClose,
            tooltip: 'Close inspector',
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSection() {
    return _Section(
      title: 'Device',
      children: [
        _TextRow(
          label: 'Name',
          value: widget.node.label,
          hint: 'PC1',
          onCommitted: (v) {
            final trimmed = v.trim();
            if (trimmed.isEmpty || trimmed == widget.node.label) return;
            widget.onNodeChanged(widget.node.copyWith(label: trimmed));
          },
        ),
        if (_isRouter)
          _SwitchRow(
            label: 'OSPF enabled',
            help: 'Lets this router learn routes automatically.',
            value: widget.node.ospfEnabled,
            onChanged: (v) =>
                widget.onNodeChanged(widget.node.copyWith(ospfEnabled: v)),
          ),
      ],
    );
  }

  Widget _buildInterfacesSection() {
    return _Section(
      title: 'Interfaces',
      children: [
        for (var i = 0; i < widget.node.interfaces.length; i++)
          _buildInterfaceTile(i, widget.node.interfaces[i]),
        if (widget.node.interfaces.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'This device has no interfaces.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildInterfaceTile(int index, InterfaceConfig iface) {
    final isExpanded = _expandedInterface == index;
    final isDown = iface.status == 'down';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDown
              ? Colors.orangeAccent.withValues(alpha: 0.5)
              : Colors.white12,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                setState(() => _expandedInterface = isExpanded ? -1 : index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    isDown ? Icons.link_off : Icons.settings_ethernet,
                    size: 16,
                    color: isDown ? Colors.orangeAccent : AppTheme.primaryCyan,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    iface.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      iface.ip?.isNotEmpty == true ? iface.ip! : 'no IP',
                      style: TextStyle(
                        color: iface.ip?.isNotEmpty == true
                            ? Colors.white54
                            : Colors.white24,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (iface.vlan != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryCyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'VLAN ${iface.vlan}',
                        style: const TextStyle(
                          color: AppTheme.primaryCyan,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Colors.white38,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  _TextRow(
                    label: 'IP address',
                    value: iface.ip ?? '',
                    hint: '192.168.1.10',
                    // Validated on commit so a half-typed address doesn't
                    // constantly show an error while the student types.
                    validator: _validateIpOrEmpty,
                    onCommitted: (v) => _updateInterface(
                      index,
                      iface.copyWith(ip: v.trim().isEmpty ? null : v.trim()),
                    ),
                  ),
                  _TextRow(
                    label: 'Subnet mask',
                    value: iface.subnet ?? '',
                    hint: '255.255.255.0',
                    validator: _validateIpOrEmpty,
                    onCommitted: (v) => _updateInterface(
                      index,
                      iface.copyWith(
                        subnet: v.trim().isEmpty ? null : v.trim(),
                      ),
                    ),
                  ),
                  if (_isHost)
                    _TextRow(
                      label: 'Default gateway',
                      value: iface.gateway ?? '',
                      hint: '192.168.1.1',
                      validator: _validateIpOrEmpty,
                      onCommitted: (v) => _updateInterface(
                        index,
                        iface.copyWith(
                          gateway: v.trim().isEmpty ? null : v.trim(),
                        ),
                      ),
                    ),
                  _TextRow(
                    label: 'VLAN id',
                    value: iface.vlan?.toString() ?? '',
                    hint: 'untagged',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _validateVlanOrEmpty,
                    onCommitted: (v) {
                      final trimmed = v.trim();
                      final vlan = trimmed.isEmpty
                          ? null
                          : int.tryParse(trimmed);
                      _updateInterface(
                        index,
                        // copyWith can't set null on a nullable field, so
                        // rebuild the record when clearing the VLAN.
                        vlan == null
                            ? InterfaceConfig(
                                name: iface.name,
                                ip: iface.ip,
                                subnet: iface.subnet,
                                mac: iface.mac,
                                gateway: iface.gateway,
                                status: iface.status,
                                acls: iface.acls,
                              )
                            : iface.copyWith(vlan: vlan),
                      );
                    },
                  ),
                  _SwitchRow(
                    label: 'Interface up',
                    help: 'A down interface drops every packet.',
                    value: iface.status != 'down',
                    onChanged: (v) => _updateInterface(
                      index,
                      iface.copyWith(status: v ? 'up' : 'down'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAclSection() {
    // ACLs are attached to the first interface for simplicity; that is where
    // the tracer evaluates them on the inbound hop.
    if (widget.node.interfaces.isEmpty) return const SizedBox.shrink();
    final iface = widget.node.interfaces.first;

    return _Section(
      title: 'Firewall rules (${iface.name})',
      children: [
        for (var i = 0; i < iface.acls.length; i++)
          _buildAclTile(iface, i, iface.acls[i]),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () {
            final acls = List<AclRule>.from(iface.acls)..add(const AclRule());
            _updateInterface(0, iface.copyWith(acls: acls));
          },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add rule'),
          style: TextButton.styleFrom(foregroundColor: AppTheme.primaryCyan),
        ),
      ],
    );
  }

  Widget _buildAclTile(InterfaceConfig iface, int index, AclRule rule) {
    void update(AclRule updated) {
      final acls = List<AclRule>.from(iface.acls);
      acls[index] = updated;
      _updateInterface(0, iface.copyWith(acls: acls));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DropdownRow<String>(
                  label: 'Action',
                  value: rule.action,
                  items: const ['allow', 'deny'],
                  onChanged: (v) => update(rule.copyWith(action: v!)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DropdownRow<String>(
                  label: 'Protocol',
                  value: rule.protocol,
                  items: const ['any', 'icmp', 'tcp', 'udp'],
                  onChanged: (v) => update(rule.copyWith(protocol: v!)),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.redAccent,
                ),
                onPressed: () {
                  final acls = List<AclRule>.from(iface.acls)..removeAt(index);
                  _updateInterface(0, iface.copyWith(acls: acls));
                },
                tooltip: 'Remove rule',
              ),
            ],
          ),
          _TextRow(
            label: 'From',
            value: rule.src,
            hint: 'any',
            onCommitted: (v) =>
                update(rule.copyWith(src: v.trim().isEmpty ? 'any' : v.trim())),
          ),
          _TextRow(
            label: 'To',
            value: rule.dst,
            hint: 'any',
            onCommitted: (v) =>
                update(rule.copyWith(dst: v.trim().isEmpty ? 'any' : v.trim())),
          ),
        ],
      ),
    );
  }

  static IconData _iconForType(DeviceType type) {
    switch (type) {
      case DeviceType.router:
        return Icons.router;
      case DeviceType.switchDevice:
        return Icons.lan;
      case DeviceType.firewall:
        return Icons.security;
      case DeviceType.pc:
        return Icons.computer;
      case DeviceType.server:
        return Icons.dns;
      case DeviceType.cloud:
        return Icons.cloud;
    }
  }
}

/// Accepts an empty value (field not yet filled in) or a dotted-quad IPv4.
String? _validateIpOrEmpty(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  final parts = trimmed.split('.');
  if (parts.length != 4) return 'Needs four parts, e.g. 192.168.1.10';
  for (final part in parts) {
    final n = int.tryParse(part);
    if (n == null ||
        n < 0 ||
        n > 255 ||
        (part.length > 1 && part.startsWith('0'))) {
      return 'Each part must be 0-255';
    }
  }
  return null;
}

String? _validateVlanOrEmpty(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  final n = int.tryParse(trimmed);
  if (n == null || n < 1 || n > 4094) return 'VLAN must be 1-4094';
  return null;
}

// ---------------------------------------------------------------------------
// Small presentational helpers
// ---------------------------------------------------------------------------

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

/// A labelled text field that commits on blur/submit rather than per keystroke.
class _TextRow extends StatefulWidget {
  const _TextRow({
    required this.label,
    required this.value,
    required this.onCommitted,
    this.hint,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final String value;
  final String? hint;
  final ValueChanged<String> onCommitted;
  final String? Function(String)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<_TextRow> createState() => _TextRowState();
}

class _TextRowState extends State<_TextRow> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_TextRow old) {
    super.didUpdateWidget(old);
    // Adopt external changes only while unfocused, so a rebuild triggered by
    // someone else's edit can't yank the text out from under the student.
    if (!_focusNode.hasFocus && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _commit();
  }

  void _commit() {
    final text = _controller.text;
    final error = widget.validator?.call(text);
    setState(() => _error = error);
    if (error != null) return;
    if (text.trim() != widget.value.trim()) widget.onCommitted(text);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 3),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            onSubmitted: (_) => _commit(),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              errorText: _error,
              errorStyle: const TextStyle(fontSize: 10),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppTheme.primaryCyan),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.help,
  });

  final String label;
  final String? help;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                if (help != null)
                  Text(
                    help!,
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primaryCyan,
          ),
        ],
      ),
    );
  }
}

class _DropdownRow<T> extends StatelessWidget {
  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 3),
        DropdownButtonFormField<T>(
          initialValue: value,
          isDense: true,
          dropdownColor: const Color(0xFF1B2338),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Colors.white24),
            ),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(item.toString()),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
