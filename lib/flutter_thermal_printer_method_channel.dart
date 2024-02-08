import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_thermal_printer_platform_interface.dart';

/// An implementation of [FlutterThermalPrinterPlatform] that uses method channels.
class MethodChannelFlutterThermalPrinter extends FlutterThermalPrinterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_thermal_printer');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<String?> getUsbDevices() async {
    final data = await methodChannel.invokeMethod("getUsbDevices");
    return data;
  }

  @override
  Future<bool> initUsb() async {
    final data = await methodChannel.invokeMethod("initializeUsb");
    log("Init USB: $data");
    return data ?? false;
  }
}
