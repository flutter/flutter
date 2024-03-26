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

  bool can_apply_mask_filter = geometry->CanApplyMaskFilter();
  contents->SetGeometry(std::move(geometry));

  if (can_apply_mask_filter && paint.mask_blur_descriptor.has_value()) {
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
    const Path& path) {
  std::shared_ptr<Geometry> geometry;
  switch (paint.style) {
    case Paint::Style::kFill:
      geometry = Geometry::MakeFillPath(path);
      break;
    case Paint::Style::kStroke:
      geometry =
          Geometry::MakeStrokePath(path, paint.stroke_width, paint.stroke_miter,
                                   paint.stroke_cap, paint.stroke_join);
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
  base_pass_->SetNewClipDepth(++current_depth_);
  current_pass_ = base_pass_.get();
  transform_stack_.emplace_back(CanvasStackEntry{.cull_rect = cull_rect});
  FML_DCHECK(GetSaveCount() == 1u);
  FML_DCHECK(base_pass_->GetSubpassesDepth() == 1u);
}

void Canvas::Reset() {
  base_pass_ = nullptr;
  current_pass_ = nullptr;
  current_depth_ = 0u;
  transform_stack_ = {};
}

void Canvas::Save() {
  Save(false);
}

namespace {
class MipCountVisitor : public ImageFilterVisitor {
 public:
  virtual void Visit(const BlurImageFilter& filter) {
    required_mip_count_ = FilterContents::kBlurFilterRequiredMipCount;
  }
  virtual void Visit(const LocalMatrixImageFilter& filter) {
    required_mip_count_ = 1;
  }
  virtual void Visit(const DilateImageFilter& filter) {
    required_mip_count_ = 1;
  }
  virtual void Visit(const ErodeImageFilter& filter) {
    required_mip_count_ = 1;
  }
  virtual void Visit(const MatrixImageFilter& filter) {
    required_mip_count_ = 1;
  }
  virtual void Visit(const ComposeImageFilter& filter) {
    required_mip_count_ = 1;
  }
  virtual void Visit(const ColorImageFilter& filter) {
    required_mip_count_ = 1;
  }
  int32_t GetRequiredMipCount() const { return required_mip_count_; }

 private:
  int32_t required_mip_count_ = -1;
};
}  // namespace

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
      MipCountVisitor mip_count_visitor;
      backdrop_filter->Visit(mip_count_visitor);
      current_pass_->SetRequiredMipCount(
          std::max(current_pass_->GetRequiredMipCount(),
                   mip_count_visitor.GetRequiredMipCount()));
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
  size_t num_clips = transform_stack_.back().num_clips;
  current_pass_->PopClips(num_clips, current_depth_);

  if (transform_stack_.back().rendering_mode ==
      Entity::RenderingMode::kSubpass) {
    current_pass_->SetNewClipDepth(++current_depth_);
    current_pass_ = GetCurrentPass().GetSuperpass();
    FML_DCHECK(current_pass_);
  }

  transform_stack_.pop_back();
  if (num_clips > 0) {
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

void Canvas::DrawPath(const Path& path, const Paint& paint) {
  Entity entity;
  entity.SetTransform(GetCurrentTransform());
  entity.SetClipDepth(GetClipDepth());
  entity.SetBlendMode(paint.blend_mode);
  entity.SetContents(CreatePathContentsWithFilters(paint, path));

  AddEntityToCurrentPass(std::move(entity));
}

void Canvas::DrawPaint(const Paint& paint) {
  Entity entity;
  entity.SetTransform(GetCurrentTransform());
  entity.SetClipDepth(GetClipDepth());
  entity.SetBlendMode(paint.blend_mode);
  entity.SetContents(CreateCoverContentsWithFilters(paint));

  AddEntityToCurrentPass(std::move(entity));
}

bool Canvas::AttemptDrawBlurredRRect(const Rect& rect,
                                     Size corner_radii,
                                     const Paint& paint) {
  if (paint.color_source.GetType() != ColorSource::Type::kColor ||
      paint.style != Paint::Style::kFill) {
    return false;
  }

  if (!paint.mask_blur_descriptor.has_value()) {
    return false;
  }

  // A blur sigma that is not positive enough should not result in a blur.
  if (paint.mask_blur_descriptor->sigma.sigma <= kEhCloseEnough) {
    return false;
  }

  // For symmetrically mask blurred solid RRects, absorb the mask blur and use
  // a faster SDF approximation.

  Color rrect_color =
      paint.HasColorFilter()
          // Absorb the color filter, if any.
          ? paint.GetColorFilter()->GetCPUColorFilterProc()(paint.color)
          : paint.color;

  Paint rrect_paint = {.mask_blur_descriptor = paint.mask_blur_descriptor};

  // In some cases, we need to render the mask blur to a separate layer.
  //
  //   1. If the blur style is normal, we'll be drawing using one draw call and
  //      no clips. And so we can just wrap the RRect contents with the
  //      ImageFilter, which will get applied to the result as per usual.
  //
  //   2. If the blur style is solid, we combine the non-blurred RRect with the
  //      blurred RRect via two separate draw calls, and so we need to defer any
  //      fancy blending, translucency, or image filtering until after these two
  //      draws have been combined in a separate layer.
  //
  //   3. If the blur style is outer or inner, we apply the blur style via a
  //      clip. The ImageFilter needs to be applied to the mask blurred result.
  //      And so if there's an ImageFilter, we need to defer applying it until
  //      after the clipped RRect blur has been drawn to a separate texture.
  //      However, since there's only one draw call that produces color, we
  //      don't need to worry about the blend mode or translucency (unlike with
  //      BlurStyle::kSolid).
  //
  if ((paint.mask_blur_descriptor->style !=
           FilterContents::BlurStyle::kNormal &&
       paint.image_filter) ||
      (paint.mask_blur_descriptor->style == FilterContents::BlurStyle::kSolid &&
       (!rrect_color.IsOpaque() ||
        paint.blend_mode != BlendMode::kSourceOver))) {
    // Defer the alpha, blend mode, and image filter to a separate layer.
    SaveLayer({.color = Color::White().WithAlpha(rrect_color.alpha),
               .blend_mode = paint.blend_mode,
               .image_filter = paint.image_filter});
    rrect_paint.color = rrect_color.WithAlpha(1);
  } else {
    rrect_paint.color = rrect_color;
    rrect_paint.blend_mode = paint.blend_mode;
    rrect_paint.image_filter = paint.image_filter;
    Save();
  }

  auto draw_blurred_rrect = [this, &rect, &corner_radii, &rrect_paint]() {
    auto contents = std::make_shared<SolidRRectBlurContents>();

    contents->SetColor(rrect_paint.color);
    contents->SetSigma(rrect_paint.mask_blur_descriptor->sigma);
    contents->SetRRect(rect, corner_radii);

    Entity blurred_rrect_entity;
    blurred_rrect_entity.SetTransform(GetCurrentTransform());
    blurred_rrect_entity.SetClipDepth(GetClipDepth());
    blurred_rrect_entity.SetBlendMode(rrect_paint.blend_mode);

    rrect_paint.mask_blur_descriptor = std::nullopt;
    blurred_rrect_entity.SetContents(
        rrect_paint.WithFilters(std::move(contents)));
    AddEntityToCurrentPass(std::move(blurred_rrect_entity));
  };

  switch (rrect_paint.mask_blur_descriptor->style) {
    case FilterContents::BlurStyle::kNormal: {
      draw_blurred_rrect();
      break;
    }
    case FilterContents::BlurStyle::kSolid: {
      // First, draw the blurred RRect.
      draw_blurred_rrect();
      // Then, draw the non-blurred RRect on top.
      Entity entity;
      entity.SetTransform(GetCurrentTransform());
      entity.SetClipDepth(GetClipDepth());
      entity.SetBlendMode(rrect_paint.blend_mode);
      entity.SetContents(CreateContentsForGeometryWithFilters(
          rrect_paint, Geometry::MakeRoundRect(rect, corner_radii)));
      AddEntityToCurrentPass(std::move(entity));
      break;
    }
    case FilterContents::BlurStyle::kOuter: {
      ClipRRect(rect, corner_radii, Entity::ClipOperation::kDifference);
      draw_blurred_rrect();
      break;
    }
    case FilterContents::BlurStyle::kInner: {
      ClipRRect(rect, corner_radii, Entity::ClipOperation::kIntersect);
      draw_blurred_rrect();
      break;
    }
  }

  Restore();

  return true;
}

void Canvas::DrawLine(const Point& p0, const Point& p1, const Paint& paint) {
  Entity entity;
  entity.SetTransform(GetCurrentTransform());
  entity.SetClipDepth(GetClipDepth());
  entity.SetBlendMode(paint.blend_mode);
  entity.SetContents(CreateContentsForGeometryWithFilters(
      paint, Geometry::MakeLine(p0, p1, paint.stroke_width, paint.stroke_cap)));

  AddEntityToCurrentPass(std::move(entity));
}

void Canvas::DrawRect(const Rect& rect, const Paint& paint) {
  if (paint.style == Paint::Style::kStroke) {
    DrawPath(PathBuilder{}.AddRect(rect).TakePath(), paint);
    return;
  }

  if (AttemptDrawBlurredRRect(rect, {}, paint)) {
    return;
  }

  Entity entity;
  entity.SetTransform(GetCurrentTransform());
  entity.SetClipDepth(GetClipDepth());
  entity.SetBlendMode(paint.blend_mode);
  entity.SetContents(
      CreateContentsForGeometryWithFilters(paint, Geometry::MakeRect(rect)));

  AddEntityToCurrentPass(std::move(entity));
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

  if (AttemptDrawBlurredRRect(rect, rect.GetSize() * 0.5f, paint)) {
    return;
  }

  Entity entity;
  entity.SetTransform(GetCurrentTransform());
  entity.SetClipDepth(GetClipDepth());
  entity.SetBlendMode(paint.blend_mode);
  entity.SetContents(
      CreateContentsForGeometryWithFilters(paint, Geometry::MakeOval(rect)));

  AddEntityToCurrentPass(std::move(entity));
}

void Canvas::DrawRRect(const Rect& rect,
                       const Size& corner_radii,
                       const Paint& paint) {
  if (AttemptDrawBlurredRRect(rect, corner_radii, paint)) {
    return;
  }

  if (paint.style == Paint::Style::kFill) {
    Entity entity;
    entity.SetTransform(GetCurrentTransform());
    entity.SetClipDepth(GetClipDepth());
    entity.SetBlendMode(paint.blend_mode);
    entity.SetContents(CreateContentsForGeometryWithFilters(
        paint, Geometry::MakeRoundRect(rect, corner_radii)));

    AddEntityToCurrentPass(std::move(entity));
    return;
  }

  auto path = PathBuilder{}
                  .SetConvexity(Convexity::kConvex)
                  .AddRoundedRect(rect, corner_radii)
                  .SetBounds(rect)
                  .TakePath();
  DrawPath(path, paint);
}

void Canvas::DrawCircle(const Point& center,
                        Scalar radius,
                        const Paint& paint) {
  Size half_size(radius, radius);
  if (AttemptDrawBlurredRRect(
          Rect::MakeOriginSize(center - half_size, half_size * 2),
          {radius, radius}, paint)) {
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

  AddEntityToCurrentPass(std::move(entity));
}

void Canvas::ClipPath(const Path& path, Entity::ClipOperation clip_op) {
  auto bounds = path.GetBoundingBox();
  ClipGeometry(Geometry::MakeFillPath(path), clip_op);
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

  GetCurrentPass().PushClip(std::move(entity));

  ++transform_stack_.back().clip_depth;
  ++transform_stack_.back().num_clips;
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

  AddEntityToCurrentPass(std::move(entity));
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

  AddEntityToCurrentPass(std::move(entity));
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
                           SamplerDescriptor sampler,
                           SourceRectConstraint src_rect_constraint) {
  if (!image || source.IsEmpty() || dest.IsEmpty()) {
    return;
  }

  auto size = image->GetSize();

  if (size.IsEmpty()) {
    return;
  }

  auto texture_contents = TextureContents::MakeRect(dest);
  texture_contents->SetTexture(image->GetTexture());
  texture_contents->SetSourceRect(source);
  texture_contents->SetStrictSourceRect(src_rect_constraint ==
                                        SourceRectConstraint::kStrict);
  texture_contents->SetSamplerDescriptor(std::move(sampler));
  texture_contents->SetOpacity(paint.color.alpha);
  texture_contents->SetDeferApplyingOpacity(paint.HasColorFilter());

  std::shared_ptr<Contents> contents = texture_contents;
  if (paint.mask_blur_descriptor.has_value()) {
    contents = paint.mask_blur_descriptor->CreateMaskBlur(texture_contents);
  }

  Entity entity;
  entity.SetBlendMode(paint.blend_mode);
  entity.SetClipDepth(GetClipDepth());
  entity.SetContents(paint.WithFilters(contents));
  entity.SetTransform(GetCurrentTransform());

  AddEntityToCurrentPass(std::move(entity));
}

Picture Canvas::EndRecordingAsPicture() {
  // Assign clip depths to any outstanding clip entities.
  while (current_pass_ != nullptr) {
    current_pass_->PopAllClips(current_depth_);
    current_pass_ = current_pass_->GetSuperpass();
  }

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

void Canvas::AddEntityToCurrentPass(Entity entity) {
  entity.SetNewClipDepth(++current_depth_);
  GetCurrentPass().AddEntity(std::move(entity));
}

void Canvas::SaveLayer(const Paint& paint,
                       std::optional<Rect> bounds,
                       const std::shared_ptr<ImageFilter>& backdrop_filter,
                       ContentBoundsPromise bounds_promise) {
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
  if (bounds) {
    new_layer_pass.SetBoundsLimit(bounds, bounds_promise);
  }

  if (paint.image_filter) {
    MipCountVisitor mip_count_visitor;
    paint.image_filter->Visit(mip_count_visitor);
    new_layer_pass.SetRequiredMipCount(mip_count_visitor.GetRequiredMipCount());
  }

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

  AddEntityToCurrentPass(std::move(entity));
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
    AddEntityToCurrentPass(std::move(entity));
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

  AddEntityToCurrentPass(std::move(entity));
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

  AddEntityToCurrentPass(std::move(entity));
}

}  // namespace impeller
