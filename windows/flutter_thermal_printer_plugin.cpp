#include "flutter_thermal_printer_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <stdio.h>
#include <usbuf.h>

namespace flutter_thermal_printer {

// static
void FlutterThermalPrinterPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "flutter_thermal_printer",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FlutterThermalPrinterPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

FlutterThermalPrinterPlugin::FlutterThermalPrinterPlugin() {}

FlutterThermalPrinterPlugin::~FlutterThermalPrinterPlugin() {}

void FlutterThermalPrinterPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getPlatformVersion") == 0) {
    std::ostringstream version_stream;
    version_stream << "Windows ";
    if (IsWindows10OrGreater()) {
      version_stream << "10+";
    } else if (IsWindows8OrGreater()) {
      version_stream << "8";
    } else if (IsWindows7OrGreater()) {
      version_stream << "7";
    }
    result->Success(flutter::EncodableValue(version_stream.str()));
  } if (method_call.method_name().compare("getUsbDevicesList") == 0) { 
    // Get the list of USB devices
    std::vector<std::string> usb_devices;
    // Get the list of USB devices
    usb_device_info *devices = NULL;
    int count = get_usb_devices(&devices);
    for (int i = 0; i < count; i++) {
      usb_devices.push_back(devices[i].device_name);
    }
    // return the list of USB devices
    result->Success(flutter::EncodableValue(usb_devices));
  }
  else {
    result->NotImplemented();
  }
}

// // Get List of Printers with return type as List of devices
// void FlutterThermalPrinterPlugin::GetPrinters() {
//   // Get the list of printers
//   std::vector<std::string> printers;
//   // Get the list of printers
//   DWORD needed = 0;
//   DWORD returned = 0;
//   if (!EnumPrinters(PRINTER_ENUM_LOCAL, NULL, 4, NULL, 0, &needed, &returned)) {
//     if (GetLastError() == ERROR_INSUFFICIENT_BUFFER) {
//       PRINTER_INFO_4 *printer_info = (PRINTER_INFO_4 *)malloc(needed);
//       if (EnumPrinters(PRINTER_ENUM_LOCAL, NULL, 4, (LPBYTE)printer_info, needed,
//                        &needed, &returned)) {
//         for (DWORD i = 0; i < returned; i++) {
//           printers.push_back(printer_info[i].pPrinterName);
//         }
//       }
//       free(printer_info);
//     }
//   }
//   // return the list of printers
//   return printers;

// }

}  // namespace flutter_thermal_printer
