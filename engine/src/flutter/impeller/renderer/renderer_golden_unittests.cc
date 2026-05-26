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

// Samples a sample-only block-compressed texture across a fullscreen quad
// through the golden harness. The pixel format and the raw block bytes are the
// only things that differ between the compressed families; the texture upload,
// pipeline, quad, and draw are shared by every compressed-format golden below.
static void DrawCompressedTextureGolden(GoldenPlaygroundTest& test,
                                        PixelFormat format,
                                        const std::vector<uint8_t>& block_data,
                                        ISize size) {
  using VS = TextureVertexShader;
  using FS = TextureFragmentShader;

  std::shared_ptr<Context> context = test.GetContext();
  ASSERT_TRUE(context);

  TextureDescriptor texture_desc;
  texture_desc.storage_mode = StorageMode::kHostVisible;
  texture_desc.format = format;
  texture_desc.size = size;
  texture_desc.mip_count = 1u;
  texture_desc.usage = TextureUsage::kShaderRead;
  auto texture = context->GetResourceAllocator()->CreateTexture(texture_desc);
  ASSERT_TRUE(texture);
  ASSERT_TRUE(texture->SetContents(block_data.data(), block_data.size()));

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

  ASSERT_TRUE(test.OpenPlaygroundHere([&](RenderPass& pass) -> bool {
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

// Uploads a block-compressed (BC1/DXT1) texture and samples it onto a
// fullscreen quad. The texture is an 8x8 image laid out as a 2x2 grid of solid
// color blocks, so the golden is four colored quadrants. BC1 is the most widely
// supported compressed family on desktop GPUs; backends without it are skipped.
TEST_P(RendererGoldenTest, CanRenderBC1CompressedTexture) {
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
  const std::array<std::array<uint8_t, 8>, 4> blocks = {
      {bc1_solid_block(0xF800), bc1_solid_block(0x07E0),
       bc1_solid_block(0x001F), bc1_solid_block(0xFFFF)}};
  std::vector<uint8_t> data;
  for (const auto& block : blocks) {
    data.insert(data.end(), block.begin(), block.end());
  }

  DrawCompressedTextureGolden(*this, PixelFormat::kBC1RGBAUNormInt, data,
                              ISize{8, 8});
}

// Uploads an ETC2 RGB8 texture and samples it onto a fullscreen quad. ETC2 is
// the standard compressed family on OpenGL ES 3.0 and mobile GPUs; backends
// without it are skipped. The golden is a single flat mid-gray fill.
TEST_P(RendererGoldenTest, CanRenderETC2CompressedTexture) {
  std::shared_ptr<Context> context = GetContext();
  ASSERT_TRUE(context);
  if (!context->GetCapabilities()->SupportsTextureCompression(
          CompressedTextureFamily::kETC2)) {
    GTEST_SKIP() << "Backend does not support ETC2 texture compression.";
  }

  // In "individual" mode (the differential bit is 0), an ETC2 RGB8 block
  // decodes exactly like ETC1. With both 4x4 sub-blocks sharing one base color
  // and every pixel selecting the same intensity modifier, the block resolves
  // to a single flat color. The 8x8 image is a 2x2 grid of identical 4x4
  // blocks.
  const std::array<uint8_t, 8> etc2_solid_block = {0x88, 0x88, 0x88, 0x00,
                                                   0xFF, 0xFF, 0x00, 0x00};
  std::vector<uint8_t> data;
  for (int i = 0; i < 4; ++i) {
    data.insert(data.end(), etc2_solid_block.begin(), etc2_solid_block.end());
  }

  DrawCompressedTextureGolden(*this, PixelFormat::kETC2RGB8UNormInt, data,
                              ISize{8, 8});
}

// Uploads an ASTC 8x8 LDR texture and samples it onto a fullscreen quad. ASTC
// is common on modern mobile and some desktop GPUs; backends without it are
// skipped. The golden is a single solid opaque-blue fill.
TEST_P(RendererGoldenTest, CanRenderASTCCompressedTexture) {
  std::shared_ptr<Context> context = GetContext();
  ASSERT_TRUE(context);
  if (!context->GetCapabilities()->SupportsTextureCompression(
          CompressedTextureFamily::kASTC)) {
    GTEST_SKIP() << "Backend does not support ASTC texture compression.";
  }

  // An ASTC void-extent block encodes one constant color directly: the 0xFC
  // 0xFD header marks a 2D LDR void-extent with the "no extent" sentinel
  // coordinates (all ones), followed by four little-endian UNORM16 channels.
  // This block is opaque blue (R=0, G=0, B=1, A=1). A single 8x8 ASTC block
  // tiles the 8x8 image exactly once.
  const std::vector<uint8_t> data = {0xFC, 0xFD, 0xFF, 0xFF, 0xFF, 0xFF,
                                     0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00,
                                     0xFF, 0xFF, 0xFF, 0xFF};

  DrawCompressedTextureGolden(*this, PixelFormat::kASTC8x8LDR, data,
                              ISize{8, 8});
}

}  // namespace testing
}  // namespace impeller

// NOLINTEND(bugprone-unchecked-optional-access)

#endif  // IMPELLER_GOLDEN_TESTS
