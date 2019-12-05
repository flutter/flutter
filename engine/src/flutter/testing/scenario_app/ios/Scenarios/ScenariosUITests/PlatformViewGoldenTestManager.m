// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "PlatformViewGoldenTestManager.h"
#import <XCTest/XCTest.h>

@interface PlatformViewGoldenTestManager ()

@property(readwrite, strong, nonatomic) GoldenImage* goldenImage;

@end

@implementation PlatformViewGoldenTestManager

NSDictionary* launchArgsMap;

- (instancetype)initWithLaunchArg:(NSString*)launchArg {
  self = [super init];
  if (self) {
    // The launchArgsMap should match the one in the `PlatformVieGoldenTestManager`.
    static NSDictionary<NSString*, NSString*>* launchArgsMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      launchArgsMap = @{
        @"--platform-view" : @"platform_view",
        @"--platform-view-multiple" : @"platform_view_multiple",
        @"--platform-view-multiple-background-foreground" :
            @"platform_view_multiple_background_foreground",
        @"--platform-view-cliprect" : @"platform_view_cliprect",
        @"--platform-view-cliprrect" : @"platform_view_cliprrect",
        @"--platform-view-clippath" : @"platform_view_clippath",
        @"--platform-view-transform" : @"platform_view_transform",
        @"--platform-view-opacity" : @"platform_view_opacity",
        @"--platform-view-rotate" : @"platform_view_rotate",
      };
    });
    _identifier = launchArgsMap[launchArg];
    NSString* prefix = [NSString stringWithFormat:@"golden_%@_", _identifier];
    _goldenImage = [[GoldenImage alloc] initWithGoldenNamePrefix:prefix];
    _launchArg = launchArg;
  }
  return self;
}

@end
