import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:win_ble/win_ble.dart';
import 'package:win_ble/win_file.dart';

class WindowBleManager {
  WindowBleManager._privateConstructor();

  static WindowBleManager? _instance;

  static WindowBleManager get instance {
    _instance ??= WindowBleManager._privateConstructor();
    return _instance!;
  }

  static bool isInitialized = false;

  static init() async {
    if (!isInitialized) {
      WinBle.initialize(serverPath: await WinServer.path()).then((value) {
        isInitialized = true;
      });
    }
  }

  final StreamController<List<Printer>> _devicesstream =
      StreamController<List<Printer>>.broadcast();

  Stream<List<Printer>> get devicesStream => _devicesstream.stream;

  // Stop scanning for BLE devices
  Future<void> stopscan() async {
    if (!isInitialized) {
      throw Exception('WindowBluetoothManager is not initialized');
    }
    WinBle.stopScanning();
    subscription?.cancel();
  }

  StreamSubscription? subscription;

  // Find all BLE devices
  Future<void> startscan() async {
    if (!isInitialized) {
      await init();
    }
    if (!isInitialized) {
      throw Exception(
        'WindowBluetoothManager is not initialized. Try starting the scan again',
      );
    }
    List<Printer> devices = [];
    WinBle.startScanning();
    subscription = WinBle.scanStream.listen((device) async {
      devices.add(Printer(
        address: device.address,
        name: device.name,
        connectionType: ConnectionType.BLE,
        isConnected: await WinBle.isPaired(device.address),
      ));
    });
  }

  // Connect to a BLE device
  Future<bool> connect(Printer device) async {
    if (!isInitialized) {
      throw Exception('WindowBluetoothManager is not initialized');
    }
    bool isConnected = false;
    final subscription = WinBle.connectionStream.listen((device) {});
    await WinBle.connect(device.address!);
    await Future.delayed(const Duration(seconds: 3));
    subscription.cancel();
    return isConnected;
  }

  // Print data to a BLE device
  Future<void> printData(
    Printer device,
    List<int> bytes, {
    bool longData = false,
  }) async {
    if (!isInitialized) {
      throw Exception('WindowBluetoothManager is not initialized');
    }
    final services = await WinBle.discoverServices(device.address!);
    final service = services.first;
    final characteristics = await WinBle.discoverCharacteristics(
      address: device.address!,
      serviceId: service,
    );
    final characteristic = characteristics
        .firstWhere((element) => element.properties.write ?? false)
        .uuid;
    final mtusize = await WinBle.getMaxMtuSize(device.address!);
    if (longData) {
      int mtu = mtusize - 50;
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
        await WinBle.write(
          address: device.address!,
          service: service,
          characteristic: characteristic,
          data: Uint8List.fromList(data),
          writeWithResponse: false,
        );
      }
    } else {
      await WinBle.write(
        address: device.address!,
        service: service,
        characteristic: characteristic,
        data: Uint8List.fromList(bytes),
        writeWithResponse: false,
      );
    }
  }
}
