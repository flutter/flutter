// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_HEADERS_FLUTTERSCENEDELEGATE_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_HEADERS_FLUTTERSCENEDELEGATE_H_

#import <UIKit/UIKit.h>
#import "FlutterMacros.h"

NS_ASSUME_NONNULL_BEGIN

@class FlutterEngine;

/**
 * The UISceneDelegate used by Flutter by default.
 *
 * This class is typically specified as the UISceneDelegate in the Info.plist.
 */
FLUTTER_DARWIN_EXPORT
@interface FlutterSceneDelegate : NSObject <UIWindowSceneDelegate>
@property(nonatomic, strong, nullable) UIWindow* window;

/**
 * Use this method to register a `FlutterEngine`'s plugins to the scene's life cycle events.
 *
 * Some Flutter plugins use scene life cycle events to do actions on app launch. For them to receive
 * the necessary events, the `FlutterEngine` must be registered to the scene during
 * `scene:willConnectTo:options:`. This is only required if Multiple Scenes is enabled and the
 * `rootViewController` of the scene is not a `FlutterViewController`.
 */
- (void)registerFlutterEngine:(FlutterEngine*)engine;

- (void)deregisterFlutterEngine:(FlutterEngine*)engine;
@end

NS_ASSUME_NONNULL_END

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_HEADERS_FLUTTERSCENEDELEGATE_H_
