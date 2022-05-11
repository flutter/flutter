// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERUNDOMANAGERPLUGIN_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERUNDOMANAGERPLUGIN_H_

#import <UIKit/UIKit.h>

#import "flutter/fml/memory/weak_ptr.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterChannels.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterUndoManagerDelegate.h"

@interface FlutterUndoManagerPlugin : NSObject

@property(nonatomic, assign) FlutterViewController* viewController;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDelegate:(id<FlutterUndoManagerDelegate>)undoManagerDelegate
    NS_DESIGNATED_INITIALIZER;

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;

@end

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERUNDOMANAGERPLUGIN_H_
