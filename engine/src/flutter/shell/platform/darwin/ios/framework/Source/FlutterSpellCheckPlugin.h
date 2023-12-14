// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSPELLCHECKPLUGIN_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSPELLCHECKPLUGIN_H_

#include "flutter/fml/memory/weak_ptr.h"

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterChannels.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngine.h"

@interface FlutterSpellCheckPlugin : NSObject

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;

@end

@interface FlutterSpellCheckResult : NSObject

@property(nonatomic, copy, readonly) NSArray<NSString*>* suggestions;
@property(nonatomic, assign, readonly) NSRange misspelledRange;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithMisspelledRange:(NSRange)range
                            suggestions:(NSArray<NSString*>*)suggestions NS_DESIGNATED_INITIALIZER;
- (NSDictionary<NSString*, NSObject*>*)toDictionary;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERSPELLCHECKPLUGIN_H_
