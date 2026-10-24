// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cmath>
#include <cstdint>
#include <memory>
#include <vector>

#include "flutter/display_list/effects/image_filters/dl_stretch_image_filter.h"
#include "flutter/fml/mapping.h"
#include "flutter/testing/testing.h"
#include "impeller/core/device_buffer_descriptor.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/filters/stretch_filter_contents.h"
#include "impeller/entity/contents/solid_color_contents.h"
#include "impeller/entity/entity_playground.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/geometry/geometry_asserts.h"
#include "impeller/renderer/blit_pass.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/render_pass.h"

namespace impeller {
namespace testing {

class StretchFilterContentsTest : public EntityPlayground {
 public:
  // Creates a 2-color texture using a subpass render so its coordinate space
  // matches Impeller's render pass orientation across all backends.
  // If vertical_split is true: y < split_pos is Red, y >= split_pos is Blue.
  // Additionally, if overflow_marker_y >= 0, rows [overflow_marker_y,
  // overflow_marker_y + 4) are painted Green to verify identity outside
  // stretch_bounds.
  std::shared_ptr<Texture> MakeTwoColorTexture(ISize size,
                                               bool vertical_split,
                                               Scalar split_pos,
                                               Scalar overflow_marker_y = -1) {
    ContentContext& renderer = GetContentContext();
    std::shared_ptr<CommandBuffer> cmd_buffer =
        renderer.GetContext()->CreateCommandBuffer();
    if (!cmd_buffer) {
      return nullptr;
    }

    auto render_target = renderer.MakeSubpass(
        "TwoColorInput", size, cmd_buffer,
        [&](const ContentContext& ctx, RenderPass& pass) -> bool {
          Rect first_rect = vertical_split
                                ? Rect::MakeLTRB(0, 0, size.width, split_pos)
                                : Rect::MakeLTRB(0, 0, split_pos, size.height);
          Rect second_rect =
              vertical_split
                  ? Rect::MakeLTRB(0, split_pos, size.width, size.height)
                  : Rect::MakeLTRB(split_pos, 0, size.width, size.height);

          auto draw_rect = [&](const Rect& r, Color color) -> bool {
            auto geom = Geometry::MakeRect(r);
            SolidColorContents contents(geom.get());
            contents.SetColor(color);
            Entity e;
            return contents.Render(ctx, e, pass);
          };

          if (!draw_rect(first_rect, Color::Red())) {
            return false;
          }
          if (!draw_rect(second_rect, Color::Blue())) {
            return false;
          }
          if (overflow_marker_y >= 0) {
            Rect marker = Rect::MakeLTRB(0, overflow_marker_y, size.width,
                                         overflow_marker_y + 6);
            if (!draw_rect(marker, Color::Green())) {
              return false;
            }
          }
          return true;
        });

    if (!renderer.GetContext()->GetCommandQueue()->Submit({cmd_buffer}).ok()) {
      return nullptr;
    }
    if (!render_target.ok()) {
      return nullptr;
    }
    return render_target.value().GetRenderTargetTexture();
  }

  std::shared_ptr<DeviceBuffer> ReadTexturePixels(
      const std::shared_ptr<Texture>& texture) {
    auto context = GetContentContext().GetContext();
    std::ignore = context->FlushCommandBuffers();

    DeviceBufferDescriptor buf_desc;
    buf_desc.storage_mode = StorageMode::kHostVisible;
    buf_desc.size = texture->GetTextureDescriptor().GetByteSizeOfBaseMipLevel();
    auto buffer = context->GetResourceAllocator()->CreateBuffer(buf_desc);
    if (!buffer) {
      return nullptr;
    }

    auto cmd_buffer = context->CreateCommandBuffer();
    auto blit_pass = cmd_buffer->CreateBlitPass();
    if (!blit_pass->AddCopy(texture, buffer) || !blit_pass->EncodeCommands()) {
      return nullptr;
    }
    if (!context->GetCommandQueue()->Submit({cmd_buffer}).ok()) {
      return nullptr;
    }
    return buffer;
  }

