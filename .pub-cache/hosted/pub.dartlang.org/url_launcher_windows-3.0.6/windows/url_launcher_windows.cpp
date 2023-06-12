// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "include/url_launcher_windows/url_launcher_windows.h"

#include <flutter/plugin_registrar_windows.h>

#include "url_launcher_plugin.h"

void UrlLauncherWindowsRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  url_launcher_windows::UrlLauncherPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
