import 'package:food_pos/core/data/local/tables.dart';
import 'package:food_pos/core/models/pos_models.dart';

class TransactionTableModel {
  static PosTransaction fromMap(
    Map<String, dynamic> map,
    List<CartItem> items,
  ) {
    return PosTransaction(
      id: map[TransactionColumns.id] as String,
      receiptNo: map[TransactionColumns.receiptNo] as String,
      dateTime: DateTime.tryParse(map[TransactionColumns.createdAt] as String? ?? '') ??
          DateTime.now(),
      cashierName: map[TransactionColumns.cashierName] as String? ?? 'Cashier',
      tableNo: map[TransactionColumns.tableNo] as String?,
      items: items,
      subtotal: (map[TransactionColumns.subtotal] as num).toDouble(),
      discountAmount: (map[TransactionColumns.discountAmount] as num).toDouble(),
      taxAmount: (map[TransactionColumns.taxAmount] as num).toDouble(),
      grandTotal: (map[TransactionColumns.grandTotal] as num).toDouble(),
      paymentMethod: map[TransactionColumns.paymentMethod] as String? ?? 'Cash',
      cashReceived: (map[TransactionColumns.cashReceived] as num).toDouble(),
      changeGiven: (map[TransactionColumns.changeGiven] as num).toDouble(),
      isOfflineSynced: true,
    );
  }

  static Map<String, dynamic> toMap(PosTransaction tx) {
    return {
      TransactionColumns.id: tx.id,
      TransactionColumns.receiptNo: tx.receiptNo,
      TransactionColumns.cashierName: tx.cashierName,
      TransactionColumns.tableNo: tx.tableNo,
      TransactionColumns.customerName: 'Guest',
      TransactionColumns.subtotal: tx.subtotal,
      TransactionColumns.discountType: 'fixed',
      TransactionColumns.discountRate: 0.0,
      TransactionColumns.discountAmount: tx.discountAmount,
      TransactionColumns.taxRate: 10.0,
      TransactionColumns.taxAmount: tx.taxAmount,
      TransactionColumns.serviceRate: 0.0,
      TransactionColumns.serviceAmount: 0.0,
      TransactionColumns.grandTotal: tx.grandTotal,
      TransactionColumns.paymentMethod: tx.paymentMethod,
      TransactionColumns.cashReceived: tx.cashReceived,
      TransactionColumns.changeGiven: tx.changeGiven,
      TransactionColumns.status: 'completed',
      TransactionColumns.notes: null,
      TransactionColumns.createdAt: tx.dateTime.toIso8601String(),
      TransactionColumns.updatedAt: tx.dateTime.toIso8601String(),
    };
  }
}
