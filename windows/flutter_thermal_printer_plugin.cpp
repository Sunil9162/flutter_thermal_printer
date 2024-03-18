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
#include <string>
#include <list>

namespace flutter_thermal_printer
{
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
    void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  };

  void FlutterThermalPrinterPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarWindows *registrar)
  {
    auto channel =
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "flutter_thermal_printer",
            &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<FlutterThermalPrinterPlugin>();

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto &call, auto result)
        {
          plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    registrar->AddPlugin(std::move(plugin));
  }

  FlutterThermalPrinterPlugin::FlutterThermalPrinterPlugin() {}

  FlutterThermalPrinterPlugin::~FlutterThermalPrinterPlugin() {}

  void FlutterThermalPrinterPlugin::HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
  {
    if (method_call.method_name().compare("getPlatformVersion") == 0)
    {
      std::ostringstream version_stream;
      version_stream << "Windows ";
      if (IsWindows10OrGreater())
      {
        version_stream << "10+";
      }
      else if (IsWindows8OrGreater())
      {
        version_stream << "8";
      }
      else if (IsWindows7OrGreater())
      {
        version_stream << "7";
      }
      result->Success(flutter::EncodableValue(version_stream.str()));
    }
    if (method_call.method_name().compare("getUsbDevicesList") == 0)
    {
      // Call the function to get the USB devices list from the Program class
      List<USBDeviceInfo> usbDevices = GetUSBDevices();
      // Create a list of EncodableMap to store the USB devices list
      EncodableList usbDevicesList;
      // Loop through the USB devices list and add each device to the usbDevicesList
      for (auto usbDevice : usbDevices)
      {
        EncodableMap usbDeviceMap;
        usbDeviceMap["DeviceID"] = usbDevice.DeviceID;
        usbDeviceMap["PnpDeviceID"] = usbDevice.PnpDeviceID;
        usbDeviceMap["Description"] = usbDevice.Description;
        usbDevicesList.push_back(EncodableValue(usbDeviceMap));
      }
      // Return the usbDevicesList
      result->Success(usbDevicesList);
    }
    else
    {
      result->NotImplemented();
    }
  }

  static List<USBDeviceInfo> GetUSBDevices()
  {
    List<USBDeviceInfo> devices = new List<USBDeviceInfo>();

    using var searcher = new ManagementObjectSearcher(
        @"Select * From Win32_USBHub");
    using ManagementObjectCollection collection = searcher.Get();

    foreach (var device in collection)
    {
      devices.Add(new USBDeviceInfo(
          (string)device.GetPropertyValue("DeviceID"),
          (string)device.GetPropertyValue("PNPDeviceID"),
          (string)device.GetPropertyValue("Description")));
    }
    return devices;
  }
} // namespace flutter_thermal_printer
