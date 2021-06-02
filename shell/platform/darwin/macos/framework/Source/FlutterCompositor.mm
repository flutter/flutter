// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterCompositor.h"
#include "flutter/fml/logging.h"

namespace flutter {

FlutterCompositor::FlutterCompositor(FlutterViewController* view_controller) {
  FML_CHECK(view_controller != nullptr) << "FlutterViewController* cannot be nullptr";

  view_controller_ = view_controller;
}

void FlutterCompositor::SetPresentCallback(
    const FlutterCompositor::PresentCallback& present_callback) {
  present_callback_ = present_callback;
}

}  // namespace flutter
