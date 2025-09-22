// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSCENELIFECYCLE_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSCENELIFECYCLE_H_

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"

/**
 * Propagates `UIWindowSceneDelegate` callbacks to the `FlutterEngine` to then be propograted to
 * registered plugins.
 */
@interface FlutterPluginSceneLifeCycleDelegate : NSObject

- (void)addFlutterEngine:(FlutterEngine*)engine;

- (void)removeFlutterEngine:(FlutterEngine*)engine;
@end

/**
 * Implement this in the `UIWindowSceneDelegate` of your app to enable Flutter plugins to register
 * themselves to the scene life cycle events.
 */
@protocol FlutterSceneLifeCycleProvider
@property(nonatomic, strong) FlutterPluginSceneLifeCycleDelegate* sceneLifeCycleDelegate;
@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSCENELIFECYCLE_H_
