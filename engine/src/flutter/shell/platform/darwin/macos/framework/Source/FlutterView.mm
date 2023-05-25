// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterView.h"

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterSurfaceManager.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterThreadSynchronizer.h"

#import <QuartzCore/QuartzCore.h>

@interface FlutterView () <FlutterSurfaceManagerDelegate> {
  int64_t _viewId;
  __weak id<FlutterViewReshapeListener> _reshapeListener;
  FlutterThreadSynchronizer* _threadSynchronizer;
  FlutterSurfaceManager* _surfaceManager;
}

@end

@implementation FlutterView

- (instancetype)initWithMTLDevice:(id<MTLDevice>)device
                     commandQueue:(id<MTLCommandQueue>)commandQueue
                  reshapeListener:(id<FlutterViewReshapeListener>)reshapeListener
               threadSynchronizer:(FlutterThreadSynchronizer*)threadSynchronizer
                           viewId:(int64_t)viewId {
  self = [super initWithFrame:NSZeroRect];
  if (self) {
    [self setWantsLayer:YES];
    [self setBackgroundColor:[NSColor blackColor]];
    [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawDuringViewResize];
    _viewId = viewId;
    _reshapeListener = reshapeListener;
    _threadSynchronizer = threadSynchronizer;
    _surfaceManager = [[FlutterSurfaceManager alloc] initWithDevice:device
                                                       commandQueue:commandQueue
                                                              layer:self.layer
                                                           delegate:self];
  }
  return self;
}

- (void)onPresent:(CGSize)frameSize withBlock:(dispatch_block_t)block {
  [_threadSynchronizer performCommitForView:_viewId size:frameSize notify:block];
}

- (FlutterSurfaceManager*)surfaceManager {
  return _surfaceManager;
}

- (void)reshaped {
  CGSize scaledSize = [self convertSizeToBacking:self.bounds.size];
  [_threadSynchronizer beginResizeForView:_viewId
                                     size:scaledSize
                                   notify:^{
                                     [_reshapeListener viewDidReshape:self];
                                   }];
}

- (void)setBackgroundColor:(NSColor*)color {
  self.layer.backgroundColor = color.CGColor;
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

- (void)cursorUpdate:(NSEvent*)event {
  // When adding/removing views AppKit will schedule call to current hit-test view
  // cursorUpdate: at the end of frame to determine possible cursor change. If
  // the view doesn't implement cursorUpdate: AppKit will set the default (arrow) cursor
  // instead. This would replace the cursor set by FlutterMouseCursorPlugin.
  // Empty cursorUpdate: implementation prevents this behavior.
  // https://github.com/flutter/flutter/issues/111425
}

- (void)viewDidChangeBackingProperties {
  [super viewDidChangeBackingProperties];
  // Force redraw
  [_reshapeListener viewDidReshape:self];
}

- (BOOL)layer:(CALayer*)layer
    shouldInheritContentsScale:(CGFloat)newScale
                    fromWindow:(NSWindow*)window {
  return YES;
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
