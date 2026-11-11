import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class PosCategory {
  final String id;
  final String name;
  final IconData icon;
  final int itemCount;

  const PosCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.itemCount = 0,
  });
}

class PosAddon {
  final String id;
  final String name;
  final double price;
  final int stock;
  bool isSelected;

  PosAddon({
    required this.id,
    required this.name,
    required this.price,
    this.stock = 100,
    this.isSelected = false,
  });

  PosAddon copyWith({
    String? id,
    String? name,
    double? price,
    int? stock,
    bool? isSelected,
  }) {
    return PosAddon(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class PosProduct {
  final String id;
  final String name;
  final String categoryId;
  final double price;
  final double? costPrice;
  final int stock;
  final IconData icon;
  final Color badgeColor;
  final bool isAvailable;
  final List<PosAddon> availableAddons;
  final String? imagePath;

  const PosProduct({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    this.costPrice,
    required this.stock,
    required this.icon,
    this.badgeColor = const Color(0xFF087F5B),
    this.isAvailable = true,
    this.availableAddons = const [],
    this.imagePath,
  });

  bool get isLowStock => stock > 0 && stock <= 5;
  bool get isOutOfStock => stock <= 0 || !isAvailable;
}

class CartItem {
  final PosProduct product;
  int quantity;
  List<PosAddon> selectedAddons;
  String? notes;

  CartItem({
    required this.product,
    this.quantity = 1,
    List<PosAddon>? selectedAddons,
    this.notes,
  }) : selectedAddons = selectedAddons ?? [];

  double get unitPrice {
    double addonsPrice = 0;
    for (final addon in selectedAddons) {
      addonsPrice += addon.price;
    }
    return product.price + addonsPrice;
  }

  double get totalPrice => unitPrice * quantity;
}

class PosTransaction {
  final String id;
  final String receiptNo;
  final DateTime dateTime;
  final String cashierName;
  final String? tableNo;
  final List<CartItem> items;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double grandTotal;
  final String paymentMethod;
  final double cashReceived;
  final double changeGiven;
  final bool isOfflineSynced;

  const PosTransaction({
    required this.id,
    required this.receiptNo,
    required this.dateTime,
    required this.cashierName,
    this.tableNo,
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.grandTotal,
    required this.paymentMethod,
    required this.cashReceived,
    required this.changeGiven,
    this.isOfflineSynced = true,
  });
}

// Default F&B Sample Data
final List<PosCategory> mockCategories = [
  const PosCategory(id: 'all', name: 'All Menu', icon: IconsaxPlusLinear.category, itemCount: 18),
  const PosCategory(id: 'coffee', name: 'Coffee & Tea', icon: IconsaxPlusLinear.coffee, itemCount: 7),
  const PosCategory(id: 'beverage', name: 'Cold Drinks', icon: IconsaxPlusLinear.glass, itemCount: 4),
  const PosCategory(id: 'main', name: 'Main Dishes', icon: IconsaxPlusLinear.reserve, itemCount: 4),
  const PosCategory(id: 'bakery', name: 'Bakery & Pastry', icon: IconsaxPlusLinear.cake, itemCount: 3),
];

final List<PosAddon> mockAddons = [
  PosAddon(id: 'ad1', name: 'Extra Espresso Shot', price: 6000, stock: 120),
  PosAddon(id: 'ad2', name: 'Oat Milk Upgrade', price: 8000, stock: 45),
  PosAddon(id: 'ad3', name: 'Vanilla Syrup Pump', price: 5000, stock: 80),
  PosAddon(id: 'ad4', name: 'Caramel Drizzle', price: 5000, stock: 65),
  PosAddon(id: 'ad5', name: 'Extra Cheese Slice', price: 7000, stock: 30),
  PosAddon(id: 'ad6', name: 'Less Sugar (50%)', price: 0, stock: 999),
];

final List<PosProduct> mockProducts = [
  PosProduct(
    id: 'p1',
    name: 'Caramel Macchiato',
    categoryId: 'coffee',
    price: 36000,
    costPrice: 14000,
    stock: 35,
    icon: IconsaxPlusLinear.coffee,
    availableAddons: [mockAddons[0], mockAddons[1], mockAddons[2], mockAddons[3], mockAddons[5]],
  ),
  PosProduct(
    id: 'p2',
    name: 'Iced Matcha Latte',
    categoryId: 'beverage',
    price: 38000,
    costPrice: 16000,
    stock: 22,
    icon: IconsaxPlusLinear.glass,
    availableAddons: [mockAddons[1], mockAddons[5]],
  ),
  PosProduct(
    id: 'p3',
    name: 'Classic Beef Truffle Burger',
    categoryId: 'main',
    price: 55000,
    costPrice: 28000,
    stock: 14,
    icon: IconsaxPlusLinear.reserve,
    availableAddons: [mockAddons[4]],
  ),
  PosProduct(
    id: 'p4',
    name: 'Butter Almond Croissant',
    categoryId: 'bakery',
    price: 28000,
    costPrice: 11000,
    stock: 4, // low stock!
    icon: IconsaxPlusLinear.cake,
    availableAddons: [],
  ),
  PosProduct(
    id: 'p5',
    name: 'Spanish Latte Especial',
    categoryId: 'coffee',
    price: 35000,
    costPrice: 13000,
    stock: 18,
    icon: IconsaxPlusLinear.coffee,
    availableAddons: [mockAddons[0], mockAddons[1]],
  ),
  PosProduct(
    id: 'p6',
    name: 'Truffle French Fries',
    categoryId: 'main',
    price: 32000,
    costPrice: 12000,
    stock: 25,
    icon: IconsaxPlusLinear.reserve,
    availableAddons: [mockAddons[4]],
  ),
  PosProduct(
    id: 'p7',
    name: 'Fresh Mango Mint Tea',
    categoryId: 'beverage',
    price: 28000,
    costPrice: 9000,
    stock: 0, // out of stock!
    isAvailable: false,
    icon: IconsaxPlusLinear.glass,
    availableAddons: [mockAddons[5]],
  ),
  PosProduct(
    id: 'p8',
    name: 'Spaghetti Smoked Beef Aglio',
    categoryId: 'main',
    price: 48000,
    costPrice: 22000,
    stock: 11,
    icon: IconsaxPlusLinear.reserve,
    availableAddons: [mockAddons[4]],
  ),
  PosProduct(
    id: 'p9',
    name: 'Pain au Chocolat',
    categoryId: 'bakery',
    price: 30000,
    costPrice: 12000,
    stock: 3, // low stock!
    icon: IconsaxPlusLinear.cake,
    availableAddons: [],
  ),
  PosProduct(
    id: 'p10',
    name: 'Cold Brew Reserve 24H',
    categoryId: 'coffee',
    price: 34000,
    costPrice: 12000,
    stock: 15,
    icon: IconsaxPlusLinear.coffee,
    availableAddons: [mockAddons[1]],
  ),
];

final List<PosTransaction> mockTransactions = [
  PosTransaction(
    id: 'tx1',
    receiptNo: 'REC-20261110-0089',
    dateTime: DateTime.now().subtract(const Duration(minutes: 12)),
    cashierName: 'Sarah Jenkins',
    tableNo: 'Table 04',
    items: [
      CartItem(
        product: mockProducts[0],
        quantity: 2,
        selectedAddons: [mockAddons[1]],
      ),
      CartItem(
        product: mockProducts[3],
        quantity: 1,
      ),
    ],
    subtotal: 116000,
    discountAmount: 11600,
    taxAmount: 10440,
    grandTotal: 114840,
    paymentMethod: 'Cash',
    cashReceived: 150000,
    changeGiven: 35160,
    isOfflineSynced: true,
  ),
  PosTransaction(
    id: 'tx2',
    receiptNo: 'REC-20261110-0088',
    dateTime: DateTime.now().subtract(const Duration(minutes: 45)),
    cashierName: 'Sarah Jenkins',
    tableNo: 'Takeaway',
    items: [
      CartItem(product: mockProducts[2], quantity: 1),
      CartItem(product: mockProducts[1], quantity: 1),
    ],
    subtotal: 93000,
    discountAmount: 0,
    taxAmount: 9300,
    grandTotal: 102300,
    paymentMethod: 'QRIS',
    cashReceived: 102300,
    changeGiven: 0,
    isOfflineSynced: true,
  ),
  PosTransaction(
    id: 'tx3',
    receiptNo: 'REC-20261110-0087',
    dateTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 10)),
    cashierName: 'Sarah Jenkins',
    tableNo: 'Table 09',
    items: [
      CartItem(product: mockProducts[4], quantity: 3),
      CartItem(product: mockProducts[5], quantity: 2),
    ],
    subtotal: 169000,
    discountAmount: 15000,
    taxAmount: 15400,
    grandTotal: 169400,
    paymentMethod: 'Cash',
    cashReceived: 200000,
    changeGiven: 30600,
    isOfflineSynced: false, // offline pending sync badge!
  ),
];
