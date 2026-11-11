import 'package:food_pos/core/data/local/database_helper.dart';
import 'package:food_pos/core/data/local/tables.dart';
import 'package:food_pos/core/models/pos_models.dart';
import 'package:food_pos/features/products/data/models/product_table_model.dart';
import 'package:sqflite/sqflite.dart';

class ProductLocalDataSource {
  final DatabaseHelper _dbHelper;

  ProductLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<PosCategory>> getCategories() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> categoryRows = await db.query(
      AppTables.categories,
      where: '${CategoryColumns.isActive} = ?',
      whereArgs: [1],
      orderBy: '${CategoryColumns.sortOrder} ASC',
    );

    final List<PosCategory> result = [];
    int totalAllCount = 0;

    for (final row in categoryRows) {
      final catId = row[CategoryColumns.id] as String;
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${AppTables.products} WHERE ${ProductColumns.categoryId} = ?',
        [catId],
      );
      final count = Sqflite.firstIntValue(countResult) ?? 0;
      totalAllCount += count;

      result.add(CategoryTableModel.fromMap(row, itemCount: count));
    }

    // Sisipkan kategori virtual 'All Menu' di index pertama
    result.insert(
      0,
      PosCategory(
        id: 'all',
        name: 'All Menu',
        icon: mockCategories[0].icon,
        itemCount: totalAllCount,
      ),
    );

    return result;
  }

  Future<List<PosAddon>> getAddons() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> addonRows = await db.query(
      AppTables.addons,
      where: '${AddonColumns.isActive} = ?',
      whereArgs: [1],
      orderBy: '${AddonColumns.name} ASC',
    );

    return addonRows.map((row) => AddonTableModel.fromMap(row)).toList();
  }

  Future<List<PosProduct>> getProducts({String? categoryId, String? search}) async {
    final db = await _dbHelper.database;

    String? whereClause;
    List<dynamic> whereArgs = [];

    if (categoryId != null && categoryId != 'all') {
      whereClause = '${ProductColumns.categoryId} = ?';
      whereArgs.add(categoryId);
    }

    if (search != null && search.trim().isNotEmpty) {
      final searchFilter = '${ProductColumns.name} LIKE ?';
      whereClause = whereClause != null ? '$whereClause AND $searchFilter' : searchFilter;
      whereArgs.add('%${search.trim()}%');
    }

    final List<Map<String, dynamic>> productRows = await db.query(
      AppTables.products,
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: '${ProductColumns.name} ASC',
    );

    final List<PosProduct> products = [];
    for (final pRow in productRows) {
      final productId = pRow[ProductColumns.id] as String;
      final addons = await _getAddonsForProduct(db, productId);
      products.add(ProductTableModel.fromMap(pRow, addons: addons));
    }

    return products;
  }

  Future<List<PosAddon>> _getAddonsForProduct(Database db, String productId) async {
    final List<Map<String, dynamic>> rows = await db.rawQuery('''
      SELECT a.* FROM ${AppTables.addons} a
      INNER JOIN ${AppTables.productAddons} pa ON a.${AddonColumns.id} = pa.${ProductAddonColumns.addonId}
      WHERE pa.${ProductAddonColumns.productId} = ? AND a.${AddonColumns.isActive} = 1
    ''', [productId]);

    return rows.map((row) => AddonTableModel.fromMap(row)).toList();
  }

  Future<PosProduct?> getProductById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      AppTables.products,
      where: '${ProductColumns.id} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    final addons = await _getAddonsForProduct(db, id);
    return ProductTableModel.fromMap(rows.first, addons: addons);
  }

  Future<void> saveProduct(PosProduct product) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert(
        AppTables.products,
        {
          ...ProductTableModel.toMap(product),
          ProductColumns.createdAt: DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Re-map product addons
      await txn.delete(
        AppTables.productAddons,
        where: '${ProductAddonColumns.productId} = ?',
        whereArgs: [product.id],
      );

      for (final addon in product.availableAddons) {
        await txn.insert(
          AppTables.productAddons,
          {
            ProductAddonColumns.productId: product.id,
            ProductAddonColumns.addonId: addon.id,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> deleteProduct(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      AppTables.products,
      where: '${ProductColumns.id} = ?',
      whereArgs: [id],
    );
  }

  Future<void> saveCategory(PosCategory category) async {
    final db = await _dbHelper.database;
    await db.insert(
      AppTables.categories,
      CategoryTableModel.toMap(category),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      AppTables.categories,
      where: '${CategoryColumns.id} = ?',
      whereArgs: [id],
    );
  }

  Future<void> saveAddon(PosAddon addon) async {
    final db = await _dbHelper.database;
    await db.insert(
      AppTables.addons,
      AddonTableModel.toMap(addon),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAddon(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      AppTables.addons,
      where: '${AddonColumns.id} = ?',
      whereArgs: [id],
    );
  }
}
