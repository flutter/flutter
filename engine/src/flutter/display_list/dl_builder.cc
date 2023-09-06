// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/dl_builder.h"

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/dl_blend_mode.h"
#include "flutter/display_list/dl_op_flags.h"
#include "flutter/display_list/dl_op_records.h"
#include "flutter/display_list/effects/dl_color_source.h"
#include "flutter/display_list/utils/dl_bounds_accumulator.h"
#include "fml/logging.h"
#include "third_party/skia/include/core/SkScalar.h"

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

static constexpr inline bool is_power_of_two(int value) {
  return (value & (value - 1)) == 0;
}

template <typename T, typename... Args>
void* DisplayListBuilder::Push(size_t pod, int render_op_inc, Args&&... args) {
  size_t size = SkAlignPtr(sizeof(T) + pod);
  FML_DCHECK(size < (1 << 24));
  if (used_ + size > allocated_) {
    static_assert(is_power_of_two(DL_BUILDER_PAGE),
                  "This math needs updating for non-pow2.");
    // Next greater multiple of DL_BUILDER_PAGE.
    allocated_ = (used_ + size + DL_BUILDER_PAGE) & ~(DL_BUILDER_PAGE - 1);
    storage_.realloc(allocated_);
    FML_DCHECK(storage_.get());
    memset(storage_.get() + used_, 0, allocated_ - used_);
  }
  FML_DCHECK(used_ + size <= allocated_);
  auto op = reinterpret_cast<T*>(storage_.get() + used_);
  used_ += size;
  new (op) T{std::forward<Args>(args)...};
  op->type = T::kType;
  op->size = size;
  render_op_count_ += render_op_inc;
  op_index_++;
  return op + 1;
}

sk_sp<DisplayList> DisplayListBuilder::Build() {
  while (layer_stack_.size() > 1) {
    restore();
  }

  size_t bytes = used_;
  int count = render_op_count_;
  size_t nested_bytes = nested_bytes_;
  int nested_count = nested_op_count_;
  bool compatible = current_layer_->is_group_opacity_compatible();
  bool is_safe = is_ui_thread_safe_;
  bool affects_transparency = current_layer_->affects_transparent_layer();

  used_ = allocated_ = render_op_count_ = op_index_ = 0;
  nested_bytes_ = nested_op_count_ = 0;
  is_ui_thread_safe_ = true;
  storage_.realloc(bytes);
  layer_stack_.pop_back();
  layer_stack_.emplace_back();
  tracker_.reset();
  current_ = DlPaint();

  return sk_sp<DisplayList>(new DisplayList(
      std::move(storage_), bytes, count, nested_bytes, nested_count, bounds(),
      compatible, is_safe, affects_transparency, rtree()));
}

DisplayListBuilder::DisplayListBuilder(const SkRect& cull_rect,
                                       bool prepare_rtree)
    : tracker_(cull_rect, SkMatrix::I()) {
  if (prepare_rtree) {
    accumulator_ = std::make_unique<RTreeBoundsAccumulator>();
  } else {
    accumulator_ = std::make_unique<RectBoundsAccumulator>();
  }

  layer_stack_.emplace_back();
  current_layer_ = &layer_stack_.back();
}

DisplayListBuilder::~DisplayListBuilder() {
  uint8_t* ptr = storage_.get();
  if (ptr) {
    DisplayList::DisposeOps(ptr, ptr + used_);
  }
}

SkISize DisplayListBuilder::GetBaseLayerSize() const {
  return tracker_.base_device_cull_rect().roundOut().size();
}

SkImageInfo DisplayListBuilder::GetImageInfo() const {
  SkISize size = GetBaseLayerSize();
  return SkImageInfo::MakeUnknown(size.width(), size.height());
}

void DisplayListBuilder::onSetAntiAlias(bool aa) {
  current_.setAntiAlias(aa);
  Push<SetAntiAliasOp>(0, 0, aa);
}
void DisplayListBuilder::onSetDither(bool dither) {
  current_.setDither(dither);
  Push<SetDitherOp>(0, 0, dither);
}
void DisplayListBuilder::onSetInvertColors(bool invert) {
  current_.setInvertColors(invert);
  Push<SetInvertColorsOp>(0, 0, invert);
  UpdateCurrentOpacityCompatibility();
}
void DisplayListBuilder::onSetStrokeCap(DlStrokeCap cap) {
  current_.setStrokeCap(cap);
  Push<SetStrokeCapOp>(0, 0, cap);
}
void DisplayListBuilder::onSetStrokeJoin(DlStrokeJoin join) {
  current_.setStrokeJoin(join);
  Push<SetStrokeJoinOp>(0, 0, join);
}
void DisplayListBuilder::onSetDrawStyle(DlDrawStyle style) {
  current_.setDrawStyle(style);
  Push<SetStyleOp>(0, 0, style);
}
void DisplayListBuilder::onSetStrokeWidth(float width) {
  current_.setStrokeWidth(width);
  Push<SetStrokeWidthOp>(0, 0, width);
}
void DisplayListBuilder::onSetStrokeMiter(float limit) {
  current_.setStrokeMiter(limit);
  Push<SetStrokeMiterOp>(0, 0, limit);
}
void DisplayListBuilder::onSetColor(DlColor color) {
  current_.setColor(color);
  Push<SetColorOp>(0, 0, color);
}
void DisplayListBuilder::onSetBlendMode(DlBlendMode mode) {
  current_.setBlendMode(mode);
  Push<SetBlendModeOp>(0, 0, mode);
  UpdateCurrentOpacityCompatibility();
}

