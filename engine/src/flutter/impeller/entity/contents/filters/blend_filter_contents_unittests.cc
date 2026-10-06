// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "gmock/gmock.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/filters/blend_filter_contents.h"
#include "impeller/entity/entity_playground.h"

namespace impeller {
namespace testing {

class BlendFilterContentsTest : public EntityPlayground {
 public:
  /// Create a texture that has been cleared to transparent black.
  std::shared_ptr<Texture> MakeTexture(ISize size) {
    std::shared_ptr<CommandBuffer> command_buffer =
        GetContentContext().GetContext()->CreateCommandBuffer();
    if (!command_buffer) {
      return nullptr;
    }

    auto render_target = GetContentContext().MakeSubpass(
        "Clear Subpass", size, command_buffer,
        [](const ContentContext&, RenderPass&) { return true; });

    if (!GetContentContext()
             .GetContext()
             ->GetCommandQueue()
             ->Submit(/*buffers=*/{command_buffer})
             .ok()) {
      return nullptr;
    }

    if (render_target.ok()) {
      return render_target.value().GetRenderTargetTexture();
    }
    return nullptr;
  }
};
INSTANTIATE_PLAYGROUND_SUITE(BlendFilterContentsTest);

// https://github.com/flutter/flutter/issues/149216
TEST_P(BlendFilterContentsTest, AdvancedBlendColorAlignsColorTo4) {
  std::shared_ptr<Texture> texture = MakeTexture(ISize(100, 100));
  BlendFilterContents filter_contents;
  filter_contents.SetInputs({FilterInput::Make(texture)});
  filter_contents.SetForegroundColor(Color(1.0, 0.0, 0.0, 1.0));
  filter_contents.SetBlendMode(BlendMode::kColorDodge);

  ContentContext& renderer = GetContentContext();
  // Add random byte to get the HostBuffer in a bad alignment.
  uint8_t byte = 0xff;
  BufferView buffer_view = renderer.GetTransientsDataBuffer().Emplace(
      &byte, /*length=*/1, /*align=*/1);
  EXPECT_EQ(buffer_view.GetRange().offset, 4u);
  EXPECT_EQ(buffer_view.GetRange().length, 1u);
  Entity entity;

  std::optional<Entity> result = filter_contents.GetEntity(
      renderer, entity, /*coverage_hint=*/std::nullopt);

  EXPECT_TRUE(result.has_value());
}

// Without framebuffer fetch, the canvas blends against the backdrop by giving
// it the inverse of the entity transform, so its coverage goes through the
// transform and back and lands slightly off the texture size: a 0.4x scale
// leaves a 2048x1536 backdrop at 2047.99988x1535.99988 and a 0.43x scale at
// 2048.00024x1536.00024. The subpass must still match the backdrop exactly,
// neither dropping its last column and row nor allocating an extra one.
TEST_P(BlendFilterContentsTest, AdvancedBlendSubpassSnapsNearlyIntegralSize) {
  if (GetContentContext().GetDeviceCapabilities().SupportsFramebufferFetch()) {
    GTEST_SKIP() << "Advanced blends use framebuffer fetch on this backend.";
  }
  std::shared_ptr<Texture> backdrop = MakeTexture(ISize(2048, 1536));
  std::shared_ptr<Texture> source = MakeTexture(ISize(100, 100));
  ASSERT_TRUE(backdrop);
  ASSERT_TRUE(source);

  for (Scalar scale : {0.4f, 0.43f}) {
    SCOPED_TRACE(scale);
    Matrix transform = Matrix::MakeScale({scale, scale, 1});
    BlendFilterContents filter_contents;
    filter_contents.SetInputs({FilterInput::Make(backdrop, transform.Invert()),
                               FilterInput::Make(source)});
    filter_contents.SetBlendMode(BlendMode::kScreen);
    Entity entity;
    entity.SetTransform(transform);

    std::optional<Entity> result = filter_contents.GetEntity(
        GetContentContext(), entity, /*coverage_hint=*/std::nullopt);

    ASSERT_TRUE(result.has_value());
    std::optional<Rect> coverage = result->GetCoverage();
    ASSERT_TRUE(coverage.has_value());
    EXPECT_EQ(coverage->GetSize(), Size(2048, 1536));
  }
}

}  // namespace testing
}  // namespace impeller
