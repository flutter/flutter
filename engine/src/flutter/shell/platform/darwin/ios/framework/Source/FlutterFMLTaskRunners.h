// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERFMLTASKRUNNERS_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERFMLTASKRUNNERS_H_

#import <Foundation/Foundation.h>

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFMLTaskRunner.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(TaskRunners)
@interface FlutterFMLTaskRunners : NSObject

@property(nonatomic, readonly) NSString* label;
@property(nonatomic, readonly) FlutterFMLTaskRunner* platformTaskRunner;
@property(nonatomic, readonly) FlutterFMLTaskRunner* rasterTaskRunner;
@property(nonatomic, readonly) FlutterFMLTaskRunner* uiTaskRunner;
@property(nonatomic, readonly) FlutterFMLTaskRunner* ioTaskRunner;

- (instancetype)initWithLabel:(NSString*)label
           platformTaskRunner:(FlutterFMLTaskRunner*)platformTaskRunner
             rasterTaskRunner:(FlutterFMLTaskRunner*)rasterTaskRunner
                 uiTaskRunner:(FlutterFMLTaskRunner*)uiTaskRunner
                 ioTaskRunner:(FlutterFMLTaskRunner*)ioTaskRunner;

@end

NS_ASSUME_NONNULL_END

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERFMLTASKRUNNERS_H_
