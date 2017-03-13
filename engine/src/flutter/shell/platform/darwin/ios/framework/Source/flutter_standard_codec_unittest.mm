// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterCodecs.h"
#include "gtest/gtest.h"

TEST(FlutterStandardCodec, CanEncodeAndDecodeNil) {
  FlutterStandardMessageCodec* codec =
      [FlutterStandardMessageCodec sharedInstance];
  NSData* encoded = [codec encode:nil];
  id decoded = [codec decode:encoded];
  ASSERT_TRUE(decoded == nil);
}

TEST(FlutterStandardCodec, CanEncodeAndDecodeNSNull) {
  FlutterStandardMessageCodec* codec =
      [FlutterStandardMessageCodec sharedInstance];
  NSData* encoded = [codec encode:[NSNull null]];
  id decoded = [codec decode:encoded];
  ASSERT_TRUE(decoded == nil);
}

TEST(FlutterStandardCodec, CanEncodeAndDecodeInt32) {
  FlutterStandardMessageCodec* codec =
      [FlutterStandardMessageCodec sharedInstance];
  NSData* encoded = [codec encode:@-78];
  NSNumber* decoded = [codec decode:encoded];
  ASSERT_TRUE([@-78 isEqualTo:decoded]);
}

TEST(FlutterStandardCodec, CanEncodeAndDecodeInt64) {
  FlutterStandardMessageCodec* codec =
      [FlutterStandardMessageCodec sharedInstance];
  NSData* encoded = [codec encode:@78000000001];
  NSNumber* decoded = [codec decode:encoded];
  ASSERT_TRUE([@78000000001 isEqualTo:decoded]);
}

TEST(FlutterStandardCodec, CanEncodeAndDecodeFloat64) {
  FlutterStandardMessageCodec* codec =
      [FlutterStandardMessageCodec sharedInstance];
  NSData* encoded = [codec encode:@3.14];
  NSNumber* decoded = [codec decode:encoded];
  ASSERT_TRUE([@3.14 isEqualTo:decoded]);
}

TEST(FlutterStandardCodec, CanEncodeAndDecodeString) {
  FlutterStandardMessageCodec* codec =
      [FlutterStandardMessageCodec sharedInstance];
  NSData* encoded = [codec encode:@"hello world"];
  NSString* decoded = [codec decode:encoded];
  ASSERT_TRUE([@"hello world" isEqualTo:decoded]);
}

TEST(FlutterStandardCodec, CanEncodeAndDecodeStringWithNonAsciiCodePoint) {
  FlutterStandardMessageCodec* codec =
      [FlutterStandardMessageCodec sharedInstance];
  NSData* encoded = [codec encode:@"hello \u263A world"];
  NSString* decoded = [codec decode:encoded];
  ASSERT_TRUE([@"hello \u263A world" isEqualTo:decoded]);
}

TEST(FlutterStandardCodec, CanEncodeAndDecodeStringWithNonBMPCodePoint) {
  FlutterStandardMessageCodec* codec =
      [FlutterStandardMessageCodec sharedInstance];
  NSData* encoded = [codec encode:@"hello \U0001F602 world"];
  NSString* decoded = [codec decode:encoded];
  ASSERT_TRUE([@"hello \U0001F602 world" isEqualTo:decoded]);
}

TEST(FlutterStandardCodec, CanEncodeAndDecodeBigInteger) {
  FlutterStandardMessageCodec* codec =
      [FlutterStandardMessageCodec sharedInstance];
  NSData* encoded =
      [codec encode:[FlutterStandardBigInteger
                        bigIntegerWithHex:@"-abcdef120902390239021321abfdec"]];
  FlutterStandardBigInteger* decoded = [codec decode:encoded];
  ASSERT_TRUE([@"-abcdef120902390239021321abfdec" isEqualTo:decoded.hex]);
}

TEST(FlutterStandardCodec, CanEncodeAndDecodeArray) {
  NSArray* value =
      @[ [NSNull null], @"hello", @3.14, @47,
         @{ @42 : @"nested" } ];
  FlutterStandardMessageCodec* codec =
      [FlutterStandardMessageCodec sharedInstance];
  NSData* encoded = [codec encode:value];
  NSArray* decoded = [codec decode:encoded];
  ASSERT_TRUE([value isEqualTo:decoded]);
}

