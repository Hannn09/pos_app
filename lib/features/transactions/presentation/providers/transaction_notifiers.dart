import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_pos/core/models/pos_models.dart';
import 'package:food_pos/features/transactions/domain/providers/transaction_providers.dart';

// Helper Rentang Tanggal
class DateRangeHelper {
  static (DateTime?, DateTime?) getRangeForFilter(String filter) {
    final now = DateTime.now();
    switch (filter) {
      case 'Today':
        final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return (start, end);
      case 'Yesterday':
        final yest = now.subtract(const Duration(days: 1));
        final start = DateTime(yest.year, yest.month, yest.day, 0, 0, 0);
        final end = DateTime(yest.year, yest.month, yest.day, 23, 59, 59, 999);
        return (start, end);
      case 'Last 7 Days':
        final sevenDaysAgo = now.subtract(const Duration(days: 6));
        final start = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return (start, end);
      case 'This Week':
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return (start, end);
      case 'This Month':
        final start = DateTime(now.year, now.month, 1, 0, 0, 0);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        return (start, end);
      case 'All':
      default:
        return (null, null);
    }
  }
}

// 1. Notifier Kata Kunci Pencarian Transaksi
class TransactionSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setSearch(String query) => state = query;
}

final transactionSearchQueryProvider =
    NotifierProvider<TransactionSearchQueryNotifier, String>(
        TransactionSearchQueryNotifier.new);

// 2. Notifier Filter Tanggal Transaksi ('Today', 'Yesterday', 'Last 7 Days', 'This Month', 'All')
class TransactionDateFilterNotifier extends Notifier<String> {
  @override
  String build() => 'Today';

  void setFilter(String filter) => state = filter;
}

final transactionDateFilterProvider =
    NotifierProvider<TransactionDateFilterNotifier, String>(
        TransactionDateFilterNotifier.new);

// 3. Notifier Filter Metode Pembayaran ('All', 'Cash', 'QRIS')
class TransactionPaymentFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setFilter(String filter) => state = filter;
}

final transactionPaymentFilterProvider =
    NotifierProvider<TransactionPaymentFilterNotifier, String>(
        TransactionPaymentFilterNotifier.new);

// 4. Provider List Transaksi dari Repository dengan filter tanggal & pencarian
final transactionsListProvider =
    FutureProvider<List<PosTransaction>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final search = ref.watch(transactionSearchQueryProvider);
  final dateFilter = ref.watch(transactionDateFilterProvider);
  final paymentFilter = ref.watch(transactionPaymentFilterProvider);

  final (startDate, endDate) = DateRangeHelper.getRangeForFilter(dateFilter);

  final list = await repo.getTransactions(
    startDate: startDate,
    endDate: endDate,
    search: search,
  );

  if (paymentFilter == 'All') return list;
  return list
      .where((t) => t.paymentMethod.toLowerCase() == paymentFilter.toLowerCase())
      .toList();
});

// 5. Notifier Rentang Filter Laporan ('Today', 'This Week', 'This Month')
class ReportRangeNotifier extends Notifier<String> {
  @override
  String build() => 'Today';

  void setRange(String range) => state = range;
}

final reportRangeProvider =
    NotifierProvider<ReportRangeNotifier, String>(ReportRangeNotifier.new);

// 6. Provider Ringkasan Laporan Aktual dari Database
final reportSummaryProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final range = ref.watch(reportRangeProvider);
  final (startDate, endDate) = DateRangeHelper.getRangeForFilter(range);

  return await repo.getReportSummary(
    startDate: startDate,
    endDate: endDate,
  );
});

// 7. Provider Produk Terlaris Aktual dari Database
final reportTopProductsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final range = ref.watch(reportRangeProvider);
  final (startDate, endDate) = DateRangeHelper.getRangeForFilter(range);

  return await repo.getTopSellingProducts(
    startDate: startDate,
    endDate: endDate,
    limit: 5,
  );
});

// 8. Provider Data Grafik Penjualan Aktual dari Database
final reportSalesChartProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final range = ref.watch(reportRangeProvider);
  final (startDate, endDate) = DateRangeHelper.getRangeForFilter(range);

  return await repo.getSalesChartData(
    range: range,
    startDate: startDate,
    endDate: endDate,
  );
});

// 9. Provider Ringkasan Penjualan Hari Ini (Dashboard legacy compatibility)
final todaySalesSummaryProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return await repo.getSalesSummary(date: DateTime.now());
});

// 10. Provider Histori Penjualan Harian
final dailySalesHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return await repo.getDailySalesHistory(days: 7);
});
