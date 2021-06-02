// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterBackingStoreData.h"

#import <OpenGL/gl.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterFrameBufferProvider.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterIOSurfaceHolder.h"

@implementation FlutterBackingStoreData

- (nullable instancetype)initWithFbProvider:(nonnull FlutterFrameBufferProvider*)fbProvider
                            ioSurfaceHolder:(nonnull FlutterIOSurfaceHolder*)ioSurfaceHolder {
  if (self = [super init]) {
    _frameBufferProvider = fbProvider;
    _ioSurfaceHolder = ioSurfaceHolder;
  }
  return self;
}

@end
