// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterCodecs.h"

#include "gtest/gtest.h"

FLUTTER_ASSERT_ARC

// Consider adding new tests to FlutterCodecsTests.swift instead.
// These legacy tests are kept until Swift 6.2 becomes available on CI.

TEST(FlutterJSONCodec, ThrowsOnInvalidEncode) {
  NSString* value = [[NSString alloc] initWithBytes:"\xdf\xff"
                                             length:2
                                           encoding:NSUTF16StringEncoding];
  FlutterJSONMessageCodec* codec = [FlutterJSONMessageCodec sharedInstance];
  EXPECT_EXIT([codec encode:value], testing::KilledBySignal(SIGABRT), "failed to convert to UTF8");
}

TEST(FlutterJSONCodec, ThrowsOnInvalidDecode) {
  NSString* value = @"{{{";
  FlutterJSONMessageCodec* codec = [FlutterJSONMessageCodec sharedInstance];
  EXPECT_EXIT([codec decode:[value dataUsingEncoding:value.fastestEncoding]],
              testing::KilledBySignal(SIGABRT), "No string key for value in object around line 1");
}
