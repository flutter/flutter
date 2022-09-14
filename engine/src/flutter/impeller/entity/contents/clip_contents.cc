// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <optional>

#include "fml/logging.h"
#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/solid_fill_utils.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/vertex_buffer_builder.h"

namespace impeller {

/*******************************************************************************
 ******* ClipContents
 ******************************************************************************/

ClipContents::ClipContents() = default;

ClipContents::~ClipContents() = default;

void ClipContents::SetPath(Path path) {
  path_ = std::move(path);
}

void ClipContents::SetClipOperation(Entity::ClipOperation clip_op) {
  clip_op_ = clip_op;
}

std::optional<Rect> ClipContents::GetCoverage(const Entity& entity) const {
  return std::nullopt;
};

Contents::StencilCoverage ClipContents::GetStencilCoverage(
    const Entity& entity,
    const std::optional<Rect>& current_stencil_coverage) const {
  if (!current_stencil_coverage.has_value()) {
    return {.type = StencilCoverage::Type::kAppend, .coverage = std::nullopt};
  }
  switch (clip_op_) {
    case Entity::ClipOperation::kDifference:
      // This can be optimized further by considering cases when the bounds of
      // the current stencil will shrink.
      return {.type = StencilCoverage::Type::kAppend,
              .coverage = current_stencil_coverage};
    case Entity::ClipOperation::kIntersect:
      return {
          .type = StencilCoverage::Type::kAppend,
          .coverage = current_stencil_coverage->Intersection(
              path_.GetTransformedBoundingBox(entity.GetTransformation())
                  .value()),
      };
  }
  FML_UNREACHABLE();
}

bool ClipContents::ShouldRender(
    const Entity& entity,
    const std::optional<Rect>& stencil_coverage) const {
  return true;
}

bool ClipContents::Render(const ContentContext& renderer,
                          const Entity& entity,
                          RenderPass& pass) const {
  using VS = ClipPipeline::VertexShader;
  using FS = ClipPipeline::FragmentShader;

  VS::VertInfo info;

  Command cmd;

  FS::FragInfo frag_info;
  // The color really doesn't matter.
  frag_info.color = Color::SkyBlue();
  FS::BindFragInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frag_info));

  auto options = OptionsFromPassAndEntity(pass, entity);
  cmd.stencil_reference = entity.GetStencilDepth();
  options.stencil_compare = CompareFunction::kEqual;
  options.stencil_operation = StencilOperation::kIncrementClamp;

  if (clip_op_ == Entity::ClipOperation::kDifference) {
    {
      cmd.label = "Difference Clip (Increment)";

      cmd.primitive_type = PrimitiveType::kTriangleStrip;
      auto points = Rect(Size(pass.GetRenderTargetSize())).GetPoints();
      auto vertices =
          VertexBufferBuilder<VS::PerVertexData>{}
              .AddVertices({{points[0]}, {points[1]}, {points[2]}, {points[3]}})
              .CreateVertexBuffer(pass.GetTransientsBuffer());
      cmd.BindVertices(std::move(vertices));

      info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize());
      VS::BindVertInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(info));

      cmd.pipeline = renderer.GetClipPipeline(options);
      pass.AddCommand(cmd);
    }

    {
      cmd.label = "Difference Clip (Punch)";

      cmd.primitive_type = PrimitiveType::kTriangle;
      cmd.stencil_reference = entity.GetStencilDepth() + 1;
      options.stencil_compare = CompareFunction::kEqual;
      options.stencil_operation = StencilOperation::kDecrementClamp;
    }
  } else {
    cmd.label = "Intersect Clip";
    options.stencil_compare = CompareFunction::kEqual;
    options.stencil_operation = StencilOperation::kIncrementClamp;
  }

  cmd.pipeline = renderer.GetClipPipeline(options);
  cmd.BindVertices(CreateSolidFillVertices<VS::PerVertexData>(
      path_, pass.GetTransientsBuffer()));

  info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
             entity.GetTransformation();
  VS::BindVertInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(info));

  pass.AddCommand(std::move(cmd));
  return true;
}

/*******************************************************************************
 ******* ClipRestoreContents
 ******************************************************************************/

ClipRestoreContents::ClipRestoreContents() = default;

ClipRestoreContents::~ClipRestoreContents() = default;

std::optional<Rect> ClipRestoreContents::GetCoverage(
    const Entity& entity) const {
  return std::nullopt;
};

Contents::StencilCoverage ClipRestoreContents::GetStencilCoverage(
    const Entity& entity,
    const std::optional<Rect>& current_stencil_coverage) const {
  return {.type = StencilCoverage::Type::kRestore, .coverage = std::nullopt};
}

bool ClipRestoreContents::ShouldRender(
    const Entity& entity,
    const std::optional<Rect>& stencil_coverage) const {
  return true;
}

bool ClipRestoreContents::Render(const ContentContext& renderer,
                                 const Entity& entity,
                                 RenderPass& pass) const {
  using VS = ClipPipeline::VertexShader;
  using FS = ClipPipeline::FragmentShader;

  Command cmd;
  cmd.label = "Restore Clip";
  auto options = OptionsFromPassAndEntity(pass, entity);
  options.stencil_compare = CompareFunction::kLess;
  options.stencil_operation = StencilOperation::kSetToReferenceValue;
  cmd.pipeline = renderer.GetClipPipeline(options);
  cmd.stencil_reference = entity.GetStencilDepth();

  // Create a rect that covers the whole render target.
  auto size = pass.GetRenderTargetSize();
  VertexBufferBuilder<VS::PerVertexData> vtx_builder;
  vtx_builder.AddVertices({
      {Point(0.0, 0.0)},
      {Point(size.width, 0.0)},
      {Point(size.width, size.height)},
      {Point(0.0, 0.0)},
      {Point(size.width, size.height)},
      {Point(0.0, size.height)},
  });
  cmd.BindVertices(vtx_builder.CreateVertexBuffer(pass.GetTransientsBuffer()));

  VS::VertInfo info;
  info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize());
  VS::BindVertInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(info));

  FS::FragInfo frag_info;
  // The color really doesn't matter.
  frag_info.color = Color::SkyBlue();
  FS::BindFragInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(frag_info));

  pass.AddCommand(std::move(cmd));
  return true;
}

};  // namespace impeller
