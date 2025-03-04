import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_thermal_printer/Windows/window_printer_manager.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:image/image.dart' as img;
import 'package:screenshot/screenshot.dart';

import 'Others/other_printers_manager.dart';

export 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
export 'package:flutter_blue_plus/flutter_blue_plus.dart' show BluetoothDevice, BluetoothConnectionState;
export 'package:flutter_thermal_printer/network/network_printer.dart';

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

  Future<void> getPrinters({
    Duration refreshDuration = const Duration(seconds: 2),
    List<ConnectionType> connectionTypes = const [ConnectionType.USB, ConnectionType.BLE],
    bool androidUsesFineLocation = false,
  }) async {
    if (Platform.isWindows) {
      WindowPrinterManager.instance.getPrinters(
        refreshDuration: refreshDuration,
        connectionTypes: connectionTypes,
      );
    } else {
      OtherPrinterManager.instance.getPrinters(
        connectionTypes: connectionTypes,
        androidUsesFineLocation: androidUsesFineLocation,
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

  Future<Uint8List> screenShotWidget(
    BuildContext context, {
    required Widget widget,
    Duration delay = const Duration(milliseconds: 100),
    int? customWidth,
    PaperSize paperSize = PaperSize.mm80,
    Generator? generator,
  }) async {
    final controller = ScreenshotController();
    final image = await controller.captureFromLongWidget(widget, pixelRatio: View.of(context).devicePixelRatio, delay: delay);
    Generator? generator0;
    if (generator == null) {
      final profile = await CapabilityProfile.load();
      generator0 = Generator(paperSize, profile);
    } else {
      final profile = await CapabilityProfile.load();
      generator0 = Generator(paperSize, profile);
    }
    img.Image? imagebytes = img.decodeImage(image);

    if (customWidth != null) {
      final width = _makeDivisibleBy8(customWidth);
      imagebytes = img.copyResize(imagebytes!, width: width);
    }

    imagebytes = _buildImageRasterAvaliable(imagebytes!);

    imagebytes = img.grayscale(imagebytes);
    final totalheight = imagebytes.height;
    final totalwidth = imagebytes.width;
    final timestoCut = totalheight ~/ 30;
    List<int> bytes = [];
    for (var i = 0; i < timestoCut; i++) {
      final croppedImage = img.copyCrop(
        imagebytes,
        x: 0,
        y: i * 30,
        width: totalwidth,
        height: 30,
      );
      final raster = generator0.imageRaster(
        croppedImage,
        imageFn: PosImageFn.bitImageRaster,
      );
      bytes += raster;
    }
    return Uint8List.fromList(bytes);
  }

  img.Image _buildImageRasterAvaliable(img.Image image) {
    final avaliable = image.width % 8 == 0;
    if (avaliable) {
      return image;
    }
    final newWidth = _makeDivisibleBy8(image.width);
    return img.copyResize(image, width: newWidth);
  }

  int _makeDivisibleBy8(int number) {
    if (number % 8 == 0) {
      return number;
    }
    return number + (8 - (number % 8));
  }

  Future<void> printWidget(
    BuildContext context, {
    required Printer printer,
    required Widget widget,
    Duration delay = const Duration(milliseconds: 100),
    PaperSize paperSize = PaperSize.mm80,
    CapabilityProfile? profile,
    bool printOnBle = false,
    bool cutAfterPrinted = true,
  }) async {
    // if (printOnBle == false && printer.connectionType == ConnectionType.BLE) {
    //   throw Exception(
    //     "Image printing on BLE Printer may be slow or fail. Still Need try? set printOnBle to true",
    //   );
    // }
    final controller = ScreenshotController();

    final image = await controller.captureFromLongWidget(
      widget,
      pixelRatio: View.of(context).devicePixelRatio,
      delay: delay,
    );
    if (printer.connectionType == ConnectionType.BLE) {
      CapabilityProfile profile0 = profile ?? await CapabilityProfile.load();
      final ticket = Generator(paperSize, profile0);
      img.Image? imagebytes = img.decodeImage(image);
      imagebytes = _buildImageRasterAvaliable(imagebytes!);
      final raster = ticket.imageRaster(
        imagebytes,
        imageFn: PosImageFn.bitImageRaster,
      );
      await FlutterThermalPrinter.instance.printData(
        printer,
        raster,
        longData: true,
      );
      return;
    }
    if (Platform.isWindows) {
      await printData(
        printer,
        image.toList(),
        longData: true,
      );
    } else {
      CapabilityProfile profile0 = profile ?? await CapabilityProfile.load();
      final ticket = Generator(paperSize, profile0);
      img.Image? imagebytes = img.decodeImage(image);
      imagebytes = _buildImageRasterAvaliable(imagebytes!);
      final totalheight = imagebytes.height;
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
      if (cutAfterPrinted) {
        await FlutterThermalPrinter.instance.printData(
          printer,
          ticket.cut(),
          longData: true,
        );
      }
    }
  }

  Future<void> printImageBytes({
    required Uint8List imageBytes,
    required Printer printer,
    Duration delay = const Duration(milliseconds: 100),
    PaperSize paperSize = PaperSize.mm80,
    CapabilityProfile? profile,
    Generator? generator,
    bool printOnBle = false,
    int? customWidth,
  }) async {
    if (printOnBle == false && printer.connectionType == ConnectionType.BLE) {
      throw Exception(
        "Image printing on BLE Printer may be slow or fail. Still Need try? set printOnBle to true",
      );
    }

    if (Platform.isWindows) {
      await printData(
        printer,
        imageBytes.toList(),
        longData: true,
      );
    } else {
      CapabilityProfile profile0 = profile ?? await CapabilityProfile.load();
      final ticket = generator ?? Generator(paperSize, profile0);
      img.Image? imagebytes = img.decodeImage(imageBytes);
      if (customWidth != null) {
        final width = _makeDivisibleBy8(customWidth);
        imagebytes = img.copyResize(imagebytes!, width: width);
      }
      imagebytes = _buildImageRasterAvaliable(imagebytes!);
      final totalheight = imagebytes.height;
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
