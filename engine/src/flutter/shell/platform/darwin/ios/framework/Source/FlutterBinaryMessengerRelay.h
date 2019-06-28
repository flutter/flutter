// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterBinaryMessenger.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"

#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG
FLUTTER_EXPORT
#endif
@interface FlutterBinaryMessengerRelay : NSObject <FlutterBinaryMessenger>
@property(nonatomic, assign) NSObject<FlutterBinaryMessenger>* parent;
- (instancetype)initWithParent:(NSObject<FlutterBinaryMessenger>*)parent;
@end
