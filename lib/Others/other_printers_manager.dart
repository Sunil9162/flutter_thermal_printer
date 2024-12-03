import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer_platform_interface.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';

class OtherPrinterManager {
  OtherPrinterManager._privateConstructor();

  static OtherPrinterManager? _instance;

  static OtherPrinterManager get instance {
    _instance ??= OtherPrinterManager._privateConstructor();
    return _instance!;
  }

  final StreamController<List<Printer>> _devicesstream =
      StreamController<List<Printer>>.broadcast();

  Stream<List<Printer>> get devicesStream => _devicesstream.stream;
  StreamSubscription? subscription;

  static String channelName = 'flutter_thermal_printer/events';
  EventChannel eventChannel = EventChannel(channelName);

  // // Start scanning for BLE devices
  // Future<void> startScan() async {
  //   try {
  //     await FlutterBluePlus.startScan();
  //     if (Platform.isAndroid) {
  //       _devicesstream.add((await FlutterBluePlus.systemDevices([]))
  //           .map((e) => Printer(
  //                 address: e.remoteId.str,
  //                 name: e.platformName,
  //                 connectionType: ConnectionType.BLE,
  //                 isConnected: e.isConnected,
  //               ))
  //           .toList());
  //       // Bonded devices
  //       _devicesstream.add((await FlutterBluePlus.bondedDevices)
  //           .map((e) => Printer(
  //                 address: e.remoteId.str,
  //                 name: e.platformName,
  //                 connectionType: ConnectionType.BLE,
  //                 isConnected: e.isConnected,
  //               ))
  //           .toList());
  //     }
  //     subscription = FlutterBluePlus.scanResults.listen((device) {
  //       _devicesstream.add(
  //         device.map(
  //           (e) {
  //             return Printer(
  //               address: e.device.remoteId.str,
  //               name: e.device.platformName,
  //               connectionType: ConnectionType.BLE,
  //               isConnected: e.device.isConnected,
  //             );
  //           },
  //         ).toList(),
  //       );
  //     });
  //   } catch (e) {
  //     log('Failed to start scanning for devices $e');
  //   }
  // }

  // Stop scanning for BLE devices
  Future<void> stopScan({
    bool stopBle = true,
    bool stopUsb = true,
  }) async {
    try {
      if (stopBle) {
        await subscription?.cancel();
        await FlutterBluePlus.stopScan();
      }
      if (stopUsb) {
        await _usbSubscription?.cancel();
      }
    } catch (e) {
      log('Failed to stop scanning for devices $e');
    }
  }

  Future<bool> connect(Printer device) async {
    if (device.connectionType == ConnectionType.USB) {
      return await FlutterThermalPrinterPlatform.instance.connect(device);
    } else {
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
  }

  Future<bool> isConnected(Printer device) async {
    if (device.connectionType == ConnectionType.USB) {
      return await FlutterThermalPrinterPlatform.instance.isConnected(device);
    } else {
      try {
        final bt = BluetoothDevice.fromId(device.address!);
        return bt.isConnected;
      } catch (e) {
        return false;
      }
    }
  }

  Future<void> disconnect(Printer device) async {
    if (device.connectionType == ConnectionType.BLE) {
      try {
        final bt = BluetoothDevice.fromId(device.address!);
        await bt.disconnect();
      } catch (e) {
        log('Failed to disconnect device');
      }
    }
  }

  // Print data to BLE device
  Future<void> printData(
    Printer printer,
    List<int> bytes, {
    bool longData = false,
  }) async {
    if (printer.connectionType == ConnectionType.USB) {
      try {
        await FlutterThermalPrinterPlatform.instance.printText(
          printer,
          Uint8List.fromList(bytes),
          path: printer.address,
        );
      } catch (e) {
        log("FlutterThermalPrinter: Unable to Print Data $e");
      }
    } else {
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
          int mtu = (await device.mtu.first) - 30;
          final numberOfTimes = bytes.length / mtu;
          final numberOfTimesInt = numberOfTimes.toInt();
          int timestoPrint = 0;
          if (numberOfTimes > numberOfTimesInt) {
            timestoPrint = numberOfTimesInt + 1;
          } else {
            timestoPrint = numberOfTimesInt;
          }
          for (var i = 0; i < timestoPrint; i++) {
            final data = bytes.sublist(
                i * mtu,
                ((i + 1) * mtu) > bytes.length
                    ? bytes.length
                    : ((i + 1) * mtu));
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

  // StreamSubscription? _usbSubscription;

  // // USB
  // Future<dynamic> startUsbScan({
  //   Duration refreshDuration = const Duration(seconds: 5),
  // }) async {
  //   if (Platform.isAndroid || Platform.isMacOS) {
  //     _usbSubscription?.cancel();
  //     _usbSubscription =
  //         Stream.periodic(refreshDuration, (x) => x).listen((event) async {
  //       List<Printer> list = [];
  //       final devices =
  //           await FlutterThermalPrinterPlatform.instance.startUsbScan();
  //       for (var e in devices) {
  //         final map =
  //             Map<String, dynamic>.from(e is String ? jsonDecode(e) : e);
  //         final device = Printer(
  //           vendorId: map['vendorId']?.toString(),
  //           productId: map['productId']?.toString(),
  //           name: map['name']?.toString(),
  //           connectionType: ConnectionType.USB,
  //           address: map['bsdPath']?.toString() ?? map['vendorId']?.toString(),
  //           isConnected: false,
  //         );
  //         final isConnected =
  //             await FlutterThermalPrinterPlatform.instance.isConnected(device);
  //         device.isConnected = isConnected;
  //         list.add(device);
  //       }
  //       _devicesstream.add(list);
  //     });
  //     return;
  //   } else {
  //     throw Exception('Unsupported Platform');
  //   }
  // }

  StreamSubscription? refresher;

  final List<Printer> _devices = [];
  StreamSubscription? _usbSubscription;

  // Get Printers from BT and USB
  Future<void> getPrinters({
    List<ConnectionType> connectionTypes = const [
      ConnectionType.BLE,
      ConnectionType.USB,
    ],
    bool androidUsesFineLocation = false,
  }) async {
    if (connectionTypes.isEmpty) {
      throw Exception('No connection type provided');
    }
    try {
      if (connectionTypes.contains(ConnectionType.USB)) {
        final devices =
            await FlutterThermalPrinterPlatform.instance.startUsbScan();
        List<Printer> templist = [];
        for (var e in devices) {
          final map =
              Map<String, dynamic>.from(e is String ? jsonDecode(e) : e);
          final device = Printer(
            vendorId: map['vendorId'].toString(),
            productId: map['productId'].toString(),
            name: map['name'],
            connectionType: ConnectionType.USB,
            address: map['vendorId'].toString(),
            isConnected: map['connected'] ?? false,
          );
          final isConnected =
              await FlutterThermalPrinterPlatform.instance.isConnected(device);
          device.isConnected = isConnected;
          templist.add(device);
        }
        _devices.addAll(templist);
        _usbSubscription?.cancel();
        _usbSubscription = eventChannel.receiveBroadcastStream().listen(
          (event) {
            final map = Map<String, dynamic>.from(event);
            final device = Printer(
              vendorId: map['vendorId'].toString(),
              productId: map['productId'].toString(),
              name: map['name'],
              connectionType: ConnectionType.USB,
              address: map['vendorId'].toString(),
              isConnected: map['connected'] ?? false,
            );
            final index =
                _devices.indexWhere((i) => i.address == device.address);
            if (index == -1) {
              _devices.add(device);
            } else {
              _devices[index] = device;
            }
            sortDevices();
          },
        );
        sortDevices();
      }
    } catch (e) {
      log("$e [USB Connection]");
    }
    try {
      if (connectionTypes.contains(ConnectionType.BLE)) {
        if (subscription != null) {
          subscription?.cancel();
          subscription = null;
        }
        if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
          await FlutterBluePlus.turnOn();
        }
        await FlutterBluePlus.stopScan();
        await FlutterBluePlus.startScan(
          androidUsesFineLocation: androidUsesFineLocation,
        );
        final systemDevices = (await FlutterBluePlus.systemDevices([]))
            .map(
              (e) => Printer(
                address: e.remoteId.str,
                name: e.platformName,
                connectionType: ConnectionType.BLE,
                isConnected: e.isConnected,
              ),
            )
            .toList();
        _devices.addAll(systemDevices);
        if (Platform.isAndroid) {
          // Bonded devices
          final bondedDevices = (await FlutterBluePlus.bondedDevices)
              .map((e) => Printer(
                    address: e.remoteId.str,
                    name: e.platformName,
                    connectionType: ConnectionType.BLE,
                    isConnected: e.isConnected,
                  ))
              .toList();
          _devices.addAll(bondedDevices);
        }
        sortDevices();
        subscription = FlutterBluePlus.scanResults.listen((device) {
          final devices = device.map(
            (e) {
              return Printer(
                address: e.device.remoteId.str,
                name: e.device.platformName,
                connectionType: ConnectionType.BLE,
                isConnected: e.device.isConnected,
              );
            },
          ).toList();
          devices.removeWhere(
            (element) => element.name == null || element.name == '',
          );
          //  If the device is already in the list, update it
          for (var e in devices) {
            final index = _devices.indexWhere((i) => i.address == e.address);
            if (index < 0) {
              _devices.add(e);
            } else {
              _devices[index] = e;
            }
            sortDevices();
          }
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  void sortDevices() {
    _devices
        .removeWhere((element) => element.name == null || element.name == '');
    // remove items having same vendorId
    _devices.removeWhere((element) =>
        _devices.indexWhere((i) => i.vendorId == element.vendorId) !=
        _devices.lastIndexOf(element));
    final list = _devices.toSet().toList();
    _devicesstream.add(list);
  }

  Future<void> turnOnBluetooth() async {
    await FlutterBluePlus.turnOn();
  }

  Stream<bool> get isBleTurnedOnStream {
    return FlutterBluePlus.adapterState.map(
      (event) {
        return event == BluetoothAdapterState.on;
      },
    );
  }
}
