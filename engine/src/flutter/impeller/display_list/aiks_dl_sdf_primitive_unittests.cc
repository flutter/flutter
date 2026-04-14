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

struct RenderParameters {
  flutter::DlPoint center;
  flutter::DlScalar stroke_width = 0.0f;
  flutter::DlScalar scale_x = 1.0f;
  flutter::DlScalar scale_y = 1.0f;
  flutter::DlScalar skew_x = 0.0f;
  flutter::DlScalar skew_y = 0.0f;
  flutter::DlScalar degrees = 0.0f;
  RenderType render_type;
};

void RenderPrimitiveWithHairline(flutter::DisplayListBuilder& builder,
                                 const RenderParameters& params) {
  builder.Save();

  builder.Translate(params.center.x, params.center.y);
  builder.Rotate(params.degrees);
  builder.Scale(params.scale_x, params.scale_y);
  builder.Skew(params.skew_x, params.skew_y);
  builder.Translate(-params.center.x, -params.center.y);

  // Paint for filling a large outline around the shape outside of the
  // stroke for reference to see how the stroke tracks the shape.
  flutter::DlPaint fill_paint =  //
      flutter::DlPaint()
          .setColor(flutter::DlColor::kBlue())
          .setDrawStyle(flutter::DlDrawStyle::kFill);

  // Paint for filling the interior inside the stroke to track the exact
  // position of the stroke. The contrast between these fills will provide
  // a reference for where the stroke should appear and whether it
  // precisely follows the shape boundary.
  flutter::DlPaint interior_paint =
      flutter::DlPaint()
          // A very very dark blue
          .setColor(flutter::DlColor::ARGB(1.0f, 0.0f, 0.0f, 0.5f))
          .setDrawStyle(flutter::DlDrawStyle::kFill);

  // Paint for stroking the stroke outline of the shape itself.
  flutter::DlPaint stroke_paint =
      flutter::DlPaint()
          .setColor(flutter::DlColor::kWhite())
          .setDrawStyle(flutter::DlDrawStyle::kStroke)
          .setStrokeWidth(params.stroke_width);

  constexpr int fill_radius = 100;
  constexpr int stroke_inset = 10;
  // The "expansion (contraction)" of the squared bounds to make rect bounds.
  constexpr flutter::DlVector2 rect_expansion(0, -20);
  constexpr int stroke_radius = fill_radius - stroke_inset;

  // Common rectangle used as bounds by many of the render operations.
  flutter::DlRect fill_bounds = flutter::DlRect::MakeLTRB(
      params.center.x - fill_radius, params.center.y - fill_radius,
      params.center.x + fill_radius, params.center.y + fill_radius);

  // Common rectangle used as bounds by many of the render operations.
  flutter::DlRect stroke_bounds = flutter::DlRect::MakeLTRB(
      params.center.x - stroke_radius, params.center.y - stroke_radius,
      params.center.x + stroke_radius, params.center.y + stroke_radius);

  switch (params.render_type) {
    case RenderType::kSquare:
      builder.DrawRect(fill_bounds, fill_paint);
      builder.DrawRect(stroke_bounds, interior_paint);
      builder.DrawRect(stroke_bounds, stroke_paint);
      break;
    case RenderType::kRectangle:
      builder.DrawRect(fill_bounds.Expand(rect_expansion), fill_paint);
      builder.DrawRect(stroke_bounds.Expand(rect_expansion), interior_paint);
      builder.DrawRect(stroke_bounds.Expand(rect_expansion), stroke_paint);
      break;
    case RenderType::kCircle:
      builder.DrawCircle(params.center, fill_radius, fill_paint);
      builder.DrawCircle(params.center, stroke_radius, interior_paint);
      builder.DrawCircle(params.center, stroke_radius, stroke_paint);
      break;
    case RenderType::kOval:
      builder.DrawOval(fill_bounds.Expand(rect_expansion), fill_paint);
      builder.DrawOval(stroke_bounds.Expand(rect_expansion), interior_paint);
      builder.DrawOval(stroke_bounds.Expand(rect_expansion), stroke_paint);
      break;
    case RenderType::kLine: {
      flutter::DlPaint outer_stroke_paint = fill_paint;
      // Drawline can't "fill" the outer shape since it is just a line and
      // has no fillable interior. So, instead we just draw it stroked with
      // a larger line width.
      outer_stroke_paint.setDrawStyle(flutter::DlDrawStyle::kStroke);
      outer_stroke_paint.setStrokeWidth(20.0);
      flutter::DlVector2 fill_offset(fill_radius, 0);
      builder.DrawLine(params.center - fill_offset,  //
                       params.center + fill_offset,  //
                       outer_stroke_paint);
      // Nothing to render for "interior" of the stroke since lines have
      // no fillable interior.
      flutter::DlVector2 stroke_offset(stroke_radius, 0);
      builder.DrawLine(params.center - stroke_offset,  //
                       params.center + stroke_offset,  //
                       stroke_paint);
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
// on the consistency of a stroke (particularly hairlines). The math used to
// estimate the pixel size can get complicated in a shader that is performing
// some of its operations on local space values and some in device space.
TEST_P(AiksTest, SdfPrimitivePlayground) {
  if (IsGoldenTest()) {
    GTEST_SKIP() << "SdfPrimitivePlayground does not produce a golden image";
  }

  RenderParameters params{
      .center = flutter::DlPoint(GetWindowSize().width * 0.5f,
                                 GetWindowSize().height * 0.5f),
      .render_type = RenderType::kRectangle,
  };
  // The ImGui controls need a pointer to an int and casting a pointer to
  // an enum field to an int pointer is frowned upon, so we instead create
  // an int variable and then fill in the params enum from it later.
  int render_type_index = static_cast<int>(RenderType::kRectangle);

  auto callback = [&]() -> sk_sp<flutter::DisplayList> {
    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::SliderFloat("Stroke", &params.stroke_width, 0, 3);
      ImGui::SliderFloat("X Scale", &params.scale_x, 1, 3);
      ImGui::SliderFloat("Y Scale", &params.scale_y, 1, 3);
      ImGui::SliderFloat("X Skew", &params.skew_x, 0, 1);
      ImGui::SliderFloat("Y Skew", &params.skew_y, 0, 1);
      ImGui::SliderFloat("Rotation", &params.degrees, 0, 360);
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
    builder.DrawColor(flutter::DlColor::kBlack(), flutter::DlBlendMode::kSrc);
    RenderPrimitiveWithHairline(builder, params);
    return builder.Build();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, CanRenderSkewedHairlineSdfCircle) {
  flutter::DisplayListBuilder builder;
  builder.Scale(GetContentScale().x, GetContentScale().y);
  builder.DrawColor(flutter::DlColor::kBlack(), flutter::DlBlendMode::kSrc);

  RenderParameters params{
      .center = flutter::DlPoint(GetWindowSize().width * 0.5f,
                                 GetWindowSize().height * 0.5f),
      .skew_x = 0.75f,
      .skew_y = 0.75f,
      .render_type = RenderType::kCircle,
  };
  RenderPrimitiveWithHairline(builder, params);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

}  // namespace testing
}  // namespace impeller
