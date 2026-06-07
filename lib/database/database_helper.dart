import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/network_component.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('network_components.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';

    await db.execute('''
      CREATE TABLE $tableNetworkComponents (
        ${NetworkComponentFields.id} $idType,
        ${NetworkComponentFields.qrCode} $textType,
        ${NetworkComponentFields.componentType} $textType,
        ${NetworkComponentFields.brand} $textTypeNullable,
        ${NetworkComponentFields.model} $textTypeNullable,
        ${NetworkComponentFields.ipAddress} $textTypeNullable,
        ${NetworkComponentFields.macAddress} $textTypeNullable,
        ${NetworkComponentFields.location} $textTypeNullable,
        ${NetworkComponentFields.notes} $textTypeNullable,
        ${NetworkComponentFields.connectedComponentIds} $textTypeNullable,
        ${NetworkComponentFields.createdTime} $textType
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add the new column if it doesn't exist
      try {
        await db.execute('''
          ALTER TABLE $tableNetworkComponents 
          ADD COLUMN ${NetworkComponentFields.connectedComponentIds} TEXT
        ''');
      } catch (e) {
        print('Column already exists or error: $e');
      }
    }
  }

  Future<NetworkComponent> create(NetworkComponent component) async {
    final db = await instance.database;
    final id = await db.insert(tableNetworkComponents, component.toJson());
    return component.copy(id: id);
  }

  Future<NetworkComponent?> readComponent(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      tableNetworkComponents,
      columns: NetworkComponentFields.values,
      where: '${NetworkComponentFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return NetworkComponent.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<NetworkComponent?> readComponentByQrCode(String qrCode) async {
    final db = await instance.database;

    final cleanedQrCode = qrCode.trim();

    final maps = await db.query(
      tableNetworkComponents,
      columns: NetworkComponentFields.values,
      where: '${NetworkComponentFields.qrCode} = ?',
      whereArgs: [cleanedQrCode],
    );

    if (maps.isNotEmpty) {
      return NetworkComponent.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<List<NetworkComponent>> readAllComponents() async {
    final db = await instance.database;
    const orderBy = '${NetworkComponentFields.createdTime} DESC';
    final result = await db.query(tableNetworkComponents, orderBy: orderBy);
    return result.map((json) => NetworkComponent.fromJson(json)).toList();
  }

  Future<int> update(NetworkComponent component) async {
    final db = await instance.database;
    return db.update(
      tableNetworkComponents,
      component.toJson(),
      where: '${NetworkComponentFields.id} = ?',
      whereArgs: [component.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      tableNetworkComponents,
      where: '${NetworkComponentFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}