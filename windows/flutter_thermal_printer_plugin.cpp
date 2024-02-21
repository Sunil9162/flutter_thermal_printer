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
  using flutter::EncodableList;
  using flutter::EncodableMap;
  using flutter::EncodableValue;

  class FlutterThermalPrinterPlugin : public flutter::Plugin
  {
  public:
    static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

    FlutterThermalPrinterPlugin();

    virtual ~FlutterThermalPrinterPlugin();

  private:
    // Called when a method is called on this plugin's channel from Dart.
    void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  };
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
//  void FlutterThermalPrinterPlugin::HandleMethodCall(
//       const flutter::MethodCall<EncodableValue> &method_call,
//       std::unique_ptr<flutter::MethodResult<EncodableValue>> result)
//   {
//     // Get arguments the C++ way
//     const auto *args = std::get_if<EncodableMap>(method_call.arguments());

//     if (method_call.method_name().compare("getUsbDevicesList") == 0)
//     {
//       auto printers = PrintManager::listPrinters();
//       auto list = EncodableList{};
//       for (auto printer : printers)
//       {
//         auto map = EncodableMap{};
//         map[EncodableValue("name")] =
//             EncodableValue(printer.name);
//         map[EncodableValue("model")] =
//             EncodableValue(printer.model);
//         map[EncodableValue("default")] =
//             EncodableValue(printer.default);
//         map[EncodableValue("available")] =
//             EncodableValue(printer.available);
//         list.push_back(map);
//       }

//       return result->Success(list);
//     }
//     else if (method_call.method_name().compare("connect") == 0)
//     {
//       std::string printerName;

//       if (args)
//       {
//         auto name_it = args->find(EncodableValue("name"));
//         if (name_it != args->end())
//         {
//           printerName = std::get<std::string>(name_it->second);
//         }

//         auto success = PrintManager::pickPrinter(printerName);
//         return result->Success(EncodableValue(success));
//       }

//       return result->Success(EncodableValue(false));
//     }
//     else if (method_call.method_name().compare("close") == 0)
//     {
//       auto success = PrintManager::close();
//       return result->Success(EncodableValue(success));
//     }
//     else if (method_call.method_name().compare("printText") == 0)
//     {
//       std::vector<uint8_t> bytes;

//       if (args)
//       {
//         auto bytes_it = args->find(EncodableValue("bytes"));
//         if (bytes_it != args->end())
//         {
//           bytes = std::get<std::vector<uint8_t>>(bytes_it->second);
//         }

//         auto success = PrintManager::printBytes(bytes);
//         return result->Success(EncodableValue(success));
//       }
//     }
//     else if (method_call.method_name().compare("isConnected") == 0)
//     {
//       auto success = true;
//       return result->Success(EncodableValue(success));
//     }
    
//     else
//     {
//       result->NotImplemented();
//     }
//   }

}  // namespace flutter_thermal_printer

// void FlutterPosPrinterPluginRegisterWithRegistrar(
//     FlutterDesktopPluginRegistrarRef registrar)
// {
//   FlutterPosPrinterPlugin::RegisterWithRegistrar(
//       flutter::PluginRegistrarManager::GetInstance()
//           ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
// }