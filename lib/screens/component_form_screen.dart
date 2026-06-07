import 'package:flutter/material.dart';
import '../models/network_component.dart';
import '../database/database_helper.dart';

class ComponentFormScreen extends StatefulWidget {
  final String qrCode;
  final NetworkComponent? component;

  const ComponentFormScreen({
    Key? key,
    required this.qrCode,
    this.component,
  }) : super(key: key);

  @override
  State<ComponentFormScreen> createState() => _ComponentFormScreenState();
}

class _ComponentFormScreenState extends State<ComponentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _qrController;
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _ipController;
  late TextEditingController _macController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;

  String _selectedType = 'Router';
  List<int> _selectedConnections = [];
  List<NetworkComponent> _allComponents = [];

  final List<String> _componentTypes = [
    'Router',
    'Switch',
    'Access Point',
    'Firewall',
    'Server',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadAllComponents();
    _qrController = TextEditingController(
        text: widget.component?.qrCode ?? widget.qrCode);
    _brandController =
        TextEditingController(text: widget.component?.brand ?? '');
    _modelController =
        TextEditingController(text: widget.component?.model ?? '');
    _ipController =
        TextEditingController(text: widget.component?.ipAddress ?? '');
    _macController =
        TextEditingController(text: widget.component?.macAddress ?? '');
    _locationController =
        TextEditingController(text: widget.component?.location ?? '');
    _notesController =
        TextEditingController(text: widget.component?.notes ?? '');

    if (widget.component != null) {
      _selectedType = widget.component!.componentType;
      _selectedConnections =
          List.from(widget.component!.connectedComponentIds);
    }
  }

  Future<void> _loadAllComponents() async {
    final components =
        await DatabaseHelper.instance.readAllComponents();
    setState(() {
      _allComponents = components
          .where((c) => c.id != widget.component?.id)
          .toList();
    });
  }

  @override
  void dispose() {
    _qrController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _ipController.dispose();
    _macController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _normalizeMac(String mac) {
    String clean = mac.replaceAll(':', '').replaceAll('-', '');
    List<String> groups = [];
    for (int i = 0; i < clean.length; i += 2) {
      groups.add(clean.substring(i, i + 2));
    }
    return groups.join(':').toUpperCase();
  }

  Future<void> _saveComponent() async {
    if (_formKey.currentState!.validate()) {
      final component = NetworkComponent(
        id: widget.component?.id,
        qrCode: _qrController.text,
        componentType: _selectedType,
        brand: _brandController.text.isEmpty ? null : _brandController.text,
        model: _modelController.text.isEmpty ? null : _modelController.text,
        ipAddress:
            _ipController.text.isEmpty ? null : _ipController.text,
        macAddress: _macController.text.isEmpty
            ? null
            : _normalizeMac(_macController.text),
        location: _locationController.text.isEmpty
            ? null
            : _locationController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        connectedComponentIds: _selectedConnections,
        createdTime: widget.component?.createdTime ?? DateTime.now(),
      );

      if (widget.component == null) {
        await DatabaseHelper.instance.create(component);
      } else {
        await DatabaseHelper.instance.update(component);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.component == null ? 'Add Component' : 'Edit Component'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveComponent,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _qrController,
              decoration: const InputDecoration(
                labelText: 'QR Code',
                prefixIcon: Icon(Icons.qr_code),
                border: OutlineInputBorder(),
              ),
              enabled: false,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Component Type *',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: _componentTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedType = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Brand',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Model',
                prefixIcon: Icon(Icons.devices),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                prefixIcon: Icon(Icons.language),
                border: OutlineInputBorder(),
                hintText: 'e.g., 192.168.1.1',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final ipRegex = RegExp(
                    r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
                  );
                  if (!ipRegex.hasMatch(value)) {
                    return 'Enter a valid IP address';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _macController,
              decoration: const InputDecoration(
                labelText: 'MAC Address',
                prefixIcon: Icon(Icons.settings_ethernet),
                border: OutlineInputBorder(),
                hintText: 'e.g., 00:1A:2B:3C:4D:5E',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final macRegex = RegExp(
                    r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$',
                  );
                  if (!macRegex.hasMatch(value)) {
                    return 'Enter a valid MAC address (e.g., 00:1A:2B:3C:4D:5E)';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
                hintText: 'e.g., Server Room A, Rack 3',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connected To:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_allComponents.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'No other components yet. Create more components first.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ..._allComponents.map((component) {
                        final isSelected =
                            _selectedConnections.contains(component.id);
                        return CheckboxListTile(
                          title: Text(component.componentType),
                          subtitle: Text(
                              '${component.brand ?? 'Unknown'} - ${component.qrCode}'),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                if (!_selectedConnections
                                    .contains(component.id)) {
                                  _selectedConnections.add(component.id!);
                                }
                              } else {
                                _selectedConnections.remove(component.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    if (_selectedConnections.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Wrap(
                          spacing: 8,
                          children: _selectedConnections.map((id) {
                            final component = _allComponents
                                .firstWhere((c) => c.id == id);
                            return Chip(
                              label: Text(
                                  '${component.componentType} (${component.qrCode})'),
                              onDeleted: () {
                                setState(() {
                                  _selectedConnections.remove(id);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '* = Required field',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _saveComponent,
              icon: const Icon(Icons.save),
              label: const Text('Save Component'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}