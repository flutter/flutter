// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterView.h"

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterRenderingBackend.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterResizeSynchronizer.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterSurfaceManager.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/MacOSGLContextSwitch.h"

#import <OpenGL/gl.h>
#import <QuartzCore/QuartzCore.h>

@interface FlutterView () {
  __weak id<FlutterViewReshapeListener> _reshapeListener;
  FlutterResizeSynchronizer* _resizeSynchronizer;
  id<FlutterResizableBackingStoreProvider> _resizableBackingStoreProvider;
}

@end

@implementation FlutterView

- (instancetype)initWithMTLDevice:(id<MTLDevice>)device
                     commandQueue:(id<MTLCommandQueue>)commandQueue
                  reshapeListener:(id<FlutterViewReshapeListener>)reshapeListener {
  self = [super initWithFrame:NSZeroRect];
  if (self) {
    [self setWantsLayer:YES];
    [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawDuringViewResize];
    _reshapeListener = reshapeListener;
    _resizableBackingStoreProvider =
        [[FlutterMetalResizableBackingStoreProvider alloc] initWithDevice:device
                                                             commandQueue:commandQueue
                                                                    layer:self.layer];
    _resizeSynchronizer =
        [[FlutterResizeSynchronizer alloc] initWithDelegate:_resizableBackingStoreProvider];
  }
  return self;
}

- (instancetype)initWithMainContext:(NSOpenGLContext*)mainContext
                    reshapeListener:(id<FlutterViewReshapeListener>)reshapeListener {
  return [self initWithFrame:NSZeroRect mainContext:mainContext reshapeListener:reshapeListener];
}

- (instancetype)initWithFrame:(NSRect)frame
                  mainContext:(NSOpenGLContext*)mainContext
              reshapeListener:(id<FlutterViewReshapeListener>)reshapeListener {
  self = [super initWithFrame:frame];
  if (self) {
    [self setWantsLayer:YES];
    _reshapeListener = reshapeListener;
    _resizableBackingStoreProvider =
        [[FlutterOpenGLResizableBackingStoreProvider alloc] initWithMainContext:mainContext
                                                                          layer:self.layer];
    _resizeSynchronizer =
        [[FlutterResizeSynchronizer alloc] initWithDelegate:_resizableBackingStoreProvider];
  }
  return self;
}

- (FlutterRenderBackingStore*)backingStoreForSize:(CGSize)size {
  if ([_resizeSynchronizer shouldEnsureSurfaceForSize:size]) {
    [_resizableBackingStoreProvider onBackingStoreResized:size];
  }
  return [_resizableBackingStoreProvider backingStore];
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

/**
 * Declares that the initial mouse-down when the view is not in focus will send an event to the
 * view.
 */
- (BOOL)acceptsFirstMouse:(NSEvent*)event {
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

- (void)shutdown {
  [_resizeSynchronizer shutdown];
}
#pragma mark - NSAccessibility overrides

- (BOOL)isAccessibilityElement {
  return YES;
}

- (NSAccessibilityRole)accessibilityRole {
  return NSAccessibilityGroupRole;
}

- (NSString*)accessibilityLabel {
  // TODO(chunhtai): Provides a way to let developer customize the accessibility
  // label.
  // https://github.com/flutter/flutter/issues/75446
  NSString* applicationName =
      [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
  if (!applicationName) {
    applicationName = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleName"];
  }
  return applicationName;
}

@end
