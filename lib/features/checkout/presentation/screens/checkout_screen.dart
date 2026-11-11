import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_pos/core/models/pos_models.dart';
import 'package:food_pos/features/auth/presentation/providers/auth_notifiers.dart';
import 'package:food_pos/features/pos/presentation/providers/pos_cart_notifier.dart';
import 'package:food_pos/features/pos/presentation/screens/pos_screen.dart';
import 'package:food_pos/features/products/presentation/providers/product_notifiers.dart';
import 'package:food_pos/features/transactions/domain/providers/transaction_providers.dart';
import 'package:food_pos/features/transactions/presentation/providers/transaction_notifiers.dart';
import 'package:food_pos/routers/app_routes.dart';
import 'package:food_pos/theme/app_themes.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final List<CartItem>? items;
  final double? subtotal;

  const CheckoutScreen({super.key, this.items, this.subtotal});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late List<CartItem> _items;
  late double _baseSubtotal;

  String _paymentMethod = 'Cash'; // Cash, QRIS, Debit
  double _discountPercentage = 0.0;
  double _fixedDiscount = 0.0;
  String _activeDiscountKey = 'none';

  final TextEditingController _cashReceivedController = TextEditingController();
  double _cashReceived = 0.0;

  @override
  void initState() {
    super.initState();
    _items =
        widget.items ??
        [
          CartItem(
            product: mockProducts[0],
            quantity: 2,
            selectedAddons: [mockAddons[1]],
          ),
          CartItem(product: mockProducts[3], quantity: 1),
        ];

    _baseSubtotal =
        widget.subtotal ?? _items.fold(0, (sum, item) => sum + item.totalPrice);

    // Default cash received to exact amount initially
    final initialTotal = _calculateGrandTotal();
    _cashReceived = initialTotal;
    _cashReceivedController.text = initialTotal.round().toString();
  }

  @override
  void dispose() {
    _cashReceivedController.dispose();
    super.dispose();
  }

  double get _discountAmount {
    if (_discountPercentage > 0) {
      return _baseSubtotal * _discountPercentage;
    }
    return _fixedDiscount;
  }

  double get _taxableAmount =>
      (_baseSubtotal - _discountAmount).clamp(0, double.infinity);
  double get _taxAmount => _taxableAmount * 0.10; // PB1 10%
  double get _grandTotal => _taxableAmount + _taxAmount;
  double get _change => _cashReceived - _grandTotal;

  double _calculateGrandTotal() {
    final discount = _discountPercentage > 0
        ? _baseSubtotal * _discountPercentage
        : _fixedDiscount;
    final taxable = (_baseSubtotal - discount).clamp(0, double.infinity);
    return taxable + (taxable * 0.10);
  }

  void _setCash(double amount) {
    setState(() {
      _cashReceived = amount;
      _cashReceivedController.text = amount.round().toString();
    });
  }

  List<double> _generateQuickAmounts(double total) {
    final Set<double> amounts = {total};
    final int rounded10k = ((total / 10000).ceil()) * 10000;
    amounts.add(rounded10k.toDouble());

    final int rounded50k = ((total / 50000).ceil()) * 50000;
    amounts.add(rounded50k.toDouble());

    final int rounded100k = ((total / 100000).ceil()) * 100000;
    amounts.add(rounded100k.toDouble());

    amounts.add(100000.0);
    amounts.add(200000.0);

    final sorted = amounts.where((a) => a >= total).toList()..sort();
    return sorted.take(4).toList();
  }

  Future<void> _onCompletePayment() async {
    if (_paymentMethod == 'Cash' && _cashReceived < _grandTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cash received is less than total amount'),
          backgroundColor: redColor,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final randomSuffix = (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    final cashierName = ref.read(currentUserProvider)?.name ?? 'Sarah Jenkins';

    final newTx = PosTransaction(
      id: 'tx_${now.millisecondsSinceEpoch}',
      receiptNo:
          'REC-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$randomSuffix',
      dateTime: now,
      cashierName: cashierName,
      tableNo: 'Table 04 / Dine In',
      items: _items,
      subtotal: _baseSubtotal,
      discountAmount: _discountAmount,
      taxAmount: _taxAmount,
      grandTotal: _grandTotal,
      paymentMethod: _paymentMethod,
      cashReceived: _paymentMethod == 'Cash' ? _cashReceived : _grandTotal,
      changeGiven: _paymentMethod == 'Cash'
          ? _change.clamp(0, double.infinity)
          : 0,
      isOfflineSynced: true,
    );

    try {
      // Simpan transaksi secara atomik ke database SQLite
      await ref.read(transactionRepositoryProvider).saveTransaction(newTx);

      // Invalidate provider agar layar histori transaksi & laporan langsung terupdate
      ref.invalidate(transactionsListProvider);
      ref.invalidate(reportSummaryProvider);
      ref.invalidate(reportTopProductsProvider);
      ref.invalidate(reportSalesChartProvider);
      ref.invalidate(todaySalesSummaryProvider);
      ref.invalidate(dailySalesHistoryProvider);
      ref.invalidate(filteredProductsProvider);

      // Reset keranjang POS
      ref.read(posCartProvider.notifier).clearCart();

      if (!mounted) return;
      context.push(AppRoutes.receipt, extra: newTx);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save transaction: $e'),
          backgroundColor: redColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quickAmounts = _generateQuickAmounts(_grandTotal);

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: whiteColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(IconsaxPlusLinear.arrow_left, color: blackColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Checkout & Payment',
          style: boldTextStyle.copyWith(fontSize: 18, color: blackColor),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: primaryLightColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(IconsaxPlusLinear.flash_1, size: 14, color: primaryColor),
                const SizedBox(width: 4),
                Text(
                  'Fast Pay',
                  style: semiBoldTextStyle.copyWith(
                    fontSize: 12,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Card
            Container(
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
                      Text(
                        'Order Summary',
                        style: boldTextStyle.copyWith(
                          fontSize: 15,
                          color: blackColor,
                        ),
                      ),
                      Text(
                        '${_items.length} Items',
                        style: regularTextStyle.copyWith(
                          fontSize: 13,
                          color: greyColor,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  ..._items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item.quantity}x',
                              style: boldTextStyle.copyWith(
                                fontSize: 12,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: semiBoldTextStyle.copyWith(
                                    fontSize: 13,
                                    color: blackColor,
                                  ),
                                ),
                                if (item.selectedAddons.isNotEmpty)
                                  Text(
                                    item.selectedAddons
                                        .map((a) => a.name)
                                        .join(', '),
                                    style: regularTextStyle.copyWith(
                                      fontSize: 11,
                                      color: primaryColor,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            'Rp ${formatCurrency(item.totalPrice)}',
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
            const SizedBox(height: 16),

            // Discounts Selection
            Container(
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
                      Text(
                        'Discount / Promo',
                        style: boldTextStyle.copyWith(
                          fontSize: 15,
                          color: blackColor,
                        ),
                      ),
                      if (_discountAmount > 0)
                        Text(
                          '-Rp ${formatCurrency(_discountAmount)}',
                          style: boldTextStyle.copyWith(
                            fontSize: 13,
                            color: redColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDiscountChip('none', 'No Discount', 0, 0),
                      _buildDiscountChip('member', '10% Member', 0.10, 0),
                      _buildDiscountChip('student', '5% Student', 0.05, 0),
                      _buildDiscountChip(
                        'promo10k',
                        'Rp 10.000 Voucher',
                        0,
                        10000,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Method Tabs
            Container(
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
                    'Payment Method',
                    style: boldTextStyle.copyWith(
                      fontSize: 15,
                      color: blackColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMethodButton('Cash', IconsaxPlusLinear.money_tick),
                      const SizedBox(width: 10),
                      _buildMethodButton(
                        'QRIS',
                        IconsaxPlusLinear.scan_barcode,
                      ),
                      const SizedBox(width: 10),
                      _buildMethodButton(
                        'Debit/Card',
                        IconsaxPlusLinear.card_pos,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cash Received Input & Shortcuts
            if (_paymentMethod == 'Cash')
              Container(
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
                      'Cash Received',
                      style: boldTextStyle.copyWith(
                        fontSize: 15,
                        color: blackColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _cashReceivedController,
                      keyboardType: TextInputType.number,
                      style: boldTextStyle.copyWith(
                        fontSize: 22,
                        color: blackColor,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _cashReceived = double.tryParse(val) ?? 0;
                        });
                      },
                      decoration: textFieldDecoration.copyWith(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 14, right: 8),
                          child: Text(
                            'Rp',
                            style: boldTextStyle.copyWith(
                              fontSize: 20,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Quick Cash Shortcuts',
                      style: mediumTextStyle.copyWith(
                        fontSize: 12,
                        color: greyColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: quickAmounts.map((amt) {
                        final isExact = (amt == _grandTotal);
                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _setCash(amt),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _cashReceived == amt
                                    ? primaryColor
                                    : borderColor,
                              ),
                            ),
                            child: Text(
                              isExact
                                  ? 'Exact (Rp ${formatCurrency(amt)})'
                                  : 'Rp ${formatCurrency(amt)}',
                              style: semiBoldTextStyle.copyWith(
                                fontSize: 12,
                                color: _cashReceived == amt
                                    ? primaryColor
                                    : blackColor,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Calculation Breakdown Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _summaryRow(
                    'Subtotal',
                    'Rp ${formatCurrency(_baseSubtotal)}',
                  ),
                  if (_discountAmount > 0)
                    _summaryRow(
                      'Discount',
                      '-Rp ${formatCurrency(_discountAmount)}',
                      textColor: redColor,
                    ),
                  _summaryRow(
                    'Tax (PB1 10%)',
                    'Rp ${formatCurrency(_taxAmount)}',
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Payment',
                        style: boldTextStyle.copyWith(
                          fontSize: 17,
                          color: blackColor,
                        ),
                      ),
                      Text(
                        'Rp ${formatCurrency(_grandTotal)}',
                        style: boldTextStyle.copyWith(
                          fontSize: 22,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  if (_paymentMethod == 'Cash') ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _change >= 0
                            ? primaryLightColor.withValues(alpha: 0.6)
                            : redColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _change >= 0
                                    ? IconsaxPlusLinear.tick_circle
                                    : IconsaxPlusLinear.danger,
                                size: 18,
                                color: _change >= 0 ? primaryColor : redColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _change >= 0
                                    ? 'Change (Kembalian)'
                                    : 'Underpaid',
                                style: boldTextStyle.copyWith(
                                  fontSize: 14,
                                  color: _change >= 0 ? primaryColor : redColor,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _change >= 0
                                ? 'Rp ${formatCurrency(_change)}'
                                : '-Rp ${formatCurrency(_change.abs())}',
                            style: boldTextStyle.copyWith(
                              fontSize: 16,
                              color: _change >= 0 ? primaryColor : redColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Complete Payment Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: primaryButtonStyle,
                onPressed: _onCompletePayment,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      IconsaxPlusLinear.receipt_1,
                      color: whiteColor,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Complete Payment • Rp ${formatCurrency(_grandTotal)}',
                      style: boldTextStyle.copyWith(
                        fontSize: 16,
                        color: whiteColor,
                      ),
                    ),
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

  Widget _buildDiscountChip(
    String key,
    String label,
    double percent,
    double fixed,
  ) {
    final isSelected = _activeDiscountKey == key;
    return ChoiceChip(
      showCheckmark: false,
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        setState(() {
          _activeDiscountKey = key;
          _discountPercentage = percent;
          _fixedDiscount = fixed;
          // readjust cash if it was exact
          _cashReceived = _calculateGrandTotal();
          _cashReceivedController.text = _cashReceived.round().toString();
        });
      },
      selectedColor: primaryColor,
      backgroundColor: scaffoldBackgroundColor,
      labelStyle: semiBoldTextStyle.copyWith(
        fontSize: 12,
        color: isSelected ? whiteColor : blackColor,
      ),
      side: BorderSide(color: isSelected ? primaryColor : borderColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildMethodButton(String method, IconData icon) {
    final isSelected = _paymentMethod == method;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            _paymentMethod = method;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryLightColor : scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? primaryColor : borderColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? primaryColor : greyColor,
                size: 20,
              ),
              const SizedBox(height: 6),
              Text(
                method,
                style: semiBoldTextStyle.copyWith(
                  fontSize: 12,
                  color: isSelected ? primaryColor : blackColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String title, String val, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: regularTextStyle.copyWith(fontSize: 13, color: greyColor),
          ),
          Text(
            val,
            style: semiBoldTextStyle.copyWith(
              fontSize: 14,
              color: textColor ?? blackColor,
            ),
          ),
        ],
      ),
    );
  }
}
