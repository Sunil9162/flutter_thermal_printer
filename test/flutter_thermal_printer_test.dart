import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer_method_channel.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterThermalPrinterPlatform with MockPlatformInterfaceMixin {}

void main() {
  final FlutterThermalPrinterPlatform initialPlatform =
      FlutterThermalPrinterPlatform.instance;

  test('$MethodChannelFlutterThermalPrinter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterThermalPrinter>());
  });

  test('getPlatformVersion', () async {
    expect("42", '42');
  });
}
