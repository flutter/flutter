#include "include/share_plus/share_plus_windows_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "share_plus_windows_plugin.h"

void SharePlusWindowsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  share_plus_windows::SharePlusWindowsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
