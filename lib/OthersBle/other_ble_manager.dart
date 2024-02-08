import 'dart:developer';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class OtherBleManager {
  OtherBleManager._privateConstructor();

  static OtherBleManager? _instance;

  static OtherBleManager get instance {
    _instance ??= OtherBleManager._privateConstructor();
    return _instance!;
  }

  // Find all BLE devices
  Future<List<BluetoothDevice>> scan() async {
    List<ScanResult> results = [];
    await FlutterBluePlus.startScan(
      androidScanMode: AndroidScanMode.lowPower,
      androidUsesFineLocation: true,
      timeout: const Duration(seconds: 5),
    );
    final subscription = FlutterBluePlus.scanResults.listen((device) {
      results.addAll(device);
    });
    await Future.delayed(const Duration(seconds: 5));
    await FlutterBluePlus.stopScan();
    subscription.cancel();
    List<BluetoothDevice> devices = [];
    for (var result in results) {
      if (result.device.platformName == '') {
        continue;
      } else if (devices.any(
          (element) => element.remoteId.str == result.device.remoteId.str)) {
        continue;
      } else {
        devices.add(result.device);
      }
    }
    log('Devices: ${devices.length}');
    devices += FlutterBluePlus.connectedDevices;
    devices += await FlutterBluePlus.systemDevices;
    if (Platform.isAndroid) {
      devices += await FlutterBluePlus.bondedDevices;
    }
    devices = devices.toSet().toList();
    log('Devices: ${devices.map((e) => e.platformName).toList()}');
    return devices;
  }

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
