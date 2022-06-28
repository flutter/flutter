// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <optional>

#include "flutter/testing/testing.h"
#include "impeller/entity/contents/filters/blend_filter_contents.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/filters/inputs/filter_input.h"
#include "impeller/entity/contents/solid_color_contents.h"
#include "impeller/entity/contents/solid_stroke_contents.h"
#include "impeller/entity/contents/texture_contents.h"
#include "impeller/entity/contents/vertices_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/entity_pass.h"
#include "impeller/entity/entity_pass_delegate.h"
#include "impeller/entity/entity_playground.h"
#include "impeller/geometry/geometry_unittests.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/playground/playground.h"
#include "impeller/playground/widgets.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/vertex_buffer_builder.h"
#include "impeller/tessellator/tessellator.h"
#include "third_party/imgui/imgui.h"

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
  explicit TestPassDelegate(std::optional<Rect> coverage)
      : coverage_(coverage) {}

  // |EntityPassDelegate|
  ~TestPassDelegate() override = default;

  // |EntityPassDelegate|
  std::optional<Rect> GetCoverageRect() override { return coverage_; }

  // |EntityPassDelgate|
  bool CanElide() override { return false; }

  // |EntityPassDelgate|
  bool CanCollapseIntoParentPass() override { return false; }

  // |EntityPassDelgate|
  std::shared_ptr<Contents> CreateContentsForSubpassTarget(
      std::shared_ptr<Texture> target) override {
    return nullptr;
  }

 private:
  const std::optional<Rect> coverage_;
};

