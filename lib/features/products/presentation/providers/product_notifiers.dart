import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_pos/core/models/pos_models.dart';
import 'package:food_pos/features/products/domain/providers/product_providers.dart';

// 1. Notifier Kategori Aktif
class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setCategory(String category) => state = category;
}

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String>(SelectedCategoryNotifier.new);

// 2. Notifier Kata Kunci Pencarian Produk
class ProductSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setSearch(String query) => state = query;
}

final productSearchQueryProvider =
    NotifierProvider<ProductSearchQueryNotifier, String>(ProductSearchQueryNotifier.new);

// 3. Provider List Kategori dari Repository
final categoriesProvider = FutureProvider<List<PosCategory>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return await repo.getCategories();
});

// 4. Provider List Addons dari Repository
final addonsProvider = FutureProvider<List<PosAddon>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return await repo.getAddons();
});

// 5. Notifier / Provider List Produk Terfilter
final filteredProductsProvider = FutureProvider<List<PosProduct>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final search = ref.watch(productSearchQueryProvider);

  return await repo.getProducts(categoryId: category, search: search);
});