TEST(FlutterStandardCodec, CanEncodeAndDecodeDictionary) {
  NSDictionary* value = @{
    @"a" : @3.14,
    @"b" : @47,
    [NSNull null] : [NSNull null],
    @3.14 : @[ @"nested" ]
  };
  FlutterStandardMessageCodec* codec =
      [FlutterStandardMessageCodec sharedInstance];
  NSData* encoded = [codec encode:value];
  NSDictionary* decoded = [codec decode:encoded];
  ASSERT_TRUE([value isEqualTo:decoded]);
}

TEST(FlutterStandardCodec, CanEncodeAndDecodeByteArray) {
  char bytes[4] = {0xBA, 0x5E, 0xBA, 0x11};
  NSData* data = [NSData dataWithBytes:bytes length:4];
  FlutterStandardTypedData* value =
      [FlutterStandardTypedData typedDataWithBytes:data];
  FlutterStandardMessageCodec* codec =
      [FlutterStandardMessageCodec sharedInstance];
  NSData* encoded = [codec encode:value];
  FlutterStandardTypedData* decoded = [codec decode:encoded];
  ASSERT_TRUE(decoded.type == FlutterStandardDataTypeUInt8);
  ASSERT_TRUE(decoded.elementCount == 4);
  ASSERT_TRUE(decoded.elementSize == 1);
  ASSERT_TRUE([data isEqualTo:decoded.data]);
}

TEST(FlutterStandardCodec, CanEncodeAndDecodeInt32Array) {
  char bytes[8] = {0xBA, 0x5E, 0xBA, 0x11, 0xff, 0xff, 0xff, 0xff};
  NSData* data = [NSData dataWithBytes:bytes length:8];
  FlutterStandardTypedData* value =
      [FlutterStandardTypedData typedDataWithInt32:data];
  FlutterStandardMessageCodec* codec =
      [FlutterStandardMessageCodec sharedInstance];
  NSData* encoded = [codec encode:value];
  FlutterStandardTypedData* decoded = [codec decode:encoded];
  ASSERT_TRUE(decoded.type == FlutterStandardDataTypeInt32);
  ASSERT_TRUE(decoded.elementCount == 2);
  ASSERT_TRUE(decoded.elementSize == 4);
  ASSERT_TRUE([data isEqualTo:decoded.data]);
}

TEST(FlutterStandardCodec, CanEncodeAndDecodeInt64Array) {
  char bytes[8] = {0xBA, 0x5E, 0xBA, 0x11, 0xff, 0xff, 0xff, 0xff};
  NSData* data = [NSData dataWithBytes:bytes length:8];
  FlutterStandardTypedData* value =
      [FlutterStandardTypedData typedDataWithInt64:data];
  FlutterStandardMessageCodec* codec =
      [FlutterStandardMessageCodec sharedInstance];
  NSData* encoded = [codec encode:value];
  FlutterStandardTypedData* decoded = [codec decode:encoded];
  ASSERT_TRUE(decoded.type == FlutterStandardDataTypeInt64);
  ASSERT_TRUE(decoded.elementCount == 1);
  ASSERT_TRUE(decoded.elementSize == 8);
  ASSERT_TRUE([data isEqualTo:decoded.data]);
}

TEST(FlutterStandardCodec, CanEncodeAndDecodeFloat64Array) {
  char bytes[16] = {0xBA, 0x5E, 0xBA, 0x11, 0xff, 0xff, 0xff, 0xff,
                    0xBA, 0x5E, 0xBA, 0x11, 0xff, 0xff, 0xff, 0xff};
  NSData* data = [NSData dataWithBytes:bytes length:16];
  FlutterStandardTypedData* value =
      [FlutterStandardTypedData typedDataWithFloat64:data];
  FlutterStandardMessageCodec* codec =
      [FlutterStandardMessageCodec sharedInstance];
  NSData* encoded = [codec encode:value];
  FlutterStandardTypedData* decoded = [codec decode:encoded];
  ASSERT_TRUE(decoded.type == FlutterStandardDataTypeFloat64);
  ASSERT_TRUE(decoded.elementCount == 2);
  ASSERT_TRUE(decoded.elementSize == 8);
  ASSERT_TRUE([data isEqualTo:decoded.data]);
}
