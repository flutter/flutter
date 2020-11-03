// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterEngine.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterDartProject_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/testing/testing.h"

namespace flutter::testing {

namespace {
// Returns an engine configured for the text fixture resource configuration.
FlutterEngine* CreateTestEngine() {
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  return [[FlutterEngine alloc] initWithName:@"test" project:project allowHeadlessExecution:true];
}
}  // namespace

TEST(FlutterEngine, CanLaunch) {
  FlutterEngine* engine = CreateTestEngine();
  EXPECT_TRUE([engine runWithEntrypoint:@"main"]);
  EXPECT_TRUE(engine.running);
  [engine shutDownEngine];
}

TEST(FlutterEngine, MessengerSend) {
  FlutterEngine* engine = CreateTestEngine();
  EXPECT_TRUE([engine runWithEntrypoint:@"main"]);

  NSData* test_message = [@"a message" dataUsingEncoding:NSUTF8StringEncoding];
  bool called = false;

  engine.embedderAPI.SendPlatformMessage = MOCK_ENGINE_PROC(
      SendPlatformMessage, ([&called, test_message](auto engine, auto message) {
        called = true;
        EXPECT_STREQ(message->channel, "test");
        EXPECT_EQ(memcmp(message->message, test_message.bytes, message->message_size), 0);
        return kSuccess;
      }));

  [engine.binaryMessenger sendOnChannel:@"test" message:test_message];
  EXPECT_TRUE(called);

  [engine shutDownEngine];
}

}  // flutter::testing
