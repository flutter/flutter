// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMPLUGIN_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMPLUGIN_H_

#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterChannels.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngine.h"

@interface FlutterPlatformPlugin : NSObject
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithEngine:(fml::WeakPtr<FlutterEngine>)engine NS_DESIGNATED_INITIALIZER;
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;

@end

namespace shell {

extern const char* const kOrientationUpdateNotificationName;
extern const char* const kOrientationUpdateNotificationKey;
extern const char* const kOverlayStyleUpdateNotificationName;
extern const char* const kOverlayStyleUpdateNotificationKey;

}  // namespace shell

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMPLUGIN_H_
