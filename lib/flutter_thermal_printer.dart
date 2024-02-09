import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_thermal_printer/utils/ble_device_window.dart';

import 'OthersBle/other_ble_manager.dart';
import 'WindowBle/window_ble_manager.dart';

export 'package:esc_pos_utils/esc_pos_utils.dart';
export 'package:flutter_blue_plus/flutter_blue_plus.dart' show BluetoothDevice;

class FlutterThermalPrinter {
  FlutterThermalPrinter._();

  static FlutterThermalPrinter? _instance;

  static FlutterThermalPrinter get instance {
    FlutterBluePlus.setLogLevel(LogLevel.debug);
    _instance ??= FlutterThermalPrinter._();
    return _instance!;
  }

  Future<List<BleDeviceWindow>> getWindowBleDevicesList() async {
    final devices = await WindowBleManager.instance.scan();
    return devices.map((e) => BleDeviceWindow.fromJson(e.toJson())).toList();
  }

  Stream<List<BluetoothDevice>> get devicesStream =>
      OtherBleManager.instance.devicesStream;

  Future<void> startScan() async {
    await OtherBleManager.instance.startScan();
  }

  Future<void> stopScan() async {
    await OtherBleManager.instance.stopScan();
  }

  Future<bool> connect(BluetoothDevice device) async {
    return await OtherBleManager.instance.connect(device);
  }

  Future<void> printData(
    BluetoothDevice device,
    List<int> bytes,
  ) async {
    return await OtherBleManager.instance.printData(device, bytes);
  }
}
