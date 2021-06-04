// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterFrameBufferProvider.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterIOSurfaceHolder.h"

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

/**
 * FlutterBackingStoreData holds data to be stored in the
 * BackingStore's user_data.
 */
@interface FlutterBackingStoreData : NSObject

- (nullable instancetype)initWithFbProvider:(nonnull FlutterFrameBufferProvider*)fbProvider
                            ioSurfaceHolder:(nonnull FlutterIOSurfaceHolder*)ioSurfaceHolder;

/**
 * Provides the fbo for rendering the layer.
 */
@property(nonnull, nonatomic, readonly) FlutterFrameBufferProvider* frameBufferProvider;

/**
 * Contains the IOSurfaceRef with the layer contents.
 */
@property(nonnull, nonatomic, readonly) FlutterIOSurfaceHolder* ioSurfaceHolder;

@end
