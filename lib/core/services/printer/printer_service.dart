import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:food_pos/core/models/pos_models.dart';
import 'package:food_pos/features/pos/presentation/screens/pos_screen.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class PrinterService {
  static final PrinterService instance = PrinterService._internal();
  PrinterService._internal();

  /// Periksa apakah platform mendukung Bluetooth printing
  bool get isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Periksa status aktif Bluetooth di perangkat
  Future<bool> isBluetoothEnabled() async {
    if (!isSupportedPlatform) return false;
    try {
      return await PrintBluetoothThermal.bluetoothEnabled;
    } catch (e) {
      debugPrint('[PRINTER ERROR] Failed to check bluetooth: $e');
      return false;
    }
  }

  /// Periksa izin Bluetooth (khusus Android)
  Future<bool> checkPermission() async {
    if (!isSupportedPlatform) return true;
    try {
      return await PrintBluetoothThermal.isPermissionBluetoothGranted;
    } catch (e) {
      debugPrint('[PRINTER ERROR] Failed to check permissions: $e');
      return false;
    }
  }

  /// Dapatkan daftar perangkat Bluetooth yang sudah ter-pairing
  Future<List<BluetoothInfo>> getPairedDevices() async {
    if (!isSupportedPlatform) return [];
    try {
      final List<BluetoothInfo> devices =
          await PrintBluetoothThermal.pairedBluetooths;
      return devices;
    } catch (e) {
      debugPrint('[PRINTER ERROR] Failed to get paired devices: $e');
      return [];
    }
  }

  /// Hubungkan ke printer melalui MAC Address
  Future<bool> connect(String macAddress) async {
    if (!isSupportedPlatform) return false;
    try {
      final bool result =
          await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      debugPrint('[PRINTER] Connect result: $result to $macAddress');
      return result;
    } catch (e) {
      debugPrint('[PRINTER ERROR] Connect failed: $e');
      return false;
    }
  }

  /// Putuskan koneksi printer
  Future<bool> disconnect() async {
    if (!isSupportedPlatform) return true;
    try {
      final bool result = await PrintBluetoothThermal.disconnect;
      debugPrint('[PRINTER] Disconnected: $result');
      return result;
    } catch (e) {
      debugPrint('[PRINTER ERROR] Disconnect failed: $e');
      return false;
    }
  }

  /// Periksa apakah printer saat ini sedang terhubung
  Future<bool> isConnected() async {
    if (!isSupportedPlatform) return false;
    try {
      return await PrintBluetoothThermal.connectionStatus;
    } catch (e) {
      debugPrint('[PRINTER ERROR] Connection status failed: $e');
      return false;
    }
  }

  /// Cetak raw bytes ke printer
  Future<bool> printBytes(List<int> bytes) async {
    if (!isSupportedPlatform) return false;
    try {
      final bool connected = await isConnected();
      if (!connected) {
        debugPrint('[PRINTER ERROR] Cannot print: Printer is not connected');
        return false;
      }
      final bool result = await PrintBluetoothThermal.writeBytes(bytes);
      debugPrint('[PRINTER] Write bytes result: $result');
      return result;
    } catch (e) {
      debugPrint('[PRINTER ERROR] Failed to print bytes: $e');
      return false;
    }
  }

  /// Generate struk uji coba (Test Ticket)
  Future<List<int>> generateTestTicketBytes({
    PaperSize paperSize = PaperSize.mm58,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    bytes += generator.reset();
    bytes += generator.text(
      'GREEN BITES CAFE',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.text(
      'Thermal Printer Test',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      '--------------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Status: CONNECTED OK',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'Paper Size: ${paperSize == PaperSize.mm58 ? '58mm' : '80mm'}',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Date: ${DateTime.now().toString().split('.')[0]}',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      '--------------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Ready for POS Transactions!',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  /// Generate struk transaksi pesanan POS lengkap
  Future<List<int>> generateReceiptBytes({
    required PosTransaction transaction,
    PaperSize paperSize = PaperSize.mm58,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    bytes += generator.reset();

    // 1. Header Struk
    bytes += generator.text(
      'GREEN BITES CAFE',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.text(
      'Jl. Senopati No. 88, Jakarta',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Telp: (021) 555-0199',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      '================================',
      styles: const PosStyles(align: PosAlign.center),
    );

    // 2. Metadata Transaksi
    final dateStr =
        '${transaction.dateTime.year}-${transaction.dateTime.month.toString().padLeft(2, '0')}-${transaction.dateTime.day.toString().padLeft(2, '0')} ${transaction.dateTime.hour.toString().padLeft(2, '0')}:${transaction.dateTime.minute.toString().padLeft(2, '0')}';

    bytes += generator.row([
      PosColumn(
        text: 'Receipt:',
        width: 4,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: transaction.receiptNo,
        width: 8,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Date:', width: 4),
      PosColumn(
        text: dateStr,
        width: 8,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Cashier:', width: 4),
      PosColumn(
        text: transaction.cashierName,
        width: 8,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    if (transaction.tableNo != null && transaction.tableNo!.isNotEmpty) {
      bytes += generator.row([
        PosColumn(text: 'Table:', width: 4),
        PosColumn(
          text: transaction.tableNo!,
          width: 8,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.text(
      '--------------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );

    // 3. Daftar Item Pesanan
    for (final item in transaction.items) {
      bytes += generator.text(
        item.product.name,
        styles: const PosStyles(bold: true),
      );

      final qtyStr = '${item.quantity} x ${formatCurrency(item.unitPrice)}';
      final totalStr = formatCurrency(item.totalPrice);

      bytes += generator.row([
        PosColumn(
          text: '  $qtyStr',
          width: 7,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: totalStr,
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      // Cetak Addon jika ada
      for (final addon in item.selectedAddons) {
        bytes += generator.row([
          PosColumn(
            text: '   + ${addon.name}',
            width: 7,
            styles: const PosStyles(align: PosAlign.left),
          ),
          PosColumn(
            text: addon.price > 0 ? formatCurrency(addon.price) : 'Free',
            width: 5,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

      if (item.notes != null && item.notes!.trim().isNotEmpty) {
        bytes += generator.text(
          '   Note: ${item.notes}',
          styles: const PosStyles(align: PosAlign.left),
        );
      }
    }

    bytes += generator.text(
      '--------------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );

    // 4. Perhitungan Subtotal, Diskon, Pajak, Grand Total
    bytes += generator.row([
      PosColumn(text: 'Subtotal:', width: 6),
      PosColumn(
        text: 'Rp ${formatCurrency(transaction.subtotal)}',
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    if (transaction.discountAmount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Discount:', width: 6),
        PosColumn(
          text: '-Rp ${formatCurrency(transaction.discountAmount)}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.row([
      PosColumn(text: 'Tax (10%):', width: 6),
      PosColumn(
        text: 'Rp ${formatCurrency(transaction.taxAmount)}',
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += generator.text(
      '================================',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.row([
      PosColumn(
        text: 'TOTAL:',
        width: 6,
        styles: const PosStyles(
          bold: true,
          height: PosTextSize.size1,
        ),
      ),
      PosColumn(
        text: 'Rp ${formatCurrency(transaction.grandTotal)}',
        width: 6,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size1,
        ),
      ),
    ]);

    bytes += generator.row([
      PosColumn(text: 'Payment (${transaction.paymentMethod}):', width: 7),
      PosColumn(
        text: 'Rp ${formatCurrency(transaction.cashReceived)}',
        width: 5,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    if (transaction.paymentMethod == 'Cash') {
      bytes += generator.row([
        PosColumn(text: 'Change:', width: 6),
        PosColumn(
          text: 'Rp ${formatCurrency(transaction.changeGiven)}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.text(
      '================================',
      styles: const PosStyles(align: PosAlign.center),
    );

    // 5. Footer Struk
    bytes += generator.text(
      'Thank you for your visit!',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'IG: @greenbites.cafe',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }
}
