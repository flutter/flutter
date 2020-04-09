// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVIEWCONTROLLER_INTERNAL_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVIEWCONTROLLER_INTERNAL_H_

#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"

namespace flutter {
class FlutterPlatformViewsController;
}

FLUTTER_EXPORT
extern NSNotificationName const FlutterViewControllerWillDealloc;

FLUTTER_EXPORT
extern NSNotificationName const FlutterViewControllerHideHomeIndicator;

FLUTTER_EXPORT
extern NSNotificationName const FlutterViewControllerShowHomeIndicator;

@interface FlutterViewController ()

- (fml::WeakPtr<FlutterViewController>)getWeakPtr;
- (flutter::FlutterPlatformViewsController*)platformViewsController;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERVIEWCONTROLLER_INTERNAL_H_
