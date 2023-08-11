// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/graphics/FlutterDarwinExternalTextureMetal.h"
#include "flutter/display_list/image/dl_image.h"
#include "impeller/base/validation.h"
#include "impeller/display_list/dl_image_impeller.h"
#include "impeller/renderer/backend/metal/texture_mtl.h"
#include "third_party/skia/include/core/SkColorSpace.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkYUVAInfo.h"
#include "third_party/skia/include/gpu/GrBackendSurface.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"
#include "third_party/skia/include/gpu/GrYUVABackendTextures.h"
#include "third_party/skia/include/gpu/ganesh/SkImageGanesh.h"
#include "third_party/skia/include/ports/SkCFObject.h"

FLUTTER_ASSERT_ARC

@implementation FlutterDarwinExternalTextureMetal {
  CVMetalTextureCacheRef _textureCache;
  NSObject<FlutterTexture>* _externalTexture;
  BOOL _textureFrameAvailable;
  sk_sp<flutter::DlImage> _externalImage;
  CVPixelBufferRef _lastPixelBuffer;
  OSType _pixelFormat;
  BOOL _enableImpeller;
}

- (instancetype)initWithTextureCache:(nonnull CVMetalTextureCacheRef)textureCache
                           textureID:(int64_t)textureID
                             texture:(NSObject<FlutterTexture>*)texture
                      enableImpeller:(BOOL)enableImpeller {
  if (self = [super init]) {
    _textureCache = textureCache;
    CFRetain(_textureCache);
    _textureID = textureID;
    _externalTexture = texture;
    _enableImpeller = enableImpeller;
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

- (void)paintContext:(flutter::Texture::PaintContext&)context
              bounds:(const SkRect&)bounds
              freeze:(BOOL)freeze
            sampling:(const flutter::DlImageSampling)sampling {
  const bool needsUpdatedTexture = (!freeze && _textureFrameAvailable) || !_externalImage;

  if (needsUpdatedTexture) {
    [self onNeedsUpdatedTexture:context];
  }

  if (_externalImage) {
    context.canvas->DrawImageRect(_externalImage,                                // image
                                  SkRect::Make(_externalImage->bounds()),        // source rect
                                  bounds,                                        // destination rect
                                  sampling,                                      // sampling
                                  context.paint,                                 // paint
                                  flutter::DlCanvas::SrcRectConstraint::kStrict  // enforce edges
    );
  }
}

- (void)onNeedsUpdatedTexture:(flutter::Texture::PaintContext&)context {
  CVPixelBufferRef pixelBuffer = [_externalTexture copyPixelBuffer];
  if (pixelBuffer) {
    CVPixelBufferRelease(_lastPixelBuffer);
    _lastPixelBuffer = pixelBuffer;
    _pixelFormat = CVPixelBufferGetPixelFormatType(_lastPixelBuffer);
  }

  // If the application told us there was a texture frame available but did not provide one when
  // asked for it, reuse the previous texture but make sure to ask again the next time around.
  sk_sp<flutter::DlImage> image = [self wrapExternalPixelBuffer:_lastPixelBuffer context:context];
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

- (sk_sp<flutter::DlImage>)wrapExternalPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                           context:(flutter::Texture::PaintContext&)context {
  if (!pixelBuffer) {
    return nullptr;
  }

  sk_sp<flutter::DlImage> image = nullptr;
  if (_pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange ||
      _pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
    image = [self wrapNV12ExternalPixelBuffer:pixelBuffer context:context];
  } else {
    image = [self wrapRGBAExternalPixelBuffer:pixelBuffer context:context];
  }

  if (!image) {
    FML_DLOG(ERROR) << "Could not wrap Metal texture as a display list image.";
  }

  return image;
}

- (sk_sp<flutter::DlImage>)wrapNV12ExternalPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                               context:(flutter::Texture::PaintContext&)context {
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

  if (_enableImpeller) {
    impeller::TextureDescriptor yDesc;
    yDesc.storage_mode = impeller::StorageMode::kHostVisible;
    yDesc.format = impeller::PixelFormat::kR8UNormInt;
    yDesc.size = {textureSize.width(), textureSize.height()};
    yDesc.mip_count = 1;
    auto yTexture = impeller::TextureMTL::Wrapper(yDesc, yTex);
    yTexture->SetCoordinateSystem(impeller::TextureCoordinateSystem::kUploadFromHost);

    impeller::TextureDescriptor uvDesc;
    uvDesc.storage_mode = impeller::StorageMode::kHostVisible;
    uvDesc.format = impeller::PixelFormat::kR8G8UNormInt;
    uvDesc.size = {textureSize.width() / 2, textureSize.height() / 2};
    uvDesc.mip_count = 1;
    auto uvTexture = impeller::TextureMTL::Wrapper(uvDesc, uvTex);
    uvTexture->SetCoordinateSystem(impeller::TextureCoordinateSystem::kUploadFromHost);

    impeller::YUVColorSpace yuvColorSpace =
        _pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
            ? impeller::YUVColorSpace::kBT601LimitedRange
            : impeller::YUVColorSpace::kBT601FullRange;

    return impeller::DlImageImpeller::MakeFromYUVTextures(context.aiks_context, yTexture, uvTexture,
                                                          yuvColorSpace);
  }

  SkYUVColorSpace colorSpace = _pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
                                   ? kRec601_Limited_SkYUVColorSpace
                                   : kJPEG_Full_SkYUVColorSpace;
  auto skImage = [FlutterDarwinExternalTextureSkImageWrapper wrapYUVATexture:yTex
                                                                       UVTex:uvTex
                                                               YUVColorSpace:colorSpace
                                                                   grContext:context.gr_context
                                                                       width:textureSize.width()
                                                                      height:textureSize.height()];
  if (!skImage) {
    return nullptr;
  }

  // This image should not escape local use by this flutter::Texture implementation
  return flutter::DlImage::Make(skImage);
}

- (sk_sp<flutter::DlImage>)wrapRGBAExternalPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                               context:(flutter::Texture::PaintContext&)context {
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

  if (_enableImpeller) {
    impeller::TextureDescriptor desc;
    desc.storage_mode = impeller::StorageMode::kHostVisible;
    desc.format = impeller::PixelFormat::kB8G8R8A8UNormInt;
    desc.size = {textureSize.width(), textureSize.height()};
    desc.mip_count = 1;
    auto texture = impeller::TextureMTL::Wrapper(desc, rgbaTex);
    texture->SetCoordinateSystem(impeller::TextureCoordinateSystem::kUploadFromHost);
    return impeller::DlImageImpeller::Make(texture);
  }

  auto skImage = [FlutterDarwinExternalTextureSkImageWrapper wrapRGBATexture:rgbaTex
                                                                   grContext:context.gr_context
                                                                       width:textureSize.width()
                                                                      height:textureSize.height()];
  if (!skImage) {
    return nullptr;
  }

  // This image should not escape local use by this flutter::Texture implementation
  return flutter::DlImage::Make(skImage);
}

@end

@implementation FlutterDarwinExternalTextureSkImageWrapper

+ (sk_sp<SkImage>)wrapYUVATexture:(id<MTLTexture>)yTex
                            UVTex:(id<MTLTexture>)uvTex
                    YUVColorSpace:(SkYUVColorSpace)colorSpace
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
                      SkYUVAInfo::Subsampling::k444, colorSpace);
  GrYUVABackendTextures yuvaBackendTextures(yuvaInfo, skiaBackendTextures,
                                            kTopLeft_GrSurfaceOrigin);

  return SkImages::TextureFromYUVATextures(grContext, yuvaBackendTextures,
                                           /*imageColorSpace=*/nullptr,
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

  return SkImages::BorrowTextureFrom(grContext, skiaBackendTexture, kTopLeft_GrSurfaceOrigin,
                                     kBGRA_8888_SkColorType, kPremul_SkAlphaType,
                                     /*imageColorSpace=*/nullptr, /*releaseProc*/ nullptr,
                                     /*releaseContext*/ nullptr);
}
@end
