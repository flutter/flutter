// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViews_Internal.h"

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTER_TOUCH_INTERCEPTING_VIEW_TEST_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTER_TOUCH_INTERCEPTING_VIEW_TEST_H_

@interface FlutterTouchInterceptingView (Tests)
- (id)accessibilityContainer;
@end

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTER_TOUCH_INTERCEPTING_VIEW_TESTS_H_
