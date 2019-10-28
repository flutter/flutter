// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/macos/framework/Headers/FlutterEngine.h"
#include "flutter/shell/platform/darwin/macos/framework/Source/FlutterDartProject_Internal.h"
#include "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
#include "flutter/testing/testing.h"

namespace flutter::testing {

TEST(FlutterEngineTest, FlutterEngineCanLaunch) {
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test"
                                                      project:project
                                       allowHeadlessExecution:true];
  ASSERT_TRUE([engine runWithEntrypoint:@"main"]);
  ASSERT_TRUE(engine.running);
  [engine shutDownEngine];
}

}  // flutter::testing
