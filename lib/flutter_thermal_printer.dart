import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer_platform_interface.dart';
import 'package:flutter_thermal_printer/utils/ble_device_window.dart';

import 'OthersBle/other_ble_manager.dart';
import 'WindowBle/window_ble_manager.dart';

export 'package:esc_pos_utils/esc_pos_utils.dart';
export 'package:flutter_blue_plus/flutter_blue_plus.dart' show BluetoothDevice;

class FlutterThermalPrinter {
  FlutterThermalPrinter._();

  static FlutterThermalPrinter? _instance;

  static FlutterThermalPrinter get instance {
    if (!Platform.isWindows) {
      FlutterBluePlus.setLogLevel(LogLevel.debug);
    }
    _instance ??= FlutterThermalPrinter._();
    return _instance!;
  }

  Future<List<BleDeviceWindow>> getWindowBleDevicesList() async {
    final devices = await WindowBleManager.instance.scan();
    return devices.map((e) => BleDeviceWindow.fromJson(e.toJson())).toList();
  }

  Future<List<BluetoothDevice>> getBleDevices() async {
    final devices = await OtherBleManager.instance.scan();
    return devices;
  }

  Future<bool> connect(dynamic device) async {
    if (device is BleDeviceWindow) {
      return await WindowBleManager.instance.connect(device);
    }
    return await OtherBleManager.instance.connect(device);
  }

  Future<void> printData(
    dynamic device,
    List<int> bytes,
  ) async {
    if (device is BleDeviceWindow) {
      return await WindowBleManager.instance.print(device, bytes);
    }
    return await OtherBleManager.instance.printData(device, bytes);
  }

  Future<String?> getUsbDevices() async {
    return await FlutterThermalPrinterPlatform.instance.getUsbDevices();
  }

  Future<bool> initUsb() async {
    return await FlutterThermalPrinterPlatform.instance.initUsb();
  }
}
