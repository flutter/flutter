// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterView.h"

#import <QuartzCore/QuartzCore.h>

#import "flutter/shell/platform/darwin/common/InternalFlutterSwiftCommon/InternalFlutterSwiftCommon.h"
#import "flutter/shell/platform/darwin/macos/InternalFlutterSwift/InternalFlutterSwift.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterSurfaceManager.h"

@interface FlutterView () <FlutterSurfaceManagerDelegate> {
  FlutterViewIdentifier _viewIdentifier;
  __weak id<FlutterViewDelegate> _viewDelegate;
  FlutterResizeSynchronizer* _resizeSynchronizer;
  FlutterSurfaceManager* _surfaceManager;
  NSCursor* _lastCursor;
}

@end

@implementation FlutterView

- (instancetype)initWithMTLDevice:(id<MTLDevice>)device
                     commandQueue:(id<MTLCommandQueue>)commandQueue
                         delegate:(id<FlutterViewDelegate>)delegate
                   viewIdentifier:(FlutterViewIdentifier)viewIdentifier
                  enableWideGamut:(BOOL)enableWideGamut {
  self = [super initWithFrame:NSZeroRect];
  if (self) {
    [self setWantsLayer:YES];
    [self setBackgroundColor:[NSColor blackColor]];
    [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawDuringViewResize];
    _viewIdentifier = viewIdentifier;
    _viewDelegate = delegate;
    _surfaceManager = [[FlutterSurfaceManager alloc] initWithDevice:device
                                                       commandQueue:commandQueue
                                                              layer:self.layer
                                                           delegate:self
                                                          wideGamut:enableWideGamut];
    _resizeSynchronizer = [[FlutterResizeSynchronizer alloc] init];
  }
  return self;
}

- (void)onPresent:(CGSize)frameSize withBlock:(dispatch_block_t)block delay:(NSTimeInterval)delay {
  // This block will be called in main thread same run loop turn as the layer content
  // update.
  auto notifyBlock = ^{
    NSSize scaledSize = [self convertSizeFromBacking:frameSize];
    [self.sizingDelegate viewDidUpdateContents:self withSize:scaledSize];
    block();
  };
  [_resizeSynchronizer performCommitForSize:frameSize afterDelay:delay notify:notifyBlock];
}

- (FlutterSurfaceManager*)surfaceManager {
  return _surfaceManager;
}

- (void)setEnableWideGamut:(BOOL)enableWideGamut {
  [_surfaceManager setEnableWideGamut:enableWideGamut];
}

- (void)shutDown {
  [_resizeSynchronizer shutDown];
}

- (void)setBackgroundColor:(NSColor*)color {
  self.layer.backgroundColor = color.CGColor;
}

#pragma mark - NSView overrides

- (void)setFrameSize:(NSSize)newSize {
  [super setFrameSize:newSize];
  if (!self.sizedToContents) {
    CGSize scaledSize = [self convertSizeToBacking:self.bounds.size];
    [_resizeSynchronizer beginResizeForSize:scaledSize
        notify:^{
          [_viewDelegate viewDidReshape:self];
        }
        onTimeout:^{
          [FlutterLogger logError:@"Resize timed out"];
        }];
  }
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
  // This is to ensure that FlutterView does not take first responder status from TextInputPlugin
  // on mouse clicks.
  return [_viewDelegate viewShouldAcceptFirstResponder:self];
}

- (void)didUpdateMouseCursor:(NSCursor*)cursor {
  _lastCursor = cursor;
}

// Restores mouse cursor. There are few cases when this is needed and framework will not handle
// this automatically:
// - When mouse cursor leaves subview of FlutterView (technically still within bound of
// FlutterView tracking area so the framework won't be notified)
// - When context menu above FlutterView is closed. Context menu will change current cursor to
// arrow and will not restore it back.
- (void)cursorUpdate:(NSEvent*)event {
  // Make sure to not override cursor when over a platform view.
  NSPoint mouseLocation = [[self superview] convertPoint:event.locationInWindow fromView:nil];
  NSView* hitTestView = [self hitTest:mouseLocation];
  if (hitTestView != self) {
    return;
  }
  [_lastCursor set];
  // It is possible that there is a platform view with NSTrackingArea below flutter content.
  // This could override the mouse cursor as a result of mouse move event. There is no good way
  // to prevent that short of swizzling [NSCursor set], so as a workaround force flutter cursor
  // in next runloop turn. This is not ideal, as it may cause the cursor flicker a bit.
  [[NSRunLoop currentRunLoop] performBlock:^{
    [_lastCursor set];
  }];
}

- (void)viewDidChangeBackingProperties {
  [super viewDidChangeBackingProperties];
  // Force redraw
  [_viewDelegate viewDidReshape:self];
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

- (BOOL)sizedToContents {
  return _sizingDelegate != nil && [_sizingDelegate minimumViewSize:self] != std::nullopt;
}

- (NSSize)minimumContentSize {
  if (_sizingDelegate != nil) {
    std::optional<NSSize> minSize = [_sizingDelegate minimumViewSize:self];
    if (minSize) {
      return *minSize;
    }
  }
  return self.bounds.size;
}

- (NSSize)maximumContentSize {
  if (_sizingDelegate != nil) {
    std::optional<NSSize> maxSize = [_sizingDelegate maximumViewSize:self];
    if (maxSize) {
      return *maxSize;
    }
  }
  return self.bounds.size;
}

- (void)constraintsDidChange {
  [_viewDelegate viewDidReshape:self];
}

@end
