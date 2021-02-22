// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#include <memory>
#include <vector>

#import "flutter/shell/platform/darwin/graphics/FlutterDarwinContextMetal.h"
#import "flutter/shell/platform/darwin/graphics/FlutterDarwinExternalTextureMetal.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/embedder_external_texture_metal.h"
#import "flutter/testing/testing.h"
#include "third_party/googletest/googletest/include/gtest/gtest.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkSamplingOptions.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter::testing {

TEST(FlutterEmbedderExternalTextureUnittests, TestTextureResolution) {
  // constants.
  const size_t width = 100;
  const size_t height = 100;
  const int64_t texture_id = 1;

  // setup the surface.
  FlutterDarwinContextMetal* darwinContextMetal =
      [[FlutterDarwinContextMetal alloc] initWithDefaultMTLDevice];
  SkImageInfo info = SkImageInfo::MakeN32Premul(width, height);
  GrDirectContext* grContext = darwinContextMetal.mainContext.get();
  sk_sp<SkSurface> gpuSurface(SkSurface::MakeRenderTarget(grContext, SkBudgeted::kNo, info));

  // create a texture.
  MTLTextureDescriptor* textureDescriptor = [[MTLTextureDescriptor alloc] init];
  textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
  textureDescriptor.width = width;
  textureDescriptor.height = height;
  textureDescriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
  id<MTLTexture> mtlTexture =
      [darwinContextMetal.device newTextureWithDescriptor:textureDescriptor];
  std::vector<FlutterMetalTextureHandle> textures = {
      (__bridge FlutterMetalTextureHandle)mtlTexture,
  };

  // callback to resolve the texture.
  EmbedderExternalTextureMetal::ExternalTextureCallback callback = [&](int64_t texture_id, size_t w,
                                                                       size_t h) {
    EXPECT_TRUE(w == width);
    EXPECT_TRUE(h == height);

    FlutterMetalExternalTexture* texture = new FlutterMetalExternalTexture();
    texture->struct_size = sizeof(FlutterMetalExternalTexture);
    texture->num_textures = 1;
    texture->height = h;
    texture->width = w;
    texture->pixel_format = FlutterMetalExternalTexturePixelFormat::kRGBA;
    texture->textures = textures.data();

    return std::unique_ptr<FlutterMetalExternalTexture>(texture);
  };

  // render the texture.
  std::unique_ptr<flutter::Texture> texture =
      std::make_unique<EmbedderExternalTextureMetal>(texture_id, callback);
  SkRect bounds = SkRect::MakeWH(info.width(), info.height());
  SkSamplingOptions sampling = SkSamplingOptions(SkFilterMode::kNearest);
  texture->Paint(*gpuSurface->getCanvas(), bounds, /*freeze=*/false, grContext, sampling);

  ASSERT_TRUE(mtlTexture != nil);

  gpuSurface->makeImageSnapshot();
}

}  // namespace flutter::testing
