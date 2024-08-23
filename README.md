# flutter_thermal_printer
[![Visits Badge](https://badges.pufler.dev/visits/Sunil9162/flutter_thermal_printer)]([https://badges.pufler.dev](https://badges.pufler.dev/visits/Sunil9162/flutter_thermal_printer))
[![Updated Badge](https://badges.pufler.dev/updated/Sunil9162/flutter_thermal_printer)](https://badges.pufler.dev)

Package for all services for thermal printer in android, ios, macos, windows.

## Getting Started

This plugin is used to print data on thermal printer.

## Currently Supported

| Service                        | Android | iOS | macOS | Windows |
| ------------------------------ | :-----: | :-: | :---: |:-----:  |
| Bluetooth                      | ✅      | ✅  | ✅    | ✅     |
| USB                            | ✅      |     | ✅    | ✅     |

```dart

 final _flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;


  // Enum ConnectionType
  enum ConnectionType {
    BLE,
    USB,
  }

  // Additional Functions
  // Recommended Function for getting printers
  getPrinters(
    refreshDuration: Duration,
    connectionTypes: List<ConnectionType>,
  ){
    // Supports WINDOWS, ANDROID for USB
    // MAC, IOS, ANDROID, WINDOWS for BLUETOOTH.
  }


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
| Start scanning                 | ✅      |     |  ✅   | ✅      |
| stop scanning                  | ✅      |     |       | ✅      |
| connect printer                | ✅      |     |       | ✅      |
| print data                     | ✅      |     |       | ✅      |


## Printer Model Class
```dart
 String? address;
  String? name;
  ConnectionType? connectionType;
  bool? isConnected;
  String? vendorId;
  String? productId;



```

## Take Care OF

Printers of Widows will only work if you have the POS-X driver installed on Windows.

Download Driver from Here:

https://pos-x.com/download/thermal-receipt-printer-driver-2/




## Contributers

![Contributors Display](https://badges.pufler.dev/contributors/Sunil9162/flutter_thermal_printer?size=50&padding=5&perRow=10&bots=true)