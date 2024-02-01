// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <optional>

#include "fml/logging.h"
#include "impeller/core/formats.h"
#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/vertex_buffer_builder.h"

namespace impeller {

/*******************************************************************************
 ******* ClipContents
 ******************************************************************************/

ClipContents::ClipContents() = default;

ClipContents::~ClipContents() = default;

void ClipContents::SetGeometry(const std::shared_ptr<Geometry>& geometry) {
  geometry_ = geometry;
}

void ClipContents::SetClipOperation(Entity::ClipOperation clip_op) {
  clip_op_ = clip_op;
}

std::optional<Rect> ClipContents::GetCoverage(const Entity& entity) const {
  return std::nullopt;
};

Contents::ClipCoverage ClipContents::GetClipCoverage(
    const Entity& entity,
    const std::optional<Rect>& current_clip_coverage) const {
  if (!current_clip_coverage.has_value()) {
    return {.type = ClipCoverage::Type::kAppend, .coverage = std::nullopt};
  }
  switch (clip_op_) {
    case Entity::ClipOperation::kDifference:
      // This can be optimized further by considering cases when the bounds of
      // the current stencil will shrink.
      return {.type = ClipCoverage::Type::kAppend,
              .coverage = current_clip_coverage};
    case Entity::ClipOperation::kIntersect:
      if (!geometry_) {
        return {.type = ClipCoverage::Type::kAppend, .coverage = std::nullopt};
      }
      auto coverage = geometry_->GetCoverage(entity.GetTransform());
      if (!coverage.has_value() || !current_clip_coverage.has_value()) {
        return {.type = ClipCoverage::Type::kAppend, .coverage = std::nullopt};
      }
      return {
          .type = ClipCoverage::Type::kAppend,
          .coverage = current_clip_coverage->Intersection(coverage.value()),
      };
  }
  FML_UNREACHABLE();
}

bool ClipContents::ShouldRender(const Entity& entity,
                                const std::optional<Rect> clip_coverage) const {
  return true;
}

bool ClipContents::CanInheritOpacity(const Entity& entity) const {
  return true;
}

void ClipContents::SetInheritedOpacity(Scalar opacity) {}

bool ClipContents::Render(const ContentContext& renderer,
                          const Entity& entity,
                          RenderPass& pass) const {
  using VS = ClipPipeline::VertexShader;

  VS::FrameInfo info;
  info.depth = entity.GetShaderClipDepth();

  auto options = OptionsFromPass(pass);
  options.blend_mode = BlendMode::kDestination;
  pass.SetStencilReference(entity.GetClipDepth());

  if (clip_op_ == Entity::ClipOperation::kDifference) {
    {
      pass.SetCommandLabel("Difference Clip (Increment)");

      options.stencil_mode =
          ContentContextOptions::StencilMode::kLegacyClipIncrement;

      auto points = Rect::MakeSize(pass.GetRenderTargetSize()).GetPoints();
      auto vertices =
          VertexBufferBuilder<VS::PerVertexData>{}
              .AddVertices({{points[0]}, {points[1]}, {points[2]}, {points[3]}})
              .CreateVertexBuffer(renderer.GetTransientsBuffer());

      pass.SetVertexBuffer(std::move(vertices));

      info.mvp = pass.GetOrthographicTransform();
      VS::BindFrameInfo(pass,
                        renderer.GetTransientsBuffer().EmplaceUniform(info));

      options.primitive_type = PrimitiveType::kTriangleStrip;
      pass.SetPipeline(renderer.GetClipPipeline(options));
      pass.Draw();
    }

    {
      pass.SetCommandLabel("Difference Clip (Punch)");
      pass.SetStencilReference(entity.GetClipDepth() + 1);

      options.stencil_mode =
          ContentContextOptions::StencilMode::kLegacyClipDecrement;
    }
  } else {
    pass.SetCommandLabel("Intersect Clip");

    options.stencil_mode =
        ContentContextOptions::StencilMode::kLegacyClipIncrement;
  }

  auto geometry_result = geometry_->GetPositionBuffer(renderer, entity, pass);
  options.primitive_type = geometry_result.type;
  pass.SetPipeline(renderer.GetClipPipeline(options));

  pass.SetVertexBuffer(std::move(geometry_result.vertex_buffer));

  info.mvp = geometry_result.transform;
  VS::BindFrameInfo(pass, renderer.GetTransientsBuffer().EmplaceUniform(info));

  return pass.Draw().ok();
}

/*******************************************************************************
 ******* ClipRestoreContents
 ******************************************************************************/

ClipRestoreContents::ClipRestoreContents() = default;

ClipRestoreContents::~ClipRestoreContents() = default;

void ClipRestoreContents::SetRestoreCoverage(
    std::optional<Rect> restore_coverage) {
  restore_coverage_ = restore_coverage;
}

std::optional<Rect> ClipRestoreContents::GetCoverage(
    const Entity& entity) const {
  return std::nullopt;
};

Contents::ClipCoverage ClipRestoreContents::GetClipCoverage(
    const Entity& entity,
    const std::optional<Rect>& current_clip_coverage) const {
  return {.type = ClipCoverage::Type::kRestore, .coverage = std::nullopt};
}

bool ClipRestoreContents::ShouldRender(
    const Entity& entity,
    const std::optional<Rect> clip_coverage) const {
  return true;
}

bool ClipRestoreContents::CanInheritOpacity(const Entity& entity) const {
  return true;
}

void ClipRestoreContents::SetInheritedOpacity(Scalar opacity) {}

bool ClipRestoreContents::Render(const ContentContext& renderer,
                                 const Entity& entity,
                                 RenderPass& pass) const {
  using VS = ClipPipeline::VertexShader;

  pass.SetCommandLabel("Restore Clip");
  auto options = OptionsFromPass(pass);
  options.blend_mode = BlendMode::kDestination;
  options.stencil_mode = ContentContextOptions::StencilMode::kLegacyClipRestore;
  options.primitive_type = PrimitiveType::kTriangleStrip;
  pass.SetPipeline(renderer.GetClipPipeline(options));
  pass.SetStencilReference(entity.GetClipDepth());

  // Create a rect that covers either the given restore area, or the whole
  // render target texture.
  auto ltrb =
      restore_coverage_.value_or(Rect::MakeSize(pass.GetRenderTargetSize()))
          .GetLTRB();
  VertexBufferBuilder<VS::PerVertexData> vtx_builder;
  vtx_builder.AddVertices({
      {Point(ltrb[0], ltrb[1])},
      {Point(ltrb[2], ltrb[1])},
      {Point(ltrb[0], ltrb[3])},
      {Point(ltrb[2], ltrb[3])},
  });
  pass.SetVertexBuffer(
      vtx_builder.CreateVertexBuffer(renderer.GetTransientsBuffer()));

  VS::FrameInfo info;
  info.mvp = pass.GetOrthographicTransform();
  VS::BindFrameInfo(pass, renderer.GetTransientsBuffer().EmplaceUniform(info));

  return pass.Draw().ok();
}

};  // namespace impeller
