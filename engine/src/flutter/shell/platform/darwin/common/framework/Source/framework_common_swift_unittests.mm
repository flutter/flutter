// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/common/framework_common_swift_unittests/framework_common_swift_unittests.h"

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/common/framework/Source/FlutterTestUtils.h"
#include "gtest/gtest.h"

FLUTTER_ASSERT_ARC

TEST(FrameworkCommonUnittestsSwift, Logger) {
  ASSERT_FALSE(FLTThrowsObjcException(^{
    [[LoggerTest alloc] runAllTests];
  }));
}
