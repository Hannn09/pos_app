import 'package:food_pos/core/models/pos_models.dart';

abstract class ProductRepository {
  Future<List<PosCategory>> getCategories();
  Future<List<PosAddon>> getAddons();
  Future<List<PosProduct>> getProducts({String? categoryId, String? search});
  Future<PosProduct?> getProductById(String id);
  Future<void> saveProduct(PosProduct product);
  Future<void> deleteProduct(String id);
  Future<void> saveCategory(PosCategory category);
  Future<void> deleteCategory(String id);
  Future<void> saveAddon(PosAddon addon);
  Future<void> deleteAddon(String id);
}
