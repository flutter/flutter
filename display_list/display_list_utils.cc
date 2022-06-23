// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_utils.h"

#include <math.h>
#include <optional>
#include <type_traits>

#include "flutter/display_list/display_list_blend_mode.h"
#include "flutter/display_list/display_list_canvas_dispatcher.h"
#include "flutter/fml/logging.h"
#include "third_party/skia/include/core/SkMaskFilter.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkRSXform.h"
#include "third_party/skia/include/core/SkTextBlob.h"
#include "third_party/skia/include/utils/SkShadowUtils.h"

namespace flutter {

// clang-format off
constexpr float kInvertColorMatrix[20] = {
  -1.0,    0,    0, 1.0, 0,
     0, -1.0,    0, 1.0, 0,
     0,    0, -1.0, 1.0, 0,
   1.0,  1.0,  1.0, 1.0, 0
};
// clang-format on

void SkPaintDispatchHelper::save_opacity(SkScalar child_opacity) {
  save_stack_.emplace_back(opacity_);
  set_opacity(child_opacity);
}
void SkPaintDispatchHelper::restore_opacity() {
  if (save_stack_.empty()) {
    return;
  }
  set_opacity(save_stack_.back().opacity);
  save_stack_.pop_back();
}

void SkPaintDispatchHelper::setAntiAlias(bool aa) {
  paint_.setAntiAlias(aa);
}
void SkPaintDispatchHelper::setDither(bool dither) {
  paint_.setDither(dither);
}
void SkPaintDispatchHelper::setInvertColors(bool invert) {
  invert_colors_ = invert;
  paint_.setColorFilter(makeColorFilter());
}
void SkPaintDispatchHelper::setStrokeCap(DlStrokeCap cap) {
  paint_.setStrokeCap(ToSk(cap));
}
void SkPaintDispatchHelper::setStrokeJoin(DlStrokeJoin join) {
  paint_.setStrokeJoin(ToSk(join));
}
void SkPaintDispatchHelper::setStyle(DlDrawStyle style) {
  paint_.setStyle(ToSk(style));
}
void SkPaintDispatchHelper::setStrokeWidth(SkScalar width) {
  paint_.setStrokeWidth(width);
}
void SkPaintDispatchHelper::setStrokeMiter(SkScalar limit) {
  paint_.setStrokeMiter(limit);
}
void SkPaintDispatchHelper::setColor(DlColor color) {
  current_color_ = color;
  paint_.setColor(color);
  if (has_opacity()) {
    paint_.setAlphaf(paint_.getAlphaf() * opacity());
  }
}
void SkPaintDispatchHelper::setBlendMode(DlBlendMode mode) {
  paint_.setBlendMode(ToSk(mode));
}
void SkPaintDispatchHelper::setBlender(sk_sp<SkBlender> blender) {
  paint_.setBlender(blender);
}
void SkPaintDispatchHelper::setColorSource(const DlColorSource* source) {
  paint_.setShader(source ? source->skia_object() : nullptr);
}
void SkPaintDispatchHelper::setImageFilter(const DlImageFilter* filter) {
  paint_.setImageFilter(filter ? filter->skia_object() : nullptr);
}
void SkPaintDispatchHelper::setColorFilter(const DlColorFilter* filter) {
  color_filter_ = filter ? filter->shared() : nullptr;
  paint_.setColorFilter(makeColorFilter());
}
void SkPaintDispatchHelper::setPathEffect(const DlPathEffect* effect) {
  paint_.setPathEffect(effect ? effect->skia_object() : nullptr);
}
void SkPaintDispatchHelper::setMaskFilter(const DlMaskFilter* filter) {
  paint_.setMaskFilter(filter ? filter->skia_object() : nullptr);
}

sk_sp<SkColorFilter> SkPaintDispatchHelper::makeColorFilter() const {
  if (!invert_colors_) {
    return color_filter_ ? color_filter_->skia_object() : nullptr;
  }
  sk_sp<SkColorFilter> invert_filter =
      SkColorFilters::Matrix(kInvertColorMatrix);
  if (color_filter_) {
    invert_filter = invert_filter->makeComposed(color_filter_->skia_object());
  }
  return invert_filter;
}

void SkMatrixDispatchHelper::translate(SkScalar tx, SkScalar ty) {
  matrix_.preTranslate(tx, ty);
  matrix33_ = matrix_.asM33();
}
void SkMatrixDispatchHelper::scale(SkScalar sx, SkScalar sy) {
  matrix_.preScale(sx, sy);
  matrix33_ = matrix_.asM33();
}
void SkMatrixDispatchHelper::rotate(SkScalar degrees) {
  matrix33_.setRotate(degrees);
  matrix_.preConcat(matrix33_);
  matrix33_ = matrix_.asM33();
}
void SkMatrixDispatchHelper::skew(SkScalar sx, SkScalar sy) {
  matrix33_.setSkew(sx, sy);
  matrix_.preConcat(matrix33_);
  matrix33_ = matrix_.asM33();
}

// clang-format off

// 2x3 2D affine subset of a 4x4 transform in row major order
void SkMatrixDispatchHelper::transform2DAffine(
    SkScalar mxx, SkScalar mxy, SkScalar mxt,
    SkScalar myx, SkScalar myy, SkScalar myt) {
  matrix_.preConcat({
      mxx, mxy,  0 , mxt,
      myx, myy,  0 , myt,
       0 ,  0 ,  1 ,  0 ,
       0 ,  0 ,  0 ,  1 ,
  });
  matrix33_ = matrix_.asM33();
}
// full 4x4 transform in row major order
void SkMatrixDispatchHelper::transformFullPerspective(
    SkScalar mxx, SkScalar mxy, SkScalar mxz, SkScalar mxt,
    SkScalar myx, SkScalar myy, SkScalar myz, SkScalar myt,
    SkScalar mzx, SkScalar mzy, SkScalar mzz, SkScalar mzt,
    SkScalar mwx, SkScalar mwy, SkScalar mwz, SkScalar mwt) {
  matrix_.preConcat({
      mxx, mxy, mxz, mxt,
      myx, myy, myz, myt,
      mzx, mzy, mzz, mzt,
      mwx, mwy, mwz, mwt,
  });
  matrix33_ = matrix_.asM33();
}

// clang-format on

void SkMatrixDispatchHelper::transformReset() {
  matrix_ = {};
  matrix33_ = {};
}

void SkMatrixDispatchHelper::save() {
  saved_.push_back(matrix_);
}
void SkMatrixDispatchHelper::restore() {
  if (saved_.empty()) {
    return;
  }
  matrix_ = saved_.back();
  matrix33_ = matrix_.asM33();
  saved_.pop_back();
}
void SkMatrixDispatchHelper::reset() {
  matrix_.setIdentity();
  matrix33_ = matrix_.asM33();
}

void ClipBoundsDispatchHelper::clipRect(const SkRect& rect,
                                        SkClipOp clip_op,
                                        bool is_aa) {
  switch (clip_op) {
    case SkClipOp::kIntersect:
      intersect(rect, is_aa);
      break;
    case SkClipOp::kDifference:
      break;
  }
}
void ClipBoundsDispatchHelper::clipRRect(const SkRRect& rrect,
                                         SkClipOp clip_op,
                                         bool is_aa) {
  switch (clip_op) {
    case SkClipOp::kIntersect:
      intersect(rrect.getBounds(), is_aa);
      break;
    case SkClipOp::kDifference:
      break;
  }
}
void ClipBoundsDispatchHelper::clipPath(const SkPath& path,
                                        SkClipOp clip_op,
                                        bool is_aa) {
  switch (clip_op) {
    case SkClipOp::kIntersect:
      intersect(path.getBounds(), is_aa);
      break;
    case SkClipOp::kDifference:
      break;
  }
}
void ClipBoundsDispatchHelper::intersect(const SkRect& rect, bool is_aa) {
  SkRect devClipBounds = matrix().mapRect(rect);
  if (is_aa) {
    devClipBounds.roundOut(&devClipBounds);
  }
  if (has_clip_) {
    if (!bounds_.intersect(devClipBounds)) {
      bounds_.setEmpty();
    }
  } else {
    has_clip_ = true;
    if (devClipBounds.isEmpty()) {
      bounds_.setEmpty();
    } else {
      bounds_ = devClipBounds;
    }
  }
}
void ClipBoundsDispatchHelper::save() {
  if (!has_clip_) {
    saved_.push_back(SkRect::MakeLTRB(0, 0, -1, -1));
  } else if (bounds_.isEmpty()) {
    saved_.push_back(SkRect::MakeEmpty());
  } else {
    saved_.push_back(bounds_);
  }
}
void ClipBoundsDispatchHelper::restore() {
  if (saved_.empty()) {
    return;
  }
  bounds_ = saved_.back();
  saved_.pop_back();
  has_clip_ = (bounds_.fLeft <= bounds_.fRight &&  //
               bounds_.fTop <= bounds_.fBottom);
  if (!has_clip_) {
    bounds_.setEmpty();
  }
}
void ClipBoundsDispatchHelper::reset(const SkRect* cull_rect) {
  if ((has_clip_ = cull_rect != nullptr) && !cull_rect->isEmpty()) {
    bounds_ = *cull_rect;
  } else {
    bounds_.setEmpty();
  }
}

DisplayListBoundsCalculator::DisplayListBoundsCalculator(
    const SkRect* cull_rect)
    : ClipBoundsDispatchHelper(cull_rect) {
  layer_infos_.emplace_back(std::make_unique<LayerData>(nullptr));
  accumulator_ = layer_infos_.back()->layer_accumulator();
}
void DisplayListBoundsCalculator::setStrokeCap(DlStrokeCap cap) {
  cap_is_square_ = (cap == DlStrokeCap::kSquare);
}
void DisplayListBoundsCalculator::setStrokeJoin(DlStrokeJoin join) {
  join_is_miter_ = (join == DlStrokeJoin::kMiter);
}
void DisplayListBoundsCalculator::setStyle(DlDrawStyle style) {
  style_ = style;
}
void DisplayListBoundsCalculator::setStrokeWidth(SkScalar width) {
  half_stroke_width_ = std::max(width * 0.5f, kMinStrokeWidth);
}
void DisplayListBoundsCalculator::setStrokeMiter(SkScalar limit) {
  miter_limit_ = std::max(limit, 1.0f);
}
void DisplayListBoundsCalculator::setBlendMode(DlBlendMode mode) {
  blend_mode_ = mode;
}
void DisplayListBoundsCalculator::setBlender(sk_sp<SkBlender> blender) {
  SkPaint paint;
  paint.setBlender(std::move(blender));
  auto blend_mode = paint.asBlendMode();
  if (blend_mode.has_value()) {
    blend_mode_ = ToDl(blend_mode.value());
  } else {
    blend_mode_ = std::nullopt;
  }
}
void DisplayListBoundsCalculator::setImageFilter(const DlImageFilter* filter) {
  image_filter_ = filter ? filter->shared() : nullptr;
}
void DisplayListBoundsCalculator::setColorFilter(const DlColorFilter* filter) {
  color_filter_ = filter ? filter->shared() : nullptr;
}
void DisplayListBoundsCalculator::setPathEffect(const DlPathEffect* effect) {
  path_effect_ = effect ? effect->shared() : nullptr;
}
void DisplayListBoundsCalculator::setMaskFilter(const DlMaskFilter* filter) {
  mask_filter_ = filter ? filter->shared() : nullptr;
}
void DisplayListBoundsCalculator::save() {
  SkMatrixDispatchHelper::save();
  ClipBoundsDispatchHelper::save();
  layer_infos_.emplace_back(std::make_unique<LayerData>(accumulator_));
  accumulator_ = layer_infos_.back()->layer_accumulator();
}
void DisplayListBoundsCalculator::saveLayer(const SkRect* bounds,
                                            const SaveLayerOptions options,
                                            const DlImageFilter* backdrop) {
  SkMatrixDispatchHelper::save();
  ClipBoundsDispatchHelper::save();
  if (options.renders_with_attributes()) {
    // The actual flood of the outer layer clip will occur after the
    // (eventual) corresponding restore is called, but rather than
    // remember this information in the LayerInfo until the restore
    // method is processed, we just mark the unbounded state up front.
    if (!paint_nops_on_transparency()) {
      // We will fill the clip of the outer layer when we restore
      AccumulateUnbounded();
    }

    layer_infos_.emplace_back(
        std::make_unique<LayerData>(accumulator_, image_filter_));
  } else {
    layer_infos_.emplace_back(
        std::make_unique<LayerData>(accumulator_, nullptr));
  }

  accumulator_ = layer_infos_.back()->layer_accumulator();

  // Even though Skia claims that the bounds are only a hint, they actually
  // use them as the temporary layer bounds during rendering the layer, so
  // we set them as if a clip operation were performed.
  if (bounds) {
    clipRect(*bounds, SkClipOp::kIntersect, false);
  }
  if (backdrop) {
    // A backdrop will affect up to the entire surface, bounded by the clip
    AccumulateUnbounded();
  }
}
void DisplayListBoundsCalculator::restore() {
  if (layer_infos_.size() > 1) {
    SkMatrixDispatchHelper::restore();
    ClipBoundsDispatchHelper::restore();

    // Remember a few pieces of information from the current layer info
    // for later processing.
    LayerData* layer_info = layer_infos_.back().get();
    BoundsAccumulator* outer_accumulator = layer_info->restore_accumulator();
    bool is_unbounded = layer_info->is_unbounded();

    // Before we pop_back we will get the current layer bounds from the
    // current accumulator and adjust ot as required based on the filter.
    SkRect layer_bounds = accumulator_->bounds();
    std::shared_ptr<DlImageFilter> filter = layer_info->filter();
    if (filter) {
      SkIRect filter_bounds;
      if (filter->map_device_bounds(layer_bounds.roundOut(), matrix(),
                                    filter_bounds)) {
        layer_bounds.set(filter_bounds);

        // We could leave the clipping to the code below that will
        // finally accumulate the layer bounds, but the bounds do
        // not normally need clipping unless they were modified by
        // entering this filtering code path.
        if (has_clip() && !layer_bounds.intersect(clip_bounds())) {
          layer_bounds.setEmpty();
        }
      } else {
        // If the filter cannot compute bounds then it might take an
        // unbounded amount of space. This can sometimes happen if it
        // modifies transparent black which means its affect will not
        // be bounded by the transparent pixels outside of the layer
        // drawable.
        is_unbounded = true;
      }
    }

    // Restore the accumulator before popping the LayerInfo so that
    // it nevers points to an out of scope instance.
    accumulator_ = outer_accumulator;
    layer_infos_.pop_back();

    // Finally accumulate the impact of the layer into the new scope.
    // Note that the bounds were already accumulated in device pixels
    // and clipped to any clips involved so we do not need to go
    // through any transforms or clips to accuulate them into this
    // layer.
    accumulator_->accumulate(layer_bounds);
    if (is_unbounded) {
      AccumulateUnbounded();
    }
  }
}

void DisplayListBoundsCalculator::drawPaint() {
  AccumulateUnbounded();
}
void DisplayListBoundsCalculator::drawColor(DlColor color, DlBlendMode mode) {
  AccumulateUnbounded();
}
void DisplayListBoundsCalculator::drawLine(const SkPoint& p0,
                                           const SkPoint& p1) {
  SkRect bounds = SkRect::MakeLTRB(p0.fX, p0.fY, p1.fX, p1.fY).makeSorted();
  DisplayListAttributeFlags flags =
      (bounds.width() > 0.0f && bounds.height() > 0.0f) ? kDrawLineFlags
                                                        : kDrawHVLineFlags;
  AccumulateOpBounds(bounds, flags);
}
void DisplayListBoundsCalculator::drawRect(const SkRect& rect) {
  AccumulateOpBounds(rect, kDrawRectFlags);
}
void DisplayListBoundsCalculator::drawOval(const SkRect& bounds) {
  AccumulateOpBounds(bounds, kDrawOvalFlags);
}
void DisplayListBoundsCalculator::drawCircle(const SkPoint& center,
                                             SkScalar radius) {
  AccumulateOpBounds(SkRect::MakeLTRB(center.fX - radius, center.fY - radius,
                                      center.fX + radius, center.fY + radius),
                     kDrawCircleFlags);
}
void DisplayListBoundsCalculator::drawRRect(const SkRRect& rrect) {
  AccumulateOpBounds(rrect.getBounds(), kDrawRRectFlags);
}
void DisplayListBoundsCalculator::drawDRRect(const SkRRect& outer,
                                             const SkRRect& inner) {
  AccumulateOpBounds(outer.getBounds(), kDrawDRRectFlags);
}
void DisplayListBoundsCalculator::drawPath(const SkPath& path) {
  if (path.isInverseFillType()) {
    AccumulateUnbounded();
  } else {
    AccumulateOpBounds(path.getBounds(), kDrawPathFlags);
  }
}
void DisplayListBoundsCalculator::drawArc(const SkRect& bounds,
                                          SkScalar start,
                                          SkScalar sweep,
                                          bool useCenter) {
  // This could be tighter if we compute where the start and end
  // angles are and then also consider the quadrants swept and
  // the center if specified.
  AccumulateOpBounds(bounds,
                     useCenter  //
                         ? kDrawArcWithCenterFlags
                         : kDrawArcNoCenterFlags);
}
void DisplayListBoundsCalculator::drawPoints(SkCanvas::PointMode mode,
                                             uint32_t count,
                                             const SkPoint pts[]) {
  if (count > 0) {
    BoundsAccumulator ptBounds;
    for (size_t i = 0; i < count; i++) {
      ptBounds.accumulate(pts[i]);
    }
    SkRect point_bounds = ptBounds.bounds();
    switch (mode) {
      case SkCanvas::kPoints_PointMode:
        AccumulateOpBounds(point_bounds, kDrawPointsAsPointsFlags);
        break;
      case SkCanvas::kLines_PointMode:
        AccumulateOpBounds(point_bounds, kDrawPointsAsLinesFlags);
        break;
      case SkCanvas::kPolygon_PointMode:
        AccumulateOpBounds(point_bounds, kDrawPointsAsPolygonFlags);
        break;
    }
  }
}
void DisplayListBoundsCalculator::drawSkVertices(
    const sk_sp<SkVertices> vertices,
    SkBlendMode mode) {
  AccumulateOpBounds(vertices->bounds(), kDrawVerticesFlags);
}
void DisplayListBoundsCalculator::drawVertices(const DlVertices* vertices,
                                               DlBlendMode mode) {
  AccumulateOpBounds(vertices->bounds(), kDrawVerticesFlags);
}
void DisplayListBoundsCalculator::drawImage(const sk_sp<DlImage> image,
                                            const SkPoint point,
                                            DlImageSampling sampling,
                                            bool render_with_attributes) {
  SkRect bounds = SkRect::MakeXYWH(point.fX, point.fY,  //
                                   image->width(), image->height());
  DisplayListAttributeFlags flags = render_with_attributes  //
                                        ? kDrawImageWithPaintFlags
                                        : kDrawImageFlags;
  AccumulateOpBounds(bounds, flags);
}
void DisplayListBoundsCalculator::drawImageRect(
    const sk_sp<DlImage> image,
    const SkRect& src,
    const SkRect& dst,
    DlImageSampling sampling,
    bool render_with_attributes,
    SkCanvas::SrcRectConstraint constraint) {
  DisplayListAttributeFlags flags = render_with_attributes
                                        ? kDrawImageRectWithPaintFlags
                                        : kDrawImageRectFlags;
  AccumulateOpBounds(dst, flags);
}
void DisplayListBoundsCalculator::drawImageNine(const sk_sp<DlImage> image,
                                                const SkIRect& center,
                                                const SkRect& dst,
                                                DlFilterMode filter,
                                                bool render_with_attributes) {
  DisplayListAttributeFlags flags = render_with_attributes
                                        ? kDrawImageNineWithPaintFlags
                                        : kDrawImageNineFlags;
  AccumulateOpBounds(dst, flags);
}
void DisplayListBoundsCalculator::drawImageLattice(
    const sk_sp<DlImage> image,
    const SkCanvas::Lattice& lattice,
    const SkRect& dst,
    DlFilterMode filter,
    bool render_with_attributes) {
  DisplayListAttributeFlags flags = render_with_attributes
                                        ? kDrawImageLatticeWithPaintFlags
                                        : kDrawImageLatticeFlags;
  AccumulateOpBounds(dst, flags);
}
void DisplayListBoundsCalculator::drawAtlas(const sk_sp<DlImage> atlas,
                                            const SkRSXform xform[],
                                            const SkRect tex[],
                                            const DlColor colors[],
                                            int count,
                                            DlBlendMode mode,
                                            DlImageSampling sampling,
                                            const SkRect* cullRect,
                                            bool render_with_attributes) {
  SkPoint quad[4];
  BoundsAccumulator atlasBounds;
  for (int i = 0; i < count; i++) {
    const SkRect& src = tex[i];
    xform[i].toQuad(src.width(), src.height(), quad);
    for (int j = 0; j < 4; j++) {
      atlasBounds.accumulate(quad[j]);
    }
  }
  if (atlasBounds.is_not_empty()) {
    DisplayListAttributeFlags flags = render_with_attributes  //
                                          ? kDrawAtlasWithPaintFlags
                                          : kDrawAtlasFlags;
    AccumulateOpBounds(atlasBounds.bounds(), flags);
  }
}
void DisplayListBoundsCalculator::drawPicture(const sk_sp<SkPicture> picture,
                                              const SkMatrix* pic_matrix,
                                              bool render_with_attributes) {
  // TODO(flar) cull rect really cannot be trusted in general, but it will
  // work for SkPictures generated from our own PictureRecorder or any
  // picture captured with an SkRTreeFactory or accurate bounds estimate.
  SkRect bounds = picture->cullRect();
  if (pic_matrix) {
    pic_matrix->mapRect(&bounds);
  }
  DisplayListAttributeFlags flags = render_with_attributes  //
                                        ? kDrawPictureWithPaintFlags
                                        : kDrawPictureFlags;
  AccumulateOpBounds(bounds, flags);
}
void DisplayListBoundsCalculator::drawDisplayList(
    const sk_sp<DisplayList> display_list) {
  AccumulateOpBounds(display_list->bounds(), kDrawDisplayListFlags);
}
void DisplayListBoundsCalculator::drawTextBlob(const sk_sp<SkTextBlob> blob,
                                               SkScalar x,
                                               SkScalar y) {
  AccumulateOpBounds(blob->bounds().makeOffset(x, y), kDrawTextBlobFlags);
}
void DisplayListBoundsCalculator::drawShadow(const SkPath& path,
                                             const DlColor color,
                                             const SkScalar elevation,
                                             bool transparent_occluder,
                                             SkScalar dpr) {
  SkRect shadow_bounds = DisplayListCanvasDispatcher::ComputeShadowBounds(
      path, elevation, dpr, matrix());
  AccumulateOpBounds(shadow_bounds, kDrawShadowFlags);
}

bool DisplayListBoundsCalculator::ComputeFilteredBounds(SkRect& bounds,
                                                        DlImageFilter* filter) {
  if (filter) {
    if (!filter->map_local_bounds(bounds, bounds)) {
      return false;
    }
  }
  return true;
}

bool DisplayListBoundsCalculator::AdjustBoundsForPaint(
    SkRect& bounds,
    DisplayListAttributeFlags flags) {
  if (flags.ignores_paint()) {
    return true;
  }

  if (flags.is_geometric()) {
    // Path effect occurs before stroking...
    DisplayListSpecialGeometryFlags special_flags =
        flags.WithPathEffect(path_effect_.get());
    if (path_effect_) {
      auto effect_bounds = path_effect_->effect_bounds(bounds);
      if (!effect_bounds.has_value()) {
        return false;
      }
      bounds = effect_bounds.value();
    }

    if (flags.is_stroked(style_)) {
      // Determine the max multiplier to the stroke width first.
      SkScalar pad = 1.0f;
      if (join_is_miter_ && special_flags.may_have_acute_joins()) {
        pad = std::max(pad, miter_limit_);
      }
      if (cap_is_square_ && special_flags.may_have_diagonal_caps()) {
        pad = std::max(pad, SK_ScalarSqrt2);
      }
      pad *= half_stroke_width_;
      bounds.outset(pad, pad);
    }
  }

  if (flags.applies_mask_filter()) {
    if (mask_filter_) {
      const DlBlurMaskFilter* blur_filter = mask_filter_->asBlur();
      if (blur_filter) {
        SkScalar mask_sigma_pad = blur_filter->sigma() * 3.0;
        bounds.outset(mask_sigma_pad, mask_sigma_pad);
      } else {
        SkPaint p;
        p.setMaskFilter(mask_filter_->skia_object());
        if (!p.canComputeFastBounds()) {
          return false;
        }
        bounds = p.computeFastBounds(bounds, &bounds);
      }
    }
  }

  if (flags.applies_image_filter()) {
    return ComputeFilteredBounds(bounds, image_filter_.get());
  }

  return true;
}

void DisplayListBoundsCalculator::AccumulateUnbounded() {
  if (has_clip()) {
    accumulator_->accumulate(clip_bounds());
  } else {
    layer_infos_.back()->set_unbounded();
  }
}
void DisplayListBoundsCalculator::AccumulateOpBounds(
    SkRect& bounds,
    DisplayListAttributeFlags flags) {
  if (AdjustBoundsForPaint(bounds, flags)) {
    AccumulateBounds(bounds);
  } else {
    AccumulateUnbounded();
  }
}
void DisplayListBoundsCalculator::AccumulateBounds(SkRect& bounds) {
  matrix().mapRect(&bounds);
  if (!has_clip() || bounds.intersect(clip_bounds())) {
    accumulator_->accumulate(bounds);
  }
}

bool DisplayListBoundsCalculator::paint_nops_on_transparency() {
  // SkImageFilter::canComputeFastBounds tests for transparency behavior
  // This test assumes that the blend mode checked down below will
  // NOP on transparent black.
  if (image_filter_ && image_filter_->modifies_transparent_black()) {
    return false;
  }

  // We filter the transparent black that is used for the background of a
  // saveLayer and make sure it returns transparent black. If it does, then
  // the color filter will leave all area surrounding the contents of the
  // save layer untouched out to the edge of the output surface.
  // This test assumes that the blend mode checked down below will
  // NOP on transparent black.
  if (color_filter_ && color_filter_->modifies_transparent_black()) {
    return false;
  }

  if (!blend_mode_) {
    return false;  // can we query other blenders for this?
  }
  // Unusual blendmodes require us to process a saved layer
  // even with operations outisde the clip.
  // For example, DstIn is used by masking layers.
  // https://code.google.com/p/skia/issues/detail?id=1291
  // https://crbug.com/401593
  switch (blend_mode_.value()) {
    // For each of the following transfer modes, if the source
    // alpha is zero (our transparent black), the resulting
    // blended pixel is not necessarily equal to the original
    // destination pixel.
    // Mathematically, any time in the following equations where
    // the result is not d assuming source is 0
    case DlBlendMode::kClear:     // r = 0
    case DlBlendMode::kSrc:       // r = s
    case DlBlendMode::kSrcIn:     // r = s * da
    case DlBlendMode::kDstIn:     // r = d * sa
    case DlBlendMode::kSrcOut:    // r = s * (1-da)
    case DlBlendMode::kDstATop:   // r = d*sa + s*(1-da)
    case DlBlendMode::kModulate:  // r = s*d
      return false;
      break;

    // And in these equations, the result must be d if the
    // source is 0
    case DlBlendMode::kDst:         // r = d
    case DlBlendMode::kSrcOver:     // r = s + (1-sa)*d
    case DlBlendMode::kDstOver:     // r = d + (1-da)*s
    case DlBlendMode::kDstOut:      // r = d * (1-sa)
    case DlBlendMode::kSrcATop:     // r = s*da + d*(1-sa)
    case DlBlendMode::kXor:         // r = s*(1-da) + d*(1-sa)
    case DlBlendMode::kPlus:        // r = min(s + d, 1)
    case DlBlendMode::kScreen:      // r = s + d - s*d
    case DlBlendMode::kOverlay:     // multiply or screen, depending on dest
    case DlBlendMode::kDarken:      // rc = s + d - max(s*da, d*sa),
                                    // ra = kSrcOver
    case DlBlendMode::kLighten:     // rc = s + d - min(s*da, d*sa),
                                    // ra = kSrcOver
    case DlBlendMode::kColorDodge:  // brighten destination to reflect source
    case DlBlendMode::kColorBurn:   // darken destination to reflect source
    case DlBlendMode::kHardLight:   // multiply or screen, depending on source
    case DlBlendMode::kSoftLight:   // lighten or darken, depending on source
    case DlBlendMode::kDifference:  // rc = s + d - 2*(min(s*da, d*sa)),
                                    // ra = kSrcOver
    case DlBlendMode::kExclusion:   // rc = s + d - two(s*d), ra = kSrcOver
    case DlBlendMode::kMultiply:    // r = s*(1-da) + d*(1-sa) + s*d
    case DlBlendMode::kHue:         // ra = kSrcOver
    case DlBlendMode::kSaturation:  // ra = kSrcOver
    case DlBlendMode::kColor:       // ra = kSrcOver
    case DlBlendMode::kLuminosity:  // ra = kSrcOver
      return true;
      break;
  }
}

}  // namespace flutter
