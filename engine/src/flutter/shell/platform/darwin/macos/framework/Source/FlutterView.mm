// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterView.h"

@implementation FlutterView {
  __weak id<FlutterViewReshapeListener> _reshapeListener;
}

- (instancetype)initWithReshapeListener:(id<FlutterViewReshapeListener>)reshapeListener {
  return [self initWithFrame:NSZeroRect reshapeListener:reshapeListener];
}

- (instancetype)initWithFrame:(NSRect)frame
              reshapeListener:(id<FlutterViewReshapeListener>)reshapeListener {
  NSOpenGLPixelFormatAttribute attributes[] = {
      NSOpenGLPFAColorSize, 24, NSOpenGLPFAAlphaSize, 8, NSOpenGLPFADoubleBuffer, 0,
  };
  NSOpenGLPixelFormat* pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
  self = [super initWithFrame:frame pixelFormat:pixelFormat];
  if (self) {
    _reshapeListener = reshapeListener;
    self.wantsBestResolutionOpenGLSurface = YES;
  }
  return self;
}

- (void)makeCurrentContext {
  [self.openGLContext makeCurrentContext];
}

- (void)onPresent {
  [self.openGLContext flushBuffer];
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

@end
