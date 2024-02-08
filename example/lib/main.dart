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
      final devices = await _flutterThermalPrinterPlugin.getBleDevices();
      setState(() {
        bleDevices = devices;
      });
    } on PlatformException {
      print('Failed to get USB devices list.');
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
                getOthersBleDevicesList();
              },
              child: const Text('Get Others Ble Devices List'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: windowsBleList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () async {
                      final isConnected = await _flutterThermalPrinterPlugin
                          .connect(windowsBleList[index]);
                      log("Devices: $isConnected");
                    },
                    title: Text(windowsBleList[index].name),
                    subtitle:
                        Text("VendorId: ${windowsBleList[index].address} "),
                    trailing: IconButton(
                      icon: const Icon(Icons.connect_without_contact),
                      onPressed: () async {
                        final profile = await CapabilityProfile.load();
                        final generator = Generator(PaperSize.mm80, profile);
                        List<int> bytes = [];
                        bytes += generator.text('Hello World');
                        bytes +=
                            generator.text("|||| FLUTTER THERMAL PRINTER ||||");
                        bytes += generator.feed(2);
                        bytes += generator.cut();
                        await _flutterThermalPrinterPlugin.printData(
                          windowsBleList[index],
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
    );
  }
}
