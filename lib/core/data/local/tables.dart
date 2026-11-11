/// Definisi Nama Tabel dan Kolom SQLite untuk POS Application
class AppTables {
  static const String users = 'users';
  static const String categories = 'categories';
  static const String products = 'products';
  static const String addons = 'addons';
  static const String productAddons = 'product_addons';
  static const String transactions = 'transactions';
  static const String transactionItems = 'transaction_items';
  static const String transactionItemAddons = 'transaction_item_addons';
  static const String inventoryLogs = 'inventory_logs';
  static const String storeSettings = 'store_settings';
}

class UserColumns {
  static const String id = 'id';
  static const String username = 'username';
  static const String name = 'name';
  static const String email = 'email';
  static const String phone = 'phone';
  static const String role = 'role';
  static const String pinHash = 'pin_hash';
  static const String isActive = 'is_active';
  static const String createdAt = 'created_at';
}

class CategoryColumns {
  static const String id = 'id';
  static const String name = 'name';
  static const String iconName = 'icon_name';
  static const String sortOrder = 'sort_order';
  static const String isActive = 'is_active';
}

class ProductColumns {
  static const String id = 'id';
  static const String categoryId = 'category_id';
  static const String sku = 'sku';
  static const String name = 'name';
  static const String price = 'price';
  static const String costPrice = 'cost_price';
  static const String stock = 'stock';
  static const String trackStock = 'track_stock';
  static const String iconName = 'icon_name';
  static const String imagePath = 'image_path';
  static const String isAvailable = 'is_available';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

class AddonColumns {
  static const String id = 'id';
  static const String name = 'name';
  static const String price = 'price';
  static const String stock = 'stock';
  static const String trackStock = 'track_stock';
  static const String isActive = 'is_active';
}

class ProductAddonColumns {
  static const String productId = 'product_id';
  static const String addonId = 'addon_id';
}

class TransactionColumns {
  static const String id = 'id';
  static const String receiptNo = 'receipt_no';
  static const String cashierId = 'cashier_id';
  static const String cashierName = 'cashier_name';
  static const String tableNo = 'table_no';
  static const String customerName = 'customer_name';
  static const String subtotal = 'subtotal';
  static const String discountType = 'discount_type';
  static const String discountRate = 'discount_rate';
  static const String discountAmount = 'discount_amount';
  static const String taxRate = 'tax_rate';
  static const String taxAmount = 'tax_amount';
  static const String serviceRate = 'service_rate';
  static const String serviceAmount = 'service_amount';
  static const String grandTotal = 'grand_total';
  static const String paymentMethod = 'payment_method';
  static const String cashReceived = 'cash_received';
  static const String changeGiven = 'change_given';
  static const String status = 'status'; // 'completed', 'held', 'cancelled'
  static const String notes = 'notes';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

class TransactionItemColumns {
  static const String id = 'id';
  static const String transactionId = 'transaction_id';
  static const String productId = 'product_id';
  static const String productName = 'product_name';
  static const String unitPrice = 'unit_price';
  static const String costPrice = 'cost_price';
  static const String quantity = 'quantity';
  static const String subtotal = 'subtotal';
  static const String notes = 'notes';
}

class TransactionItemAddonColumns {
  static const String id = 'id';
  static const String transactionItemId = 'transaction_item_id';
  static const String addonId = 'addon_id';
  static const String addonName = 'addon_name';
  static const String addonPrice = 'addon_price';
  static const String quantity = 'quantity';
  static const String subtotal = 'subtotal';
}

class InventoryLogColumns {
  static const String id = 'id';
  static const String itemType = 'item_type'; // 'product' atau 'addon'
  static const String itemId = 'item_id';
  static const String quantityChange = 'quantity_change';
  static const String balanceAfter = 'balance_after';
  static const String mutationType = 'mutation_type'; // 'sale', 'restock', 'adjustment'
  static const String referenceId = 'reference_id';
  static const String notes = 'notes';
  static const String createdAt = 'created_at';
}

class StoreSettingColumns {
  static const String id = 'id';
  static const String storeName = 'store_name';
  static const String address = 'address';
  static const String phone = 'phone';
  static const String receiptHeader = 'receipt_header';
  static const String receiptFooter = 'receipt_footer';
  static const String taxRate = 'tax_rate';
  static const String serviceRate = 'service_rate';
  static const String currencyCode = 'currency_code';
}
