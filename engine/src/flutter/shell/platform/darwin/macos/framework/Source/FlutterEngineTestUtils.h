// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterEngine.h"

#import <OCMock/OCMock.h>
#include "flutter/testing/test_dart_native_resolver.h"
#include "gtest/gtest.h"

namespace flutter::testing {

class FlutterEngineTest : public ::testing::Test {
 public:
  FlutterEngineTest();

  FlutterEngine* GetFlutterEngine() { return engine_; };

  void SetUp() override;
  void TearDown() override;

  void AddNativeCallback(const char* name, Dart_NativeFunction function);

  static void IsolateCreateCallback(void* user_data);

 private:
  inline static std::shared_ptr<TestDartNativeResolver> native_resolver_;

  FlutterDartProject* project_;
  FlutterEngine* engine_;

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterEngineTest);
};

// Returns a mock FlutterEngine that is able to work in environments
// without a real pasteboard.
id CreateMockFlutterEngine(NSString* pasteboardString);

}  // namespace flutter::testing
