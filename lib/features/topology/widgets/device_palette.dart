import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/enums/app_enums.dart';

/// Sidebar Device Palette Widget for drag-and-drop or tap placement on canvas
class DevicePalette extends StatelessWidget {
  final Function(DeviceType type, String defaultModel) onDeviceSelected;

  const DevicePalette({super.key, required this.onDeviceSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppTheme.surfaceGlass,
        border: const Border(right: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.developer_board,
                  color: AppTheme.primaryCyan,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Hardware Library',
                  style: TextStyle(
                    color: AppTheme.textBright,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildDeviceTile(
                  type: DeviceType.router,
                  label: 'Router',
                  model: 'Cisco 2911 ISR',
                  icon: Icons.router,
                  color: AppTheme.primaryCyan,
                ),
                _buildDeviceTile(
                  type: DeviceType.switchDevice,
                  label: 'Switch',
                  model: 'Catalyst 2960',
                  icon: Icons.swap_horiz,
                  color: AppTheme.primaryBlue,
                ),
                _buildDeviceTile(
                  type: DeviceType.firewall,
                  label: 'Firewall',
                  model: 'ASA 5506-X',
                  icon: Icons.security,
                  color: AppTheme.accentCrimson,
                ),
                _buildDeviceTile(
                  type: DeviceType.pc,
                  label: 'Workstation PC',
                  model: 'Ubuntu Host',
                  icon: Icons.desktop_windows,
                  color: AppTheme.accentEmerald,
                ),
                _buildDeviceTile(
                  type: DeviceType.server,
                  label: 'Server Host',
                  model: 'Enterprise Server',
                  icon: Icons.dns,
                  color: Colors.purpleAccent,
                ),
                _buildDeviceTile(
                  type: DeviceType.cloud,
                  label: 'Cloud / WAN',
                  model: 'Internet Gateway',
                  icon: Icons.cloud_queue,
                  color: Colors.amber,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTile({
    required DeviceType type,
    required String label,
    required String model,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onDeviceSelected(type, model),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundMidnight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: AppTheme.textBright,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        model,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.add_circle_outline,
                  color: color.withValues(alpha: 0.7),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
