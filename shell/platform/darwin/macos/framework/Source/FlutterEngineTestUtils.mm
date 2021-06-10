
// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngineTestUtils.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterDartProject_Internal.h"

#include "flutter/testing/testing.h"

namespace flutter::testing {

FlutterEngineTest::FlutterEngineTest() = default;

void FlutterEngineTest::SetUp() {
  native_resolver_ = std::make_shared<TestDartNativeResolver>();
  NSString* fixtures = @(testing::GetFixturesPath());
  project_ = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  project_.rootIsolateCreateCallback = FlutterEngineTest::IsolateCreateCallback;
  engine_ = [[FlutterEngine alloc] initWithName:@"test"
                                        project:project_
                         allowHeadlessExecution:true];
}

void FlutterEngineTest::TearDown() {
  [engine_ shutDownEngine];
  engine_ = nil;
  native_resolver_.reset();
}

void FlutterEngineTest::IsolateCreateCallback(void* user_data) {
  native_resolver_->SetNativeResolverForIsolate();
}

void FlutterEngineTest::AddNativeCallback(const char* name, Dart_NativeFunction function) {
  native_resolver_->AddNativeCallback({name}, function);
}

}  // namespace flutter::testing
