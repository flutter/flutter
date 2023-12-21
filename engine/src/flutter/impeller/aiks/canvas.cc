// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/aiks/canvas.h"

#include <optional>
#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "impeller/aiks/image_filter.h"
#include "impeller/aiks/paint_pass_delegate.h"
#include "impeller/entity/contents/atlas_contents.h"
#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/solid_rrect_blur_contents.h"
#include "impeller/entity/contents/text_contents.h"
#include "impeller/entity/contents/texture_contents.h"
#include "impeller/entity/contents/vertices_contents.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/geometry/constants.h"
#include "impeller/geometry/path_builder.h"

namespace impeller {

namespace {

static std::shared_ptr<Contents> CreateContentsForGeometryWithFilters(
    const Paint& paint,
    std::shared_ptr<Geometry> geometry) {
  std::shared_ptr<ColorSourceContents> contents =
      paint.color_source.GetContents(paint);

  // Attempt to apply the color filter on the CPU first.
  // Note: This is not just an optimization; some color sources rely on
  //       CPU-applied color filters to behave properly.
  bool needs_color_filter = paint.HasColorFilter();
  if (needs_color_filter) {
    auto color_filter = paint.GetColorFilter();
    if (contents->ApplyColorFilter(color_filter->GetCPUColorFilterProc())) {
      needs_color_filter = false;
    }
  }

  contents->SetGeometry(std::move(geometry));
  if (paint.mask_blur_descriptor.has_value()) {
    // If there's a mask blur and we need to apply the color filter on the GPU,
    // we need to be careful to only apply the color filter to the source
    // colors. CreateMaskBlur is able to handle this case.
    return paint.mask_blur_descriptor->CreateMaskBlur(
        contents, needs_color_filter ? paint.GetColorFilter() : nullptr);
  }

  std::shared_ptr<Contents> contents_copy = std::move(contents);
  // Image input types will directly set their color filter,
  // if any. See `TiledTextureContents.SetColorFilter`.
  if (needs_color_filter &&
      paint.color_source.GetType() != ColorSource::Type::kImage) {
    std::shared_ptr<ColorFilter> color_filter = paint.GetColorFilter();
    contents_copy = color_filter->WrapWithGPUColorFilter(
        FilterInput::Make(std::move(contents_copy)),
        ColorFilterContents::AbsorbOpacity::kYes);
  }

  if (paint.image_filter) {
    std::shared_ptr<FilterContents> filter = paint.image_filter->WrapInput(
        FilterInput::Make(std::move(contents_copy)));
    filter->SetRenderingMode(Entity::RenderingMode::kDirect);
    return filter;
  }

  return contents_copy;
}

static std::shared_ptr<Contents> CreatePathContentsWithFilters(
    const Paint& paint,
    Path path = {}) {
  std::shared_ptr<Geometry> geometry;
  switch (paint.style) {
    case Paint::Style::kFill:
      geometry = Geometry::MakeFillPath(std::move(path));
      break;
    case Paint::Style::kStroke:
      geometry = Geometry::MakeStrokePath(std::move(path), paint.stroke_width,
                                          paint.stroke_miter, paint.stroke_cap,
                                          paint.stroke_join);
      break;
  }

  return CreateContentsForGeometryWithFilters(paint, std::move(geometry));
}

static std::shared_ptr<Contents> CreateCoverContentsWithFilters(
    const Paint& paint) {
  return CreateContentsForGeometryWithFilters(paint, Geometry::MakeCover());
}

}  // namespace

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
  transform_stack_.emplace_back(CanvasStackEntry{.cull_rect = cull_rect});
  FML_DCHECK(GetSaveCount() == 1u);
  FML_DCHECK(base_pass_->GetSubpassesDepth() == 1u);
}

void Canvas::Reset() {
  base_pass_ = nullptr;
  current_pass_ = nullptr;
  transform_stack_ = {};
}

void Canvas::Save() {
  Save(false);
}

void Canvas::Save(bool create_subpass,
                  BlendMode blend_mode,
                  const std::shared_ptr<ImageFilter>& backdrop_filter) {
  auto entry = CanvasStackEntry{};
  entry.transform = transform_stack_.back().transform;
  entry.cull_rect = transform_stack_.back().cull_rect;
  entry.clip_depth = transform_stack_.back().clip_depth;
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
    current_pass_->SetTransform(transform_stack_.back().transform);
    current_pass_->SetClipDepth(transform_stack_.back().clip_depth);
  }
  transform_stack_.emplace_back(entry);
}

