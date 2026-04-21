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

// The tests in this file check the primitive rendering operations to make
// sure that they produce correct output, particularly for strokes and
// especially for hairline strokes, under a variety of transforms.

namespace {

using flutter::DisplayList;
using flutter::DisplayListBuilder;
using flutter::DlBlendMode;
using flutter::DlColor;
using flutter::DlDrawStyle;
using flutter::DlPaint;
using flutter::DlPoint;
using flutter::DlRect;
using flutter::DlScalar;

enum class RenderType {
  kSquare,
  kRectangle,
  kCircle,
  kOval,
  kLine,

  // kValidCount casts to the number of valid enum values.
  kValidCount,
  // kInvalid is used as a default initializer to force construction override.
  kInvalid,
};

struct RenderParameters {
  RenderType render_type =
      RenderType::kInvalid;  // Will cause errors unless explicitly replaced.
  DlPoint center;
  DlScalar stroke_width = 0.0f;
  DlScalar scale_x = 1.0f;
  DlScalar scale_y = 1.0f;
  DlScalar skew_x = 0.0f;
  DlScalar skew_y = 0.0f;
  DlScalar degrees = 0.0f;
};

void RenderPrimitiveWithStroke(DisplayListBuilder& builder,
                               const RenderParameters& params) {
  builder.Save();

  builder.Translate(params.center.x, params.center.y);
  builder.Rotate(params.degrees);
  builder.Scale(params.scale_x, params.scale_y);
  builder.Skew(params.skew_x, params.skew_y);
  builder.Translate(-params.center.x, -params.center.y);

  // We describe the base size of the shape to draw in terms of the radius
  // of a circle that would fill the space.
  const DlScalar base_radius = 100.0f;
  const DlScalar fill_radius = base_radius + params.stroke_width;
  const DlScalar stroke_radius = base_radius - 10.0f;

  auto draw_shape = [&](DlScalar radius, DlColor color,
                        DlScalar stroke_width = -1) -> void {
    DlPaint paint;
    paint.setColor(color);
    if (stroke_width < 0) {
      paint.setDrawStyle(DlDrawStyle::kFill);
    } else {
      paint.setDrawStyle(DlDrawStyle::kStroke);
      paint.setStrokeWidth(stroke_width);
    }

    // Square bounds to match the overall size of the circle described.
    DlRect square_bounds = DlRect::MakeCircleBounds(params.center, radius);
    // Rectangular bounds slightly elongated from the square bounds.
    DlRect rect_bounds = square_bounds.Expand(20.0f, 0.0f);

    switch (params.render_type) {
      case RenderType::kSquare:
        builder.DrawRect(square_bounds, paint);
        break;
      case RenderType::kRectangle:
        builder.DrawRect(rect_bounds, paint);
        break;
      case RenderType::kCircle:
        builder.DrawCircle(params.center, radius, paint);
        break;
      case RenderType::kOval:
        builder.DrawOval(rect_bounds, paint);
        break;
      case RenderType::kLine: {
        // Drawline can't "fill" the outer shape since it is just a line and
        // has no fillable interior. So, instead we reinterpret the radius as
        // a larger line width, but only accepting a radius outside of the
        // typical stroke_radius. The length of the line always extends across
        // the diameter of what would have been a circle of that radius.
        if (stroke_width < 0) {
          if (radius <= stroke_radius) {
            // This must be an interior fill, but the line has no interior.
            break;
          }
          paint.setDrawStyle(DlDrawStyle::kStroke);
          paint.setStrokeWidth((radius - stroke_radius) * 2.0f);
        }
        // Extend the line by the radius amount in both directions.
        DlPoint fill_offset(radius, 0.0f);
        builder.DrawLine(params.center - fill_offset,  //
                         params.center + fill_offset,  //
                         paint);
        break;
      }
      case RenderType::kValidCount:
      case RenderType::kInvalid:
        FML_UNREACHABLE();
    }
  };

  draw_shape(fill_radius, DlColor::kBlue());
  draw_shape(stroke_radius, DlColor::ARGB(1.0f, 0.0f, 0.0f, 0.5f));
  draw_shape(stroke_radius, DlColor::kWhite(), params.stroke_width);

  builder.Restore();
}

}  // namespace

namespace impeller {
namespace testing {

// This playground tests the effects of scaling, rotation and skew transforms
// on the consistency of a stroke (particularly hairlines). The math used to
// estimate the pixel size can get complicated in a shader that is performing
// some of its operations on local space values and some in device space.
TEST_P(AiksTest, PrimitiveShapePlayground) {
  if (IsGoldenTest()) {
    GTEST_SKIP() << "PrimitiveShapePlayground does not produce a golden image";
  }

  RenderParameters params{
      .render_type = RenderType::kRectangle,
      .center = GetWindowBounds().GetCenter(),
  };
  // The ImGui controls need a pointer to an int and casting a pointer to
  // an enum field to an int pointer is frowned upon, so we instead create
  // an int variable and then fill in the params enum from it later.
  int render_type_index = static_cast<int>(RenderType::kRectangle);

  auto callback = [&]() -> sk_sp<DisplayList> {
    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::SliderFloat("Stroke", &params.stroke_width, 0.0f, 30.0f);
      ImGui::SliderFloat("X Scale", &params.scale_x, 1.0f, 3.0f);
      ImGui::SliderFloat("Y Scale", &params.scale_y, 1.0f, 3.0f);
      ImGui::SliderFloat("X Skew", &params.skew_x, 0.0f, 1.0f);
      ImGui::SliderFloat("Y Skew", &params.skew_y, 0.0f, 1.0f);
      ImGui::SliderFloat("Rotation", &params.degrees, 0.0f, 360.0f);
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
              case RenderType::kValidCount:
              case RenderType::kInvalid:
                FML_UNREACHABLE();
            }
          },
          nullptr, static_cast<int>(RenderType::kValidCount), -1);
      ImGui::End();
    }

    // Translate our "Gui int variable" to the appropriate enum field value.
    params.render_type = static_cast<RenderType>(render_type_index);

    DisplayListBuilder builder;
    builder.Scale(GetContentScale().x, GetContentScale().y);
    builder.DrawColor(DlColor::kBlack(), DlBlendMode::kSrc);
    RenderPrimitiveWithStroke(builder, params);
    return builder.Build();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, CanRenderSkewedCircleHairline) {
  DisplayListBuilder builder;
  builder.Scale(GetContentScale().x, GetContentScale().y);
  builder.DrawColor(DlColor::kBlack(), DlBlendMode::kSrc);

  RenderParameters params{
      .render_type = RenderType::kCircle,
      .center = GetWindowBounds().GetCenter(),
      .skew_x = 0.75f,
      .skew_y = 0.75f,
  };
  RenderPrimitiveWithStroke(builder, params);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

}  // namespace testing
}  // namespace impeller
