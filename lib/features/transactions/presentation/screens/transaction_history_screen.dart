import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_pos/core/models/pos_models.dart';
import 'package:food_pos/features/pos/presentation/screens/pos_screen.dart';
import 'package:food_pos/features/transactions/presentation/providers/transaction_notifiers.dart';
import 'package:food_pos/routers/app_routes.dart';
import 'package:food_pos/theme/app_themes.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateFilter = ref.watch(transactionDateFilterProvider);
    final selectedPaymentFilter = ref.watch(transactionPaymentFilterProvider);
    final transactionsAsync = ref.watch(transactionsListProvider);

    final transactions = transactionsAsync.value ?? [];
    final isLoading = transactionsAsync.isLoading;

    final double totalRevenue =
        transactions.fold(0.0, (sum, tx) => sum + tx.grandTotal);

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: whiteColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Transaction History',
          style: boldTextStyle.copyWith(fontSize: 18, color: blackColor),
        ),
        actions: [
          IconButton(
            icon: Icon(IconsaxPlusLinear.document_download, color: blackColor),
            tooltip: 'Export CSV',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Exporting transactions to CSV...'),
                  backgroundColor: primaryColor,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Container(
            color: whiteColor,
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    ref
                        .read(transactionSearchQueryProvider.notifier)
                        .setSearch(val);
                  },
                  decoration: textFieldDecoration.copyWith(
                    hintText: 'Search by Receipt # or Cashier...',
                    hintStyle: hintTextStyle,
                    prefixIcon: Icon(
                      IconsaxPlusLinear.search_normal,
                      color: greyColor,
                      size: 18,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              IconsaxPlusLinear.close_circle,
                              size: 18,
                              color: greyColor,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(transactionSearchQueryProvider.notifier)
                                  .setSearch('');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),

                // Date Filter Chips
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            'Today',
                            'Yesterday',
                            'Last 7 Days',
                            'This Month',
                            'All',
                          ].map((f) {
                            final isSel = selectedDateFilter == f;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                showCheckmark: false,
                                label: Text(f),
                                selected: isSel,
                                selectedColor: primaryColor,
                                backgroundColor: scaffoldBackgroundColor,
                                labelStyle: semiBoldTextStyle.copyWith(
                                  fontSize: 11,
                                  color: isSel ? whiteColor : blackColor,
                                ),
                                side: BorderSide(
                                  color: isSel ? primaryColor : borderColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                onSelected: (val) {
                                  ref
                                      .read(transactionDateFilterProvider.notifier)
                                      .setFilter(f);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Payment Method Filter Chips
                Row(
                  children: [
                    Text(
                      'Payment: ',
                      style: regularTextStyle.copyWith(
                        fontSize: 11,
                        color: greyColor,
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', 'Cash', 'QRIS'].map((p) {
                            final isSel = selectedPaymentFilter == p;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                showCheckmark: false,
                                label: Text(p),
                                selected: isSel,
                                selectedColor: primaryLightColor,
                                backgroundColor: scaffoldBackgroundColor,
                                labelStyle: semiBoldTextStyle.copyWith(
                                  fontSize: 11,
                                  color: isSel ? primaryColor : blackColor,
                                ),
                                side: BorderSide(
                                  color: isSel ? primaryColor : borderColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                onSelected: (val) {
                                  ref
                                      .read(
                                          transactionPaymentFilterProvider.notifier)
                                      .setFilter(p);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Total Summary Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: primaryLightColor.withValues(alpha: 0.6),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${transactions.length} Transactions ($selectedDateFilter)',
                  style: semiBoldTextStyle.copyWith(
                    fontSize: 13,
                    color: primaryColor,
                  ),
                ),
                Text(
                  'Total: Rp ${formatCurrency(totalRevenue)}',
                  style: boldTextStyle.copyWith(
                    fontSize: 14,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Transaction List or Skeletonizer
          Expanded(
            child: Skeletonizer(
              enabled: isLoading,
              child: transactions.isEmpty && !isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            IconsaxPlusLinear.receipt_item,
                            size: 54,
                            color: lightGreyColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No transactions found',
                            style: boldTextStyle.copyWith(
                              fontSize: 16,
                              color: blackColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No sales recorded for "$selectedDateFilter"',
                            style: regularTextStyle.copyWith(
                              fontSize: 13,
                              color: greyColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: isLoading ? 5 : transactions.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final tx = isLoading
                            ? PosTransaction(
                                id: 'dummy_$index',
                                receiptNo: 'TRX-DUMMY-$index',
                                dateTime: DateTime.now(),
                                cashierName: 'Cashier Name',
                                tableNo: 'T-01',
                                items: [],
                                subtotal: 50000,
                                discountAmount: 0,
                                taxAmount: 5000,
                                grandTotal: 55000,
                                paymentMethod: 'Cash',
                                cashReceived: 100000,
                                changeGiven: 45000,
                                isOfflineSynced: true,
                              )
                            : transactions[index];

                        final itemsSummary = tx.items.isNotEmpty
                            ? '${tx.items.length} items (${tx.items.map((i) => i.product.name).join(', ')})'
                            : 'Completed order';

                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: isLoading
                              ? null
                              : () {
                                  context.push(AppRoutes.receipt, extra: tx);
                                },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: whiteColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Row: Receipt # & Status Badge
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: primaryLightColor,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Icon(
                                            IconsaxPlusLinear.receipt_text,
                                            size: 16,
                                            color: primaryColor,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          tx.receiptNo,
                                          style: boldTextStyle.copyWith(
                                            fontSize: 14,
                                            color: blackColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryLightColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            IconsaxPlusLinear.tick_circle,
                                            size: 12,
                                            color: primaryColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Completed',
                                            style: boldTextStyle.copyWith(
                                              fontSize: 10,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                // Middle Row: Items summary & Table
                                Text(
                                  itemsSummary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: regularTextStyle.copyWith(
                                    fontSize: 13,
                                    color: greyColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Bottom Row: Time, Method & Grand Total
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${tx.dateTime.hour.toString().padLeft(2, '0')}:${tx.dateTime.minute.toString().padLeft(2, '0')} • ${tx.paymentMethod} • ${tx.tableNo ?? 'Take Away'}',
                                      style: regularTextStyle.copyWith(
                                        fontSize: 12,
                                        color: lightGreyColor,
                                      ),
                                    ),
                                    Text(
                                      'Rp ${formatCurrency(tx.grandTotal)}',
                                      style: boldTextStyle.copyWith(
                                        fontSize: 15,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
