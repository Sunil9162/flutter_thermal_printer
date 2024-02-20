import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';

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

  List<Printer> printers = [];

  StreamSubscription<List<Printer>>? _devicesStreamSubscription;

  // Get Printer List
  void startScan() async {
    _devicesStreamSubscription?.cancel();
    await _flutterThermalPrinterPlugin.getPrinters();
    _devicesStreamSubscription = _flutterThermalPrinterPlugin.devicesStream
        .listen((List<Printer> event) {
      setState(() {
        printers = event;
        printers.removeWhere((element) =>
            element.name == null ||
            element.name == '' ||
            !element.name!.toLowerCase().contains('print'));
      });
    });
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
                startScan();
              },
              child: const Text('Get Printers'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: printers.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () async {
                      final isConnected = await _flutterThermalPrinterPlugin
                          .connect(printers[index]);
                      log("Devices: $isConnected");
                    },
                    title: Text(printers[index].name ?? 'No Name'),
                    subtitle: Text(
                        "VendorId: ${printers[index].address} - Connected: ${printers[index].isConnected}"),
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
                          printers[index],
                          bytes,
                          longData: true,
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
