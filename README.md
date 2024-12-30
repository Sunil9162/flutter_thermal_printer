# flutter_thermal_printer
[![Visits Badge](https://badges.pufler.dev/visits/Sunil9162/flutter_thermal_printer)]([https://badges.pufler.dev](https://badges.pufler.dev/visits/Sunil9162/flutter_thermal_printer))
[![Updated Badge](https://badges.pufler.dev/updated/Sunil9162/flutter_thermal_printer)](https://badges.pufler.dev)

Package for all services for thermal printer in Android, iOS, macOS, Windows.

## Getting Started

This plugin is used to print data on thermal printers with ease across multiple platforms.

## Currently Supported

| Service                        | Android | iOS | macOS | Windows |
| ------------------------------ | :-----: | :-: | :---: | :-----: |
| Bluetooth                      | ✅      | ✅  | ✅    | ✅      |
| USB                            | ✅      |     | ✅    | ✅      |
| BLE                            | ✅      | ✅  | ✅    | ✅      |

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
) {
  // Supports WINDOWS, ANDROID for USB
  // MAC, IOS, ANDROID, WINDOWS for BLUETOOTH.
}

// Refer to Example for Complete code 
```

---

## Bluetooth Services

| Feature                        | Android | iOS | macOS | Windows |
| ------------------------------ | :-----: | :-: | :---: | :-----: |
| Start scanning                 | ✅      | ✅  | ✅    | ✅      |
| Stop scanning                  | ✅      | ✅  | ✅    | ✅      |
| Connect printer                | ✅      | ✅  | ✅    | ✅      |
| Disconnect printer             | ✅      | ✅  | ✅    | ✅      |
| Print data                     | ✅      | ✅  | ✅    | ✅      |
| Print widget                   | ✅      | ✅  | ✅    | ✅      |

---

## USB Services

| Feature                        | Android | iOS | macOS | Windows |
| ------------------------------ | :-----: | :-: | :---: | :-----: |
| Start scanning                 | ✅      |     | ✅    | ✅      |
| Stop scanning                  | ✅      |     |       | ✅      |
| Connect printer                | ✅      |     |       | ✅      |
| Print data                     | ✅      |     |       | ✅      |
| Print widget                   | ✅      |     |       | ✅      |

---

## Printer Model Class

```dart
String? address;
String? name;
ConnectionType? connectionType;
bool? isConnected;
String? vendorId;
String? productId;
```

---

## Additional Features

### Screenshot to Printer
Easily capture and print widgets as images using the `printWidget` method.

### Image Cropping for Long Prints
Handles long data by cropping images and printing them in chunks to ensure seamless printing on devices with limited buffer capacity.

### Connection Type Validation
- Ensures `ConnectionType` compatibility and alerts when unsupported combinations are used. 

### BLE State Monitoring
Provides real-time monitoring for Bluetooth states, ensuring proactive error handling and reconnections.

---

## Notes and Recommendations

- **Windows Users:** Make sure you have the POS-X driver installed on Windows for printer compatibility.  
  Download the driver from [POS-X Drivers](https://pos-x.com/downloads/driver/).

- **Cross-Platform Usage:** Ensure Bluetooth permissions and configurations are set correctly for Android and iOS.

---

## Contributing Guidelines

We welcome contributions to enhance the plugin's functionality!  
To contribute, please fork the repository, make changes, and submit a pull request.  
For bug reports or feature requests, feel free to open an issue.

---

## Contributors

![Contributors Display](https://badges.pufler.dev/contributors/Sunil9162/flutter_thermal_printer?size=50&padding=5&perRow=10&bots=true)

---