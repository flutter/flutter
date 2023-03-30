// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <algorithm>
#include <cstring>
#include <memory>
#include <optional>
#include <unordered_map>
#include <vector>

#include "flutter/testing/testing.h"
#include "fml/logging.h"
#include "fml/time/time_point.h"
#include "gtest/gtest.h"
#include "impeller/entity/contents/atlas_contents.h"
#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/filters/blend_filter_contents.h"
#include "impeller/entity/contents/filters/color_filter_contents.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/filters/inputs/filter_input.h"
#include "impeller/entity/contents/linear_gradient_contents.h"
#include "impeller/entity/contents/rrect_shadow_contents.h"
#include "impeller/entity/contents/runtime_effect_contents.h"
#include "impeller/entity/contents/solid_color_contents.h"
#include "impeller/entity/contents/text_contents.h"
#include "impeller/entity/contents/texture_contents.h"
#include "impeller/entity/contents/tiled_texture_contents.h"
#include "impeller/entity/contents/vertices_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/entity_pass.h"
#include "impeller/entity/entity_pass_delegate.h"
#include "impeller/entity/entity_playground.h"
#include "impeller/entity/geometry.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/geometry_asserts.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/geometry/sigma.h"
#include "impeller/playground/playground.h"
#include "impeller/playground/widgets.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/vertex_buffer_builder.h"
#include "impeller/runtime_stage/runtime_stage.h"
#include "impeller/tessellator/tessellator.h"
#include "impeller/typographer/backends/skia/text_frame_skia.h"
#include "impeller/typographer/backends/skia/text_render_context_skia.h"
#include "include/core/SkBlendMode.h"
#include "third_party/imgui/imgui.h"
#include "third_party/skia/include/core/SkTextBlob.h"

namespace impeller {
namespace testing {

using EntityTest = EntityPlayground;
INSTANTIATE_PLAYGROUND_SUITE(EntityTest);

TEST_P(EntityTest, CanCreateEntity) {
  Entity entity;
  ASSERT_TRUE(entity.GetTransformation().IsIdentity());
}

class TestPassDelegate final : public EntityPassDelegate {
 public:
  explicit TestPassDelegate(std::optional<Rect> coverage, bool collapse = false)
      : coverage_(coverage), collapse_(collapse) {}

  // |EntityPassDelegate|
  ~TestPassDelegate() override = default;

  // |EntityPassDelegate|
  std::optional<Rect> GetCoverageRect() override { return coverage_; }

  // |EntityPassDelgate|
  bool CanElide() override { return false; }

  // |EntityPassDelgate|
  bool CanCollapseIntoParentPass(EntityPass* entity_pass) override {
    return collapse_;
  }

  // |EntityPassDelgate|
  std::shared_ptr<Contents> CreateContentsForSubpassTarget(
      std::shared_ptr<Texture> target,
      const Matrix& transform) override {
    return nullptr;
  }

