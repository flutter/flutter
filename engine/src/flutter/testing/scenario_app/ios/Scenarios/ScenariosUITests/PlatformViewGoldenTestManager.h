// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

#import "GoldenImage.h"

NS_ASSUME_NONNULL_BEGIN

extern NSDictionary* launchArgsMap;

// Manages a `GoldenPlatformViewTests`.
//
// It creates the correct `identifer` based on the `launchArg`.
// It also generates the correct GoldenImage based on the `identifier`.
@interface PlatformViewGoldenTestManager : NSObject

@property(readonly, strong, nonatomic) GoldenImage* goldenImage;
@property(readonly, copy, nonatomic) NSString* identifier;
@property(readonly, copy, nonatomic) NSString* launchArg;

// Initilize with launchArg.
//
// Crahes if the launchArg is not mapped in `Appdelegate.launchArgsMap`.
- (instancetype)initWithLaunchArg:(NSString*)launchArg;

@end

NS_ASSUME_NONNULL_END
