// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Golden tests for the low-level renderer API. Unlike renderer_unittests.cc,
// which opens an interactive playground, the tests here render through the
// golden harness and have their output uploaded to Skia Gold. They only build
// as part of the golden test executable.

#ifdef IMPELLER_GOLDEN_TESTS

#include <array>
#include <cstdint>
#include <vector>

#include "flutter/impeller/golden_tests/golden_playground_test.h"
#include "impeller/core/formats.h"
#include "impeller/core/host_buffer.h"
#include "impeller/core/sampler_descriptor.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/fixtures/baby.frag.h"
#include "impeller/fixtures/baby.vert.h"
#include "impeller/fixtures/texture.frag.h"
#include "impeller/fixtures/texture.vert.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/matrix.h"
#include "impeller/playground/playground_test.h"
#include "impeller/renderer/pipeline_builder.h"
#include "impeller/renderer/pipeline_library.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/vertex_buffer_builder.h"

// TODO(zanderso): https://github.com/flutter/flutter/issues/127701
// NOLINTBEGIN(bugprone-unchecked-optional-access)

namespace impeller {
namespace testing {

using RendererGoldenTest = GoldenPlaygroundTest;
INSTANTIATE_PLAYGROUND_SUITE(RendererGoldenTest);

// Ported from RendererTest.BabysFirstTriangle. Draws a single gradient
// triangle straight through the renderer API. The shader's time uniform is
// pinned to zero so the golden is deterministic.
TEST_P(RendererGoldenTest, BabysFirstTriangle) {
  using VS = BabyVertexShader;
  using FS = BabyFragmentShader;

  std::shared_ptr<Context> context = GetContext();
  ASSERT_TRUE(context);

  auto desc = PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(desc.has_value());
  // Match the golden harness render target: single-sampled, no depth/stencil.
  // `ClearStencilAttachments` also resets the stencil pixel format on the
  // pipeline, which Metal validation requires to match the target's lack of a
  // stencil texture; `SetStencilAttachmentDescriptors(nullopt)` alone leaves
  // the format set and trips that validation.
  desc->SetSampleCount(SampleCount::kCount1);
  desc->ClearStencilAttachments();
  desc->ClearDepthAttachment();
  auto pipeline = context->GetPipelineLibrary()->GetPipeline(desc).Get();
  ASSERT_TRUE(pipeline);

  VertexBufferBuilder<VS::PerVertexData> vertex_buffer_builder;
  vertex_buffer_builder.AddVertices({
      {{-0.5, -0.5}, Color::Red(), Color::Green()},
      {{0.0, 0.5}, Color::Green(), Color::Blue()},
      {{0.5, -0.5}, Color::Blue(), Color::Red()},
  });
  auto vertex_buffer = vertex_buffer_builder.CreateVertexBuffer(
      *context->GetResourceAllocator());

  auto host_buffer = HostBuffer::Create(
      context->GetResourceAllocator(), context->GetIdleWaiter(),
      context->GetCapabilities()->GetMinimumUniformAlignment());

  ASSERT_TRUE(OpenPlaygroundHere([&](RenderPass& pass) -> bool {
    // The harness runs the callback once per pass; start each from a clean
    // host buffer.
    host_buffer->Reset();
    pass.SetPipeline(pipeline);
    pass.SetVertexBuffer(vertex_buffer);

    FS::FragInfo frag_info;
    frag_info.time = 0.0f;
    FS::BindFragInfo(pass, host_buffer->EmplaceUniform(frag_info));

    return pass.Draw().ok();
  }));
}

// Uploads a block-compressed (BC1/DXT1) texture and samples it onto a
// fullscreen quad. The texture is an 8x8 image laid out as a 2x2 grid of solid
// color blocks, so the golden is four colored quadrants. BC1 is the most widely
// supported compressed family on desktop GPUs; backends without it are skipped.
TEST_P(RendererGoldenTest, CanRenderBC1CompressedTexture) {
  using VS = TextureVertexShader;
  using FS = TextureFragmentShader;

  std::shared_ptr<Context> context = GetContext();
  ASSERT_TRUE(context);

  if (!context->GetCapabilities()->SupportsTextureCompression(
          CompressedTextureFamily::kBC)) {
    GTEST_SKIP() << "Backend does not support BC texture compression.";
  }

  // A solid-color BC1 block stores the color in both RGB565 endpoints with
  // all-zero selector bits, which decodes to a single opaque color.
  auto bc1_solid_block = [](uint16_t rgb565) -> std::array<uint8_t, 8> {
    const auto lo = static_cast<uint8_t>(rgb565 & 0xFF);
    const auto hi = static_cast<uint8_t>(rgb565 >> 8);
    return {{lo, hi, lo, hi, 0, 0, 0, 0}};
  };
  // RGB565: red, green, blue, white.
  const std::array<std::array<uint8_t, 8>, 4> blocks = {{
      bc1_solid_block(0xF800), bc1_solid_block(0x07E0),
      bc1_solid_block(0x001F), bc1_solid_block(0xFFFF)}};
  std::vector<uint8_t> data;
  for (const auto& block : blocks) {
    data.insert(data.end(), block.begin(), block.end());
  }

  TextureDescriptor texture_desc;
  texture_desc.storage_mode = StorageMode::kHostVisible;
  texture_desc.format = PixelFormat::kBC1RGBAUNormInt;
  texture_desc.size = ISize{8, 8};
  texture_desc.mip_count = 1u;
  texture_desc.usage = TextureUsage::kShaderRead;
  auto texture = context->GetResourceAllocator()->CreateTexture(texture_desc);
  ASSERT_TRUE(texture);
  ASSERT_TRUE(texture->SetContents(data.data(), data.size()));

  auto desc = PipelineBuilder<VS, FS>::MakeDefaultPipelineDescriptor(*context);
  ASSERT_TRUE(desc.has_value());
  desc->SetSampleCount(SampleCount::kCount1);
  desc->ClearStencilAttachments();
  desc->ClearDepthAttachment();
  auto pipeline = context->GetPipelineLibrary()->GetPipeline(desc).Get();
  ASSERT_TRUE(pipeline);

  // A fullscreen quad in normalized device coordinates with an identity MVP.
  VertexBufferBuilder<VS::PerVertexData> vertex_buffer_builder;
  vertex_buffer_builder.AddVertices({
      {{-1, -1, 0.0}, {0.0, 0.0}},
      {{1, -1, 0.0}, {1.0, 0.0}},
      {{1, 1, 0.0}, {1.0, 1.0}},
      {{-1, -1, 0.0}, {0.0, 0.0}},
      {{1, 1, 0.0}, {1.0, 1.0}},
      {{-1, 1, 0.0}, {0.0, 1.0}},
  });
  auto vertex_buffer = vertex_buffer_builder.CreateVertexBuffer(
      *context->GetResourceAllocator());

  const auto& sampler = context->GetSamplerLibrary()->GetSampler({});

  auto host_buffer = HostBuffer::Create(
      context->GetResourceAllocator(), context->GetIdleWaiter(),
      context->GetCapabilities()->GetMinimumUniformAlignment());

  ASSERT_TRUE(OpenPlaygroundHere([&](RenderPass& pass) -> bool {
    host_buffer->Reset();
    pass.SetPipeline(pipeline);
    pass.SetVertexBuffer(vertex_buffer);

    VS::UniformBuffer uniforms;
    uniforms.mvp = Matrix();
    VS::BindUniformBuffer(pass, host_buffer->EmplaceUniform(uniforms));
    FS::BindTextureContents(pass, texture, sampler);

    return pass.Draw().ok();
  }));
}

}  // namespace testing
}  // namespace impeller

// NOLINTEND(bugprone-unchecked-optional-access)

#endif  // IMPELLER_GOLDEN_TESTS
