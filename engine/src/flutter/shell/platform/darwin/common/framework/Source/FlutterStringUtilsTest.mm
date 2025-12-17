// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterStringUtils.h"
#include "gtest/gtest.h"

namespace {

TEST(FlutterStringUtilsTest, HandlesNil) {
  EXPECT_EQ(FlutterSanitizeUTF8ForJSON(nil), nil);
}

TEST(FlutterStringUtilsTest, PreservesValidUTF8) {
  NSString* input = @"Hello, World!";
  NSData* data = [input dataUsingEncoding:NSUTF8StringEncoding];
  EXPECT_TRUE([FlutterSanitizeUTF8ForJSON(data) isEqualToString:input]);

  NSString* emoji = @"👋🌍";
  NSData* emojiData = [emoji dataUsingEncoding:NSUTF8StringEncoding];
  EXPECT_TRUE([FlutterSanitizeUTF8ForJSON(emojiData) isEqualToString:emoji]);
}

TEST(FlutterStringUtilsTest, SanitizesInvalidUTF8) {
  // Invalid byte sequence (continuation byte without start)
  const char bytes[] = "Hello \x80 World";
  NSData* data = [NSData dataWithBytes:bytes length:strlen(bytes)];
  NSString* sanitized = FlutterSanitizeUTF8ForJSON(data);
  EXPECT_TRUE([sanitized isEqualToString:@"Hello \uFFFD World"]);
}

TEST(FlutterStringUtilsTest, PreservesValidJSONEscapes) {
  NSString* input = @"\\\" \\\\ \\/ \\b \\f \\n \\r \\t";
  NSData* data = [input dataUsingEncoding:NSUTF8StringEncoding];
  EXPECT_TRUE([FlutterSanitizeUTF8ForJSON(data) isEqualToString:input]);
}

TEST(FlutterStringUtilsTest, PreservesValidSurrogatePairs) {
  // \uD83D\uDE00 is 😀
  NSString* input = @"\\uD83D\\uDE00";
  NSData* data = [input dataUsingEncoding:NSUTF8StringEncoding];
  EXPECT_TRUE([FlutterSanitizeUTF8ForJSON(data) isEqualToString:input]);

  // Lowercase hex
  NSString* inputLower = @"\\ud83d\\ude00";
  NSData* dataLower = [inputLower dataUsingEncoding:NSUTF8StringEncoding];
  EXPECT_TRUE([FlutterSanitizeUTF8ForJSON(dataLower) isEqualToString:inputLower]);
}

TEST(FlutterStringUtilsTest, SanitizesUnpairedHighSurrogates) {
  // \uD800 is a high surrogate
  NSString* input = @"Val: \\uD800 end";
  NSData* data = [input dataUsingEncoding:NSUTF8StringEncoding];
  NSString* expected = @"Val: \\uFFFD end";
  EXPECT_TRUE([FlutterSanitizeUTF8ForJSON(data) isEqualToString:expected]);
}

TEST(FlutterStringUtilsTest, SanitizesUnpairedLowSurrogates) {
  // \uDC00 is a low surrogate
  NSString* input = @"Val: \\uDC00 end";
  NSData* data = [input dataUsingEncoding:NSUTF8StringEncoding];
  NSString* expected = @"Val: \\uFFFD end";
  EXPECT_TRUE([FlutterSanitizeUTF8ForJSON(data) isEqualToString:expected]);
}

TEST(FlutterStringUtilsTest, SanitizesHighSurrogateFollowedByNonLow) {
  // \uD800 followed by \u0020 (space) instead of low surrogate
  NSString* input = @"\\uD800\\u0020";
  NSData* data = [input dataUsingEncoding:NSUTF8StringEncoding];
  NSString* expected = @"\\uFFFD\\u0020";
  EXPECT_TRUE([FlutterSanitizeUTF8ForJSON(data) isEqualToString:expected]);
}

TEST(FlutterStringUtilsTest, SanitizesBrokenEscapeSequences) {
  // String ending in middle of escape
  NSString* input = @"test \\uD8";
  NSData* data = [input dataUsingEncoding:NSUTF8StringEncoding];
  // Should be preserved as is (or handled gracefully), here it's valid UTF8 chars
  // but not a complete escape. SanitizeJSON loop checks length.
  EXPECT_TRUE([FlutterSanitizeUTF8ForJSON(data) isEqualToString:input]);
}

TEST(FlutterStringUtilsTest, MixedContent) {
  // Valid text + Invalid UTF8 + Valid Escape + Lone Surrogate
  // "H\x80 \u0041 \uD800"
  // Expected: "H\uFFFD \u0041 \uFFFD"
  const char bytes[] = "H\x80 \\u0041 \\uD800";
  NSData* data = [NSData dataWithBytes:bytes length:strlen(bytes)];
  NSString* expected = @"H\uFFFD \\u0041 \\uFFFD";
  EXPECT_TRUE([FlutterSanitizeUTF8ForJSON(data) isEqualToString:expected]);
}

}  // namespace
