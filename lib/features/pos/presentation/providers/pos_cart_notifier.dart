import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_pos/core/models/pos_models.dart';

class PosCartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addToCart(
    PosProduct product, {
    List<PosAddon>? addons,
    String? notes,
    int quantity = 1,
  }) {
    final selectedAddons = addons ?? [];
    final currentList = List<CartItem>.from(state);

    final existingIndex = currentList.indexWhere((item) {
      if (item.product.id != product.id) return false;
      if (item.notes != notes) return false;
      if (item.selectedAddons.length != selectedAddons.length) return false;
      for (int i = 0; i < selectedAddons.length; i++) {
        if (!item.selectedAddons.any((a) => a.id == selectedAddons[i].id)) {
          return false;
        }
      }
      return true;
    });

    if (existingIndex >= 0) {
      currentList[existingIndex].quantity += quantity;
      state = [...currentList];
    } else {
      state = [
        ...currentList,
        CartItem(
          product: product,
          quantity: quantity,
          selectedAddons: selectedAddons,
          notes: notes,
        ),
      ];
    }
  }

  void updateQuantity(CartItem item, int delta) {
    final currentList = List<CartItem>.from(state);
    final index = currentList.indexOf(item);
    if (index >= 0) {
      item.quantity += delta;
      if (item.quantity <= 0) {
        currentList.removeAt(index);
      }
      state = [...currentList];
    }
  }

  void removeItem(CartItem item) {
    final currentList = List<CartItem>.from(state);
    currentList.remove(item);
    state = [...currentList];
  }

  void restoreCart(List<CartItem> items) {
    state = List<CartItem>.from(items);
  }

  void clearCart() {
    state = [];
  }
}

final posCartProvider =
    NotifierProvider<PosCartNotifier, List<CartItem>>(PosCartNotifier.new);
