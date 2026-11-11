import 'package:food_pos/core/models/pos_models.dart';
import 'package:food_pos/features/transactions/data/datasource/transaction_local_datasource.dart';
import 'package:food_pos/features/transactions/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource _localDataSource;

  TransactionRepositoryImpl({TransactionLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? TransactionLocalDataSource();

  @override
  Future<void> saveTransaction(PosTransaction tx) =>
      _localDataSource.saveTransaction(tx);

  @override
  Future<List<PosTransaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    String? status,
  }) =>
      _localDataSource.getTransactions(
        startDate: startDate,
        endDate: endDate,
        search: search,
        status: status,
      );

  @override
  Future<PosTransaction?> getTransactionById(String id) =>
      _localDataSource.getTransactionById(id);

  @override
  Future<Map<String, dynamic>> getSalesSummary({DateTime? date}) =>
      _localDataSource.getSalesSummary(date: date);

  @override
  Future<List<Map<String, dynamic>>> getDailySalesHistory({int days = 7}) =>
      _localDataSource.getDailySalesHistory(days: days);

  @override
  Future<Map<String, dynamic>> getReportSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      _localDataSource.getReportSummary(
        startDate: startDate,
        endDate: endDate,
      );

  @override
  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 5,
  }) =>
      _localDataSource.getTopSellingProducts(
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );

  @override
  Future<List<Map<String, dynamic>>> getSalesChartData({
    required String range,
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      _localDataSource.getSalesChartData(
        range: range,
        startDate: startDate,
        endDate: endDate,
      );
}
