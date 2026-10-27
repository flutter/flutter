// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Smoke test for flutter_swift_library (build_defs/cc/swift_library.bzl):
// a Swift module compiled through build/toolchain/darwin/swiftc.py, reached
// from Objective-C++ through its generated header -- the shape of
// darwin/common's InternalFlutterSwiftCommon under FlutterMacOS.

#import <Foundation/Foundation.h>

#include "gtest/gtest.h"

// The module's generated header, at GN's path under the generated root:
// $target_gen_dir/<name>/<name>.h.
#import "flutter/build/bazel/toolchains/tests/MacosSwiftSmoke/MacosSwiftSmoke.h"

TEST(MacosSwiftSmokeTest, SwiftRunsThroughTheGeneratedHeader) {
  NSString* reversed = [FlutterBazelSwiftSmoke reversed:@"bazel"];
  EXPECT_TRUE([reversed isEqualToString:@"lezab"]);
}

TEST(MacosSwiftSmokeTest, SwiftCallsCThroughTheBridgingHeader) {
  EXPECT_EQ([FlutterBazelSwiftSmoke answerFromC], 42);
}