  // Finds the first row (or column) where Blue dominates Red.
  int FindRedToBlueTransition(const std::shared_ptr<Texture>& texture,
                              bool vertical_split) {
    auto buffer = ReadTexturePixels(texture);
    if (!buffer) {
      return -1;
    }
    const uint8_t* px = buffer->OnGetContents();
    const ISize size = texture->GetSize();
    const int limit = vertical_split ? size.height : size.width;
    const int fixed = (vertical_split ? size.width : size.height) / 2;
    for (int i = 0; i < limit; ++i) {
      const int x = vertical_split ? fixed : i;
      const int y = vertical_split ? i : fixed;
      const size_t idx = (y * size.width + x) * 4;
      const uint8_t r = px[idx + 0];
      const uint8_t g = px[idx + 1];
      const uint8_t b = px[idx + 2];
      // Skip green overflow marker rows.
      if (g > 128 && r < 64 && b < 64) {
        continue;
      }
      if (b > 128 && r < 128) {
        return i;
      }
    }
    return -1;
  }

  // Finds the first row where the Green overflow marker appears.
  int FindGreenMarkerTop(const std::shared_ptr<Texture>& texture) {
    auto buffer = ReadTexturePixels(texture);
    if (!buffer) {
      return -1;
    }
    const uint8_t* px = buffer->OnGetContents();
    const ISize size = texture->GetSize();
    const int x = size.width / 2;
    for (int y = 0; y < size.height; ++y) {
      const size_t idx = (y * size.width + x) * 4;
      const uint8_t r = px[idx + 0];
      const uint8_t g = px[idx + 1];
      const uint8_t b = px[idx + 2];
      if (g > 150 && r < 80 && b < 80) {
        return y;
      }
    }
    return -1;
  }
};

INSTANTIATE_PLAYGROUND_SUITE(StretchFilterContentsTest);

TEST_P(StretchFilterContentsTest,
       PixelReadbackDirectAndComposedWithOverflowContainerUV) {
  const ISize tex_size(100, 200);
  // Container bounds is [0, 40] -> [100, 160] (height 120), while texture is
  // [0, 0] -> [100, 200] (overflowing 40px top and 40px bottom).
  // Split at y = 100 (midpoint of container_uv: norm = (100 - 40) / 120 = 0.5).
  // Overflow green marker at y = 12 (outside stretch_bounds, should remain at
  // y = 12).
  const Rect stretch_bounds = Rect::MakeLTRB(0, 40, 100, 160);
  const Scalar split_y = 100.0f;
  const Scalar marker_y = 12.0f;
  const Scalar interp = 0.7f;

  std::shared_ptr<Texture> v_tex =
      MakeTwoColorTexture(tex_size, /*vertical_split=*/true, split_y, marker_y);
  ASSERT_NE(v_tex, nullptr);

  ContentContext& renderer = GetContentContext();
  // Non-zero entity and effect translation to verify RenderToSnapshot re-basing
  // does not shift container_uv.
  const Matrix offset_transform = Matrix::MakeTranslation({35.0f, 55.0f, 0.0f});

  for (Scalar oy : {0.35f, -0.35f}) {
    const Scalar expected_norm =
        flutter::DlStretchImageFilter::ComputeStretchedNormalizedPosition(
            0.5f, oy, interp);
    const Scalar expected_y =
        stretch_bounds.GetTop() + expected_norm * stretch_bounds.GetHeight();

    auto stretch = FilterContents::MakeStretch(FilterInput::Make(v_tex), 0.0f,
                                               oy, interp, stretch_bounds);
    stretch->SetEffectTransform(offset_transform);

    Entity entity;
    entity.SetTransform(offset_transform);

    // 1. Direct draw into a subpass (re-based to coverage origin).
    std::optional<Entity> direct_entity =
        stretch->GetEntity(renderer, entity, /*coverage_hint=*/{});
    ASSERT_TRUE(direct_entity.has_value());
    EXPECT_TRUE(RectNear(direct_entity->GetCoverage().value(),
                         Rect::MakeXYWH(35, 55, 100, 200)));

    auto cmd_buffer = renderer.GetContext()->CreateCommandBuffer();
    ASSERT_NE(cmd_buffer, nullptr);
    auto direct_rt = renderer.MakeSubpass(
        "DirectDrawSubpass", tex_size, cmd_buffer,
        [&](const ContentContext& ctx, RenderPass& pass) -> bool {
          Entity pass_entity = direct_entity.value().Clone();
          pass_entity.SetTransform(
              Matrix::MakeTranslation({-35.0f, -55.0f, 0.0f}) *
              pass_entity.GetTransform());
          return pass_entity.Render(ctx, pass);
        });
    ASSERT_TRUE(
        renderer.GetContext()->GetCommandQueue()->Submit({cmd_buffer}).ok());
    ASSERT_TRUE(direct_rt.ok());

    int direct_transition = FindRedToBlueTransition(
        direct_rt.value().GetRenderTargetTexture(), /*vertical_split=*/true);
    EXPECT_NEAR(static_cast<Scalar>(direct_transition), expected_y, 1.5f)
        << "Direct draw transition mismatch for oy=" << oy;
    int direct_marker =
        FindGreenMarkerTop(direct_rt.value().GetRenderTargetTexture());
    EXPECT_NEAR(static_cast<Scalar>(direct_marker), marker_y, 1.5f)
        << "Direct draw overflow marker shifted for oy=" << oy;

    // 2. Composed filter (outer identity MatrixFilter wrapping inner Stretch),
    // which exercises StretchFilterContents::RenderToSnapshot where
    // AnonymousContents re-bases entity.GetTransform() by T(-coverage.origin).
    auto composed = FilterContents::MakeMatrixFilter(
        FilterInput::Make(stretch), Matrix(), SamplerDescriptor{});
    composed->SetEffectTransform(offset_transform);

    std::optional<Snapshot> composed_snap =
        composed->RenderToSnapshot(renderer, entity, {});
    ASSERT_TRUE(composed_snap.has_value());
    ASSERT_NE(composed_snap->texture, nullptr);

    int composed_transition = FindRedToBlueTransition(composed_snap->texture,
                                                      /*vertical_split=*/true);
    EXPECT_NEAR(static_cast<Scalar>(composed_transition), expected_y, 1.5f)
        << "Composed (RenderToSnapshot) transition mismatch for oy=" << oy;
    int composed_marker = FindGreenMarkerTop(composed_snap->texture);
    EXPECT_NEAR(static_cast<Scalar>(composed_marker), marker_y, 1.5f)
        << "Composed (RenderToSnapshot) overflow marker shifted for oy=" << oy;
  }

  // 3. Horizontal overscroll (+x and -x) with container_uv sub-rect [20, 0] ->
  // [80, 200] (width 60, split at x = 50 => norm = 0.5).
  const Rect h_stretch_bounds = Rect::MakeLTRB(20, 0, 80, 200);
  const Scalar split_x = 50.0f;
  std::shared_ptr<Texture> h_tex =
      MakeTwoColorTexture(tex_size, /*vertical_split=*/false, split_x);
  ASSERT_NE(h_tex, nullptr);

  for (Scalar ox : {0.35f, -0.35f}) {
    const Scalar expected_norm =
        flutter::DlStretchImageFilter::ComputeStretchedNormalizedPosition(
            0.5f, ox, interp);
    const Scalar expected_x = h_stretch_bounds.GetLeft() +
                              expected_norm * h_stretch_bounds.GetWidth();

    auto stretch = FilterContents::MakeStretch(FilterInput::Make(h_tex), ox,
                                               0.0f, interp, h_stretch_bounds);
    stretch->SetEffectTransform(offset_transform);

    Entity entity;
    entity.SetTransform(offset_transform);

    std::optional<Snapshot> snap =
        stretch->RenderToSnapshot(renderer, entity, {});
    ASSERT_TRUE(snap.has_value());
    int h_transition =
        FindRedToBlueTransition(snap->texture, /*vertical_split=*/false);
    EXPECT_NEAR(static_cast<Scalar>(h_transition), expected_x, 1.5f)
        << "Horizontal transition mismatch for ox=" << ox;
  }
}

}  // namespace testing
}  // namespace impeller
