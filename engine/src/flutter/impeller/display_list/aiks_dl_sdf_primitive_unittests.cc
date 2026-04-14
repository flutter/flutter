// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "display_list/display_list.h"
#include "flutter/impeller/display_list/aiks_unittests.h"

#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/dl_color.h"
#include "flutter/display_list/dl_paint.h"
#include "flutter/impeller/geometry/constants.h"
#include "flutter/impeller/geometry/scalar.h"
#include "flutter/testing/display_list_testing.h"
#include "flutter/testing/testing.h"
#include "imgui.h"
#include "impeller/playground/widgets.h"

// File for tests that check conditions that complicate the SDF shaders,
// such as making sure our hairline (and other) strokes are consistent
// under various transforms. These same issues can also affect non-SDF
// shaders, though the math on tessellated primitives is likely to be
// less complicated.

namespace {

enum class RenderType {
  kSquare,
  kRectangle,
  kCircle,
  kOval,
  kLine,
  kCount,
};

struct RenderParams {
  flutter::DlPoint center;
  flutter::DlScalar scale_x;
  flutter::DlScalar scale_y;
  flutter::DlScalar skew_x;
  flutter::DlScalar skew_y;
  flutter::DlScalar rotation;
  RenderType render_type;
};

void RenderPrimitiveWithHairline(flutter::DisplayListBuilder& builder,
                                 const RenderParams& params) {
  builder.Save();

  builder.Translate(params.center.x, params.center.y);
  builder.Rotate(params.rotation * 360);
  builder.Scale(params.scale_x, params.scale_y);
  builder.Skew(params.skew_x, params.skew_y);
  builder.Translate(-params.center.x, -params.center.y);

  // Paint for filling the outline (or wide stroke in the case of DrawLine)
  // into which the hairline will be inscribed, inset by about 10 pixels
  // for comparison.
  flutter::DlPaint fill_paint =
      flutter::DlPaint()
          .setColor(flutter::DlColor::kBlue())
          .setDrawStyle(flutter::DlDrawStyle::kFill)
          // This stroke width is only for the DrawLine case which still uses
          // the stroke width even if the style is kFill.
          .setStrokeWidth(20.0f);

  // Paint for stroking a hairline outline of the shape inside the filled
  // version for comparison.
  flutter::DlPaint hairline_paint =
      flutter::DlPaint()
          .setColor(flutter::DlColor::kWhite())
          .setDrawStyle(flutter::DlDrawStyle::kStroke)
          .setStrokeWidth(0.0f);

  constexpr int fill_radius = 100;
  constexpr int hairline_inset = 10;
  constexpr flutter::DlVector2 rect_expansion(0, -20);
  constexpr int hairline_radius = fill_radius - hairline_inset;

  // Common rectangle used as bounds by many of the render operations.
  flutter::DlRect fill_bounds = flutter::DlRect::MakeLTRB(
      params.center.x - fill_radius, params.center.y - fill_radius,
      params.center.x + fill_radius, params.center.y + fill_radius);

  // Common rectangle used as bounds by many of the render operations.
  flutter::DlRect hairline_bounds = flutter::DlRect::MakeLTRB(
      params.center.x - hairline_radius, params.center.y - hairline_radius,
      params.center.x + hairline_radius, params.center.y + hairline_radius);

  switch (params.render_type) {
    case RenderType::kSquare:
      builder.DrawRect(fill_bounds, fill_paint);
      builder.DrawRect(hairline_bounds, hairline_paint);
      break;
    case RenderType::kRectangle:
      builder.DrawRect(fill_bounds.Expand(rect_expansion), fill_paint);
      builder.DrawRect(hairline_bounds.Expand(rect_expansion), hairline_paint);
      break;
    case RenderType::kCircle:
      builder.DrawCircle(params.center, fill_radius, fill_paint);
      builder.DrawCircle(params.center, hairline_radius, hairline_paint);
      break;
    case RenderType::kOval:
      builder.DrawOval(fill_bounds.Expand(rect_expansion), fill_paint);
      builder.DrawOval(hairline_bounds.Expand(rect_expansion), hairline_paint);
      break;
    case RenderType::kLine: {
      flutter::DlVector2 fill_offset(fill_radius, 0);
      builder.DrawLine(params.center - fill_offset,  //
                       params.center + fill_offset,  //
                       fill_paint);
      flutter::DlVector2 hairline_offset(hairline_radius, 0);
      builder.DrawLine(params.center - hairline_offset,  //
                       params.center + hairline_offset,  //
                       hairline_paint);
      break;
    }
    case RenderType::kCount:
      FML_UNREACHABLE();
  }

  builder.Restore();
}

}  // namespace

