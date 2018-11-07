// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterAppDelegate.h"

@interface FlutterAppDelegate ()

@property(readonly, nonatomic) NSMutableArray* pluginDelegates;
@property(readonly, nonatomic) NSMutableDictionary* pluginPublications;

@end

@interface FlutterAppDelegateRegistrar : NSObject <FlutterPluginRegistrar>

- (instancetype)initWithPlugin:(NSString*)pluginKey appDelegate:(FlutterAppDelegate*)delegate;

@end
