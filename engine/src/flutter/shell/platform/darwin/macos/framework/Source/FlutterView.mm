// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterView.h"

@implementation FlutterView {
  __weak id<FlutterViewReshapeListener> _reshapeListener;
}

- (instancetype)initWithShareContext:(NSOpenGLContext*)shareContext
                     reshapeListener:(id<FlutterViewReshapeListener>)reshapeListener {
  return [self initWithFrame:NSZeroRect shareContext:shareContext reshapeListener:reshapeListener];
}

- (instancetype)initWithFrame:(NSRect)frame
                 shareContext:(NSOpenGLContext*)shareContext
              reshapeListener:(id<FlutterViewReshapeListener>)reshapeListener {
  self = [super initWithFrame:frame];
  if (self) {
    self.openGLContext = [[NSOpenGLContext alloc] initWithFormat:shareContext.pixelFormat
                                                    shareContext:shareContext];
    _reshapeListener = reshapeListener;
    self.wantsBestResolutionOpenGLSurface = YES;
  }
  return self;
}

#pragma mark - NSView overrides

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

- (void)viewDidChangeBackingProperties {
  [super viewDidChangeBackingProperties];
  [_reshapeListener viewDidReshape:self];
}

@end
