import 'package:food_pos/core/models/pos_models.dart';

abstract class TransactionRepository {
  Future<void> saveTransaction(PosTransaction tx);
  Future<List<PosTransaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    String? status,
  });
  Future<PosTransaction?> getTransactionById(String id);
  Future<Map<String, dynamic>> getSalesSummary({DateTime? date});
  Future<List<Map<String, dynamic>>> getDailySalesHistory({int days = 7});
  Future<Map<String, dynamic>> getReportSummary({
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 5,
  });
  Future<List<Map<String, dynamic>>> getSalesChartData({
    required String range,
    DateTime? startDate,
    DateTime? endDate,
  });
}
