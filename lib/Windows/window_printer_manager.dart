import 'dart:async';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:win32/win32.dart';
import 'package:win_ble/win_ble.dart';
import 'package:win_ble/win_file.dart';

import 'print_data.dart';
import 'printers_data.dart';

class WindowPrinterManager {
  WindowPrinterManager._privateConstructor();

  static WindowPrinterManager? _instance;

  static WindowPrinterManager get instance {
    _instance ??= WindowPrinterManager._privateConstructor();
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

  final StreamController<List<Printer>> _devicesstream = StreamController<List<Printer>>.broadcast();

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

  // Connect to a BLE device
  Future<bool> connect(Printer device) async {
    if (!isInitialized) {
      throw Exception('WindowBluetoothManager is not initialized');
    }
    await WinBle.connect(device.address!);
    await Future.delayed(const Duration(seconds: 5));
    return await WinBle.isPaired(device.address!);
  }

  // Print data to a BLE device
  Future<void> printData(
    Printer device,
    List<int> bytes, {
    bool longData = false,
  }) async {
    if (device.connectionType == ConnectionType.USB) {
      using((Arena alloc) {
        final printer = RawPrinter(device.name!, alloc);
        printer.printEscPosWin32(bytes);
      });
      return;
    }
    if (!isInitialized) {
      throw Exception('WindowBluetoothManager is not initialized');
    }
    final services = await WinBle.discoverServices(device.address!);
    final service = services.first;
    final characteristics = await WinBle.discoverCharacteristics(
      address: device.address!,
      serviceId: service,
    );
    final characteristic = characteristics.firstWhere((element) => element.properties.write ?? false).uuid;
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
        final data = bytes.sublist(i * mtu, ((i + 1) * mtu) > bytes.length ? bytes.length : ((i + 1) * mtu));
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

  StreamSubscription? _usbSubscription;

  // Getprinters
  void getPrinters({
    Duration refreshDuration = const Duration(seconds: 5),
    List<ConnectionType> connectionTypes = const [
      ConnectionType.BLE,
      ConnectionType.USB,
    ],
  }) async {
    List<Printer> btlist = [];
    if (connectionTypes.contains(ConnectionType.BLE)) {
      await init();
      if (!isInitialized) {
        await init();
      }
      if (!isInitialized) {
        throw Exception(
          'WindowBluetoothManager is not initialized. Try starting the scan again',
        );
      }
      WinBle.stopScanning();
      WinBle.startScanning();
      subscription?.cancel();
      subscription = WinBle.scanStream.listen((device) async {
        btlist.add(Printer(
          address: device.address,
          name: device.name,
          connectionType: ConnectionType.BLE,
          isConnected: await WinBle.isPaired(device.address),
        ));
      });
    }
    List<Printer> list = [];
    if (connectionTypes.contains(ConnectionType.USB)) {
      _usbSubscription?.cancel();
      _usbSubscription = Stream.periodic(refreshDuration, (x) => x).listen((event) async {
        final devices = PrinterNames(PRINTER_ENUM_LOCAL);
        List<Printer> templist = [];
        for (var e in devices.all()) {
          final device = Printer(
            vendorId: e,
            productId: "N/A",
            name: e,
            connectionType: ConnectionType.USB,
            address: e,
            isConnected: true,
          );
          templist.add(device);
        }
        list = templist;
      });
    }
    Stream.periodic(refreshDuration, (x) => x).listen((event) {
      _devicesstream.add(list + btlist);
    });
  }

  turnOnBluetooth() async {
    if (!isInitialized) {
      throw Exception('WindowBluetoothManager is not initialized');
    }
    await WinBle.updateBluetoothState(true);
  }

  Stream<bool> isBleTurnedOnStream = WinBle.bleState.map(
    (event) {
      return event == BleState.On;
    },
  );

  Future<bool> isBleTurnedOn() async {
    if (!isInitialized) {
      throw Exception('WindowBluetoothManager is not initialized');
    }
    return (await WinBle.getBluetoothState()) == BleState.On;
  }
}
