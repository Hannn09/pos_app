import 'package:flutter/material.dart';
import 'package:food_pos/core/data/local/tables.dart';
import 'package:food_pos/core/models/pos_models.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:sqflite/sqflite.dart';

class InitialDataSeeder {
  static Future<void> seedAll(Database db) async {
    final batch = db.batch();

    batch.insert(
      AppTables.storeSettings,
      {
        StoreSettingColumns.id: 'store_1',
        StoreSettingColumns.storeName: 'Aroma Artisan Cafe & Eatery',
        StoreSettingColumns.address: 'Jl. Senopati Raya No. 42, Jakarta Selatan',
        StoreSettingColumns.phone: '+62 812-3456-7890',
        StoreSettingColumns.receiptHeader: 'Thank you for dining with us!',
        StoreSettingColumns.receiptFooter: 'Follow our Instagram @aroma.cafe',
        StoreSettingColumns.taxRate: 10.0,
        StoreSettingColumns.serviceRate: 0.0,
        StoreSettingColumns.currencyCode: 'IDR',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    batch.insert(
      AppTables.users,
      {
        UserColumns.id: 'user_1',
        UserColumns.username: 'admin',
        UserColumns.name: 'Store Manager',
        UserColumns.role: 'admin',
        UserColumns.pinHash: '1234',
        UserColumns.isActive: 1,
        UserColumns.createdAt: DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    batch.insert(
      AppTables.users,
      {
        UserColumns.id: 'user_2',
        UserColumns.username: 'sarah',
        UserColumns.name: 'Sarah Jenkins',
        UserColumns.role: 'cashier',
        UserColumns.pinHash: '1234',
        UserColumns.isActive: 1,
        UserColumns.createdAt: DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    for (int i = 0; i < mockCategories.length; i++) {
      final cat = mockCategories[i];
      if (cat.id == 'all') continue;

      batch.insert(
        AppTables.categories,
        {
          CategoryColumns.id: cat.id,
          CategoryColumns.name: cat.name,
          CategoryColumns.iconName: _getIconName(cat.icon),
          CategoryColumns.sortOrder: i,
          CategoryColumns.isActive: 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    for (final addon in mockAddons) {
      batch.insert(
        AppTables.addons,
        {
          AddonColumns.id: addon.id,
          AddonColumns.name: addon.name,
          AddonColumns.price: addon.price,
          AddonColumns.stock: addon.stock,
          AddonColumns.trackStock: 1,
          AddonColumns.isActive: 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    for (final product in mockProducts) {
      batch.insert(
        AppTables.products,
        {
          ProductColumns.id: product.id,
          ProductColumns.categoryId: product.categoryId,
          ProductColumns.sku: 'SKU-${product.id.toUpperCase()}',
          ProductColumns.name: product.name,
          ProductColumns.price: product.price,
          ProductColumns.costPrice: product.costPrice ?? 0,
          ProductColumns.stock: product.stock,
          ProductColumns.trackStock: 1,
          ProductColumns.iconName: _getIconName(product.icon),
          ProductColumns.imagePath: null,
          ProductColumns.isAvailable: product.isAvailable ? 1 : 0,
          ProductColumns.createdAt: DateTime.now().toIso8601String(),
          ProductColumns.updatedAt: DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final addon in product.availableAddons) {
        batch.insert(
          AppTables.productAddons,
          {
            ProductAddonColumns.productId: product.id,
            ProductAddonColumns.addonId: addon.id,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    await batch.commit(noResult: true);

    for (final tx in mockTransactions) {
      await _seedTransaction(db, tx);
    }
  }

  static Future<void> _seedTransaction(Database db, PosTransaction tx) async {
    await db.insert(
      AppTables.transactions,
      {
        TransactionColumns.id: tx.id,
        TransactionColumns.receiptNo: tx.receiptNo,
        TransactionColumns.cashierId: 'user_2',
        TransactionColumns.cashierName: tx.cashierName,
        TransactionColumns.tableNo: tx.tableNo,
        TransactionColumns.customerName: 'Guest',
        TransactionColumns.subtotal: tx.subtotal,
        TransactionColumns.discountType: 'fixed',
        TransactionColumns.discountRate: 0,
        TransactionColumns.discountAmount: tx.discountAmount,
        TransactionColumns.taxRate: 10.0,
        TransactionColumns.taxAmount: tx.taxAmount,
        TransactionColumns.serviceRate: 0,
        TransactionColumns.serviceAmount: 0,
        TransactionColumns.grandTotal: tx.grandTotal,
        TransactionColumns.paymentMethod: tx.paymentMethod,
        TransactionColumns.cashReceived: tx.cashReceived,
        TransactionColumns.changeGiven: tx.changeGiven,
        TransactionColumns.status: 'completed',
        TransactionColumns.notes: null,
        TransactionColumns.createdAt: tx.dateTime.toIso8601String(),
        TransactionColumns.updatedAt: tx.dateTime.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    int itemIndex = 0;
    for (final item in tx.items) {
      itemIndex++;
      final itemId = '${tx.id}_item_$itemIndex';

      await db.insert(
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

      int addonIndex = 0;
      for (final addon in item.selectedAddons) {
        addonIndex++;
        final itemAddonId = '${itemId}_addon_$addonIndex';

        await db.insert(
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
      }
    }
  }

  static String _getIconName(IconData icon) {
    if (icon == IconsaxPlusLinear.coffee) return 'coffee';
    if (icon == IconsaxPlusLinear.glass) return 'glass';
    if (icon == IconsaxPlusLinear.reserve) return 'reserve';
    if (icon == IconsaxPlusLinear.cake) return 'cake';
    return 'category';
  }

  static IconData getIconDataByName(String? name) {
    switch (name) {
      case 'coffee':
        return IconsaxPlusLinear.coffee;
      case 'glass':
        return IconsaxPlusLinear.glass;
      case 'reserve':
        return IconsaxPlusLinear.reserve;
      case 'cake':
        return IconsaxPlusLinear.cake;
      default:
        return IconsaxPlusLinear.category;
    }
  }
}
