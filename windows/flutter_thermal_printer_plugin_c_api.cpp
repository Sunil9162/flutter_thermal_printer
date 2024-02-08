#include "include/flutter_thermal_printer/flutter_thermal_printer_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_thermal_printer_plugin.h"

void FlutterThermalPrinterPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_thermal_printer::FlutterThermalPrinterPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
