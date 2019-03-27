// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Headers/FLEView.h"

@implementation FLEView

#pragma mark -
#pragma mark FLEContextHandlingProtocol

- (void)makeCurrentContext {
  [self.openGLContext makeCurrentContext];
}

- (void)onPresent {
  [self.openGLContext flushBuffer];
}

#pragma mark -
#pragma mark Implementation

/**
 * Declares that the view uses a flipped coordinate system, consistent with Flutter conventions.
 */
- (BOOL)isFlipped {
  return YES;
}

- (BOOL)isOpaque {
  return YES;
}

- (void)reshape {
  [super reshape];
  [_reshapeListener viewDidReshape:self];
}

- (BOOL)acceptsFirstResponder {
  return YES;
}

@end
