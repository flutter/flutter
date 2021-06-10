// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngineTestContext.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterDartProject_Internal.h"

#include "flutter/testing/testing.h"

namespace flutter::testing {

class FlutterEngineTestContext {
 public:
  FlutterEngineTestContext(std::string assets_path = "");
  virtual ~FlutterEngineTestContext();

 private:
  static IsolateCreateCallback();
};

}  // namespace flutter::testing
