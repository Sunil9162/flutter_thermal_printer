import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_thermal_printer/Windows/window_printer_manager.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';

import 'Others/other_printers_manager.dart';

export 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
export 'package:flutter_blue_plus/flutter_blue_plus.dart' show BluetoothDevice;

class FlutterThermalPrinter {
  FlutterThermalPrinter._();

  static FlutterThermalPrinter? _instance;

  static FlutterThermalPrinter get instance {
    FlutterBluePlus.setLogLevel(LogLevel.debug);
    _instance ??= FlutterThermalPrinter._();
    return _instance!;
  }

  Stream<List<Printer>> get devicesStream {
    if (Platform.isWindows) {
      return WindowPrinterManager.instance.devicesStream;
    } else {
      return OtherPrinterManager.instance.devicesStream;
    }
  }

  Future<void> startScan() async {
    if (Platform.isWindows) {
      await WindowPrinterManager.instance.startscan();
    } else {
      await OtherPrinterManager.instance.startScan();
    }
  }

  Future<void> stopScan() async {
    if (Platform.isWindows) {
      await WindowPrinterManager.instance.stopscan();
    } else {
      await OtherPrinterManager.instance.stopScan();
    }
  }

  Future<bool> connect(Printer device) async {
    if (Platform.isWindows) {
      return await WindowPrinterManager.instance.connect(device);
    } else {
      return await OtherPrinterManager.instance.connect(device);
    }
  }

  Future<void> disconnect(Printer device) async {
    if (Platform.isWindows) {
      // await WindowBleManager.instance.disc(device);
    } else {
      await OtherPrinterManager.instance.disconnect(device);
    }
  }

  Future<void> printData(
    Printer device,
    List<int> bytes, {
    bool longData = false,
  }) async {
    if (Platform.isWindows) {
      return await WindowPrinterManager.instance.printData(
        device,
        bytes,
        longData: longData,
      );
    } else {
      return await OtherPrinterManager.instance.printData(
        device,
        bytes,
        longData: longData,
      );
    }
  }

  Future<void> getUsbDevices() async {
    if (Platform.isWindows) {
      WindowPrinterManager.instance.getPrinters(
        connectionTypes: [
          ConnectionType.USB,
        ],
      );
    } else {
      await OtherPrinterManager.instance.startUsbScan();
    }
  }

  Future<void> getPrinters({
    Duration refreshDuration = const Duration(seconds: 2),
    List<ConnectionType> connectionTypes = const [
      ConnectionType.USB,
      ConnectionType.BLE
    ],
  }) async {
    if (Platform.isWindows) {
      WindowPrinterManager.instance.getPrinters(
        refreshDuration: refreshDuration,
        connectionTypes: connectionTypes,
      );
    } else {
      OtherPrinterManager.instance.getPrinters(
        refreshDuration: refreshDuration,
        connectionTypes: connectionTypes,
      );
    }
  }

  Future<dynamic> convertImageToGrayscale(Uint8List? value) async {
    if (Platform.isWindows) {
      // return WindowBleManager.instance.convertImageToGrayscale(value);
      return null;
    } else {
      return OtherPrinterManager.instance.convertImageToGrayscale(value);
    }
  }
}
