// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterTexture.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"

@interface FlutterDarwinExternalTextureMetal : NSObject

- (nullable instancetype)initWithTextureCache:(nonnull CVMetalTextureCacheRef)textureCache
                                    textureID:(int64_t)textureID
                                      texture:(nonnull NSObject<FlutterTexture>*)texture;

- (void)paint:(SkCanvas&)canvas
       bounds:(const SkRect&)bounds
       freeze:(BOOL)freeze
    grContext:(nonnull GrDirectContext*)grContext
     sampling:(const SkSamplingOptions&)sampling;

- (void)onGrContextCreated;

- (void)onGrContextDestroyed;

- (void)markNewFrameAvailable;

- (void)onTextureUnregistered;

@property(nonatomic, readonly) int64_t textureID;

@end