 private:
  const std::optional<Rect> coverage_;
  const bool collapse_;
};

auto CreatePassWithRectPath(Rect rect,
                            std::optional<Rect> bounds_hint,
                            bool collapse = false) {
  auto subpass = std::make_unique<EntityPass>();
  Entity entity;
  entity.SetContents(SolidColorContents::Make(
      PathBuilder{}.AddRect(rect).TakePath(), Color::Red()));
  subpass->AddEntity(entity);
  subpass->SetDelegate(
      std::make_unique<TestPassDelegate>(bounds_hint, collapse));
  return subpass;
}

TEST_P(EntityTest, EntityPassCoverageRespectsDelegateBoundsHint) {
  EntityPass pass;

  auto subpass0 = CreatePassWithRectPath(Rect::MakeLTRB(0, 0, 100, 100),
                                         Rect::MakeLTRB(50, 50, 150, 150));
  auto subpass1 = CreatePassWithRectPath(Rect::MakeLTRB(500, 500, 1000, 1000),
                                         Rect::MakeLTRB(800, 800, 900, 900));

  auto subpass0_coverage =
      pass.GetSubpassCoverage(*subpass0.get(), std::nullopt);
  ASSERT_TRUE(subpass0_coverage.has_value());
  ASSERT_RECT_NEAR(subpass0_coverage.value(), Rect::MakeLTRB(50, 50, 100, 100));

  auto subpass1_coverage =
      pass.GetSubpassCoverage(*subpass1.get(), std::nullopt);
  ASSERT_TRUE(subpass1_coverage.has_value());
  ASSERT_RECT_NEAR(subpass1_coverage.value(),
                   Rect::MakeLTRB(800, 800, 900, 900));

  pass.AddSubpass(std::move(subpass0));
  pass.AddSubpass(std::move(subpass1));

  auto coverage = pass.GetElementsCoverage(std::nullopt);
  ASSERT_TRUE(coverage.has_value());
  ASSERT_RECT_NEAR(coverage.value(), Rect::MakeLTRB(50, 50, 900, 900));
}

TEST_P(EntityTest, EntityPassCanMergeSubpassIntoParent) {
  // Both a red and a blue box should appear if the pass merging has worked
  // correctly.

  EntityPass pass;
  auto subpass = CreatePassWithRectPath(Rect::MakeLTRB(0, 0, 100, 100),
                                        Rect::MakeLTRB(50, 50, 150, 150), true);
  pass.AddSubpass(std::move(subpass));

  Entity entity;
  entity.SetTransformation(Matrix::MakeScale(GetContentScale()));
  auto contents = std::make_unique<SolidColorContents>();
  contents->SetGeometry(Geometry::MakeRect(Rect::MakeLTRB(100, 100, 200, 200)));
  contents->SetColor(Color::Blue());
  entity.SetContents(std::move(contents));

  pass.AddEntity(entity);

  ASSERT_TRUE(OpenPlaygroundHere(pass));
}

TEST_P(EntityTest, EntityPassCoverageRespectsCoverageLimit) {
  // Rect is drawn entirely in negative area.
  auto pass = CreatePassWithRectPath(Rect::MakeLTRB(-200, -200, -100, -100),
                                     std::nullopt);

  // Without coverage limit.
  {
    auto pass_coverage = pass->GetElementsCoverage(std::nullopt);
    ASSERT_TRUE(pass_coverage.has_value());
    ASSERT_RECT_NEAR(pass_coverage.value(),
                     Rect::MakeLTRB(-200, -200, -100, -100));
  }

  // With limit that doesn't overlap.
  {
    auto pass_coverage =
        pass->GetElementsCoverage(Rect::MakeLTRB(0, 0, 100, 100));
    ASSERT_FALSE(pass_coverage.has_value());
  }

  // With limit that partially overlaps.
  {
    auto pass_coverage =
        pass->GetElementsCoverage(Rect::MakeLTRB(-150, -150, 0, 0));
    ASSERT_TRUE(pass_coverage.has_value());
    ASSERT_RECT_NEAR(pass_coverage.value(),
                     Rect::MakeLTRB(-150, -150, -100, -100));
  }
}

TEST_P(EntityTest, FilterCoverageRespectsCropRect) {
  auto image = CreateTextureForFixture("boston.jpg");
  auto filter = ColorFilterContents::MakeBlend(BlendMode::kSoftLight,
                                               FilterInput::Make({image}));

  // Without the crop rect (default behavior).
  {
    auto actual = filter->GetCoverage({});
    auto expected = Rect::MakeSize(image->GetSize());

    ASSERT_TRUE(actual.has_value());
    ASSERT_RECT_NEAR(actual.value(), expected);
  }

  // With the crop rect.
  {
    auto expected = Rect::MakeLTRB(50, 50, 100, 100);
    filter->SetCoverageCrop(expected);
    auto actual = filter->GetCoverage({});

    ASSERT_TRUE(actual.has_value());
    ASSERT_RECT_NEAR(actual.value(), expected);
  }
}

TEST_P(EntityTest, CanDrawRect) {
  auto contents = std::make_shared<SolidColorContents>();
  contents->SetGeometry(Geometry::MakeRect({100, 100, 100, 100}));
  contents->SetColor(Color::Red());

  Entity entity;
  entity.SetTransformation(Matrix::MakeScale(GetContentScale()));
  entity.SetContents(contents);

  ASSERT_TRUE(OpenPlaygroundHere(entity));
}

TEST_P(EntityTest, CanDrawRRect) {
  auto contents = std::make_shared<SolidColorContents>();
  contents->SetGeometry(Geometry::MakeRRect({100, 100, 100, 100}, 10.0));
  contents->SetColor(Color::Red());

  Entity entity;
  entity.SetTransformation(Matrix::MakeScale(GetContentScale()));
  entity.SetContents(contents);

  ASSERT_TRUE(OpenPlaygroundHere(entity));
}

TEST_P(EntityTest, GeometryBoundsAreTransformed) {
  auto geometry = Geometry::MakeRect({100, 100, 100, 100});
  auto transform = Matrix::MakeScale({2.0, 2.0, 2.0});

  ASSERT_RECT_NEAR(geometry->GetCoverage(transform).value(),
                   Rect(200, 200, 200, 200));
}

TEST_P(EntityTest, ThreeStrokesInOnePath) {
  Path path = PathBuilder{}
                  .MoveTo({100, 100})
                  .LineTo({100, 200})
                  .MoveTo({100, 300})
                  .LineTo({100, 400})
                  .MoveTo({100, 500})
                  .LineTo({100, 600})
                  .TakePath();

  Entity entity;
  entity.SetTransformation(Matrix::MakeScale(GetContentScale()));
  auto contents = std::make_unique<SolidColorContents>();
  contents->SetGeometry(Geometry::MakeStrokePath(path, 5.0));
  contents->SetColor(Color::Red());
  entity.SetContents(std::move(contents));
  ASSERT_TRUE(OpenPlaygroundHere(entity));
}

TEST_P(EntityTest, StrokeWithTextureContents) {
  auto bridge = CreateTextureForFixture("bay_bridge.jpg");
  Path path = PathBuilder{}
                  .MoveTo({100, 100})
                  .LineTo({100, 200})
                  .MoveTo({100, 300})
                  .LineTo({100, 400})
                  .MoveTo({100, 500})
                  .LineTo({100, 600})
                  .TakePath();

  Entity entity;
  entity.SetTransformation(Matrix::MakeScale(GetContentScale()));
  auto contents = std::make_unique<TiledTextureContents>();
  contents->SetGeometry(Geometry::MakeStrokePath(path, 100.0));
  contents->SetTexture(bridge);
  contents->SetTileModes(Entity::TileMode::kClamp, Entity::TileMode::kClamp);
  entity.SetContents(std::move(contents));
  ASSERT_TRUE(OpenPlaygroundHere(entity));
}

TEST_P(EntityTest, TriangleInsideASquare) {
  auto callback = [&](ContentContext& context, RenderPass& pass) {
    Point offset(100, 100);

    Point a =
        IMPELLER_PLAYGROUND_POINT(Point(10, 10) + offset, 20, Color::White());
    Point b =
        IMPELLER_PLAYGROUND_POINT(Point(210, 10) + offset, 20, Color::White());
    Point c =
        IMPELLER_PLAYGROUND_POINT(Point(210, 210) + offset, 20, Color::White());
    Point d =
        IMPELLER_PLAYGROUND_POINT(Point(10, 210) + offset, 20, Color::White());
    Point e =
        IMPELLER_PLAYGROUND_POINT(Point(50, 50) + offset, 20, Color::White());
    Point f =
        IMPELLER_PLAYGROUND_POINT(Point(100, 50) + offset, 20, Color::White());
    Point g =
        IMPELLER_PLAYGROUND_POINT(Point(50, 150) + offset, 20, Color::White());
    Path path = PathBuilder{}
                    .MoveTo(a)
                    .LineTo(b)
                    .LineTo(c)
                    .LineTo(d)
                    .Close()
                    .MoveTo(e)
                    .LineTo(f)
                    .LineTo(g)
                    .Close()
                    .TakePath();

    Entity entity;
    entity.SetTransformation(Matrix::MakeScale(GetContentScale()));
    auto contents = std::make_unique<SolidColorContents>();
    contents->SetGeometry(Geometry::MakeStrokePath(path, 20.0));
    contents->SetColor(Color::Red());
    entity.SetContents(std::move(contents));

    return entity.Render(context, pass);
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(EntityTest, StrokeCapAndJoinTest) {
  const Point padding(300, 250);
  const Point margin(140, 180);

  auto callback = [&](ContentContext& context, RenderPass& pass) {
    // Slightly above sqrt(2) by default, so that right angles are just below
    // the limit and acute angles are over the limit (causing them to get
    // beveled).
    static Scalar miter_limit = 1.41421357;
    static Scalar width = 30;

    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    {
      ImGui::SliderFloat("Miter limit", &miter_limit, 0, 30);
      ImGui::SliderFloat("Stroke width", &width, 0, 100);
      if (ImGui::Button("Reset")) {
        miter_limit = 1.41421357;
        width = 30;
      }
    }
    ImGui::End();

    auto world_matrix = Matrix::MakeScale(GetContentScale());
    auto render_path = [width = width, &context, &pass, &world_matrix](
                           const Path& path, Cap cap, Join join) {
      auto contents = std::make_unique<SolidColorContents>();
      contents->SetGeometry(
          Geometry::MakeStrokePath(path, width, miter_limit, cap, join));
      contents->SetColor(Color::Red());

      Entity entity;
      entity.SetTransformation(world_matrix);
      entity.SetContents(std::move(contents));

      auto coverage = entity.GetCoverage();
      if (coverage.has_value()) {
        auto bounds_contents = std::make_unique<SolidColorContents>();
        bounds_contents->SetGeometry(Geometry::MakeFillPath(
            PathBuilder{}.AddRect(entity.GetCoverage().value()).TakePath()));
        bounds_contents->SetColor(Color::Green().WithAlpha(0.5));
        Entity bounds_entity;
        bounds_entity.SetContents(std::move(bounds_contents));
        bounds_entity.Render(context, pass);
      }

      entity.Render(context, pass);
    };

    const Point a_def(0, 0), b_def(0, 100), c_def(150, 0), d_def(150, -100),
        e_def(75, 75);
    const Scalar r = 30;
    // Cap::kButt demo.
    {
      Point off = Point(0, 0) * padding + margin;
      auto [a, b] = IMPELLER_PLAYGROUND_LINE(off + a_def, off + b_def, r,
                                             Color::Black(), Color::White());
      auto [c, d] = IMPELLER_PLAYGROUND_LINE(off + c_def, off + d_def, r,
                                             Color::Black(), Color::White());
      render_path(PathBuilder{}.AddCubicCurve(a, b, d, c).TakePath(),
                  Cap::kButt, Join::kBevel);
    }

    // Cap::kSquare demo.
    {
      Point off = Point(1, 0) * padding + margin;
      auto [a, b] = IMPELLER_PLAYGROUND_LINE(off + a_def, off + b_def, r,
                                             Color::Black(), Color::White());
      auto [c, d] = IMPELLER_PLAYGROUND_LINE(off + c_def, off + d_def, r,
                                             Color::Black(), Color::White());
      render_path(PathBuilder{}.AddCubicCurve(a, b, d, c).TakePath(),
                  Cap::kSquare, Join::kBevel);
    }

    // Cap::kRound demo.
    {
      Point off = Point(2, 0) * padding + margin;
      auto [a, b] = IMPELLER_PLAYGROUND_LINE(off + a_def, off + b_def, r,
                                             Color::Black(), Color::White());
      auto [c, d] = IMPELLER_PLAYGROUND_LINE(off + c_def, off + d_def, r,
                                             Color::Black(), Color::White());
      render_path(PathBuilder{}.AddCubicCurve(a, b, d, c).TakePath(),
                  Cap::kRound, Join::kBevel);
    }

    // Join::kBevel demo.
    {
      Point off = Point(0, 1) * padding + margin;
      Point a = IMPELLER_PLAYGROUND_POINT(off + a_def, r, Color::White());
      Point b = IMPELLER_PLAYGROUND_POINT(off + e_def, r, Color::White());
      Point c = IMPELLER_PLAYGROUND_POINT(off + c_def, r, Color::White());
      render_path(
          PathBuilder{}.MoveTo(a).LineTo(b).LineTo(c).Close().TakePath(),
          Cap::kButt, Join::kBevel);
    }

    // Join::kMiter demo.
    {
      Point off = Point(1, 1) * padding + margin;
      Point a = IMPELLER_PLAYGROUND_POINT(off + a_def, r, Color::White());
      Point b = IMPELLER_PLAYGROUND_POINT(off + e_def, r, Color::White());
      Point c = IMPELLER_PLAYGROUND_POINT(off + c_def, r, Color::White());
      render_path(
          PathBuilder{}.MoveTo(a).LineTo(b).LineTo(c).Close().TakePath(),
          Cap::kButt, Join::kMiter);
    }

    // Join::kRound demo.
    {
      Point off = Point(2, 1) * padding + margin;
      Point a = IMPELLER_PLAYGROUND_POINT(off + a_def, r, Color::White());
      Point b = IMPELLER_PLAYGROUND_POINT(off + e_def, r, Color::White());
      Point c = IMPELLER_PLAYGROUND_POINT(off + c_def, r, Color::White());
      render_path(
          PathBuilder{}.MoveTo(a).LineTo(b).LineTo(c).Close().TakePath(),
          Cap::kButt, Join::kRound);
    }

    return true;
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(EntityTest, CubicCurveTest) {
  // Compare with https://fiddle.skia.org/c/b3625f26122c9de7afe7794fcf25ead3
  Path path =
      PathBuilder{}
          .MoveTo({237.164, 125.003})
          .CubicCurveTo({236.709, 125.184}, {236.262, 125.358},
                        {235.81, 125.538})
          .CubicCurveTo({235.413, 125.68}, {234.994, 125.832},
                        {234.592, 125.977})
          .CubicCurveTo({234.592, 125.977}, {234.591, 125.977},
                        {234.59, 125.977})
          .CubicCurveTo({222.206, 130.435}, {207.708, 135.753},
                        {192.381, 141.429})
          .CubicCurveTo({162.77, 151.336}, {122.17, 156.894}, {84.1123, 160})
          .Close()
          .TakePath();
  Entity entity;
  entity.SetTransformation(Matrix::MakeScale(GetContentScale()));
  entity.SetContents(SolidColorContents::Make(path, Color::Red()));
  ASSERT_TRUE(OpenPlaygroundHere(entity));
}

TEST_P(EntityTest, CanDrawCorrectlyWithRotatedTransformation) {
  auto callback = [&](ContentContext& context, RenderPass& pass) -> bool {
    const char* input_axis[] = {"X", "Y", "Z"};
    static int rotation_axis_index = 0;
    static float rotation = 0;
    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::SliderFloat("Rotation", &rotation, -kPi, kPi);
    ImGui::Combo("Rotation Axis", &rotation_axis_index, input_axis,
                 sizeof(input_axis) / sizeof(char*));
    Matrix rotation_matrix;
    switch (rotation_axis_index) {
      case 0:
        rotation_matrix = Matrix::MakeRotationX(Radians(rotation));
        break;
      case 1:
        rotation_matrix = Matrix::MakeRotationY(Radians(rotation));
        break;
      case 2:
        rotation_matrix = Matrix::MakeRotationZ(Radians(rotation));
        break;
      default:
        rotation_matrix = Matrix{};
        break;
    }

    if (ImGui::Button("Reset")) {
      rotation = 0;
    }
    ImGui::End();
    Matrix current_transform =
        Matrix::MakeScale(GetContentScale())
            .MakeTranslation(
                Vector3(Point(pass.GetRenderTargetSize().width / 2.0,
                              pass.GetRenderTargetSize().height / 2.0)));
    Matrix result_transform = current_transform * rotation_matrix;
    Path path =
        PathBuilder{}.AddRect(Rect::MakeXYWH(-300, -400, 600, 800)).TakePath();

    Entity entity;
    entity.SetTransformation(result_transform);
    entity.SetContents(SolidColorContents::Make(path, Color::Red()));
    return entity.Render(context, pass);
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(EntityTest, CubicCurveAndOverlapTest) {
  // Compare with https://fiddle.skia.org/c/7a05a3e186c65a8dfb732f68020aae06
  Path path =
      PathBuilder{}
          .MoveTo({359.934, 96.6335})
          .CubicCurveTo({358.189, 96.7055}, {356.436, 96.7908},
                        {354.673, 96.8895})
          .CubicCurveTo({354.571, 96.8953}, {354.469, 96.9016},
                        {354.367, 96.9075})
          .CubicCurveTo({352.672, 97.0038}, {350.969, 97.113},
                        {349.259, 97.2355})
          .CubicCurveTo({349.048, 97.2506}, {348.836, 97.2678},
                        {348.625, 97.2834})
          .CubicCurveTo({347.019, 97.4014}, {345.407, 97.5299},
                        {343.789, 97.6722})
          .CubicCurveTo({343.428, 97.704}, {343.065, 97.7402},
                        {342.703, 97.7734})
          .CubicCurveTo({341.221, 97.9086}, {339.736, 98.0505},
                        {338.246, 98.207})
          .CubicCurveTo({337.702, 98.2642}, {337.156, 98.3292},
                        {336.612, 98.3894})
          .CubicCurveTo({335.284, 98.5356}, {333.956, 98.6837},
                        {332.623, 98.8476})
          .CubicCurveTo({332.495, 98.8635}, {332.366, 98.8818},
                        {332.237, 98.8982})
          .LineTo({332.237, 102.601})
          .LineTo({321.778, 102.601})
          .LineTo({321.778, 100.382})
          .CubicCurveTo({321.572, 100.413}, {321.367, 100.442},
                        {321.161, 100.476})
          .CubicCurveTo({319.22, 100.79}, {317.277, 101.123},
                        {315.332, 101.479})
          .CubicCurveTo({315.322, 101.481}, {315.311, 101.482},
                        {315.301, 101.484})
          .LineTo({310.017, 105.94})
          .LineTo({309.779, 105.427})
          .LineTo({314.403, 101.651})
          .CubicCurveTo({314.391, 101.653}, {314.379, 101.656},
                        {314.368, 101.658})
          .CubicCurveTo({312.528, 102.001}, {310.687, 102.366},
                        {308.846, 102.748})
          .CubicCurveTo({307.85, 102.955}, {306.855, 103.182}, {305.859, 103.4})
          .CubicCurveTo({305.048, 103.579}, {304.236, 103.75},
                        {303.425, 103.936})
          .LineTo({299.105, 107.578})
          .LineTo({298.867, 107.065})
          .LineTo({302.394, 104.185})
          .LineTo({302.412, 104.171})
          .CubicCurveTo({301.388, 104.409}, {300.366, 104.67},
                        {299.344, 104.921})
          .CubicCurveTo({298.618, 105.1}, {297.89, 105.269}, {297.165, 105.455})
          .CubicCurveTo({295.262, 105.94}, {293.36, 106.445},
                        {291.462, 106.979})
          .CubicCurveTo({291.132, 107.072}, {290.802, 107.163},
                        {290.471, 107.257})
          .CubicCurveTo({289.463, 107.544}, {288.455, 107.839},
                        {287.449, 108.139})
          .CubicCurveTo({286.476, 108.431}, {285.506, 108.73},
                        {284.536, 109.035})
          .CubicCurveTo({283.674, 109.304}, {282.812, 109.579},
                        {281.952, 109.859})
          .CubicCurveTo({281.177, 110.112}, {280.406, 110.377},
                        {279.633, 110.638})
          .CubicCurveTo({278.458, 111.037}, {277.256, 111.449},
                        {276.803, 111.607})
          .CubicCurveTo({276.76, 111.622}, {276.716, 111.637},
                        {276.672, 111.653})
          .CubicCurveTo({275.017, 112.239}, {273.365, 112.836},
                        {271.721, 113.463})
          .LineTo({271.717, 113.449})
          .CubicCurveTo({271.496, 113.496}, {271.238, 113.559},
                        {270.963, 113.628})
          .CubicCurveTo({270.893, 113.645}, {270.822, 113.663},
                        {270.748, 113.682})
          .CubicCurveTo({270.468, 113.755}, {270.169, 113.834},
                        {269.839, 113.926})
          .CubicCurveTo({269.789, 113.94}, {269.732, 113.957},
                        {269.681, 113.972})
          .CubicCurveTo({269.391, 114.053}, {269.081, 114.143},
                        {268.756, 114.239})
          .CubicCurveTo({268.628, 114.276}, {268.5, 114.314},
                        {268.367, 114.354})
          .CubicCurveTo({268.172, 114.412}, {267.959, 114.478},
                        {267.752, 114.54})
          .CubicCurveTo({263.349, 115.964}, {258.058, 117.695},
                        {253.564, 119.252})
          .CubicCurveTo({253.556, 119.255}, {253.547, 119.258},
                        {253.538, 119.261})
          .CubicCurveTo({251.844, 119.849}, {250.056, 120.474},
                        {248.189, 121.131})
          .CubicCurveTo({248, 121.197}, {247.812, 121.264}, {247.621, 121.331})
          .CubicCurveTo({247.079, 121.522}, {246.531, 121.715},
                        {245.975, 121.912})
          .CubicCurveTo({245.554, 122.06}, {245.126, 122.212},
                        {244.698, 122.364})
          .CubicCurveTo({244.071, 122.586}, {243.437, 122.811},
                        {242.794, 123.04})
          .CubicCurveTo({242.189, 123.255}, {241.58, 123.472},
                        {240.961, 123.693})
          .CubicCurveTo({240.659, 123.801}, {240.357, 123.909},
                        {240.052, 124.018})
          .CubicCurveTo({239.12, 124.351}, {238.18, 124.687}, {237.22, 125.032})
          .LineTo({237.164, 125.003})
          .CubicCurveTo({236.709, 125.184}, {236.262, 125.358},
                        {235.81, 125.538})
          .CubicCurveTo({235.413, 125.68}, {234.994, 125.832},
                        {234.592, 125.977})
          .CubicCurveTo({234.592, 125.977}, {234.591, 125.977},
                        {234.59, 125.977})
          .CubicCurveTo({222.206, 130.435}, {207.708, 135.753},
                        {192.381, 141.429})
          .CubicCurveTo({162.77, 151.336}, {122.17, 156.894}, {84.1123, 160})
          .LineTo({360, 160})
          .LineTo({360, 119.256})
          .LineTo({360, 106.332})
          .LineTo({360, 96.6307})
          .CubicCurveTo({359.978, 96.6317}, {359.956, 96.6326},
                        {359.934, 96.6335})
          .Close()
          .MoveTo({337.336, 124.143})
          .CubicCurveTo({337.274, 122.359}, {338.903, 121.511},
                        {338.903, 121.511})
          .CubicCurveTo({338.903, 121.511}, {338.96, 123.303},
                        {337.336, 124.143})
          .Close()
          .MoveTo({340.082, 121.849})
          .CubicCurveTo({340.074, 121.917}, {340.062, 121.992},
                        {340.046, 122.075})
          .CubicCurveTo({340.039, 122.109}, {340.031, 122.142},
                        {340.023, 122.177})
          .CubicCurveTo({340.005, 122.26}, {339.98, 122.346},
                        {339.952, 122.437})
          .CubicCurveTo({339.941, 122.473}, {339.931, 122.507},
                        {339.918, 122.544})
          .CubicCurveTo({339.873, 122.672}, {339.819, 122.804},
                        {339.75, 122.938})
          .CubicCurveTo({339.747, 122.944}, {339.743, 122.949},
                        {339.74, 122.955})
          .CubicCurveTo({339.674, 123.08}, {339.593, 123.205},
                        {339.501, 123.328})
          .CubicCurveTo({339.473, 123.366}, {339.441, 123.401},
                        {339.41, 123.438})
          .CubicCurveTo({339.332, 123.534}, {339.243, 123.625},
                        {339.145, 123.714})
          .CubicCurveTo({339.105, 123.75}, {339.068, 123.786},
                        {339.025, 123.821})
          .CubicCurveTo({338.881, 123.937}, {338.724, 124.048},
                        {338.539, 124.143})
          .CubicCurveTo({338.532, 123.959}, {338.554, 123.79},
                        {338.58, 123.626})
          .CubicCurveTo({338.58, 123.625}, {338.58, 123.625}, {338.58, 123.625})
          .CubicCurveTo({338.607, 123.455}, {338.65, 123.299},
                        {338.704, 123.151})
          .CubicCurveTo({338.708, 123.14}, {338.71, 123.127},
                        {338.714, 123.117})
          .CubicCurveTo({338.769, 122.971}, {338.833, 122.838},
                        {338.905, 122.712})
          .CubicCurveTo({338.911, 122.702}, {338.916, 122.69200000000001},
                        {338.922, 122.682})
          .CubicCurveTo({338.996, 122.557}, {339.072, 122.444},
                        {339.155, 122.34})
          .CubicCurveTo({339.161, 122.333}, {339.166, 122.326},
                        {339.172, 122.319})
          .CubicCurveTo({339.256, 122.215}, {339.339, 122.12},
                        {339.425, 122.037})
          .CubicCurveTo({339.428, 122.033}, {339.431, 122.03},
                        {339.435, 122.027})
          .CubicCurveTo({339.785, 121.687}, {340.106, 121.511},
                        {340.106, 121.511})
          .CubicCurveTo({340.106, 121.511}, {340.107, 121.645},
                        {340.082, 121.849})
          .Close()
          .MoveTo({340.678, 113.245})
          .CubicCurveTo({340.594, 113.488}, {340.356, 113.655},
                        {340.135, 113.775})
          .CubicCurveTo({339.817, 113.948}, {339.465, 114.059},
                        {339.115, 114.151})
          .CubicCurveTo({338.251, 114.379}, {337.34, 114.516},
                        {336.448, 114.516})
          .CubicCurveTo({335.761, 114.516}, {335.072, 114.527},
                        {334.384, 114.513})
          .CubicCurveTo({334.125, 114.508}, {333.862, 114.462},
                        {333.605, 114.424})
          .CubicCurveTo({332.865, 114.318}, {332.096, 114.184},
                        {331.41, 113.883})
          .CubicCurveTo({330.979, 113.695}, {330.442, 113.34},
                        {330.672, 112.813})
          .CubicCurveTo({331.135, 111.755}, {333.219, 112.946},
                        {334.526, 113.833})
          .CubicCurveTo({334.54, 113.816}, {334.554, 113.8}, {334.569, 113.784})
          .CubicCurveTo({333.38, 112.708}, {331.749, 110.985},
                        {332.76, 110.402})
          .CubicCurveTo({333.769, 109.82}, {334.713, 111.93},
                        {335.228, 113.395})
          .CubicCurveTo({334.915, 111.889}, {334.59, 109.636},
                        {335.661, 109.592})
          .CubicCurveTo({336.733, 109.636}, {336.408, 111.889},
                        {336.07, 113.389})
          .CubicCurveTo({336.609, 111.93}, {337.553, 109.82},
                        {338.563, 110.402})
          .CubicCurveTo({339.574, 110.984}, {337.942, 112.708},
                        {336.753, 113.784})
          .CubicCurveTo({336.768, 113.8}, {336.782, 113.816},
                        {336.796, 113.833})
          .CubicCurveTo({338.104, 112.946}, {340.187, 111.755},
                        {340.65, 112.813})
          .CubicCurveTo({340.71, 112.95}, {340.728, 113.102},
                        {340.678, 113.245})
          .Close()
          .MoveTo({346.357, 106.771})
          .CubicCurveTo({346.295, 104.987}, {347.924, 104.139},
                        {347.924, 104.139})
          .CubicCurveTo({347.924, 104.139}, {347.982, 105.931},
                        {346.357, 106.771})
          .Close()
          .MoveTo({347.56, 106.771})
          .CubicCurveTo({347.498, 104.987}, {349.127, 104.139},
                        {349.127, 104.139})
          .CubicCurveTo({349.127, 104.139}, {349.185, 105.931},
                        {347.56, 106.771})
          .Close()
          .TakePath();
  Entity entity;
  entity.SetTransformation(Matrix::MakeScale(GetContentScale()));
  entity.SetContents(SolidColorContents::Make(path, Color::Red()));
  ASSERT_TRUE(OpenPlaygroundHere(entity));
}

TEST_P(EntityTest, SolidColorContentsStrokeSetStrokeCapsAndJoins) {
  {
    auto geometry = Geometry::MakeStrokePath(Path{});
    auto path_geometry = static_cast<StrokePathGeometry*>(geometry.get());
    // Defaults.
    ASSERT_EQ(path_geometry->GetStrokeCap(), Cap::kButt);
    ASSERT_EQ(path_geometry->GetStrokeJoin(), Join::kMiter);
  }

  {
    auto geometry = Geometry::MakeStrokePath(Path{}, 1.0, 4.0, Cap::kSquare);
    auto path_geometry = static_cast<StrokePathGeometry*>(geometry.get());
    ASSERT_EQ(path_geometry->GetStrokeCap(), Cap::kSquare);
  }

  {
    auto geometry = Geometry::MakeStrokePath(Path{}, 1.0, 4.0, Cap::kRound);
    auto path_geometry = static_cast<StrokePathGeometry*>(geometry.get());
    ASSERT_EQ(path_geometry->GetStrokeCap(), Cap::kRound);
  }
}

TEST_P(EntityTest, SolidColorContentsStrokeSetMiterLimit) {
  {
    auto geometry = Geometry::MakeStrokePath(Path{});
    auto path_geometry = static_cast<StrokePathGeometry*>(geometry.get());
    ASSERT_FLOAT_EQ(path_geometry->GetMiterLimit(), 4);
  }

  {
    auto geometry = Geometry::MakeStrokePath(Path{}, 1.0, /*miter_limit=*/8.0);
    auto path_geometry = static_cast<StrokePathGeometry*>(geometry.get());
    ASSERT_FLOAT_EQ(path_geometry->GetMiterLimit(), 8);
  }

  {
    auto geometry = Geometry::MakeStrokePath(Path{}, 1.0, /*miter_limit=*/-1.0);
    auto path_geometry = static_cast<StrokePathGeometry*>(geometry.get());
    ASSERT_FLOAT_EQ(path_geometry->GetMiterLimit(), 4);
  }
}

TEST_P(EntityTest, BlendingModeOptions) {
  std::vector<const char*> blend_mode_names;
  std::vector<BlendMode> blend_mode_values;
  {
    // Force an exhausiveness check with a switch. When adding blend modes,
    // update this switch with a new name/value to make it selectable in the
    // test GUI.

    const BlendMode b{};
    static_assert(b == BlendMode::kClear);  // Ensure the first item in
                                            // the switch is the first
                                            // item in the enum.
    static_assert(Entity::kLastPipelineBlendMode == BlendMode::kModulate);
    switch (b) {
      case BlendMode::kClear:
        blend_mode_names.push_back("Clear");
        blend_mode_values.push_back(BlendMode::kClear);
      case BlendMode::kSource:
        blend_mode_names.push_back("Source");
        blend_mode_values.push_back(BlendMode::kSource);
      case BlendMode::kDestination:
        blend_mode_names.push_back("Destination");
        blend_mode_values.push_back(BlendMode::kDestination);
      case BlendMode::kSourceOver:
        blend_mode_names.push_back("SourceOver");
        blend_mode_values.push_back(BlendMode::kSourceOver);
      case BlendMode::kDestinationOver:
        blend_mode_names.push_back("DestinationOver");
        blend_mode_values.push_back(BlendMode::kDestinationOver);
      case BlendMode::kSourceIn:
        blend_mode_names.push_back("SourceIn");
        blend_mode_values.push_back(BlendMode::kSourceIn);
      case BlendMode::kDestinationIn:
        blend_mode_names.push_back("DestinationIn");
        blend_mode_values.push_back(BlendMode::kDestinationIn);
      case BlendMode::kSourceOut:
        blend_mode_names.push_back("SourceOut");
        blend_mode_values.push_back(BlendMode::kSourceOut);
      case BlendMode::kDestinationOut:
        blend_mode_names.push_back("DestinationOut");
        blend_mode_values.push_back(BlendMode::kDestinationOut);
      case BlendMode::kSourceATop:
        blend_mode_names.push_back("SourceATop");
        blend_mode_values.push_back(BlendMode::kSourceATop);
      case BlendMode::kDestinationATop:
        blend_mode_names.push_back("DestinationATop");
        blend_mode_values.push_back(BlendMode::kDestinationATop);
      case BlendMode::kXor:
        blend_mode_names.push_back("Xor");
        blend_mode_values.push_back(BlendMode::kXor);
      case BlendMode::kPlus:
        blend_mode_names.push_back("Plus");
        blend_mode_values.push_back(BlendMode::kPlus);
      case BlendMode::kModulate:
        blend_mode_names.push_back("Modulate");
        blend_mode_values.push_back(BlendMode::kModulate);
    };
  }

  auto callback = [&](ContentContext& context, RenderPass& pass) {
    auto world_matrix = Matrix::MakeScale(GetContentScale());
    auto draw_rect = [&context, &pass, &world_matrix](
                         Rect rect, Color color, BlendMode blend_mode) -> bool {
      using VS = SolidFillPipeline::VertexShader;
      using FS = SolidFillPipeline::FragmentShader;

      VertexBufferBuilder<VS::PerVertexData> vtx_builder;
      {
        auto r = rect.GetLTRB();
        vtx_builder.AddVertices({
            {Point(r[0], r[1])},
            {Point(r[2], r[1])},
            {Point(r[2], r[3])},
            {Point(r[0], r[1])},
            {Point(r[2], r[3])},
            {Point(r[0], r[3])},
        });
      }

      Command cmd;
      cmd.label = "Blended Rectangle";
      auto options = OptionsFromPass(pass);
      options.blend_mode = blend_mode;
      options.primitive_type = PrimitiveType::kTriangle;
      cmd.pipeline = context.GetSolidFillPipeline(options);
      cmd.BindVertices(
          vtx_builder.CreateVertexBuffer(pass.GetTransientsBuffer()));

      VS::FrameInfo frame_info;
      frame_info.mvp =
          Matrix::MakeOrthographic(pass.GetRenderTargetSize()) * world_matrix;
      VS::BindFrameInfo(cmd,
                        pass.GetTransientsBuffer().EmplaceUniform(frame_info));

      FS::FragInfo frag_info;
      frag_info.color = color.Premultiply();
      FS::BindFragInfo(cmd,
                       pass.GetTransientsBuffer().EmplaceUniform(frag_info));

      return pass.AddCommand(std::move(cmd));
    };

    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    static Color color1(1, 0, 0, 0.5), color2(0, 1, 0, 0.5);
    ImGui::ColorEdit4("Color 1", reinterpret_cast<float*>(&color1));
    ImGui::ColorEdit4("Color 2", reinterpret_cast<float*>(&color2));
    static int current_blend_index = 3;
    ImGui::ListBox("Blending mode", &current_blend_index,
                   blend_mode_names.data(), blend_mode_names.size());
    ImGui::End();

    BlendMode selected_mode = blend_mode_values[current_blend_index];

    Point a, b, c, d;
    std::tie(a, b) = IMPELLER_PLAYGROUND_LINE(
        Point(400, 100), Point(200, 300), 20, Color::White(), Color::White());
    std::tie(c, d) = IMPELLER_PLAYGROUND_LINE(
        Point(470, 190), Point(270, 390), 20, Color::White(), Color::White());

    bool result = true;
    result = result && draw_rect(Rect(0, 0, pass.GetRenderTargetSize().width,
                                      pass.GetRenderTargetSize().height),
                                 Color(), BlendMode::kClear);
    result = result && draw_rect(Rect::MakeLTRB(a.x, a.y, b.x, b.y), color1,
                                 BlendMode::kSourceOver);
    result = result && draw_rect(Rect::MakeLTRB(c.x, c.y, d.x, d.y), color2,
                                 selected_mode);
    return result;
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(EntityTest, BezierCircleScaled) {
  auto callback = [&](ContentContext& context, RenderPass& pass) -> bool {
    static float scale = 20;

    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::SliderFloat("Scale", &scale, 1, 100);
    ImGui::End();

    Entity entity;
    entity.SetTransformation(Matrix::MakeScale(GetContentScale()));
    auto path = PathBuilder{}
                    .MoveTo({97.325, 34.818})
                    .CubicCurveTo({98.50862885295136, 34.81812293973836},
                                  {99.46822048142015, 33.85863261475589},
                                  {99.46822048142015, 32.67499810206613})
                    .CubicCurveTo({99.46822048142015, 31.491363589376355},
                                  {98.50862885295136, 30.53187326439389},
                                  {97.32499434685802, 30.531998226542708})
                    .CubicCurveTo({96.14153655073771, 30.532123170035373},
                                  {95.18222070648729, 31.491540299350355},
                                  {95.18222070648729, 32.67499810206613})
                    .CubicCurveTo({95.18222070648729, 33.85845590478189},
                                  {96.14153655073771, 34.81787303409686},
                                  {97.32499434685802, 34.81799797758954})
                    .Close()
                    .TakePath();
    entity.SetTransformation(
        Matrix::MakeScale({scale, scale, 1.0}).Translate({-90, -20, 0}));
    entity.SetContents(SolidColorContents::Make(path, Color::Red()));
    return entity.Render(context, pass);
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(EntityTest, Filters) {
  auto bridge = CreateTextureForFixture("bay_bridge.jpg");
  auto boston = CreateTextureForFixture("boston.jpg");
  auto kalimba = CreateTextureForFixture("kalimba.jpg");
  ASSERT_TRUE(bridge && boston && kalimba);

  auto callback = [&](ContentContext& context, RenderPass& pass) -> bool {
    auto fi_bridge = FilterInput::Make(bridge);
    auto fi_boston = FilterInput::Make(boston);
    auto fi_kalimba = FilterInput::Make(kalimba);

    std::shared_ptr<FilterContents> blend0 = ColorFilterContents::MakeBlend(
        BlendMode::kModulate, {fi_kalimba, fi_boston});

    auto blend1 = ColorFilterContents::MakeBlend(
        BlendMode::kScreen,
        {FilterInput::Make(blend0), fi_bridge, fi_bridge, fi_bridge});

    Entity entity;
    entity.SetTransformation(Matrix::MakeScale(GetContentScale()) *
                             Matrix::MakeTranslation({500, 300}) *
                             Matrix::MakeScale(Vector2{0.5, 0.5}));
    entity.SetContents(blend1);
    return entity.Render(context, pass);
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(EntityTest, GaussianBlurFilter) {
  auto boston = CreateTextureForFixture("boston.jpg");
  ASSERT_TRUE(boston);

  auto callback = [&](ContentContext& context, RenderPass& pass) -> bool {
    const char* input_type_names[] = {"Texture", "Solid Color"};
    const char* blur_type_names[] = {"Image blur", "Mask blur"};
    const char* pass_variation_names[] = {"Two pass", "Directional"};
    const char* blur_style_names[] = {"Normal", "Solid", "Outer", "Inner"};
    const char* tile_mode_names[] = {"Clamp", "Repeat", "Mirror", "Decal"};
    const FilterContents::BlurStyle blur_styles[] = {
        FilterContents::BlurStyle::kNormal, FilterContents::BlurStyle::kSolid,
        FilterContents::BlurStyle::kOuter, FilterContents::BlurStyle::kInner};
    const Entity::TileMode tile_modes[] = {
        Entity::TileMode::kClamp, Entity::TileMode::kRepeat,
        Entity::TileMode::kMirror, Entity::TileMode::kDecal};

    // UI state.
    static int selected_input_type = 0;
    static Color input_color = Color::Black();
    static int selected_blur_type = 0;
    static int selected_pass_variation = 0;
    static float blur_amount[2] = {10, 10};
    static int selected_blur_style = 0;
    static int selected_tile_mode = 3;
    static Color cover_color(1, 0, 0, 0.2);
    static Color bounds_color(0, 1, 0, 0.1);
    static float offset[2] = {500, 400};
    static float rotation = 0;
    static float scale[2] = {0.65, 0.65};
    static float skew[2] = {0, 0};
    static float path_rect[4] = {0, 0,
                                 static_cast<float>(boston->GetSize().width),
                                 static_cast<float>(boston->GetSize().height)};

    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    {
      ImGui::Combo("Input type", &selected_input_type, input_type_names,
                   sizeof(input_type_names) / sizeof(char*));
      if (selected_input_type == 0) {
        ImGui::SliderFloat("Input opacity", &input_color.alpha, 0, 1);
      } else {
        ImGui::ColorEdit4("Input color",
                          reinterpret_cast<float*>(&input_color));
      }
      ImGui::Combo("Blur type", &selected_blur_type, blur_type_names,
                   sizeof(blur_type_names) / sizeof(char*));
      if (selected_blur_type == 0) {
        ImGui::Combo("Pass variation", &selected_pass_variation,
                     pass_variation_names,
                     sizeof(pass_variation_names) / sizeof(char*));
      }
      ImGui::SliderFloat2("Sigma", blur_amount, 0, 10);
      ImGui::Combo("Blur style", &selected_blur_style, blur_style_names,
                   sizeof(blur_style_names) / sizeof(char*));
      ImGui::Combo("Tile mode", &selected_tile_mode, tile_mode_names,
                   sizeof(tile_mode_names) / sizeof(char*));
      ImGui::ColorEdit4("Cover color", reinterpret_cast<float*>(&cover_color));
      ImGui::ColorEdit4("Bounds color",
                        reinterpret_cast<float*>(&bounds_color));
      ImGui::SliderFloat2("Translation", offset, 0,
                          pass.GetRenderTargetSize().width);
      ImGui::SliderFloat("Rotation", &rotation, 0, kPi * 2);
      ImGui::SliderFloat2("Scale", scale, 0, 3);
      ImGui::SliderFloat2("Skew", skew, -3, 3);
      ImGui::SliderFloat4("Path XYWH", path_rect, -1000, 1000);
    }
    ImGui::End();

    std::shared_ptr<Contents> input;
    Size input_size;

    auto input_rect =
        Rect::MakeXYWH(path_rect[0], path_rect[1], path_rect[2], path_rect[3]);
    if (selected_input_type == 0) {
      auto texture = std::make_shared<TextureContents>();
      texture->SetSourceRect(Rect::MakeSize(boston->GetSize()));
      texture->SetRect(input_rect);
      texture->SetTexture(boston);
      texture->SetOpacity(input_color.alpha);

      input = texture;
      input_size = input_rect.size;
    } else {
      auto fill = std::make_shared<SolidColorContents>();
      fill->SetColor(input_color);
      fill->SetGeometry(
          Geometry::MakeFillPath(PathBuilder{}.AddRect(input_rect).TakePath()));

      input = fill;
      input_size = input_rect.size;
    }

    std::shared_ptr<FilterContents> blur;
    if (selected_pass_variation == 0) {
      blur = FilterContents::MakeGaussianBlur(
          FilterInput::Make(input), Sigma{blur_amount[0]},
          Sigma{blur_amount[1]}, blur_styles[selected_blur_style],
          tile_modes[selected_tile_mode]);
    } else {
      Vector2 blur_vector(blur_amount[0], blur_amount[1]);
      blur = FilterContents::MakeDirectionalGaussianBlur(
          FilterInput::Make(input), Sigma{blur_vector.GetLength()},
          blur_vector.Normalize());
    }

    auto mask_blur = FilterContents::MakeBorderMaskBlur(
        FilterInput::Make(input), Sigma{blur_amount[0]}, Sigma{blur_amount[1]},
        blur_styles[selected_blur_style]);

    auto ctm = Matrix::MakeScale(GetContentScale()) *
               Matrix::MakeTranslation(Vector3(offset[0], offset[1])) *
               Matrix::MakeRotationZ(Radians(rotation)) *
               Matrix::MakeScale(Vector2(scale[0], scale[1])) *
               Matrix::MakeSkew(skew[0], skew[1]) *
               Matrix::MakeTranslation(-Point(input_size) / 2);

    auto target_contents = selected_blur_type == 0 ? blur : mask_blur;

    Entity entity;
    entity.SetContents(target_contents);
    entity.SetTransformation(ctm);

    entity.Render(context, pass);

    // Renders a red "cover" rectangle that shows the original position of the
    // unfiltered input.
    Entity cover_entity;
    cover_entity.SetContents(SolidColorContents::Make(
        PathBuilder{}.AddRect(input_rect).TakePath(), cover_color));
    cover_entity.SetTransformation(ctm);

    cover_entity.Render(context, pass);

    // Renders a green bounding rect of the target filter.
    Entity bounds_entity;
    bounds_entity.SetContents(SolidColorContents::Make(
        PathBuilder{}
            .AddRect(target_contents->GetCoverage(entity).value())
            .TakePath(),
        bounds_color));
    bounds_entity.SetTransformation(Matrix());

    bounds_entity.Render(context, pass);

    return true;
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(EntityTest, MorphologyFilter) {
  auto boston = CreateTextureForFixture("boston.jpg");
  ASSERT_TRUE(boston);

  auto callback = [&](ContentContext& context, RenderPass& pass) -> bool {
    const char* morphology_type_names[] = {"Dilate", "Erode"};
    const FilterContents::MorphType morphology_types[] = {
        FilterContents::MorphType::kDilate, FilterContents::MorphType::kErode};
    static Color input_color = Color::Black();
    // UI state.
    static int selected_morphology_type = 0;
    static float radius[2] = {20, 20};
    static Color cover_color(1, 0, 0, 0.2);
    static Color bounds_color(0, 1, 0, 0.1);
    static float offset[2] = {500, 400};
    static float rotation = 0;
    static float scale[2] = {0.65, 0.65};
    static float skew[2] = {0, 0};
    static float path_rect[4] = {0, 0,
                                 static_cast<float>(boston->GetSize().width),
                                 static_cast<float>(boston->GetSize().height)};
    static float effect_transform_scale = 1;

    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    {
      ImGui::Combo("Morphology type", &selected_morphology_type,
                   morphology_type_names,
                   sizeof(morphology_type_names) / sizeof(char*));
      ImGui::SliderFloat2("Radius", radius, 0, 200);
      ImGui::SliderFloat("Input opacity", &input_color.alpha, 0, 1);
      ImGui::ColorEdit4("Cover color", reinterpret_cast<float*>(&cover_color));
      ImGui::ColorEdit4("Bounds color",
                        reinterpret_cast<float*>(&bounds_color));
      ImGui::SliderFloat2("Translation", offset, 0,
                          pass.GetRenderTargetSize().width);
      ImGui::SliderFloat("Rotation", &rotation, 0, kPi * 2);
      ImGui::SliderFloat2("Scale", scale, 0, 3);
      ImGui::SliderFloat2("Skew", skew, -3, 3);
      ImGui::SliderFloat4("Path XYWH", path_rect, -1000, 1000);
      ImGui::SliderFloat("Effect transform scale", &effect_transform_scale, 0,
                         3);
    }
    ImGui::End();

    std::shared_ptr<Contents> input;
    Size input_size;

    auto input_rect =
        Rect::MakeXYWH(path_rect[0], path_rect[1], path_rect[2], path_rect[3]);
    auto texture = std::make_shared<TextureContents>();
    texture->SetSourceRect(Rect::MakeSize(boston->GetSize()));
    texture->SetRect(input_rect);
    texture->SetTexture(boston);
    texture->SetOpacity(input_color.alpha);

    input = texture;
    input_size = input_rect.size;

    auto effect_transform = Matrix::MakeScale(
        Vector2{effect_transform_scale, effect_transform_scale});

    auto contents = FilterContents::MakeMorphology(
        FilterInput::Make(input), Radius{radius[0]}, Radius{radius[1]},
        morphology_types[selected_morphology_type], effect_transform);

    auto ctm = Matrix::MakeScale(GetContentScale()) *
               Matrix::MakeTranslation(Vector3(offset[0], offset[1])) *
               Matrix::MakeRotationZ(Radians(rotation)) *
               Matrix::MakeScale(Vector2(scale[0], scale[1])) *
               Matrix::MakeSkew(skew[0], skew[1]) *
               Matrix::MakeTranslation(-Point(input_size) / 2);

    Entity entity;
    entity.SetContents(contents);
    entity.SetTransformation(ctm);

    entity.Render(context, pass);

    // Renders a red "cover" rectangle that shows the original position of the
    // unfiltered input.
    Entity cover_entity;
    cover_entity.SetContents(SolidColorContents::Make(
        PathBuilder{}.AddRect(input_rect).TakePath(), cover_color));
    cover_entity.SetTransformation(ctm);

    cover_entity.Render(context, pass);

    // Renders a green bounding rect of the target filter.
    Entity bounds_entity;
    bounds_entity.SetContents(SolidColorContents::Make(
        PathBuilder{}.AddRect(contents->GetCoverage(entity).value()).TakePath(),
        bounds_color));
    bounds_entity.SetTransformation(Matrix());

    bounds_entity.Render(context, pass);

    return true;
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(EntityTest, SetBlendMode) {
  Entity entity;
  ASSERT_EQ(entity.GetBlendMode(), BlendMode::kSourceOver);
  entity.SetBlendMode(BlendMode::kClear);
  ASSERT_EQ(entity.GetBlendMode(), BlendMode::kClear);
}

TEST_P(EntityTest, ContentsGetBoundsForEmptyPathReturnsNullopt) {
  Entity entity;
  entity.SetContents(std::make_shared<SolidColorContents>());
  ASSERT_FALSE(entity.GetCoverage().has_value());
}

TEST_P(EntityTest, SolidStrokeCoverageIsCorrect) {
  {
    auto geometry = Geometry::MakeStrokePath(
        PathBuilder{}.AddLine({0, 0}, {10, 10}).TakePath(), 4.0, 4.0,
        Cap::kButt, Join::kBevel);

    Entity entity;
    auto contents = std::make_unique<SolidColorContents>();
    contents->SetGeometry(std::move(geometry));
    contents->SetColor(Color::Black());
    entity.SetContents(std::move(contents));
    auto actual = entity.GetCoverage();
    auto expected = Rect::MakeLTRB(-2, -2, 12, 12);
    ASSERT_TRUE(actual.has_value());
    ASSERT_RECT_NEAR(actual.value(), expected);
  }

  // Cover the Cap::kSquare case.
  {
    auto geometry = Geometry::MakeStrokePath(
        PathBuilder{}.AddLine({0, 0}, {10, 10}).TakePath(), 4.0, 4.0,
        Cap::kSquare, Join::kBevel);

    Entity entity;
    auto contents = std::make_unique<SolidColorContents>();
    contents->SetGeometry(std::move(geometry));
    contents->SetColor(Color::Black());
    entity.SetContents(std::move(contents));
    auto actual = entity.GetCoverage();
    auto expected =
        Rect::MakeLTRB(-sqrt(8), -sqrt(8), 10 + sqrt(8), 10 + sqrt(8));
    ASSERT_TRUE(actual.has_value());
    ASSERT_RECT_NEAR(actual.value(), expected);
  }

  // Cover the Join::kMiter case.
  {
    auto geometry = Geometry::MakeStrokePath(
        PathBuilder{}.AddLine({0, 0}, {10, 10}).TakePath(), 4.0, 2.0,
        Cap::kSquare, Join::kMiter);

    Entity entity;
    auto contents = std::make_unique<SolidColorContents>();
    contents->SetGeometry(std::move(geometry));
    contents->SetColor(Color::Black());
    entity.SetContents(std::move(contents));
    auto actual = entity.GetCoverage();
    auto expected = Rect::MakeLTRB(-4, -4, 14, 14);
    ASSERT_TRUE(actual.has_value());
    ASSERT_RECT_NEAR(actual.value(), expected);
  }
}

TEST_P(EntityTest, BorderMaskBlurCoverageIsCorrect) {
  auto fill = std::make_shared<SolidColorContents>();
  fill->SetGeometry(Geometry::MakeFillPath(
      PathBuilder{}.AddRect(Rect::MakeXYWH(0, 0, 300, 400)).TakePath()));
  fill->SetColor(Color::CornflowerBlue());
  auto border_mask_blur = FilterContents::MakeBorderMaskBlur(
      FilterInput::Make(fill), Radius{3}, Radius{4});

  {
    Entity e;
    e.SetTransformation(Matrix());
    auto actual = border_mask_blur->GetCoverage(e);
    auto expected = Rect::MakeXYWH(-3, -4, 306, 408);
    ASSERT_TRUE(actual.has_value());
    ASSERT_RECT_NEAR(actual.value(), expected);
  }

  {
    Entity e;
    e.SetTransformation(Matrix::MakeRotationZ(Radians{kPi / 4}));
    auto actual = border_mask_blur->GetCoverage(e);
    auto expected = Rect::MakeXYWH(-287.792, -4.94975, 504.874, 504.874);
    ASSERT_TRUE(actual.has_value());
    ASSERT_RECT_NEAR(actual.value(), expected);
  }
}

TEST_P(EntityTest, DrawAtlasNoColor) {
  // Draws the image as four squares stiched together.
  auto atlas = CreateTextureForFixture("bay_bridge.jpg");
  auto size = atlas->GetSize();
  // Divide image into four quadrants.
  Scalar half_width = size.width / 2;
  Scalar half_height = size.height / 2;
  std::vector<Rect> texture_coordinates = {
      Rect::MakeLTRB(0, 0, half_width, half_height),
      Rect::MakeLTRB(half_width, 0, size.width, half_height),
      Rect::MakeLTRB(0, half_height, half_width, size.height),
      Rect::MakeLTRB(half_width, half_height, size.width, size.height)};
  // Position quadrants adjacent to eachother.
  std::vector<Matrix> transforms = {
      Matrix::MakeTranslation({0, 0, 0}),
      Matrix::MakeTranslation({half_width, 0, 0}),
      Matrix::MakeTranslation({0, half_height, 0}),
      Matrix::MakeTranslation({half_width, half_height, 0})};
  std::shared_ptr<AtlasContents> contents = std::make_shared<AtlasContents>();

  contents->SetTransforms(std::move(transforms));
  contents->SetTextureCoordinates(std::move(texture_coordinates));
  contents->SetTexture(atlas);
  contents->SetBlendMode(BlendMode::kSource);

  Entity e;
  e.SetTransformation(Matrix::MakeScale(GetContentScale()));
  e.SetContents(contents);

  ASSERT_TRUE(OpenPlaygroundHere(e));
}

TEST_P(EntityTest, DrawAtlasWithColorAdvanced) {
  // Draws the image as four squares stiched together. Because blend modes
  // aren't implented this ends up as four solid color blocks.
  auto atlas = CreateTextureForFixture("bay_bridge.jpg");
  auto size = atlas->GetSize();
  // Divide image into four quadrants.
  Scalar half_width = size.width / 2;
  Scalar half_height = size.height / 2;
  std::vector<Rect> texture_coordinates = {
      Rect::MakeLTRB(0, 0, half_width, half_height),
      Rect::MakeLTRB(half_width, 0, size.width, half_height),
      Rect::MakeLTRB(0, half_height, half_width, size.height),
      Rect::MakeLTRB(half_width, half_height, size.width, size.height)};
  // Position quadrants adjacent to eachother.
  std::vector<Matrix> transforms = {
      Matrix::MakeTranslation({0, 0, 0}),
      Matrix::MakeTranslation({half_width, 0, 0}),
      Matrix::MakeTranslation({0, half_height, 0}),
      Matrix::MakeTranslation({half_width, half_height, 0})};
  std::vector<Color> colors = {Color::Red(), Color::Green(), Color::Blue(),
                               Color::Yellow()};
  std::shared_ptr<AtlasContents> contents = std::make_shared<AtlasContents>();

  contents->SetTransforms(std::move(transforms));
  contents->SetTextureCoordinates(std::move(texture_coordinates));
  contents->SetTexture(atlas);
  contents->SetColors(colors);
  contents->SetBlendMode(BlendMode::kModulate);

  Entity e;
  e.SetTransformation(Matrix::MakeScale(GetContentScale()));
  e.SetContents(contents);

  ASSERT_TRUE(OpenPlaygroundHere(e));
}

TEST_P(EntityTest, DrawAtlasWithColorSimple) {
  // Draws the image as four squares stiched together. Because blend modes
  // aren't implented this ends up as four solid color blocks.
  auto atlas = CreateTextureForFixture("bay_bridge.jpg");
  auto size = atlas->GetSize();
  // Divide image into four quadrants.
  Scalar half_width = size.width / 2;
  Scalar half_height = size.height / 2;
  std::vector<Rect> texture_coordinates = {
      Rect::MakeLTRB(0, 0, half_width, half_height),
      Rect::MakeLTRB(half_width, 0, size.width, half_height),
      Rect::MakeLTRB(0, half_height, half_width, size.height),
      Rect::MakeLTRB(half_width, half_height, size.width, size.height)};
  // Position quadrants adjacent to eachother.
  std::vector<Matrix> transforms = {
      Matrix::MakeTranslation({0, 0, 0}),
      Matrix::MakeTranslation({half_width, 0, 0}),
      Matrix::MakeTranslation({0, half_height, 0}),
      Matrix::MakeTranslation({half_width, half_height, 0})};
  std::vector<Color> colors = {Color::Red(), Color::Green(), Color::Blue(),
                               Color::Yellow()};
  std::shared_ptr<AtlasContents> contents = std::make_shared<AtlasContents>();

  contents->SetTransforms(std::move(transforms));
  contents->SetTextureCoordinates(std::move(texture_coordinates));
  contents->SetTexture(atlas);
  contents->SetColors(colors);
  contents->SetBlendMode(BlendMode::kSourceATop);

  Entity e;
  e.SetTransformation(Matrix::MakeScale(GetContentScale()));
  e.SetContents(contents);

  ASSERT_TRUE(OpenPlaygroundHere(e));
}

TEST_P(EntityTest, DrawAtlasUsesProvidedCullRectForCoverage) {
  auto atlas = CreateTextureForFixture("bay_bridge.jpg");
  auto size = atlas->GetSize();

  Scalar half_width = size.width / 2;
  Scalar half_height = size.height / 2;
  std::vector<Rect> texture_coordinates = {
      Rect::MakeLTRB(0, 0, half_width, half_height),
      Rect::MakeLTRB(half_width, 0, size.width, half_height),
      Rect::MakeLTRB(0, half_height, half_width, size.height),
      Rect::MakeLTRB(half_width, half_height, size.width, size.height)};
  std::vector<Matrix> transforms = {
      Matrix::MakeTranslation({0, 0, 0}),
      Matrix::MakeTranslation({half_width, 0, 0}),
      Matrix::MakeTranslation({0, half_height, 0}),
      Matrix::MakeTranslation({half_width, half_height, 0})};

  std::shared_ptr<AtlasContents> contents = std::make_shared<AtlasContents>();

  contents->SetTransforms(std::move(transforms));
  contents->SetTextureCoordinates(std::move(texture_coordinates));
  contents->SetTexture(atlas);
  contents->SetBlendMode(BlendMode::kSource);

  auto transform = Matrix::MakeScale(GetContentScale());
  Entity e;
  e.SetTransformation(transform);
  e.SetContents(contents);

  ASSERT_EQ(contents->GetCoverage(e).value(),
            Rect::MakeSize(size).TransformBounds(transform));

  contents->SetCullRect(Rect::MakeLTRB(0, 0, 10, 10));

  ASSERT_EQ(contents->GetCoverage(e).value(),
            Rect::MakeLTRB(0, 0, 10, 10).TransformBounds(transform));
}

TEST_P(EntityTest, DrawAtlasWithOpacity) {
  // Draws the image as four squares stiched together slightly
  // opaque
  auto atlas = CreateTextureForFixture("bay_bridge.jpg");
  auto size = atlas->GetSize();
  // Divide image into four quadrants.
  Scalar half_width = size.width / 2;
  Scalar half_height = size.height / 2;
  std::vector<Rect> texture_coordinates = {
      Rect::MakeLTRB(0, 0, half_width, half_height),
      Rect::MakeLTRB(half_width, 0, size.width, half_height),
      Rect::MakeLTRB(0, half_height, half_width, size.height),
      Rect::MakeLTRB(half_width, half_height, size.width, size.height)};
  // Position quadrants adjacent to eachother.
  std::vector<Matrix> transforms = {
      Matrix::MakeTranslation({0, 0, 0}),
      Matrix::MakeTranslation({half_width, 0, 0}),
      Matrix::MakeTranslation({0, half_height, 0}),
      Matrix::MakeTranslation({half_width, half_height, 0})};

  std::shared_ptr<AtlasContents> contents = std::make_shared<AtlasContents>();

  contents->SetTransforms(std::move(transforms));
  contents->SetTextureCoordinates(std::move(texture_coordinates));
  contents->SetTexture(atlas);
  contents->SetBlendMode(BlendMode::kSource);
  contents->SetAlpha(0.5);

  Entity e;
  e.SetTransformation(Matrix::MakeScale(GetContentScale()));
  e.SetContents(contents);

  ASSERT_TRUE(OpenPlaygroundHere(e));
}

TEST_P(EntityTest, DrawAtlasNoColorFullSize) {
  auto atlas = CreateTextureForFixture("bay_bridge.jpg");
  auto size = atlas->GetSize();
  std::vector<Rect> texture_coordinates = {
      Rect::MakeLTRB(0, 0, size.width, size.height)};
  std::vector<Matrix> transforms = {Matrix::MakeTranslation({0, 0, 0})};
  std::shared_ptr<AtlasContents> contents = std::make_shared<AtlasContents>();

  contents->SetTransforms(std::move(transforms));
  contents->SetTextureCoordinates(std::move(texture_coordinates));
  contents->SetTexture(atlas);
  contents->SetBlendMode(BlendMode::kSource);

  Entity e;
  e.SetTransformation(Matrix::MakeScale(GetContentScale()));
  e.SetContents(contents);

  ASSERT_TRUE(OpenPlaygroundHere(e));
}

TEST_P(EntityTest, SolidFillCoverageIsCorrect) {
  // No transform
  {
    auto fill = std::make_shared<SolidColorContents>();
    fill->SetColor(Color::CornflowerBlue());
    auto expected = Rect::MakeLTRB(100, 110, 200, 220);
    fill->SetGeometry(
        Geometry::MakeFillPath(PathBuilder{}.AddRect(expected).TakePath()));

    auto coverage = fill->GetCoverage({});
    ASSERT_TRUE(coverage.has_value());
    ASSERT_RECT_NEAR(coverage.value(), expected);
  }

  // Entity transform
  {
    auto fill = std::make_shared<SolidColorContents>();
    fill->SetColor(Color::CornflowerBlue());
    fill->SetGeometry(Geometry::MakeFillPath(
        PathBuilder{}.AddRect(Rect::MakeLTRB(100, 110, 200, 220)).TakePath()));

    Entity entity;
    entity.SetTransformation(Matrix::MakeTranslation(Vector2(4, 5)));
    entity.SetContents(std::move(fill));

    auto coverage = entity.GetCoverage();
    auto expected = Rect::MakeLTRB(104, 115, 204, 225);
    ASSERT_TRUE(coverage.has_value());
    ASSERT_RECT_NEAR(coverage.value(), expected);
  }

  // No coverage for fully transparent colors
  {
    auto fill = std::make_shared<SolidColorContents>();
    fill->SetColor(Color::WhiteTransparent());
    fill->SetGeometry(Geometry::MakeFillPath(
        PathBuilder{}.AddRect(Rect::MakeLTRB(100, 110, 200, 220)).TakePath()));

    auto coverage = fill->GetCoverage({});
    ASSERT_FALSE(coverage.has_value());
  }
}

TEST_P(EntityTest, SolidFillShouldRenderIsCorrect) {
  // No path.
  {
    auto fill = std::make_shared<SolidColorContents>();
    fill->SetColor(Color::CornflowerBlue());
    ASSERT_FALSE(fill->ShouldRender(Entity{}, Rect::MakeSize(Size{100, 100})));
    ASSERT_FALSE(
        fill->ShouldRender(Entity{}, Rect::MakeLTRB(-100, -100, -50, -50)));
  }

  // With path.
  {
    auto fill = std::make_shared<SolidColorContents>();
    fill->SetColor(Color::CornflowerBlue());
    fill->SetGeometry(Geometry::MakeFillPath(
        PathBuilder{}.AddRect(Rect::MakeLTRB(0, 0, 100, 100)).TakePath()));
    ASSERT_TRUE(fill->ShouldRender(Entity{}, Rect::MakeSize(Size{100, 100})));
    ASSERT_FALSE(
        fill->ShouldRender(Entity{}, Rect::MakeLTRB(-100, -100, -50, -50)));
  }

  // With paint cover.
  {
    auto fill = std::make_shared<SolidColorContents>();
    fill->SetColor(Color::CornflowerBlue());
    fill->SetGeometry(Geometry::MakeCover());
    ASSERT_TRUE(fill->ShouldRender(Entity{}, Rect::MakeSize(Size{100, 100})));
    ASSERT_TRUE(
        fill->ShouldRender(Entity{}, Rect::MakeLTRB(-100, -100, -50, -50)));
  }
}

TEST_P(EntityTest, ClipContentsShouldRenderIsCorrect) {
  // For clip ops, `ShouldRender` should always return true.

  // Clip.
  {
    auto clip = std::make_shared<ClipContents>();
    ASSERT_TRUE(clip->ShouldRender(Entity{}, Rect::MakeSize(Size{100, 100})));
    clip->SetGeometry(Geometry::MakeFillPath(
        PathBuilder{}.AddRect(Rect::MakeLTRB(0, 0, 100, 100)).TakePath()));
    ASSERT_TRUE(clip->ShouldRender(Entity{}, Rect::MakeSize(Size{100, 100})));
    ASSERT_TRUE(
        clip->ShouldRender(Entity{}, Rect::MakeLTRB(-100, -100, -50, -50)));
  }

  // Clip restore.
  {
    auto restore = std::make_shared<ClipRestoreContents>();
    ASSERT_TRUE(
        restore->ShouldRender(Entity{}, Rect::MakeSize(Size{100, 100})));
    ASSERT_TRUE(
        restore->ShouldRender(Entity{}, Rect::MakeLTRB(-100, -100, -50, -50)));
  }
}

TEST_P(EntityTest, ClipContentsGetStencilCoverageIsCorrect) {
  // Intersection: No stencil coverage, no geometry.
  {
    auto clip = std::make_shared<ClipContents>();
    clip->SetClipOperation(Entity::ClipOperation::kIntersect);
    auto result = clip->GetStencilCoverage(Entity{}, Rect{});

    ASSERT_FALSE(result.coverage.has_value());
  }

  // Intersection: No stencil coverage, with geometry.
  {
    auto clip = std::make_shared<ClipContents>();
    clip->SetClipOperation(Entity::ClipOperation::kIntersect);
    clip->SetGeometry(Geometry::MakeFillPath(
        PathBuilder{}.AddRect(Rect::MakeLTRB(0, 0, 100, 100)).TakePath()));
    auto result = clip->GetStencilCoverage(Entity{}, Rect{});

    ASSERT_FALSE(result.coverage.has_value());
  }

  // Intersection: With stencil coverage, no geometry.
  {
    auto clip = std::make_shared<ClipContents>();
    clip->SetClipOperation(Entity::ClipOperation::kIntersect);
    auto result =
        clip->GetStencilCoverage(Entity{}, Rect::MakeLTRB(0, 0, 100, 100));

    ASSERT_FALSE(result.coverage.has_value());
  }

  // Intersection: With stencil coverage, with geometry.
  {
    auto clip = std::make_shared<ClipContents>();
    clip->SetClipOperation(Entity::ClipOperation::kIntersect);
    clip->SetGeometry(Geometry::MakeFillPath(
        PathBuilder{}.AddRect(Rect::MakeLTRB(0, 0, 50, 50)).TakePath()));
    auto result =
        clip->GetStencilCoverage(Entity{}, Rect::MakeLTRB(0, 0, 100, 100));

    ASSERT_TRUE(result.coverage.has_value());
    ASSERT_RECT_NEAR(result.coverage.value(), Rect::MakeLTRB(0, 0, 50, 50));
    ASSERT_EQ(result.type, Contents::StencilCoverage::Type::kAppend);
  }

  // Difference: With stencil coverage, with geometry.
  {
    auto clip = std::make_shared<ClipContents>();
    clip->SetClipOperation(Entity::ClipOperation::kDifference);
    clip->SetGeometry(Geometry::MakeFillPath(
        PathBuilder{}.AddRect(Rect::MakeLTRB(0, 0, 50, 50)).TakePath()));
    auto result =
        clip->GetStencilCoverage(Entity{}, Rect::MakeLTRB(0, 0, 100, 100));

    ASSERT_TRUE(result.coverage.has_value());
    ASSERT_RECT_NEAR(result.coverage.value(), Rect::MakeLTRB(0, 0, 100, 100));
    ASSERT_EQ(result.type, Contents::StencilCoverage::Type::kAppend);
  }
}

TEST_P(EntityTest, RRectShadowTest) {
  auto callback = [&](ContentContext& context, RenderPass& pass) {
    static Color color = Color::Red();
    static float corner_radius = 100;
    static float blur_radius = 100;
    static bool show_coverage = false;
    static Color coverage_color = Color::Green().WithAlpha(0.2);

    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::SliderFloat("Corner radius", &corner_radius, 0, 300);
    ImGui::SliderFloat("Blur radius", &blur_radius, 0, 300);
    ImGui::ColorEdit4("Color", reinterpret_cast<Scalar*>(&color));
    ImGui::Checkbox("Show coverage", &show_coverage);
    if (show_coverage) {
      ImGui::ColorEdit4("Coverage color",
                        reinterpret_cast<Scalar*>(&coverage_color));
    }
    ImGui::End();

    auto [top_left, bottom_right] = IMPELLER_PLAYGROUND_LINE(
        Point(200, 200), Point(600, 400), 30, Color::White(), Color::White());
    auto rect =
        Rect::MakeLTRB(top_left.x, top_left.y, bottom_right.x, bottom_right.y);

    auto contents = std::make_unique<RRectShadowContents>();
    contents->SetRRect(rect, corner_radius);
    contents->SetColor(color);
    contents->SetSigma(Radius(blur_radius));

    Entity entity;
    entity.SetTransformation(Matrix::MakeScale(GetContentScale()));
    entity.SetContents(std::move(contents));
    entity.Render(context, pass);

    auto coverage = entity.GetCoverage();
    if (show_coverage && coverage.has_value()) {
      auto bounds_contents = std::make_unique<SolidColorContents>();
      bounds_contents->SetGeometry(Geometry::MakeFillPath(
          PathBuilder{}.AddRect(entity.GetCoverage().value()).TakePath()));
      bounds_contents->SetColor(coverage_color.Premultiply());
      Entity bounds_entity;
      bounds_entity.SetContents(std::move(bounds_contents));
      bounds_entity.Render(context, pass);
    }

    return true;
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(EntityTest, ColorMatrixFilterCoverageIsCorrect) {
  // Set up a simple color background.
  auto fill = std::make_shared<SolidColorContents>();
  fill->SetGeometry(Geometry::MakeFillPath(
      PathBuilder{}.AddRect(Rect::MakeXYWH(0, 0, 300, 400)).TakePath()));
  fill->SetColor(Color::Coral());

  // Set the color matrix filter.
  FilterContents::ColorMatrix matrix = {
      1, 1, 1, 1, 1,  //
      1, 1, 1, 1, 1,  //
      1, 1, 1, 1, 1,  //
      1, 1, 1, 1, 1,  //
  };

  auto filter =
      ColorFilterContents::MakeColorMatrix(FilterInput::Make(fill), matrix);

  Entity e;
  e.SetTransformation(Matrix());

  // Confirm that the actual filter coverage matches the expected coverage.
  auto actual = filter->GetCoverage(e);
  auto expected = Rect::MakeXYWH(0, 0, 300, 400);

  ASSERT_TRUE(actual.has_value());
  ASSERT_RECT_NEAR(actual.value(), expected);
}

TEST_P(EntityTest, ColorMatrixFilterEditable) {
  auto bay_bridge = CreateTextureForFixture("bay_bridge.jpg");
  ASSERT_TRUE(bay_bridge);

  auto callback = [&](ContentContext& context, RenderPass& pass) -> bool {
    // UI state.
    static FilterContents::ColorMatrix color_matrix = {
        1, 0, 0, 0, 0,  //
        0, 3, 0, 0, 0,  //
        0, 0, 1, 0, 0,  //
        0, 0, 0, 1, 0,  //
    };
    static float offset[2] = {500, 400};
    static float rotation = 0;
    static float scale[2] = {0.65, 0.65};
    static float skew[2] = {0, 0};

    // Define the ImGui
    ImGui::Begin("Color Matrix", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    {
      std::string label = "##1";
      for (int i = 0; i < 20; i += 5) {
        ImGui::InputScalarN(label.c_str(), ImGuiDataType_Float,
                            &(color_matrix.array[i]), 5, nullptr, nullptr,
                            "%.2f", 0);
        label[2]++;
      }

      ImGui::SliderFloat2("Translation", &offset[0], 0,
                          pass.GetRenderTargetSize().width);
      ImGui::SliderFloat("Rotation", &rotation, 0, kPi * 2);
      ImGui::SliderFloat2("Scale", &scale[0], 0, 3);
      ImGui::SliderFloat2("Skew", &skew[0], -3, 3);
    }
    ImGui::End();

    // Set the color matrix filter.
    auto filter = ColorFilterContents::MakeColorMatrix(
        FilterInput::Make(bay_bridge), color_matrix);

    // Define the entity with the color matrix filter.
    Entity entity;
    entity.SetTransformation(
        Matrix::MakeScale(GetContentScale()) *
        Matrix::MakeTranslation(Vector3(offset[0], offset[1])) *
        Matrix::MakeRotationZ(Radians(rotation)) *
        Matrix::MakeScale(Vector2(scale[0], scale[1])) *
        Matrix::MakeSkew(skew[0], skew[1]) *
        Matrix::MakeTranslation(-Point(bay_bridge->GetSize()) / 2));
    entity.SetContents(filter);
    entity.Render(context, pass);

    return true;
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(EntityTest, LinearToSrgbFilterCoverageIsCorrect) {
  // Set up a simple color background.
  auto fill = std::make_shared<SolidColorContents>();
  fill->SetGeometry(Geometry::MakeFillPath(
      PathBuilder{}.AddRect(Rect::MakeXYWH(0, 0, 300, 400)).TakePath()));
  fill->SetColor(Color::MintCream());

  auto filter =
      ColorFilterContents::MakeLinearToSrgbFilter(FilterInput::Make(fill));

  Entity e;
  e.SetTransformation(Matrix());

  // Confirm that the actual filter coverage matches the expected coverage.
  auto actual = filter->GetCoverage(e);
  auto expected = Rect::MakeXYWH(0, 0, 300, 400);

  ASSERT_TRUE(actual.has_value());
  ASSERT_RECT_NEAR(actual.value(), expected);
}

TEST_P(EntityTest, LinearToSrgbFilter) {
  auto image = CreateTextureForFixture("kalimba.jpg");
  ASSERT_TRUE(image);

  auto callback = [&](ContentContext& context, RenderPass& pass) -> bool {
    auto filtered =
        ColorFilterContents::MakeLinearToSrgbFilter(FilterInput::Make(image));

    // Define the entity that will serve as the control image as a Gaussian blur
    // filter with no filter at all.
    Entity entity_left;
    entity_left.SetTransformation(Matrix::MakeScale(GetContentScale()) *
                                  Matrix::MakeTranslation({100, 300}) *
                                  Matrix::MakeScale(Vector2{0.5, 0.5}));
    auto unfiltered = FilterContents::MakeGaussianBlur(FilterInput::Make(image),
                                                       Sigma{0}, Sigma{0});
    entity_left.SetContents(unfiltered);

    // Define the entity that will be filtered from linear to sRGB.
    Entity entity_right;
    entity_right.SetTransformation(Matrix::MakeScale(GetContentScale()) *
                                   Matrix::MakeTranslation({500, 300}) *
                                   Matrix::MakeScale(Vector2{0.5, 0.5}));
    entity_right.SetContents(filtered);
    return entity_left.Render(context, pass) &&
           entity_right.Render(context, pass);
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(EntityTest, SrgbToLinearFilterCoverageIsCorrect) {
  // Set up a simple color background.
  auto fill = std::make_shared<SolidColorContents>();
  fill->SetGeometry(Geometry::MakeFillPath(
      PathBuilder{}.AddRect(Rect::MakeXYWH(0, 0, 300, 400)).TakePath()));
  fill->SetColor(Color::DeepPink());

  auto filter =
      ColorFilterContents::MakeSrgbToLinearFilter(FilterInput::Make(fill));

  Entity e;
  e.SetTransformation(Matrix());

  // Confirm that the actual filter coverage matches the expected coverage.
  auto actual = filter->GetCoverage(e);
  auto expected = Rect::MakeXYWH(0, 0, 300, 400);

  ASSERT_TRUE(actual.has_value());
  ASSERT_RECT_NEAR(actual.value(), expected);
}

TEST_P(EntityTest, SrgbToLinearFilter) {
  auto image = CreateTextureForFixture("embarcadero.jpg");
  ASSERT_TRUE(image);

  auto callback = [&](ContentContext& context, RenderPass& pass) -> bool {
    auto filtered =
        ColorFilterContents::MakeSrgbToLinearFilter(FilterInput::Make(image));

    // Define the entity that will serve as the control image as a Gaussian blur
    // filter with no filter at all.
    Entity entity_left;
    entity_left.SetTransformation(Matrix::MakeScale(GetContentScale()) *
                                  Matrix::MakeTranslation({100, 300}) *
                                  Matrix::MakeScale(Vector2{0.5, 0.5}));
    auto unfiltered = FilterContents::MakeGaussianBlur(FilterInput::Make(image),
                                                       Sigma{0}, Sigma{0});
    entity_left.SetContents(unfiltered);

    // Define the entity that will be filtered from sRGB to linear.
    Entity entity_right;
    entity_right.SetTransformation(Matrix::MakeScale(GetContentScale()) *
                                   Matrix::MakeTranslation({500, 300}) *
                                   Matrix::MakeScale(Vector2{0.5, 0.5}));
    entity_right.SetContents(filtered);
    return entity_left.Render(context, pass) &&
           entity_right.Render(context, pass);
  };

  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(EntityTest, TTTBlendColor) {
  {
    Color src = {1, 0, 0, 0.5};
    Color dst = {1, 0, 1, 1};
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kClear),
              Color(0, 0, 0, 0));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSource),
              Color(1, 0, 0, 0.5));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestination),
              Color(1, 0, 1, 1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceOver),
              Color(1.5, 0, 0.5, 1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationOver),
              Color(1, 0, 1, 1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceIn),
              Color(1, 0, 0, 0.5));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationIn),
              Color(0.5, 0, 0.5, 0.5));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceOut),
              Color(0, 0, 0, 0));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationOut),
              Color(0.5, 0, 0.5, 0.5));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceATop),
              Color(1.5, 0, 0.5, 1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationATop),
              Color(0.5, 0, 0.5, 0.5));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kXor),
              Color(0.5, 0, 0.5, 0.5));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kPlus), Color(1, 0, 1, 1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kModulate),
              Color(1, 0, 0, 0.5));
  }

  {
    Color src = {1, 1, 0, 1};
    Color dst = {1, 0, 1, 1};

    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kClear),
              Color(0, 0, 0, 0));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSource),
              Color(1, 1, 0, 1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestination),
              Color(1, 0, 1, 1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceOver),
              Color(1, 1, 0, 1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationOver),
              Color(1, 0, 1, 1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceIn),
              Color(1, 1, 0, 1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationIn),
              Color(1, 0, 1, 1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceOut),
              Color(0, 0, 0, 0));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationOut),
              Color(0, 0, 0, 0));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceATop),
              Color(1, 1, 0, 1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationATop),
              Color(1, 0, 1, 1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kXor), Color(0, 0, 0, 0));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kPlus), Color(1, 1, 1, 1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kModulate),
              Color(1, 0, 0, 1));
  }

  {
    Color src = {1, 1, 0, 0.2};
    Color dst = {1, 1, 1, 0.5};

    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kClear),
              Color(0, 0, 0, 0));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSource),
              Color(1, 1, 0, 0.2));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestination),
              Color(1, 1, 1, 0.5));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceOver),
              Color(1.8, 1.8, 0.8, 0.6));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationOver),
              Color(1.5, 1.5, 1, 0.6));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceIn),
              Color(0.5, 0.5, 0, 0.1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationIn),
              Color(0.2, 0.2, 0.2, 0.1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceOut),
              Color(0.5, 0.5, 0, 0.1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationOut),
              Color(0.8, 0.8, 0.8, 0.4));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceATop),
              Color(1.3, 1.3, 0.8, 0.5));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationATop),
              Color(0.7, 0.7, 0.2, 0.2));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kXor),
              Color(1.3, 1.3, 0.8, 0.5));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kPlus),
              Color(1, 1, 1, 0.7));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kModulate),
              Color(1, 1, 0, 0.1));
  }

  {
    Color src = {1, 0.5, 0, 0.2};
    Color dst = {1, 1, 0.5, 0.5};
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kClear),
              Color(0, 0, 0, 0));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSource),
              Color(1, 0.5, 0, 0.2));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestination),
              Color(1, 1, 0.5, 0.5));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceOver),
              Color(1.8, 1.3, 0.4, 0.6));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationOver),
              Color(1.5, 1.25, 0.5, 0.6));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceIn),
              Color(0.5, 0.25, 0, 0.1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationIn),
              Color(0.2, 0.2, 0.1, 0.1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceOut),
              Color(0.5, 0.25, 0, 0.1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationOut),
              Color(0.8, 0.8, 0.4, 0.4));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceATop),
              Color(1.3, 1.05, 0.4, 0.5));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationATop),
              Color(0.7, 0.45, 0.1, 0.2));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kXor),
              Color(1.3, 1.05, 0.4, 0.5));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kPlus),
              Color(1, 1, 0.5, 0.7));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kModulate),
              Color(1, 0.5, 0, 0.1));
  }

  {
    Color src = {0.5, 0.5, 0, 0.2};
    Color dst = {0, 1, 0.5, 0.5};
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kClear),
              Color(0, 0, 0, 0));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSource),
              Color(0.5, 0.5, 0, 0.2));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestination),
              Color(0, 1, 0.5, 0.5));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceOver),
              Color(0.5, 1.3, 0.4, 0.6));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationOver),
              Color(0.25, 1.25, 0.5, 0.6));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceIn),
              Color(0.25, 0.25, 0, 0.1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationIn),
              Color(0, 0.2, 0.1, 0.1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceOut),
              Color(0.25, 0.25, 0, 0.1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationOut),
              Color(0, 0.8, 0.4, 0.4));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceATop),
              Color(0.25, 1.05, 0.4, 0.5));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationATop),
              Color(0.25, 0.45, 0.1, 0.2));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kXor),
              Color(0.25, 1.05, 0.4, 0.5));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kPlus),
              Color(0.5, 1, 0.5, 0.7));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kModulate),
              Color(0, 0.5, 0, 0.1));
  }

  {
    Color src = {0.5, 0.5, 0.2, 0.2};
    Color dst = {0.2, 1, 0.5, 0.5};
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kClear),
              Color(0, 0, 0, 0));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSource),
              Color(0.5, 0.5, 0.2, 0.2));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestination),
              Color(0.2, 1, 0.5, 0.5));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceOver),
              Color(0.66, 1.3, 0.6, 0.6));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationOver),
              Color(0.45, 1.25, 0.6, 0.6));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceIn),
              Color(0.25, 0.25, 0.1, 0.1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationIn),
              Color(0.04, 0.2, 0.1, 0.1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceOut),
              Color(0.25, 0.25, 0.1, 0.1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationOut),
              Color(0.16, 0.8, 0.4, 0.4));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceATop),
              Color(0.41, 1.05, 0.5, 0.5));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationATop),
              Color(0.29, 0.45, 0.2, 0.2));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kXor),
              Color(0.41, 1.05, 0.5, 0.5));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kPlus),
              Color(0.7, 1, 0.7, 0.7));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kModulate),
              Color(0.1, 0.5, 0.1, 0.1));
  }

  {
    Color src = {0.5, 0.5, 0.2, 0.2};
    Color dst = {0.2, 0.2, 0.5, 0.5};
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kClear),
              Color(0, 0, 0, 0));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSource),
              Color(0.5, 0.5, 0.2, 0.2));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestination),
              Color(0.2, 0.2, 0.5, 0.5));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceOver),
              Color(0.66, 0.66, 0.6, 0.6));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationOver),
              Color(0.45, 0.45, 0.6, 0.6));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceIn),
              Color(0.25, 0.25, 0.1, 0.1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationIn),
              Color(0.04, 0.04, 0.1, 0.1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceOut),
              Color(0.25, 0.25, 0.1, 0.1));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationOut),
              Color(0.16, 0.16, 0.4, 0.4));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kSourceATop),
              Color(0.41, 0.41, 0.5, 0.5));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kDestinationATop),
              Color(0.29, 0.29, 0.2, 0.2));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kXor),
              Color(0.41, 0.41, 0.5, 0.5));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kPlus),
              Color(0.7, 0.7, 0.7, 0.7));
    ASSERT_EQ(Color::BlendColor(src, dst, BlendMode::kModulate),
              Color(0.1, 0.1, 0.1, 0.1));
  }
}

