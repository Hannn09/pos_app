import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_pos/features/pos/presentation/screens/pos_screen.dart';
import 'package:food_pos/features/transactions/presentation/providers/transaction_notifiers.dart';
import 'package:food_pos/theme/app_themes.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final selectedRange = ref.watch(reportRangeProvider);
    final summaryAsync = ref.watch(reportSummaryProvider);
    final topProductsAsync = ref.watch(reportTopProductsProvider);
    final chartDataAsync = ref.watch(reportSalesChartProvider);

    final isLoading = summaryAsync.isLoading ||
        topProductsAsync.isLoading ||
        chartDataAsync.isLoading;

    final summary = summaryAsync.value ?? {};
    final grossRevenue = (summary['grossRevenue'] as num?)?.toDouble() ?? 0.0;
    final totalOrders = (summary['totalOrders'] as num?)?.toInt() ?? 0;
    final avgOrderValue = (summary['avgOrderValue'] as num?)?.toDouble() ?? 0.0;
    final totalItemsSold = (summary['totalItemsSold'] as num?)?.toInt() ?? 0;
    final totalTax = (summary['totalTax'] as num?)?.toDouble() ?? 0.0;

    final topProducts = topProductsAsync.value ?? [];
    final chartData = chartDataAsync.value ?? [];

    // Hitung max amount untuk scaling tinggi chart
    double maxChartAmount = 1.0;
    for (final c in chartData) {
      final amt = (c['amount'] as num?)?.toDouble() ?? 0.0;
      if (amt > maxChartAmount) maxChartAmount = amt;
    }

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: whiteColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Sales & Reports',
          style: boldTextStyle.copyWith(fontSize: 18, color: blackColor),
        ),
        actions: [
          IconButton(
            icon: Icon(IconsaxPlusLinear.export_1, color: blackColor),
            tooltip: 'Export Report',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Exporting $selectedRange sales report...'),
                  backgroundColor: primaryColor,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: ['Today', 'This Week', 'This Month'].map((range) {
                  final isSel = selectedRange == range;
                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        ref.read(reportRangeProvider.notifier).setRange(range);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          range,
                          textAlign: TextAlign.center,
                          style: semiBoldTextStyle.copyWith(
                            fontSize: 13,
                            color: isSel ? whiteColor : blackColor,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // KPI Grid (Revenue, Total Orders, Avg Ticket, Items Sold)
            Skeletonizer(
              enabled: isLoading,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Gross Revenue',
                          value: 'Rp ${formatCurrency(grossRevenue)}',
                          trend: '$selectedRange total sales',
                          isPositiveTrend: true,
                          icon: IconsaxPlusLinear.wallet_3,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Total Orders',
                          value: '$totalOrders Orders',
                          trend: 'Completed receipts',
                          isPositiveTrend: true,
                          icon: IconsaxPlusLinear.receipt_item,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Avg Order Value',
                          value: 'Rp ${formatCurrency(avgOrderValue)}',
                          trend: 'Per transaction',
                          isPositiveTrend: true,
                          icon: IconsaxPlusLinear.chart_2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildKpiCard(
                          title: 'Total Items Sold',
                          value: '$totalItemsSold Items',
                          trend: 'Tax: Rp ${formatCurrency(totalTax)}',
                          isPositiveTrend: true,
                          icon: IconsaxPlusLinear.box_1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Revenue Chart Card
            Skeletonizer(
              enabled: isLoading,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sales Trend ($selectedRange)',
                              style: boldTextStyle.copyWith(
                                fontSize: 15,
                                color: blackColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              chartData.isNotEmpty
                                  ? 'Showing SQLite database sales curve'
                                  : 'No sales records in selected period',
                              style: regularTextStyle.copyWith(
                                fontSize: 12,
                                color: greyColor,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primaryLightColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            selectedRange == 'Today' ? 'Hourly' : 'Daily',
                            style: semiBoldTextStyle.copyWith(
                              fontSize: 11,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Visual Bar Chart
                    SizedBox(
                      height: 140,
                      child: chartData.isEmpty
                          ? Center(
                              child: Text(
                                'No transactions recorded for $selectedRange',
                                style: regularTextStyle.copyWith(
                                  color: greyColor,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: chartData.map((item) {
                                final amt =
                                    (item['amount'] as num?)?.toDouble() ?? 0.0;
                                final hFactor = maxChartAmount > 0
                                    ? (amt / maxChartAmount).clamp(0.12, 1.0)
                                    : 0.12;
                                final label =
                                    (item['label'] as String?) ?? '-';

                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Tooltip(
                                      message:
                                          '$label: Rp ${formatCurrency(amt)}',
                                      child: Container(
                                        width: 24,
                                        height: 100 * hFactor,
                                        decoration: BoxDecoration(
                                          color: hFactor > 0.7
                                              ? primaryColor
                                              : primaryLightColor,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(6),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      label,
                                      style: regularTextStyle.copyWith(
                                        fontSize: 10,
                                        color: greyColor,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Top Selling Menu Items
            Skeletonizer(
              enabled: isLoading,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top 5 Best Selling Items',
                      style: boldTextStyle.copyWith(
                        fontSize: 15,
                        color: blackColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (topProducts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'No sales data available yet',
                            style: regularTextStyle.copyWith(
                              fontSize: 13,
                              color: greyColor,
                            ),
                          ),
                        ),
                      )
                    else
                      ...topProducts.asMap().entries.map((entry) {
                        final rank = entry.key + 1;
                        final item = entry.value;
                        final name = item['name'] as String? ?? 'Product';
                        final category =
                            item['category'] as String? ?? 'General';
                        final sold = (item['sold'] as num?)?.toInt() ?? 0;
                        final revenue =
                            (item['revenue'] as num?)?.toDouble() ?? 0.0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: rank == 1
                                      ? primaryColor
                                      : scaffoldBackgroundColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$rank',
                                    style: boldTextStyle.copyWith(
                                      fontSize: 12,
                                      color:
                                          rank == 1 ? whiteColor : blackColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: boldTextStyle.copyWith(
                                        fontSize: 13,
                                        color: blackColor,
                                      ),
                                    ),
                                    Text(
                                      '$category • $sold sold',
                                      style: regularTextStyle.copyWith(
                                        fontSize: 11,
                                        color: greyColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Rp ${formatCurrency(revenue)}',
                                style: semiBoldTextStyle.copyWith(
                                  fontSize: 13,
                                  color: blackColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String trend,
    required bool isPositiveTrend,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: regularTextStyle.copyWith(
                  fontSize: 12,
                  color: greyColor,
                ),
              ),
              Icon(icon, size: 18, color: primaryColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: boldTextStyle.copyWith(fontSize: 17, color: blackColor),
          ),
          const SizedBox(height: 4),
          Text(
            trend,
            style: semiBoldTextStyle.copyWith(
              fontSize: 11,
              color: isPositiveTrend ? primaryColor : redColor,
            ),
          ),
        ],
      ),
    );
  }
}
