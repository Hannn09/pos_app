import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_pos/core/models/pos_models.dart';
import 'package:food_pos/features/pos/presentation/screens/pos_screen.dart';
import 'package:food_pos/features/products/domain/providers/product_providers.dart';
import 'package:food_pos/features/products/presentation/providers/product_notifiers.dart';
import 'package:food_pos/routers/app_routes.dart';
import 'package:food_pos/theme/app_themes.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ProductManagementScreen extends ConsumerStatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  ConsumerState<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState
    extends ConsumerState<ProductManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<PosProduct> _products = [];
  List<PosCategory> _categories = [];
  List<PosAddon> _addons = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(productRepositoryProvider);
      final products = await repo.getProducts();
      final allCats = await repo.getCategories();
      final addons = await repo.getAddons();

      if (mounted) {
        setState(() {
          _products = products;
          _categories = allCats.where((c) => c.id != 'all').toList();
          _addons = addons;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<PosProduct> get _filteredProducts {
    if (_isLoading && _products.isEmpty) {
      return List.generate(
        6,
        (i) => const PosProduct(
          id: 'dummy',
          name: 'Signature Coffee Blend',
          categoryId: 'all',
          price: 36000,
          stock: 25,
          icon: IconsaxPlusLinear.coffee,
        ),
      );
    }
    return _products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(
            _searchQuery.toLowerCase().trim(),
          );
      final matchesCat =
          _selectedCategory == 'all' || p.categoryId == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();
  }

  List<PosCategory> get _displayCategories {
    if (_isLoading && _categories.isEmpty) {
      return List.generate(
        5,
        (i) => const PosCategory(
          id: 'dummy',
          name: 'Category Name',
          icon: IconsaxPlusLinear.category,
          itemCount: 8,
        ),
      );
    }
    return _categories;
  }

  List<PosAddon> get _displayAddons {
    if (_isLoading && _addons.isEmpty) {
      return List.generate(
        5,
        (i) => PosAddon(
          id: 'dummy',
          name: 'Add-on Modifier',
          price: 6000,
          stock: 50,
        ),
      );
    }
    return _addons;
  }

  Future<void> _navigateAddEditProduct([PosProduct? product]) async {
    final result = await context.push(
      AppRoutes.addEditProduct,
      extra: product,
    );
    if (result != null && result is PosProduct) {
      final repo = ref.read(productRepositoryProvider);
      await repo.saveProduct(result);
      ref.invalidate(categoriesProvider);
      ref.invalidate(filteredProductsProvider);
      await _loadData();
    }
  }

  void _deleteProduct(PosProduct product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Product?',
            style: boldTextStyle.copyWith(fontSize: 18, color: blackColor),
          ),
          content: Text(
            'Are you sure you want to remove "${product.name}" from your catalog?',
            style: regularTextStyle.copyWith(fontSize: 14, color: greyColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: semiBoldTextStyle.copyWith(color: greyColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: redColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                final repo = ref.read(productRepositoryProvider);
                await repo.deleteProduct(product.id);
                ref.invalidate(categoriesProvider);
                ref.invalidate(filteredProductsProvider);
                await _loadData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Product "${product.name}" deleted'),
                      backgroundColor: redColor,
                    ),
                  );
                }
              },
              child: Text(
                'Delete',
                style: boldTextStyle.copyWith(color: whiteColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddCategoryDialog([PosCategory? categoryToEdit]) {
    final nameCtrl = TextEditingController(text: categoryToEdit?.name ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            categoryToEdit == null ? 'Add New Category' : 'Edit Category',
            style: boldTextStyle.copyWith(fontSize: 18, color: blackColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: textFieldDecoration.copyWith(
                  hintText: 'Category Name (e.g. Desserts)',
                  hintStyle: hintTextStyle,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: semiBoldTextStyle.copyWith(color: greyColor),
              ),
            ),
            ElevatedButton(
              style: primaryButtonStyle.copyWith(
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              onPressed: () async {
                if (nameCtrl.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  final repo = ref.read(productRepositoryProvider);
                  final cat = PosCategory(
                    id: categoryToEdit?.id ??
                        'cat_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    icon: categoryToEdit?.icon ?? IconsaxPlusLinear.category,
                    itemCount: categoryToEdit?.itemCount ?? 0,
                  );
                  await repo.saveCategory(cat);
                  ref.invalidate(categoriesProvider);
                  ref.invalidate(filteredProductsProvider);
                  await _loadData();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(PosCategory cat) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Category?',
            style: boldTextStyle.copyWith(fontSize: 18, color: blackColor),
          ),
          content: Text(
            'Are you sure you want to delete category "${cat.name}"?',
            style: regularTextStyle.copyWith(fontSize: 14, color: greyColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: semiBoldTextStyle.copyWith(color: greyColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: redColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                final repo = ref.read(productRepositoryProvider);
                await repo.deleteCategory(cat.id);
                ref.invalidate(categoriesProvider);
                ref.invalidate(filteredProductsProvider);
                await _loadData();
              },
              child: Text(
                'Delete',
                style: boldTextStyle.copyWith(color: whiteColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddAddonDialog([PosAddon? addonToEdit]) {
    final nameCtrl = TextEditingController(text: addonToEdit?.name ?? '');
    final priceCtrl = TextEditingController(
      text: addonToEdit != null ? addonToEdit.price.round().toString() : '',
    );
    final stockCtrl = TextEditingController(
      text: addonToEdit != null ? addonToEdit.stock.toString() : '100',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            addonToEdit == null ? 'Add New Topping / Add-on' : 'Edit Add-on',
            style: boldTextStyle.copyWith(fontSize: 18, color: blackColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: textFieldDecoration.copyWith(
                  hintText: 'Add-on Name (e.g. Oat Milk)',
                  hintStyle: hintTextStyle,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: textFieldDecoration.copyWith(
                  hintText: 'Additional Price (e.g. 8000)',
                  hintStyle: hintTextStyle,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                decoration: textFieldDecoration.copyWith(
                  hintText: 'Stock Quantity',
                  hintStyle: hintTextStyle,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: semiBoldTextStyle.copyWith(color: greyColor),
              ),
            ),
            ElevatedButton(
              style: primaryButtonStyle.copyWith(
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              onPressed: () async {
                if (nameCtrl.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  final price = double.tryParse(priceCtrl.text) ?? 0;
                  final stock = int.tryParse(stockCtrl.text) ?? 100;
                  final repo = ref.read(productRepositoryProvider);
                  final addon = PosAddon(
                    id: addonToEdit?.id ??
                        'ad_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    price: price,
                    stock: stock,
                  );
                  await repo.saveAddon(addon);
                  ref.invalidate(addonsProvider);
                  ref.invalidate(filteredProductsProvider);
                  await _loadData();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAddon(PosAddon addon) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Add-on?',
            style: boldTextStyle.copyWith(fontSize: 18, color: blackColor),
          ),
          content: Text(
            'Are you sure you want to delete add-on "${addon.name}"?',
            style: regularTextStyle.copyWith(fontSize: 14, color: greyColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: semiBoldTextStyle.copyWith(color: greyColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: redColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                final repo = ref.read(productRepositoryProvider);
                await repo.deleteAddon(addon.id);
                ref.invalidate(addonsProvider);
                ref.invalidate(filteredProductsProvider);
                await _loadData();
              },
              child: Text(
                'Delete',
                style: boldTextStyle.copyWith(color: whiteColor),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: whiteColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Product Management',
          style: boldTextStyle.copyWith(fontSize: 18, color: blackColor),
        ),
        actions: [
          IconButton(
            icon: Icon(IconsaxPlusLinear.add_circle, color: primaryColor),
            onPressed: () async {
              if (_tabController.index == 0) {
                await _navigateAddEditProduct();
              } else if (_tabController.index == 1) {
                _showAddCategoryDialog();
              } else {
                _showAddAddonDialog();
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: greyColor,
          indicatorColor: primaryColor,
          indicatorWeight: 3,
          labelStyle: boldTextStyle.copyWith(fontSize: 14),
          unselectedLabelStyle: mediumTextStyle.copyWith(fontSize: 14),
          tabs: const [
            Tab(text: 'Products'),
            Tab(text: 'Categories'),
            Tab(text: 'Add-ons / Toppings'),
          ],
        ),
      ),
      body: Skeletonizer(
        enabled: _isLoading,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildProductsTab(),
            _buildCategoriesTab(),
            _buildAddonsTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        foregroundColor: whiteColor,
        icon: const Icon(Icons.add),
        label: Text(
          _tabController.index == 0
              ? 'New Product'
              : _tabController.index == 1
                  ? 'New Category'
                  : 'New Add-on',
          style: boldTextStyle.copyWith(color: whiteColor),
        ),
        onPressed: () async {
          if (_tabController.index == 0) {
            await _navigateAddEditProduct();
          } else if (_tabController.index == 1) {
            _showAddCategoryDialog();
          } else {
            _showAddAddonDialog();
          }
        },
      ),
    );
  }

  Widget _buildProductsTab() {
    final allCategoryFilters = [
      const PosCategory(
        id: 'all',
        name: 'All Menu',
        icon: IconsaxPlusLinear.category,
      ),
      ..._categories,
    ];

    return Column(
      children: [
        // Search & Category Filter
        Container(
          color: whiteColor,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: textFieldDecoration.copyWith(
                  hintText: 'Search products by name or SKU...',
                  hintStyle: hintTextStyle,
                  prefixIcon: Icon(
                    IconsaxPlusLinear.search_normal_1,
                    color: greyColor,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: allCategoryFilters.map((c) {
                    final isSel = _selectedCategory == c.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        showCheckmark: false,
                        label: Text(c.name),
                        selected: isSel,
                        selectedColor: primaryLightColor,
                        backgroundColor: scaffoldBackgroundColor,
                        labelStyle: semiBoldTextStyle.copyWith(
                          fontSize: 12,
                          color: isSel ? primaryColor : blackColor,
                        ),
                        side: BorderSide(
                          color: isSel ? primaryColor : borderColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onSelected: (val) {
                          setState(() {
                            _selectedCategory = c.id;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Product List
        Expanded(
          child: _filteredProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        IconsaxPlusLinear.box_search,
                        size: 48,
                        color: lightGreyColor,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No products match your filter',
                        style: boldTextStyle.copyWith(
                          fontSize: 15,
                          color: blackColor,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _filteredProducts.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: primaryLightColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: product.imagePath != null &&
                                    File(product.imagePath!).existsSync()
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      File(product.imagePath!),
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(
                                    product.icon,
                                    color: primaryColor,
                                    size: 26,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: boldTextStyle.copyWith(
                                    fontSize: 15,
                                    color: blackColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Rp ${formatCurrency(product.price)} • Stock: ${product.stock}',
                                  style: regularTextStyle.copyWith(
                                    fontSize: 12,
                                    color: product.isOutOfStock
                                        ? redColor
                                        : (product.isLowStock
                                            ? Colors.amber.shade800
                                            : greyColor),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: product.isAvailable
                                            ? primaryLightColor
                                            : redColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        product.isAvailable
                                            ? 'Available'
                                            : 'Unavailable',
                                        style: semiBoldTextStyle.copyWith(
                                          fontSize: 10,
                                          color: product.isAvailable
                                              ? primaryColor
                                              : redColor,
                                        ),
                                      ),
                                    ),
                                    if (product.availableAddons.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '${product.availableAddons.length} add-ons',
                                        style: regularTextStyle.copyWith(
                                          fontSize: 11,
                                          color: greyColor,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              IconsaxPlusLinear.edit,
                              size: 18,
                              color: greyColor,
                            ),
                            onPressed: () => _navigateAddEditProduct(product),
                          ),
                          IconButton(
                            icon: Icon(
                              IconsaxPlusLinear.trash,
                              size: 18,
                              color: redColor,
                            ),
                            onPressed: () => _deleteProduct(product),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoriesTab() {
    final list = _displayCategories;
    return list.isEmpty
        ? Center(
            child: Text(
              'No categories found',
              style: regularTextStyle.copyWith(color: greyColor),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: list.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final cat = list[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primaryLightColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(cat.icon, color: primaryColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.name,
                            style: boldTextStyle.copyWith(
                              fontSize: 15,
                              color: blackColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${cat.id} • ${cat.itemCount} menu items',
                            style: regularTextStyle.copyWith(
                              fontSize: 12,
                              color: greyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        IconsaxPlusLinear.edit,
                        size: 18,
                        color: greyColor,
                      ),
                      onPressed: () => _showAddCategoryDialog(cat),
                    ),
                    IconButton(
                      icon: Icon(
                        IconsaxPlusLinear.trash,
                        size: 18,
                        color: redColor,
                      ),
                      onPressed: () => _deleteCategory(cat),
                    ),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildAddonsTab() {
    final list = _displayAddons;
    return list.isEmpty
        ? Center(
            child: Text(
              'No add-ons found',
              style: regularTextStyle.copyWith(color: greyColor),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: list.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final addon = list[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primaryLightColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        IconsaxPlusLinear.add_circle,
                        color: primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            addon.name,
                            style: boldTextStyle.copyWith(
                              fontSize: 15,
                              color: blackColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            addon.price > 0
                                ? '+Rp ${formatCurrency(addon.price)} • Stock: ${addon.stock}'
                                : 'Free Modifier • Stock: ${addon.stock}',
                            style: regularTextStyle.copyWith(
                              fontSize: 12,
                              color: addon.price > 0 ? primaryColor : greyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        IconsaxPlusLinear.edit,
                        size: 18,
                        color: greyColor,
                      ),
                      onPressed: () => _showAddAddonDialog(addon),
                    ),
                    IconButton(
                      icon: Icon(
                        IconsaxPlusLinear.trash,
                        size: 18,
                        color: redColor,
                      ),
                      onPressed: () => _deleteAddon(addon),
                    ),
                  ],
                ),
              );
            },
          );
  }
}
