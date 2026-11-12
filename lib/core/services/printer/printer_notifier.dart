import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_pos/core/models/pos_models.dart';
import 'package:food_pos/core/services/printer/printer_service.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterState {
  final bool isConnected;
  final bool isConnecting;
  final bool isScanning;
  final String? connectedDeviceName;
  final String? connectedMacAddress;
  final List<BluetoothInfo> availableDevices;
  final String paperSize;
  final String? statusMessage;

  const PrinterState({
    this.isConnected = false,
    this.isConnecting = false,
    this.isScanning = false,
    this.connectedDeviceName,
    this.connectedMacAddress,
    this.availableDevices = const [],
    this.paperSize = '58mm',
    this.statusMessage,
  });

  PrinterState copyWith({
    bool? isConnected,
    bool? isConnecting,
    bool? isScanning,
    String? connectedDeviceName,
    String? connectedMacAddress,
    List<BluetoothInfo>? availableDevices,
    String? paperSize,
    String? statusMessage,
    bool clearConnectedDevice = false,
  }) {
    return PrinterState(
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      isScanning: isScanning ?? this.isScanning,
      connectedDeviceName: clearConnectedDevice
          ? null
          : (connectedDeviceName ?? this.connectedDeviceName),
      connectedMacAddress: clearConnectedDevice
          ? null
          : (connectedMacAddress ?? this.connectedMacAddress),
      availableDevices: availableDevices ?? this.availableDevices,
      paperSize: paperSize ?? this.paperSize,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class PrinterNotifier extends Notifier<PrinterState> {
  static const _prefMacKey = 'saved_printer_mac';
  static const _prefNameKey = 'saved_printer_name';
  static const _prefPaperKey = 'saved_printer_paper';

  final PrinterService _service = PrinterService.instance;

  @override
  PrinterState build() {
    _initPrinter();
    return const PrinterState();
  }

  Future<void> _initPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMac = prefs.getString(_prefMacKey);
    final savedName = prefs.getString(_prefNameKey);
    final savedPaper = prefs.getString(_prefPaperKey) ?? '58mm';

    final connected = await _service.isConnected();

    state = state.copyWith(
      isConnected: connected,
      connectedMacAddress: savedMac,
      connectedDeviceName: savedName,
      paperSize: savedPaper,
      statusMessage: connected ? 'Connected' : 'Disconnected',
    );
  }

  Future<void> scanDevices() async {
    state = state.copyWith(isScanning: true, statusMessage: 'Scanning devices...');

    final isBluetoothOn = await _service.isBluetoothEnabled();
    if (!isBluetoothOn && _service.isSupportedPlatform) {
      state = state.copyWith(
        isScanning: false,
        statusMessage: 'Bluetooth is turned off. Please enable Bluetooth.',
      );
      return;
    }

    final devices = await _service.getPairedDevices();
    state = state.copyWith(
      isScanning: false,
      availableDevices: devices,
      statusMessage: devices.isEmpty
          ? 'No paired Bluetooth devices found.'
          : 'Found ${devices.length} devices',
    );
  }

  Future<bool> connect(BluetoothInfo device) async {
    state = state.copyWith(
      isConnecting: true,
      statusMessage: 'Connecting to ${device.name}...',
    );

    final success = await _service.connect(device.macAdress);

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefMacKey, device.macAdress);
      await prefs.setString(_prefNameKey, device.name);

      state = state.copyWith(
        isConnected: true,
        isConnecting: false,
        connectedDeviceName: device.name,
        connectedMacAddress: device.macAdress,
        statusMessage: 'Connected to ${device.name}',
      );
      return true;
    } else {
      state = state.copyWith(
        isConnected: false,
        isConnecting: false,
        statusMessage: 'Failed to connect to ${device.name}',
      );
      return false;
    }
  }

  Future<void> disconnect() async {
    await _service.disconnect();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefMacKey);
    await prefs.remove(_prefNameKey);

    state = state.copyWith(
      isConnected: false,
      clearConnectedDevice: true,
      statusMessage: 'Printer disconnected',
    );
  }

  Future<void> setPaperSize(String size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefPaperKey, size);
    state = state.copyWith(paperSize: size);
  }

  Future<bool> printTestTicket() async {
    try {
      final paper =
          state.paperSize == '80mm' ? PaperSize.mm80 : PaperSize.mm58;
      final bytes = await _service.generateTestTicketBytes(paperSize: paper);
      return await _service.printBytes(bytes);
    } catch (e) {
      debugPrint('[PRINTER ERROR] Test print failed: $e');
      return false;
    }
  }

  Future<bool> printReceipt(PosTransaction transaction) async {
    try {
      final paper =
          state.paperSize == '80mm' ? PaperSize.mm80 : PaperSize.mm58;
      final bytes = await _service.generateReceiptBytes(
        transaction: transaction,
        paperSize: paper,
      );
      return await _service.printBytes(bytes);
    } catch (e) {
      debugPrint('[PRINTER ERROR] Print receipt failed: $e');
      return false;
    }
  }
}

final printerNotifierProvider =
    NotifierProvider<PrinterNotifier, PrinterState>(PrinterNotifier.new);
