class NetworkPrintResult {
  const NetworkPrintResult._internal(this.value);
  final int value;
  static const success = NetworkPrintResult._internal(1);
  static const timeout = NetworkPrintResult._internal(2);
  static const printerConnected = NetworkPrintResult._internal(3);
  static const ticketEmpty = NetworkPrintResult._internal(4);
  static const printInProgress = NetworkPrintResult._internal(5);
  static const scanInProgress = NetworkPrintResult._internal(6);

  String get msg {
    if (value == NetworkPrintResult.success.value) {
      return 'Success';
    } else if (value == NetworkPrintResult.timeout.value) {
      return 'Error. Printer connection timeout';
    } else if (value == NetworkPrintResult.printerConnected.value) {
      return 'Error. Printer not connected';
    } else if (value == NetworkPrintResult.ticketEmpty.value) {
      return 'Error. Ticket is empty';
    } else if (value == NetworkPrintResult.printInProgress.value) {
      return 'Error. Another print in progress';
    } else if (value == NetworkPrintResult.scanInProgress.value) {
      return 'Error. Printer scanning in progress';
    } else {
      return 'Unknown error';
    }
  }
}