void DisplayListBuilder::onSetColorSource(const DlColorSource* source) {
  if (source == nullptr) {
    current_.setColorSource(nullptr);
    Push<ClearColorSourceOp>(0, 0);
  } else {
    current_.setColorSource(source->shared());
    is_ui_thread_safe_ = is_ui_thread_safe_ && source->isUIThreadSafe();
    switch (source->type()) {
      case DlColorSourceType::kColor: {
        const DlColorColorSource* color_source = source->asColor();
        current_.setColorSource(nullptr);
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
void DisplayListBuilder::onSetImageFilter(const DlImageFilter* filter) {
  if (filter == nullptr) {
    current_.setImageFilter(nullptr);
    Push<ClearImageFilterOp>(0, 0);
  } else {
    current_.setImageFilter(filter->shared());
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
void DisplayListBuilder::onSetColorFilter(const DlColorFilter* filter) {
  if (filter == nullptr) {
    current_.setColorFilter(nullptr);
    Push<ClearColorFilterOp>(0, 0);
  } else {
    current_.setColorFilter(filter->shared());
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
  UpdateCurrentOpacityCompatibility();
}
void DisplayListBuilder::onSetPathEffect(const DlPathEffect* effect) {
  if (effect == nullptr) {
    current_.setPathEffect(nullptr);
    Push<ClearPathEffectOp>(0, 0);
  } else {
    current_.setPathEffect(effect->shared());
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
void DisplayListBuilder::onSetMaskFilter(const DlMaskFilter* filter) {
  if (filter == nullptr) {
    current_.setMaskFilter(nullptr);
    Push<ClearMaskFilterOp>(0, 0);
  } else {
    current_.setMaskFilter(filter->shared());
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

void DisplayListBuilder::SetAttributesFromPaint(
    const DlPaint& paint,
    const DisplayListAttributeFlags flags) {
  if (flags.applies_anti_alias()) {
    setAntiAlias(paint.isAntiAlias());
  }
  if (flags.applies_dither()) {
    setDither(paint.isDither());
  }
  if (flags.applies_alpha_or_color()) {
    setColor(paint.getColor().argb);
  }
  if (flags.applies_blend()) {
    setBlendMode(paint.getBlendMode());
  }
  if (flags.applies_style()) {
    setDrawStyle(paint.getDrawStyle());
  }
  if (flags.is_stroked(paint.getDrawStyle())) {
    setStrokeWidth(paint.getStrokeWidth());
    setStrokeMiter(paint.getStrokeMiter());
    setStrokeCap(paint.getStrokeCap());
    setStrokeJoin(paint.getStrokeJoin());
  }
  if (flags.applies_shader()) {
    setColorSource(paint.getColorSource().get());
  }
  if (flags.applies_color_filter()) {
    setInvertColors(paint.isInvertColors());
    setColorFilter(paint.getColorFilter().get());
  }
  if (flags.applies_image_filter()) {
    setImageFilter(paint.getImageFilter().get());
  }
  if (flags.applies_path_effect()) {
    setPathEffect(paint.getPathEffect().get());
  }
  if (flags.applies_mask_filter()) {
    setMaskFilter(paint.getMaskFilter().get());
  }
}

void DisplayListBuilder::checkForDeferredSave() {
  if (current_layer_->has_deferred_save_op_) {
    size_t save_offset_ = used_;
    Push<SaveOp>(0, 1);
    current_layer_->save_offset_ = save_offset_;
    current_layer_->has_deferred_save_op_ = false;
  }
}

void DisplayListBuilder::Save() {
  bool is_nop = current_layer_->is_nop_;
  layer_stack_.emplace_back();
  current_layer_ = &layer_stack_.back();
  current_layer_->has_deferred_save_op_ = true;
  current_layer_->is_nop_ = is_nop;
  tracker_.save();
  accumulator()->save();
}

void DisplayListBuilder::Restore() {
  if (layer_stack_.size() > 1) {
    SaveOpBase* op = reinterpret_cast<SaveOpBase*>(
        storage_.get() + current_layer_->save_offset());
    if (!current_layer_->has_deferred_save_op_) {
      op->restore_index = op_index_;
      Push<RestoreOp>(0, 1);
    }
    // Grab the current layer info before we push the restore
    // on the stack.
    LayerInfo layer_info = layer_stack_.back();

    tracker_.restore();
    layer_stack_.pop_back();
    current_layer_ = &layer_stack_.back();
    bool is_unbounded = layer_info.is_unbounded();

    // Before we pop_back we will get the current layer bounds from the
    // current accumulator and adjust it as required based on the filter.
    std::shared_ptr<const DlImageFilter> filter = layer_info.filter();
    if (filter) {
      const SkRect clip = tracker_.device_cull_rect();
      if (!accumulator()->restore(
              [filter = filter, matrix = GetTransform()](const SkRect& input,
                                                         SkRect& output) {
                SkIRect output_bounds;
                bool ret = filter->map_device_bounds(input.roundOut(), matrix,
                                                     output_bounds);
                output.set(output_bounds);
                return ret;
              },
              &clip)) {
        is_unbounded = true;
      }
    } else {
      accumulator()->restore();
    }

    if (is_unbounded) {
      AccumulateUnbounded();
    }

    if (layer_info.has_layer()) {
      // Layers are never deferred for now, we need to update the
      // following code if we ever do saveLayer culling...
      FML_DCHECK(!layer_info.has_deferred_save_op_);
      if (layer_info.is_group_opacity_compatible()) {
        // We are now going to go back and modify the matching saveLayer
        // call to add the option indicating it can distribute an opacity
        // value to its children.
        //
        // Note that this operation cannot and does not change the size
        // or structure of the SaveLayerOp record. It only sets an option
        // flag on an existing field.
        //
        // Note that these kinds of modification operations on data already
        // in the DisplayList are only allowed *during* the build phase.
        // Once built, the DisplayList records must remain read only to
        // ensure consistency of rendering and |Equals()| behavior.
        op->options = op->options.with_can_distribute_opacity();
      }
    } else {
      // For regular save() ops there was no protecting layer so we have to
      // accumulate the values into the enclosing layer.
      if (layer_info.cannot_inherit_opacity()) {
        current_layer_->mark_incompatible();
      } else if (layer_info.has_compatible_op()) {
        current_layer_->add_compatible_op();
      }
    }
  }
}
void DisplayListBuilder::RestoreToCount(int restore_count) {
  FML_DCHECK(restore_count <= GetSaveCount());
  while (restore_count < GetSaveCount() && GetSaveCount() > 1) {
    restore();
  }
}
void DisplayListBuilder::saveLayer(const SkRect* bounds,
                                   const SaveLayerOptions in_options,
                                   const DlImageFilter* backdrop) {
  SaveLayerOptions options = in_options.without_optimizations();
  DisplayListAttributeFlags flags = options.renders_with_attributes()
                                        ? kSaveLayerWithPaintFlags
                                        : kSaveLayerFlags;
  OpResult result = PaintResult(current_, flags);
  if (result == OpResult::kNoEffect) {
    save();
    current_layer_->is_nop_ = true;
    return;
  }
  size_t save_layer_offset = used_;
  if (options.renders_with_attributes()) {
    // The actual flood of the outer layer clip will occur after the
    // (eventual) corresponding restore is called, but rather than
    // remember this information in the LayerInfo until the restore
    // method is processed, we just mark the unbounded state up front.
    // Another reason to accumulate the clip here rather than in
    // restore is so that this savelayer will be tagged in the rtree
    // with its full bounds and the right op_index so that it doesn't
    // get culled during rendering.
    if (!paint_nops_on_transparency()) {
      // We will fill the clip of the outer layer when we restore.
      // Accumulate should always return true here because if the
      // clip was empty then that would have been caught up above
      // when we tested the PaintResult.
      [[maybe_unused]] bool unclipped = AccumulateUnbounded();
      FML_DCHECK(unclipped);
    }
    CheckLayerOpacityCompatibility(true);
    layer_stack_.emplace_back(save_layer_offset, true,
                              current_.getImageFilter());
  } else {
    CheckLayerOpacityCompatibility(false);
    layer_stack_.emplace_back(save_layer_offset, true, nullptr);
  }
  current_layer_ = &layer_stack_.back();

  tracker_.save();
  accumulator()->save();

  if (backdrop) {
    // A backdrop will affect up to the entire surface, bounded by the clip
    // Accumulate should always return true here because if the
    // clip was empty then that would have been caught up above
    // when we tested the PaintResult.
    [[maybe_unused]] bool unclipped = AccumulateUnbounded();
    FML_DCHECK(unclipped);
    bounds  //
        ? Push<SaveLayerBackdropBoundsOp>(0, 1, options, *bounds, backdrop)
        : Push<SaveLayerBackdropOp>(0, 1, options, backdrop);
  } else {
    bounds  //
        ? Push<SaveLayerBoundsOp>(0, 1, options, *bounds)
        : Push<SaveLayerOp>(0, 1, options);
  }

  if (options.renders_with_attributes()) {
    // |current_opacity_compatibility_| does not take an ImageFilter into
    // account because an individual primitive with an ImageFilter can apply
    // opacity on top of it. But, if the layer is applying the ImageFilter
    // then it cannot pass the opacity on.
    if (!current_opacity_compatibility_ ||
        current_.getImageFilter() != nullptr) {
      UpdateLayerOpacityCompatibility(false);
    }
  }
  UpdateLayerResult(result);

  if (options.renders_with_attributes() && current_.getImageFilter()) {
    // We use |resetCullRect| here because we will be accumulating bounds of
    // primitives before applying the filter to those bounds. We might
    // encounter a primitive whose bounds are clipped, but whose filtered
    // bounds will not be clipped. If the individual rendering ops bounds
    // are clipped, it will not contribute to the overall bounds which
    // could lead to inaccurate (subset) bounds of the DisplayList.
    // We need to reset the cull rect here to avoid this premature clipping.
    // The filtered bounds will be clipped to the existing clip rect when
    // this layer is restored.
    // If bounds is null then the original cull_rect will be used.
    tracker_.resetCullRect(bounds);
  } else if (bounds) {
    // Even though Skia claims that the bounds are only a hint, they actually
    // use them as the temporary layer bounds during rendering the layer, so
    // we set them as if a clip operation were performed.
    tracker_.clipRect(*bounds, ClipOp::kIntersect, false);
  }
}
void DisplayListBuilder::SaveLayer(const SkRect* bounds,
                                   const DlPaint* paint,
                                   const DlImageFilter* backdrop) {
  if (paint != nullptr) {
    SetAttributesFromPaint(*paint,
                           DisplayListOpFlags::kSaveLayerWithPaintFlags);
    saveLayer(bounds, SaveLayerOptions::kWithAttributes, backdrop);
  } else {
    saveLayer(bounds, SaveLayerOptions::kNoAttributes, backdrop);
  }
}

void DisplayListBuilder::Translate(SkScalar tx, SkScalar ty) {
  if (SkScalarIsFinite(tx) && SkScalarIsFinite(ty) &&
      (tx != 0.0 || ty != 0.0)) {
    checkForDeferredSave();
    Push<TranslateOp>(0, 1, tx, ty);
    tracker_.translate(tx, ty);
  }
}
void DisplayListBuilder::Scale(SkScalar sx, SkScalar sy) {
  if (SkScalarIsFinite(sx) && SkScalarIsFinite(sy) &&
      (sx != 1.0 || sy != 1.0)) {
    checkForDeferredSave();
    Push<ScaleOp>(0, 1, sx, sy);
    tracker_.scale(sx, sy);
  }
}
void DisplayListBuilder::Rotate(SkScalar degrees) {
  if (SkScalarMod(degrees, 360.0) != 0.0) {
    checkForDeferredSave();
    Push<RotateOp>(0, 1, degrees);
    tracker_.rotate(degrees);
  }
}
void DisplayListBuilder::Skew(SkScalar sx, SkScalar sy) {
  if (SkScalarIsFinite(sx) && SkScalarIsFinite(sy) &&
      (sx != 0.0 || sy != 0.0)) {
    checkForDeferredSave();
    Push<SkewOp>(0, 1, sx, sy);
    tracker_.skew(sx, sy);
  }
}

// clang-format off

// 2x3 2D affine subset of a 4x4 transform in row major order
void DisplayListBuilder::Transform2DAffine(
    SkScalar mxx, SkScalar mxy, SkScalar mxt,
    SkScalar myx, SkScalar myy, SkScalar myt) {
  if (SkScalarsAreFinite(mxx, myx) &&
      SkScalarsAreFinite(mxy, myy) &&
      SkScalarsAreFinite(mxt, myt)) {
    if (mxx == 1 && mxy == 0 &&
        myx == 0 && myy == 1) {
      Translate(mxt, myt);
    } else {
      checkForDeferredSave();
      Push<Transform2DAffineOp>(0, 1,
                                mxx, mxy, mxt,
                                myx, myy, myt);
      tracker_.transform2DAffine(mxx, mxy, mxt,
                                 myx, myy, myt);
    }
  }
}
// full 4x4 transform in row major order
void DisplayListBuilder::TransformFullPerspective(
    SkScalar mxx, SkScalar mxy, SkScalar mxz, SkScalar mxt,
    SkScalar myx, SkScalar myy, SkScalar myz, SkScalar myt,
    SkScalar mzx, SkScalar mzy, SkScalar mzz, SkScalar mzt,
    SkScalar mwx, SkScalar mwy, SkScalar mwz, SkScalar mwt) {
  if (                        mxz == 0 &&
                              myz == 0 &&
      mzx == 0 && mzy == 0 && mzz == 1 && mzt == 0 &&
      mwx == 0 && mwy == 0 && mwz == 0 && mwt == 1) {
    Transform2DAffine(mxx, mxy, mxt,
                      myx, myy, myt);
  } else if (SkScalarsAreFinite(mxx, mxy) && SkScalarsAreFinite(mxz, mxt) &&
             SkScalarsAreFinite(myx, myy) && SkScalarsAreFinite(myz, myt) &&
             SkScalarsAreFinite(mzx, mzy) && SkScalarsAreFinite(mzz, mzt) &&
             SkScalarsAreFinite(mwx, mwy) && SkScalarsAreFinite(mwz, mwt)) {
    checkForDeferredSave();
    Push<TransformFullPerspectiveOp>(0, 1,
                                     mxx, mxy, mxz, mxt,
                                     myx, myy, myz, myt,
                                     mzx, mzy, mzz, mzt,
                                     mwx, mwy, mwz, mwt);
    tracker_.transformFullPerspective(mxx, mxy, mxz, mxt,
                                      myx, myy, myz, myt,
                                      mzx, mzy, mzz, mzt,
                                      mwx, mwy, mwz, mwt);
  }
}
// clang-format on
void DisplayListBuilder::TransformReset() {
  checkForDeferredSave();
  Push<TransformResetOp>(0, 0);
  tracker_.setIdentity();
}
void DisplayListBuilder::Transform(const SkMatrix* matrix) {
  if (matrix != nullptr) {
    Transform(SkM44(*matrix));
  }
}
void DisplayListBuilder::Transform(const SkM44* m44) {
  if (m44 != nullptr) {
    transformFullPerspective(
        m44->rc(0, 0), m44->rc(0, 1), m44->rc(0, 2), m44->rc(0, 3),
        m44->rc(1, 0), m44->rc(1, 1), m44->rc(1, 2), m44->rc(1, 3),
        m44->rc(2, 0), m44->rc(2, 1), m44->rc(2, 2), m44->rc(2, 3),
        m44->rc(3, 0), m44->rc(3, 1), m44->rc(3, 2), m44->rc(3, 3));
  }
}

void DisplayListBuilder::ClipRect(const SkRect& rect,
                                  ClipOp clip_op,
                                  bool is_aa) {
  if (!rect.isFinite()) {
    return;
  }
  tracker_.clipRect(rect, clip_op, is_aa);
  if (current_layer_->is_nop_ || tracker_.is_cull_rect_empty()) {
    current_layer_->is_nop_ = true;
    return;
  }
  checkForDeferredSave();
  switch (clip_op) {
    case ClipOp::kIntersect:
      Push<ClipIntersectRectOp>(0, 1, rect, is_aa);
      break;
    case ClipOp::kDifference:
      Push<ClipDifferenceRectOp>(0, 1, rect, is_aa);
      break;
  }
}
void DisplayListBuilder::ClipRRect(const SkRRect& rrect,
                                   ClipOp clip_op,
                                   bool is_aa) {
  if (rrect.isRect()) {
    clipRect(rrect.rect(), clip_op, is_aa);
  } else {
    tracker_.clipRRect(rrect, clip_op, is_aa);
    if (current_layer_->is_nop_ || tracker_.is_cull_rect_empty()) {
      current_layer_->is_nop_ = true;
      return;
    }
    checkForDeferredSave();
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
void DisplayListBuilder::ClipPath(const SkPath& path,
                                  ClipOp clip_op,
                                  bool is_aa) {
  if (!path.isInverseFillType()) {
    SkRect rect;
    if (path.isRect(&rect)) {
      this->clipRect(rect, clip_op, is_aa);
      return;
    }
    SkRRect rrect;
    if (path.isOval(&rect)) {
      rrect.setOval(rect);
      this->clipRRect(rrect, clip_op, is_aa);
      return;
    }
    if (path.isRRect(&rrect)) {
      this->clipRRect(rrect, clip_op, is_aa);
      return;
    }
  }
  tracker_.clipPath(path, clip_op, is_aa);
  if (current_layer_->is_nop_ || tracker_.is_cull_rect_empty()) {
    current_layer_->is_nop_ = true;
    return;
  }
  checkForDeferredSave();
  switch (clip_op) {
    case ClipOp::kIntersect:
      Push<ClipIntersectPathOp>(0, 1, path, is_aa);
      break;
    case ClipOp::kDifference:
      Push<ClipDifferencePathOp>(0, 1, path, is_aa);
      break;
  }
}

bool DisplayListBuilder::QuickReject(const SkRect& bounds) const {
  return tracker_.content_culled(bounds);
}

void DisplayListBuilder::drawPaint() {
  OpResult result = PaintResult(current_, kDrawPaintFlags);
  if (result != OpResult::kNoEffect && AccumulateUnbounded()) {
    Push<DrawPaintOp>(0, 1);
    CheckLayerOpacityCompatibility();
    UpdateLayerResult(result);
  }
}
void DisplayListBuilder::DrawPaint(const DlPaint& paint) {
  SetAttributesFromPaint(paint, DisplayListOpFlags::kDrawPaintFlags);
  drawPaint();
}
void DisplayListBuilder::DrawColor(DlColor color, DlBlendMode mode) {
  OpResult result = PaintResult(DlPaint(color).setBlendMode(mode));
  if (result != OpResult::kNoEffect && AccumulateUnbounded()) {
    Push<DrawColorOp>(0, 1, color, mode);
    CheckLayerOpacityCompatibility(mode);
    UpdateLayerResult(result);
  }
}
void DisplayListBuilder::drawLine(const SkPoint& p0, const SkPoint& p1) {
  SkRect bounds = SkRect::MakeLTRB(p0.fX, p0.fY, p1.fX, p1.fY).makeSorted();
  DisplayListAttributeFlags flags =
      (bounds.width() > 0.0f && bounds.height() > 0.0f) ? kDrawLineFlags
                                                        : kDrawHVLineFlags;
  OpResult result = PaintResult(current_, flags);
  if (result != OpResult::kNoEffect && AccumulateOpBounds(bounds, flags)) {
    Push<DrawLineOp>(0, 1, p0, p1);
    CheckLayerOpacityCompatibility();
    UpdateLayerResult(result);
  }
}
void DisplayListBuilder::DrawLine(const SkPoint& p0,
                                  const SkPoint& p1,
                                  const DlPaint& paint) {
  SetAttributesFromPaint(paint, DisplayListOpFlags::kDrawLineFlags);
  drawLine(p0, p1);
}
void DisplayListBuilder::drawRect(const SkRect& rect) {
  DisplayListAttributeFlags flags = kDrawRectFlags;
  OpResult result = PaintResult(current_, flags);
  if (result != OpResult::kNoEffect &&
      AccumulateOpBounds(rect.makeSorted(), flags)) {
    Push<DrawRectOp>(0, 1, rect);
    CheckLayerOpacityCompatibility();
    UpdateLayerResult(result);
  }
}
void DisplayListBuilder::DrawRect(const SkRect& rect, const DlPaint& paint) {
  SetAttributesFromPaint(paint, DisplayListOpFlags::kDrawRectFlags);
  drawRect(rect);
}
void DisplayListBuilder::drawOval(const SkRect& bounds) {
  DisplayListAttributeFlags flags = kDrawOvalFlags;
  OpResult result = PaintResult(current_, flags);
  if (result != OpResult::kNoEffect &&
      AccumulateOpBounds(bounds.makeSorted(), flags)) {
    Push<DrawOvalOp>(0, 1, bounds);
    CheckLayerOpacityCompatibility();
    UpdateLayerResult(result);
  }
}
void DisplayListBuilder::DrawOval(const SkRect& bounds, const DlPaint& paint) {
  SetAttributesFromPaint(paint, DisplayListOpFlags::kDrawOvalFlags);
  drawOval(bounds);
}
void DisplayListBuilder::drawCircle(const SkPoint& center, SkScalar radius) {
  DisplayListAttributeFlags flags = kDrawCircleFlags;
  OpResult result = PaintResult(current_, flags);
  if (result != OpResult::kNoEffect) {
    SkRect bounds = SkRect::MakeLTRB(center.fX - radius, center.fY - radius,
                                     center.fX + radius, center.fY + radius);
    if (AccumulateOpBounds(bounds, flags)) {
      Push<DrawCircleOp>(0, 1, center, radius);
      CheckLayerOpacityCompatibility();
      UpdateLayerResult(result);
    }
  }
}
void DisplayListBuilder::DrawCircle(const SkPoint& center,
                                    SkScalar radius,
                                    const DlPaint& paint) {
  SetAttributesFromPaint(paint, DisplayListOpFlags::kDrawCircleFlags);
  drawCircle(center, radius);
}
void DisplayListBuilder::drawRRect(const SkRRect& rrect) {
  if (rrect.isRect()) {
    drawRect(rrect.rect());
  } else if (rrect.isOval()) {
    drawOval(rrect.rect());
  } else {
    DisplayListAttributeFlags flags = kDrawRRectFlags;
    OpResult result = PaintResult(current_, flags);
    if (result != OpResult::kNoEffect &&
        AccumulateOpBounds(rrect.getBounds(), flags)) {
      Push<DrawRRectOp>(0, 1, rrect);
      CheckLayerOpacityCompatibility();
      UpdateLayerResult(result);
    }
  }
}
void DisplayListBuilder::DrawRRect(const SkRRect& rrect, const DlPaint& paint) {
  SetAttributesFromPaint(paint, DisplayListOpFlags::kDrawRRectFlags);
  drawRRect(rrect);
}
void DisplayListBuilder::drawDRRect(const SkRRect& outer,
                                    const SkRRect& inner) {
  DisplayListAttributeFlags flags = kDrawDRRectFlags;
  OpResult result = PaintResult(current_, flags);
  if (result != OpResult::kNoEffect &&
      AccumulateOpBounds(outer.getBounds(), flags)) {
    Push<DrawDRRectOp>(0, 1, outer, inner);
    CheckLayerOpacityCompatibility();
    UpdateLayerResult(result);
  }
}
void DisplayListBuilder::DrawDRRect(const SkRRect& outer,
                                    const SkRRect& inner,
                                    const DlPaint& paint) {
  SetAttributesFromPaint(paint, DisplayListOpFlags::kDrawDRRectFlags);
  drawDRRect(outer, inner);
}
void DisplayListBuilder::drawPath(const SkPath& path) {
  DisplayListAttributeFlags flags = kDrawPathFlags;
  OpResult result = PaintResult(current_, flags);
  if (result != OpResult::kNoEffect) {
    bool is_visible = path.isInverseFillType()
                          ? AccumulateUnbounded()
                          : AccumulateOpBounds(path.getBounds(), flags);
    if (is_visible) {
      Push<DrawPathOp>(0, 1, path);
      CheckLayerOpacityHairlineCompatibility();
      UpdateLayerResult(result);
    }
  }
}
void DisplayListBuilder::DrawPath(const SkPath& path, const DlPaint& paint) {
  SetAttributesFromPaint(paint, DisplayListOpFlags::kDrawPathFlags);
  drawPath(path);
}

void DisplayListBuilder::drawArc(const SkRect& bounds,
                                 SkScalar start,
                                 SkScalar sweep,
                                 bool useCenter) {
  DisplayListAttributeFlags flags =  //
      useCenter                      //
          ? kDrawArcWithCenterFlags
          : kDrawArcNoCenterFlags;
  OpResult result = PaintResult(current_, flags);
  // This could be tighter if we compute where the start and end
  // angles are and then also consider the quadrants swept and
  // the center if specified.
  if (result != OpResult::kNoEffect && AccumulateOpBounds(bounds, flags)) {
    Push<DrawArcOp>(0, 1, bounds, start, sweep, useCenter);
    if (useCenter) {
      CheckLayerOpacityHairlineCompatibility();
    } else {
      CheckLayerOpacityCompatibility();
    }
    UpdateLayerResult(result);
  }
}
void DisplayListBuilder::DrawArc(const SkRect& bounds,
                                 SkScalar start,
                                 SkScalar sweep,
                                 bool useCenter,
                                 const DlPaint& paint) {
  SetAttributesFromPaint(
      paint, useCenter ? kDrawArcWithCenterFlags : kDrawArcNoCenterFlags);
  drawArc(bounds, start, sweep, useCenter);
}

DisplayListAttributeFlags DisplayListBuilder::FlagsForPointMode(
    PointMode mode) {
  switch (mode) {
    case DlCanvas::PointMode::kPoints:
      return kDrawPointsAsPointsFlags;
    case PointMode::kLines:
      return kDrawPointsAsLinesFlags;
    case PointMode::kPolygon:
      return kDrawPointsAsPolygonFlags;
  }
  FML_UNREACHABLE();
}
void DisplayListBuilder::drawPoints(PointMode mode,
                                    uint32_t count,
                                    const SkPoint pts[]) {
  if (count == 0) {
    return;
  }
  DisplayListAttributeFlags flags = FlagsForPointMode(mode);
  OpResult result = PaintResult(current_, flags);
  if (result == OpResult::kNoEffect) {
    return;
  }

  FML_DCHECK(count < DlOpReceiver::kMaxDrawPointsCount);
  int bytes = count * sizeof(SkPoint);
  RectBoundsAccumulator ptBounds;
  for (size_t i = 0; i < count; i++) {
    ptBounds.accumulate(pts[i]);
  }
  SkRect point_bounds = ptBounds.bounds();
  if (!AccumulateOpBounds(point_bounds, flags)) {
    return;
  }

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
  // drawPoints treats every point or line (or segment of a polygon)
  // as a completely separate operation meaning we cannot ensure
  // distribution of group opacity without analyzing the mode and the
  // bounds of every sub-primitive.
  // See: https://fiddle.skia.org/c/228459001d2de8db117ce25ef5cedb0c
  UpdateLayerOpacityCompatibility(false);
  UpdateLayerResult(result);
}
void DisplayListBuilder::DrawPoints(PointMode mode,
                                    uint32_t count,
                                    const SkPoint pts[],
                                    const DlPaint& paint) {
  SetAttributesFromPaint(paint, FlagsForPointMode(mode));
  drawPoints(mode, count, pts);
}
void DisplayListBuilder::drawVertices(const DlVertices* vertices,
                                      DlBlendMode mode) {
  DisplayListAttributeFlags flags = kDrawVerticesFlags;
  OpResult result = PaintResult(current_, flags);
  if (result != OpResult::kNoEffect &&
      AccumulateOpBounds(vertices->bounds(), flags)) {
    void* pod = Push<DrawVerticesOp>(vertices->size(), 1, mode);
    new (pod) DlVertices(vertices);
    // DrawVertices applies its colors to the paint so we have no way
    // of controlling opacity using the current paint attributes.
    // Although, examination of the |mode| might find some predictable
    // cases.
    UpdateLayerOpacityCompatibility(false);
    UpdateLayerResult(result);
  }
}
void DisplayListBuilder::DrawVertices(const DlVertices* vertices,
                                      DlBlendMode mode,
                                      const DlPaint& paint) {
  SetAttributesFromPaint(paint, DisplayListOpFlags::kDrawVerticesFlags);
  drawVertices(vertices, mode);
}

void DisplayListBuilder::drawImage(const sk_sp<DlImage> image,
                                   const SkPoint point,
                                   DlImageSampling sampling,
                                   bool render_with_attributes) {
  DisplayListAttributeFlags flags = render_with_attributes  //
                                        ? kDrawImageWithPaintFlags
                                        : kDrawImageFlags;
  OpResult result = PaintResult(current_, flags);
  if (result == OpResult::kNoEffect) {
    return;
  }
  SkRect bounds = SkRect::MakeXYWH(point.fX, point.fY,  //
                                   image->width(), image->height());
  if (AccumulateOpBounds(bounds, flags)) {
    render_with_attributes
        ? Push<DrawImageWithAttrOp>(0, 1, image, point, sampling)
        : Push<DrawImageOp>(0, 1, image, point, sampling);
    CheckLayerOpacityCompatibility(render_with_attributes);
    UpdateLayerResult(result);
    is_ui_thread_safe_ = is_ui_thread_safe_ && image->isUIThreadSafe();
  }
}
void DisplayListBuilder::DrawImage(const sk_sp<DlImage>& image,
                                   const SkPoint point,
                                   DlImageSampling sampling,
                                   const DlPaint* paint) {
  if (paint != nullptr) {
    SetAttributesFromPaint(*paint,
                           DisplayListOpFlags::kDrawImageWithPaintFlags);
    drawImage(image, point, sampling, true);
  } else {
    drawImage(image, point, sampling, false);
  }
}
void DisplayListBuilder::drawImageRect(const sk_sp<DlImage> image,
                                       const SkRect& src,
                                       const SkRect& dst,
                                       DlImageSampling sampling,
                                       bool render_with_attributes,
                                       SrcRectConstraint constraint) {
  DisplayListAttributeFlags flags = render_with_attributes
                                        ? kDrawImageRectWithPaintFlags
                                        : kDrawImageRectFlags;
  OpResult result = PaintResult(current_, flags);
  if (result != OpResult::kNoEffect && AccumulateOpBounds(dst, flags)) {
    Push<DrawImageRectOp>(0, 1, image, src, dst, sampling,
                          render_with_attributes, constraint);
    CheckLayerOpacityCompatibility(render_with_attributes);
    UpdateLayerResult(result);
    is_ui_thread_safe_ = is_ui_thread_safe_ && image->isUIThreadSafe();
  }
}
void DisplayListBuilder::DrawImageRect(const sk_sp<DlImage>& image,
                                       const SkRect& src,
                                       const SkRect& dst,
                                       DlImageSampling sampling,
                                       const DlPaint* paint,
                                       SrcRectConstraint constraint) {
  if (paint != nullptr) {
    SetAttributesFromPaint(*paint,
                           DisplayListOpFlags::kDrawImageRectWithPaintFlags);
    drawImageRect(image, src, dst, sampling, true, constraint);
  } else {
    drawImageRect(image, src, dst, sampling, false, constraint);
  }
}
void DisplayListBuilder::drawImageNine(const sk_sp<DlImage> image,
                                       const SkIRect& center,
                                       const SkRect& dst,
                                       DlFilterMode filter,
                                       bool render_with_attributes) {
  DisplayListAttributeFlags flags = render_with_attributes
                                        ? kDrawImageNineWithPaintFlags
                                        : kDrawImageNineFlags;
  OpResult result = PaintResult(current_, flags);
  if (result != OpResult::kNoEffect && AccumulateOpBounds(dst, flags)) {
    render_with_attributes
        ? Push<DrawImageNineWithAttrOp>(0, 1, image, center, dst, filter)
        : Push<DrawImageNineOp>(0, 1, image, center, dst, filter);
    CheckLayerOpacityCompatibility(render_with_attributes);
    UpdateLayerResult(result);
    is_ui_thread_safe_ = is_ui_thread_safe_ && image->isUIThreadSafe();
  }
}
void DisplayListBuilder::DrawImageNine(const sk_sp<DlImage>& image,
                                       const SkIRect& center,
                                       const SkRect& dst,
                                       DlFilterMode filter,
                                       const DlPaint* paint) {
  if (paint != nullptr) {
    SetAttributesFromPaint(*paint,
                           DisplayListOpFlags::kDrawImageNineWithPaintFlags);
    drawImageNine(image, center, dst, filter, true);
  } else {
    drawImageNine(image, center, dst, filter, false);
  }
}
void DisplayListBuilder::drawAtlas(const sk_sp<DlImage> atlas,
                                   const SkRSXform xform[],
                                   const SkRect tex[],
                                   const DlColor colors[],
                                   int count,
                                   DlBlendMode mode,
                                   DlImageSampling sampling,
                                   const SkRect* cull_rect,
                                   bool render_with_attributes) {
  DisplayListAttributeFlags flags = render_with_attributes  //
                                        ? kDrawAtlasWithPaintFlags
                                        : kDrawAtlasFlags;
  OpResult result = PaintResult(current_, flags);
  if (result == OpResult::kNoEffect) {
    return;
  }
  SkPoint quad[4];
  RectBoundsAccumulator atlasBounds;
  for (int i = 0; i < count; i++) {
    const SkRect& src = tex[i];
    xform[i].toQuad(src.width(), src.height(), quad);
    for (int j = 0; j < 4; j++) {
      atlasBounds.accumulate(quad[j]);
    }
  }
  if (atlasBounds.is_empty() ||
      !AccumulateOpBounds(atlasBounds.bounds(), flags)) {
    return;
  }

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
  // drawAtlas treats each image as a separate operation so we cannot rely
  // on it to distribute the opacity without overlap without checking all
  // of the transforms and texture rectangles.
  UpdateLayerOpacityCompatibility(false);
  UpdateLayerResult(result);
  is_ui_thread_safe_ = is_ui_thread_safe_ && atlas->isUIThreadSafe();
}
void DisplayListBuilder::DrawAtlas(const sk_sp<DlImage>& atlas,
                                   const SkRSXform xform[],
                                   const SkRect tex[],
                                   const DlColor colors[],
                                   int count,
                                   DlBlendMode mode,
                                   DlImageSampling sampling,
                                   const SkRect* cull_rect,
                                   const DlPaint* paint) {
  if (paint != nullptr) {
    SetAttributesFromPaint(*paint,
                           DisplayListOpFlags::kDrawAtlasWithPaintFlags);
    drawAtlas(atlas, xform, tex, colors, count, mode, sampling, cull_rect,
              true);
  } else {
    drawAtlas(atlas, xform, tex, colors, count, mode, sampling, cull_rect,
              false);
  }
}

void DisplayListBuilder::DrawDisplayList(const sk_sp<DisplayList> display_list,
                                         SkScalar opacity) {
  if (!SkScalarIsFinite(opacity) || opacity <= SK_ScalarNearlyZero ||
      display_list->op_count() == 0 || display_list->bounds().isEmpty() ||
      current_layer_->is_nop_) {
    return;
  }
  const SkRect bounds = display_list->bounds();
  bool accumulated;
  switch (accumulator()->type()) {
    case BoundsAccumulatorType::kRect:
      accumulated = AccumulateOpBounds(bounds, kDrawDisplayListFlags);
      break;
    case BoundsAccumulatorType::kRTree:
      auto rtree = display_list->rtree();
      if (rtree) {
        std::list<SkRect> rects =
            rtree->searchAndConsolidateRects(GetLocalClipBounds(), false);
        accumulated = false;
        for (const SkRect& rect : rects) {
          // TODO (https://github.com/flutter/flutter/issues/114919): Attributes
          // are not necessarily `kDrawDisplayListFlags`.
          if (AccumulateOpBounds(rect, kDrawDisplayListFlags)) {
            accumulated = true;
          }
        }
      } else {
        accumulated = AccumulateOpBounds(bounds, kDrawDisplayListFlags);
      }
      break;
  }
  if (!accumulated) {
    return;
  }

  DlPaint current_paint = current_;
  Push<DrawDisplayListOp>(0, 1, display_list,
                          opacity < SK_Scalar1 ? opacity : SK_Scalar1);
  is_ui_thread_safe_ = is_ui_thread_safe_ && display_list->isUIThreadSafe();
  // Not really necessary if the developer is interacting with us via
  // our attribute-state-less DlCanvas methods, but this avoids surprises
  // for those who may have been using the stateful Dispatcher methods.
  SetAttributesFromPaint(current_paint,
                         DisplayListOpFlags::kSaveLayerWithPaintFlags);

  // The non-nested op count accumulated in the |Push| method will include
  // this call to |drawDisplayList| for non-nested op count metrics.
  // But, for nested op count metrics we want the |drawDisplayList| call itself
  // to be transparent. So we subtract 1 from our accumulated nested count to
  // balance out against the 1 that was accumulated into the regular count.
  // This behavior is identical to the way SkPicture computed nested op counts.
  nested_op_count_ += display_list->op_count(true) - 1;
  nested_bytes_ += display_list->bytes(true);
  UpdateLayerOpacityCompatibility(display_list->can_apply_group_opacity());
  // Nop DisplayLists are eliminated above so we either affect transparent
  // pixels or we do not. We should not have [kNoEffect].
  UpdateLayerResult(display_list->modifies_transparent_black()
                        ? OpResult::kAffectsAll
                        : OpResult::kPreservesTransparency);
}
void DisplayListBuilder::drawTextBlob(const sk_sp<SkTextBlob> blob,
                                      SkScalar x,
                                      SkScalar y) {
  DisplayListAttributeFlags flags = kDrawTextBlobFlags;
  OpResult result = PaintResult(current_, flags);
  if (result == OpResult::kNoEffect) {
    return;
  }
  bool unclipped = AccumulateOpBounds(blob->bounds().makeOffset(x, y), flags);
  // TODO(https://github.com/flutter/flutter/issues/82202): Remove once the
  // unit tests can use Fuchsia's font manager instead of the empty default.
  // Until then we might encounter empty bounds for otherwise valid text and
  // thus we ignore the results from AccumulateOpBounds.
#if defined(OS_FUCHSIA)
  unclipped = true;
#endif  // OS_FUCHSIA
  if (unclipped) {
    Push<DrawTextBlobOp>(0, 1, blob, x, y);
    // There is no way to query if the glyphs of a text blob overlap and
    // there are no current guarantees from either Skia or Impeller that
    // they will protect overlapping glyphs from the effects of overdraw
    // so we must make the conservative assessment that this DL layer is
    // not compatible with group opacity inheritance.
    UpdateLayerOpacityCompatibility(false);
    UpdateLayerResult(result);
  }
}
void DisplayListBuilder::DrawTextBlob(const sk_sp<SkTextBlob>& blob,
                                      SkScalar x,
                                      SkScalar y,
                                      const DlPaint& paint) {
  SetAttributesFromPaint(paint, DisplayListOpFlags::kDrawTextBlobFlags);
  drawTextBlob(blob, x, y);
}

void DisplayListBuilder::drawTextFrame(
    const std::shared_ptr<impeller::TextFrame>& text_frame,
    SkScalar x,
    SkScalar y) {
  DisplayListAttributeFlags flags = kDrawTextBlobFlags;
  OpResult result = PaintResult(current_, flags);
  if (result == OpResult::kNoEffect) {
    return;
  }
  impeller::Rect bounds = text_frame->GetBounds();
  SkRect sk_bounds = SkRect::MakeLTRB(bounds.GetLeft(), bounds.GetTop(),
                                      bounds.GetRight(), bounds.GetBottom());
  bool unclipped = AccumulateOpBounds(sk_bounds.makeOffset(x, y), flags);
  // TODO(https://github.com/flutter/flutter/issues/82202): Remove once the
  // unit tests can use Fuchsia's font manager instead of the empty default.
  // Until then we might encounter empty bounds for otherwise valid text and
  // thus we ignore the results from AccumulateOpBounds.
#if defined(OS_FUCHSIA)
  unclipped = true;
#endif  // OS_FUCHSIA
  if (unclipped) {
    Push<DrawTextFrameOp>(0, 1, text_frame, x, y);
    // There is no way to query if the glyphs of a text blob overlap and
    // there are no current guarantees from either Skia or Impeller that
    // they will protect overlapping glyphs from the effects of overdraw
    // so we must make the conservative assessment that this DL layer is
    // not compatible with group opacity inheritance.
    UpdateLayerOpacityCompatibility(false);
    UpdateLayerResult(result);
  }
}

void DisplayListBuilder::DrawTextFrame(
    const std::shared_ptr<impeller::TextFrame>& text_frame,
    SkScalar x,
    SkScalar y,
    const DlPaint& paint) {
  SetAttributesFromPaint(paint, DisplayListOpFlags::kDrawTextBlobFlags);
  drawTextFrame(text_frame, x, y);
}

void DisplayListBuilder::DrawShadow(const SkPath& path,
                                    const DlColor color,
                                    const SkScalar elevation,
                                    bool transparent_occluder,
                                    SkScalar dpr) {
  OpResult result = PaintResult(DlPaint(color));
  if (result != OpResult::kNoEffect) {
    SkRect shadow_bounds =
        DlCanvas::ComputeShadowBounds(path, elevation, dpr, GetTransform());
    if (AccumulateOpBounds(shadow_bounds, kDrawShadowFlags)) {
      transparent_occluder  //
          ? Push<DrawShadowTransparentOccluderOp>(0, 1, path, color, elevation,
                                                  dpr)
          : Push<DrawShadowOp>(0, 1, path, color, elevation, dpr);
      UpdateLayerOpacityCompatibility(false);
      UpdateLayerResult(result);
    }
  }
}

bool DisplayListBuilder::ComputeFilteredBounds(SkRect& bounds,
                                               const DlImageFilter* filter) {
  if (filter) {
    if (!filter->map_local_bounds(bounds, bounds)) {
      return false;
    }
  }
  return true;
}

bool DisplayListBuilder::AdjustBoundsForPaint(SkRect& bounds,
                                              DisplayListAttributeFlags flags) {
  if (flags.ignores_paint()) {
    return true;
  }

  if (flags.is_geometric()) {
    bool is_stroked = flags.is_stroked(current_.getDrawStyle());

    // Path effect occurs before stroking...
    DisplayListSpecialGeometryFlags special_flags =
        flags.WithPathEffect(current_.getPathEffectPtr(), is_stroked);
    if (current_.getPathEffect()) {
      auto effect_bounds = current_.getPathEffect()->effect_bounds(bounds);
      if (!effect_bounds.has_value()) {
        return false;
      }
      bounds = effect_bounds.value();
    }

    if (is_stroked) {
      // Determine the max multiplier to the stroke width first.
      SkScalar pad = 1.0f;
      if (current_.getStrokeJoin() == DlStrokeJoin::kMiter &&
          special_flags.may_have_acute_joins()) {
        pad = std::max(pad, current_.getStrokeMiter());
      }
      if (current_.getStrokeCap() == DlStrokeCap::kSquare &&
          special_flags.may_have_diagonal_caps()) {
        pad = std::max(pad, SK_ScalarSqrt2);
      }
      SkScalar min_stroke_width = 0.01;
      pad *= std::max(current_.getStrokeWidth() * 0.5f, min_stroke_width);
      bounds.outset(pad, pad);
    }
  }

  if (flags.applies_mask_filter()) {
    auto filter = current_.getMaskFilter();
    if (filter) {
      switch (filter->type()) {
        case DlMaskFilterType::kBlur: {
          FML_DCHECK(filter->asBlur());
          SkScalar mask_sigma_pad = filter->asBlur()->sigma() * 3.0;
          bounds.outset(mask_sigma_pad, mask_sigma_pad);
        }
      }
    }
  }

  if (flags.applies_image_filter()) {
    return ComputeFilteredBounds(bounds, current_.getImageFilter().get());
  }

  return true;
}

bool DisplayListBuilder::AccumulateUnbounded() {
  SkRect clip = tracker_.device_cull_rect();
  if (clip.isEmpty()) {
    return false;
  }
  accumulator()->accumulate(clip, op_index_);
  return true;
}

bool DisplayListBuilder::AccumulateOpBounds(SkRect& bounds,
                                            DisplayListAttributeFlags flags) {
  if (AdjustBoundsForPaint(bounds, flags)) {
    return AccumulateBounds(bounds);
  } else {
    return AccumulateUnbounded();
  }
}
bool DisplayListBuilder::AccumulateBounds(SkRect& bounds) {
  if (!bounds.isEmpty()) {
    tracker_.mapRect(&bounds);
    if (bounds.intersect(tracker_.device_cull_rect())) {
      accumulator()->accumulate(bounds, op_index_);
      return true;
    }
  }
  return false;
}

bool DisplayListBuilder::paint_nops_on_transparency() {
  // SkImageFilter::canComputeFastBounds tests for transparency behavior
  // This test assumes that the blend mode checked down below will
  // NOP on transparent black.
  if (current_.getImageFilterPtr() &&
      current_.getImageFilterPtr()->modifies_transparent_black()) {
    return false;
  }

  // We filter the transparent black that is used for the background of a
  // saveLayer and make sure it returns transparent black. If it does, then
  // the color filter will leave all area surrounding the contents of the
  // save layer untouched out to the edge of the output surface.
  // This test assumes that the blend mode checked down below will
  // NOP on transparent black.
  if (current_.getColorFilterPtr() &&
      current_.getColorFilterPtr()->modifies_transparent_black()) {
    return false;
  }

  // Unusual blendmodes require us to process a saved layer
  // even with operations outside the clip.
  // For example, DstIn is used by masking layers.
  // https://code.google.com/p/skia/issues/detail?id=1291
  // https://crbug.com/401593
  switch (current_.getBlendMode()) {
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

DlColor DisplayListBuilder::GetEffectiveColor(const DlPaint& paint,
                                              DisplayListAttributeFlags flags) {
  DlColor color;
  if (flags.applies_color()) {
    const DlColorSource* source = paint.getColorSourcePtr();
    if (source) {
      if (source->asColor()) {
        color = source->asColor()->color();
      } else {
        color = source->is_opaque() ? DlColor::kBlack() : kAnyColor;
      }
    } else {
      color = paint.getColor();
    }
  } else if (flags.applies_alpha()) {
    // If the operation applies alpha, but not color, then the only impact
    // of the alpha is to modulate the output towards transparency.
    // We can not guarantee an opaque source even if the alpha is opaque
    // since that would require knowing something about the colors that
    // the alpha is modulating, but we can guarantee a transparent source
    // if the alpha is 0.
    color = (paint.getAlpha() == 0) ? DlColor::kTransparent() : kAnyColor;
  } else {
    color = kAnyColor;
  }
  if (flags.applies_image_filter()) {
    auto filter = paint.getImageFilterPtr();
    if (filter) {
      if (!color.isTransparent() || filter->modifies_transparent_black()) {
        color = kAnyColor;
      }
    }
  }
  if (flags.applies_color_filter()) {
    auto filter = paint.getColorFilterPtr();
    if (filter) {
      if (!color.isTransparent() || filter->modifies_transparent_black()) {
        color = kAnyColor;
      }
    }
  }
  return color;
}

DisplayListBuilder::OpResult DisplayListBuilder::PaintResult(
    const DlPaint& paint,
    DisplayListAttributeFlags flags) {
  if (current_layer_->is_nop_) {
    return OpResult::kNoEffect;
  }
  if (flags.applies_blend()) {
    switch (paint.getBlendMode()) {
      // Nop blend mode (singular, there is only one)
      case DlBlendMode::kDst:
        return OpResult::kNoEffect;

      // Always clears pixels blend mode (singular, there is only one)
      case DlBlendMode::kClear:
        return OpResult::kPreservesTransparency;

      case DlBlendMode::kHue:
      case DlBlendMode::kSaturation:
      case DlBlendMode::kColor:
      case DlBlendMode::kLuminosity:
      case DlBlendMode::kColorBurn:
        return GetEffectiveColor(paint, flags).isTransparent()
                   ? OpResult::kNoEffect
                   : OpResult::kAffectsAll;

      // kSrcIn modifies pixels towards transparency
      case DlBlendMode::kSrcIn:
        return OpResult::kPreservesTransparency;

      // These blend modes preserve destination alpha
      case DlBlendMode::kSrcATop:
      case DlBlendMode::kDstOut:
        return GetEffectiveColor(paint, flags).isTransparent()
                   ? OpResult::kNoEffect
                   : OpResult::kPreservesTransparency;

      // Always destructive blend modes, potentially not affecting transparency
      case DlBlendMode::kSrc:
      case DlBlendMode::kSrcOut:
      case DlBlendMode::kDstATop:
        return GetEffectiveColor(paint, flags).isTransparent()
                   ? OpResult::kPreservesTransparency
                   : OpResult::kAffectsAll;

      // The kDstIn blend mode modifies the destination unless the
      // source color is opaque.
      case DlBlendMode::kDstIn:
        return GetEffectiveColor(paint, flags).isOpaque()
                   ? OpResult::kNoEffect
                   : OpResult::kPreservesTransparency;

      // The next group of blend modes modifies the destination unless the
      // source color is transparent.
      case DlBlendMode::kSrcOver:
      case DlBlendMode::kDstOver:
      case DlBlendMode::kXor:
      case DlBlendMode::kPlus:
      case DlBlendMode::kScreen:
      case DlBlendMode::kMultiply:
      case DlBlendMode::kOverlay:
      case DlBlendMode::kDarken:
      case DlBlendMode::kLighten:
      case DlBlendMode::kColorDodge:
      case DlBlendMode::kHardLight:
      case DlBlendMode::kSoftLight:
      case DlBlendMode::kDifference:
      case DlBlendMode::kExclusion:
        return GetEffectiveColor(paint, flags).isTransparent()
                   ? OpResult::kNoEffect
                   : OpResult::kAffectsAll;

      // Modulate only leaves the pixel alone when the source is white.
      case DlBlendMode::kModulate:
        return GetEffectiveColor(paint, flags) == DlColor::kWhite()
                   ? OpResult::kNoEffect
                   : OpResult::kPreservesTransparency;
    }
  }
  return OpResult::kAffectsAll;
}

}  // namespace flutter
