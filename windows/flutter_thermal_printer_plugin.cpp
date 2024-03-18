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
#include <iostream>
#include <vector>
#include <wbemidl.h>
#pragma comment(lib, "wbemuuid.lib")
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
      std::vector<USBDeviceInfo> devices = GetUSBDevices();
      EncodableList devicesList;
      for (auto &device : devices)
      {
        EncodableMap deviceMap;
        deviceMap.insert(std::make_pair(EncodableValue("deviceID"), EncodableValue(device.deviceID)));
        deviceMap.insert(std::make_pair(EncodableValue("pnpDeviceID"), EncodableValue(device.pnpDeviceID)));
        deviceMap.insert(std::make_pair(EncodableValue("description"), EncodableValue(device.description)));
        devicesList.push_back(EncodableValue(deviceMap));
      }
      result->Success(flutter::EncodableValue(devicesList));
    }
    else
    {
      result->NotImplemented();
    }
  }
  std::vector<USBDeviceInfo> GetUSBDevices()
  {
    std::vector<USBDeviceInfo> devices;

    HRESULT hr;
    IWbemLocator *pLoc = nullptr;
    IWbemServices *pSvc = nullptr;
    IEnumWbemClassObject *pEnumerator = nullptr;

    // Initialize COM
    hr = CoInitializeEx(0, COINIT_MULTITHREADED);
    if (FAILED(hr))
    {
      std::cerr << "Failed to initialize COM library. Error code: " << hr << std::endl;
      return devices;
    }

    // Initialize security
    hr = CoInitializeSecurity(
        nullptr,
        -1,
        nullptr,
        nullptr,
        RPC_C_AUTHN_LEVEL_DEFAULT,
        RPC_C_IMP_LEVEL_IMPERSONATE,
        nullptr,
        EOAC_NONE,
        nullptr);
    if (FAILED(hr))
    {
      CoUninitialize();
      std::cerr << "Failed to initialize security. Error code: " << hr << std::endl;
      return devices;
    }

    // Obtain the initial locator to WMI
    hr = CoCreateInstance(CLSID_WbemLocator, nullptr, CLSCTX_INPROC_SERVER, IID_IWbemLocator, reinterpret_cast<LPVOID *>(&pLoc));
    if (FAILED(hr))
    {
      CoUninitialize();
      std::cerr << "Failed to create IWbemLocator object. Error code: " << hr << std::endl;
      return devices;
    }

    // Connect to WMI through the IWbemLocator::ConnectServer method
    hr = pLoc->ConnectServer(
        _bstr_t(L"ROOT\\CIMV2"), // Namespace
        nullptr,                 // User name
        nullptr,                 // User password
        0,                       // Locale
        nullptr,                 // Security flags
        0,                       // Authority
        0,                       // Context object
        &pSvc);                  // IWbemServices proxy
    if (FAILED(hr))
    {
      pLoc->Release();
      CoUninitialize();
      std::cerr << "Failed to connect to WMI namespace. Error code: " << hr << std::endl;
      return devices;
    }

    // Set security levels on the proxy
    hr = CoSetProxyBlanket(
        pSvc,
        RPC_C_AUTHN_WINNT,
        RPC_C_AUTHZ_NONE,
        nullptr,
        RPC_C_AUTHN_LEVEL_CALL,
        RPC_C_IMP_LEVEL_IMPERSONATE,
        nullptr,
        EOAC_NONE);
    if (FAILED(hr))
    {
      pSvc->Release();
      pLoc->Release();
      CoUninitialize();
      std::cerr << "Failed to set proxy blanket. Error code: " << hr << std::endl;
      return devices;
    }

    // Use the IWbemServices pointer to make requests of WMI
    hr = pSvc->ExecQuery(
        bstr_t("WQL"),
        bstr_t("SELECT * FROM Win32_USBHub"),
        WBEM_FLAG_FORWARD_ONLY | WBEM_FLAG_RETURN_IMMEDIATELY,
        nullptr,
        &pEnumerator);
    if (FAILED(hr))
    {
      pSvc->Release();
      pLoc->Release();
      CoUninitialize();
      std::cerr << "Query for Win32_USBHub failed. Error code: " << hr << std::endl;
      return devices;
    }

    // Iterate over the query results
    while (pEnumerator)
    {
      IWbemClassObject *pclsObj = nullptr;
      ULONG uReturn = 0;

      hr = pEnumerator->Next(WBEM_INFINITE, 1, &pclsObj, &uReturn);
      if (0 == uReturn)
      {
        break;
      }

      VARIANT vtProp;

      // Get the value of the "DeviceID" property
      hr = pclsObj->Get(L"DeviceID", 0, &vtProp, 0, 0);
      std::string deviceID;
      if (SUCCEEDED(hr))
      {
        deviceID = _bstr_t(vtProp.bstrVal);
        VariantClear(&vtProp);
      }

      // Get the value of the "PNPDeviceID" property
      hr = pclsObj->Get(L"PNPDeviceID", 0, &vtProp, 0, 0);
      std::string pnpDeviceID;
      if (SUCCEEDED(hr))
      {
        pnpDeviceID = _bstr_t(vtProp.bstrVal);
        VariantClear(&vtProp);
      }

      // Get the value of the "Description" property
      hr = pclsObj->Get(L"Description", 0, &vtProp, 0, 0);
      std::string description;
      if (SUCCEEDED(hr))
      {
        description = _bstr_t(vtProp.bstrVal);
        VariantClear(&vtProp);
      }

      devices.push_back({deviceID, pnpDeviceID, description});

      pclsObj->Release();
    }

    pEnumerator->Release();
    pSvc->Release();
    pLoc->Release();
    CoUninitialize();

    return devices;
  }

  struct USBDeviceInfo
  {
    std::string deviceID;
    std::string pnpDeviceID;
    std::string description;
  };

} // namespace flutter_thermal_printer
