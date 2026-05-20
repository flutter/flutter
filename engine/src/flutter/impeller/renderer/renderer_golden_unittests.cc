// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Golden tests for the low-level renderer API. Unlike renderer_unittests.cc,
// which opens an interactive playground, the tests here render through the
// golden harness and have their output uploaded to Skia Gold. They only build
// as part of the golden test executable.

#ifdef IMPELLER_GOLDEN_TESTS

#include "flutter/impeller/golden_tests/golden_playground_test.h"
#include "impeller/core/formats.h"
#include "impeller/core/host_buffer.h"
#include "impeller/fixtures/baby.frag.h"
#include "impeller/fixtures/baby.vert.h"
#include "impeller/geometry/color.h"
#include "impeller/playground/playground_test.h"
#include "impeller/renderer/pipeline_builder.h"
#include "impeller/renderer/pipeline_library.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/vertex_buffer_builder.h"

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

}  // namespace testing
}  // namespace impeller

#endif  // IMPELLER_GOLDEN_TESTS
