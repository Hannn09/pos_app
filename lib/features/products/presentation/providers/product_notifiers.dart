import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_pos/core/models/pos_models.dart';
import 'package:food_pos/features/products/domain/providers/product_providers.dart';

class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setCategory(String category) => state = category;
}

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String>(SelectedCategoryNotifier.new);

class ProductSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setSearch(String query) => state = query;
}

final productSearchQueryProvider =
    NotifierProvider<ProductSearchQueryNotifier, String>(ProductSearchQueryNotifier.new);

final categoriesProvider = FutureProvider<List<PosCategory>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return await repo.getCategories();
});

final addonsProvider = FutureProvider<List<PosAddon>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return await repo.getAddons();
});

final filteredProductsProvider = FutureProvider<List<PosProduct>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final search = ref.watch(productSearchQueryProvider);

  return await repo.getProducts(categoryId: category, search: search);
});
