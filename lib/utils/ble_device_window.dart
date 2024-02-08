import 'dart:convert';
import 'dart:typed_data';

BleDeviceWindow bleDeviceWindowFromJson(String str) =>
    BleDeviceWindow.fromJson(json.decode(str));

String bleDeviceWindowToJson(BleDeviceWindow data) =>
    json.encode(data.toJson());

class BleDeviceWindow {
  BleDeviceWindow({
    required this.address,
    required this.rssi,
    required this.timestamp,
    required this.advType,
    required this.name,
    required this.serviceUuids,
    required this.manufacturerData,
    this.adStructures,
  });

  String address;
  String name;
  String rssi;
  String timestamp;
  String advType;
  Uint8List manufacturerData;
  List<dynamic> serviceUuids;
  List<AdStructure>? adStructures;

  factory BleDeviceWindow.fromJson(Map<String, dynamic> json) =>
      BleDeviceWindow(
        address: json["bluetoothAddress"] ?? "",
        rssi: json["rssi"]?.toString() ?? "",
        timestamp: json["timestamp"]?.toString() ?? "",
        advType: json["advType"] ?? "",
        name: json["localName"] ?? "N/A",
        serviceUuids: json["serviceUuids"],
        manufacturerData: json["manufacturerData"] != null
            ? Uint8List.fromList(List<int>.from(json["manufacturerData"]))
            : Uint8List.fromList(List.empty()),
        adStructures: json["adStructures"] == null
            ? null
            : List<AdStructure>.from(json["adStructures"].map((x) =>
                AdStructure(type: x["type"], data: List<int>.from(x["data"])))),
      );

  Map<String, dynamic> toJson() => {
        "bluetoothAddress": address,
        "rssi": rssi,
        "timestamp": timestamp,
        "advType": advType,
        "localName": name,
        "serviceUuids": serviceUuids.toString(),
        "manufacturerData": manufacturerData.toString(),
      };
}

class AdStructure {
  int type;
  List<int> data;
  AdStructure({required this.type, required this.data});
}
