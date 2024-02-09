import 'dart:async';
import 'dart:developer';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';

class OtherBleManager {
  OtherBleManager._privateConstructor();

  static OtherBleManager? _instance;

  static OtherBleManager get instance {
    _instance ??= OtherBleManager._privateConstructor();
    return _instance!;
  }

  final StreamController<List<Printer>> _devicesstream =
      StreamController<List<Printer>>.broadcast();

  Stream<List<Printer>> get devicesStream => _devicesstream.stream;
  StreamSubscription? subscription;

  // Start scanning for BLE devices
  Future<void> startScan() async {
    try {
      await FlutterBluePlus.startScan(
        androidScanMode: AndroidScanMode.lowPower,
        androidUsesFineLocation: true,
      );
      subscription = FlutterBluePlus.scanResults.listen((device) {
        _devicesstream.add(
          device
              .map(
                (e) => Printer(
                  address: e.device.remoteId.str,
                  name: e.device.platformName,
                  connectionType: ConnectionType.BLE,
                  isConnected: e.device.isConnected,
                ),
              )
              .toList(),
        );
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

  Future<bool> connect(Printer device) async {
    try {
      bool isConnected = false;
      final bt = BluetoothDevice.fromId(device.address!);
      await bt.connect();
      final stream = bt.connectionState.listen((event) {
        if (event == BluetoothConnectionState.connected) {
          isConnected = true;
        }
      });
      await Future.delayed(const Duration(seconds: 3));
      await stream.cancel();
      return isConnected;
    } catch (e) {
      return false;
    }
  }

  Future<void> disconnect(Printer device) async {
    try {
      final bt = BluetoothDevice.fromId(device.address!);
      await bt.disconnect();
    } catch (e) {
      log('Failed to disconnect device');
    }
  }

  // Print data to BLE device
  Future<void> printData(
    Printer printer,
    List<int> bytes, {
    bool longData = false,
  }) async {
    try {
      final device = BluetoothDevice.fromId(printer.address!);
      if (!device.isConnected) {
        log('Device is not connected');
        return;
      }
      final services = (await device.discoverServices()).skipWhile((value) =>
          value.characteristics
              .where((element) => element.properties.write)
              .isEmpty);
      BluetoothCharacteristic? writecharacteristic;
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            writecharacteristic = characteristic;
            break;
          }
        }
      }
      if (writecharacteristic == null) {
        log('No write characteristic found');
        return;
      }
      if (longData) {
        int mtu = (await device.mtu.first) - 50;
        if (mtu.isNegative) {
          mtu = 20;
        }
        final numberOfTimes = bytes.length / mtu;
        final numberOfTimesInt = numberOfTimes.toInt();
        int timestoPrint = 0;
        if (numberOfTimes > numberOfTimesInt) {
          timestoPrint = numberOfTimesInt + 1;
        } else {
          timestoPrint = numberOfTimesInt;
        }
        for (var i = 0; i < timestoPrint; i++) {
          final data = bytes.sublist(i * mtu,
              ((i + 1) * mtu) > bytes.length ? bytes.length : ((i + 1) * mtu));
          await writecharacteristic.write(data);
        }
      } else {
        await writecharacteristic.write(bytes);
      }
      return;
    } catch (e) {
      log('Failed to print data to device $e');
    }
  }
}
