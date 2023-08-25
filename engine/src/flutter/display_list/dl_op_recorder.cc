// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/dl_op_recorder.h"

#include "flutter/display_list/dl_attributes.h"
#include "flutter/display_list/dl_op_records.h"
#include "flutter/display_list/effects/dl_color_source.h"

namespace flutter {

#define DL_BUILDER_PAGE 4096

// CopyV(dst, src,n, src,n, ...) copies any number of typed srcs into dst.
static void CopyV(void* dst) {}

template <typename S, typename... Rest>
static void CopyV(void* dst, const S* src, int n, Rest&&... rest) {
  FML_DCHECK(((uintptr_t)dst & (alignof(S) - 1)) == 0)
      << "Expected " << dst << " to be aligned for at least " << alignof(S)
      << " bytes.";
  // If n is 0, there is nothing to copy into dst from src.
  if (n > 0) {
    memcpy(dst, src, n * sizeof(S));
    dst = reinterpret_cast<void*>(reinterpret_cast<uint8_t*>(dst) +
                                  n * sizeof(S));
  }
  // Repeat for the next items, if any
  CopyV(dst, std::forward<Rest>(rest)...);
}

DlOpRecorder::DlOpRecorder(const SkRect& cull_rect, bool keep_rtree) {
  tracker_ =
      std::make_shared<DisplayListMatrixClipTracker>(cull_rect, SkMatrix::I());
  if (keep_rtree) {
    accumulator_ = std::make_shared<RTreeBoundsAccumulator>();
  } else {
    accumulator_ = std::make_shared<RectBoundsAccumulator>();
  }
  save_infos_.push_back({
      .offset = 0u,
      .deferred = false,
      .is_layer = false,
  });
}

template <typename T, typename... Args>
void* DlOpRecorder::Push(size_t pod, int render_op_inc, Args&&... args) {
  size_t size = SkAlignPtr(sizeof(T) + pod);
  auto op = reinterpret_cast<T*>(storage_.alloc(size));
  new (op) T{std::forward<Args>(args)...};
  op->type = T::kType;
  op->size = size;
  render_op_count_ += render_op_inc;
  op_index_++;
  return op + 1;
}

void DlOpRecorder::setAntiAlias(bool aa) {
  Push<SetAntiAliasOp>(0, 0, aa);
}
void DlOpRecorder::setDither(bool dither) {
  Push<SetDitherOp>(0, 0, dither);
}
void DlOpRecorder::setInvertColors(bool invert) {
  Push<SetInvertColorsOp>(0, 0, invert);
}
void DlOpRecorder::setStrokeCap(DlStrokeCap cap) {
  Push<SetStrokeCapOp>(0, 0, cap);
}
void DlOpRecorder::setStrokeJoin(DlStrokeJoin join) {
  Push<SetStrokeJoinOp>(0, 0, join);
}
void DlOpRecorder::setDrawStyle(DlDrawStyle style) {
  Push<SetStyleOp>(0, 0, style);
}
void DlOpRecorder::setStrokeWidth(float width) {
  Push<SetStrokeWidthOp>(0, 0, width);
}
void DlOpRecorder::setStrokeMiter(float limit) {
  Push<SetStrokeMiterOp>(0, 0, limit);
}
void DlOpRecorder::setColor(DlColor color) {
  Push<SetColorOp>(0, 0, color);
}
void DlOpRecorder::setBlendMode(DlBlendMode mode) {
  Push<SetBlendModeOp>(0, 0, mode);
}

void DlOpRecorder::setColorSource(const DlColorSource* source) {
  if (source == nullptr) {
    Push<ClearColorSourceOp>(0, 0);
  } else {
    is_ui_thread_safe_ = is_ui_thread_safe_ && source->isUIThreadSafe();
    switch (source->type()) {
      case DlColorSourceType::kColor: {
        const DlColorColorSource* color_source = source->asColor();
        setColor(color_source->color());
        break;
      }
      case DlColorSourceType::kImage: {
        const DlImageColorSource* image_source = source->asImage();
        FML_DCHECK(image_source);
        Push<SetImageColorSourceOp>(0, 0, image_source);
        break;
      }
      case DlColorSourceType::kLinearGradient: {
        const DlLinearGradientColorSource* linear = source->asLinearGradient();
        FML_DCHECK(linear);
        void* pod = Push<SetPodColorSourceOp>(linear->size(), 0);
        new (pod) DlLinearGradientColorSource(linear);
        break;
      }
      case DlColorSourceType::kRadialGradient: {
        const DlRadialGradientColorSource* radial = source->asRadialGradient();
        FML_DCHECK(radial);
        void* pod = Push<SetPodColorSourceOp>(radial->size(), 0);
        new (pod) DlRadialGradientColorSource(radial);
        break;
      }
      case DlColorSourceType::kConicalGradient: {
        const DlConicalGradientColorSource* conical =
            source->asConicalGradient();
        FML_DCHECK(conical);
        void* pod = Push<SetPodColorSourceOp>(conical->size(), 0);
        new (pod) DlConicalGradientColorSource(conical);
        break;
      }
      case DlColorSourceType::kSweepGradient: {
        const DlSweepGradientColorSource* sweep = source->asSweepGradient();
        FML_DCHECK(sweep);
        void* pod = Push<SetPodColorSourceOp>(sweep->size(), 0);
        new (pod) DlSweepGradientColorSource(sweep);
        break;
      }
      case DlColorSourceType::kRuntimeEffect: {
        const DlRuntimeEffectColorSource* effect = source->asRuntimeEffect();
        FML_DCHECK(effect);
        Push<SetRuntimeEffectColorSourceOp>(0, 0, effect);
        break;
      }
#ifdef IMPELLER_ENABLE_3D
      case DlColorSourceType::kScene: {
        const DlSceneColorSource* scene = source->asScene();
        FML_DCHECK(scene);
        Push<SetSceneColorSourceOp>(0, 0, scene);
        break;
      }
#endif  // IMPELLER_ENABLE_3D
    }
  }
}
void DlOpRecorder::setImageFilter(const DlImageFilter* filter) {
  if (filter == nullptr) {
    Push<ClearImageFilterOp>(0, 0);
  } else {
    switch (filter->type()) {
      case DlImageFilterType::kBlur: {
        const DlBlurImageFilter* blur_filter = filter->asBlur();
        FML_DCHECK(blur_filter);
        void* pod = Push<SetPodImageFilterOp>(blur_filter->size(), 0);
        new (pod) DlBlurImageFilter(blur_filter);
        break;
      }
      case DlImageFilterType::kDilate: {
        const DlDilateImageFilter* dilate_filter = filter->asDilate();
        FML_DCHECK(dilate_filter);
        void* pod = Push<SetPodImageFilterOp>(dilate_filter->size(), 0);
        new (pod) DlDilateImageFilter(dilate_filter);
        break;
      }
      case DlImageFilterType::kErode: {
        const DlErodeImageFilter* erode_filter = filter->asErode();
        FML_DCHECK(erode_filter);
        void* pod = Push<SetPodImageFilterOp>(erode_filter->size(), 0);
        new (pod) DlErodeImageFilter(erode_filter);
        break;
      }
      case DlImageFilterType::kMatrix: {
        const DlMatrixImageFilter* matrix_filter = filter->asMatrix();
        FML_DCHECK(matrix_filter);
        void* pod = Push<SetPodImageFilterOp>(matrix_filter->size(), 0);
        new (pod) DlMatrixImageFilter(matrix_filter);
        break;
      }
      case DlImageFilterType::kCompose:
      case DlImageFilterType::kLocalMatrix:
      case DlImageFilterType::kColorFilter: {
        Push<SetSharedImageFilterOp>(0, 0, filter);
        break;
      }
    }
  }
}
void DlOpRecorder::setColorFilter(const DlColorFilter* filter) {
  if (filter == nullptr) {
    Push<ClearColorFilterOp>(0, 0);
  } else {
    switch (filter->type()) {
      case DlColorFilterType::kBlend: {
        const DlBlendColorFilter* blend_filter = filter->asBlend();
        FML_DCHECK(blend_filter);
        void* pod = Push<SetPodColorFilterOp>(blend_filter->size(), 0);
        new (pod) DlBlendColorFilter(blend_filter);
        break;
      }
      case DlColorFilterType::kMatrix: {
        const DlMatrixColorFilter* matrix_filter = filter->asMatrix();
        FML_DCHECK(matrix_filter);
        void* pod = Push<SetPodColorFilterOp>(matrix_filter->size(), 0);
        new (pod) DlMatrixColorFilter(matrix_filter);
        break;
      }
      case DlColorFilterType::kSrgbToLinearGamma: {
        void* pod = Push<SetPodColorFilterOp>(filter->size(), 0);
        new (pod) DlSrgbToLinearGammaColorFilter();
        break;
      }
      case DlColorFilterType::kLinearToSrgbGamma: {
        void* pod = Push<SetPodColorFilterOp>(filter->size(), 0);
        new (pod) DlLinearToSrgbGammaColorFilter();
        break;
      }
    }
  }
}
void DlOpRecorder::setPathEffect(const DlPathEffect* effect) {
  if (effect == nullptr) {
    Push<ClearPathEffectOp>(0, 0);
  } else {
    switch (effect->type()) {
      case DlPathEffectType::kDash: {
        const DlDashPathEffect* dash_effect = effect->asDash();
        void* pod = Push<SetPodPathEffectOp>(dash_effect->size(), 0);
        new (pod) DlDashPathEffect(dash_effect);
        break;
      }
    }
  }
}
void DlOpRecorder::setMaskFilter(const DlMaskFilter* filter) {
  if (filter == nullptr) {
    Push<ClearMaskFilterOp>(0, 0);
  } else {
    switch (filter->type()) {
      case DlMaskFilterType::kBlur: {
        const DlBlurMaskFilter* blur_filter = filter->asBlur();
        FML_DCHECK(blur_filter);
        void* pod = Push<SetPodMaskFilterOp>(blur_filter->size(), 0);
        new (pod) DlBlurMaskFilter(blur_filter);
        break;
      }
    }
  }
}

void DlOpRecorder::save() {
  save_infos_.push_back({
      .offset = 0u,
      .deferred = true,
      .is_layer = false,
  });
  tracker_->save();
  accumulator_->save();
}
void DlOpRecorder::ResolveDeferredSave() {
  SaveInfo& save_info_ref = save_infos_.back();
  if (save_info_ref.deferred) {
    FML_DCHECK(save_info_ref.is_layer == false);
    FML_DCHECK(save_info_ref.offset == 0u);
    save_info_ref.offset = storage_.used();
    save_info_ref.deferred = false;
    Push<SaveOp>(0, 1);
  }
}
void DlOpRecorder::saveLayer(const SkRect* bounds,
                             const SaveLayerOptions options,
                             const DlImageFilter* backdrop) {
  save_infos_.push_back({
      .offset = storage_.used(),
      .deferred = false,
      .is_layer = true,
  });
  tracker_->save();
  accumulator_->save();
  if (backdrop) {
    bounds  //
        ? Push<SaveLayerBackdropBoundsOp>(0, 1, options, *bounds, backdrop)
        : Push<SaveLayerBackdropOp>(0, 1, options, backdrop);
  } else {
    bounds  //
        ? Push<SaveLayerBoundsOp>(0, 1, options, *bounds)
        : Push<SaveLayerOp>(0, 1, options);
  }
}

void DlOpRecorder::restore() {
  FML_DCHECK(!save_infos_.empty());
  {  // Ensure all uses of save_info_ref occur before pop_back()
    const SaveInfo& save_info_ref = save_infos_.back();
    if (save_info_ref.is_layer) {
      // This should only happen when unrolling the save stack
      // in the Build() method.
      restoreLayer(nullptr, false, false);
      return;
    }

    if (!save_info_ref.deferred) {
      SaveOpBase* op =
          reinterpret_cast<SaveOpBase*>(storage_.get() + save_info_ref.offset);
      FML_DCHECK(op->type == DisplayListOpType::kSave);
      op->restore_index = op_index_;

      Push<RestoreOp>(0, 1);
    }
  }  // save_info_ref no longer accessible
  save_infos_.pop_back();

  tracker_->restore();
  accumulator_->restore();
}
void DlOpRecorder::restoreLayer(const DlImageFilter* filter,
                                bool layer_content_was_unbounded,
                                bool layer_could_distribute_opacity) {
  FML_DCHECK(!save_infos_.empty());
  {  // Ensure all uses of save_info_ref occur before pop_back()
    SaveInfo& save_info_ref = save_infos_.back();
    FML_DCHECK(save_info_ref.is_layer == true);
    FML_DCHECK(save_info_ref.deferred == false);

    SaveOpBase* op =
        reinterpret_cast<SaveOpBase*>(storage_.get() + save_info_ref.offset);
    FML_DCHECK(op->type == DisplayListOpType::kSaveLayer ||
               op->type == DisplayListOpType::kSaveLayerBounds ||
               op->type == DisplayListOpType::kSaveLayerBackdrop ||
               op->type == DisplayListOpType::kSaveLayerBackdropBounds);
    op->restore_index = op_index_;
    if (layer_could_distribute_opacity) {
      op->options = op->options.with_can_distribute_opacity();
    }
  }  // save_info_ref no longer accessible
  save_infos_.pop_back();

  Push<RestoreOp>(0, 1);

  // Manage the layer bounds before we push the restore op so that any
  // bounds we need to adjust get tagged on the RestoreOp rather than
  // the rendering op that follows it.

  // Restore the tracker before we manage the layer bounds so that we use
  // the enclosing cull_rect and transform for filtering bounds.
  tracker_->restore();
  const SkRect clip = tracker_->device_cull_rect();

  // As we pop the accumulator we will adjust the bounds associated with
  // the layer content by the layer filter.
  // We have already restored the tracker so that the cull_rect information
  // we use in the adjustment is from the environment outside of the layer.
  // If there is a failure in converting the bounds within the layer due
  // to an issue with the layer filter, or if the content of the layer
  // was already unbounded, we will propagate the unbounded status to the
  // enclosing layer.
  if (filter) {
    const SkMatrix matrix = tracker_->matrix_3x3();
    if (!accumulator_->restore(
            [filter, matrix](const SkRect& input, SkRect& output) {
              SkIRect output_bounds;
              bool ret = filter->map_device_bounds(input.roundOut(), matrix,
                                                   output_bounds);
              output.set(output_bounds);
              return ret;
            },
            &clip)) {
      layer_content_was_unbounded = true;
    }
  } else {
    accumulator_->restore();
  }

  if (layer_content_was_unbounded) {
    // Ideally we would insert this back in the list of rects with the
    // OpID of the original SaveLayer...
    if (!clip.isEmpty()) {
      accumulator_->accumulate(clip, render_op_count_);
    }
  }
}

void DlOpRecorder::translate(SkScalar tx, SkScalar ty) {
  ResolveDeferredSave();
  tracker_->translate(tx, ty);
  Push<TranslateOp>(0, 1, tx, ty);
}
void DlOpRecorder::scale(SkScalar sx, SkScalar sy) {
  ResolveDeferredSave();
  tracker_->scale(sx, sy);
  Push<ScaleOp>(0, 1, sx, sy);
}
void DlOpRecorder::rotate(SkScalar degrees) {
  ResolveDeferredSave();
  tracker_->rotate(degrees);
  Push<RotateOp>(0, 1, degrees);
}
void DlOpRecorder::skew(SkScalar sx, SkScalar sy) {
  ResolveDeferredSave();
  tracker_->skew(sx, sy);
  Push<SkewOp>(0, 1, sx, sy);
}

// clang-format off

// 2x3 2D affine subset of a 4x4 transform in row major order
void DlOpRecorder::transform2DAffine(
    SkScalar mxx, SkScalar mxy, SkScalar mxt,
    SkScalar myx, SkScalar myy, SkScalar myt) {
  ResolveDeferredSave();
  tracker_->transform2DAffine(mxx, mxy, mxt,
                              myx, myy, myt);
  Push<Transform2DAffineOp>(0, 1,
                            mxx, mxy, mxt,
                            myx, myy, myt);
}
// full 4x4 transform in row major order
void DlOpRecorder::transformFullPerspective(
    SkScalar mxx, SkScalar mxy, SkScalar mxz, SkScalar mxt,
    SkScalar myx, SkScalar myy, SkScalar myz, SkScalar myt,
    SkScalar mzx, SkScalar mzy, SkScalar mzz, SkScalar mzt,
    SkScalar mwx, SkScalar mwy, SkScalar mwz, SkScalar mwt) {
  ResolveDeferredSave();
  tracker_->transformFullPerspective(mxx, mxy, mxz, mxt,
                                     myx, myy, myz, myt,
                                     mzx, mzy, mzz, mzt,
                                     mwx, mwy, mwz, mwt);
  Push<TransformFullPerspectiveOp>(0, 1,
                                   mxx, mxy, mxz, mxt,
                                   myx, myy, myz, myt,
                                   mzx, mzy, mzz, mzt,
                                   mwx, mwy, mwz, mwt);
}
// clang-format on
void DlOpRecorder::transformReset() {
  ResolveDeferredSave();
  tracker_->setIdentity();
  Push<TransformResetOp>(0, 0);
}

void DlOpRecorder::clipRect(const SkRect& rect, ClipOp clip_op, bool is_aa) {
  ResolveDeferredSave();
  tracker_->clipRect(rect, clip_op, is_aa);
  if (!tracker_->is_cull_rect_empty()) {
    switch (clip_op) {
      case ClipOp::kIntersect:
        Push<ClipIntersectRectOp>(0, 1, rect, is_aa);
        break;
      case ClipOp::kDifference:
        Push<ClipDifferenceRectOp>(0, 1, rect, is_aa);
        break;
    }
  }
}

void DlOpRecorder::clipRRect(const SkRRect& rrect, ClipOp clip_op, bool is_aa) {
  ResolveDeferredSave();
  tracker_->clipRRect(rrect, clip_op, is_aa);
  if (!tracker_->is_cull_rect_empty()) {
    switch (clip_op) {
      case ClipOp::kIntersect:
        Push<ClipIntersectRRectOp>(0, 1, rrect, is_aa);
        break;
      case ClipOp::kDifference:
        Push<ClipDifferenceRRectOp>(0, 1, rrect, is_aa);
        break;
    }
  }
}

void DlOpRecorder::clipPath(const SkPath& path, ClipOp clip_op, bool is_aa) {
  ResolveDeferredSave();
  tracker_->clipPath(path, clip_op, is_aa);
  if (!tracker_->is_cull_rect_empty()) {
    switch (clip_op) {
      case ClipOp::kIntersect:
        Push<ClipIntersectPathOp>(0, 1, path, is_aa);
        break;
      case ClipOp::kDifference:
        Push<ClipDifferencePathOp>(0, 1, path, is_aa);
        break;
    }
  }
}
void DlOpRecorder::resetCullRect(const SkRect* cull_rect) {
  tracker_->resetCullRect(cull_rect);
}
void DlOpRecorder::intersectCullRect(const SkRect& cull_rect) {
  tracker_->clipRect(cull_rect, DlCanvas::ClipOp::kIntersect, false);
}

void DlOpRecorder::drawPaint() {
  Push<DrawPaintOp>(0, 1);
}
void DlOpRecorder::drawColor(DlColor color, DlBlendMode mode) {
  Push<DrawColorOp>(0, 1, color, mode);
}
void DlOpRecorder::drawLine(const SkPoint& p0, const SkPoint& p1) {
  Push<DrawLineOp>(0, 1, p0, p1);
}
void DlOpRecorder::drawRect(const SkRect& rect) {
  Push<DrawRectOp>(0, 1, rect);
}
void DlOpRecorder::drawOval(const SkRect& bounds) {
  Push<DrawOvalOp>(0, 1, bounds);
}
void DlOpRecorder::drawCircle(const SkPoint& center, SkScalar radius) {
  Push<DrawCircleOp>(0, 1, center, radius);
}
void DlOpRecorder::drawRRect(const SkRRect& rrect) {
  Push<DrawRRectOp>(0, 1, rrect);
}
void DlOpRecorder::drawDRRect(const SkRRect& outer, const SkRRect& inner) {
  Push<DrawDRRectOp>(0, 1, outer, inner);
}
void DlOpRecorder::drawPath(const SkPath& path) {
  Push<DrawPathOp>(0, 1, path);
}

void DlOpRecorder::drawArc(const SkRect& bounds,
                           SkScalar start,
                           SkScalar sweep,
                           bool useCenter) {
  Push<DrawArcOp>(0, 1, bounds, start, sweep, useCenter);
}

void DlOpRecorder::drawPoints(PointMode mode,
                              uint32_t count,
                              const SkPoint pts[]) {
  FML_DCHECK(count > 0);
  FML_DCHECK(count < DlOpReceiver::kMaxDrawPointsCount);
  int bytes = count * sizeof(SkPoint);
  void* data_ptr;
  switch (mode) {
    case PointMode::kPoints:
      data_ptr = Push<DrawPointsOp>(bytes, 1, count);
      break;
    case PointMode::kLines:
      data_ptr = Push<DrawLinesOp>(bytes, 1, count);
      break;
    case PointMode::kPolygon:
      data_ptr = Push<DrawPolygonOp>(bytes, 1, count);
      break;
    default:
      FML_UNREACHABLE();
      return;
  }
  CopyV(data_ptr, pts, count);
}
void DlOpRecorder::drawVertices(const DlVertices* vertices, DlBlendMode mode) {
  void* pod = Push<DrawVerticesOp>(vertices->size(), 1, mode);
  new (pod) DlVertices(vertices);
}

void DlOpRecorder::drawImage(const sk_sp<DlImage>& image,
                             const SkPoint point,
                             DlImageSampling sampling,
                             bool render_with_attributes) {
  render_with_attributes
      ? Push<DrawImageWithAttrOp>(0, 1, image, point, sampling)
      : Push<DrawImageOp>(0, 1, image, point, sampling);
  is_ui_thread_safe_ = is_ui_thread_safe_ && image->isUIThreadSafe();
}
void DlOpRecorder::drawImageRect(const sk_sp<DlImage>& image,
                                 const SkRect& src,
                                 const SkRect& dst,
                                 DlImageSampling sampling,
                                 bool render_with_attributes,
                                 SrcRectConstraint constraint) {
  Push<DrawImageRectOp>(0, 1, image, src, dst, sampling,  //
                        render_with_attributes, constraint);
  is_ui_thread_safe_ = is_ui_thread_safe_ && image->isUIThreadSafe();
}
void DlOpRecorder::drawImageNine(const sk_sp<DlImage>& image,
                                 const SkIRect& center,
                                 const SkRect& dst,
                                 DlFilterMode filter,
                                 bool render_with_attributes) {
  render_with_attributes
      ? Push<DrawImageNineWithAttrOp>(0, 1, image, center, dst, filter)
      : Push<DrawImageNineOp>(0, 1, image, center, dst, filter);
  is_ui_thread_safe_ = is_ui_thread_safe_ && image->isUIThreadSafe();
}
void DlOpRecorder::drawAtlas(const sk_sp<DlImage>& atlas,
                             const SkRSXform xform[],
                             const SkRect tex[],
                             const DlColor colors[],
                             int count,
                             DlBlendMode mode,
                             DlImageSampling sampling,
                             const SkRect* cull_rect,
                             bool render_with_attributes) {
  int bytes = count * (sizeof(SkRSXform) + sizeof(SkRect));
  void* data_ptr;
  if (colors != nullptr) {
    bytes += count * sizeof(DlColor);
    if (cull_rect != nullptr) {
      data_ptr =
          Push<DrawAtlasCulledOp>(bytes, 1, atlas, count, mode, sampling, true,
                                  *cull_rect, render_with_attributes);
    } else {
      data_ptr = Push<DrawAtlasOp>(bytes, 1, atlas, count, mode, sampling, true,
                                   render_with_attributes);
    }
    CopyV(data_ptr, xform, count, tex, count, colors, count);
  } else {
    if (cull_rect != nullptr) {
      data_ptr =
          Push<DrawAtlasCulledOp>(bytes, 1, atlas, count, mode, sampling, false,
                                  *cull_rect, render_with_attributes);
    } else {
      data_ptr = Push<DrawAtlasOp>(bytes, 1, atlas, count, mode, sampling,
                                   false, render_with_attributes);
    }
    CopyV(data_ptr, xform, count, tex, count);
  }
  is_ui_thread_safe_ = is_ui_thread_safe_ && atlas->isUIThreadSafe();
}

void DlOpRecorder::drawDisplayList(const sk_sp<DisplayList>& display_list,
                                   SkScalar opacity) {
  Push<DrawDisplayListOp>(0, 1, display_list, opacity);
  nested_op_count_ += display_list->op_count(true) - 1;
  nested_bytes_ += display_list->bytes(true);
  is_ui_thread_safe_ = is_ui_thread_safe_ && display_list->isUIThreadSafe();
}
void DlOpRecorder::drawTextBlob(const sk_sp<SkTextBlob>& blob,
                                SkScalar x,
                                SkScalar y) {
  Push<DrawTextBlobOp>(0, 1, blob, x, y);
}
void DlOpRecorder::drawShadow(const SkPath& path,
                              const DlColor color,
                              const SkScalar elevation,
                              bool transparent_occluder,
                              SkScalar dpr) {
  transparent_occluder  //
      ? Push<DrawShadowTransparentOccluderOp>(0, 1, path, color, elevation, dpr)
      : Push<DrawShadowOp>(0, 1, path, color, elevation, dpr);
}

bool DlOpRecorder::accumulateLocalBoundsForNextOp(const SkRect& r) {
  if (!r.isEmpty()) {
    SkRect bounds = r;
    tracker_->mapRect(&bounds);
    if (bounds.intersect(tracker_->device_cull_rect())) {
      accumulator_->accumulate(bounds, render_op_count_);
      return true;
    }
  }
  return false;
}
bool DlOpRecorder::accumulateUnboundedForNextOp() {
  SkRect clip = tracker_->device_cull_rect();
  if (!clip.isEmpty()) {
    accumulator_->accumulate(clip, render_op_count_);
    return true;
  }
  return false;
}

sk_sp<DisplayList> DlOpRecorder::Build(bool can_distribute_opacity,
                                       bool affects_transparent_layer) {
  if (!storage_.is_valid()) {
    FML_DCHECK(storage_.is_valid());
    return nullptr;
  }

  while (save_infos_.size() > 1u) {
    restore();
  }

  auto rtree = accumulator_->rtree();
  // It is faster to ask the completed rtree for bounds than to ask
  // the accumulator to run through all of its rects for the bounds.
  auto bounds = rtree ? rtree->bounds() : accumulator_->bounds();

  return sk_sp<DisplayList>(
      new DisplayList(storage_.take(), render_op_count_, nested_bytes_,
                      nested_op_count_, bounds, can_distribute_opacity,
                      is_ui_thread_safe_, affects_transparent_layer, rtree));
}

}  // namespace flutter
