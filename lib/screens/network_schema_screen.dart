import 'package:flutter/material.dart';
import '../models/network_component.dart';
import '../database/database_helper.dart';

class NetworkSchemaScreen extends StatefulWidget {
  const NetworkSchemaScreen({Key? key}) : super(key: key);

  @override
  State<NetworkSchemaScreen> createState() => _NetworkSchemaScreenState();
}

class _NetworkSchemaScreenState extends State<NetworkSchemaScreen> {
  List<NetworkComponent> components = [];
  List<NetworkComponent> filteredComponents = [];
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadComponents();
    _searchController.addListener(_filterComponents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadComponents() async {
    final loaded = await DatabaseHelper.instance.readAllComponents();
    setState(() {
      components = loaded;
      filteredComponents = loaded;
      isLoading = false;
    });
  }

  void _filterComponents() {
    setState(() {
      searchQuery = _searchController.text.toLowerCase();
      if (searchQuery.isEmpty) {
        filteredComponents = components;
      } else {
        filteredComponents = components.where((component) {
          final matchesQr =
              component.qrCode.toLowerCase().contains(searchQuery);
          final matchesType =
              component.componentType.toLowerCase().contains(searchQuery);
          final matchesBrand = component.brand != null &&
              component.brand!.toLowerCase().contains(searchQuery);
          final matchesIP = component.ipAddress != null &&
              component.ipAddress!.toLowerCase().contains(searchQuery);
          final matchesLocation = component.location != null &&
              component.location!.toLowerCase().contains(searchQuery);

          return matchesQr ||
              matchesType ||
              matchesBrand ||
              matchesIP ||
              matchesLocation;
        }).toList();
      }
    });
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

  List<Widget> _buildSchema() {
    return filteredComponents.map((component) {
      final connectedCount = component.connectedComponentIds.length;

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
          child: ExpansionTile(
            leading: Icon(_getIconForType(component.componentType)),
            title: Text('${component.componentType} - ${component.qrCode}'),
            subtitle: Text(
                '${component.brand ?? 'Unknown'} ${component.model ?? ''}'
                    .trim()),
            trailing: connectedCount > 0
                ? Chip(
                    label: Text('$connectedCount connected'),
                    backgroundColor: Colors.blue[100],
                  )
                : const Text('No connections'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Details',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (component.ipAddress != null)
                                Text('IP: ${component.ipAddress}'),
                              if (component.macAddress != null)
                                Text('MAC: ${component.macAddress}'),
                              if (component.location != null)
                                Text('Location: ${component.location}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (component.connectedComponentIds.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'No connections',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.link,
                                  color: Colors.grey[600], size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Connected To:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ..._buildConnectionsList(
                              component.connectedComponentIds),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildConnectionsList(List<int> connectionIds) {
    return connectionIds.map((id) {
      final connectedComponent = components.firstWhere(
        (c) => c.id == id,
        orElse: () => NetworkComponent(
          qrCode: 'Unknown',
          componentType: 'Unknown',
          createdTime: DateTime.now(),
        ),
      );

      return Padding(
        padding: const EdgeInsets.only(left: 28, bottom: 8),
        child: Row(
          children: [
            Icon(
              Icons.arrow_right,
              color: Colors.blue[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${connectedComponent.componentType} (${connectedComponent.qrCode})',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
            if (connectedComponent.ipAddress != null)
              Text(
                connectedComponent.ipAddress!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildConnectionSummary() {
    Map<String, int> typeCounts = {};
    for (var component in filteredComponents) {
      typeCounts[component.componentType] =
          (typeCounts[component.componentType] ?? 0) + 1;
    }

    int totalConnections = 0;
    for (var component in filteredComponents) {
      totalConnections += component.connectedComponentIds.length;
    }

    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  const Text(
                    'Statistics',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${filteredComponents.length}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Text('Components Found'),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '$totalConnections',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Text('Connections'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.category, color: Colors.purple[600]),
                  const SizedBox(width: 8),
                  const Text(
                    'Components by Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...typeCounts.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(_getIconForType(entry.key), size: 20),
                          const SizedBox(width: 8),
                          Text(entry.key),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${entry.value}',
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Schema'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadComponents,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : components.isEmpty
              ? const Center(
                  child: Text('No components to display'),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText:
                              'Search by QR, Type, Brand, IP, Location...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterComponents();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Results: ${filteredComponents.length} / ${components.length}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (searchQuery.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                _filterComponents();
                              },
                              icon: const Icon(Icons.clear, size: 18),
                              label: const Text('Clear'),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filteredComponents.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No components found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try a different search term',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Network Topology',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ..._buildSchema(),
                                  const SizedBox(height: 24),
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Connection Summary',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ..._buildConnectionSummary(),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}