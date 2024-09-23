// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cmath>
#include <optional>

#include "fml/logging.h"
#include "impeller/core/formats.h"
#include "impeller/core/vertex_buffer.h"
#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/entity.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/vertex_buffer_builder.h"

namespace impeller {

static Scalar GetShaderClipDepth(const Entity& entity) {
  // Draw the clip at the max of the clip entity's depth slice, so that other
  // draw calls with this same depth value will be culled even if they have a
  // perspective transform.
  return std::nextafterf(Entity::GetShaderClipDepth(entity.GetClipDepth() + 1),
                         0.0f);
}

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
      return {
          .type = ClipCoverage::Type::kAppend,  //
          .is_difference_or_non_square = true,  //
          .coverage = current_clip_coverage     //
      };
    case Entity::ClipOperation::kIntersect:
      if (!geometry_) {
        return {.type = ClipCoverage::Type::kAppend, .coverage = std::nullopt};
      }
      auto coverage = geometry_->GetCoverage(entity.GetTransform());
      if (!coverage.has_value() || !current_clip_coverage.has_value()) {
        return {.type = ClipCoverage::Type::kAppend, .coverage = std::nullopt};
      }
      return {
          .type = ClipCoverage::Type::kAppend,                                //
          .is_difference_or_non_square = !geometry_->IsAxisAlignedRect(),     //
          .coverage = current_clip_coverage->Intersection(coverage.value()),  //
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
  if (!geometry_) {
    return true;
  }

  using VS = ClipPipeline::VertexShader;

  VS::FrameInfo info;
  info.depth = GetShaderClipDepth(entity);

  auto geometry_result = geometry_->GetPositionBuffer(renderer, entity, pass);
  auto options = OptionsFromPass(pass);
  options.blend_mode = BlendMode::kDestination;

  pass.SetStencilReference(0);

  /// Stencil preparation draw.

  options.depth_write_enabled = false;
  options.primitive_type = geometry_result.type;
  pass.SetVertexBuffer(std::move(geometry_result.vertex_buffer));
  switch (geometry_result.mode) {
    case GeometryResult::Mode::kNonZero:
      pass.SetCommandLabel("Clip stencil preparation (NonZero)");
      options.stencil_mode =
          ContentContextOptions::StencilMode::kStencilNonZeroFill;
      break;
    case GeometryResult::Mode::kEvenOdd:
      pass.SetCommandLabel("Clip stencil preparation (EvenOdd)");
      options.stencil_mode =
          ContentContextOptions::StencilMode::kStencilEvenOddFill;
      break;
    case GeometryResult::Mode::kNormal:
    case GeometryResult::Mode::kPreventOverdraw:
      pass.SetCommandLabel("Clip stencil preparation (Increment)");
      options.stencil_mode =
          ContentContextOptions::StencilMode::kOverdrawPreventionIncrement;
      break;
  }
  pass.SetPipeline(renderer.GetClipPipeline(options));

  info.mvp = geometry_result.transform;
  VS::BindFrameInfo(pass, renderer.GetTransientsBuffer().EmplaceUniform(info));

  if (!pass.Draw().ok()) {
    return false;
  }

  /// Write depth.

  options.depth_write_enabled = true;
  options.primitive_type = PrimitiveType::kTriangleStrip;
  Rect cover_area;
  switch (clip_op_) {
    case Entity::ClipOperation::kIntersect:
      pass.SetCommandLabel("Intersect Clip");
      options.stencil_mode =
          ContentContextOptions::StencilMode::kCoverCompareInverted;
      cover_area = Rect::MakeSize(pass.GetRenderTargetSize());
      break;
    case Entity::ClipOperation::kDifference:
      pass.SetCommandLabel("Difference Clip");
      options.stencil_mode = ContentContextOptions::StencilMode::kCoverCompare;
      std::optional<Rect> maybe_cover_area =
          geometry_->GetCoverage(entity.GetTransform());
      if (!maybe_cover_area.has_value()) {
        return true;
      }
      cover_area = maybe_cover_area.value();
      break;
  }
  auto points = cover_area.GetPoints();
  pass.SetVertexBuffer(
      CreateVertexBuffer(points, renderer.GetTransientsBuffer()));

  pass.SetPipeline(renderer.GetClipPipeline(options));

  info.mvp = pass.GetOrthographicTransform();
  VS::BindFrameInfo(pass, renderer.GetTransientsBuffer().EmplaceUniform(info));

  return pass.Draw().ok();
}

/*******************************************************************************
 ******* ClipRestoreContents
 ******************************************************************************/

ClipRestoreContents::ClipRestoreContents() = default;

ClipRestoreContents::~ClipRestoreContents() = default;

void ClipRestoreContents::SetRestoreHeight(size_t clip_height) {
  restore_height_ = clip_height;
}

size_t ClipRestoreContents::GetRestoreHeight() const {
  return restore_height_;
}

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
  options.stencil_mode =
      ContentContextOptions::StencilMode::kOverdrawPreventionRestore;
  options.primitive_type = PrimitiveType::kTriangleStrip;
  pass.SetPipeline(renderer.GetClipPipeline(options));
  pass.SetStencilReference(0);

  // Create a rect that covers either the given restore area, or the whole
  // render target texture.
  auto ltrb =
      restore_coverage_.value_or(Rect::MakeSize(pass.GetRenderTargetSize()))
          .GetLTRB();

  std::array<VS::PerVertexData, 4> vertices = {
      VS::PerVertexData{Point(ltrb[0], ltrb[1])},
      VS::PerVertexData{Point(ltrb[2], ltrb[1])},
      VS::PerVertexData{Point(ltrb[0], ltrb[3])},
      VS::PerVertexData{Point(ltrb[2], ltrb[3])},
  };
  pass.SetVertexBuffer(
      CreateVertexBuffer(vertices, renderer.GetTransientsBuffer()));

  VS::FrameInfo info;
  info.depth = GetShaderClipDepth(entity);
  info.mvp = pass.GetOrthographicTransform();
  VS::BindFrameInfo(pass, renderer.GetTransientsBuffer().EmplaceUniform(info));

  return pass.Draw().ok();
}

}  // namespace impeller
