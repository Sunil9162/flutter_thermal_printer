import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:win_ble/win_ble.dart';
import 'package:win_ble/win_file.dart';

import '../utils/ble_device_window.dart';

class WindowBleManager {
  WindowBleManager._privateConstructor();

  static WindowBleManager? _instance;

  static WindowBleManager get instance {
    _instance ??= WindowBleManager._privateConstructor();
    return _instance!;
  }

  static bool isInitialized = false;

  WindowBleManager() {
    init();
  }

  static init() async {
    if (!isInitialized) {
      await WinBle.initialize(serverPath: await WinServer.path()).then((value) {
        isInitialized = true;
      });
    }
  }

  // Find all BLE devices
  Future<List<BleDevice>> scan() async {
    await init();
    log("Init");
    if (!isInitialized) {
      throw Exception('WindowBluetoothManager is not initialized');
    }
    List<BleDevice> devices = [];
    WinBle.startScanning();
    final subscription = WinBle.scanStream.listen((device) {
      devices.add(device);
    });
    await Future.delayed(const Duration(seconds: 10));
    WinBle.stopScanning();
    devices = devices.toSet().toList();
    devices.removeWhere((element) => element.name == '');
    // Remove all device whose name is same

    log(devices.map((e) => jsonEncode(e)).toList().toString());
    subscription.cancel();
    return devices;
  }

  // Connect to a BLE device
  Future<bool> connect(BleDeviceWindow device) async {
    if (!isInitialized) {
      throw Exception('WindowBluetoothManager is not initialized');
    }
    bool isConnected = false;
    final canpair = await WinBle.canPair(device.address);
    if (!canpair) {
      throw Exception('Device cannot be paired');
    }
    await WinBle.connect(device.address);
    await Future.delayed(const Duration(seconds: 5));
    isConnected = await WinBle.isPaired(device.address);
    return isConnected;
  }

  Future print(BleDeviceWindow device, List<int> bytes) async {
    if (!isInitialized) {
      throw Exception('WindowBluetoothManager is not initialized');
    }
    final services = await WinBle.discoverServices(device.address);
    List<BleCharacteristic> characteristics =
        await WinBle.discoverCharacteristics(
      address: device.address,
      serviceId: services[0],
    );
    log(characteristics.map((e) => e.toJson()).toList().toString());
    await WinBle.write(
      address: device.address,
      service: services[0],
      characteristic: characteristics[0].uuid,
      data: Uint8List.fromList(bytes),
      writeWithResponse: true,
    );
  }
}
