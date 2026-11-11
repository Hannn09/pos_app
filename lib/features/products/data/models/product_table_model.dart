import 'package:food_pos/core/data/local/initial_data_seeder.dart';
import 'package:food_pos/core/data/local/tables.dart';
import 'package:food_pos/core/models/pos_models.dart';

class CategoryTableModel {
  static PosCategory fromMap(Map<String, dynamic> map, {int itemCount = 0}) {
    return PosCategory(
      id: map[CategoryColumns.id] as String,
      name: map[CategoryColumns.name] as String,
      icon: InitialDataSeeder.getIconDataByName(map[CategoryColumns.iconName] as String?),
      itemCount: itemCount,
    );
  }

  static Map<String, dynamic> toMap(PosCategory category) {
    return {
      CategoryColumns.id: category.id,
      CategoryColumns.name: category.name,
      CategoryColumns.iconName: category.icon.codePoint.toString(),
      CategoryColumns.sortOrder: 0,
      CategoryColumns.isActive: 1,
    };
  }
}

class AddonTableModel {
  static PosAddon fromMap(Map<String, dynamic> map) {
    return PosAddon(
      id: map[AddonColumns.id] as String,
      name: map[AddonColumns.name] as String,
      price: (map[AddonColumns.price] as num).toDouble(),
      stock: (map[AddonColumns.stock] as int?) ?? 0,
      isSelected: false,
    );
  }

  static Map<String, dynamic> toMap(PosAddon addon) {
    return {
      AddonColumns.id: addon.id,
      AddonColumns.name: addon.name,
      AddonColumns.price: addon.price,
      AddonColumns.stock: addon.stock,
      AddonColumns.trackStock: 1,
      AddonColumns.isActive: 1,
    };
  }
}

class ProductTableModel {
  static PosProduct fromMap(
    Map<String, dynamic> map, {
    List<PosAddon> addons = const [],
  }) {
    final isAvailable = (map[ProductColumns.isAvailable] as int?) == 1;

    return PosProduct(
      id: map[ProductColumns.id] as String,
      name: map[ProductColumns.name] as String,
      categoryId: map[ProductColumns.categoryId] as String,
      price: (map[ProductColumns.price] as num).toDouble(),
      costPrice: map[ProductColumns.costPrice] != null
          ? (map[ProductColumns.costPrice] as num).toDouble()
          : null,
      stock: (map[ProductColumns.stock] as int?) ?? 0,
      icon: InitialDataSeeder.getIconDataByName(map[ProductColumns.iconName] as String?),
      isAvailable: isAvailable,
      availableAddons: addons,
      imagePath: map[ProductColumns.imagePath] as String?,
    );
  }

  static Map<String, dynamic> toMap(PosProduct product) {
    return {
      ProductColumns.id: product.id,
      ProductColumns.categoryId: product.categoryId,
      ProductColumns.sku: 'SKU-${product.id.toUpperCase()}',
      ProductColumns.name: product.name,
      ProductColumns.price: product.price,
      ProductColumns.costPrice: product.costPrice ?? 0,
      ProductColumns.stock: product.stock,
      ProductColumns.trackStock: 1,
      ProductColumns.iconName: product.icon.codePoint.toString(),
      ProductColumns.imagePath: product.imagePath,
      ProductColumns.isAvailable: product.isAvailable ? 1 : 0,
      ProductColumns.updatedAt: DateTime.now().toIso8601String(),
    };
  }
}
