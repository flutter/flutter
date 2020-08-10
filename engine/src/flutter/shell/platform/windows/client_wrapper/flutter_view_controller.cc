// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "include/flutter/flutter_view_controller.h"

#include <algorithm>
#include <iostream>

namespace flutter {

FlutterViewController::FlutterViewController(int width,
                                             int height,
                                             const DartProject& project) {
  engine_ = std::make_unique<FlutterEngine>(project);
  controller_ = FlutterDesktopViewControllerCreate(width, height,
                                                   engine_->RelinquishEngine());
  if (!controller_) {
    std::cerr << "Failed to create view controller." << std::endl;
    return;
  }
  view_ = std::make_unique<FlutterView>(
      FlutterDesktopViewControllerGetView(controller_));
}

FlutterViewController::~FlutterViewController() {
  if (controller_) {
    FlutterDesktopViewControllerDestroy(controller_);
  }
}

std::chrono::nanoseconds FlutterViewController::ProcessMessages() {
  return engine_->ProcessMessages();
}

FlutterDesktopPluginRegistrarRef FlutterViewController::GetRegistrarForPlugin(
    const std::string& plugin_name) {
  return engine_->GetRegistrarForPlugin(plugin_name);
}

}  // namespace flutter
