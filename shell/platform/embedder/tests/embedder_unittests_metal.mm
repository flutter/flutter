// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include <string>
#include <vector>

#import <Metal/Metal.h>

#include "embedder.h"
#include "flutter/shell/platform/embedder/tests/embedder_assertions.h"
#include "flutter/shell/platform/embedder/tests/embedder_config_builder.h"
#include "flutter/shell/platform/embedder/tests/embedder_test.h"
#include "flutter/shell/platform/embedder/tests/embedder_test_context_metal.h"
#include "flutter/shell/platform/embedder/tests/embedder_unittests_util.h"
#include "flutter/testing/assertions_skia.h"
#include "flutter/testing/testing.h"

namespace flutter {
namespace testing {

using EmbedderTest = testing::EmbedderTest;

TEST_F(EmbedderTest, CanRenderGradientWithMetal) {
  auto& context = GetEmbedderContext(EmbedderTestContextType::kMetalContext);

  EmbedderConfigBuilder builder(context);

  builder.SetDartEntrypoint("render_gradient");
  builder.SetMetalRendererConfig(SkISize::Make(800, 600));

  auto rendered_scene = context.GetNextSceneImage();

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  // Send a window metrics events so frames may be scheduled.
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = 800;
  event.height = 600;
  event.pixel_ratio = 1.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event), kSuccess);

  // TODO (https://github.com/flutter/flutter/issues/73590): re-enable once
  // we are able to figure out why this fails on the bots.
  // ASSERT_TRUE(ImageMatchesFixture("gradient_metal.png", rendered_scene));
}

static sk_sp<SkSurface> GetSurfaceFromTexture(sk_sp<GrDirectContext> skia_context,
                                              SkISize texture_size,
                                              void* texture) {
  GrMtlTextureInfo info;
  info.fTexture.reset([(id<MTLTexture>)texture retain]);
  GrBackendTexture backend_texture(texture_size.width(), texture_size.height(), GrMipmapped::kNo,
                                   info);

  return SkSurface::MakeFromBackendTexture(skia_context.get(), backend_texture,
                                           kTopLeft_GrSurfaceOrigin, 1, kBGRA_8888_SkColorType,
                                           nullptr, nullptr);
}

TEST_F(EmbedderTest, ExternalTextureMetal) {
  EmbedderTestContextMetal& context = reinterpret_cast<EmbedderTestContextMetal&>(
      GetEmbedderContext(EmbedderTestContextType::kMetalContext));

  const auto texture_size = SkISize::Make(800, 600);
  const int64_t texture_id = 1;

  TestMetalContext* metal_context = context.GetTestMetalContext();
  TestMetalContext::TextureInfo texture_info = metal_context->CreateMetalTexture(texture_size);

  sk_sp<SkSurface> surface =
      GetSurfaceFromTexture(metal_context->GetSkiaContext(), texture_size, texture_info.texture);
  auto canvas = surface->getCanvas();
  canvas->clear(SK_ColorRED);
  metal_context->GetSkiaContext()->flushAndSubmit();

  std::vector<FlutterMetalTextureHandle> textures{texture_info.texture};

  context.SetExternalTextureCallback(
      [&](int64_t id, size_t w, size_t h, FlutterMetalExternalTexture* output) {
        EXPECT_TRUE(w == texture_size.width());
        EXPECT_TRUE(h == texture_size.height());
        EXPECT_TRUE(texture_id == id);
        output->num_textures = 1;
        output->height = h;
        output->width = w;
        output->pixel_format = FlutterMetalExternalTexturePixelFormat::kRGBA;
        output->textures = textures.data();
        return true;
      });

  EmbedderConfigBuilder builder(context);

  builder.SetDartEntrypoint("render_texture");
  builder.SetMetalRendererConfig(texture_size);

  auto engine = builder.LaunchEngine();
  ASSERT_TRUE(engine.is_valid());

  ASSERT_EQ(FlutterEngineRegisterExternalTexture(engine.get(), texture_id), kSuccess);

  auto rendered_scene = context.GetNextSceneImage();

  // Send a window metrics events so frames may be scheduled.
  FlutterWindowMetricsEvent event = {};
  event.struct_size = sizeof(event);
  event.width = texture_size.width();
  event.height = texture_size.height();
  event.pixel_ratio = 1.0;
  ASSERT_EQ(FlutterEngineSendWindowMetricsEvent(engine.get(), &event), kSuccess);

  ASSERT_TRUE(ImageMatchesFixture("external_texture_metal.png", rendered_scene));
}

}  // namespace testing
}  // namespace flutter
