// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERDARTSOURCE_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERDARTSOURCE_H_

#import <Foundation/Foundation.h>

typedef void (^ValidationResult)(BOOL result, NSString* message);

@interface FlutterDartSource : NSObject

@property(nonatomic, readonly) NSURL* dartMain;
@property(nonatomic, readonly) NSURL* packages;
@property(nonatomic, readonly) NSURL* flutterAssets;
@property(nonatomic, readonly) BOOL assetsDirContainsScriptSnapshot;

- (instancetype)initWithDartMain:(NSURL*)dartMain
                        packages:(NSURL*)packages
                   flutterAssets:(NSURL*)flutterAssets NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFlutterAssetsWithScriptSnapshot:(NSURL*)flutterAssets
    NS_DESIGNATED_INITIALIZER;

- (void)validate:(ValidationResult)result;

@end

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_FLUTTERDARTSOURCE_H_
