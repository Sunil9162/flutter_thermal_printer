// ignore_for_file: depend_on_referenced_packages

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

  String _ip = '192.168.0.100';
  String _port = '9100';

  List<Printer> printers = [];

  StreamSubscription<List<Printer>>? _devicesStreamSubscription;

  // Get Printer List
  void startScan() async {
    _devicesStreamSubscription?.cancel();
    await _flutterThermalPrinterPlugin.getPrinters(connectionTypes: [
      ConnectionType.USB,
      ConnectionType.BLE,
    ]);
    _devicesStreamSubscription = _flutterThermalPrinterPlugin.devicesStream.listen((List<Printer> event) {
      log(event.map((e) => e.name).toList().toString());
      setState(() {
        printers = event;
        printers.removeWhere((element) => element.name == null || element.name == '');
      });
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      startScan();
    });
  }

  stopScan() {
    _flutterThermalPrinterPlugin.stopScan();
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
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'NETWORK',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _ip,
                decoration: const InputDecoration(
                  labelText: 'Enter IP Address',
                ),
                onChanged: (value) {
                  _ip = value;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _port,
                decoration: const InputDecoration(
                  labelText: 'Enter Port',
                ),
                onChanged: (value) {
                  _port = value;
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final service = FlutterThermalPrinterNetwork(
                          _ip,
                          port: int.parse(_port),
                        );
                        await service.connect();
                        final profile = await CapabilityProfile.load();
                        final generator = Generator(PaperSize.mm80, profile);
                        List<int> bytes = [];
                        if (context.mounted) {
                          bytes = await FlutterThermalPrinter.instance.screenShotWidget(
                            context,
                            generator: generator,
                            widget: receiptWidget("Network"),
                          );
                          bytes += generator.cut();
                          await service.printTicket(bytes);
                        }
                        await service.disconnect();
                      },
                      child: const Text('Test network printer'),
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final service = FlutterThermalPrinterNetwork(_ip, port: int.parse(_port));
                        await service.connect();
                        final bytes = await _generateReceipt();
                        await service.printTicket(bytes);
                        await service.disconnect();
                      },
                      child: const Text('Test network printer widget'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 22),
              Text(
                'USB/BLE',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // startScan();
                        startScan();
                      },
                      child: const Text('Get Printers'),
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // startScan();
                        stopScan();
                      },
                      child: const Text('Stop Scan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: printers.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () async {
                        if (printers[index].isConnected ?? false) {
                          await _flutterThermalPrinterPlugin.disconnect(printers[index]);
                        } else {
                          await _flutterThermalPrinterPlugin.connect(printers[index]);
                        }
                      },
                      title: Text(printers[index].name ?? 'No Name'),
                      subtitle: Text("Connected: ${printers[index].isConnected}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.connect_without_contact),
                        onPressed: () async {
                          await _flutterThermalPrinterPlugin.printWidget(
                            context,
                            printer: printers[index],
                            printOnBle: true,
                            widget: receiptWidget(
                              printers[index].connectionTypeString,
                            ),
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
      ),
    );
  }

  Future<List<int>> _generateReceipt() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];
    bytes += generator.text(
      "Teste Network print",
      styles: const PosStyles(
        bold: true,
        height: PosTextSize.size3,
        width: PosTextSize.size3,
      ),
    );
    bytes += generator.cut();
    return bytes;
  }

  Widget receiptWidget(String printerType) {
    return SizedBox(
      width: 550,
      child: Material(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'FLUTTER THERMAL PRINTER',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(thickness: 2),
              const SizedBox(height: 10),
              _buildReceiptRow('Item', 'Price'),
              const Divider(),
              _buildReceiptRow('Apple', '\$1.00'),
              _buildReceiptRow('Banana', '\$0.50'),
              _buildReceiptRow('Orange', '\$0.75'),
              const Divider(thickness: 2),
              _buildReceiptRow('Total', '\$2.25', isBold: true),
              const SizedBox(height: 20),
              _buildReceiptRow('Printer Type', printerType),
              const SizedBox(height: 50),
              const Center(
                child: Text(
                  'Thank you for your purchase!',
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildReceiptRow(String leftText, String rightText, {bool isBold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          leftText,
          style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
        ),
        Text(
          rightText,
          style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
        ),
      ],
    ),
  );
}
