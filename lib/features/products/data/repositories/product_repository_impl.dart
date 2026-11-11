import 'package:food_pos/core/models/pos_models.dart';
import 'package:food_pos/features/products/data/datasource/product_local_datasource.dart';
import 'package:food_pos/features/products/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductLocalDataSource _localDataSource;

  ProductRepositoryImpl({ProductLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? ProductLocalDataSource();

  @override
  Future<List<PosCategory>> getCategories() => _localDataSource.getCategories();

  @override
  Future<List<PosAddon>> getAddons() => _localDataSource.getAddons();

  @override
  Future<List<PosProduct>> getProducts({String? categoryId, String? search}) =>
      _localDataSource.getProducts(categoryId: categoryId, search: search);

  @override
  Future<PosProduct?> getProductById(String id) =>
      _localDataSource.getProductById(id);

  @override
  Future<void> saveProduct(PosProduct product) =>
      _localDataSource.saveProduct(product);

  @override
  Future<void> deleteProduct(String id) =>
      _localDataSource.deleteProduct(id);

  @override
  Future<void> saveCategory(PosCategory category) =>
      _localDataSource.saveCategory(category);

  @override
  Future<void> deleteCategory(String id) =>
      _localDataSource.deleteCategory(id);

  @override
  Future<void> saveAddon(PosAddon addon) =>
      _localDataSource.saveAddon(addon);

  @override
  Future<void> deleteAddon(String id) =>
      _localDataSource.deleteAddon(id);
}
