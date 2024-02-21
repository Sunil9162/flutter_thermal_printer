# flutter_thermal_printer

Package for all services for thermal printer in android, ios, macos, windows.

## Getting Started

This plugin is used to print data on thermal printer.

## Currently Supported

| Service                        | Android | iOS | macOS | Windows |
| ------------------------------ | :-----: | :-: | :---: |:-----:  |
| Bluetooth                      | ✅      | ✅  | ✅    | ✅      |
| USB                            | ✅      |     |       |         |

```dart
 final _flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;

  List<Printer> bleDevices = [];

  StreamSubscription<List<Printer>>? _devicesStreamSubscription;

  //  Start scanning for BLE devices
  Future<void> startScan() async {
    try {
      await _flutterThermalPrinterPlugin.startScan();
      _devicesStreamSubscription =
          _flutterThermalPrinterPlugin.devicesStream.listen((event) {
        setState(() {
          bleDevices = event.map((e) => Printer.fromJson(e.toJson())).toList();
          bleDevices.removeWhere(
            (element) => element.name == null || element.name!.isEmpty,
          );
        });
      });
    } catch (e) {
      log('Failed to start scanning for devices $e');
    }
  }

  // Stop scanning for BLE devices
  Future<void> stopScan() async {
    try {
      _devicesStreamSubscription?.cancel();
      await _flutterThermalPrinterPlugin.stopScan();
    } catch (e) {
      log('Failed to stop scanning for devices $e');
    }
  }

 // Usb Devices List
  Future<void> getUsbDevicesList() async {
    try {
      await _flutterThermalPrinterPlugin.getUsbDevices();
      _devicesStreamSubscription?.cancel();
      _devicesStreamSubscription =
          _flutterThermalPrinterPlugin.devicesStream.listen((event) {
        setState(() {
          printers = event;
        });
      });
    } catch (e) {
      log('Failed to get usb devices list $e');
    }
  }
```

## Bluetooth Services

| Feature                        | Android | iOS | macOS | Windows |
| ------------------------------ | :-----: | :-: | :---: |:-----:  |
| Start scanning                 | ✅      | ✅  | ✅    | ✅      |
| stop scanning                  | ✅      | ✅  | ✅    | ✅      |
| connect printer                | ✅      | ✅  | ✅    | ✅      |
| disconnect printer             | ✅      | ✅  | ✅    | ✅      |
| print data                     | ✅      | ✅  | ✅    | ✅      |

## USB Services

| Feature                        | Android | iOS | macOS | Windows |
| ------------------------------ | :-----: | :-: | :---: |:-----:  |
| Start scanning                 | ✅      |     |       |         |
| stop scanning                  | ✅      |     |       |         |
| connect printer                | ✅      |     |       |         |
| print data                     | ✅      |     |       |         |

## Printer Model Class
```dart
 String? address;
  String? name;
  ConnectionType? connectionType;
  bool? isConnected;
  String? vendorId;
  String? productId;

// Enum ConnectionType
enum ConnectionType {
  BLE,
  USB,
}

// Additional Functions
getPrinters(
  refreshDuration: Duration,
  connectionTypes: List<ConnectionType>,
){
  
}

```