import 'package:food_pos/core/data/local/database_helper.dart';
import 'package:food_pos/core/data/local/initial_data_seeder.dart';
import 'package:food_pos/core/data/local/tables.dart';
import 'package:food_pos/core/models/pos_models.dart';
import 'package:food_pos/features/transactions/data/models/transaction_table_model.dart';
import 'package:sqflite/sqflite.dart';

class TransactionLocalDataSource {
  final DatabaseHelper _dbHelper;

  TransactionLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> saveTransaction(PosTransaction tx) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      await txn.insert(
        AppTables.transactions,
        TransactionTableModel.toMap(tx),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      int itemIndex = 0;
      for (final item in tx.items) {
        itemIndex++;
        final itemId = '${tx.id}_item_$itemIndex';

        await txn.insert(
          AppTables.transactionItems,
          {
            TransactionItemColumns.id: itemId,
            TransactionItemColumns.transactionId: tx.id,
            TransactionItemColumns.productId: item.product.id,
            TransactionItemColumns.productName: item.product.name,
            TransactionItemColumns.unitPrice: item.product.price,
            TransactionItemColumns.costPrice: item.product.costPrice ?? 0,
            TransactionItemColumns.quantity: item.quantity,
            TransactionItemColumns.subtotal: item.totalPrice,
            TransactionItemColumns.notes: item.notes,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        await txn.rawUpdate('''
          UPDATE ${AppTables.products}
          SET ${ProductColumns.stock} = MAX(0, ${ProductColumns.stock} - ?)
          WHERE ${ProductColumns.id} = ?
        ''', [item.quantity, item.product.id]);

        await txn.insert(
          AppTables.inventoryLogs,
          {
            InventoryLogColumns.id: 'log_${DateTime.now().microsecondsSinceEpoch}',
            InventoryLogColumns.itemType: 'product',
            InventoryLogColumns.itemId: item.product.id,
            InventoryLogColumns.quantityChange: -item.quantity,
            InventoryLogColumns.balanceAfter: item.product.stock - item.quantity,
            InventoryLogColumns.mutationType: 'sale',
            InventoryLogColumns.referenceId: tx.id,
            InventoryLogColumns.notes: 'Sale transaction #${tx.receiptNo}',
            InventoryLogColumns.createdAt: DateTime.now().toIso8601String(),
          },
        );

        int addonIndex = 0;
        for (final addon in item.selectedAddons) {
          addonIndex++;
          final itemAddonId = '${itemId}_addon_$addonIndex';

          await txn.insert(
            AppTables.transactionItemAddons,
            {
              TransactionItemAddonColumns.id: itemAddonId,
              TransactionItemAddonColumns.transactionItemId: itemId,
              TransactionItemAddonColumns.addonId: addon.id,
              TransactionItemAddonColumns.addonName: addon.name,
              TransactionItemAddonColumns.addonPrice: addon.price,
              TransactionItemAddonColumns.quantity: 1,
              TransactionItemAddonColumns.subtotal: addon.price,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          await txn.rawUpdate('''
            UPDATE ${AppTables.addons}
            SET ${AddonColumns.stock} = MAX(0, ${AddonColumns.stock} - 1)
            WHERE ${AddonColumns.id} = ?
          ''', [addon.id]);
        }
      }
    });
  }

  Future<List<PosTransaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    String? status,
  }) async {
    final db = await _dbHelper.database;

    String? whereClause;
    List<dynamic> whereArgs = [];

    if (status != null) {
      whereClause = '${TransactionColumns.status} = ?';
      whereArgs.add(status);
    }

    if (startDate != null) {
      final cond = '${TransactionColumns.createdAt} >= ?';
      whereClause = whereClause != null ? '$whereClause AND $cond' : cond;
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      final cond = '${TransactionColumns.createdAt} <= ?';
      whereClause = whereClause != null ? '$whereClause AND $cond' : cond;
      whereArgs.add(endDate.toIso8601String());
    }

    if (search != null && search.trim().isNotEmpty) {
      final s = '%${search.trim()}%';
      final searchCondition =
          '(${TransactionColumns.receiptNo} LIKE ? OR ${TransactionColumns.cashierName} LIKE ? OR ${TransactionColumns.tableNo} LIKE ?)';
      whereClause = whereClause != null
          ? '$whereClause AND $searchCondition'
          : searchCondition;
      whereArgs.addAll([s, s, s]);
    }

    final List<Map<String, dynamic>> txRows = await db.query(
      AppTables.transactions,
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: '${TransactionColumns.createdAt} DESC',
    );

    final List<PosTransaction> transactions = [];
    for (final txRow in txRows) {
      final txId = txRow[TransactionColumns.id] as String;
      final items = await _getTransactionItems(db, txId);
      transactions.add(TransactionTableModel.fromMap(txRow, items));
    }

    return transactions;
  }

