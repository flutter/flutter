// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterResizableBackingStoreProvider.h"

#import <OpenGL/gl.h>
#import <QuartzCore/QuartzCore.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterSurfaceManager.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/MacOSGLContextSwitch.h"

@implementation FlutterOpenGLResizableBackingStoreProvider {
  NSOpenGLContext* _mainContext;
  id<FlutterSurfaceManager> _surfaceManager;
}

- (instancetype)initWithMainContext:(NSOpenGLContext*)mainContext layer:(CALayer*)layer {
  self = [super init];
  if (self) {
    _mainContext = mainContext;
    _surfaceManager = [[FlutterGLSurfaceManager alloc] initWithLayer:layer
                                                       openGLContext:_mainContext];
  }
  return self;
}

- (void)onBackingStoreResized:(CGSize)size {
  [_surfaceManager ensureSurfaceSize:size];
}

- (FlutterRenderBackingStore*)backingStore {
  return [_surfaceManager renderBuffer];
}

- (void)resizeSynchronizerFlush:(nonnull FlutterResizeSynchronizer*)synchronizer {
  MacOSGLContextSwitch context_switch(_mainContext);
  glFlush();
}

- (void)resizeSynchronizerCommit:(nonnull FlutterResizeSynchronizer*)synchronizer {
  [CATransaction begin];
  [CATransaction setDisableActions:YES];

  [_surfaceManager swapBuffers];

  [CATransaction commit];
}

@end

@implementation FlutterMetalResizableBackingStoreProvider {
  id<MTLDevice> _device;
  id<MTLCommandQueue> _commandQueue;
  id<FlutterSurfaceManager> _surfaceManager;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device
                  commandQueue:(id<MTLCommandQueue>)commandQueue
                         layer:(CALayer*)layer {
  self = [super init];
  if (self) {
    _device = device;
    _commandQueue = commandQueue;
    _surfaceManager = [[FlutterMetalSurfaceManager alloc] initWithDevice:device
                                                            commandQueue:commandQueue
                                                                   layer:layer];
  }
  return self;
}

- (void)onBackingStoreResized:(CGSize)size {
  [_surfaceManager ensureSurfaceSize:size];
}

- (FlutterRenderBackingStore*)backingStore {
  return [_surfaceManager renderBuffer];
}

- (void)resizeSynchronizerFlush:(nonnull FlutterResizeSynchronizer*)synchronizer {
  id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
  [commandBuffer commit];
  [commandBuffer waitUntilScheduled];
}

- (void)resizeSynchronizerCommit:(nonnull FlutterResizeSynchronizer*)synchronizer {
  [CATransaction begin];
  [CATransaction setDisableActions:YES];

  [_surfaceManager swapBuffers];

  [CATransaction commit];
}

@end
