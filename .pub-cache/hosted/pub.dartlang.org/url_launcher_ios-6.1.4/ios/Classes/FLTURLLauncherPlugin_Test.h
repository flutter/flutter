// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTURLLauncherPlugin.h"
#import "FULLauncher.h"

/// APIs exposed for testing.
@interface FLTURLLauncherPlugin (Test)
- (instancetype)initWithLauncher:(NSObject<FULLauncher> *)launcher;
@end
