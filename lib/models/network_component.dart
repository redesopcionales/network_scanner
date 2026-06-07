const String tableNetworkComponents = 'network_components';

class NetworkComponentFields {
  static final List<String> values = [
    id, qrCode, componentType, brand, model, ipAddress, 
    macAddress, location, notes, connectedComponentIds, createdTime
  ];

  static const String id = '_id';
  static const String qrCode = 'qrCode';
  static const String componentType = 'componentType';
  static const String brand = 'brand';
  static const String model = 'model';
  static const String ipAddress = 'ipAddress';
  static const String macAddress = 'macAddress';
  static const String location = 'location';
  static const String notes = 'notes';
  static const String connectedComponentIds = 'connectedComponentIds'; // 👈 NEW
  static const String createdTime = 'createdTime';
}

class NetworkComponent {
  final int? id;
  final String qrCode;
  final String componentType;
  final String? brand;
  final String? model;
  final String? ipAddress;
  final String? macAddress;
  final String? location;
  final String? notes;
  final List<int> connectedComponentIds; // 👈 NEW - stores IDs of connected components
  final DateTime createdTime;

  const NetworkComponent({
    this.id,
    required this.qrCode,
    required this.componentType,
    this.brand,
    this.model,
    this.ipAddress,
    this.macAddress,
    this.location,
    this.notes,
    this.connectedComponentIds = const [], // 👈 NEW - default empty list
    required this.createdTime,
  });

  NetworkComponent copy({
    int? id,
    String? qrCode,
    String? componentType,
    String? brand,
    String? model,
    String? ipAddress,
    String? macAddress,
    String? location,
    String? notes,
    List<int>? connectedComponentIds, // 👈 NEW
    DateTime? createdTime,
  }) =>
      NetworkComponent(
        id: id ?? this.id,
        qrCode: qrCode ?? this.qrCode,
        componentType: componentType ?? this.componentType,
        brand: brand ?? this.brand,
        model: model ?? this.model,
        ipAddress: ipAddress ?? this.ipAddress,
        macAddress: macAddress ?? this.macAddress,
        location: location ?? this.location,
        notes: notes ?? this.notes,
        connectedComponentIds: connectedComponentIds ?? this.connectedComponentIds, // 👈 NEW
        createdTime: createdTime ?? this.createdTime,
      );

  static NetworkComponent fromJson(Map<String, Object?> json) => NetworkComponent(
        id: json[NetworkComponentFields.id] as int?,
        qrCode: json[NetworkComponentFields.qrCode] as String,
        componentType: json[NetworkComponentFields.componentType] as String,
        brand: json[NetworkComponentFields.brand] as String?,
        model: json[NetworkComponentFields.model] as String?,
        ipAddress: json[NetworkComponentFields.ipAddress] as String?,
        macAddress: json[NetworkComponentFields.macAddress] as String?,
        location: json[NetworkComponentFields.location] as String?,
        notes: json[NetworkComponentFields.notes] as String?,
        connectedComponentIds: _parseConnections(json[NetworkComponentFields.connectedComponentIds] as String?), // 👈 NEW
        createdTime: DateTime.parse(json[NetworkComponentFields.createdTime] as String),
      );

  Map<String, Object?> toJson() => {
        NetworkComponentFields.id: id,
        NetworkComponentFields.qrCode: qrCode,
        NetworkComponentFields.componentType: componentType,
        NetworkComponentFields.brand: brand,
        NetworkComponentFields.model: model,
        NetworkComponentFields.ipAddress: ipAddress,
        NetworkComponentFields.macAddress: macAddress,
        NetworkComponentFields.location: location,
        NetworkComponentFields.notes: notes,
        NetworkComponentFields.connectedComponentIds: _serializeConnections(connectedComponentIds), // 👈 NEW
        NetworkComponentFields.createdTime: createdTime.toIso8601String(),
      };

  // 👇 NEW - Convert list to string for database storage
  static String _serializeConnections(List<int> ids) {
    return ids.join(',');
  }

  // 👇 NEW - Convert string back to list
  static List<int> _parseConnections(String? idsString) {
    if (idsString == null || idsString.isEmpty) return [];
    return idsString.split(',').map((id) => int.parse(id.trim())).toList();
  }
}