// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterView.h"

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterResizeSynchronizer.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterSurfaceManager.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/MacOSGLContextSwitch.h"

#import <OpenGL/gl.h>
#import <QuartzCore/QuartzCore.h>

@interface FlutterView () <FlutterResizeSynchronizerDelegate> {
  __weak id<FlutterViewReshapeListener> _reshapeListener;
  FlutterResizeSynchronizer* _resizeSynchronizer;
  FlutterSurfaceManager* _surfaceManager;
}

@end

@implementation FlutterView

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

    [self setWantsLayer:YES];

    _resizeSynchronizer = [[FlutterResizeSynchronizer alloc] initWithDelegate:self];
    _surfaceManager = [[FlutterSurfaceManager alloc] initWithLayer:self.layer
                                                     openGLContext:self.openGLContext];

    _reshapeListener = reshapeListener;
  }
  return self;
}

- (void)resizeSynchronizerFlush:(FlutterResizeSynchronizer*)synchronizer {
  MacOSGLContextSwitch context_switch(self.openGLContext);
  glFlush();
}

- (void)resizeSynchronizerCommit:(FlutterResizeSynchronizer*)synchronizer {
  [CATransaction begin];
  [CATransaction setDisableActions:YES];

  [_surfaceManager swapBuffers];

  [CATransaction commit];
}

- (int)frameBufferIDForSize:(CGSize)size {
  if ([_resizeSynchronizer shouldEnsureSurfaceForSize:size]) {
    [_surfaceManager ensureSurfaceSize:size];
  }
  return [_surfaceManager glFrameBufferId];
}

- (void)present {
  [_resizeSynchronizer requestCommit];
}

- (void)reshaped {
  CGSize scaledSize = [self convertSizeToBacking:self.bounds.size];
  [_resizeSynchronizer beginResize:scaledSize
                            notify:^{
                              [_reshapeListener viewDidReshape:self];
                            }];
}

#pragma mark - NSView overrides

- (void)setFrameSize:(NSSize)newSize {
  [super setFrameSize:newSize];
  [self reshaped];
}

/**
 * Declares that the view uses a flipped coordinate system, consistent with Flutter conventions.
 */
- (BOOL)isFlipped {
  return YES;
}

- (BOOL)isOpaque {
  return YES;
}

- (BOOL)acceptsFirstResponder {
  return YES;
}

- (void)viewDidChangeBackingProperties {
  [super viewDidChangeBackingProperties];
  // Force redraw
  [_reshapeListener viewDidReshape:self];
}

@end
