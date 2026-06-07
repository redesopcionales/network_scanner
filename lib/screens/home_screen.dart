import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/network_component.dart';
import '../database/database_helper.dart';
import 'qr_scanner_screen.dart';
import 'component_form_screen.dart';
import 'component_detail_screen.dart';
import 'network_schema_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<NetworkComponent> components = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    refreshComponents();
  }

  Future refreshComponents() async {
    setState(() => isLoading = true);
    components = await DatabaseHelper.instance.readAllComponents();
    setState(() => isLoading = false);
  }

  Future<void> scanQRCode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (result != null && result is String) {
      final cleanedQrCode = result.trim();

      print('Scanned QR Code: "$cleanedQrCode"');
      print('QR Code length: ${cleanedQrCode.length}');

      final existingComponent =
          await DatabaseHelper.instance.readComponentByQrCode(cleanedQrCode);

      print('Found existing component: ${existingComponent != null}');

      if (existingComponent != null) {
        if (!mounted) return;

        final detailResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ComponentDetailScreen(component: existingComponent),
          ),
        );

        if (detailResult == true) {
          refreshComponents();
        }
      } else {
        if (!mounted) return;

        final saved = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ComponentFormScreen(qrCode: cleanedQrCode),
          ),
        );

        if (saved == true) {
          refreshComponents();
        }
      }
    }
  }

  IconData getIconForType(String type) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Components'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree),
            tooltip: 'Network Schema',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                   builder: (context) => NetworkSchemaScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshComponents,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : components.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        size: 100,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No components scanned yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the + button to scan a QR code',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: components.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final component = components[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(getIconForType(component.componentType)),
                        ),
                        title: Text(
                          component.componentType,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (component.brand != null)
                              Text(
                                  '${component.brand} ${component.model ?? ''}'),
                            if (component.ipAddress != null)
                              Text('IP: ${component.ipAddress}'),
                            Text(
                              'Scanned: ${DateFormat('MMM dd, yyyy').format(component.createdTime)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ComponentDetailScreen(component: component),
                            ),
                          );
                          if (result == true) {
                            refreshComponents();
                          }
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: scanQRCode,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan QR'),
      ),
    );
  }
}