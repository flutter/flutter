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
// without it are skipped. The 8x8 image is a 2x2 grid of solid color blocks, so
// the golden is the same four colored quadrants as the BC1 and ASTC goldens.
TEST_P(RendererGoldenTest, CanRenderETC2CompressedTexture) {
  std::shared_ptr<Context> context = GetContext();
  ASSERT_TRUE(context);
  if (!context->GetCapabilities()->SupportsTextureCompression(
          CompressedTextureFamily::kETC2)) {
    GTEST_SKIP() << "Backend does not support ETC2 texture compression.";
  }

  // A solid-color ETC2 RGB8 block in "individual" mode (differential bit 0,
  // which decodes like ETC1). The 64-bit block is laid out big-endian (byte 0
  // most significant): byte 0 = R nibbles (R1,R2), byte 1 = G, byte 2 = B,
  // byte 3 = codeword/diff/flip bits (all 0), bytes 4..7 = the two pixel-index
  // bit planes. Both sub-blocks share the base color and every texel uses index
  // 0 (all-zero planes), so the block is one flat color.
  auto etc2_solid_block = [](uint8_t r, uint8_t g,
                             uint8_t b) -> std::array<uint8_t, 8> {
    return {{r, g, b, 0x00, 0x00, 0x00, 0x00, 0x00}};
  };
  // Red, green, blue, white. Each channel byte is 0xFF (nibble 0xF, ~255) or
  // 0x00.
  const std::array<std::array<uint8_t, 8>, 4> blocks = {
      {etc2_solid_block(0xFF, 0x00, 0x00), etc2_solid_block(0x00, 0xFF, 0x00),
       etc2_solid_block(0x00, 0x00, 0xFF), etc2_solid_block(0xFF, 0xFF, 0xFF)}};
  std::vector<uint8_t> data;
  for (const auto& block : blocks) {
    data.insert(data.end(), block.begin(), block.end());
  }

  DrawCompressedTextureGolden(*this, PixelFormat::kETC2RGB8UNormInt, data,
                              ISize{8, 8});
}

// Uploads an ASTC 4x4 LDR texture and samples it onto a fullscreen quad. ASTC
// is common on modern mobile and some desktop GPUs; backends without it are
// skipped. The 8x8 image is a 2x2 grid of solid color blocks, so the golden is
// the same four colored quadrants as the BC1 and ETC2 goldens.
TEST_P(RendererGoldenTest, CanRenderASTCCompressedTexture) {
  std::shared_ptr<Context> context = GetContext();
  ASSERT_TRUE(context);
  if (!context->GetCapabilities()->SupportsTextureCompression(
          CompressedTextureFamily::kASTC)) {
    GTEST_SKIP() << "Backend does not support ASTC texture compression.";
  }

  // An ASTC void-extent block encodes one constant color directly: the 0xFC
  // 0xFD header marks a 2D LDR void-extent with the "no extent" sentinel
  // coordinates (all ones), followed by four little-endian UNORM16 channels
  // (R, G, B, A). Alpha is opaque.
  auto astc_solid_block = [](uint16_t r, uint16_t g,
                             uint16_t b) -> std::array<uint8_t, 16> {
    return {{0xFC, 0xFD, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
             static_cast<uint8_t>(r & 0xFF), static_cast<uint8_t>(r >> 8),
             static_cast<uint8_t>(g & 0xFF), static_cast<uint8_t>(g >> 8),
             static_cast<uint8_t>(b & 0xFF), static_cast<uint8_t>(b >> 8), 0xFF,
             0xFF}};
  };
  // Red, green, blue, white.
  const std::array<std::array<uint8_t, 16>, 4> blocks = {
      {astc_solid_block(0xFFFF, 0, 0), astc_solid_block(0, 0xFFFF, 0),
       astc_solid_block(0, 0, 0xFFFF),
       astc_solid_block(0xFFFF, 0xFFFF, 0xFFFF)}};
  std::vector<uint8_t> data;
  for (const auto& block : blocks) {
    data.insert(data.end(), block.begin(), block.end());
  }

  DrawCompressedTextureGolden(*this, PixelFormat::kASTC4x4LDR, data,
                              ISize{8, 8});
}

}  // namespace testing
}  // namespace impeller

// NOLINTEND(bugprone-unchecked-optional-access)

#endif  // IMPELLER_GOLDEN_TESTS
