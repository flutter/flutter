// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "display_list/dl_sampling_options.h"
#include "display_list/dl_tile_mode.h"
#include "display_list/dl_vertices.h"
#include "flutter/impeller/aiks/aiks_unittests.h"

#include "flutter/display_list/dl_blend_mode.h"
#include "flutter/display_list/dl_builder.h"
#include "flutter/display_list/dl_color.h"
#include "flutter/display_list/dl_paint.h"
#include "flutter/testing/testing.h"
#include "impeller/display_list/dl_image_impeller.h"

namespace impeller {
namespace testing {

using namespace flutter;

namespace {
std::shared_ptr<DlVertices> MakeVertices(
    DlVertexMode mode,
    std::vector<SkPoint> vertices,
    std::vector<uint16_t> indices,
    std::vector<SkPoint> texture_coordinates,
    std::vector<DlColor> colors) {
  DlVertices::Builder::Flags flags(
      {{texture_coordinates.size() > 0, colors.size() > 0}});
  DlVertices::Builder builder(mode, vertices.size(), flags, indices.size());
  if (colors.size() > 0) {
    builder.store_colors(colors.data());
  }
  if (texture_coordinates.size() > 0) {
    builder.store_texture_coordinates(texture_coordinates.data());
  }
  if (indices.size() > 0) {
    builder.store_indices(indices.data());
  }
  builder.store_vertices(vertices.data());
  return builder.build();
}
};  // namespace

// Regression test for https://github.com/flutter/flutter/issues/135441 .
TEST_P(AiksTest, VerticesGeometryUVPositionData) {
  DisplayListBuilder builder;
  DlPaint paint;
  auto image =
      DlImageImpeller::Make(CreateTextureForFixture("table_mountain_nx.png"));
  auto size = image->impeller_texture()->GetSize();

  paint.setColorSource(std::make_shared<DlImageColorSource>(
      image, DlTileMode::kClamp, DlTileMode::kClamp));

  std::vector<SkPoint> vertex_coordinates = {SkPoint::Make(0, 0),
                                             SkPoint::Make(size.width, 0),
                                             SkPoint::Make(0, size.height)};
  auto vertices = MakeVertices(DlVertexMode::kTriangleStrip, vertex_coordinates,
                               {0, 1, 2}, {}, {});

  builder.DrawVertices(vertices, DlBlendMode::kSrcOver, paint);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

// Regression test for https://github.com/flutter/flutter/issues/135441 .
TEST_P(AiksTest, VerticesGeometryUVPositionDataWithTranslate) {
  DisplayListBuilder builder;
  DlPaint paint;
  auto image =
      DlImageImpeller::Make(CreateTextureForFixture("table_mountain_nx.png"));
  auto size = image->impeller_texture()->GetSize();

  SkMatrix matrix;
  matrix.setTranslateX(100);
  matrix.setTranslateY(100);
  paint.setColorSource(std::make_shared<DlImageColorSource>(
      image, DlTileMode::kClamp, DlTileMode::kClamp, DlImageSampling::kLinear,
      &matrix));

  std::vector<SkPoint> positions = {SkPoint::Make(0, 0),
                                    SkPoint::Make(size.width, 0),
                                    SkPoint::Make(0, size.height)};
  auto vertices =
      MakeVertices(DlVertexMode::kTriangleStrip, positions, {0, 1, 2}, {}, {});

  builder.DrawVertices(vertices, DlBlendMode::kSrcOver, paint);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

// Regression test for https://github.com/flutter/flutter/issues/145707
TEST_P(AiksTest, VerticesGeometryColorUVPositionData) {
  DisplayListBuilder builder;
  DlPaint paint;
  auto image =
      DlImageImpeller::Make(CreateTextureForFixture("table_mountain_nx.png"));
  auto size = image->impeller_texture()->GetSize();

  paint.setColorSource(std::make_shared<DlImageColorSource>(
      image, DlTileMode::kClamp, DlTileMode::kClamp));

  std::vector<SkPoint> positions = {
      SkPoint::Make(0, 0),           SkPoint::Make(size.width, 0),
      SkPoint::Make(0, size.height), SkPoint::Make(size.width, 0),
      SkPoint::Make(0, 0),           SkPoint::Make(size.width, size.height),
  };
  std::vector<DlColor> colors = {
      DlColor::kRed().withAlpha(128),   DlColor::kBlue().withAlpha(128),
      DlColor::kGreen().withAlpha(128), DlColor::kRed().withAlpha(128),
      DlColor::kBlue().withAlpha(128),  DlColor::kGreen().withAlpha(128),
  };

  auto vertices =
      MakeVertices(DlVertexMode::kTriangles, positions, {}, {}, colors);

  builder.DrawVertices(vertices, DlBlendMode::kDstOver, paint);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, VerticesGeometryColorUVPositionDataAdvancedBlend) {
  DisplayListBuilder builder;
  DlPaint paint;
  auto image =
      DlImageImpeller::Make(CreateTextureForFixture("table_mountain_nx.png"));
  auto size = image->impeller_texture()->GetSize();

  paint.setColorSource(std::make_shared<DlImageColorSource>(
      image, DlTileMode::kClamp, DlTileMode::kClamp));

  std::vector<SkPoint> positions = {
      SkPoint::Make(0, 0),           SkPoint::Make(size.width, 0),
      SkPoint::Make(0, size.height), SkPoint::Make(size.width, 0),
      SkPoint::Make(0, 0),           SkPoint::Make(size.width, size.height),
  };
  std::vector<DlColor> colors = {
      DlColor::kRed().modulateOpacity(0.5),
      DlColor::kBlue().modulateOpacity(0.5),
      DlColor::kGreen().modulateOpacity(0.5),
      DlColor::kRed().modulateOpacity(0.5),
      DlColor::kBlue().modulateOpacity(0.5),
      DlColor::kGreen().modulateOpacity(0.5),
  };

  auto vertices =
      MakeVertices(DlVertexMode::kTriangles, positions, {}, {}, colors);

  builder.DrawVertices(vertices, DlBlendMode::kColorBurn, paint);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

// Draw a hexagon using triangle fan
TEST_P(AiksTest, CanConvertTriangleFanToTriangles) {
  constexpr Scalar hexagon_radius = 125;
  auto hex_start = Point(200.0, -hexagon_radius + 200.0);
  auto center_to_flat = 1.73 / 2 * hexagon_radius;

  // clang-format off
  std::vector<SkPoint> vertices = {
    SkPoint::Make(hex_start.x, hex_start.y),
    SkPoint::Make(hex_start.x + center_to_flat, hex_start.y + 0.5 * hexagon_radius),
    SkPoint::Make(hex_start.x + center_to_flat, hex_start.y + 1.5 * hexagon_radius),
    SkPoint::Make(hex_start.x + center_to_flat, hex_start.y + 1.5 * hexagon_radius),
    SkPoint::Make(hex_start.x, hex_start.y + 2 * hexagon_radius),
    SkPoint::Make(hex_start.x, hex_start.y + 2 * hexagon_radius),
    SkPoint::Make(hex_start.x - center_to_flat, hex_start.y + 1.5 * hexagon_radius),
    SkPoint::Make(hex_start.x - center_to_flat, hex_start.y + 1.5 * hexagon_radius),
    SkPoint::Make(hex_start.x - center_to_flat, hex_start.y + 0.5 * hexagon_radius)
  };
  // clang-format on
  auto paint = flutter::DlPaint(flutter::DlColor::kDarkGrey());
  auto dl_vertices = flutter::DlVertices::Make(
      flutter::DlVertexMode::kTriangleFan, vertices.size(), vertices.data(),
      nullptr, nullptr);
  flutter::DisplayListBuilder builder;
  builder.DrawVertices(dl_vertices, flutter::DlBlendMode::kSrcOver, paint);
  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, DrawVerticesSolidColorTrianglesWithoutIndices) {
  // Use negative coordinates and then scale the transform by -1, -1 to make
  // sure coverage is taking the transform into account.
  std::vector<SkPoint> positions = {SkPoint::Make(-100, -300),
                                    SkPoint::Make(-200, -100),
                                    SkPoint::Make(-300, -300)};
  std::vector<flutter::DlColor> colors = {flutter::DlColor::kWhite(),
                                          flutter::DlColor::kGreen(),
                                          flutter::DlColor::kWhite()};

  auto vertices = flutter::DlVertices::Make(
      flutter::DlVertexMode::kTriangles, 3, positions.data(),
      /*texture_coordinates=*/nullptr, colors.data());

  flutter::DisplayListBuilder builder;
  flutter::DlPaint paint;

  paint.setColor(flutter::DlColor::kRed().modulateOpacity(0.5));
  builder.Scale(-1, -1);
  builder.DrawVertices(vertices, flutter::DlBlendMode::kSrcOver, paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, DrawVerticesLinearGradientWithoutIndices) {
  std::vector<SkPoint> positions = {SkPoint::Make(100, 300),
                                    SkPoint::Make(200, 100),
                                    SkPoint::Make(300, 300)};

  auto vertices = flutter::DlVertices::Make(
      flutter::DlVertexMode::kTriangles, 3, positions.data(),
      /*texture_coordinates=*/nullptr, /*colors=*/nullptr);

  std::vector<flutter::DlColor> colors = {flutter::DlColor::kBlue(),
                                          flutter::DlColor::kRed()};
  const float stops[2] = {0.0, 1.0};

  auto linear = flutter::DlColorSource::MakeLinear(
      {100.0, 100.0}, {300.0, 300.0}, 2, colors.data(), stops,
      flutter::DlTileMode::kRepeat);

  flutter::DisplayListBuilder builder;
  flutter::DlPaint paint;

  paint.setColorSource(linear);
  builder.DrawVertices(vertices, flutter::DlBlendMode::kSrcOver, paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, DrawVerticesLinearGradientWithTextureCoordinates) {
  std::vector<SkPoint> positions = {SkPoint::Make(100, 300),
                                    SkPoint::Make(200, 100),
                                    SkPoint::Make(300, 300)};
  std::vector<SkPoint> texture_coordinates = {SkPoint::Make(300, 100),
                                              SkPoint::Make(100, 200),
                                              SkPoint::Make(300, 300)};

  auto vertices = flutter::DlVertices::Make(
      flutter::DlVertexMode::kTriangles, 3, positions.data(),
      texture_coordinates.data(), /*colors=*/nullptr);

  std::vector<flutter::DlColor> colors = {flutter::DlColor::kBlue(),
                                          flutter::DlColor::kRed()};
  const float stops[2] = {0.0, 1.0};

  auto linear = flutter::DlColorSource::MakeLinear(
      {100.0, 100.0}, {300.0, 300.0}, 2, colors.data(), stops,
      flutter::DlTileMode::kRepeat);

  flutter::DisplayListBuilder builder;
  flutter::DlPaint paint;

  paint.setColorSource(linear);
  builder.DrawVertices(vertices, flutter::DlBlendMode::kSrcOver, paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, DrawVerticesImageSourceWithTextureCoordinates) {
  auto texture = CreateTextureForFixture("embarcadero.jpg");
  auto dl_image = DlImageImpeller::Make(texture);
  std::vector<SkPoint> positions = {SkPoint::Make(100, 300),
                                    SkPoint::Make(200, 100),
                                    SkPoint::Make(300, 300)};
  std::vector<SkPoint> texture_coordinates = {
      SkPoint::Make(0, 0), SkPoint::Make(100, 200), SkPoint::Make(200, 100)};

  auto vertices = flutter::DlVertices::Make(
      flutter::DlVertexMode::kTriangles, 3, positions.data(),
      texture_coordinates.data(), /*colors=*/nullptr);

  flutter::DisplayListBuilder builder;
  flutter::DlPaint paint;

  auto image_source = flutter::DlImageColorSource(
      dl_image, flutter::DlTileMode::kRepeat, flutter::DlTileMode::kRepeat);

  paint.setColorSource(&image_source);
  builder.DrawVertices(vertices, flutter::DlBlendMode::kSrcOver, paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest,
       DrawVerticesImageSourceWithTextureCoordinatesAndColorBlending) {
  auto texture = CreateTextureForFixture("embarcadero.jpg");
  auto dl_image = DlImageImpeller::Make(texture);
  std::vector<SkPoint> positions = {SkPoint::Make(100, 300),
                                    SkPoint::Make(200, 100),
                                    SkPoint::Make(300, 300)};
  std::vector<flutter::DlColor> colors = {flutter::DlColor::kWhite(),
                                          flutter::DlColor::kGreen(),
                                          flutter::DlColor::kWhite()};
  std::vector<SkPoint> texture_coordinates = {
      SkPoint::Make(0, 0), SkPoint::Make(100, 200), SkPoint::Make(200, 100)};

  auto vertices = flutter::DlVertices::Make(
      flutter::DlVertexMode::kTriangles, 3, positions.data(),
      texture_coordinates.data(), colors.data());

  flutter::DisplayListBuilder builder;
  flutter::DlPaint paint;

  auto image_source = flutter::DlImageColorSource(
      dl_image, flutter::DlTileMode::kRepeat, flutter::DlTileMode::kRepeat);

  paint.setColorSource(&image_source);
  builder.DrawVertices(vertices, flutter::DlBlendMode::kModulate, paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, DrawVerticesSolidColorTrianglesWithIndices) {
  std::vector<SkPoint> positions = {
      SkPoint::Make(100, 300), SkPoint::Make(200, 100), SkPoint::Make(300, 300),
      SkPoint::Make(200, 500)};
  std::vector<uint16_t> indices = {0, 1, 2, 0, 2, 3};

  auto vertices = flutter::DlVertices::Make(
      flutter::DlVertexMode::kTriangles, positions.size(), positions.data(),
      /*texture_coordinates=*/nullptr, /*colors=*/nullptr, indices.size(),
      indices.data());

  flutter::DisplayListBuilder builder;
  flutter::DlPaint paint;

  paint.setColor(flutter::DlColor::kRed());
  builder.DrawVertices(vertices, flutter::DlBlendMode::kSrcOver, paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

TEST_P(AiksTest, DrawVerticesPremultipliesColors) {
  std::vector<SkPoint> positions = {
      SkPoint::Make(100, 300), SkPoint::Make(200, 100), SkPoint::Make(300, 300),
      SkPoint::Make(200, 500)};
  auto color = flutter::DlColor::kBlue().withAlpha(0x99);
  std::vector<uint16_t> indices = {0, 1, 2, 0, 2, 3};
  std::vector<flutter::DlColor> colors = {color, color, color, color};

  auto vertices = flutter::DlVertices::Make(
      flutter::DlVertexMode::kTriangles, positions.size(), positions.data(),
      /*texture_coordinates=*/nullptr, colors.data(), indices.size(),
      indices.data());

  flutter::DisplayListBuilder builder;
  flutter::DlPaint paint;
  paint.setBlendMode(flutter::DlBlendMode::kSrcOver);
  paint.setColor(flutter::DlColor::kRed());

  builder.DrawRect(SkRect::MakeLTRB(0, 0, 400, 400), paint);
  builder.DrawVertices(vertices, flutter::DlBlendMode::kDst, paint);

  ASSERT_TRUE(OpenPlaygroundHere(builder.Build()));
}

}  // namespace testing
}  // namespace impeller
