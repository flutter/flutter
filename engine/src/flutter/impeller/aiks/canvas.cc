// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/canvas.h"

#include <optional>
#include <utility>

#include "flutter/fml/logging.h"
#include "impeller/aiks/image_filter.h"
#include "impeller/aiks/paint_pass_delegate.h"
#include "impeller/entity/contents/atlas_contents.h"
#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/contents/solid_rrect_blur_contents.h"
#include "impeller/entity/contents/text_contents.h"
#include "impeller/entity/contents/texture_contents.h"
#include "impeller/entity/contents/vertices_contents.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/geometry/path_builder.h"

namespace impeller {

Canvas::Canvas() {
  Initialize(std::nullopt);
}

Canvas::Canvas(Rect cull_rect) {
  Initialize(cull_rect);
}

Canvas::Canvas(IRect cull_rect) {
  Initialize(Rect::MakeLTRB(cull_rect.GetLeft(), cull_rect.GetTop(),
                            cull_rect.GetRight(), cull_rect.GetBottom()));
}

Canvas::~Canvas() = default;

void Canvas::Initialize(std::optional<Rect> cull_rect) {
  initial_cull_rect_ = cull_rect;
  base_pass_ = std::make_unique<EntityPass>();
  current_pass_ = base_pass_.get();
  xformation_stack_.emplace_back(CanvasStackEntry{.cull_rect = cull_rect});
  FML_DCHECK(GetSaveCount() == 1u);
  FML_DCHECK(base_pass_->GetSubpassesDepth() == 1u);
}

void Canvas::Reset() {
  base_pass_ = nullptr;
  current_pass_ = nullptr;
  xformation_stack_ = {};
}

void Canvas::Save() {
  Save(false);
}

void Canvas::Save(bool create_subpass,
                  BlendMode blend_mode,
                  const std::shared_ptr<ImageFilter>& backdrop_filter) {
  auto entry = CanvasStackEntry{};
  entry.xformation = xformation_stack_.back().xformation;
  entry.cull_rect = xformation_stack_.back().cull_rect;
  entry.stencil_depth = xformation_stack_.back().stencil_depth;
  if (create_subpass) {
    entry.rendering_mode = Entity::RenderingMode::kSubpass;
    auto subpass = std::make_unique<EntityPass>();
    subpass->SetEnableOffscreenCheckerboard(
        debug_options.offscreen_texture_checkerboard);
    if (backdrop_filter) {
      EntityPass::BackdropFilterProc backdrop_filter_proc =
          [backdrop_filter = backdrop_filter->Clone()](
              const FilterInput::Ref& input, const Matrix& effect_transform,
              Entity::RenderingMode rendering_mode) {
            auto filter = backdrop_filter->WrapInput(input);
            filter->SetEffectTransform(effect_transform);
            filter->SetRenderingMode(rendering_mode);
            return filter;
          };
      subpass->SetBackdropFilter(backdrop_filter_proc);
    }
    subpass->SetBlendMode(blend_mode);
    current_pass_ = GetCurrentPass().AddSubpass(std::move(subpass));
    current_pass_->SetTransformation(xformation_stack_.back().xformation);
    current_pass_->SetStencilDepth(xformation_stack_.back().stencil_depth);
  }
  xformation_stack_.emplace_back(entry);
}

bool Canvas::Restore() {
  FML_DCHECK(xformation_stack_.size() > 0);
  if (xformation_stack_.size() == 1) {
    return false;
  }
  if (xformation_stack_.back().rendering_mode ==
      Entity::RenderingMode::kSubpass) {
    current_pass_ = GetCurrentPass().GetSuperpass();
    FML_DCHECK(current_pass_);
  }

  bool contains_clips = xformation_stack_.back().contains_clips;
  xformation_stack_.pop_back();

  if (contains_clips) {
    RestoreClip();
  }

  return true;
}

void Canvas::Concat(const Matrix& xformation) {
  xformation_stack_.back().xformation = GetCurrentTransformation() * xformation;
}

void Canvas::PreConcat(const Matrix& xformation) {
  xformation_stack_.back().xformation = xformation * GetCurrentTransformation();
}

void Canvas::ResetTransform() {
  xformation_stack_.back().xformation = {};
}

void Canvas::Transform(const Matrix& xformation) {
  Concat(xformation);
}

const Matrix& Canvas::GetCurrentTransformation() const {
  return xformation_stack_.back().xformation;
}

const std::optional<Rect> Canvas::GetCurrentLocalCullingBounds() const {
  auto cull_rect = xformation_stack_.back().cull_rect;
  if (cull_rect.has_value()) {
    Matrix inverse = xformation_stack_.back().xformation.Invert();
    cull_rect = cull_rect.value().TransformBounds(inverse);
  }
  return cull_rect;
}

void Canvas::Translate(const Vector3& offset) {
  Concat(Matrix::MakeTranslation(offset));
}

void Canvas::Scale(const Vector2& scale) {
  Concat(Matrix::MakeScale(scale));
}

void Canvas::Scale(const Vector3& scale) {
  Concat(Matrix::MakeScale(scale));
}

void Canvas::Skew(Scalar sx, Scalar sy) {
  Concat(Matrix::MakeSkew(sx, sy));
}

void Canvas::Rotate(Radians radians) {
  Concat(Matrix::MakeRotationZ(radians));
}

size_t Canvas::GetSaveCount() const {
  return xformation_stack_.size();
}

void Canvas::RestoreToCount(size_t count) {
  while (GetSaveCount() > count) {
    if (!Restore()) {
      return;
    }
  }
}

void Canvas::DrawPath(const Path& path, const Paint& paint) {
  Entity entity;
  entity.SetTransformation(GetCurrentTransformation());
  entity.SetStencilDepth(GetStencilDepth());
  entity.SetBlendMode(paint.blend_mode);
  entity.SetContents(paint.WithFilters(paint.CreateContentsForEntity(path)));

  GetCurrentPass().AddEntity(entity);
}

void Canvas::DrawPaint(const Paint& paint) {
  Entity entity;
  entity.SetTransformation(GetCurrentTransformation());
  entity.SetStencilDepth(GetStencilDepth());
  entity.SetBlendMode(paint.blend_mode);
  entity.SetContents(paint.CreateContentsForEntity({}, true));

  GetCurrentPass().AddEntity(entity);
}

bool Canvas::AttemptDrawBlurredRRect(const Rect& rect,
                                     Scalar corner_radius,
                                     const Paint& paint) {
  Paint new_paint = paint;
  if (new_paint.color_source.GetType() != ColorSource::Type::kColor ||
      new_paint.style != Paint::Style::kFill) {
    return false;
  }

  if (!new_paint.mask_blur_descriptor.has_value() ||
      new_paint.mask_blur_descriptor->style !=
          FilterContents::BlurStyle::kNormal) {
    return false;
  }

  // For symmetrically mask blurred solid RRects, absorb the mask blur and use
  // a faster SDF approximation.

  auto contents = std::make_shared<SolidRRectBlurContents>();
  contents->SetColor(new_paint.color);
  contents->SetSigma(new_paint.mask_blur_descriptor->sigma);
  contents->SetRRect(rect, corner_radius);

  new_paint.mask_blur_descriptor = std::nullopt;

  Entity entity;
  entity.SetTransformation(GetCurrentTransformation());
  entity.SetStencilDepth(GetStencilDepth());
  entity.SetBlendMode(new_paint.blend_mode);
  entity.SetContents(new_paint.WithFilters(std::move(contents)));

  GetCurrentPass().AddEntity(entity);

  return true;
}

void Canvas::DrawRect(Rect rect, const Paint& paint) {
  if (paint.style == Paint::Style::kStroke) {
    DrawPath(PathBuilder{}.AddRect(rect).TakePath(), paint);
    return;
  }

  if (AttemptDrawBlurredRRect(rect, 0, paint)) {
    return;
  }

  Entity entity;
  entity.SetTransformation(GetCurrentTransformation());
  entity.SetStencilDepth(GetStencilDepth());
  entity.SetBlendMode(paint.blend_mode);
  entity.SetContents(paint.WithFilters(
      paint.CreateContentsForGeometry(Geometry::MakeRect(rect))));

  GetCurrentPass().AddEntity(entity);
}

void Canvas::DrawRRect(Rect rect, Scalar corner_radius, const Paint& paint) {
  if (AttemptDrawBlurredRRect(rect, corner_radius, paint)) {
    return;
  }
  auto path = PathBuilder{}
                  .SetConvexity(Convexity::kConvex)
                  .AddRoundedRect(rect, corner_radius)
                  .TakePath();
  if (paint.style == Paint::Style::kFill) {
    Entity entity;
    entity.SetTransformation(GetCurrentTransformation());
    entity.SetStencilDepth(GetStencilDepth());
    entity.SetBlendMode(paint.blend_mode);
    entity.SetContents(paint.WithFilters(
        paint.CreateContentsForGeometry(Geometry::MakeFillPath(path))));

    GetCurrentPass().AddEntity(entity);
    return;
  }
  DrawPath(path, paint);
}

void Canvas::DrawCircle(Point center, Scalar radius, const Paint& paint) {
  Size half_size(radius, radius);
  if (AttemptDrawBlurredRRect(Rect(center - half_size, half_size * 2), radius,
                              paint)) {
    return;
  }
  auto circle_path = PathBuilder{}
                         .AddCircle(center, radius)
                         .SetConvexity(Convexity::kConvex)
                         .TakePath();
  DrawPath(circle_path, paint);
}

void Canvas::ClipPath(const Path& path, Entity::ClipOperation clip_op) {
  ClipGeometry(Geometry::MakeFillPath(path), clip_op);
  if (clip_op == Entity::ClipOperation::kIntersect) {
    auto bounds = path.GetBoundingBox();
    if (bounds.has_value()) {
      IntersectCulling(bounds.value());
    }
  }
}

void Canvas::ClipRect(const Rect& rect, Entity::ClipOperation clip_op) {
  auto geometry = Geometry::MakeRect(rect);
  auto& cull_rect = xformation_stack_.back().cull_rect;
  if (clip_op == Entity::ClipOperation::kIntersect &&                        //
      cull_rect.has_value() &&                                               //
      geometry->CoversArea(xformation_stack_.back().xformation, *cull_rect)  //
  ) {
    return;  // This clip will do nothing, so skip it.
  }

  ClipGeometry(std::move(geometry), clip_op);
  switch (clip_op) {
    case Entity::ClipOperation::kIntersect:
      IntersectCulling(rect);
      break;
    case Entity::ClipOperation::kDifference:
      SubtractCulling(rect);
      break;
  }
}

void Canvas::ClipRRect(const Rect& rect,
                       Scalar corner_radius,
                       Entity::ClipOperation clip_op) {
  auto path = PathBuilder{}
                  .SetConvexity(Convexity::kConvex)
                  .AddRoundedRect(rect, corner_radius)
                  .TakePath();

  std::optional<Rect> inner_rect = (corner_radius * 2 < rect.size.width &&
                                    corner_radius * 2 < rect.size.height)
                                       ? rect.Expand(-corner_radius)
                                       : std::make_optional<Rect>();
  auto geometry = Geometry::MakeFillPath(path, inner_rect);
  auto& cull_rect = xformation_stack_.back().cull_rect;
  if (clip_op == Entity::ClipOperation::kIntersect &&                        //
      cull_rect.has_value() &&                                               //
      geometry->CoversArea(xformation_stack_.back().xformation, *cull_rect)  //
  ) {
    return;  // This clip will do nothing, so skip it.
  }

  ClipGeometry(std::move(geometry), clip_op);
  switch (clip_op) {
    case Entity::ClipOperation::kIntersect:
      IntersectCulling(rect);
      break;
    case Entity::ClipOperation::kDifference:
      if (corner_radius <= 0) {
        SubtractCulling(rect);
      } else {
        // We subtract the inner "tall" and "wide" rectangle pieces
        // that fit inside the corners which cover the greatest area
        // without involving the curved corners
        // Since this is a subtract operation, we can subtract each
        // rectangle piece individually without fear of interference.
        if (corner_radius * 2 < rect.size.width) {
          SubtractCulling(Rect::MakeLTRB(
              rect.GetLeft() + corner_radius, rect.GetTop(),
              rect.GetRight() - corner_radius, rect.GetBottom()));
        }
        if (corner_radius * 2 < rect.size.height) {
          SubtractCulling(Rect::MakeLTRB(
              rect.GetLeft(), rect.GetTop() + corner_radius,  //
              rect.GetRight(), rect.GetBottom() - corner_radius));
        }
      }
      break;
  }
}

void Canvas::ClipGeometry(std::unique_ptr<Geometry> geometry,
                          Entity::ClipOperation clip_op) {
  auto contents = std::make_shared<ClipContents>();
  contents->SetGeometry(std::move(geometry));
  contents->SetClipOperation(clip_op);

  Entity entity;
  entity.SetTransformation(GetCurrentTransformation());
  entity.SetContents(std::move(contents));
  entity.SetStencilDepth(GetStencilDepth());

  GetCurrentPass().AddEntity(entity);

  ++xformation_stack_.back().stencil_depth;
  xformation_stack_.back().contains_clips = true;
}

void Canvas::IntersectCulling(Rect clip_rect) {
  clip_rect = clip_rect.TransformBounds(GetCurrentTransformation());
  std::optional<Rect>& cull_rect = xformation_stack_.back().cull_rect;
  if (cull_rect.has_value()) {
    cull_rect = cull_rect
                    .value()                  //
                    .Intersection(clip_rect)  //
                    .value_or(Rect{});
  } else {
    cull_rect = clip_rect;
  }
}

void Canvas::SubtractCulling(Rect clip_rect) {
  std::optional<Rect>& cull_rect = xformation_stack_.back().cull_rect;
  if (cull_rect.has_value()) {
    clip_rect = clip_rect.TransformBounds(GetCurrentTransformation());
    cull_rect = cull_rect
                    .value()            //
                    .Cutout(clip_rect)  //
                    .value_or(Rect{});
  }
  // else (no cull) diff (any clip) is non-rectangular
}

void Canvas::RestoreClip() {
  Entity entity;
  entity.SetTransformation(GetCurrentTransformation());
  // This path is empty because ClipRestoreContents just generates a quad that
  // takes up the full render target.
  entity.SetContents(std::make_shared<ClipRestoreContents>());
  entity.SetStencilDepth(GetStencilDepth());

  GetCurrentPass().AddEntity(entity);
}

void Canvas::DrawPoints(std::vector<Point> points,
                        Scalar radius,
                        const Paint& paint,
                        PointStyle point_style) {
  if (radius <= 0) {
    return;
  }

  Entity entity;
  entity.SetTransformation(GetCurrentTransformation());
  entity.SetStencilDepth(GetStencilDepth());
  entity.SetBlendMode(paint.blend_mode);
  entity.SetContents(paint.WithFilters(paint.CreateContentsForGeometry(
      Geometry::MakePointField(std::move(points), radius,
                               /*round=*/point_style == PointStyle::kRound))));

  GetCurrentPass().AddEntity(entity);
}

void Canvas::DrawPicture(const Picture& picture) {
  if (!picture.pass) {
    return;
  }

  // Clone the base pass and account for the CTM updates.
  auto pass = picture.pass->Clone();

  pass->IterateAllElements([&](auto& element) -> bool {
    if (auto entity = std::get_if<Entity>(&element)) {
      entity->IncrementStencilDepth(GetStencilDepth());
      entity->SetTransformation(GetCurrentTransformation() *
                                entity->GetTransformation());
      return true;
    }

    if (auto subpass = std::get_if<std::unique_ptr<EntityPass>>(&element)) {
      subpass->get()->SetStencilDepth(subpass->get()->GetStencilDepth() +
                                      GetStencilDepth());
      return true;
    }

    FML_UNREACHABLE();
  });

  GetCurrentPass().AddSubpassInline(std::move(pass));

  RestoreClip();
}

void Canvas::DrawImage(const std::shared_ptr<Image>& image,
                       Point offset,
                       const Paint& paint,
                       SamplerDescriptor sampler) {
  if (!image) {
    return;
  }

  const auto source = Rect::MakeSize(image->GetSize());
  const auto dest =
      Rect::MakeXYWH(offset.x, offset.y, source.size.width, source.size.height);

  DrawImageRect(image, source, dest, paint, std::move(sampler));
}

void Canvas::DrawImageRect(const std::shared_ptr<Image>& image,
                           Rect source,
                           Rect dest,
                           const Paint& paint,
                           SamplerDescriptor sampler) {
  if (!image || source.size.IsEmpty() || dest.size.IsEmpty()) {
    return;
  }

  auto size = image->GetSize();

  if (size.IsEmpty()) {
    return;
  }

  auto contents = TextureContents::MakeRect(dest);
  contents->SetTexture(image->GetTexture());
  contents->SetSourceRect(source);
  contents->SetSamplerDescriptor(std::move(sampler));
  contents->SetOpacity(paint.color.alpha);
  contents->SetDeferApplyingOpacity(paint.HasColorFilter());

  Entity entity;
  entity.SetBlendMode(paint.blend_mode);
  entity.SetStencilDepth(GetStencilDepth());
  entity.SetContents(paint.WithFilters(contents));
  entity.SetTransformation(GetCurrentTransformation());

  GetCurrentPass().AddEntity(entity);
}

Picture Canvas::EndRecordingAsPicture() {
  Picture picture;
  picture.pass = std::move(base_pass_);

  Reset();
  Initialize(initial_cull_rect_);

  return picture;
}

EntityPass& Canvas::GetCurrentPass() {
  FML_DCHECK(current_pass_ != nullptr);
  return *current_pass_;
}

size_t Canvas::GetStencilDepth() const {
  return xformation_stack_.back().stencil_depth;
}

void Canvas::SaveLayer(const Paint& paint,
                       std::optional<Rect> bounds,
                       const std::shared_ptr<ImageFilter>& backdrop_filter) {
  Save(true, paint.blend_mode, backdrop_filter);

  auto& new_layer_pass = GetCurrentPass();
  new_layer_pass.SetBoundsLimit(bounds);

  // Only apply opacity peephole on default blending.
  if (paint.blend_mode == BlendMode::kSourceOver) {
    new_layer_pass.SetDelegate(
        std::make_shared<OpacityPeepholePassDelegate>(paint));
  } else {
    new_layer_pass.SetDelegate(std::make_shared<PaintPassDelegate>(paint));
  }
}

void Canvas::DrawTextFrame(const std::shared_ptr<TextFrame>& text_frame,
                           Point position,
                           const Paint& paint) {
  Entity entity;
  entity.SetStencilDepth(GetStencilDepth());
  entity.SetBlendMode(paint.blend_mode);

  auto text_contents = std::make_shared<TextContents>();
  text_contents->SetTextFrame(text_frame);
  text_contents->SetColor(paint.color);

  entity.SetTransformation(GetCurrentTransformation() *
                           Matrix::MakeTranslation(position));

  // TODO(bdero): This mask blur application is a hack. It will always wind up
  //              doing a gaussian blur that affects the color source itself
  //              instead of just the mask. The color filter text support
  //              needs to be reworked in order to interact correctly with
  //              mask filters.
  //              https://github.com/flutter/flutter/issues/133297
  entity.SetContents(
      paint.WithFilters(paint.WithMaskBlur(std::move(text_contents), true)));

  GetCurrentPass().AddEntity(entity);
}

static bool UseColorSourceContents(
    const std::shared_ptr<VerticesGeometry>& vertices,
    const Paint& paint) {
  // If there are no vertex color or texture coordinates. Or if there
  // are vertex coordinates then only if the contents are an image or
  // a solid color.
  if (vertices->HasVertexColors()) {
    return false;
  }
  if (vertices->HasTextureCoordinates() &&
      (paint.color_source.GetType() == ColorSource::Type::kImage ||
       paint.color_source.GetType() == ColorSource::Type::kColor)) {
    return true;
  }
  return !vertices->HasTextureCoordinates();
}

void Canvas::DrawVertices(const std::shared_ptr<VerticesGeometry>& vertices,
                          BlendMode blend_mode,
                          const Paint& paint) {
  // Override the blend mode with kDestination in order to match the behavior
  // of Skia's SK_LEGACY_IGNORE_DRAW_VERTICES_BLEND_WITH_NO_SHADER flag, which
  // is enabled when the Flutter engine builds Skia.
  if (paint.color_source.GetType() == ColorSource::Type::kColor) {
    blend_mode = BlendMode::kDestination;
  }

  Entity entity;
  entity.SetTransformation(GetCurrentTransformation());
  entity.SetStencilDepth(GetStencilDepth());
  entity.SetBlendMode(paint.blend_mode);

  // If there are no vertex color or texture coordinates. Or if there
  // are vertex coordinates then only if the contents are an image.
  if (UseColorSourceContents(vertices, paint)) {
    auto contents = paint.CreateContentsForGeometry(vertices);
    entity.SetContents(paint.WithFilters(std::move(contents)));
    GetCurrentPass().AddEntity(entity);
    return;
  }

  auto src_paint = paint;
  src_paint.color = paint.color.WithAlpha(1.0);

  std::shared_ptr<Contents> src_contents =
      src_paint.CreateContentsForGeometry(vertices);
  if (vertices->HasTextureCoordinates()) {
    // If the color source has an intrinsic size, then we use that to
    // create the src contents as a simplification. Otherwise we use
    // the extent of the texture coordinates to determine how large
    // the src contents should be. If neither has a value we fall back
    // to using the geometry coverage data.
    Rect src_coverage;
    auto size = src_contents->GetColorSourceSize();
    if (size.has_value()) {
      src_coverage = Rect::MakeXYWH(0, 0, size->width, size->height);
    } else {
      auto cvg = vertices->GetCoverage(Matrix{});
      FML_CHECK(cvg.has_value());
      src_coverage =
          // Covered by FML_CHECK.
          // NOLINTNEXTLINE(bugprone-unchecked-optional-access)
          vertices->GetTextureCoordinateCoverge().value_or(cvg.value());
    }
    src_contents =
        src_paint.CreateContentsForGeometry(Geometry::MakeRect(src_coverage));
  }

  auto contents = std::make_shared<VerticesContents>();
  contents->SetAlpha(paint.color.alpha);
  contents->SetBlendMode(blend_mode);
  contents->SetGeometry(vertices);
  contents->SetSourceContents(std::move(src_contents));
  entity.SetContents(paint.WithFilters(std::move(contents)));

  GetCurrentPass().AddEntity(entity);
}

void Canvas::DrawAtlas(const std::shared_ptr<Image>& atlas,
                       std::vector<Matrix> transforms,
                       std::vector<Rect> texture_coordinates,
                       std::vector<Color> colors,
                       BlendMode blend_mode,
                       SamplerDescriptor sampler,
                       std::optional<Rect> cull_rect,
                       const Paint& paint) {
  if (!atlas) {
    return;
  }

  std::shared_ptr<AtlasContents> contents = std::make_shared<AtlasContents>();
  contents->SetColors(std::move(colors));
  contents->SetTransforms(std::move(transforms));
  contents->SetTextureCoordinates(std::move(texture_coordinates));
  contents->SetTexture(atlas->GetTexture());
  contents->SetSamplerDescriptor(std::move(sampler));
  contents->SetBlendMode(blend_mode);
  contents->SetCullRect(cull_rect);
  contents->SetAlpha(paint.color.alpha);

  Entity entity;
  entity.SetTransformation(GetCurrentTransformation());
  entity.SetStencilDepth(GetStencilDepth());
  entity.SetBlendMode(paint.blend_mode);
  entity.SetContents(paint.WithFilters(contents));

  GetCurrentPass().AddEntity(entity);
}

}  // namespace impeller
