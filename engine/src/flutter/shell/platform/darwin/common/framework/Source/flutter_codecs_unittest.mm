// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterCodecs.h"

#include "gtest/gtest.h"

FLUTTER_ASSERT_ARC



TEST(FlutterJSONCodec, CanEncodeAndDecodeArray) {
  NSArray* value = @[ [NSNull null], @"hello", @3.14, @47, @{@"a" : @"nested"} ];
  FlutterJSONMessageCodec* codec = [FlutterJSONMessageCodec sharedInstance];
  NSData* encoded = [codec encode:value];
  NSArray* decoded = [codec decode:encoded];
  ASSERT_TRUE([value isEqualTo:decoded]);
}

TEST(FlutterJSONCodec, CanEncodeAndDecodeDictionary) {
  NSDictionary* value = @{@"a" : @3.14, @"b" : @47, @"c" : [NSNull null], @"d" : @[ @"nested" ]};
  FlutterJSONMessageCodec* codec = [FlutterJSONMessageCodec sharedInstance];
  NSData* encoded = [codec encode:value];
  NSDictionary* decoded = [codec decode:encoded];
  ASSERT_TRUE([value isEqualTo:decoded]);
}
