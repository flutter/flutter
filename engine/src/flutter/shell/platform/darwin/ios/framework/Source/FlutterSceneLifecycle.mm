// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSceneLifecycle.h"

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"

FLUTTER_ASSERT_ARC

@interface FlutterPluginSceneLifeCycleDelegate () {
}
@property(nonatomic, strong) NSPointerArray* engines;
@end

@implementation FlutterPluginSceneLifeCycleDelegate
- (instancetype)init {
  if (self = [super init]) {
    _engines = [NSPointerArray weakObjectsPointerArray];
  }
  return self;
}

- (void)addFlutterViewController:(FlutterViewController*)controller {
  // Check if the engine is already in the array to avoid duplicates.
  if ([self.engines.allObjects containsObject:controller.engine]) {
    return;
  }

  [self.engines addPointer:(__bridge void*)controller.engine];

  // NSPointerArray is clever and assumes that unless a mutation operation has occurred on it that
  // has set one of its values to nil, nothing could have changed and it can skip compaction.
  // That's reasonable behaviour on a regular NSPointerArray but not for a weakObjectPointerArray.
  // As a workaround, we mutate it first. See: http://www.openradar.me/15396578
  [self.engines addPointer:nil];
  [self.engines compact];
}
@end