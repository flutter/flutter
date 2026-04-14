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

namespace {

using RenderFunction = std::function<void(flutter::DisplayListBuilder& builder,
                                          flutter::DlPoint center,
                                          flutter::DlScalar radius,
                                          const flutter::DlPaint& paint)>;

flutter::DlRect MakeRect(flutter::DlPoint center,
                         flutter::DlScalar width,
                         flutter::DlScalar height) {
  return flutter::DlRect::MakeLTRB(center.x - width, center.y - height,  //
                                   center.x + width, center.y + height);
}

const RenderFunction kRenderSquare = [](flutter::DisplayListBuilder& builder,
                                        flutter::DlPoint center,
                                        flutter::DlScalar radius,
                                        const flutter::DlPaint& paint) {
  builder.DrawRect(MakeRect(center, radius, radius), paint);
};

const RenderFunction kRenderRectangle = [](flutter::DisplayListBuilder& builder,
                                           flutter::DlPoint center,
                                           flutter::DlScalar radius,
                                           const flutter::DlPaint& paint) {
  builder.DrawRect(MakeRect(center, radius, radius * 0.9f), paint);
};

const RenderFunction kRenderCircle = [](flutter::DisplayListBuilder& builder,
                                        flutter::DlPoint center,
                                        flutter::DlScalar radius,
                                        const flutter::DlPaint& paint) {
  builder.DrawCircle(center, radius, paint);
};

const RenderFunction kRenderOval = [](flutter::DisplayListBuilder& builder,
                                      flutter::DlPoint center,
                                      flutter::DlScalar radius,
                                      const flutter::DlPaint& paint) {
  builder.DrawOval(MakeRect(center, radius, radius * 0.9f), paint);
};

const RenderFunction kRenderLine = [](flutter::DisplayListBuilder& builder,
                                      flutter::DlPoint center,
                                      flutter::DlScalar radius,
                                      const flutter::DlPaint& paint) {
  flutter::DlVector2 offset(radius, 0);
  builder.DrawLine(center - offset, center + offset, paint);
};

enum class RenderType {
  kSquare,
  kRectangle,
  kCircle,
  kOval,
  kLine,
  kCount,
};

const char* ToName(RenderType type) {
  switch (type) {
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
}

const RenderFunction& ToFunction(RenderType type) {
  switch (type) {
    case RenderType::kSquare:
      return kRenderSquare;
    case RenderType::kRectangle:
      return kRenderRectangle;
    case RenderType::kCircle:
      return kRenderCircle;
    case RenderType::kOval:
      return kRenderOval;
    case RenderType::kLine:
      return kRenderLine;
    case RenderType::kCount:
      FML_UNREACHABLE();
  }
}

struct RenderParams {
  flutter::DlPoint center;
  flutter::DlScalar scale_x;
  flutter::DlScalar scale_y;
  flutter::DlScalar skew_x;
  flutter::DlScalar skew_y;
  flutter::DlScalar rotation;
  RenderType render_type;

  flutter::DlRadians Radians() const {
    return flutter::DlRadians(rotation * impeller::kPi * 2.0f);
  }
};

void RenderPrimitive(flutter::DisplayListBuilder& builder,
                     const RenderParams& params) {
  using Matrix = impeller::Matrix;

  Matrix transform =  //
      Matrix::MakeTranslation(params.center) *
      Matrix::MakeRotationZ(params.Radians()) *
      Matrix::MakeScale({params.scale_x, params.scale_y, 1.0f}) *
      Matrix::MakeSkew(params.skew_x, params.skew_y);
  builder.Transform(transform);

  flutter::DlPaint paint;
  paint.setColor(flutter::DlColor::kBlue());
  paint.setStrokeWidth(20.0f);
  const RenderFunction& renderer = ToFunction(params.render_type);
  renderer(builder, flutter::DlPoint(), 100, paint);
  paint.setColor(flutter::DlColor::kWhite());
  paint.setDrawStyle(flutter::DlDrawStyle::kStroke);
  paint.setStrokeWidth(0.0f);
  renderer(builder, flutter::DlPoint(), 90, paint);
}

}  // namespace

namespace impeller {
namespace testing {

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

  auto callback = [&]() -> sk_sp<flutter::DisplayList> {
    if (AiksTest::ImGuiBegin("Controls", nullptr,
                             ImGuiWindowFlags_AlwaysAutoResize)) {
      ImGui::SliderFloat("X Scale", &params.scale_x, 1, 3);
      ImGui::SliderFloat("Y Scale", &params.scale_y, 1, 3);
      ImGui::SliderFloat("X Skew", &params.skew_x, 0, 1);
      ImGui::SliderFloat("Y Skew", &params.skew_y, 0, 1);
      ImGui::SliderFloat("Rotation", &params.rotation, 0, 1);
      ImGui::ListBox(
          "Shape Type", reinterpret_cast<int*>(&params.render_type),
          [](void* data, int index) {
            return ToName(static_cast<RenderType>(index));
          },
          nullptr, static_cast<int>(RenderType::kCount), -1);
      ImGui::End();
    }

    flutter::DisplayListBuilder builder;
    builder.Scale(GetContentScale().x, GetContentScale().y);
    RenderPrimitive(builder, params);
    return builder.Build();
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(AiksTest, CanRenderSkewedSdfRectangle) {
  RenderParams params{
      .center = flutter::DlPoint(GetWindowSize().width * 0.5f,
                                 GetWindowSize().height * 0.5f),
      .scale_x = 1.0f,
      .scale_y = 1.0f,
      .skew_x = 0.5f,
      .skew_y = 0.5f,
      .rotation = 0.1f,
      .render_type = RenderType::kRectangle,
  };

  flutter::DisplayListBuilder builder;
  builder.Scale(GetContentScale().x, GetContentScale().y);
  RenderPrimitive(builder, params);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

}  // namespace testing
}  // namespace impeller
