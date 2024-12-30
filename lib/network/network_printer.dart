import 'dart:io';
import 'network_print_result.dart';

class FlutterThermalPrinterNetwork {
  late String _host;
  int _port = 9100;
  bool _isConnected = false;
  Duration _timeout = const Duration(seconds: 5);
  late Socket _socket;

  FlutterThermalPrinterNetwork(
    String host, {
    int port = 9100,
    Duration timeout = const Duration(seconds: 5),
  }) {
    _host = host;
    _port = port;
    _timeout = timeout;
  }

  Future<NetworkPrintResult> connect({Duration? timeout = const Duration(seconds: 5)}) async {
    try {
      _socket = await Socket.connect(_host, _port, timeout: _timeout);
      _isConnected = true;
      return Future<NetworkPrintResult>.value(NetworkPrintResult.success);
    } catch (e) {
      _isConnected = false;
      return Future<NetworkPrintResult>.value(NetworkPrintResult.timeout);
    }
  }

  Future<NetworkPrintResult> printTicket(List<int> data, {bool isDisconnect = true}) async {
    try {
      if (!_isConnected) {
        await connect();
      }
      _socket.add(data);
      if (isDisconnect) {
        await disconnect();
      }
      return Future<NetworkPrintResult>.value(NetworkPrintResult.success);
    } catch (e) {
      return Future<NetworkPrintResult>.value(NetworkPrintResult.timeout);
    }
  }

  Future<NetworkPrintResult> disconnect({Duration? timeout}) async {
    await _socket.flush();
    await _socket.close();
    _isConnected = false;
    if (timeout != null) {
      await Future.delayed(timeout, () => null);
    }
    return Future<NetworkPrintResult>.value(NetworkPrintResult.success);
  }
}