TEST_P(EntityTest, SdfText) {
  auto callback = [&](ContentContext& context, RenderPass& pass) -> bool {
    SkFont font;
    font.setSize(30);
    auto blob = SkTextBlob::MakeFromString(
        "the quick brown fox jumped over the lazy dog (but with sdf).", font);
    auto frame = TextFrameFromTextBlob(blob);
    auto lazy_glyph_atlas = std::make_shared<LazyGlyphAtlas>();
    lazy_glyph_atlas->AddTextFrame(frame);

    EXPECT_FALSE(lazy_glyph_atlas->HasColor());

    auto text_contents = std::make_shared<TextContents>();
    text_contents->SetTextFrame(frame);
    text_contents->SetGlyphAtlas(std::move(lazy_glyph_atlas));
    text_contents->SetColor(Color(1.0, 0.0, 0.0, 1.0));
    Entity entity;
    entity.SetTransformation(
        Matrix::MakeTranslation(Vector3{200.0, 200.0, 0.0}) *
        Matrix::MakeScale(GetContentScale()));
    entity.SetContents(text_contents);

    // Force SDF rendering.
    return text_contents->RenderSdf(context, entity, pass);
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(EntityTest, AtlasContentsSubAtlas) {
  auto boston = CreateTextureForFixture("boston.jpg");

  {
    auto contents = std::make_shared<AtlasContents>();
    contents->SetBlendMode(BlendMode::kSourceOver);
    contents->SetTexture(boston);
    contents->SetColors({
        Color::Red(),
        Color::Red(),
        Color::Red(),
    });
    contents->SetTextureCoordinates({
        Rect::MakeLTRB(0, 0, 10, 10),
        Rect::MakeLTRB(0, 0, 10, 10),
        Rect::MakeLTRB(0, 0, 10, 10),
    });
    contents->SetTransforms({
        Matrix::MakeTranslation(Vector2(0, 0)),
        Matrix::MakeTranslation(Vector2(100, 100)),
        Matrix::MakeTranslation(Vector2(200, 200)),
    });

    // Since all colors and sample rects are the same, there should
    // only be a single entry in the sub atlas.
    auto subatlas = contents->GenerateSubAtlas();
    ASSERT_EQ(subatlas->sub_texture_coords.size(), 1u);
  }

  {
    auto contents = std::make_shared<AtlasContents>();
    contents->SetBlendMode(BlendMode::kSourceOver);
    contents->SetTexture(boston);
    contents->SetColors({
        Color::Red(),
        Color::Green(),
        Color::Blue(),
    });
    contents->SetTextureCoordinates({
        Rect::MakeLTRB(0, 0, 10, 10),
        Rect::MakeLTRB(0, 0, 10, 10),
        Rect::MakeLTRB(0, 0, 10, 10),
    });
    contents->SetTransforms({
        Matrix::MakeTranslation(Vector2(0, 0)),
        Matrix::MakeTranslation(Vector2(100, 100)),
        Matrix::MakeTranslation(Vector2(200, 200)),
    });

    // Since all colors are different, there are three entires.
    auto subatlas = contents->GenerateSubAtlas();
    ASSERT_EQ(subatlas->sub_texture_coords.size(), 3u);

    // The translations are kept but the sample rects point into
    // different parts of the sub atlas.
    ASSERT_EQ(subatlas->result_texture_coords[0], Rect::MakeXYWH(0, 0, 10, 10));
    ASSERT_EQ(subatlas->result_texture_coords[1],
              Rect::MakeXYWH(11, 0, 10, 10));
    ASSERT_EQ(subatlas->result_texture_coords[2],
              Rect::MakeXYWH(22, 0, 10, 10));
  }
}

static Vector3 RGBToYUV(Vector3 rgb, YUVColorSpace yuv_color_space) {
  Vector3 yuv;
  switch (yuv_color_space) {
    case YUVColorSpace::kBT601FullRange:
      yuv.x = rgb.x * 0.299 + rgb.y * 0.587 + rgb.z * 0.114;
      yuv.y = rgb.x * -0.169 + rgb.y * -0.331 + rgb.z * 0.5 + 0.5;
      yuv.z = rgb.x * 0.5 + rgb.y * -0.419 + rgb.z * -0.081 + 0.5;
      break;
    case YUVColorSpace::kBT601LimitedRange:
      yuv.x = rgb.x * 0.257 + rgb.y * 0.516 + rgb.z * 0.100 + 0.063;
      yuv.y = rgb.x * -0.145 + rgb.y * -0.291 + rgb.z * 0.439 + 0.5;
      yuv.z = rgb.x * 0.429 + rgb.y * -0.368 + rgb.z * -0.071 + 0.5;
      break;
  }
  return yuv;
}

static std::vector<std::shared_ptr<Texture>> CreateTestYUVTextures(
    Context* context,
    YUVColorSpace yuv_color_space) {
  Vector3 red = {244.0 / 255.0, 67.0 / 255.0, 54.0 / 255.0};
  Vector3 green = {76.0 / 255.0, 175.0 / 255.0, 80.0 / 255.0};
  Vector3 blue = {33.0 / 255.0, 150.0 / 255.0, 243.0 / 255.0};
  Vector3 white = {1.0, 1.0, 1.0};
  Vector3 red_yuv = RGBToYUV(red, yuv_color_space);
  Vector3 green_yuv = RGBToYUV(green, yuv_color_space);
  Vector3 blue_yuv = RGBToYUV(blue, yuv_color_space);
  Vector3 white_yuv = RGBToYUV(white, yuv_color_space);
  std::vector<Vector3> yuvs{red_yuv, green_yuv, blue_yuv, white_yuv};
  std::vector<uint8_t> y_data;
  std::vector<uint8_t> uv_data;
  for (int i = 0; i < 4; i++) {
    auto yuv = yuvs[i];
    uint8_t y = std::round(yuv.x * 255.0);
    uint8_t u = std::round(yuv.y * 255.0);
    uint8_t v = std::round(yuv.z * 255.0);
    for (int j = 0; j < 16; j++) {
      y_data.push_back(y);
    }
    for (int j = 0; j < 8; j++) {
      uv_data.push_back(j % 2 == 0 ? u : v);
    }
  }
  impeller::TextureDescriptor y_texture_descriptor;
  y_texture_descriptor.storage_mode = impeller::StorageMode::kHostVisible;
  y_texture_descriptor.format = PixelFormat::kR8UNormInt;
  y_texture_descriptor.size = {8, 8};
  auto y_texture =
      context->GetResourceAllocator()->CreateTexture(y_texture_descriptor);
  auto y_mapping = std::make_shared<fml::DataMapping>(y_data);
  if (!y_texture->SetContents(y_mapping)) {
    FML_DLOG(ERROR) << "Could not copy contents into Y texture.";
  }

  impeller::TextureDescriptor uv_texture_descriptor;
  uv_texture_descriptor.storage_mode = impeller::StorageMode::kHostVisible;
  uv_texture_descriptor.format = PixelFormat::kR8G8UNormInt;
  uv_texture_descriptor.size = {4, 4};
  auto uv_texture =
      context->GetResourceAllocator()->CreateTexture(uv_texture_descriptor);
  auto uv_mapping = std::make_shared<fml::DataMapping>(uv_data);
  if (!uv_texture->SetContents(uv_mapping)) {
    FML_DLOG(ERROR) << "Could not copy contents into UV texture.";
  }

  return {y_texture, uv_texture};
}

TEST_P(EntityTest, YUVToRGBFilter) {
  if (GetParam() == PlaygroundBackend::kOpenGLES) {
    // TODO(114588) : Support YUV to RGB filter on OpenGLES backend.
    GTEST_SKIP_("YUV to RGB filter is not supported on OpenGLES backend yet.");
  }

  auto callback = [&](ContentContext& context, RenderPass& pass) -> bool {
    YUVColorSpace yuv_color_space_array[2]{YUVColorSpace::kBT601FullRange,
                                           YUVColorSpace::kBT601LimitedRange};
    for (int i = 0; i < 2; i++) {
      auto yuv_color_space = yuv_color_space_array[i];
      auto textures =
          CreateTestYUVTextures(GetContext().get(), yuv_color_space);
      auto filter_contents = FilterContents::MakeYUVToRGBFilter(
          textures[0], textures[1], yuv_color_space);
      Entity filter_entity;
      filter_entity.SetContents(filter_contents);
      auto snapshot = filter_contents->RenderToSnapshot(context, filter_entity);

      Entity entity;
      auto contents = TextureContents::MakeRect(Rect::MakeLTRB(0, 0, 256, 256));
      contents->SetTexture(snapshot->texture);
      contents->SetSourceRect(Rect::MakeSize(snapshot->texture->GetSize()));
      entity.SetContents(contents);
      entity.SetTransformation(
          Matrix::MakeTranslation({static_cast<Scalar>(100 + 400 * i), 300}));
      entity.Render(context, pass);
    }
    return true;
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(EntityTest, RuntimeEffect) {
  if (GetParam() != PlaygroundBackend::kMetal) {
    GTEST_SKIP_("This backend doesn't support runtime effects.");
  }

  auto runtime_stage =
      OpenAssetAsRuntimeStage("runtime_stage_example.frag.iplr");
  ASSERT_TRUE(runtime_stage->IsDirty());

  bool first_frame = true;
  auto callback = [&](ContentContext& context, RenderPass& pass) -> bool {
    if (first_frame) {
      first_frame = false;
    } else {
      assert(runtime_stage->IsDirty() == false);
    }

    auto contents = std::make_shared<RuntimeEffectContents>();
    contents->SetGeometry(Geometry::MakeCover());

    contents->SetRuntimeStage(runtime_stage);

    struct FragUniforms {
      Vector2 iResolution;
      Scalar iTime;
    } frag_uniforms = {
        .iResolution = Vector2(GetWindowSize().width, GetWindowSize().height),
        .iTime = static_cast<Scalar>(GetSecondsElapsed()),
    };
    auto uniform_data = std::make_shared<std::vector<uint8_t>>();
    uniform_data->resize(sizeof(FragUniforms));
    memcpy(uniform_data->data(), &frag_uniforms, sizeof(FragUniforms));
    contents->SetUniformData(uniform_data);

    Entity entity;
    entity.SetContents(contents);
    return contents->Render(context, entity, pass);
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(EntityTest, InheritOpacityTest) {
  Entity entity;

  // Texture contents can always accept opacity.
  auto texture_contents = std::make_shared<TextureContents>();
  texture_contents->SetOpacity(0.5);
  ASSERT_TRUE(texture_contents->CanInheritOpacity(entity));

  texture_contents->SetInheritedOpacity(0.5);
  ASSERT_EQ(texture_contents->GetOpacity(), 0.25);
  texture_contents->SetInheritedOpacity(0.5);
  ASSERT_EQ(texture_contents->GetOpacity(), 0.25);

  // Solid color contents can accept opacity if their geometry
  // doesn't overlap.
  auto solid_color = std::make_shared<SolidColorContents>();
  solid_color->SetGeometry(
      Geometry::MakeRect(Rect::MakeLTRB(100, 100, 200, 200)));
  solid_color->SetColor(Color::Blue().WithAlpha(0.5));

  ASSERT_TRUE(solid_color->CanInheritOpacity(entity));

  solid_color->SetInheritedOpacity(0.5);
  ASSERT_EQ(solid_color->GetColor().alpha, 0.25);
  solid_color->SetInheritedOpacity(0.5);
  ASSERT_EQ(solid_color->GetColor().alpha, 0.25);

  // Color source contents can accept opacity if their geometry
  // doesn't overlap.
  auto tiled_texture = std::make_shared<TiledTextureContents>();
  tiled_texture->SetGeometry(
      Geometry::MakeRect(Rect::MakeLTRB(100, 100, 200, 200)));
  tiled_texture->SetOpacity(0.5);

  ASSERT_TRUE(tiled_texture->CanInheritOpacity(entity));

  tiled_texture->SetInheritedOpacity(0.5);
  ASSERT_EQ(tiled_texture->GetOpacity(), 0.25);
  tiled_texture->SetInheritedOpacity(0.5);
  ASSERT_EQ(tiled_texture->GetOpacity(), 0.25);

  // Text contents can accept opacity if the text frames do not
  // overlap
  SkFont font;
  font.setSize(30);
  auto blob = SkTextBlob::MakeFromString("A", font);
  auto frame = TextFrameFromTextBlob(blob);
  auto lazy_glyph_atlas = std::make_shared<LazyGlyphAtlas>();
  lazy_glyph_atlas->AddTextFrame(frame);

  auto text_contents = std::make_shared<TextContents>();
  text_contents->SetTextFrame(frame);
  text_contents->SetColor(Color::Blue().WithAlpha(0.5));

  ASSERT_TRUE(text_contents->CanInheritOpacity(entity));

  text_contents->SetInheritedOpacity(0.5);
  ASSERT_EQ(text_contents->GetColor().alpha, 0.25);
  text_contents->SetInheritedOpacity(0.5);
  ASSERT_EQ(text_contents->GetColor().alpha, 0.25);

  // Clips and restores trivially accept opacity.
  ASSERT_TRUE(ClipContents().CanInheritOpacity(entity));
  ASSERT_TRUE(ClipRestoreContents().CanInheritOpacity(entity));

  // Runtime effect contents can't accept opacity.
  auto runtime_effect = std::make_shared<RuntimeEffectContents>();
  ASSERT_FALSE(runtime_effect->CanInheritOpacity(entity));
}

}  // namespace testing
}  // namespace impeller
