import 'dart:async';
import 'dart:developer';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class OtherBleManager {
  OtherBleManager._privateConstructor();

  static OtherBleManager? _instance;

  static OtherBleManager get instance {
    _instance ??= OtherBleManager._privateConstructor();
    return _instance!;
  }

  final StreamController<List<BluetoothDevice>> _devicesstream =
      StreamController<List<BluetoothDevice>>.broadcast();

  Stream<List<BluetoothDevice>> get devicesStream => _devicesstream.stream;
  StreamSubscription? subscription;

  // Start scanning for BLE devices
  Future<void> startScan() async {
    try {
      await FlutterBluePlus.startScan(
        androidScanMode: AndroidScanMode.lowPower,
        androidUsesFineLocation: true,
      );
      subscription = FlutterBluePlus.scanResults.listen((device) {
        _devicesstream.add(device.map((e) => e.device).toList());
      });
    } catch (e) {
      log('Failed to start scanning for devices $e');
    }
  }

  // Stop scanning for BLE devices
  Future<void> stopScan() async {
    try {
      await subscription?.cancel();
      await FlutterBluePlus.stopScan();
    } catch (e) {
      log('Failed to stop scanning for devices $e');
    }
  }

  // Find all BLE devices
  // Stream<List<BluetoothDevice>> scan()   {
  //   List<ScanResult> results = [];
  //   await FlutterBluePlus.startScan(
  //     androidScanMode: AndroidScanMode.lowPower,
  //     androidUsesFineLocation: true,
  //     timeout: const Duration(seconds: 5),
  //   );
  //   final subscription = FlutterBluePlus.scanResults.listen((device) {
  //     results.addAll(device);
  //   });
  //   List<BluetoothDevice> devices = [];
  //   for (var result in results) {
  //     if (result.device.platformName == '') {
  //       continue;
  //     } else if (devices.any(
  //         (element) => element.remoteId.str == result.device.remoteId.str)) {
  //       continue;
  //     } else {
  //       devices.add(result.device);
  //     }
  //   }
  //   log('Devices: ${devices.length}');
  //   devices += FlutterBluePlus.connectedDevices;
  //   devices += await FlutterBluePlus.systemDevices;
  //   if (Platform.isAndroid) {
  //     devices += await FlutterBluePlus.bondedDevices;
  //   }
  //   devices = devices.toSet().toList();
  //   log('Devices: ${devices.map((e) => e.platformName).toList()}');
  //   return devices;
  // }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      if (device.isConnected) {
        log('Device is already connected');
        return true;
      }
      bool isConnected = false;
      await device.connect();
      final subscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.connected) {
          isConnected = true;
        }
      });
      await subscription.cancel();
      return isConnected;
    } catch (e) {
      return false;
    }
  }

  Future<void> disconnect(BluetoothDevice device) async {
    try {
      if (!device.isConnected) {
        log('Device is already disconnected');
        return;
      }
      await device.disconnect();
    } catch (e) {
      log('Failed to disconnect device');
    }
  }

  // Print data to BLE device
  Future<void> printData(
    BluetoothDevice device,
    List<int> bytes,
  ) async {
    try {
      if (!device.isConnected) {
        log('Device is not connected');
        return;
      }
      final services = (await device.discoverServices()).skipWhile((value) =>
          value.characteristics
              .where((element) => element.properties.write)
              .isEmpty);
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            await characteristic.write(bytes);
            log('Printed data to device');
            return;
          }
        }
      }
    } catch (e) {
      log('Failed to print data to device $e');
    }
  }
}
