import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_pos/core/services/printer/printer_notifier.dart';
import 'package:food_pos/features/auth/presentation/providers/auth_notifiers.dart';
import 'package:food_pos/routers/app_routes.dart';
import 'package:food_pos/theme/app_themes.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isAutoPrintReceipt = true;
  bool _isCashDrawerBeep = true;

  void _openPrinterModal(BuildContext context) {
    ref.read(printerNotifierProvider.notifier).scanDevices();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final printer = ref.watch(printerNotifierProvider);
            final notifier = ref.read(printerNotifierProvider.notifier);

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryLightColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                IconsaxPlusLinear.printer,
                                color: primaryColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Bluetooth Printer Setup',
                              style: boldTextStyle.copyWith(
                                fontSize: 16,
                                color: blackColor,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: greyColor),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'PAPER SIZE',
                      style: boldTextStyle.copyWith(
                        fontSize: 11,
                        color: greyColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: ['58mm', '80mm'].map((size) {
                        final isSel = printer.paperSize == size;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            showCheckmark: false,
                            label: Text(
                              size == '58mm'
                                  ? '58mm Standard'
                                  : '80mm Wide (Receipt)',
                            ),
                            selected: isSel,
                            selectedColor: primaryColor,
                            backgroundColor: scaffoldBackgroundColor,
                            labelStyle: semiBoldTextStyle.copyWith(
                              fontSize: 12,
                              color: isSel ? whiteColor : blackColor,
                            ),
                            side: BorderSide(
                              color: isSel ? primaryColor : borderColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            onSelected: (_) => notifier.setPaperSize(size),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PAIRED BLUETOOTH PRINTERS',
                          style: boldTextStyle.copyWith(
                            fontSize: 11,
                            color: greyColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: printer.isScanning
                              ? null
                              : () => notifier.scanDevices(),
                          icon: printer.isScanning
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  Icons.refresh,
                                  size: 16,
                                  color: primaryColor,
                                ),
                          label: Text(
                            printer.isScanning ? 'Scanning...' : 'Scan Again',
                            style: semiBoldTextStyle.copyWith(
                              fontSize: 12,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (printer.availableDevices.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              IconsaxPlusLinear.bluetooth_circle,
                              size: 40,
                              color: greyColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No Paired Bluetooth Devices Found',
                              style: boldTextStyle.copyWith(
                                fontSize: 14,
                                color: blackColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Please pair your thermal printer in Android Bluetooth Settings first, then tap "Scan Again".',
                              textAlign: TextAlign.center,
                              style: regularTextStyle.copyWith(
                                fontSize: 12,
                                color: greyColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: printer.availableDevices.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final device = printer.availableDevices[index];
                          final isThisConnected =
                              printer.isConnected &&
                              printer.connectedMacAddress == device.macAdress;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isThisConnected
                                  ? primaryLightColor.withValues(alpha: 0.3)
                                  : whiteColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isThisConnected
                                    ? primaryColor
                                    : borderColor,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  IconsaxPlusLinear.printer,
                                  color: isThisConnected
                                      ? primaryColor
                                      : greyColor,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        device.name.isNotEmpty
                                            ? device.name
                                            : 'Thermal Printer',
                                        style: boldTextStyle.copyWith(
                                          fontSize: 14,
                                          color: blackColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        device.macAdress,
                                        style: regularTextStyle.copyWith(
                                          fontSize: 11,
                                          color: greyColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isThisConnected)
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: redColor,
                                      foregroundColor: whiteColor,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => notifier.disconnect(),
                                    child: const Text(
                                      'Disconnect',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  )
                                else
                                  ElevatedButton(
                                    style: primaryButtonStyle.copyWith(
                                      padding: const WidgetStatePropertyAll(
                                        EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6,
                                        ),
                                      ),
                                    ),
                                    onPressed: printer.isConnecting
                                        ? null
                                        : () => notifier.connect(device),
                                    child: printer.isConnecting
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Connect',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 20),

                    if (printer.isConnected)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primaryColor),
                            foregroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            IconsaxPlusLinear.receipt_1,
                            size: 18,
                          ),
                          label: Text(
                            'Print Test Ticket',
                            style: boldTextStyle.copyWith(
                              fontSize: 14,
                              color: primaryColor,
                            ),
                          ),
                          onPressed: () async {
                            final success = await notifier.printTestTicket();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Test ticket printed successfully!'
                                        : 'Failed to print test ticket. Check printer connection.',
                                  ),
                                  backgroundColor: success
                                      ? primaryColor
                                      : redColor,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Sign Out?',
            style: boldTextStyle.copyWith(fontSize: 18, color: blackColor),
          ),
          content: Text(
            'Are you sure you want to end your cashier shift and return to login?',
            style: regularTextStyle.copyWith(fontSize: 14, color: greyColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: semiBoldTextStyle.copyWith(color: greyColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: redColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(authNotifierProvider.notifier).logout();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
              child: Text(
                'Sign Out',
                style: boldTextStyle.copyWith(color: whiteColor),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final printerState = ref.watch(printerNotifierProvider);
    final displayName = currentUser?.name ?? 'Sarah Jenkins';
    final initials = displayName
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .take(2)
        .join();

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: whiteColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Settings & Profile',
          style: boldTextStyle.copyWith(fontSize: 18, color: blackColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: primaryLightColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials.isNotEmpty ? initials : 'CP',
                        style: boldTextStyle.copyWith(
                          fontSize: 20,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: boldTextStyle.copyWith(
                            fontSize: 16,
                            color: blackColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${currentUser?.role.toUpperCase() ?? 'CASHIER'} • @${currentUser?.username ?? 'sarah'}',
                          style: regularTextStyle.copyWith(
                            fontSize: 12,
                            color: greyColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryLightColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Active Register #02',
                            style: semiBoldTextStyle.copyWith(
                              fontSize: 10,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _sectionLabel('HARDWARE & PRINTING'),
            Container(
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _settingsTile(
                    icon: IconsaxPlusLinear.printer,
                    title: 'Thermal Printer',
                    subtitle: printerState.isConnected
                        ? '${printerState.connectedDeviceName ?? 'Connected'} (${printerState.paperSize}) • Tap to configure'
                        : 'No printer connected • Tap to pair Bluetooth',
                    onTap: () => _openPrinterModal(context),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: printerState.isConnected
                                ? primaryLightColor
                                : scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: printerState.isConnected
                                  ? primaryColor
                                  : borderColor,
                            ),
                          ),
                          child: Text(
                            printerState.isConnected
                                ? 'Connected'
                                : (printerState.isConnecting
                                      ? 'Connecting...'
                                      : 'Not Paired'),
                            style: boldTextStyle.copyWith(
                              fontSize: 11,
                              color: printerState.isConnected
                                  ? primaryColor
                                  : greyColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          IconsaxPlusLinear.arrow_right_3,
                          size: 16,
                          color: greyColor,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: Icon(
                      IconsaxPlusLinear.receipt_text,
                      color: greyColor,
                      size: 20,
                    ),
                    activeThumbColor: primaryColor,
                    title: Text(
                      'Auto-print receipt on checkout',
                      style: mediumTextStyle.copyWith(
                        fontSize: 14,
                        color: blackColor,
                      ),
                    ),
                    value: _isAutoPrintReceipt,
                    onChanged: (val) {
                      setState(() {
                        _isAutoPrintReceipt = val;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: Icon(
                      IconsaxPlusLinear.notification_bing,
                      color: greyColor,
                      size: 20,
                    ),
                    activeThumbColor: primaryColor,
                    title: Text(
                      'Cash drawer open sound',
                      style: mediumTextStyle.copyWith(
                        fontSize: 14,
                        color: blackColor,
                      ),
                    ),
                    value: _isCashDrawerBeep,
                    onChanged: (val) {
                      setState(() {
                        _isCashDrawerBeep = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: redColor,
                  side: BorderSide(color: redColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(IconsaxPlusLinear.logout, size: 20, color: redColor),
                label: Text(
                  'End Shift & Sign Out',
                  style: boldTextStyle.copyWith(fontSize: 15, color: redColor),
                ),
                onPressed: _confirmLogout,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: boldTextStyle.copyWith(
          fontSize: 11,
          color: greyColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: greyColor, size: 20),
      title: Text(
        title,
        style: mediumTextStyle.copyWith(fontSize: 14, color: blackColor),
      ),
      subtitle: Text(
        subtitle,
        style: regularTextStyle.copyWith(fontSize: 12, color: greyColor),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
