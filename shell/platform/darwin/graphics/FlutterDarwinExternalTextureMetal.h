// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#include "flutter/common/graphics/texture.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterTexture.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkImage.h"

@interface FlutterDarwinExternalTextureSkImageWrapper : NSObject

+ (sk_sp<SkImage>)wrapYUVATexture:(nonnull id<MTLTexture>)yTex
                            UVTex:(nonnull id<MTLTexture>)uvTex
                    YUVColorSpace:(SkYUVColorSpace)colorSpace
                        grContext:(nonnull GrDirectContext*)grContext
                            width:(size_t)width
                           height:(size_t)height;

+ (sk_sp<SkImage>)wrapRGBATexture:(nonnull id<MTLTexture>)rgbaTex
                        grContext:(nonnull GrDirectContext*)grContext
                            width:(size_t)width
                           height:(size_t)height;

@end

@interface FlutterDarwinExternalTextureMetal : NSObject

- (nullable instancetype)initWithTextureCache:(nonnull CVMetalTextureCacheRef)textureCache
                                    textureID:(int64_t)textureID
                                      texture:(nonnull NSObject<FlutterTexture>*)texture
                               enableImpeller:(BOOL)enableImpeller;

- (void)paintContext:(flutter::Texture::PaintContext&)context
              bounds:(const SkRect&)bounds
              freeze:(BOOL)freeze
            sampling:(const flutter::DlImageSampling)sampling;

- (void)onGrContextCreated;

- (void)onGrContextDestroyed;

- (void)markNewFrameAvailable;

- (void)onTextureUnregistered;

@property(nonatomic, readonly) int64_t textureID;

@end
