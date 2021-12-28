// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_utils.h"

#include <math.h>
#include <type_traits>

#include "flutter/display_list/display_list_canvas_dispatcher.h"
#include "flutter/fml/logging.h"
#include "third_party/skia/include/core/SkMaskFilter.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkRSXform.h"
#include "third_party/skia/include/core/SkTextBlob.h"
#include "third_party/skia/include/utils/SkShadowUtils.h"

namespace flutter {

// clang-format off
constexpr float invert_color_matrix[20] = {
  -1.0,    0,    0, 1.0, 0,
     0, -1.0,    0, 1.0, 0,
     0,    0, -1.0, 1.0, 0,
   1.0,  1.0,  1.0, 1.0, 0
};
// clang-format on

void SkPaintDispatchHelper::save_opacity(bool reset_and_restore) {
  if (opacity_ >= SK_Scalar1) {
    reset_and_restore = false;
  }
  save_stack_.emplace_back(opacity_, reset_and_restore);
  if (reset_and_restore) {
    opacity_ = SK_Scalar1;
    setColor(current_color_);
  }
}
void SkPaintDispatchHelper::restore_opacity() {
  SaveInfo& info = save_stack_.back();
  if (info.restore_opacity) {
    opacity_ = info.opacity;
    setColor(current_color_);
  }
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
void SkPaintDispatchHelper::setStrokeCap(SkPaint::Cap cap) {
  paint_.setStrokeCap(cap);
}
void SkPaintDispatchHelper::setStrokeJoin(SkPaint::Join join) {
  paint_.setStrokeJoin(join);
}
void SkPaintDispatchHelper::setStyle(SkPaint::Style style) {
  paint_.setStyle(style);
}
void SkPaintDispatchHelper::setStrokeWidth(SkScalar width) {
  paint_.setStrokeWidth(width);
}
void SkPaintDispatchHelper::setStrokeMiter(SkScalar limit) {
  paint_.setStrokeMiter(limit);
}
void SkPaintDispatchHelper::setColor(SkColor color) {
  current_color_ = color;
  paint_.setColor(color);
  if (has_opacity()) {
    paint_.setAlphaf(paint_.getAlphaf() * opacity());
  }
}
void SkPaintDispatchHelper::setBlendMode(SkBlendMode mode) {
  paint_.setBlendMode(mode);
}
void SkPaintDispatchHelper::setBlender(sk_sp<SkBlender> blender) {
  paint_.setBlender(blender);
}
void SkPaintDispatchHelper::setShader(sk_sp<SkShader> shader) {
  paint_.setShader(shader);
}
void SkPaintDispatchHelper::setImageFilter(sk_sp<SkImageFilter> filter) {
  paint_.setImageFilter(filter);
}
void SkPaintDispatchHelper::setColorFilter(sk_sp<SkColorFilter> filter) {
  color_filter_ = filter;
  paint_.setColorFilter(makeColorFilter());
}
void SkPaintDispatchHelper::setPathEffect(sk_sp<SkPathEffect> effect) {
  paint_.setPathEffect(effect);
}
void SkPaintDispatchHelper::setMaskFilter(sk_sp<SkMaskFilter> filter) {
  paint_.setMaskFilter(filter);
}
void SkPaintDispatchHelper::setMaskBlurFilter(SkBlurStyle style,
                                              SkScalar sigma) {
  paint_.setMaskFilter(SkMaskFilter::MakeBlur(style, sigma));
}

sk_sp<SkColorFilter> SkPaintDispatchHelper::makeColorFilter() {
  if (!invert_colors_) {
    return color_filter_;
  }
  sk_sp<SkColorFilter> invert_filter =
      SkColorFilters::Matrix(invert_color_matrix);
  if (color_filter_) {
    invert_filter = invert_filter->makeComposed(color_filter_);
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

void SkMatrixDispatchHelper::save() {
  saved_.push_back(matrix_);
}
void SkMatrixDispatchHelper::restore() {
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
  if (clip_op == SkClipOp::kIntersect) {
    intersect(rect, is_aa);
  }
}
void ClipBoundsDispatchHelper::clipRRect(const SkRRect& rrect,
                                         SkClipOp clip_op,
                                         bool is_aa) {
  if (clip_op == SkClipOp::kIntersect) {
    intersect(rrect.getBounds(), is_aa);
  }
}
void ClipBoundsDispatchHelper::clipPath(const SkPath& path,
                                        SkClipOp clip_op,
                                        bool is_aa) {
  if (clip_op == SkClipOp::kIntersect) {
    intersect(path.getBounds(), is_aa);
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
  layer_infos_.emplace_back(std::make_unique<RootLayerData>());
  accumulator_ = layer_infos_.back()->layer_accumulator();
}
void DisplayListBoundsCalculator::setStrokeCap(SkPaint::Cap cap) {
  cap_is_square_ = (cap == SkPaint::kSquare_Cap);
}
void DisplayListBoundsCalculator::setStrokeJoin(SkPaint::Join join) {
  join_is_miter_ = (join == SkPaint::kMiter_Join);
}
void DisplayListBoundsCalculator::setStyle(SkPaint::Style style) {
  style_ = style;
}
void DisplayListBoundsCalculator::setStrokeWidth(SkScalar width) {
  half_stroke_width_ = std::max(width * 0.5f, kMinStrokeWidth);
}
void DisplayListBoundsCalculator::setStrokeMiter(SkScalar limit) {
  miter_limit_ = std::max(limit, 1.0f);
}
void DisplayListBoundsCalculator::setBlendMode(SkBlendMode mode) {
  blend_mode_ = mode;
}
void DisplayListBoundsCalculator::setBlender(sk_sp<SkBlender> blender) {
  SkPaint paint;
  paint.setBlender(std::move(blender));
  blend_mode_ = paint.asBlendMode();
}
void DisplayListBoundsCalculator::setImageFilter(sk_sp<SkImageFilter> filter) {
  image_filter_ = std::move(filter);
}
void DisplayListBoundsCalculator::setColorFilter(sk_sp<SkColorFilter> filter) {
  color_filter_ = std::move(filter);
}
void DisplayListBoundsCalculator::setPathEffect(sk_sp<SkPathEffect> effect) {
  path_effect_ = std::move(effect);
}
void DisplayListBoundsCalculator::setMaskFilter(sk_sp<SkMaskFilter> filter) {
  mask_filter_ = std::move(filter);
  mask_sigma_pad_ = 0.0f;
}
void DisplayListBoundsCalculator::setMaskBlurFilter(SkBlurStyle style,
                                                    SkScalar sigma) {
  mask_sigma_pad_ = std::max(3.0f * sigma, 0.0f);
  mask_filter_ = nullptr;
}
void DisplayListBoundsCalculator::save() {
  SkMatrixDispatchHelper::save();
  ClipBoundsDispatchHelper::save();
  layer_infos_.emplace_back(std::make_unique<SaveData>(accumulator_));
  accumulator_ = layer_infos_.back()->layer_accumulator();
}
void DisplayListBoundsCalculator::saveLayer(const SkRect* bounds,
                                            bool with_paint) {
  SkMatrixDispatchHelper::save();
  ClipBoundsDispatchHelper::save();
  if (with_paint) {
    layer_infos_.emplace_back(std::make_unique<SaveLayerData>(
        accumulator_, image_filter_, paint_nops_on_transparency()));
  } else {
    layer_infos_.emplace_back(
        std::make_unique<SaveLayerData>(accumulator_, nullptr, true));
  }
  accumulator_ = layer_infos_.back()->layer_accumulator();
  // Accumulate the layer in its own coordinate system and then
  // filter and transform its bounds on restore.
  SkMatrixDispatchHelper::reset();
  if (bounds) {
    clipRect(*bounds, SkClipOp::kIntersect, false);
  }
}
void DisplayListBoundsCalculator::restore() {
  if (layer_infos_.size() > 1) {
    SkMatrixDispatchHelper::restore();
    ClipBoundsDispatchHelper::restore();
    accumulator_ = layer_infos_.back()->restore_accumulator();
    SkRect layer_bounds = layer_infos_.back()->layer_bounds();
    // Must read unbounded state after layer_bounds
    bool layer_unbounded = layer_infos_.back()->is_unbounded();
    layer_infos_.pop_back();

    // We accumulate the bounds even if the layer was unbounded because
    // the unbounded state may be contained at a higher level, so we at
    // least accumulate our best estimate about what we have.
    if (!layer_bounds.isEmpty()) {
      // We do not use AccumulateOpBounds because the layer info already
      // applied all bounds modifications based on the attributes that
      // were in place when it was created. Modifying the bounds further
      // based on the current attributes would mix attribute states.
      // The bounds are still transformed and clipped by this method.
      AccumulateBounds(layer_bounds);
    }
    if (layer_unbounded) {
      AccumulateUnbounded();
    }
  }
}

void DisplayListBoundsCalculator::drawPaint() {
  AccumulateUnbounded();
}
void DisplayListBoundsCalculator::drawColor(SkColor color, SkBlendMode mode) {
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
void DisplayListBoundsCalculator::drawVertices(const sk_sp<SkVertices> vertices,
                                               SkBlendMode mode) {
  AccumulateOpBounds(vertices->bounds(), kDrawVerticesFlags);
}
void DisplayListBoundsCalculator::drawImage(const sk_sp<SkImage> image,
                                            const SkPoint point,
                                            const SkSamplingOptions& sampling,
                                            bool render_with_attributes) {
  SkRect bounds = SkRect::MakeXYWH(point.fX, point.fY,  //
                                   image->width(), image->height());
  DisplayListAttributeFlags flags = render_with_attributes  //
                                        ? kDrawImageWithPaintFlags
                                        : kDrawImageFlags;
  AccumulateOpBounds(bounds, flags);
}
void DisplayListBoundsCalculator::drawImageRect(
    const sk_sp<SkImage> image,
    const SkRect& src,
    const SkRect& dst,
    const SkSamplingOptions& sampling,
    bool render_with_attributes,
    SkCanvas::SrcRectConstraint constraint) {
  DisplayListAttributeFlags flags = render_with_attributes
                                        ? kDrawImageRectWithPaintFlags
                                        : kDrawImageRectFlags;
  AccumulateOpBounds(dst, flags);
}
void DisplayListBoundsCalculator::drawImageNine(const sk_sp<SkImage> image,
                                                const SkIRect& center,
                                                const SkRect& dst,
                                                SkFilterMode filter,
                                                bool render_with_attributes) {
  DisplayListAttributeFlags flags = render_with_attributes
                                        ? kDrawImageNineWithPaintFlags
                                        : kDrawImageNineFlags;
  AccumulateOpBounds(dst, flags);
}
void DisplayListBoundsCalculator::drawImageLattice(
    const sk_sp<SkImage> image,
    const SkCanvas::Lattice& lattice,
    const SkRect& dst,
    SkFilterMode filter,
    bool render_with_attributes) {
  DisplayListAttributeFlags flags = render_with_attributes
                                        ? kDrawImageLatticeWithPaintFlags
                                        : kDrawImageLatticeFlags;
  AccumulateOpBounds(dst, flags);
}
void DisplayListBoundsCalculator::drawAtlas(const sk_sp<SkImage> atlas,
                                            const SkRSXform xform[],
                                            const SkRect tex[],
                                            const SkColor colors[],
                                            int count,
                                            SkBlendMode mode,
                                            const SkSamplingOptions& sampling,
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
                                             const SkColor color,
                                             const SkScalar elevation,
                                             bool transparent_occluder,
                                             SkScalar dpr) {
  SkRect shadow_bounds = DisplayListCanvasDispatcher::ComputeShadowBounds(
      path, elevation, dpr, matrix());
  AccumulateOpBounds(shadow_bounds, kDrawShadowFlags);
}

bool DisplayListBoundsCalculator::ComputeFilteredBounds(SkRect& bounds,
                                                        SkImageFilter* filter) {
  if (filter) {
    if (!filter->canComputeFastBounds()) {
      return false;
    }
    bounds = filter->computeFastBounds(bounds);
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
        flags.WithPathEffect(path_effect_);
    if (path_effect_) {
      SkPaint p;
      p.setPathEffect(path_effect_);
      if (!p.canComputeFastBounds()) {
        return false;
      }
      bounds = p.computeFastBounds(bounds, &bounds);
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
      SkPaint p;
      p.setMaskFilter(mask_filter_);
      if (!p.canComputeFastBounds()) {
        return false;
      }
      bounds = p.computeFastBounds(bounds, &bounds);
    }
    if (mask_sigma_pad_ > 0.0f) {
      bounds.outset(mask_sigma_pad_, mask_sigma_pad_);
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
  if (image_filter_ && !image_filter_->canComputeFastBounds()) {
    return false;
  }

  // We filter the transparent black that is used for the background of a
  // saveLayer and make sure it returns transparent black. If it does, then
  // the color filter will leave all area surrounding the contents of the
  // save layer untouched out to the edge of the output surface.
  // This test assumes that the blend mode checked down below will
  // NOP on transparent black.
  if (color_filter_ &&
      color_filter_->filterColor(SK_ColorTRANSPARENT) != SK_ColorTRANSPARENT) {
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
    case SkBlendMode::kClear:     // r = 0
    case SkBlendMode::kSrc:       // r = s
    case SkBlendMode::kSrcIn:     // r = s * da
    case SkBlendMode::kDstIn:     // r = d * sa
    case SkBlendMode::kSrcOut:    // r = s * (1-da)
    case SkBlendMode::kDstATop:   // r = d*sa + s*(1-da)
    case SkBlendMode::kModulate:  // r = s*d
      return false;
      break;

    // And in these equations, the result must be d if the
    // source is 0
    case SkBlendMode::kDst:         // r = d
    case SkBlendMode::kSrcOver:     // r = s + (1-sa)*d
    case SkBlendMode::kDstOver:     // r = d + (1-da)*s
    case SkBlendMode::kDstOut:      // r = d * (1-sa)
    case SkBlendMode::kSrcATop:     // r = s*da + d*(1-sa)
    case SkBlendMode::kXor:         // r = s*(1-da) + d*(1-sa)
    case SkBlendMode::kPlus:        // r = min(s + d, 1)
    case SkBlendMode::kScreen:      // r = s + d - s*d
    case SkBlendMode::kOverlay:     // multiply or screen, depending on dest
    case SkBlendMode::kDarken:      // rc = s + d - max(s*da, d*sa),
                                    // ra = kSrcOver
    case SkBlendMode::kLighten:     // rc = s + d - min(s*da, d*sa),
                                    // ra = kSrcOver
    case SkBlendMode::kColorDodge:  // brighten destination to reflect source
    case SkBlendMode::kColorBurn:   // darken destination to reflect source
    case SkBlendMode::kHardLight:   // multiply or screen, depending on source
    case SkBlendMode::kSoftLight:   // lighten or darken, depending on source
    case SkBlendMode::kDifference:  // rc = s + d - 2*(min(s*da, d*sa)),
                                    // ra = kSrcOver
    case SkBlendMode::kExclusion:   // rc = s + d - two(s*d), ra = kSrcOver
    case SkBlendMode::kMultiply:    // r = s*(1-da) + d*(1-sa) + s*d
    case SkBlendMode::kHue:         // ra = kSrcOver
    case SkBlendMode::kSaturation:  // ra = kSrcOver
    case SkBlendMode::kColor:       // ra = kSrcOver
    case SkBlendMode::kLuminosity:  // ra = kSrcOver
      return true;
      break;
  }
}

}  // namespace flutter
