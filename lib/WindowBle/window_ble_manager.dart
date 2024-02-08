import 'package:win_ble/win_ble.dart';

class WindowBleManager {
  WindowBleManager._privateConstructor();

  static WindowBleManager? _instance;

  static WindowBleManager get instance {
    _instance ??= WindowBleManager._privateConstructor();
    return _instance!;
  }

  static bool isInitialized = false;

  WindowBleManager() {
    init();
  }

  static init() async {
    if (!isInitialized) {
      WinBle.initialize(serverPath: 'lib/WindowBle/BLEServer.exe')
          .then((value) {
        isInitialized = true;
      });
    }
  }

  // Find all BLE devices
  Future<List<BleDevice>> scan() async {
    if (!isInitialized) {
      throw Exception('WindowBluetoothManager is not initialized');
    }
    List<BleDevice> devices = [];
    WinBle.startScanning();
    final subscription = WinBle.scanStream.listen((device) {
      devices.add(device);
    });
    await Future.delayed(const Duration(seconds: 5));
    WinBle.stopScanning();
    devices = devices.toSet().toList();
    subscription.cancel();
    return devices;
  }

  // Connect to a BLE device
  Future<bool> connect(BleDevice device) async {
    if (!isInitialized) {
      throw Exception('WindowBluetoothManager is not initialized');
    }
    bool isConnected = false;
    final subscription = WinBle.connectionStream.listen((device) {});
    await WinBle.connect(device.address);
    await Future.delayed(const Duration(seconds: 3));
    subscription.cancel();
    return isConnected;
  }
}
