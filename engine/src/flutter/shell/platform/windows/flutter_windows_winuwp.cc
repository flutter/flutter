// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/public/flutter_windows.h"

#include <io.h>

#include <algorithm>
#include <cassert>
#include <chrono>
#include <cstdlib>
#include <filesystem>
#include <iostream>
#include <memory>
#include <vector>

#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/plugin_registrar.h"
#include "flutter/shell/platform/common/cpp/incoming_message_dispatcher.h"

FlutterDesktopViewControllerRef FlutterDesktopViewControllerCreate(
    int width,
    int height,
    FlutterDesktopEngineRef engine) {
  // TODO add WINUWP implementation.
  return nullptr;
}

uint64_t FlutterDesktopEngineProcessMessages(FlutterDesktopEngineRef engine) {
  // TODO add WINUWP implementation.
  return 0;
}

void FlutterDesktopPluginRegistrarRegisterTopLevelWindowProcDelegate(
    FlutterDesktopPluginRegistrarRef registrar,
    FlutterDesktopWindowProcCallback delegate,
    void* user_data) {
  // TODO add WINUWP implementation.
}

void FlutterDesktopPluginRegistrarUnregisterTopLevelWindowProcDelegate(
    FlutterDesktopPluginRegistrarRef registrar,
    FlutterDesktopWindowProcCallback delegate) {
  // TODO add WINUWP implementation.
}
