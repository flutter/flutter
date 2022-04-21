// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <optional>
#include "impeller/geometry/path_builder.h"
#include "impeller/renderer/formats.h"
#include "impeller/renderer/vertex_buffer_builder.h"
#include "linear_gradient_contents.h"

#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/contents/solid_color_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/renderer/render_pass.h"

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
  return path_.GetTransformedBoundingBox(entity.GetTransformation());
};

bool ClipContents::Render(const ContentContext& renderer,
                          const Entity& entity,
                          RenderPass& pass) const {
  using VS = ClipPipeline::VertexShader;

  VS::FrameInfo info;
  // The color really doesn't matter.
  info.color = Color::SkyBlue();

  Command cmd;
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
      VS::BindFrameInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(info));

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
  cmd.BindVertices(SolidColorContents::CreateSolidFillVertices(
      path_, pass.GetTransientsBuffer()));

  info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize()) *
             entity.GetTransformation();
  VS::BindFrameInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(info));

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

bool ClipRestoreContents::Render(const ContentContext& renderer,
                                 const Entity& entity,
                                 RenderPass& pass) const {
  using VS = ClipPipeline::VertexShader;

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

  VS::FrameInfo info;
  // The color really doesn't matter.
  info.color = Color::SkyBlue();
  info.mvp = Matrix::MakeOrthographic(pass.GetRenderTargetSize());

  VS::BindFrameInfo(cmd, pass.GetTransientsBuffer().EmplaceUniform(info));

  pass.AddCommand(std::move(cmd));
  return true;
}

};  // namespace impeller
