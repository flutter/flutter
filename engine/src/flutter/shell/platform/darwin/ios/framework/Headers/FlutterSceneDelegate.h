// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_HEADERS_FLUTTERSCENEDELEGATE_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_HEADERS_FLUTTERSCENEDELEGATE_H_

#import <UIKit/UIKit.h>
#import "FlutterMacros.h"
#import "FlutterSceneLifeCycle.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * The UISceneDelegate used by Flutter by default.
 *
 * This class is typically specified as the UISceneDelegate in the Info.plist.
 */
FLUTTER_DARWIN_EXPORT
@interface FlutterSceneDelegate
    : NSObject <UIWindowSceneDelegate, FlutterSceneLifeCycleEngineRegistration>
@property(nonatomic, strong, nullable) UIWindow* window;

@end

NS_ASSUME_NONNULL_END

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_HEADERS_FLUTTERSCENEDELEGATE_H_
