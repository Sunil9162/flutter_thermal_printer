import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_thermal_printer_method_channel.dart';

abstract class FlutterThermalPrinterPlatform extends PlatformInterface {
  FlutterThermalPrinterPlatform() : super(token: _token);
  static final Object _token = Object();
  static FlutterThermalPrinterPlatform _instance =
      MethodChannelFlutterThermalPrinter();
  static FlutterThermalPrinterPlatform get instance => _instance;

  static set instance(FlutterThermalPrinterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> getUsbDevices() {
    throw UnimplementedError("getUsbDevice() has not been implemented");
  }

  Future<bool> initUsb() {
    throw UnimplementedError('initUsb() has not been implemented');
  }
}
