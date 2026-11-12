import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:food_pos/core/data/local/initial_data_seeder.dart';
import 'package:food_pos/core/data/local/tables.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  static const String dbName = 'food_pos.db';
  static const int dbVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(dbName);
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    debugPrint('📁 [SQLITE DB LOCATION]: $path');

    return await openDatabase(
      path,
      version: dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppTables.users} (
        ${UserColumns.id} TEXT PRIMARY KEY,
        ${UserColumns.username} TEXT NOT NULL UNIQUE,
        ${UserColumns.name} TEXT NOT NULL,
        ${UserColumns.email} TEXT,
        ${UserColumns.phone} TEXT,
        ${UserColumns.role} TEXT NOT NULL DEFAULT 'cashier',
        ${UserColumns.pinHash} TEXT,
        ${UserColumns.isActive} INTEGER NOT NULL DEFAULT 1,
        ${UserColumns.createdAt} TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE ${AppTables.categories} (
        ${CategoryColumns.id} TEXT PRIMARY KEY,
        ${CategoryColumns.name} TEXT NOT NULL,
        ${CategoryColumns.iconName} TEXT,
        ${CategoryColumns.sortOrder} INTEGER NOT NULL DEFAULT 0,
        ${CategoryColumns.isActive} INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE ${AppTables.products} (
        ${ProductColumns.id} TEXT PRIMARY KEY,
        ${ProductColumns.categoryId} TEXT NOT NULL,
        ${ProductColumns.sku} TEXT UNIQUE,
        ${ProductColumns.name} TEXT NOT NULL,
        ${ProductColumns.price} REAL NOT NULL,
        ${ProductColumns.costPrice} REAL DEFAULT 0,
        ${ProductColumns.stock} INTEGER NOT NULL DEFAULT 0,
        ${ProductColumns.trackStock} INTEGER NOT NULL DEFAULT 1,
        ${ProductColumns.iconName} TEXT,
        ${ProductColumns.imagePath} TEXT,
        ${ProductColumns.isAvailable} INTEGER NOT NULL DEFAULT 1,
        ${ProductColumns.createdAt} TEXT NOT NULL,
        ${ProductColumns.updatedAt} TEXT NOT NULL,
        FOREIGN KEY (${ProductColumns.categoryId}) REFERENCES ${AppTables.categories} (${CategoryColumns.id}) ON DELETE RESTRICT
      );
    ''');

    await db.execute('''
      CREATE TABLE ${AppTables.addons} (
        ${AddonColumns.id} TEXT PRIMARY KEY,
        ${AddonColumns.name} TEXT NOT NULL,
        ${AddonColumns.price} REAL NOT NULL DEFAULT 0,
        ${AddonColumns.stock} INTEGER NOT NULL DEFAULT 0,
        ${AddonColumns.trackStock} INTEGER NOT NULL DEFAULT 1,
        ${AddonColumns.isActive} INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE ${AppTables.productAddons} (
        ${ProductAddonColumns.productId} TEXT NOT NULL,
        ${ProductAddonColumns.addonId} TEXT NOT NULL,
        PRIMARY KEY (${ProductAddonColumns.productId}, ${ProductAddonColumns.addonId}),
        FOREIGN KEY (${ProductAddonColumns.productId}) REFERENCES ${AppTables.products} (${ProductColumns.id}) ON DELETE CASCADE,
        FOREIGN KEY (${ProductAddonColumns.addonId}) REFERENCES ${AppTables.addons} (${AddonColumns.id}) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE ${AppTables.transactions} (
        ${TransactionColumns.id} TEXT PRIMARY KEY,
        ${TransactionColumns.receiptNo} TEXT NOT NULL UNIQUE,
        ${TransactionColumns.cashierId} TEXT,
        ${TransactionColumns.cashierName} TEXT NOT NULL,
        ${TransactionColumns.tableNo} TEXT,
        ${TransactionColumns.customerName} TEXT,
        ${TransactionColumns.subtotal} REAL NOT NULL,
        ${TransactionColumns.discountType} TEXT DEFAULT 'fixed',
        ${TransactionColumns.discountRate} REAL DEFAULT 0,
        ${TransactionColumns.discountAmount} REAL NOT NULL DEFAULT 0,
        ${TransactionColumns.taxRate} REAL DEFAULT 0,
        ${TransactionColumns.taxAmount} REAL NOT NULL DEFAULT 0,
        ${TransactionColumns.serviceRate} REAL DEFAULT 0,
        ${TransactionColumns.serviceAmount} REAL NOT NULL DEFAULT 0,
        ${TransactionColumns.grandTotal} REAL NOT NULL,
        ${TransactionColumns.paymentMethod} TEXT NOT NULL,
        ${TransactionColumns.cashReceived} REAL NOT NULL DEFAULT 0,
        ${TransactionColumns.changeGiven} REAL NOT NULL DEFAULT 0,
        ${TransactionColumns.status} TEXT NOT NULL DEFAULT 'completed',
        ${TransactionColumns.notes} TEXT,
        ${TransactionColumns.createdAt} TEXT NOT NULL,
        ${TransactionColumns.updatedAt} TEXT NOT NULL,
        FOREIGN KEY (${TransactionColumns.cashierId}) REFERENCES ${AppTables.users} (${UserColumns.id}) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE ${AppTables.transactionItems} (
        ${TransactionItemColumns.id} TEXT PRIMARY KEY,
        ${TransactionItemColumns.transactionId} TEXT NOT NULL,
        ${TransactionItemColumns.productId} TEXT,
        ${TransactionItemColumns.productName} TEXT NOT NULL,
        ${TransactionItemColumns.unitPrice} REAL NOT NULL,
        ${TransactionItemColumns.costPrice} REAL NOT NULL DEFAULT 0,
        ${TransactionItemColumns.quantity} INTEGER NOT NULL,
        ${TransactionItemColumns.subtotal} REAL NOT NULL,
        ${TransactionItemColumns.notes} TEXT,
        FOREIGN KEY (${TransactionItemColumns.transactionId}) REFERENCES ${AppTables.transactions} (${TransactionColumns.id}) ON DELETE CASCADE,
        FOREIGN KEY (${TransactionItemColumns.productId}) REFERENCES ${AppTables.products} (${ProductColumns.id}) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE ${AppTables.transactionItemAddons} (
        ${TransactionItemAddonColumns.id} TEXT PRIMARY KEY,
        ${TransactionItemAddonColumns.transactionItemId} TEXT NOT NULL,
        ${TransactionItemAddonColumns.addonId} TEXT,
        ${TransactionItemAddonColumns.addonName} TEXT NOT NULL,
        ${TransactionItemAddonColumns.addonPrice} REAL NOT NULL,
        ${TransactionItemAddonColumns.quantity} INTEGER NOT NULL DEFAULT 1,
        ${TransactionItemAddonColumns.subtotal} REAL NOT NULL,
        FOREIGN KEY (${TransactionItemAddonColumns.transactionItemId}) REFERENCES ${AppTables.transactionItems} (${TransactionItemColumns.id}) ON DELETE CASCADE,
        FOREIGN KEY (${TransactionItemAddonColumns.addonId}) REFERENCES ${AppTables.addons} (${AddonColumns.id}) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE ${AppTables.inventoryLogs} (
        ${InventoryLogColumns.id} TEXT PRIMARY KEY,
        ${InventoryLogColumns.itemType} TEXT NOT NULL,
        ${InventoryLogColumns.itemId} TEXT NOT NULL,
        ${InventoryLogColumns.quantityChange} INTEGER NOT NULL,
        ${InventoryLogColumns.balanceAfter} INTEGER NOT NULL,
        ${InventoryLogColumns.mutationType} TEXT NOT NULL,
        ${InventoryLogColumns.referenceId} TEXT,
        ${InventoryLogColumns.notes} TEXT,
        ${InventoryLogColumns.createdAt} TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE ${AppTables.storeSettings} (
        ${StoreSettingColumns.id} TEXT PRIMARY KEY,
        ${StoreSettingColumns.storeName} TEXT NOT NULL,
        ${StoreSettingColumns.address} TEXT,
        ${StoreSettingColumns.phone} TEXT,
        ${StoreSettingColumns.receiptHeader} TEXT,
        ${StoreSettingColumns.receiptFooter} TEXT,
        ${StoreSettingColumns.taxRate} REAL DEFAULT 10.0,
        ${StoreSettingColumns.serviceRate} REAL DEFAULT 0.0,
        ${StoreSettingColumns.currencyCode} TEXT DEFAULT 'IDR'
      );
    ''');

    await db.execute('CREATE INDEX idx_products_category ON ${AppTables.products} (${ProductColumns.categoryId});');
    await db.execute('CREATE INDEX idx_products_name ON ${AppTables.products} (${ProductColumns.name});');
    await db.execute('CREATE INDEX idx_transactions_created_at ON ${AppTables.transactions} (${TransactionColumns.createdAt});');
    await db.execute('CREATE INDEX idx_transactions_status ON ${AppTables.transactions} (${TransactionColumns.status});');
    await db.execute('CREATE INDEX idx_tx_items_transaction ON ${AppTables.transactionItems} (${TransactionItemColumns.transactionId});');
    await db.execute('CREATE INDEX idx_tx_item_addons_item ON ${AppTables.transactionItemAddons} (${TransactionItemAddonColumns.transactionItemId});');

    await InitialDataSeeder.seedAll(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {}

  Future<Map<String, int>> inspectDatabase() async {
    final db = await database;
    final dbPath = await getDatabasesPath();
    final fullPath = join(dbPath, dbName);

    final tables = await db.rawQuery(
      "SELECT name, sql FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
    );

    final Map<String, int> summary = {};

    debugPrint('========== [POS DB INSPECTOR] ==========');
    debugPrint('📁 File Database: $fullPath');
    for (final table in tables) {
      final tableName = table['name'] as String;
      final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
      final count = Sqflite.firstIntValue(countResult) ?? 0;
      summary[tableName] = count;
      debugPrint('Table: $tableName ($count rows)');
    }
    debugPrint('=========================================');
    return summary;
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<void> resetDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);
    await close();
    await deleteDatabase(path);
    _database = await _initDB(dbName);
  }
}
