// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMPLUGIN_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMPLUGIN_H_

#include "flutter/shell/platform/darwin/common/FlutterChannels.h"

@interface FlutterPlatformPlugin : NSObject

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;

@end

namespace shell {

extern const char* const kOrientationUpdateNotificationName;
extern const char* const kOrientationUpdateNotificationKey;
extern const char* const kOverlayStyleUpdateNotificationName;
extern const char* const kOverlayStyleUpdateNotificationKey;

}  // namespace shell

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMPLUGIN_H_