bool Canvas::Restore() {
  FML_DCHECK(transform_stack_.size() > 0);
  if (transform_stack_.size() == 1) {
    return false;
  }
  if (transform_stack_.back().rendering_mode ==
      Entity::RenderingMode::kSubpass) {
    current_pass_ = GetCurrentPass().GetSuperpass();
    FML_DCHECK(current_pass_);
  }

  bool contains_clips = transform_stack_.back().contains_clips;
  transform_stack_.pop_back();

  if (contains_clips) {
    RestoreClip();
  }

  return true;
}

void Canvas::Concat(const Matrix& transform) {
  transform_stack_.back().transform = GetCurrentTransform() * transform;
}

void Canvas::PreConcat(const Matrix& transform) {
  transform_stack_.back().transform = transform * GetCurrentTransform();
}

void Canvas::ResetTransform() {
  transform_stack_.back().transform = {};
}

void Canvas::Transform(const Matrix& transform) {
  Concat(transform);
}

const Matrix& Canvas::GetCurrentTransform() const {
  return transform_stack_.back().transform;
}

const std::optional<Rect> Canvas::GetCurrentLocalCullingBounds() const {
  auto cull_rect = transform_stack_.back().cull_rect;
  if (cull_rect.has_value()) {
    Matrix inverse = transform_stack_.back().transform.Invert();
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
  return transform_stack_.size();
}

void Canvas::RestoreToCount(size_t count) {
  while (GetSaveCount() > count) {
    if (!Restore()) {
      return;
    }
  }
}

void Canvas::DrawPath(Path path, const Paint& paint) {
  Entity entity;
  entity.SetTransform(GetCurrentTransform());
  entity.SetClipDepth(GetClipDepth());
  entity.SetBlendMode(paint.blend_mode);
  entity.SetContents(CreatePathContentsWithFilters(paint, std::move(path)));

  GetCurrentPass().AddEntity(std::move(entity));
}

void Canvas::DrawPaint(const Paint& paint) {
  Entity entity;
  entity.SetTransform(GetCurrentTransform());
  entity.SetClipDepth(GetClipDepth());
  entity.SetBlendMode(paint.blend_mode);
  entity.SetContents(CreateCoverContentsWithFilters(paint));

  GetCurrentPass().AddEntity(std::move(entity));
}

bool Canvas::AttemptDrawBlurredRRect(const Rect& rect,
                                     Scalar corner_radius,
                                     const Paint& paint) {
  if (paint.color_source.GetType() != ColorSource::Type::kColor ||
      paint.style != Paint::Style::kFill) {
    return false;
  }

  if (!paint.mask_blur_descriptor.has_value() ||
      paint.mask_blur_descriptor->style != FilterContents::BlurStyle::kNormal) {
    return false;
  }
  // A blur sigma that is close to zero should not result in any shadow.
  if (std::fabs(paint.mask_blur_descriptor->sigma.sigma) <= kEhCloseEnough) {
    return false;
  }

  Paint new_paint = paint;

  // For symmetrically mask blurred solid RRects, absorb the mask blur and use
  // a faster SDF approximation.

  auto contents = std::make_shared<SolidRRectBlurContents>();
  contents->SetColor(new_paint.color);
  contents->SetSigma(new_paint.mask_blur_descriptor->sigma);
  contents->SetRRect(rect, corner_radius);

  new_paint.mask_blur_descriptor = std::nullopt;

  Entity entity;
  entity.SetTransform(GetCurrentTransform());
  entity.SetClipDepth(GetClipDepth());
  entity.SetBlendMode(new_paint.blend_mode);
  entity.SetContents(new_paint.WithFilters(std::move(contents)));

  GetCurrentPass().AddEntity(std::move(entity));

  return true;
}

void Canvas::DrawLine(const Point& p0, const Point& p1, const Paint& paint) {
  Entity entity;
  entity.SetTransform(GetCurrentTransform());
  entity.SetClipDepth(GetClipDepth());
  entity.SetBlendMode(paint.blend_mode);
  entity.SetContents(CreateContentsForGeometryWithFilters(
      paint, Geometry::MakeLine(p0, p1, paint.stroke_width, paint.stroke_cap)));

  GetCurrentPass().AddEntity(std::move(entity));
}

void Canvas::DrawRect(const Rect& rect, const Paint& paint) {
  if (paint.style == Paint::Style::kStroke) {
    DrawPath(PathBuilder{}.AddRect(rect).TakePath(), paint);
    return;
  }

  if (AttemptDrawBlurredRRect(rect, 0, paint)) {
    return;
  }

  Entity entity;
  entity.SetTransform(GetCurrentTransform());
  entity.SetClipDepth(GetClipDepth());
  entity.SetBlendMode(paint.blend_mode);
  entity.SetContents(
      CreateContentsForGeometryWithFilters(paint, Geometry::MakeRect(rect)));

  GetCurrentPass().AddEntity(std::move(entity));
}

void Canvas::DrawOval(const Rect& rect, const Paint& paint) {
  if (rect.IsSquare()) {
    // Circles have slightly less overhead and can do stroking
    DrawCircle(rect.GetCenter(), rect.GetWidth() * 0.5f, paint);
    return;
  }

  if (paint.style == Paint::Style::kStroke) {
    // No stroked ellipses yet
    DrawPath(PathBuilder{}.AddOval(rect).TakePath(), paint);
    return;
  }

  if (AttemptDrawBlurredRRect(rect, 0, paint)) {
    return;
  }

  Entity entity;
  entity.SetTransform(GetCurrentTransform());
  entity.SetClipDepth(GetClipDepth());
  entity.SetBlendMode(paint.blend_mode);
  entity.SetContents(
      CreateContentsForGeometryWithFilters(paint, Geometry::MakeOval(rect)));

  GetCurrentPass().AddEntity(std::move(entity));
}

void Canvas::DrawRRect(const Rect& rect,
                       const Size& corner_radii,
                       const Paint& paint) {
  if (corner_radii.IsSquare() &&
      AttemptDrawBlurredRRect(rect, corner_radii.width, paint)) {
    return;
  }

  if (paint.style == Paint::Style::kFill) {
    Entity entity;
    entity.SetTransform(GetCurrentTransform());
    entity.SetClipDepth(GetClipDepth());
    entity.SetBlendMode(paint.blend_mode);
    entity.SetContents(CreateContentsForGeometryWithFilters(
        paint, Geometry::MakeRoundRect(rect, corner_radii)));

    GetCurrentPass().AddEntity(std::move(entity));
    return;
  }

  auto path = PathBuilder{}
                  .SetConvexity(Convexity::kConvex)
                  .AddRoundedRect(rect, corner_radii)
                  .SetBounds(rect)
                  .TakePath();
  DrawPath(std::move(path), paint);
}

void Canvas::DrawCircle(const Point& center,
                        Scalar radius,
                        const Paint& paint) {
  Size half_size(radius, radius);
  if (AttemptDrawBlurredRRect(
          Rect::MakeOriginSize(center - half_size, half_size * 2), radius,
          paint)) {
    return;
  }

  Entity entity;
  entity.SetTransform(GetCurrentTransform());
  entity.SetClipDepth(GetClipDepth());
  entity.SetBlendMode(paint.blend_mode);
  auto geometry =
      paint.style == Paint::Style::kStroke
          ? Geometry::MakeStrokedCircle(center, radius, paint.stroke_width)
          : Geometry::MakeCircle(center, radius);
  entity.SetContents(
      CreateContentsForGeometryWithFilters(paint, std::move(geometry)));

  GetCurrentPass().AddEntity(std::move(entity));
}

void Canvas::ClipPath(Path path, Entity::ClipOperation clip_op) {
  auto bounds = path.GetBoundingBox();
  ClipGeometry(Geometry::MakeFillPath(std::move(path)), clip_op);
  if (clip_op == Entity::ClipOperation::kIntersect) {
    if (bounds.has_value()) {
      IntersectCulling(bounds.value());
    }
  }
}

void Canvas::ClipRect(const Rect& rect, Entity::ClipOperation clip_op) {
  auto geometry = Geometry::MakeRect(rect);
  auto& cull_rect = transform_stack_.back().cull_rect;
  if (clip_op == Entity::ClipOperation::kIntersect &&                      //
      cull_rect.has_value() &&                                             //
      geometry->CoversArea(transform_stack_.back().transform, *cull_rect)  //
  ) {
    return;  // This clip will do nothing, so skip it.
  }

  ClipGeometry(geometry, clip_op);
  switch (clip_op) {
    case Entity::ClipOperation::kIntersect:
      IntersectCulling(rect);
      break;
    case Entity::ClipOperation::kDifference:
      SubtractCulling(rect);
      break;
  }
}

void Canvas::ClipOval(const Rect& bounds, Entity::ClipOperation clip_op) {
  auto geometry = Geometry::MakeOval(bounds);
  auto& cull_rect = transform_stack_.back().cull_rect;
  if (clip_op == Entity::ClipOperation::kIntersect &&                      //
      cull_rect.has_value() &&                                             //
      geometry->CoversArea(transform_stack_.back().transform, *cull_rect)  //
  ) {
    return;  // This clip will do nothing, so skip it.
  }

  ClipGeometry(geometry, clip_op);
  switch (clip_op) {
    case Entity::ClipOperation::kIntersect:
      IntersectCulling(bounds);
      break;
    case Entity::ClipOperation::kDifference:
      break;
  }
}

void Canvas::ClipRRect(const Rect& rect,
                       const Size& corner_radii,
                       Entity::ClipOperation clip_op) {
  // Does the rounded rect have a flat part on the top/bottom or left/right?
  bool flat_on_TB = corner_radii.width * 2 < rect.GetWidth();
  bool flat_on_LR = corner_radii.height * 2 < rect.GetHeight();
  auto geometry = Geometry::MakeRoundRect(rect, corner_radii);
  auto& cull_rect = transform_stack_.back().cull_rect;
  if (clip_op == Entity::ClipOperation::kIntersect &&                      //
      cull_rect.has_value() &&                                             //
      geometry->CoversArea(transform_stack_.back().transform, *cull_rect)  //
  ) {
    return;  // This clip will do nothing, so skip it.
  }

  ClipGeometry(geometry, clip_op);
  switch (clip_op) {
    case Entity::ClipOperation::kIntersect:
      IntersectCulling(rect);
      break;
    case Entity::ClipOperation::kDifference:
      if (corner_radii.IsEmpty()) {
        SubtractCulling(rect);
      } else {
        // We subtract the inner "tall" and "wide" rectangle pieces
        // that fit inside the corners which cover the greatest area
        // without involving the curved corners
        // Since this is a subtract operation, we can subtract each
        // rectangle piece individually without fear of interference.
        if (flat_on_TB) {
          SubtractCulling(rect.Expand(Size{-corner_radii.width, 0.0}));
        }
        if (flat_on_LR) {
          SubtractCulling(rect.Expand(Size{0.0, -corner_radii.height}));
        }
      }
      break;
  }
}

void Canvas::ClipGeometry(const std::shared_ptr<Geometry>& geometry,
                          Entity::ClipOperation clip_op) {
  auto contents = std::make_shared<ClipContents>();
  contents->SetGeometry(geometry);
  contents->SetClipOperation(clip_op);

  Entity entity;
  entity.SetTransform(GetCurrentTransform());
  entity.SetContents(std::move(contents));
  entity.SetClipDepth(GetClipDepth());

  GetCurrentPass().AddEntity(std::move(entity));

  ++transform_stack_.back().clip_depth;
  transform_stack_.back().contains_clips = true;
}

void Canvas::IntersectCulling(Rect clip_rect) {
  clip_rect = clip_rect.TransformBounds(GetCurrentTransform());
  std::optional<Rect>& cull_rect = transform_stack_.back().cull_rect;
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
  std::optional<Rect>& cull_rect = transform_stack_.back().cull_rect;
  if (cull_rect.has_value()) {
    clip_rect = clip_rect.TransformBounds(GetCurrentTransform());
    cull_rect = cull_rect
                    .value()            //
                    .Cutout(clip_rect)  //
                    .value_or(Rect{});
  }
  // else (no cull) diff (any clip) is non-rectangular
}

void Canvas::RestoreClip() {
  Entity entity;
  entity.SetTransform(GetCurrentTransform());
  // This path is empty because ClipRestoreContents just generates a quad that
  // takes up the full render target.
  entity.SetContents(std::make_shared<ClipRestoreContents>());
  entity.SetClipDepth(GetClipDepth());

  GetCurrentPass().AddEntity(std::move(entity));
}

void Canvas::DrawPoints(std::vector<Point> points,
                        Scalar radius,
                        const Paint& paint,
                        PointStyle point_style) {
  if (radius <= 0) {
    return;
  }

  Entity entity;
  entity.SetTransform(GetCurrentTransform());
  entity.SetClipDepth(GetClipDepth());
  entity.SetBlendMode(paint.blend_mode);
  entity.SetContents(CreateContentsForGeometryWithFilters(
      paint,
      Geometry::MakePointField(std::move(points), radius,
                               /*round=*/point_style == PointStyle::kRound)));

  GetCurrentPass().AddEntity(std::move(entity));
}

void Canvas::DrawPicture(const Picture& picture) {
  if (!picture.pass) {
    return;
  }

  // Clone the base pass and account for the CTM updates.
  auto pass = picture.pass->Clone();

  pass->IterateAllElements([&](auto& element) -> bool {
    if (auto entity = std::get_if<Entity>(&element)) {
      entity->IncrementStencilDepth(GetClipDepth());
      entity->SetTransform(GetCurrentTransform() * entity->GetTransform());
      return true;
    }

    if (auto subpass = std::get_if<std::unique_ptr<EntityPass>>(&element)) {
      subpass->get()->SetClipDepth(subpass->get()->GetClipDepth() +
                                   GetClipDepth());
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
  const auto dest = source.Shift(offset);

  DrawImageRect(image, source, dest, paint, std::move(sampler));
}

void Canvas::DrawImageRect(const std::shared_ptr<Image>& image,
                           Rect source,
                           Rect dest,
                           const Paint& paint,
                           SamplerDescriptor sampler) {
  if (!image || source.IsEmpty() || dest.IsEmpty()) {
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
  entity.SetClipDepth(GetClipDepth());
  entity.SetContents(paint.WithFilters(contents));
  entity.SetTransform(GetCurrentTransform());

  GetCurrentPass().AddEntity(std::move(entity));
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

size_t Canvas::GetClipDepth() const {
  return transform_stack_.back().clip_depth;
}

void Canvas::SaveLayer(const Paint& paint,
                       std::optional<Rect> bounds,
                       const std::shared_ptr<ImageFilter>& backdrop_filter) {
  TRACE_EVENT0("flutter", "Canvas::saveLayer");
  Save(true, paint.blend_mode, backdrop_filter);

  // The DisplayList bounds/rtree doesn't account for filters applied to parent
  // layers, and so sub-DisplayLists are getting culled as if no filters are
  // applied.
  // See also: https://github.com/flutter/flutter/issues/139294
  if (paint.image_filter) {
    transform_stack_.back().cull_rect = std::nullopt;
  }

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
  entity.SetClipDepth(GetClipDepth());
  entity.SetBlendMode(paint.blend_mode);

  auto text_contents = std::make_shared<TextContents>();
  text_contents->SetTextFrame(text_frame);
  text_contents->SetColor(paint.color);
  text_contents->SetForceTextColor(paint.mask_blur_descriptor.has_value());

  entity.SetTransform(GetCurrentTransform() *
                      Matrix::MakeTranslation(position));

  // TODO(bdero): This mask blur application is a hack. It will always wind up
  //              doing a gaussian blur that affects the color source itself
  //              instead of just the mask. The color filter text support
  //              needs to be reworked in order to interact correctly with
  //              mask filters.
  //              https://github.com/flutter/flutter/issues/133297
  entity.SetContents(
      paint.WithFilters(paint.WithMaskBlur(std::move(text_contents), true)));

  GetCurrentPass().AddEntity(std::move(entity));
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
  entity.SetTransform(GetCurrentTransform());
  entity.SetClipDepth(GetClipDepth());
  entity.SetBlendMode(paint.blend_mode);

  // If there are no vertex color or texture coordinates. Or if there
  // are vertex coordinates then only if the contents are an image.
  if (UseColorSourceContents(vertices, paint)) {
    entity.SetContents(CreateContentsForGeometryWithFilters(paint, vertices));
    GetCurrentPass().AddEntity(std::move(entity));
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

  GetCurrentPass().AddEntity(std::move(entity));
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
  entity.SetTransform(GetCurrentTransform());
  entity.SetClipDepth(GetClipDepth());
  entity.SetBlendMode(paint.blend_mode);
  entity.SetContents(paint.WithFilters(contents));

  GetCurrentPass().AddEntity(std::move(entity));
}

}  // namespace impeller
