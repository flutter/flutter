// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterCodecs.h"
#include "gtest/gtest.h"

TEST(FlutterStringCodec, CanEncodeAndDecodeNil) {
  FlutterStringCodec* codec = [FlutterStringCodec sharedInstance];
  ASSERT_TRUE([codec encode:nil] == nil);
  ASSERT_TRUE([codec decode:nil] == nil);
}

TEST(FlutterStringCodec, CanEncodeAndDecodeEmptyString) {
  FlutterStringCodec* codec = [FlutterStringCodec sharedInstance];
  ASSERT_TRUE([[codec encode:@""] isEqualTo:[NSData data]]);
  ASSERT_TRUE([[codec decode:[NSData data]] isEqualTo:@""]);
}

TEST(FlutterStringCodec, CanEncodeAndDecodeAsciiString) {
  NSString* value = @"hello world";
  FlutterStringCodec* codec = [FlutterStringCodec sharedInstance];
  NSData* encoded = [codec encode:value];
  NSString* decoded = [codec decode:encoded];
  ASSERT_TRUE([value isEqualTo:decoded]);
}

TEST(FlutterStringCodec, CanEncodeAndDecodeNonAsciiString) {
  NSString* value = @"hello \u263A world";
  FlutterStringCodec* codec = [FlutterStringCodec sharedInstance];
  NSData* encoded = [codec encode:value];
  NSString* decoded = [codec decode:encoded];
  ASSERT_TRUE([value isEqualTo:decoded]);
}

TEST(FlutterStringCodec, CanEncodeAndDecodeNonBMPString) {
  NSString* value = @"hello \U0001F602 world";
  FlutterStringCodec* codec = [FlutterStringCodec sharedInstance];
  NSData* encoded = [codec encode:value];
  NSString* decoded = [codec decode:encoded];
  ASSERT_TRUE([value isEqualTo:decoded]);
}

TEST(FlutterJSONCodec, CanEncodeAndDecodeNil) {
  FlutterJSONMessageCodec* codec = [FlutterJSONMessageCodec sharedInstance];
  ASSERT_TRUE([codec encode:nil] == nil);
  ASSERT_TRUE([codec decode:nil] == nil);
}

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
