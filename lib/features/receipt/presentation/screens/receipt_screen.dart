import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_pos/core/models/pos_models.dart';
import 'package:food_pos/core/services/printer/printer_notifier.dart';
import 'package:food_pos/features/pos/presentation/providers/pos_cart_notifier.dart';
import 'package:food_pos/features/pos/presentation/screens/pos_screen.dart';
import 'package:food_pos/routers/app_routes.dart';
import 'package:food_pos/theme/app_themes.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class ReceiptScreen extends ConsumerWidget {
  final PosTransaction? transaction;

  const ReceiptScreen({super.key, this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tx = transaction ?? mockTransactions[0];

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: whiteColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(IconsaxPlusLinear.close_circle, color: blackColor),
          onPressed: () {
            ref.read(posCartProvider.notifier).clearCart();
            context.go(AppRoutes.home);
          },
        ),
        title: Text(
          'Digital Receipt',
          style: boldTextStyle.copyWith(fontSize: 18, color: blackColor),
        ),
        actions: [
          IconButton(
            icon: Icon(IconsaxPlusLinear.share, color: blackColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Sharing receipt via WhatsApp / Email...',
                  ),
                  backgroundColor: primaryColor,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, 4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: primaryLightColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            IconsaxPlusLinear.shop,
                            color: primaryColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'GREEN BITES CAFE',
                          style: boldTextStyle.copyWith(
                            fontSize: 18,
                            color: blackColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Jl. Boulevard Senopati No. 88, Jakarta Selatan\nTelp: (021) 555-0199',
                          textAlign: TextAlign.center,
                          style: regularTextStyle.copyWith(
                            fontSize: 12,
                            color: greyColor,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primaryLightColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                IconsaxPlusLinear.tick_circle,
                                size: 14,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Payment Successful • Offline Saved',
                                style: semiBoldTextStyle.copyWith(
                                  fontSize: 11,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildPerforatedDivider(),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(
                      children: [
                        _receiptMetaRow('Receipt No', tx.receiptNo),
                        _receiptMetaRow(
                          'Date & Time',
                          '${tx.dateTime.day}/${tx.dateTime.month}/${tx.dateTime.year} ${tx.dateTime.hour}:${tx.dateTime.minute.toString().padLeft(2, '0')}',
                        ),
                        _receiptMetaRow('Cashier', tx.cashierName),
                        _receiptMetaRow('Order Type', tx.tableNo ?? 'Dine In'),
                        _receiptMetaRow('Payment Method', tx.paymentMethod),
                      ],
                    ),
                  ),

                  const Divider(height: 1, indent: 20, endIndent: 20),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...tx.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.quantity}x ${item.product.name}',
                                        style: semiBoldTextStyle.copyWith(
                                          fontSize: 13,
                                          color: blackColor,
                                        ),
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
                                if (item.selectedAddons.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 18),
                                    child: Text(
                                      '+ ${item.selectedAddons.map((a) => a.name).join(', ')}',
                                      style: regularTextStyle.copyWith(
                                        fontSize: 11,
                                        color: greyColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  _buildPerforatedDivider(),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      children: [
                        _receiptMetaRow(
                          'Subtotal',
                          'Rp ${formatCurrency(tx.subtotal)}',
                        ),
                        if (tx.discountAmount > 0)
                          _receiptMetaRow(
                            'Discount',
                            '-Rp ${formatCurrency(tx.discountAmount)}',
                            valueColor: redColor,
                          ),
                        _receiptMetaRow(
                          'Tax (PB1 10%)',
                          'Rp ${formatCurrency(tx.taxAmount)}',
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TOTAL',
                              style: boldTextStyle.copyWith(
                                fontSize: 16,
                                color: blackColor,
                              ),
                            ),
                            Text(
                              'Rp ${formatCurrency(tx.grandTotal)}',
                              style: boldTextStyle.copyWith(
                                fontSize: 18,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        _receiptMetaRow(
                          'Cash Received',
                          'Rp ${formatCurrency(tx.cashReceived)}',
                        ),
                        _receiptMetaRow(
                          'Change Given',
                          'Rp ${formatCurrency(tx.changeGiven)}',
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 24,
                      left: 20,
                      right: 20,
                    ),
                    child: Text(
                      '*** THANK YOU FOR YOUR VISIT ***\nFollow us on Instagram @greenbites.cafe',
                      textAlign: TextAlign.center,
                      style: regularTextStyle.copyWith(
                        fontSize: 11,
                        color: greyColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: Icon(IconsaxPlusLinear.printer, size: 20),
                    label: Text(
                      'Print Receipt',
                      style: boldTextStyle.copyWith(
                        fontSize: 14,
                        color: primaryColor,
                      ),
                    ),
                    onPressed: () async {
                      final printerState = ref.read(printerNotifierProvider);
                      if (!printerState.isConnected) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: whiteColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Row(
                              children: [
                                Icon(
                                  IconsaxPlusLinear.printer_slash,
                                  color: orangeColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Printer Not Connected',
                                  style: boldTextStyle.copyWith(
                                    fontSize: 16,
                                    color: blackColor,
                                  ),
                                ),
                              ],
                            ),
                            content: Text(
                              'Please connect your Bluetooth thermal printer first in Settings.',
                              style: regularTextStyle.copyWith(
                                fontSize: 13,
                                color: greyColor,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(
                                  'Cancel',
                                  style: semiBoldTextStyle.copyWith(
                                    color: greyColor,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                style: primaryButtonStyle,
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  context.go(AppRoutes.home, extra: 4);
                                },
                                child: const Text('Go to Settings'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      final success = await ref
                          .read(printerNotifierProvider.notifier)
                          .printReceipt(tx);
                      if (context.mounted) {
                        if (success) {
                          _showPrintSuccessDialog(
                            context,
                            printerState.connectedDeviceName,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Failed to print receipt. Check printer connection.',
                              ),
                              backgroundColor: redColor,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: primaryButtonStyle.copyWith(
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    icon: Icon(
                      IconsaxPlusLinear.add_circle,
                      color: whiteColor,
                      size: 20,
                    ),
                    label: Text(
                      'New Order',
                      style: boldTextStyle.copyWith(
                        fontSize: 14,
                        color: whiteColor,
                      ),
                    ),
                    onPressed: () {
                      ref.read(posCartProvider.notifier).clearCart();
                      context.go(AppRoutes.home);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _receiptMetaRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: regularTextStyle.copyWith(fontSize: 12, color: greyColor),
          ),
          Text(
            value,
            style: mediumTextStyle.copyWith(
              fontSize: 12,
              color: valueColor ?? blackColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerforatedDivider() {
    return Row(
      children: [
        Container(
          width: 14,
          height: 20,
          decoration: BoxDecoration(
            color: scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boxWidth = constraints.constrainWidth();
              const dashWidth = 5.0;
              const dashSpace = 4.0;
              final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
              return Flex(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                direction: Axis.horizontal,
                children: List.generate(dashCount, (_) {
                  return const SizedBox(
                    width: dashWidth,
                    height: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Color(0xFFD1D5DB)),
                    ),
                  );
                }),
              );
            },
          ),
        ),
        Container(
          width: 14,
          height: 20,
          decoration: BoxDecoration(
            color: scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomLeft: Radius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  void _showPrintSuccessDialog(BuildContext context, [String? deviceName]) {
    final target = deviceName != null && deviceName.isNotEmpty
        ? deviceName
        : 'Bluetooth Thermal Printer';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: primaryLightColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconsaxPlusLinear.printer,
                  color: primaryColor,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Receipt Printed',
                style: boldTextStyle.copyWith(fontSize: 18, color: blackColor),
              ),
              const SizedBox(height: 6),
              Text(
                'Sent to $target. Printing complete!',
                textAlign: TextAlign.center,
                style: regularTextStyle.copyWith(color: greyColor),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: primaryButtonStyle,
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'OK',
                    style: regularTextStyle.copyWith(color: whiteColor),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
