// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <optional>

#include "gtest/gtest.h"

#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/solid_color_contents.h"
#include "impeller/entity/contents/test/contents_test_helpers.h"
#include "impeller/entity/contents/test/recording_render_pass.h"
#include "impeller/entity/contents/vertices_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/entity_playground.h"
#include "impeller/entity/vertices.frag.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/render_target.h"

namespace impeller {
namespace testing {

using EntityTest = EntityPlayground;

std::shared_ptr<VerticesGeometry> CreateColorVertices(
    const std::vector<Point>& vertices,
    const std::vector<Color>& colors) {
  auto bounds = Rect::MakePointBounds(vertices.begin(), vertices.end());
  std::vector<uint16_t> indices = {};
  indices.reserve(vertices.size());
  for (auto i = 0u; i < vertices.size(); i++) {
    indices.emplace_back(i);
  }
  std::vector<Point> texture_coordinates = {};

  return std::make_shared<VerticesGeometry>(
      vertices, indices, texture_coordinates, colors,
      bounds.value_or(Rect::MakeLTRB(0, 0, 0, 0)),
      VerticesGeometry::VertexMode::kTriangles);
}

// Verifies that the destination blend fast path still sets an alpha value.
TEST_P(EntityTest, RendersDstPerColorWithAlpha) {
  using FS = GeometryColorPipeline::FragmentShader;

  auto contents = std::make_shared<VerticesContents>();
  auto vertices = CreateColorVertices(
      {{0, 0}, {100, 0}, {0, 100}, {100, 0}, {0, 100}, {100, 100}},
      {Color::Red(), Color::Red(), Color::Red(), Color::Red(), Color::Red(),
       Color::Red()});
  auto src_contents = SolidColorContents::Make(
      PathBuilder{}.AddRect(Rect::MakeLTRB(0, 0, 100, 100)).TakePath(),
      Color::Red());

  contents->SetGeometry(vertices);
  contents->SetAlpha(0.5);
  contents->SetBlendMode(BlendMode::kDestination);
  contents->SetSourceContents(std::move(src_contents));

  auto content_context = GetContentContext();
  auto buffer = content_context->GetContext()->CreateCommandBuffer();
  auto render_target =
      GetContentContext()->GetRenderTargetCache()->CreateOffscreenMSAA(
          *content_context->GetContext(), {100, 100},
          /*mip_count=*/1);
  auto render_pass = buffer->CreateRenderPass(render_target);
  auto recording_pass = std::make_shared<RecordingRenderPass>(
      render_pass, GetContext(), render_target);
  Entity entity;

  ASSERT_TRUE(recording_pass->GetCommands().empty());
  ASSERT_TRUE(contents->Render(*content_context, entity, *recording_pass));

  ASSERT_TRUE(recording_pass->GetCommands().size() > 0);
  const auto& cmd = recording_pass->GetCommands()[0];
  auto* frag_uniforms = GetFragInfo<FS>(cmd);

  ASSERT_TRUE(frag_uniforms);
  ASSERT_EQ(frag_uniforms->alpha, 0.5);

  if (GetParam() == PlaygroundBackend::kMetal) {
    recording_pass->EncodeCommands();
  }
}

}  // namespace testing
}  // namespace impeller
