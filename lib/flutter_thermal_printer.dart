import 'dart:async';
import 'dart:io';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_thermal_printer/Windows/window_printer_manager.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:image/image.dart' as img;
import 'package:screenshot/screenshot.dart';

import 'Others/other_printers_manager.dart';

export 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
export 'package:flutter_blue_plus/flutter_blue_plus.dart'
    show BluetoothDevice, BluetoothConnectionState;

class FlutterThermalPrinter {
  FlutterThermalPrinter._();

  static FlutterThermalPrinter? _instance;

  static FlutterThermalPrinter get instance {
    FlutterBluePlus.setLogLevel(LogLevel.debug);
    _instance ??= FlutterThermalPrinter._();
    return _instance!;
  }

  Stream<List<Printer>> get devicesStream {
    if (Platform.isWindows) {
      return WindowPrinterManager.instance.devicesStream;
    } else {
      return OtherPrinterManager.instance.devicesStream;
    }
  }

  // Future<void> startScan() async {
  //   if (Platform.isWindows) {
  //     await WindowPrinterManager.instance.startscan();
  //   } else {
  //     await OtherPrinterManager.instance.startScan();
  //   }
  // }

  // Future<void> stopScan() async {
  //   if (Platform.isWindows) {
  //     await WindowPrinterManager.instance.stopscan();
  //   } else {
  //     await OtherPrinterManager.instance.stopScan();
  //   }
  // }

  Future<bool> connect(Printer device) async {
    if (Platform.isWindows) {
      return await WindowPrinterManager.instance.connect(device);
    } else {
      return await OtherPrinterManager.instance.connect(device);
    }
  }

  Future<void> disconnect(Printer device) async {
    if (Platform.isWindows) {
      // await WindowBleManager.instance.disc(device);
    } else {
      await OtherPrinterManager.instance.disconnect(device);
    }
  }

  Future<void> printData(
    Printer device,
    List<int> bytes, {
    bool longData = false,
  }) async {
    if (Platform.isWindows) {
      return await WindowPrinterManager.instance.printData(
        device,
        bytes,
        longData: longData,
      );
    } else {
      return await OtherPrinterManager.instance.printData(
        device,
        bytes,
        longData: longData,
      );
    }
  }

  // Future<void> getUsbDevices() async {
  //   if (Platform.isWindows) {
  //     WindowPrinterManager.instance.getPrinters(
  //       connectionTypes: [
  //         ConnectionType.USB,
  //       ],
  //     );
  //   } else {
  //     await OtherPrinterManager.instance.startUsbScan();
  //   }
  // }

  Future<void> getPrinters({
    Duration refreshDuration = const Duration(seconds: 2),
    List<ConnectionType> connectionTypes = const [
      ConnectionType.USB,
      ConnectionType.BLE
    ],
  }) async {
    if (Platform.isWindows) {
      WindowPrinterManager.instance.getPrinters(
        refreshDuration: refreshDuration,
        connectionTypes: connectionTypes,
      );
    } else {
      OtherPrinterManager.instance.getPrinters(
        connectionTypes: connectionTypes,
      );
    }
  }

  Future<void> stopScan() async {
    if (Platform.isWindows) {
      WindowPrinterManager.instance.stopscan();
    } else {
      OtherPrinterManager.instance.stopScan();
    }
  }

  // Turn On Bluetooth
  Future<void> turnOnBluetooth() async {
    if (Platform.isWindows) {
      await WindowPrinterManager.instance.turnOnBluetooth();
    } else {
      await OtherPrinterManager.instance.turnOnBluetooth();
    }
  }

  Stream<bool> get isBleTurnedOnStream {
    if (Platform.isWindows) {
      return WindowPrinterManager.instance.isBleTurnedOnStream;
    } else {
      return OtherPrinterManager.instance.isBleTurnedOnStream;
    }
  }

  // Get BleState
  Future<bool> isBleTurnedOn() async {
    if (Platform.isWindows) {
      return await WindowPrinterManager.instance.isBleTurnedOn();
    } else {
      return FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on;
    }
  }

  Future<void> printWidget(
    BuildContext context, {
    required Printer printer,
    required Widget widget,
    Duration delay = const Duration(milliseconds: 100),
    PaperSize paperSize = PaperSize.mm80,
    CapabilityProfile? profile,
    bool printOnBle = false,
  }) async {
    if (printOnBle == false && printer.connectionType == ConnectionType.BLE) {
      throw Exception(
        "Image printing on BLE Printer may be slow or fail. Still Need try? set printOnBle to true",
      );
    }
    final controller = ScreenshotController();
    await controller.captureFromLongWidget(
      widget,
      pixelRatio: View.of(context).devicePixelRatio,
      delay: delay,
    );
    final image = await controller.capture();

    if (Platform.isWindows) {
      await printData(
        printer,
        image!.toList(),
        longData: true,
      );
    } else {
      CapabilityProfile profile0 = profile ?? await CapabilityProfile.load();
      final ticket = Generator(paperSize, profile0);
      final imagebytes = img.decodeImage(image!);
      final totalheight = imagebytes!.height;
      final totalwidth = imagebytes.width;
      final timestoCut = totalheight ~/ 30;
      for (var i = 0; i < timestoCut; i++) {
        final croppedImage = img.copyCrop(
          imagebytes,
          x: 0,
          y: i * 30,
          width: totalwidth,
          height: 30,
        );
        final raster = ticket.imageRaster(
          croppedImage,
          imageFn: PosImageFn.bitImageRaster,
        );
        await FlutterThermalPrinter.instance.printData(
          printer,
          raster,
          longData: true,
        );
      }
    }
  }
}
