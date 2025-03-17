// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSHAREDAPPLICATION_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSHAREDAPPLICATION_H_

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FlutterSharedApplication : NSObject

+ (BOOL)isAvailable;

+ (UIApplication*)uiApplication;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSHAREDAPPLICATION_H_