auto CreatePassWithRectPath(Rect rect, std::optional<Rect> bounds_hint) {
  auto subpass = std::make_unique<EntityPass>();
  Entity entity;
  entity.SetContents(SolidColorContents::Make(
      PathBuilder{}.AddRect(rect).TakePath(), Color::Red()));
  subpass->AddEntity(entity);
  subpass->SetDelegate(std::make_unique<TestPassDelegate>(bounds_hint));
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
  auto filter = FilterContents::MakeBlend(Entity::BlendMode::kSoftLight,
                                          FilterInput::Make({image}));

  // Without the crop rect (default behavior).
  {
    auto actual = filter->GetCoverage({});
    auto expected = Rect::MakeSize(Size(image->GetSize()));

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
  Entity entity;
  entity.SetTransformation(Matrix::MakeScale(GetContentScale()));
  entity.SetContents(SolidColorContents::Make(
      PathBuilder{}.AddRect({100, 100, 100, 100}).TakePath(), Color::Red()));
  ASSERT_TRUE(OpenPlaygroundHere(entity));
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
  auto contents = std::make_unique<SolidStrokeContents>();
  contents->SetPath(std::move(path));
  contents->SetColor(Color::Red());
  contents->SetStrokeSize(5.0);
  entity.SetContents(std::move(contents));
  ASSERT_TRUE(OpenPlaygroundHere(entity));
}

TEST_P(EntityTest, TriangleInsideASquare) {
  auto callback = [&](ContentContext& context, RenderPass& pass) {
    Point a = IMPELLER_PLAYGROUND_POINT(Point(10, 10), 20, Color::White());
    Point b = IMPELLER_PLAYGROUND_POINT(Point(210, 10), 20, Color::White());
    Point c = IMPELLER_PLAYGROUND_POINT(Point(210, 210), 20, Color::White());
    Point d = IMPELLER_PLAYGROUND_POINT(Point(10, 210), 20, Color::White());
    Point e = IMPELLER_PLAYGROUND_POINT(Point(50, 50), 20, Color::White());
    Point f = IMPELLER_PLAYGROUND_POINT(Point(100, 50), 20, Color::White());
    Point g = IMPELLER_PLAYGROUND_POINT(Point(50, 150), 20, Color::White());
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
    auto contents = std::make_unique<SolidStrokeContents>();
    contents->SetPath(std::move(path));
    contents->SetColor(Color::Red());
    contents->SetStrokeSize(20.0);
    entity.SetContents(std::move(contents));

    return entity.Render(context, pass);
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(EntityTest, StrokeCapAndJoinTest) {
  const Point padding(300, 250);
  const Point margin(140, 180);

  bool first_frame = true;
  auto callback = [&](ContentContext& context, RenderPass& pass) {
    if (first_frame) {
      first_frame = false;
      ImGui::SetNextWindowSize({300, 100});
      ImGui::SetNextWindowPos(
          {0 * padding.x + margin.x, 1.7f * padding.y + margin.y});
    }

    // Slightly above sqrt(2) by default, so that right angles are just below
    // the limit and acute angles are over the limit (causing them to get
    // beveled).
    static Scalar miter_limit = 1.41421357;
    static Scalar width = 30;

    ImGui::Begin("Controls");
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
                           Path path, SolidStrokeContents::Cap cap,
                           SolidStrokeContents::Join join) {
      auto contents = std::make_unique<SolidStrokeContents>();
      contents->SetPath(path);
      contents->SetColor(Color::Red());
      contents->SetStrokeSize(width);
      contents->SetStrokeCap(cap);
      contents->SetStrokeJoin(join);
      contents->SetStrokeMiter(miter_limit);

      Entity entity;
      entity.SetTransformation(world_matrix);
      entity.SetContents(std::move(contents));

      auto coverage = entity.GetCoverage();
      if (coverage.has_value()) {
        auto bounds_contents = std::make_unique<SolidColorContents>();
        bounds_contents->SetPath(
            PathBuilder{}.AddRect(entity.GetCoverage().value()).TakePath());
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
                  SolidStrokeContents::Cap::kButt,
                  SolidStrokeContents::Join::kBevel);
    }

    // Cap::kSquare demo.
    {
      Point off = Point(1, 0) * padding + margin;
      auto [a, b] = IMPELLER_PLAYGROUND_LINE(off + a_def, off + b_def, r,
                                             Color::Black(), Color::White());
      auto [c, d] = IMPELLER_PLAYGROUND_LINE(off + c_def, off + d_def, r,
                                             Color::Black(), Color::White());
      render_path(PathBuilder{}.AddCubicCurve(a, b, d, c).TakePath(),
                  SolidStrokeContents::Cap::kSquare,
                  SolidStrokeContents::Join::kBevel);
    }

    // Cap::kRound demo.
    {
      Point off = Point(2, 0) * padding + margin;
      auto [a, b] = IMPELLER_PLAYGROUND_LINE(off + a_def, off + b_def, r,
                                             Color::Black(), Color::White());
      auto [c, d] = IMPELLER_PLAYGROUND_LINE(off + c_def, off + d_def, r,
                                             Color::Black(), Color::White());
      render_path(PathBuilder{}.AddCubicCurve(a, b, d, c).TakePath(),
                  SolidStrokeContents::Cap::kRound,
                  SolidStrokeContents::Join::kBevel);
    }

    // Join::kBevel demo.
    {
      Point off = Point(0, 1) * padding + margin;
      Point a = IMPELLER_PLAYGROUND_POINT(off + a_def, r, Color::White());
      Point b = IMPELLER_PLAYGROUND_POINT(off + e_def, r, Color::White());
      Point c = IMPELLER_PLAYGROUND_POINT(off + c_def, r, Color::White());
      render_path(
          PathBuilder{}.MoveTo(a).LineTo(b).LineTo(c).Close().TakePath(),
          SolidStrokeContents::Cap::kButt, SolidStrokeContents::Join::kBevel);
    }

    // Join::kMiter demo.
    {
      Point off = Point(1, 1) * padding + margin;
      Point a = IMPELLER_PLAYGROUND_POINT(off + a_def, r, Color::White());
      Point b = IMPELLER_PLAYGROUND_POINT(off + e_def, r, Color::White());
      Point c = IMPELLER_PLAYGROUND_POINT(off + c_def, r, Color::White());
      render_path(
          PathBuilder{}.MoveTo(a).LineTo(b).LineTo(c).Close().TakePath(),
          SolidStrokeContents::Cap::kButt, SolidStrokeContents::Join::kMiter);
    }

    // Join::kRound demo.
    {
      Point off = Point(2, 1) * padding + margin;
      Point a = IMPELLER_PLAYGROUND_POINT(off + a_def, r, Color::White());
      Point b = IMPELLER_PLAYGROUND_POINT(off + e_def, r, Color::White());
      Point c = IMPELLER_PLAYGROUND_POINT(off + c_def, r, Color::White());
      render_path(
          PathBuilder{}.MoveTo(a).LineTo(b).LineTo(c).Close().TakePath(),
          SolidStrokeContents::Cap::kButt, SolidStrokeContents::Join::kRound);
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

TEST_P(EntityTest, SolidStrokeContentsSetStrokeCapsAndJoins) {
  {
    SolidStrokeContents stroke;
    // Defaults.
    ASSERT_EQ(stroke.GetStrokeCap(), SolidStrokeContents::Cap::kButt);
    ASSERT_EQ(stroke.GetStrokeJoin(), SolidStrokeContents::Join::kMiter);
  }

  {
    SolidStrokeContents stroke;
    stroke.SetStrokeCap(SolidStrokeContents::Cap::kSquare);
    ASSERT_EQ(stroke.GetStrokeCap(), SolidStrokeContents::Cap::kSquare);
  }

  {
    SolidStrokeContents stroke;
    stroke.SetStrokeCap(SolidStrokeContents::Cap::kRound);
    ASSERT_EQ(stroke.GetStrokeCap(), SolidStrokeContents::Cap::kRound);
  }
}

TEST_P(EntityTest, SolidStrokeContentsSetMiter) {
  SolidStrokeContents contents;
  ASSERT_FLOAT_EQ(contents.GetStrokeMiter(), 4);

  contents.SetStrokeMiter(8);
  ASSERT_FLOAT_EQ(contents.GetStrokeMiter(), 8);

  contents.SetStrokeMiter(-1);
  ASSERT_FLOAT_EQ(contents.GetStrokeMiter(), 8);
}

TEST_P(EntityTest, BlendingModeOptions) {
  std::vector<const char*> blend_mode_names;
  std::vector<Entity::BlendMode> blend_mode_values;
  {
    // Force an exhausiveness check with a switch. When adding blend modes,
    // update this switch with a new name/value to to make it selectable in the
    // test GUI.

    const Entity::BlendMode b{};
    static_assert(b == Entity::BlendMode::kClear);  // Ensure the first item in
                                                    // the switch is the first
                                                    // item in the enum.
    switch (b) {
      case Entity::BlendMode::kClear:
        blend_mode_names.push_back("Clear");
        blend_mode_values.push_back(Entity::BlendMode::kClear);
      case Entity::BlendMode::kSource:
        blend_mode_names.push_back("Source");
        blend_mode_values.push_back(Entity::BlendMode::kSource);
      case Entity::BlendMode::kDestination:
        blend_mode_names.push_back("Destination");
        blend_mode_values.push_back(Entity::BlendMode::kDestination);
      case Entity::BlendMode::kSourceOver:
        blend_mode_names.push_back("SourceOver");
        blend_mode_values.push_back(Entity::BlendMode::kSourceOver);
      case Entity::BlendMode::kDestinationOver:
        blend_mode_names.push_back("DestinationOver");
        blend_mode_values.push_back(Entity::BlendMode::kDestinationOver);
      case Entity::BlendMode::kSourceIn:
        blend_mode_names.push_back("SourceIn");
        blend_mode_values.push_back(Entity::BlendMode::kSourceIn);
      case Entity::BlendMode::kDestinationIn:
        blend_mode_names.push_back("DestinationIn");
        blend_mode_values.push_back(Entity::BlendMode::kDestinationIn);
      case Entity::BlendMode::kSourceOut:
        blend_mode_names.push_back("SourceOut");
        blend_mode_values.push_back(Entity::BlendMode::kSourceOut);
      case Entity::BlendMode::kDestinationOut:
        blend_mode_names.push_back("DestinationOut");
        blend_mode_values.push_back(Entity::BlendMode::kDestinationOut);
      case Entity::BlendMode::kSourceATop:
        blend_mode_names.push_back("SourceATop");
        blend_mode_values.push_back(Entity::BlendMode::kSourceATop);
      case Entity::BlendMode::kDestinationATop:
        blend_mode_names.push_back("DestinationATop");
        blend_mode_values.push_back(Entity::BlendMode::kDestinationATop);
      case Entity::BlendMode::kXor:
        blend_mode_names.push_back("Xor");
        blend_mode_values.push_back(Entity::BlendMode::kXor);
      case Entity::BlendMode::kPlus:
        blend_mode_names.push_back("Plus");
        blend_mode_values.push_back(Entity::BlendMode::kPlus);
      case Entity::BlendMode::kModulate:
        blend_mode_names.push_back("Modulate");
        blend_mode_values.push_back(Entity::BlendMode::kModulate);
    };
  }

  bool first_frame = true;
  auto callback = [&](ContentContext& context, RenderPass& pass) {
    if (first_frame) {
      first_frame = false;
      ImGui::SetNextWindowSize({350, 200});
      ImGui::SetNextWindowPos({200, 450});
    }

    auto world_matrix = Matrix::MakeScale(GetContentScale());
    auto draw_rect = [&context, &pass, &world_matrix](
                         Rect rect, Color color,
                         Entity::BlendMode blend_mode) -> bool {
      using VS = SolidFillPipeline::VertexShader;
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
      cmd.pipeline = context.GetSolidFillPipeline(options);
      cmd.BindVertices(
          vtx_builder.CreateVertexBuffer(pass.GetTransientsBuffer()));

      VS::FrameInfo frame_info;
      frame_info.mvp =
          Matrix::MakeOrthographic(pass.GetRenderTargetSize()) * world_matrix;
      frame_info.color = color.Premultiply();
      VS::BindFrameInfo(cmd,
                        pass.GetTransientsBuffer().EmplaceUniform(frame_info));

      cmd.primitive_type = PrimitiveType::kTriangle;

      return pass.AddCommand(std::move(cmd));
    };

    ImGui::Begin("Controls");
    static Color color1(1, 0, 0, 0.5), color2(0, 1, 0, 0.5);
    ImGui::ColorEdit4("Color 1", reinterpret_cast<float*>(&color1));
    ImGui::ColorEdit4("Color 2", reinterpret_cast<float*>(&color2));
    static int current_blend_index = 3;
    ImGui::ListBox("Blending mode", &current_blend_index,
                   blend_mode_names.data(), blend_mode_names.size());
    ImGui::End();

    Entity::BlendMode selected_mode = blend_mode_values[current_blend_index];

    Point a, b, c, d;
    std::tie(a, b) = IMPELLER_PLAYGROUND_LINE(
        Point(400, 100), Point(200, 300), 20, Color::White(), Color::White());
    std::tie(c, d) = IMPELLER_PLAYGROUND_LINE(
        Point(470, 190), Point(270, 390), 20, Color::White(), Color::White());

    bool result = true;
    result = result && draw_rect(Rect(0, 0, pass.GetRenderTargetSize().width,
                                      pass.GetRenderTargetSize().height),
                                 Color(), Entity::BlendMode::kClear);
    result = result && draw_rect(Rect::MakeLTRB(a.x, a.y, b.x, b.y), color1,
                                 Entity::BlendMode::kSourceOver);
    result = result && draw_rect(Rect::MakeLTRB(c.x, c.y, d.x, d.y), color2,
                                 selected_mode);
    return result;
  };
  ASSERT_TRUE(OpenPlaygroundHere(callback));
}

TEST_P(EntityTest, BezierCircleScaled) {
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
      Matrix::MakeScale({20.0, 20.0, 1.0}).Translate({-80, -15, 0}));
  entity.SetContents(SolidColorContents::Make(path, Color::Red()));
  ASSERT_TRUE(OpenPlaygroundHere(entity));
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

    auto blend0 = FilterContents::MakeBlend(Entity::BlendMode::kModulate,
                                            {fi_kalimba, fi_boston});

    auto blend1 = FilterContents::MakeBlend(
        Entity::BlendMode::kScreen,
        {fi_bridge, FilterInput::Make(blend0), fi_bridge, fi_bridge});

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

  bool first_frame = true;
  auto callback = [&](ContentContext& context, RenderPass& pass) -> bool {
    if (first_frame) {
      first_frame = false;
      ImGui::SetNextWindowSize({500, 290});
      ImGui::SetNextWindowPos({300, 480});
    }

    const char* input_type_names[] = {"Texture", "Solid Color"};
    const char* blur_type_names[] = {"Image blur", "Mask blur"};
    const char* blur_style_names[] = {"Normal", "Solid", "Outer", "Inner"};
    const FilterContents::BlurStyle blur_styles[] = {
        FilterContents::BlurStyle::kNormal, FilterContents::BlurStyle::kSolid,
        FilterContents::BlurStyle::kOuter, FilterContents::BlurStyle::kInner};

    // UI state.
    static int selected_input_type = 0;
    static Color input_color = Color::Black();
    static int selected_blur_type = 0;
    static float blur_amount[2] = {20, 20};
    static int selected_blur_style = 0;
    static Color cover_color(1, 0, 0, 0.2);
    static Color bounds_color(0, 1, 0, 0.1);
    static float offset[2] = {500, 400};
    static float rotation = 0;
    static float scale[2] = {0.75, 0.75};
    static float skew[2] = {0, 0};

    ImGui::Begin("Controls");
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
      ImGui::SliderFloat2("Blur", &blur_amount[0], 0, 200);
      ImGui::Combo("Blur style", &selected_blur_style, blur_style_names,
                   sizeof(blur_style_names) / sizeof(char*));
      ImGui::ColorEdit4("Cover color", reinterpret_cast<float*>(&cover_color));
      ImGui::ColorEdit4("Bounds color",
                        reinterpret_cast<float*>(&bounds_color));
      ImGui::SliderFloat2("Translation", &offset[0], 0,
                          pass.GetRenderTargetSize().width);
      ImGui::SliderFloat("Rotation", &rotation, 0, kPi * 2);
      ImGui::SliderFloat2("Scale", &scale[0], 0, 3);
      ImGui::SliderFloat2("Skew", &skew[0], -3, 3);
    }
    ImGui::End();

    std::shared_ptr<Contents> input;
    Size input_size;

    if (selected_input_type == 0) {
      auto texture = std::make_shared<TextureContents>();
      auto input_rect = Rect::MakeSize(Size(boston->GetSize()));
      texture->SetSourceRect(input_rect);
      texture->SetPath(PathBuilder{}.AddRect(input_rect).TakePath());
      texture->SetTexture(boston);
      texture->SetOpacity(input_color.alpha);

      input = texture;
      input_size = input_rect.size;
    } else {
      auto fill = std::make_shared<SolidColorContents>();
      auto input_rect = Rect::MakeSize(Size(boston->GetSize()));
      fill->SetColor(input_color);
      fill->SetPath(PathBuilder{}.AddRect(input_rect).TakePath());

      input = fill;
      input_size = input_rect.size;
    }

    auto blur = FilterContents::MakeGaussianBlur(
        FilterInput::Make(input), FilterContents::Sigma{blur_amount[0]},
        FilterContents::Sigma{blur_amount[1]},
        blur_styles[selected_blur_style]);

    auto mask_blur = FilterContents::MakeBorderMaskBlur(
        FilterInput::Make(input), FilterContents::Sigma{blur_amount[0]},
        FilterContents::Sigma{blur_amount[1]},
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
        PathBuilder{}.AddRect(Rect::MakeSize(Size(input_size))).TakePath(),
        cover_color));
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

TEST_P(EntityTest, SetBlendMode) {
  Entity entity;
  ASSERT_EQ(entity.GetBlendMode(), Entity::BlendMode::kSourceOver);
  entity.SetBlendMode(Entity::BlendMode::kClear);
  ASSERT_EQ(entity.GetBlendMode(), Entity::BlendMode::kClear);
}

TEST_P(EntityTest, ContentsGetBoundsForEmptyPathReturnsNullopt) {
  Entity entity;
  entity.SetContents(std::make_shared<SolidColorContents>());
  ASSERT_FALSE(entity.GetCoverage().has_value());
}

TEST_P(EntityTest, SolidStrokeCoverageIsCorrect) {
  {
    Entity entity;
    auto contents = std::make_unique<SolidStrokeContents>();
    contents->SetPath(PathBuilder{}.AddLine({0, 0}, {10, 10}).TakePath());
    contents->SetStrokeCap(SolidStrokeContents::Cap::kButt);
    contents->SetStrokeJoin(SolidStrokeContents::Join::kBevel);
    contents->SetStrokeSize(4);
    contents->SetColor(Color::Black());
    entity.SetContents(std::move(contents));
    auto actual = entity.GetCoverage();
    auto expected = Rect::MakeLTRB(-2, -2, 12, 12);
    ASSERT_TRUE(actual.has_value());
    ASSERT_RECT_NEAR(actual.value(), expected);
  }

  // Cover the Cap::kSquare case.
  {
    Entity entity;
    auto contents = std::make_unique<SolidStrokeContents>();
    contents->SetPath(PathBuilder{}.AddLine({0, 0}, {10, 10}).TakePath());
    contents->SetStrokeCap(SolidStrokeContents::Cap::kSquare);
    contents->SetStrokeJoin(SolidStrokeContents::Join::kBevel);
    contents->SetStrokeSize(4);
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
    Entity entity;
    auto contents = std::make_unique<SolidStrokeContents>();
    contents->SetPath(PathBuilder{}.AddLine({0, 0}, {10, 10}).TakePath());
    contents->SetStrokeCap(SolidStrokeContents::Cap::kSquare);
    contents->SetStrokeJoin(SolidStrokeContents::Join::kMiter);
    contents->SetStrokeSize(4);
    contents->SetStrokeMiter(2);
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
  fill->SetPath(
      PathBuilder{}.AddRect(Rect::MakeXYWH(0, 0, 300, 400)).TakePath());
  fill->SetColor(Color::CornflowerBlue());
  auto border_mask_blur = FilterContents::MakeBorderMaskBlur(
      FilterInput::Make(fill), FilterContents::Radius{3},
      FilterContents::Radius{4});

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

TEST_P(EntityTest, DrawVerticesSolidColorTrianglesWithoutIndex) {
  std::vector<Point> points = {Point(0, 0), Point(0, 1), Point(1, 0)};
  std::vector<uint16_t> indexes;
  std::vector<Color> colors = {Color::White(), Color::White(), Color::White()};

  Vertices vertices = Vertices(points, indexes, colors, VertexMode::kTriangle,
                               Rect(0, 0, 4, 4));

  std::shared_ptr<VerticesContents> contents =
      std::make_shared<VerticesContents>(vertices);
  contents->SetColor(Color::White());
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
    fill->SetPath(PathBuilder{}.AddRect(expected).TakePath());

    auto coverage = fill->GetCoverage({});
    ASSERT_TRUE(coverage.has_value());
    ASSERT_RECT_NEAR(coverage.value(), expected);
  }

  // Entity transform
  {
    auto fill = std::make_shared<SolidColorContents>();
    fill->SetColor(Color::CornflowerBlue());
    fill->SetPath(
        PathBuilder{}.AddRect(Rect::MakeLTRB(100, 110, 200, 220)).TakePath());

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
    fill->SetPath(
        PathBuilder{}.AddRect(Rect::MakeLTRB(100, 110, 200, 220)).TakePath());

    auto coverage = fill->GetCoverage({});
    ASSERT_FALSE(coverage.has_value());
  }
}

}  // namespace testing
}  // namespace impeller