namespace impeller {
namespace testing {

// This playground tests the effects of scaling, rotation and skew transforms
// on the consistency of a hairline stroke. The math used to estimate the
// pixel size can get complicated in a shader that is performing some of
// its operations on local space values and some on device space values.
TEST_P(AiksTest, SdfPrimitivePlayground) {
  if (IsGoldenTest()) {
    GTEST_SKIP() << "SdfPrimitivePlayground does not produce a golden image";
  }

  RenderParams params{
      .center = flutter::DlPoint(GetWindowSize().width * 0.5f,
                                 GetWindowSize().height * 0.5f),
      .scale_x = 1.0f,
      .scale_y = 1.0f,
      .skew_x = 0.0f,
      .skew_y = 0.0f,
      .rotation = 0.0f,
      .render_type = RenderType::kRectangle,
  };
  // The ImGui controls need a pointer to an int and casting a pointer to
  // an enum field to an int pointer is frowned upon, so we instead create
  // an int variable and then fill in the params enum from it later.
  int render_type_index = static_cast<int>(RenderType::kRectangle);

  auto callback = [&]() -> sk_sp<flutter::DisplayList> {
    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::SliderFloat("X Scale", &params.scale_x, 1, 3);
      ImGui::SliderFloat("Y Scale", &params.scale_y, 1, 3);
      ImGui::SliderFloat("X Skew", &params.skew_x, 0, 1);
      ImGui::SliderFloat("Y Skew", &params.skew_y, 0, 1);
      ImGui::SliderFloat("Rotation", &params.rotation, 0, 1);
      ImGui::ListBox(
          "Shape Type", &render_type_index,
          [](void* data, int index) {
            switch (static_cast<RenderType>(index)) {
              case RenderType::kSquare:
                return "Square";
              case RenderType::kRectangle:
                return "Rectangle";
              case RenderType::kCircle:
                return "Circle";
              case RenderType::kOval:
                return "Oval";
              case RenderType::kLine:
                return "Line";
              case RenderType::kCount:
                FML_UNREACHABLE();
            }
          },
          nullptr, static_cast<int>(RenderType::kCount), -1);
      ImGui::End();
    }

    // Translate our "Gui int variable" to the appropriate enum field value.
    params.render_type = static_cast<RenderType>(render_type_index);

    flutter::DisplayListBuilder builder;
    builder.Scale(GetContentScale().x, GetContentScale().y);
    RenderPrimitiveWithHairline(builder, params);
    return builder.Build();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, CanRenderSkewedHairlineSdfCircle) {
  RenderParams params{
      .center = flutter::DlPoint(GetWindowSize().width * 0.5f,
                                 GetWindowSize().height * 0.5f),
      .scale_x = 1.0f,
      .scale_y = 1.0f,
      .skew_x = 0.75f,
      .skew_y = 0.75f,
      .rotation = 0.0f,
      .render_type = RenderType::kCircle,
  };

  flutter::DisplayListBuilder builder;
  builder.Scale(GetContentScale().x, GetContentScale().y);
  RenderPrimitiveWithHairline(builder, params);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

}  // namespace testing
}  // namespace impeller
