import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_pos/core/models/pos_models.dart';
import 'package:food_pos/features/auth/presentation/providers/auth_notifiers.dart';
import 'package:food_pos/features/pos/presentation/providers/pos_cart_notifier.dart';
import 'package:food_pos/features/products/presentation/providers/product_notifiers.dart';
import 'package:food_pos/routers/app_routes.dart';
import 'package:food_pos/theme/app_themes.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PosScreen extends ConsumerStatefulWidget {
  final List<CartItem>? initialCart;
  final Function(List<CartItem>)? onCartUpdated;

  const PosScreen({super.key, this.initialCart, this.onCartUpdated});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _heldBills = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialCart != null && widget.initialCart!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(posCartProvider.notifier).restoreCart(widget.initialCart!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(PosProduct product) {
    if (product.isOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} is currently out of stock'),
          backgroundColor: redColor,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (product.availableAddons.isNotEmpty) {
      _openAddonSelector(product);
    } else {
      ref.read(posCartProvider.notifier).addToCart(product);
      _notifyCartUpdated();
    }
  }

  void _openAddonSelector(PosProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AddonSelectorModal(
          product: product,
          onAddToCart: (selectedAddons, notes, qty) {
            ref.read(posCartProvider.notifier).addToCart(
                  product,
                  addons: selectedAddons,
                  notes: notes,
                  quantity: qty,
                );
            _notifyCartUpdated();
          },
        );
      },
    );
  }

  void _notifyCartUpdated() {
    widget.onCartUpdated?.call(ref.read(posCartProvider));
  }

  void _openCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final cart = ref.watch(posCartProvider);
            final cartSubtotal =
                cart.fold(0.0, (sum, item) => sum + item.totalPrice);
            final totalCartItems =
                cart.fold(0, (sum, item) => sum + item.quantity);

            return _CartBottomSheet(
              cart: cart,
              subtotal: cartSubtotal,
              onQuantityChanged: (item, delta) {
                ref.read(posCartProvider.notifier).updateQuantity(item, delta);
                _notifyCartUpdated();
              },
              onRemoveItem: (item) {
                ref.read(posCartProvider.notifier).removeItem(item);
                _notifyCartUpdated();
              },
              onHoldBill: () {
                if (cart.isEmpty) return;
                setState(() {
                  _heldBills.add({
                    'id': 'HOLD-${_heldBills.length + 1}',
                    'label': 'Order #${_heldBills.length + 1}',
                    'time':
                        '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                    'itemsCount': totalCartItems,
                    'total': cartSubtotal,
                    'items': List<CartItem>.from(cart),
                  });
                });
                ref.read(posCartProvider.notifier).clearCart();
                _notifyCartUpdated();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Order saved to Held Bills'),
                    backgroundColor: primaryColor,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              onCheckout: () {
                Navigator.pop(context);
                context.push(
                  AppRoutes.checkout,
                  extra: {
                    'items': List<CartItem>.from(cart),
                    'subtotal': cartSubtotal,
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _openHeldBillsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Held Orders (${_heldBills.length})',
                    style: boldTextStyle.copyWith(
                      fontSize: 18,
                      color: blackColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: greyColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_heldBills.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No held orders at this time',
                      style: regularTextStyle.copyWith(color: greyColor),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  itemCount: _heldBills.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final bill = _heldBills[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bill['label'] as String,
                                  style: boldTextStyle.copyWith(
                                    fontSize: 15,
                                    color: blackColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${bill['time']} • ${bill['itemsCount']} items • Rp ${formatCurrency(bill['total'] as double)}',
                                  style: regularTextStyle.copyWith(
                                    fontSize: 13,
                                    color: greyColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: whiteColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () {
                              final items = bill['items'] as List<CartItem>;
                              ref
                                  .read(posCartProvider.notifier)
                                  .restoreCart(items);
                              setState(() {
                                _heldBills.removeAt(index);
                              });
                              _notifyCartUpdated();
                              Navigator.pop(context);
                            },
                            child: const Text('Restore'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final displayName = currentUser?.name ?? 'Sarah Jenkins';
    final userRole = currentUser?.role != null && currentUser!.role.isNotEmpty
        ? currentUser.role[0].toUpperCase() + currentUser.role.substring(1)
        : 'Cashier';
    final initials = displayName
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .take(2)
        .join();

    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(filteredProductsProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);
    final searchQuery = ref.watch(productSearchQueryProvider);
    final cart = ref.watch(posCartProvider);
    final totalCartItems = cart.fold(0, (sum, item) => sum + item.quantity);
    final cartSubtotal = cart.fold(0.0, (sum, item) => sum + item.totalPrice);

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(74),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            bottom: 10,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primaryLightColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: initials.isNotEmpty
                      ? Text(
                          initials,
                          style: boldTextStyle.copyWith(
                            fontSize: 15,
                            color: primaryColor,
                          ),
                        )
                      : Icon(
                          IconsaxPlusLinear.user,
                          color: primaryColor,
                          size: 22,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome Back',
                      style: boldTextStyle.copyWith(
                        fontSize: 16,
                        color: blackColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$userRole: $displayName',
                      style: regularTextStyle.copyWith(
                        fontSize: 12,
                        color: greyColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: scaffoldBackgroundColor,
                  padding: const EdgeInsets.all(8),
                ),
                icon: Badge(
                  isLabelVisible: _heldBills.isNotEmpty,
                  label: Text('${_heldBills.length}'),
                  backgroundColor: orangeColor,
                  child: Icon(
                    IconsaxPlusLinear.receipt_text,
                    color: blackColor,
                    size: 20,
                  ),
                ),
                onPressed: _openHeldBillsSheet,
                tooltip: 'Held Orders',
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: whiteColor,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: backgroundTextField,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref
                          .read(productSearchQueryProvider.notifier)
                          .setSearch(val);
                    },
                    style: regularTextStyle.copyWith(
                      fontSize: 14,
                      color: blackColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search menu, drink, food...',
                      hintStyle: hintTextStyle.copyWith(fontSize: 13),
                      prefixIcon: Icon(
                        IconsaxPlusLinear.search_normal,
                        size: 18,
                        color: greyColor,
                      ),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(productSearchQueryProvider.notifier)
                                    .setSearch('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                categoriesAsync.when(
                  loading: () => Skeletonizer(
                    enabled: true,
                    child: SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5,
                        separatorBuilder: (_, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          return ChoiceChip(
                            showCheckmark: false,
                            label: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(IconsaxPlusLinear.category, size: 16),
                                SizedBox(width: 6),
                                Text('Category Name'),
                              ],
                            ),
                            selected: false,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  error: (err, stack) => const SizedBox.shrink(),
                  data: (categories) {
                    return SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = selectedCat == category.id;
                          return ChoiceChip(
                            showCheckmark: false,
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  category.icon,
                                  size: 16,
                                  color: isSelected ? whiteColor : blackColor,
                                ),
                                const SizedBox(width: 6),
                                Text(category.name),
                              ],
                            ),
                            selected: isSelected,
                            labelStyle: semiBoldTextStyle.copyWith(
                              fontSize: 13,
                              color: isSelected ? whiteColor : blackColor,
                            ),
                            selectedColor: primaryColor,
                            backgroundColor: whiteColor,
                            side: BorderSide(
                              color: isSelected ? primaryColor : borderColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            onSelected: (val) {
                              if (val) {
                                ref
                                    .read(selectedCategoryProvider.notifier)
                                    .setCategory(category.id);
                              }
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: productsAsync.when(
              loading: () => Skeletonizer(
                enabled: true,
                child: GridView.builder(
                  padding: const EdgeInsets.all(14),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.84,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    return _ProductGridCard(
                      product: const PosProduct(
                        id: 'dummy',
                        name: 'Artisan Signature Item',
                        categoryId: 'all',
                        price: 36000,
                        stock: 20,
                        icon: IconsaxPlusLinear.coffee,
                      ),
                      onTap: () {},
                    );
                  },
                ),
              ),
              error: (err, _) => Center(
                child: Text('Error loading products: $err'),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          IconsaxPlusLinear.box_search,
                          size: 54,
                          color: lightGreyColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No products found',
                          style: boldTextStyle.copyWith(
                            fontSize: 16,
                            color: blackColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try searching with another keyword or category',
                          style: regularTextStyle.copyWith(
                            fontSize: 13,
                            color: greyColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(14),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.84,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _ProductGridCard(
                      product: product,
                      onTap: () => _addToCart(product),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: cart.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: whiteColor,
                border: Border(top: BorderSide(color: borderColor)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _openCartSheet,
                      child: Row(
                        children: [
                          Badge(
                            label: Text('$totalCartItems'),
                            backgroundColor: primaryColor,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: primaryLightColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                IconsaxPlusLinear.shopping_bag,
                                color: primaryColor,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$totalCartItems Items',
                                style: regularTextStyle.copyWith(
                                  fontSize: 12,
                                  color: greyColor,
                                ),
                              ),
                              Text(
                                'Rp ${formatCurrency(cartSubtotal)}',
                                style: boldTextStyle.copyWith(
                                  fontSize: 16,
                                  color: blackColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: primaryButtonStyle.copyWith(
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      onPressed: _openCartSheet,
                      child: Row(
                        children: [
                          Text(
                            'View Cart',
                            style: boldTextStyle.copyWith(
                              fontSize: 14,
                              color: whiteColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: whiteColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final PosProduct product;
  final VoidCallback onTap;

  const _ProductGridCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOut = product.isOutOfStock;
    final isLow = product.isLowStock;

    return Opacity(
      opacity: isOut ? 0.6 : 1.0,
      child: Material(
        color: whiteColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isOut ? null : onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: primaryLightColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: product.imagePath != null &&
                                  File(product.imagePath!).existsSync()
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(product.imagePath!),
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  product.icon,
                                  size: 44,
                                  color: primaryColor,
                                ),
                        ),
                      ),
                      if (isOut)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: redColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Out of Stock',
                              style: boldTextStyle.copyWith(
                                fontSize: 10,
                                color: whiteColor,
                              ),
                            ),
                          ),
                        )
                      else if (isLow)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: orangeColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Low: ${product.stock} left',
                              style: boldTextStyle.copyWith(
                                fontSize: 10,
                                color: whiteColor,
                              ),
                            ),
                          ),
                        )
                      else
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: whiteColor.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Stock: ${product.stock}',
                              style: mediumTextStyle.copyWith(
                                fontSize: 10,
                                color: greyColor,
                              ),
                            ),
                          ),
                        ),
                      if (product.availableAddons.isNotEmpty && !isOut)
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: whiteColor,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              '+ Add-ons',
                              style: boldTextStyle.copyWith(
                                fontSize: 9,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: boldTextStyle.copyWith(
                    fontSize: 14,
                    color: blackColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rp ${formatCurrency(product.price)}',
                      style: semiBoldTextStyle.copyWith(
                        fontSize: 13,
                        color: primaryColor,
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isOut ? lightGreyColor : primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddonSelectorModal extends StatefulWidget {
  final PosProduct product;
  final Function(List<PosAddon> selectedAddons, String? notes, int quantity)
  onAddToCart;

  const _AddonSelectorModal({required this.product, required this.onAddToCart});

  @override
  State<_AddonSelectorModal> createState() => _AddonSelectorModalState();
}

class _AddonSelectorModalState extends State<_AddonSelectorModal> {
  final List<PosAddon> _selectedAddons = [];
  int _quantity = 1;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _unitPrice {
    double addonsTotal = _selectedAddons.fold(
      0,
      (sum, addon) => sum + addon.price,
    );
    return widget.product.price + addonsTotal;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: boldTextStyle.copyWith(
                          fontSize: 18,
                          color: blackColor,
                        ),
                      ),
                      Text(
                        'Base price: Rp ${formatCurrency(widget.product.price)}',
                        style: regularTextStyle.copyWith(
                          fontSize: 13,
                          color: greyColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: greyColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Select Toppings & Add-ons',
              style: boldTextStyle.copyWith(fontSize: 14, color: blackColor),
            ),
            const SizedBox(height: 8),
            ...widget.product.availableAddons.map((addon) {
              final isSelected = _selectedAddons.any(
                (item) => item.id == addon.id,
              );
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryLightColor
                      : scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? primaryColor : borderColor,
                  ),
                ),
                child: CheckboxListTile(
                  dense: true,
                  activeColor: primaryColor,
                  title: Text(
                    addon.name,
                    style: semiBoldTextStyle.copyWith(
                      fontSize: 14,
                      color: blackColor,
                    ),
                  ),
                  subtitle: Text(
                    addon.price > 0
                        ? '+Rp ${formatCurrency(addon.price)}'
                        : 'Free',
                    style: regularTextStyle.copyWith(
                      fontSize: 12,
                      color: addon.price > 0 ? primaryColor : greyColor,
                    ),
                  ),
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedAddons.add(addon);
                      } else {
                        _selectedAddons.removeWhere(
                          (item) => item.id == addon.id,
                        );
                      }
                    });
                  },
                ),
              );
            }),
            const SizedBox(height: 12),
            Text(
              'Special Instructions / Notes',
              style: boldTextStyle.copyWith(fontSize: 14, color: blackColor),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: textFieldDecoration.copyWith(
                hintText: 'e.g. Extra hot, separate lid, ice on side',
                hintStyle: hintTextStyle,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: _quantity > 1
                            ? () {
                                setState(() {
                                  _quantity -= 1;
                                });
                              }
                            : null,
                      ),
                      Text(
                        '$_quantity',
                        style: boldTextStyle.copyWith(fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () {
                          setState(() {
                            _quantity += 1;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    style: primaryButtonStyle,
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onAddToCart(
                        _selectedAddons,
                        _notesController.text.trim().isEmpty
                            ? null
                            : _notesController.text.trim(),
                        _quantity,
                      );
                    },
                    child: Text(
                      'Add • Rp ${formatCurrency(_unitPrice * _quantity)}',
                      style: boldTextStyle.copyWith(color: whiteColor),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartBottomSheet extends StatefulWidget {
  final List<CartItem> cart;
  final double subtotal;
  final Function(CartItem, int delta) onQuantityChanged;
  final Function(CartItem) onRemoveItem;
  final VoidCallback onHoldBill;
  final VoidCallback onCheckout;

  const _CartBottomSheet({
    required this.cart,
    required this.subtotal,
    required this.onQuantityChanged,
    required this.onRemoveItem,
    required this.onHoldBill,
    required this.onCheckout,
  });

  @override
  State<_CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<_CartBottomSheet> {
  double _discountRate = 0.0;
  String _selectedDiscount = 'None';

  @override
  Widget build(BuildContext context) {
    final discountAmount = widget.subtotal * _discountRate;
    final taxable = widget.subtotal - discountAmount;
    final taxAmount = taxable * 0.10;
    final grandTotal = taxable + taxAmount;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Order',
                      style: boldTextStyle.copyWith(
                        fontSize: 18,
                        color: blackColor,
                      ),
                    ),
                    Text(
                      '${widget.cart.length} distinct items',
                      style: regularTextStyle.copyWith(
                        fontSize: 13,
                        color: greyColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton.icon(
                      icon: Icon(
                        IconsaxPlusLinear.pause,
                        size: 16,
                        color: orangeColor,
                      ),
                      label: Text(
                        'Hold Bill',
                        style: semiBoldTextStyle.copyWith(
                          fontSize: 13,
                          color: orangeColor,
                        ),
                      ),
                      onPressed: widget.onHoldBill,
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: greyColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: widget.cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          IconsaxPlusLinear.shopping_cart,
                          size: 54,
                          color: lightGreyColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your cart is empty',
                          style: boldTextStyle.copyWith(
                            fontSize: 16,
                            color: blackColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap items from the menu to add to this order',
                          style: regularTextStyle.copyWith(
                            fontSize: 13,
                            color: greyColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    itemCount: widget.cart.length,
                    separatorBuilder: (_, index) => const Divider(height: 20),
                    itemBuilder: (context, index) {
                      final item = widget.cart[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: boldTextStyle.copyWith(
                                    fontSize: 14,
                                    color: blackColor,
                                  ),
                                ),
                                if (item.selectedAddons.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      item.selectedAddons
                                          .map((a) => a.name)
                                          .join(', '),
                                      style: regularTextStyle.copyWith(
                                        fontSize: 11,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                if (item.notes != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'Note: "${item.notes}"',
                                      style: regularTextStyle.copyWith(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: greyColor,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  'Rp ${formatCurrency(item.totalPrice)}',
                                  style: semiBoldTextStyle.copyWith(
                                    fontSize: 13,
                                    color: blackColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () =>
                                      widget.onQuantityChanged(item, -1),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Icon(Icons.remove, size: 16),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: Text(
                                    '${item.quantity}',
                                    style: boldTextStyle.copyWith(fontSize: 13),
                                  ),
                                ),
                                InkWell(
                                  onTap: () =>
                                      widget.onQuantityChanged(item, 1),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Icon(Icons.add, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: BoxDecoration(
              color: whiteColor,
              border: Border(top: BorderSide(color: borderColor)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  offset: const Offset(0, -3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Discount:',
                        style: semiBoldTextStyle.copyWith(
                          fontSize: 12,
                          color: greyColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...['None', '5%', '10%'].map((d) {
                        final isSel = _selectedDiscount == d;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedDiscount = d;
                                if (d == '5%') {
                                  _discountRate = 0.05;
                                } else if (d == '10%') {
                                  _discountRate = 0.10;
                                } else {
                                  _discountRate = 0.0;
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? primaryColor
                                    : scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSel ? primaryColor : borderColor,
                                ),
                              ),
                              child: Text(
                                d,
                                style: semiBoldTextStyle.copyWith(
                                  fontSize: 11,
                                  color: isSel ? whiteColor : blackColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _calcRow('Subtotal', 'Rp ${formatCurrency(widget.subtotal)}'),
                  if (discountAmount > 0)
                    _calcRow(
                      'Discount ($_selectedDiscount)',
                      '-Rp ${formatCurrency(discountAmount)}',
                      valueColor: redColor,
                    ),
                  _calcRow('Tax (PB1 10%)', 'Rp ${formatCurrency(taxAmount)}'),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Payment',
                        style: boldTextStyle.copyWith(
                          fontSize: 16,
                          color: blackColor,
                        ),
                      ),
                      Text(
                        'Rp ${formatCurrency(grandTotal)}',
                        style: boldTextStyle.copyWith(
                          fontSize: 18,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: primaryButtonStyle,
                      onPressed: widget.cart.isEmpty ? null : widget.onCheckout,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            IconsaxPlusLinear.card_pos,
                            color: whiteColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Proceed to Checkout',
                            style: boldTextStyle.copyWith(
                              fontSize: 15,
                              color: whiteColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _calcRow(String title, String val, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: regularTextStyle.copyWith(fontSize: 13, color: greyColor),
          ),
          Text(
            val,
            style: mediumTextStyle.copyWith(
              fontSize: 13,
              color: valueColor ?? blackColor,
            ),
          ),
        ],
      ),
    );
  }
}

String formatCurrency(double amount) {
  final int val = amount.round();
  final str = val.toString();
  final buffer = StringBuffer();
  int count = 0;
  for (int i = str.length - 1; i >= 0; i--) {
    buffer.write(str[i]);
    count++;
    if (count % 3 == 0 && i != 0) {
      buffer.write('.');
    }
  }
  return buffer.toString().split('').reversed.join('');
}
