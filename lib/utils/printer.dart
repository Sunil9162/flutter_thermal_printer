// ignore_for_file: constant_identifier_names

class Printer {
  String? address;
  String? name;
  ConnectionType? connectionType;
  bool? isConnected;
  String? vendorId;
  String? productId;

  Printer({
    this.address,
    this.name,
    this.connectionType,
    this.isConnected,
    this.vendorId,
    this.productId,
  });

  Printer.fromJson(Map<String, dynamic> json) {
    address = json['address'];
    name =
        json['connectionType'] == 'BLE' ? json['platformName'] : json['name'];
    connectionType = json['connectionType'] == 'BLE'
        ? ConnectionType.BLE
        : ConnectionType.USB;
    isConnected = json['isConnected'];
    vendorId = json['vendorId'];
    productId = json['productId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['address'] = address;
    if (connectionType == ConnectionType.BLE) {
      data['platformName'] = name;
    } else {
      data['name'] = name;
    }
    data['connectionType'] =
        connectionType == ConnectionType.BLE ? 'BLE' : 'USB';
    data['isConnected'] = isConnected;
    data['vendorId'] = vendorId;
    data['productId'] = productId;
    return data;
  }
}

enum ConnectionType {
  BLE,
  USB,
}
