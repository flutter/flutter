// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterMetalCompositor.h"

#include "flutter/fml/logging.h"

namespace flutter {

FlutterMetalCompositor::FlutterMetalCompositor(FlutterViewController* view_controller)
    : FlutterCompositor(view_controller) {}

bool FlutterMetalCompositor::CreateBackingStore(const FlutterBackingStoreConfig* config,
                                                FlutterBackingStore* backing_store_out) {
  FML_CHECK(false) << "Not implemented, see issue: https://github.com/flutter/flutter/issues/81320";
  return false;
}
bool FlutterMetalCompositor::CollectBackingStore(const FlutterBackingStore* backing_store) {
  FML_CHECK(false) << "Not implemented, see issue: https://github.com/flutter/flutter/issues/81320";
  return false;
}

bool FlutterMetalCompositor::Present(const FlutterLayer** layers, size_t layers_count) {
  FML_CHECK(false) << "Not implemented, see issue: https://github.com/flutter/flutter/issues/81320";
  return false;
}

}  // namespace flutter
