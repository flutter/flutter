// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterIntermediateKeyResponder.h"

@implementation FlutterIntermediateKeyResponder {
}

#pragma mark - Default key handling methods

- (BOOL)handleKeyUp:(NSEvent*)event {
  return NO;
}

- (BOOL)handleKeyDown:(NSEvent*)event {
  return NO;
}
@end
