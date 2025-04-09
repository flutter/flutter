// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSHAREDAPPLICATION_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSHAREDAPPLICATION_H_

#import <UIKit/UIKit.h>

@interface FlutterSharedApplication : NSObject

/**
 * Returns YES if the main bundle is an iOS App Extension.
 */
@property(class, nonatomic, readonly) BOOL isAppExtension;

/**
 * Returns YES if the UIApplication is available. UIApplication is not available for App Extensions.
 */
@property(class, nonatomic, readonly) BOOL isAvailable;

/**
 * Returns the `UIApplication.sharedApplication` is available. Otherwise returns nil.
 */
@property(class, nonatomic, readonly) UIApplication* application;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSHAREDAPPLICATION_H_
