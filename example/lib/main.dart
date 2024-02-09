import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/ble_device_window.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;
  List<BleDeviceWindow> windowsBleList = [];
  List<BluetoothDevice> bleDevices = [];

  // Get Bluetooth devices list of Windows
  Future<void> getWindowBleDevicesList() async {
    try {
      final devices =
          await _flutterThermalPrinterPlugin.getWindowBleDevicesList();
      setState(() {
        windowsBleList = devices;
      });
    } on PlatformException {
      print('Failed to get USB devices list.');
    }
  }

  // Get Bluetooth devices list of others
  Future<void> getOthersBleDevicesList() async {
    try {
      await _flutterThermalPrinterPlugin.startScan();
      _flutterThermalPrinterPlugin.devicesStream.listen((event) {
        setState(() {
          bleDevices = event.toSet().toList();
          bleDevices.removeWhere((element) => element.platformName.isEmpty);
        });
      });
    } on PlatformException {
      print('Failed to get USB devices list.');
    }
  }

  // Stop scanning for BLE devices
  Future<void> stopScan() async {
    try {
      await _flutterThermalPrinterPlugin.stopScan();
    } catch (e) {
      log('Failed to stop scanning for devices $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                getWindowBleDevicesList();
              },
              child: const Text('Get Window Ble Devices List'),
            ),
            ElevatedButton(
              onPressed: () {
                if (bleDevices.isNotEmpty) {
                  stopScan();
                }
                getOthersBleDevicesList();
              },
              child: const Text('Get Others Ble Devices List'),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: bleDevices.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          onTap: () async {
                            final isConnected =
                                await _flutterThermalPrinterPlugin
                                    .connect(bleDevices[index]);
                            log("Devices: $isConnected");
                          },
                          title: Text(bleDevices[index].platformName),
                          subtitle: Text(
                              "VendorId: ${bleDevices[index].remoteId.str} - Connected: ${bleDevices[index].isConnected}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.connect_without_contact),
                            onPressed: () async {
                              final profile = await CapabilityProfile.load();
                              final generator =
                                  Generator(PaperSize.mm80, profile);
                              List<int> bytes = [];
                              bytes += generator.text('Hello World');
                              bytes += generator
                                  .text("|||| FLUTTER THERMAL PRINTER ||||");
                              bytes += generator.feed(2);
                              bytes += generator.cut();
                              await _flutterThermalPrinterPlugin.printData(
                                bleDevices[index],
                                bytes,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: bleDevices.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          onTap: () async {
                            final isConnected =
                                await _flutterThermalPrinterPlugin
                                    .connect(bleDevices[index]);
                            log("Devices: $isConnected");
                          },
                          title: Text(bleDevices[index].platformName),
                          subtitle: Text(
                              "VendorId: ${bleDevices[index].remoteId.str} - Connected: ${bleDevices[index].isConnected}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.connect_without_contact),
                            onPressed: () async {
                              final profile = await CapabilityProfile.load();
                              final generator =
                                  Generator(PaperSize.mm80, profile);
                              List<int> bytes = [];
                              bytes += generator.text('Hello World');
                              bytes += generator
                                  .text("|||| FLUTTER THERMAL PRINTER ||||");
                              bytes += generator.feed(2);
                              bytes += generator.cut();
                              await _flutterThermalPrinterPlugin.printData(
                                bleDevices[index],
                                bytes,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
