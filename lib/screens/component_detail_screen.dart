import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/network_component.dart';
import '../database/database_helper.dart';
import 'component_form_screen.dart';

class ComponentDetailScreen extends StatelessWidget {
  final NetworkComponent component;

  const ComponentDetailScreen({Key? key, required this.component})
      : super(key: key);

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  Future<void> _deleteComponent(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Component'),
        content: const Text('Are you sure you want to delete this component?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && component.id != null) {
      await DatabaseHelper.instance.delete(component.id!);
      if (context.mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Component Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ComponentFormScreen(
                    qrCode: component.qrCode,
                    component: component,
                  ),
                ),
              );
              if (result == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteComponent(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(
            context,
            'QR Code',
            component.qrCode,
            Icons.qr_code,
            canCopy: true,
          ),
          _buildInfoCard(
            context,
            'Component Type',
            component.componentType,
            Icons.category,
          ),
          if (component.brand != null)
            _buildInfoCard(
              context,
              'Brand',
              component.brand!,
              Icons.business,
            ),
          if (component.model != null)
            _buildInfoCard(
              context,
              'Model',
              component.model!,
              Icons.devices,
            ),
          if (component.ipAddress != null)
            _buildInfoCard(
              context,
              'IP Address',
              component.ipAddress!,
              Icons.language,
              canCopy: true,
            ),
          if (component.macAddress != null)
            _buildInfoCard(
              context,
              'MAC Address',
              component.macAddress!,
              Icons.settings_ethernet,
              canCopy: true,
            ),
          if (component.location != null)
            _buildInfoCard(
              context,
              'Location',
              component.location!,
              Icons.location_on,
            ),
          if (component.notes != null)
            _buildInfoCard(
              context,
              'Notes',
              component.notes!,
              Icons.note,
            ),
          _buildInfoCard(
            context,
            'Scanned On',
            DateFormat('MMM dd, yyyy - HH:mm').format(component.createdTime),
            Icons.calendar_today,
          ),
          if (component.connectedComponentIds.isNotEmpty)
            Card(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.link, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Connected Components',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<NetworkComponent>>(
                      future: _getConnectedComponents(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        final connectedComponents = snapshot.data ?? [];
                        if (connectedComponents.isEmpty) {
                          return const Text('No connected components found');
                        }
                        return Column(
                          children: connectedComponents.map((conn) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                dense: true,
                                leading: Icon(
                                  _getIconForType(conn.componentType),
                                  size: 20,
                                ),
                                title: Text(conn.componentType),
                                subtitle: Text(
                                    '${conn.brand ?? 'Unknown'} - ${conn.qrCode}'),
                                trailing: const Icon(Icons.arrow_forward,
                                    size: 16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ComponentDetailScreen(
                                              component: conn),
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool canCopy = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: canCopy
            ? IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () => _copyToClipboard(context, value, label),
              )
            : null,
      ),
    );
  }

  Future<List<NetworkComponent>> _getConnectedComponents() async {
    List<NetworkComponent> connectedComponents = [];
    for (int id in component.connectedComponentIds) {
      final comp = await DatabaseHelper.instance.readComponent(id);
      if (comp != null) {
        connectedComponents.add(comp);
      }
    }
    return connectedComponents;
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Router':
        return Icons.router;
      case 'Switch':
        return Icons.settings_input_component;
      case 'Access Point':
        return Icons.wifi;
      case 'Firewall':
        return Icons.security;
      case 'Server':
        return Icons.dns;
      default:
        return Icons.device_hub;
    }
  }
}