  Future<PosTransaction?> getTransactionById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      AppTables.transactions,
      where: '${TransactionColumns.id} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    final items = await _getTransactionItems(db, id);
    return TransactionTableModel.fromMap(rows.first, items);
  }

  Future<List<CartItem>> _getTransactionItems(Database db, String txId) async {
    final List<Map<String, dynamic>> itemRows = await db.query(
      AppTables.transactionItems,
      where: '${TransactionItemColumns.transactionId} = ?',
      whereArgs: [txId],
    );

    final List<CartItem> items = [];
    for (final iRow in itemRows) {
      final itemId = iRow[TransactionItemColumns.id] as String;
      final addonRows = await db.query(
        AppTables.transactionItemAddons,
        where: '${TransactionItemAddonColumns.transactionItemId} = ?',
        whereArgs: [itemId],
      );

      final List<PosAddon> selectedAddons = addonRows.map((a) {
        return PosAddon(
          id: a[TransactionItemAddonColumns.addonId] as String? ?? '',
          name: a[TransactionItemAddonColumns.addonName] as String,
          price: (a[TransactionItemAddonColumns.addonPrice] as num).toDouble(),
          isSelected: true,
        );
      }).toList();

      final product = PosProduct(
        id: iRow[TransactionItemColumns.productId] as String? ?? '',
        name: iRow[TransactionItemColumns.productName] as String,
        categoryId: 'general',
        price: (iRow[TransactionItemColumns.unitPrice] as num).toDouble(),
        costPrice: (iRow[TransactionItemColumns.costPrice] as num?)?.toDouble(),
        stock: 0,
        icon: InitialDataSeeder.getIconDataByName('coffee'),
      );

      items.add(CartItem(
        product: product,
        quantity: iRow[TransactionItemColumns.quantity] as int,
        selectedAddons: selectedAddons,
        notes: iRow[TransactionItemColumns.notes] as String?,
      ));
    }

    return items;
  }

  Future<Map<String, dynamic>> getSalesSummary({DateTime? date}) async {
    final db = await _dbHelper.database;
    final filterDate = date ?? DateTime.now();
    final dateStr =
        "${filterDate.year.toString().padLeft(4, '0')}-${filterDate.month.toString().padLeft(2, '0')}-${filterDate.day.toString().padLeft(2, '0')}";

    final result = await db.rawQuery('''
      SELECT 
        COUNT(id) as totalTransactions,
        COALESCE(SUM(grand_total), 0) as totalRevenue,
        COALESCE(SUM(subtotal), 0) as totalSubtotal,
        COALESCE(SUM(discount_amount), 0) as totalDiscount,
        COALESCE(SUM(tax_amount), 0) as totalTax
      FROM ${AppTables.transactions}
      WHERE DATE(created_at) = DATE(?) AND status = 'completed'
    ''', [dateStr]);

    if (result.isNotEmpty) {
      return result.first;
    }
    return {
      'totalTransactions': 0,
      'totalRevenue': 0.0,
      'totalSubtotal': 0.0,
      'totalDiscount': 0.0,
      'totalTax': 0.0,
    };
  }

  Future<List<Map<String, dynamic>>> getDailySalesHistory({int days = 7}) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT 
        DATE(created_at) as sale_date,
        COUNT(id) as tx_count,
        COALESCE(SUM(grand_total), 0) as revenue
      FROM ${AppTables.transactions}
      WHERE status = 'completed'
      GROUP BY DATE(created_at)
      ORDER BY sale_date DESC
      LIMIT ?
    ''', [days]);
  }

  Future<Map<String, dynamic>> getReportSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;
    String whereClause = "t.${TransactionColumns.status} = 'completed'";
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += " AND t.${TransactionColumns.createdAt} >= ?";
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClause += " AND t.${TransactionColumns.createdAt} <= ?";
      whereArgs.add(endDate.toIso8601String());
    }

    final summaryResult = await db.rawQuery('''
      SELECT 
        COUNT(DISTINCT t.${TransactionColumns.id}) as total_orders,
        COALESCE(SUM(t.${TransactionColumns.grandTotal}), 0) as gross_revenue,
        COALESCE(SUM(t.${TransactionColumns.discountAmount}), 0) as total_discount,
        COALESCE(SUM(t.${TransactionColumns.taxAmount}), 0) as total_tax,
        COALESCE(SUM(ti.${TransactionItemColumns.quantity}), 0) as total_items_sold
      FROM ${AppTables.transactions} t
      LEFT JOIN ${AppTables.transactionItems} ti ON t.${TransactionColumns.id} = ti.${TransactionItemColumns.transactionId}
      WHERE $whereClause
    ''', whereArgs);

    final row = summaryResult.isNotEmpty ? summaryResult.first : <String, dynamic>{};
    final totalOrders = (row['total_orders'] as num?)?.toInt() ?? 0;
    final grossRevenue = (row['gross_revenue'] as num?)?.toDouble() ?? 0.0;
    final totalDiscount = (row['total_discount'] as num?)?.toDouble() ?? 0.0;
    final totalTax = (row['total_tax'] as num?)?.toDouble() ?? 0.0;
    final totalItemsSold = (row['total_items_sold'] as num?)?.toInt() ?? 0;
    final avgOrderValue = totalOrders > 0 ? grossRevenue / totalOrders : 0.0;

    return {
      'totalOrders': totalOrders,
      'grossRevenue': grossRevenue,
      'totalDiscount': totalDiscount,
      'totalTax': totalTax,
      'totalItemsSold': totalItemsSold,
      'avgOrderValue': avgOrderValue,
    };
  }

  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 5,
  }) async {
    final db = await _dbHelper.database;
    String whereClause = "t.${TransactionColumns.status} = 'completed'";
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += " AND t.${TransactionColumns.createdAt} >= ?";
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClause += " AND t.${TransactionColumns.createdAt} <= ?";
      whereArgs.add(endDate.toIso8601String());
    }
    whereArgs.add(limit);

    return await db.rawQuery('''
      SELECT 
        ti.${TransactionItemColumns.productId} as product_id,
        ti.${TransactionItemColumns.productName} as name,
        COALESCE(c.${CategoryColumns.name}, 'General') as category,
        COALESCE(SUM(ti.${TransactionItemColumns.quantity}), 0) as sold,
        COALESCE(SUM(ti.${TransactionItemColumns.subtotal}), 0) as revenue
      FROM ${AppTables.transactionItems} ti
      INNER JOIN ${AppTables.transactions} t ON ti.${TransactionItemColumns.transactionId} = t.${TransactionColumns.id}
      LEFT JOIN ${AppTables.products} p ON ti.${TransactionItemColumns.productId} = p.${ProductColumns.id}
      LEFT JOIN ${AppTables.categories} c ON p.${ProductColumns.categoryId} = c.${CategoryColumns.id}
      WHERE $whereClause
      GROUP BY ti.${TransactionItemColumns.productName}
      ORDER BY sold DESC, revenue DESC
      LIMIT ?
    ''', whereArgs);
  }

  Future<List<Map<String, dynamic>>> getSalesChartData({
    required String range,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;
    String whereClause = "${TransactionColumns.status} = 'completed'";
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += " AND ${TransactionColumns.createdAt} >= ?";
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClause += " AND ${TransactionColumns.createdAt} <= ?";
      whereArgs.add(endDate.toIso8601String());
    }

    if (range == 'Today') {
      return await db.rawQuery('''
        SELECT 
          strftime('%H:00', ${TransactionColumns.createdAt}) as label,
          COALESCE(SUM(${TransactionColumns.grandTotal}), 0) as amount
        FROM ${AppTables.transactions}
        WHERE $whereClause
        GROUP BY label
        ORDER BY label ASC
      ''', whereArgs);
    } else {
      return await db.rawQuery('''
        SELECT 
          strftime('%d/%m', ${TransactionColumns.createdAt}) as label,
          COALESCE(SUM(${TransactionColumns.grandTotal}), 0) as amount
        FROM ${AppTables.transactions}
        WHERE $whereClause
        GROUP BY label
        ORDER BY ${TransactionColumns.createdAt} ASC
      ''', whereArgs);
    }
  }
}
