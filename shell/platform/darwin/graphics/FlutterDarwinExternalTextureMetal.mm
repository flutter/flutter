// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/graphics/FlutterDarwinExternalTextureMetal.h"

#include "flutter/fml/logging.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#include "third_party/skia/include/core/SkColorSpace.h"
#include "third_party/skia/include/core/SkYUVAInfo.h"
#include "third_party/skia/include/gpu/GrBackendSurface.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"
#include "third_party/skia/include/gpu/GrYUVABackendTextures.h"
#include "third_party/skia/include/gpu/mtl/GrMtlTypes.h"

FLUTTER_ASSERT_ARC

@implementation FlutterDarwinExternalTextureMetal {
  CVMetalTextureCacheRef _textureCache;
  NSObject<FlutterTexture>* _externalTexture;
  BOOL _textureFrameAvailable;
  sk_sp<SkImage> _externalImage;
  CVPixelBufferRef _lastPixelBuffer;
  OSType _pixelFormat;
}

- (instancetype)initWithTextureCache:(nonnull CVMetalTextureCacheRef)textureCache
                           textureID:(int64_t)textureID
                             texture:(NSObject<FlutterTexture>*)texture {
  if (self = [super init]) {
    _textureCache = textureCache;
    CFRetain(_textureCache);
    _textureID = textureID;
    _externalTexture = texture;
    return self;
  }
  return nil;
}

- (void)dealloc {
  CVPixelBufferRelease(_lastPixelBuffer);
  if (_textureCache) {
    CVMetalTextureCacheFlush(_textureCache,  // cache
                             0               // options (must be zero)
    );
    CFRelease(_textureCache);
  }
}

- (void)canvas:(SkCanvas&)canvas
        bounds:(const SkRect&)bounds
        freeze:(BOOL)freeze
     grContext:(nonnull GrDirectContext*)grContext
      sampling:(const SkSamplingOptions&)sampling
         paint:(nullable const SkPaint*)paint {
  const bool needsUpdatedTexture = (!freeze && _textureFrameAvailable) || !_externalImage;

  if (needsUpdatedTexture) {
    [self onNeedsUpdatedTexture:grContext];
  }

  if (_externalImage) {
    canvas.drawImageRect(_externalImage,                                       // image
                         SkRect::Make(_externalImage->bounds()),               // source rect
                         bounds,                                               // destination rect
                         sampling,                                             // sampling
                         paint,                                                // paint
                         SkCanvas::SrcRectConstraint::kFast_SrcRectConstraint  // constraint
    );
  }
}

- (void)onNeedsUpdatedTexture:(nonnull GrDirectContext*)grContext {
  CVPixelBufferRef pixelBuffer = [_externalTexture copyPixelBuffer];
  if (pixelBuffer) {
    CVPixelBufferRelease(_lastPixelBuffer);
    _lastPixelBuffer = pixelBuffer;
    _pixelFormat = CVPixelBufferGetPixelFormatType(_lastPixelBuffer);
  }

  // If the application told us there was a texture frame available but did not provide one when
  // asked for it, reuse the previous texture but make sure to ask again the next time around.
  sk_sp<SkImage> image = [self wrapExternalPixelBuffer:_lastPixelBuffer grContext:grContext];
  if (image) {
    _externalImage = image;
    _textureFrameAvailable = false;
  }
}

- (void)onGrContextCreated {
  // External images in this backend have no thread affinity and are not tied to the context in any
  // way. Instead, they are tied to the Metal device which is associated with the cache already and
  // is consistent throughout the shell run.
}

- (void)onGrContextDestroyed {
  // The image must be reset because it is tied to the onscreen context. But the pixel buffer that
  // created the image is still around. In case of context reacquisition, that last pixel
  // buffer will be used to materialize the image in case the application fails to provide a new
  // one.
  _externalImage.reset();
  CVMetalTextureCacheFlush(_textureCache,  // cache
                           0               // options (must be zero)
  );
}

- (void)markNewFrameAvailable {
  _textureFrameAvailable = YES;
}

- (void)onTextureUnregistered {
  if ([_externalTexture respondsToSelector:@selector(onTextureUnregistered:)]) {
    [_externalTexture onTextureUnregistered:_externalTexture];
  }
}

#pragma mark - External texture skia wrapper methods.

- (sk_sp<SkImage>)wrapExternalPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                grContext:(GrDirectContext*)grContext {
  if (!pixelBuffer) {
    return nullptr;
  }

  sk_sp<SkImage> image = nullptr;
  if (_pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange ||
      _pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
    image = [self wrapNV12ExternalPixelBuffer:pixelBuffer grContext:grContext];
  } else {
    image = [self wrapRGBAExternalPixelBuffer:pixelBuffer grContext:grContext];
  }

  if (!image) {
    FML_DLOG(ERROR) << "Could not wrap Metal texture as a Skia image.";
  }

  return image;
}

