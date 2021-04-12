// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterExternalTextureMetal.h"

#include "flutter/fml/platform/darwin/cf_utils.h"

@implementation FlutterExternalTextureMetal {
  FlutterDarwinContextMetal* _darwinMetalContext;

  int64_t _textureID;

  id<FlutterTexture> _texture;

  std::vector<FlutterMetalTextureHandle> _textures;
}

- (instancetype)initWithFlutterTexture:(id<FlutterTexture>)texture
                    darwinMetalContext:(FlutterDarwinContextMetal*)context {
  self = [super init];
  if (self) {
    _texture = texture;
    _textureID = reinterpret_cast<int64_t>(_texture);
    _darwinMetalContext = context;
  }
  return self;
}

- (int64_t)textureID {
  return _textureID;
}

- (BOOL)populateTexture:(FlutterMetalExternalTexture*)textureOut {
  // Copy the pixel buffer from the FlutterTexture instance implemented on the user side.
  fml::CFRef<CVPixelBufferRef> pixelBuffer([_texture copyPixelBuffer]);

  if (!pixelBuffer) {
    return NO;
  }

  SkISize textureSize =
      SkISize::Make(CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));

  CVMetalTextureRef cvMetalTexture = nullptr;
  CVReturn cvReturn =
      CVMetalTextureCacheCreateTextureFromImage(/*allocator=*/kCFAllocatorDefault,
                                                /*textureCache=*/_darwinMetalContext.textureCache,
                                                /*sourceImage=*/pixelBuffer,
                                                /*textureAttributes=*/nullptr,
                                                /*pixelFormat=*/MTLPixelFormatBGRA8Unorm,
                                                /*width=*/textureSize.width(),
                                                /*height=*/textureSize.height(),
                                                /*planeIndex=*/0u,
                                                /*texture=*/&cvMetalTexture);

  if (cvReturn != kCVReturnSuccess) {
    NSLog(@"Could not create Metal texture from pixel buffer: CVReturn %d", cvReturn);
    return NO;
  }

  _textures = {(__bridge FlutterMetalTextureHandle)CVMetalTextureGetTexture(cvMetalTexture)};
  CVBufferRelease(cvMetalTexture);

  textureOut->num_textures = 1;
  textureOut->height = textureSize.height();
  textureOut->width = textureSize.width();
  textureOut->pixel_format = FlutterMetalExternalTexturePixelFormat::kRGBA;
  textureOut->textures = _textures.data();

  return YES;
}

@end
