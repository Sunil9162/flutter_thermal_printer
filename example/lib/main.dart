// ignore_for_file: depend_on_referenced_packages

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thermal_printer/esc_pos_utils_platform/esc_pos_utils_platform.dart';
// import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
// import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:thermal_printer/thermal_printer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // final _flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;

  // List<Printer> printers = [];

  // StreamSubscription<List<Printer>>? _devicesStreamSubscription;

  // // Get Printer List
  // void startScan() async {
  //   _devicesStreamSubscription?.cancel();
  //   await _flutterThermalPrinterPlugin.getPrinters();
  //   _devicesStreamSubscription = _flutterThermalPrinterPlugin.devicesStream
  //       .listen((List<Printer> event) {
  //     setState(() {
  //       printers = event;
  //       printers.removeWhere((element) =>
  //           element.name == null ||
  //           element.name == '' ||
  //           !element.name!.toLowerCase().contains('print'));
  //     });
  //   });
  // }

  List<PrinterDevice> printers = [];

  void startScan() async {
    PrinterManager.instance.usbPrinterConnector.discovery().listen((event) {
      setState(() {
        printers.add(event);
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
                      final isConnected = await PrinterManager
                          .instance.usbPrinterConnector
                          .connect(UsbPrinterInput(
                        name: printers[index].name,
                        vendorId: printers[index].vendorId,
                        productId: printers[index].productId,
                      ));
                      log("IsConnected");
                    },
                    title: Text(printers[index].name ?? 'No Name'),
                    subtitle: Text(
                        "VendorId: ${printers[index].address} - Connected: ${printers[index].operatingSystem}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.connect_without_contact),
                      onPressed: () async {
                        final profile = await CapabilityProfile.load();
                        final generator = Generator(PaperSize.mm80, profile);
                        List<int> bytes = [];
                        // bytes += generator.text('Hello World');
                        bytes +=
                            generator.text("|||| FLUTTER THERMAL PRINTER ||||");
                        // final screenshot =
                        //     await screenshotController.captureFromWidget(
                        //   receiptWidget(),
                        // );
                        // final img.Image? image = img.decodeImage(screenshot);
                        // final base64Image = base64Encode(img.encodePng(image!));
                        // final img.Image? imgImage = img.decodeImage(
                        //   base64Decode(base64Image),
                        // );
                        // bytes += generator.imageRaster(imgImage!);
                        // bytes += generator.cut();
                        //Break the data into chunks
                        PrinterManager.instance.usbPrinterConnector.send(bytes);
                        const chunkSize = 100;
                        log("Bytes: $bytes");
                        // for (var i = 0; i < bytes.length; i += chunkSize) {
                        //   await Future.delayed(
                        //       const Duration(milliseconds: 100));
                        //   await _flutterThermalPrinterPlugin.printData(
                        //     printers[index],
                        //     bytes.sublist(
                        //       i,
                        //       i + chunkSize > bytes.length
                        //           ? bytes.length
                        //           : i + chunkSize,
                        //     ),
                        //     longData: true,
                        //   );
                        // }
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

  // final ScreenshotController screenshotController = ScreenshotController();
  Widget receiptWidget() {
    return Container(
        padding: const EdgeInsets.all(8),
        color: Colors.white,
        width: 300,
        height: 300,
        child: const Center(
          child: Column(
            children: [
              Text(
                "FLUTTER THERMAL PRINTER",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Hello World",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "This is a test receipt",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ));
  }
}