- (sk_sp<SkImage>)wrapNV12ExternalPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                    grContext:(GrDirectContext*)grContext {
  SkISize textureSize =
      SkISize::Make(CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
  CVMetalTextureRef yMetalTexture = nullptr;
  {
    CVReturn cvReturn =
        CVMetalTextureCacheCreateTextureFromImage(/*allocator=*/kCFAllocatorDefault,
                                                  /*textureCache=*/_textureCache,
                                                  /*sourceImage=*/pixelBuffer,
                                                  /*textureAttributes=*/nullptr,
                                                  /*pixelFormat=*/MTLPixelFormatR8Unorm,
                                                  /*width=*/textureSize.width(),
                                                  /*height=*/textureSize.height(),
                                                  /*planeIndex=*/0u,
                                                  /*texture=*/&yMetalTexture);

    if (cvReturn != kCVReturnSuccess) {
      FML_DLOG(ERROR) << "Could not create Metal texture from pixel buffer: CVReturn " << cvReturn;
      return nullptr;
    }
  }

  CVMetalTextureRef uvMetalTexture = nullptr;
  {
    CVReturn cvReturn =
        CVMetalTextureCacheCreateTextureFromImage(/*allocator=*/kCFAllocatorDefault,
                                                  /*textureCache=*/_textureCache,
                                                  /*sourceImage=*/pixelBuffer,
                                                  /*textureAttributes=*/nullptr,
                                                  /*pixelFormat=*/MTLPixelFormatRG8Unorm,
                                                  /*width=*/textureSize.width() / 2,
                                                  /*height=*/textureSize.height() / 2,
                                                  /*planeIndex=*/1u,
                                                  /*texture=*/&uvMetalTexture);

    if (cvReturn != kCVReturnSuccess) {
      FML_DLOG(ERROR) << "Could not create Metal texture from pixel buffer: CVReturn " << cvReturn;
      return nullptr;
    }
  }

  id<MTLTexture> yTex = CVMetalTextureGetTexture(yMetalTexture);
  CVBufferRelease(yMetalTexture);

  id<MTLTexture> uvTex = CVMetalTextureGetTexture(uvMetalTexture);
  CVBufferRelease(uvMetalTexture);

  return [FlutterDarwinExternalTextureSkImageWrapper wrapYUVATexture:yTex
                                                               UVTex:uvTex
                                                           grContext:grContext
                                                               width:textureSize.width()
                                                              height:textureSize.height()];
}

- (sk_sp<SkImage>)wrapRGBAExternalPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                    grContext:(GrDirectContext*)grContext {
  SkISize textureSize =
      SkISize::Make(CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
  CVMetalTextureRef metalTexture = nullptr;
  CVReturn cvReturn =
      CVMetalTextureCacheCreateTextureFromImage(/*allocator=*/kCFAllocatorDefault,
                                                /*textureCache=*/_textureCache,
                                                /*sourceImage=*/pixelBuffer,
                                                /*textureAttributes=*/nullptr,
                                                /*pixelFormat=*/MTLPixelFormatBGRA8Unorm,
                                                /*width=*/textureSize.width(),
                                                /*height=*/textureSize.height(),
                                                /*planeIndex=*/0u,
                                                /*texture=*/&metalTexture);

  if (cvReturn != kCVReturnSuccess) {
    FML_DLOG(ERROR) << "Could not create Metal texture from pixel buffer: CVReturn " << cvReturn;
    return nullptr;
  }

  id<MTLTexture> rgbaTex = CVMetalTextureGetTexture(metalTexture);
  CVBufferRelease(metalTexture);

  return [FlutterDarwinExternalTextureSkImageWrapper wrapRGBATexture:rgbaTex
                                                           grContext:grContext
                                                               width:textureSize.width()
                                                              height:textureSize.height()];
}

@end

@implementation FlutterDarwinExternalTextureSkImageWrapper

+ (sk_sp<SkImage>)wrapYUVATexture:(id<MTLTexture>)yTex
                            UVTex:(id<MTLTexture>)uvTex
                        grContext:(nonnull GrDirectContext*)grContext
                            width:(size_t)width
                           height:(size_t)height {
  GrMtlTextureInfo ySkiaTextureInfo;
  ySkiaTextureInfo.fTexture = sk_cfp<const void*>{(__bridge_retained const void*)yTex};

  GrBackendTexture skiaBackendTextures[2];
  skiaBackendTextures[0] = GrBackendTexture(/*width=*/width,
                                            /*height=*/height,
                                            /*mipMapped=*/GrMipMapped::kNo,
                                            /*textureInfo=*/ySkiaTextureInfo);

  GrMtlTextureInfo uvSkiaTextureInfo;
  uvSkiaTextureInfo.fTexture = sk_cfp<const void*>{(__bridge_retained const void*)uvTex};

  skiaBackendTextures[1] = GrBackendTexture(/*width=*/width,
                                            /*height=*/height,
                                            /*mipMapped=*/GrMipMapped::kNo,
                                            /*textureInfo=*/uvSkiaTextureInfo);
  SkYUVAInfo yuvaInfo(skiaBackendTextures[0].dimensions(), SkYUVAInfo::PlaneConfig::kY_UV,
                      SkYUVAInfo::Subsampling::k444, kRec601_SkYUVColorSpace);
  GrYUVABackendTextures yuvaBackendTextures(yuvaInfo, skiaBackendTextures,
                                            kTopLeft_GrSurfaceOrigin);

  return SkImage::MakeFromYUVATextures(grContext, yuvaBackendTextures, /*imageColorSpace=*/nullptr,
                                       /*releaseProc*/ nullptr, /*releaseContext*/ nullptr);
}

+ (sk_sp<SkImage>)wrapRGBATexture:(id<MTLTexture>)rgbaTex
                        grContext:(nonnull GrDirectContext*)grContext
                            width:(size_t)width
                           height:(size_t)height {
  GrMtlTextureInfo skiaTextureInfo;
  skiaTextureInfo.fTexture = sk_cfp<const void*>{(__bridge_retained const void*)rgbaTex};

  GrBackendTexture skiaBackendTexture(/*width=*/width,
                                      /*height=*/height,
                                      /*mipMapped=*/GrMipMapped ::kNo,
                                      /*textureInfo=*/skiaTextureInfo);

  return SkImage::MakeFromTexture(grContext, skiaBackendTexture, kTopLeft_GrSurfaceOrigin,
                                  kBGRA_8888_SkColorType, kPremul_SkAlphaType,
                                  /*imageColorSpace=*/nullptr, /*releaseProc*/ nullptr,
                                  /*releaseContext*/ nullptr);
}
@end
