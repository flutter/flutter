// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_builder.h"

#include "flutter/display_list/display_list_blend_mode.h"
#include "flutter/display_list/display_list_ops.h"

namespace flutter {

#define DL_BUILDER_PAGE 4096

// CopyV(dst, src,n, src,n, ...) copies any number of typed srcs into dst.
static void CopyV(void* dst) {}

template <typename S, typename... Rest>
static void CopyV(void* dst, const S* src, int n, Rest&&... rest) {
  FML_DCHECK(((uintptr_t)dst & (alignof(S) - 1)) == 0)
      << "Expected " << dst << " to be aligned for at least " << alignof(S)
      << " bytes.";
  sk_careful_memcpy(dst, src, n * sizeof(S));
  CopyV(SkTAddOffset<void>(dst, n * sizeof(S)), std::forward<Rest>(rest)...);
}

template <typename T, typename... Args>
void* DisplayListBuilder::Push(size_t pod, int op_inc, Args&&... args) {
  size_t size = SkAlignPtr(sizeof(T) + pod);
  FML_DCHECK(size < (1 << 24));
  if (used_ + size > allocated_) {
    static_assert(SkIsPow2(DL_BUILDER_PAGE),
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
  op_count_ += op_inc;
  return op + 1;
}

sk_sp<DisplayList> DisplayListBuilder::Build() {
  while (layer_stack_.size() > 1) {
    restore();
  }
  size_t bytes = used_;
  int count = op_count_;
  size_t nested_bytes = nested_bytes_;
  int nested_count = nested_op_count_;
  used_ = allocated_ = op_count_ = 0;
  nested_bytes_ = nested_op_count_ = 0;
  storage_.realloc(bytes);
  bool compatible = layer_stack_.back().is_group_opacity_compatible();
  return sk_sp<DisplayList>(new DisplayList(storage_.release(), bytes, count,
                                            nested_bytes, nested_count,
                                            cull_rect_, compatible));
}

DisplayListBuilder::DisplayListBuilder(const SkRect& cull_rect)
    : cull_rect_(cull_rect) {
  layer_stack_.emplace_back(SkM44(), cull_rect);
  current_layer_ = &layer_stack_.back();
}

DisplayListBuilder::~DisplayListBuilder() {
  uint8_t* ptr = storage_.get();
  if (ptr) {
    DisplayList::DisposeOps(ptr, ptr + used_);
  }
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
void DisplayListBuilder::onSetStyle(DlDrawStyle style) {
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
  current_blender_ = nullptr;
  current_.setBlendMode(mode);
  Push<SetBlendModeOp>(0, 0, mode);
  UpdateCurrentOpacityCompatibility();
}
void DisplayListBuilder::onSetBlender(sk_sp<SkBlender> blender) {
  // setBlender(nullptr) should be redirected to setBlendMode(SrcOver)
  // by the set method, if not then the following is inefficient but works
  FML_DCHECK(blender);
  SkPaint p;
  p.setBlender(blender);
  if (p.asBlendMode()) {
    setBlendMode(ToDl(p.asBlendMode().value()));
  } else {
    // |current_blender_| supersedes any value of |current_blend_mode_|
    (current_blender_ = blender)  //
        ? Push<SetBlenderOp>(0, 0, std::move(blender))
        : Push<ClearBlenderOp>(0, 0);
    UpdateCurrentOpacityCompatibility();
  }
}
void DisplayListBuilder::onSetColorSource(const DlColorSource* source) {
  if (source == nullptr) {
    current_.setColorSource(nullptr);
    Push<ClearColorSourceOp>(0, 0);
  } else {
    current_.setColorSource(source->shared());
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
      case DlColorSourceType::kUnknown:
        Push<SetSkColorSourceOp>(0, 0, source->skia_object());
        break;
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
      case DlImageFilterType::kComposeFilter:
      case DlImageFilterType::kColorFilter: {
        Push<SetSharedImageFilterOp>(0, 0, filter);
        break;
      }
      case DlImageFilterType::kUnknown: {
        Push<SetSkImageFilterOp>(0, 0, filter->skia_object());
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
      case DlColorFilterType::kUnknown: {
        Push<SetSkColorFilterOp>(0, 0, filter->skia_object());
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
      case DlPathEffectType::kUnknown: {
        Push<SetSkPathEffectOp>(0, 0, effect->skia_object());
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
      case DlMaskFilterType::kUnknown:
        Push<SetSkMaskFilterOp>(0, 0, filter->skia_object());
        break;
    }
  }
}

void DisplayListBuilder::setAttributesFromDlPaint(
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
    setStyle(paint.getDrawStyle());
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
  // Waiting for https://github.com/flutter/engine/pull/32159
  // if (flags.applies_path_effect()) {
  //   setPathEffect(sk_ref_sp(paint.getPathEffect()));
  // }
  if (flags.applies_mask_filter()) {
    setMaskFilter(paint.getMaskFilter().get());
  }
}

void DisplayListBuilder::setAttributesFromPaint(
    const SkPaint& paint,
    const DisplayListAttributeFlags flags) {
  if (flags.applies_anti_alias()) {
    setAntiAlias(paint.isAntiAlias());
  }
  if (flags.applies_dither()) {
    setDither(paint.isDither());
  }
  if (flags.applies_alpha_or_color()) {
    setColor(paint.getColor());
  }
  if (flags.applies_blend()) {
    std::optional<SkBlendMode> mode_optional = paint.asBlendMode();
    if (mode_optional) {
      setBlendMode(ToDl(mode_optional.value()));
    } else {
      setBlender(sk_ref_sp(paint.getBlender()));
    }
  }
  if (flags.applies_style()) {
    setStyle(ToDl(paint.getStyle()));
  }
  if (flags.is_stroked(ToDl(paint.getStyle()))) {
    setStrokeWidth(paint.getStrokeWidth());
    setStrokeMiter(paint.getStrokeMiter());
    setStrokeCap(ToDl(paint.getStrokeCap()));
    setStrokeJoin(ToDl(paint.getStrokeJoin()));
  }
  if (flags.applies_shader()) {
    SkShader* shader = paint.getShader();
    setColorSource(DlColorSource::From(shader).get());
  }
  if (flags.applies_color_filter()) {
    // invert colors is a Flutter::Paint thing, not an SkPaint thing
    // we must clear it because it is a second potential color filter
    // that is composed with the paint's color filter.
    setInvertColors(false);
    SkColorFilter* color_filter = paint.getColorFilter();
    setColorFilter(DlColorFilter::From(color_filter).get());
  }
  if (flags.applies_image_filter()) {
    setImageFilter(DlImageFilter::From(paint.getImageFilter()).get());
  }
  if (flags.applies_path_effect()) {
    SkPathEffect* path_effect = paint.getPathEffect();
    setPathEffect(DlPathEffect::From(path_effect).get());
  }
  if (flags.applies_mask_filter()) {
    SkMaskFilter* mask_filter = paint.getMaskFilter();
    setMaskFilter(DlMaskFilter::From(mask_filter).get());
  }
}

void DisplayListBuilder::save() {
  Push<SaveOp>(0, 1);
  layer_stack_.emplace_back(current_layer_);
  current_layer_ = &layer_stack_.back();
}
void DisplayListBuilder::restore() {
  if (layer_stack_.size() > 1) {
    // Grab the current layer info before we push the restore
    // on the stack.
    LayerInfo layer_info = layer_stack_.back();
    layer_stack_.pop_back();
    current_layer_ = &layer_stack_.back();
    Push<RestoreOp>(0, 1);
    if (layer_info.has_layer) {
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
        SaveLayerOp* op = reinterpret_cast<SaveLayerOp*>(
            storage_.get() + layer_info.save_layer_offset);
        op->options = op->options.with_can_distribute_opacity();
      }
    } else {
      // For regular save() ops there was no protecting layer so we have to
      // accumulate the values into the enclosing layer.
      if (layer_info.cannot_inherit_opacity) {
        current_layer_->mark_incompatible();
      } else if (layer_info.has_compatible_op) {
        current_layer_->add_compatible_op();
      }
    }
  }
}
void DisplayListBuilder::restoreToCount(int restore_count) {
  FML_DCHECK(restore_count <= getSaveCount());
  while (restore_count < getSaveCount()) {
    restore();
  }
}
void DisplayListBuilder::saveLayer(const SkRect* bounds,
                                   const SaveLayerOptions in_options,
                                   const DlImageFilter* backdrop) {
  SaveLayerOptions options = in_options.without_optimizations();
  size_t save_layer_offset = used_;
  if (backdrop) {
    bounds  //
        ? Push<SaveLayerBackdropBoundsOp>(0, 1, *bounds, options, backdrop)
        : Push<SaveLayerBackdropOp>(0, 1, options, backdrop);
  } else {
    bounds  //
        ? Push<SaveLayerBoundsOp>(0, 1, *bounds, options)
        : Push<SaveLayerOp>(0, 1, options);
  }
  CheckLayerOpacityCompatibility(options.renders_with_attributes());
  layer_stack_.emplace_back(current_layer_, save_layer_offset, true);
  current_layer_ = &layer_stack_.back();
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
}
void DisplayListBuilder::saveLayer(const SkRect* bounds,
                                   const DlPaint* paint,
                                   const DlImageFilter* backdrop) {
  if (paint != nullptr) {
    setAttributesFromDlPaint(*paint,
                             DisplayListOpFlags::kSaveLayerWithPaintFlags);
    saveLayer(bounds, SaveLayerOptions::kWithAttributes, backdrop);
  } else {
    saveLayer(bounds, SaveLayerOptions::kNoAttributes, backdrop);
  }
}

void DisplayListBuilder::translate(SkScalar tx, SkScalar ty) {
  if (SkScalarIsFinite(tx) && SkScalarIsFinite(ty) &&
      (tx != 0.0 || ty != 0.0)) {
    Push<TranslateOp>(0, 1, tx, ty);
    current_layer_->matrix.preTranslate(tx, ty);
  }
}
void DisplayListBuilder::scale(SkScalar sx, SkScalar sy) {
  if (SkScalarIsFinite(sx) && SkScalarIsFinite(sy) &&
      (sx != 1.0 || sy != 1.0)) {
    Push<ScaleOp>(0, 1, sx, sy);
    current_layer_->matrix.preScale(sx, sy);
  }
}
void DisplayListBuilder::rotate(SkScalar degrees) {
  if (SkScalarMod(degrees, 360.0) != 0.0) {
    Push<RotateOp>(0, 1, degrees);
    current_layer_->matrix.preConcat(SkMatrix::RotateDeg(degrees));
  }
}
void DisplayListBuilder::skew(SkScalar sx, SkScalar sy) {
  if (SkScalarIsFinite(sx) && SkScalarIsFinite(sy) &&
      (sx != 0.0 || sy != 0.0)) {
    Push<SkewOp>(0, 1, sx, sy);
    current_layer_->matrix.preConcat(SkMatrix::Skew(sx, sy));
  }
}

// clang-format off

// 2x3 2D affine subset of a 4x4 transform in row major order
void DisplayListBuilder::transform2DAffine(
    SkScalar mxx, SkScalar mxy, SkScalar mxt,
    SkScalar myx, SkScalar myy, SkScalar myt) {
  if (SkScalarsAreFinite(mxx, myx) &&
      SkScalarsAreFinite(mxy, myy) &&
      SkScalarsAreFinite(mxt, myt) &&
      !(mxx == 1 && mxy == 0 && mxt == 0 &&
        myx == 0 && myy == 1 && myt == 0)) {
    Push<Transform2DAffineOp>(0, 1,
                              mxx, mxy, mxt,
                              myx, myy, myt);
    current_layer_->matrix.preConcat(SkM44(mxx, mxy,  0,  mxt,
                                           myx, myy,  0,  myt,
                                            0,   0,   1,   0,
                                            0,   0,   0,   1));
  }
}
// full 4x4 transform in row major order
void DisplayListBuilder::transformFullPerspective(
    SkScalar mxx, SkScalar mxy, SkScalar mxz, SkScalar mxt,
    SkScalar myx, SkScalar myy, SkScalar myz, SkScalar myt,
    SkScalar mzx, SkScalar mzy, SkScalar mzz, SkScalar mzt,
    SkScalar mwx, SkScalar mwy, SkScalar mwz, SkScalar mwt) {
  if (                        mxz == 0 &&
                              myz == 0 &&
      mzx == 0 && mzy == 0 && mzz == 1 && mzt == 0 &&
      mwx == 0 && mwy == 0 && mwz == 0 && mwt == 1) {
    transform2DAffine(mxx, mxy, mxt,
                      myx, myy, myt);
  } else if (SkScalarsAreFinite(mxx, mxy) && SkScalarsAreFinite(mxz, mxt) &&
             SkScalarsAreFinite(myx, myy) && SkScalarsAreFinite(myz, myt) &&
             SkScalarsAreFinite(mzx, mzy) && SkScalarsAreFinite(mzz, mzt) &&
             SkScalarsAreFinite(mwx, mwy) && SkScalarsAreFinite(mwz, mwt)) {
    Push<TransformFullPerspectiveOp>(0, 1,
                                     mxx, mxy, mxz, mxt,
                                     myx, myy, myz, myt,
                                     mzx, mzy, mzz, mzt,
                                     mwx, mwy, mwz, mwt);
    current_layer_->matrix.preConcat(SkM44(mxx, mxy, mxz, mxt,
                                           myx, myy, myz, myt,
                                           mzx, mzy, mzz, mzt,
                                           mwx, mwy, mwz, mwt));
  }
}
// clang-format on
void DisplayListBuilder::transformReset() {
  Push<TransformResetOp>(0, 0);
  current_layer_->matrix.setIdentity();
}
void DisplayListBuilder::transform(const SkMatrix* matrix) {
  if (matrix != nullptr) {
    transform(SkM44(*matrix));
  }
}
void DisplayListBuilder::transform(const SkM44* m44) {
  if (m44 != nullptr) {
    transformFullPerspective(
        m44->rc(0, 0), m44->rc(0, 1), m44->rc(0, 2), m44->rc(0, 3),
        m44->rc(1, 0), m44->rc(1, 1), m44->rc(1, 2), m44->rc(1, 3),
        m44->rc(2, 0), m44->rc(2, 1), m44->rc(2, 2), m44->rc(2, 3),
        m44->rc(3, 0), m44->rc(3, 1), m44->rc(3, 2), m44->rc(3, 3));
  }
}

void DisplayListBuilder::clipRect(const SkRect& rect,
                                  SkClipOp clip_op,
                                  bool is_aa) {
  switch (clip_op) {
    case SkClipOp::kIntersect:
      Push<ClipIntersectRectOp>(0, 1, rect, is_aa);
      if (!current_layer_->clip_bounds.intersect(rect)) {
        current_layer_->clip_bounds.setEmpty();
      }
      break;
    case SkClipOp::kDifference:
      Push<ClipDifferenceRectOp>(0, 1, rect, is_aa);
      break;
  }
}
void DisplayListBuilder::clipRRect(const SkRRect& rrect,
                                   SkClipOp clip_op,
                                   bool is_aa) {
  if (rrect.isRect()) {
    clipRect(rrect.rect(), clip_op, is_aa);
  } else {
    switch (clip_op) {
      case SkClipOp::kIntersect:
        Push<ClipIntersectRRectOp>(0, 1, rrect, is_aa);
        if (!current_layer_->clip_bounds.intersect(rrect.getBounds())) {
          current_layer_->clip_bounds.setEmpty();
        }
        break;
      case SkClipOp::kDifference:
        Push<ClipDifferenceRRectOp>(0, 1, rrect, is_aa);
        break;
    }
  }
}
void DisplayListBuilder::clipPath(const SkPath& path,
                                  SkClipOp clip_op,
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
  switch (clip_op) {
    case SkClipOp::kIntersect:
      Push<ClipIntersectPathOp>(0, 1, path, is_aa);
      if (!current_layer_->clip_bounds.intersect(path.getBounds())) {
        current_layer_->clip_bounds.setEmpty();
      }
      break;
    case SkClipOp::kDifference:
      Push<ClipDifferencePathOp>(0, 1, path, is_aa);
      break;
  }
}
SkRect DisplayListBuilder::getLocalClipBounds() {
  SkM44 inverse;
  if (current_layer_->matrix.invert(&inverse)) {
    SkRect devBounds;
    current_layer_->clip_bounds.roundOut(&devBounds);
    return inverse.asM33().mapRect(devBounds);
  }
  return kMaxCullRect_;
}

void DisplayListBuilder::drawPaint() {
  Push<DrawPaintOp>(0, 1);
  CheckLayerOpacityCompatibility();
}
void DisplayListBuilder::drawPaint(const DlPaint& paint) {
  setAttributesFromDlPaint(paint, DisplayListOpFlags::kDrawPaintFlags);
  drawPaint();
}
void DisplayListBuilder::drawColor(DlColor color, DlBlendMode mode) {
  Push<DrawColorOp>(0, 1, color, mode);
  CheckLayerOpacityCompatibility(mode);
}
void DisplayListBuilder::drawLine(const SkPoint& p0, const SkPoint& p1) {
  Push<DrawLineOp>(0, 1, p0, p1);
  CheckLayerOpacityCompatibility();
}
void DisplayListBuilder::drawLine(const SkPoint& p0,
                                  const SkPoint& p1,
                                  const DlPaint& paint) {
  setAttributesFromDlPaint(paint, DisplayListOpFlags::kDrawLineFlags);
  drawLine(p0, p1);
}
void DisplayListBuilder::drawRect(const SkRect& rect) {
  Push<DrawRectOp>(0, 1, rect);
  CheckLayerOpacityCompatibility();
}
void DisplayListBuilder::drawRect(const SkRect& rect, const DlPaint& paint) {
  setAttributesFromDlPaint(paint, DisplayListOpFlags::kDrawRectFlags);
  drawRect(rect);
}
void DisplayListBuilder::drawOval(const SkRect& bounds) {
  Push<DrawOvalOp>(0, 1, bounds);
  CheckLayerOpacityCompatibility();
}
void DisplayListBuilder::drawOval(const SkRect& bounds, const DlPaint& paint) {
  setAttributesFromDlPaint(paint, DisplayListOpFlags::kDrawOvalFlags);
  drawOval(bounds);
}
void DisplayListBuilder::drawCircle(const SkPoint& center, SkScalar radius) {
  Push<DrawCircleOp>(0, 1, center, radius);
  CheckLayerOpacityCompatibility();
}
void DisplayListBuilder::drawCircle(const SkPoint& center,
                                    SkScalar radius,
                                    const DlPaint& paint) {
  setAttributesFromDlPaint(paint, DisplayListOpFlags::kDrawCircleFlags);
  drawCircle(center, radius);
}
void DisplayListBuilder::drawRRect(const SkRRect& rrect) {
  if (rrect.isRect()) {
    drawRect(rrect.rect());
  } else if (rrect.isOval()) {
    drawOval(rrect.rect());
  } else {
    Push<DrawRRectOp>(0, 1, rrect);
    CheckLayerOpacityCompatibility();
  }
}
void DisplayListBuilder::drawRRect(const SkRRect& rrect, const DlPaint& paint) {
  setAttributesFromDlPaint(paint, DisplayListOpFlags::kDrawRRectFlags);
  drawRRect(rrect);
}
void DisplayListBuilder::drawDRRect(const SkRRect& outer,
                                    const SkRRect& inner) {
  Push<DrawDRRectOp>(0, 1, outer, inner);
  CheckLayerOpacityCompatibility();
}
void DisplayListBuilder::drawDRRect(const SkRRect& outer,
                                    const SkRRect& inner,
                                    const DlPaint& paint) {
  setAttributesFromDlPaint(paint, DisplayListOpFlags::kDrawDRRectFlags);
  drawDRRect(outer, inner);
}
void DisplayListBuilder::drawPath(const SkPath& path) {
  Push<DrawPathOp>(0, 1, path);
  CheckLayerOpacityHairlineCompatibility();
}
void DisplayListBuilder::drawPath(const SkPath& path, const DlPaint& paint) {
  setAttributesFromDlPaint(paint, DisplayListOpFlags::kDrawPathFlags);
  drawPath(path);
}

void DisplayListBuilder::drawArc(const SkRect& bounds,
                                 SkScalar start,
                                 SkScalar sweep,
                                 bool useCenter) {
  Push<DrawArcOp>(0, 1, bounds, start, sweep, useCenter);
  if (useCenter) {
    CheckLayerOpacityHairlineCompatibility();
  } else {
    CheckLayerOpacityCompatibility();
  }
}
void DisplayListBuilder::drawArc(const SkRect& bounds,
                                 SkScalar start,
                                 SkScalar sweep,
                                 bool useCenter,
                                 const DlPaint& paint) {
  setAttributesFromDlPaint(
      paint, useCenter ? kDrawArcWithCenterFlags : kDrawArcNoCenterFlags);
  drawArc(bounds, start, sweep, useCenter);
}
void DisplayListBuilder::drawPoints(SkCanvas::PointMode mode,
                                    uint32_t count,
                                    const SkPoint pts[]) {
  void* data_ptr;
  FML_DCHECK(count < kMaxDrawPointsCount);
  int bytes = count * sizeof(SkPoint);
  switch (mode) {
    case SkCanvas::PointMode::kPoints_PointMode:
      data_ptr = Push<DrawPointsOp>(bytes, 1, count);
      break;
    case SkCanvas::PointMode::kLines_PointMode:
      data_ptr = Push<DrawLinesOp>(bytes, 1, count);
      break;
    case SkCanvas::PointMode::kPolygon_PointMode:
      data_ptr = Push<DrawPolygonOp>(bytes, 1, count);
      break;
    default:
      FML_DCHECK(false);
      return;
  }
  CopyV(data_ptr, pts, count);
  // drawPoints treats every point or line (or segment of a polygon)
  // as a completely separate operation meaning we cannot ensure
  // distribution of group opacity without analyzing the mode and the
  // bounds of every sub-primitive.
  // See: https://fiddle.skia.org/c/228459001d2de8db117ce25ef5cedb0c
  UpdateLayerOpacityCompatibility(false);
}
void DisplayListBuilder::drawPoints(SkCanvas::PointMode mode,
                                    uint32_t count,
                                    const SkPoint pts[],
                                    const DlPaint& paint) {
  const DisplayListAttributeFlags* flags;
  switch (mode) {
    case SkCanvas::PointMode::kPoints_PointMode:
      flags = &DisplayListOpFlags::kDrawPointsAsPointsFlags;
      break;
    case SkCanvas::PointMode::kLines_PointMode:
      flags = &DisplayListOpFlags::kDrawPointsAsLinesFlags;
      break;
    case SkCanvas::PointMode::kPolygon_PointMode:
      flags = &DisplayListOpFlags::kDrawPointsAsPolygonFlags;
      break;
    default:
      FML_DCHECK(false);
      return;
  }
  setAttributesFromDlPaint(paint, *flags);
  drawPoints(mode, count, pts);
}
void DisplayListBuilder::drawSkVertices(const sk_sp<SkVertices> vertices,
                                        SkBlendMode mode) {
  Push<DrawSkVerticesOp>(0, 1, std::move(vertices), mode);
  // DrawVertices applies its colors to the paint so we have no way
  // of controlling opacity using the current paint attributes.
  // Although, examination of the |mode| might find some predictable
  // cases.
  UpdateLayerOpacityCompatibility(false);
}
void DisplayListBuilder::drawVertices(const DlVertices* vertices,
                                      DlBlendMode mode) {
  void* pod = Push<DrawVerticesOp>(vertices->size(), 1, mode);
  new (pod) DlVertices(vertices);
  // DrawVertices applies its colors to the paint so we have no way
  // of controlling opacity using the current paint attributes.
  // Although, examination of the |mode| might find some predictable
  // cases.
  UpdateLayerOpacityCompatibility(false);
}
void DisplayListBuilder::drawVertices(const DlVertices* vertices,
                                      DlBlendMode mode,
                                      const DlPaint& paint) {
  setAttributesFromDlPaint(paint, DisplayListOpFlags::kDrawVerticesFlags);
  drawVertices(vertices, mode);
}

void DisplayListBuilder::drawImage(const sk_sp<DlImage> image,
                                   const SkPoint point,
                                   DlImageSampling sampling,
                                   bool render_with_attributes) {
  render_with_attributes
      ? Push<DrawImageWithAttrOp>(0, 1, std::move(image), point, sampling)
      : Push<DrawImageOp>(0, 1, std::move(image), point, sampling);
  CheckLayerOpacityCompatibility(render_with_attributes);
}
void DisplayListBuilder::drawImage(const sk_sp<DlImage> image,
                                   const SkPoint point,
                                   DlImageSampling sampling,
                                   const DlPaint* paint) {
  if (paint != nullptr) {
    setAttributesFromDlPaint(*paint,
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
                                       SkCanvas::SrcRectConstraint constraint) {
  Push<DrawImageRectOp>(0, 1, std::move(image), src, dst, sampling,
                        render_with_attributes, constraint);
  CheckLayerOpacityCompatibility(render_with_attributes);
}
void DisplayListBuilder::drawImageRect(const sk_sp<DlImage> image,
                                       const SkRect& src,
                                       const SkRect& dst,
                                       DlImageSampling sampling,
                                       const DlPaint* paint,
                                       SkCanvas::SrcRectConstraint constraint) {
  if (paint != nullptr) {
    setAttributesFromDlPaint(*paint,
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
  render_with_attributes
      ? Push<DrawImageNineWithAttrOp>(0, 1, std::move(image), center, dst,
                                      filter)
      : Push<DrawImageNineOp>(0, 1, std::move(image), center, dst, filter);
  CheckLayerOpacityCompatibility(render_with_attributes);
}
void DisplayListBuilder::drawImageNine(const sk_sp<DlImage> image,
                                       const SkIRect& center,
                                       const SkRect& dst,
                                       DlFilterMode filter,
                                       const DlPaint* paint) {
  if (paint != nullptr) {
    setAttributesFromDlPaint(*paint,
                             DisplayListOpFlags::kDrawImageNineWithPaintFlags);
    drawImageNine(image, center, dst, filter, true);
  } else {
    drawImageNine(image, center, dst, filter, false);
  }
}
void DisplayListBuilder::drawImageLattice(const sk_sp<DlImage> image,
                                          const SkCanvas::Lattice& lattice,
                                          const SkRect& dst,
                                          DlFilterMode filter,
                                          bool render_with_attributes) {
  int xDivCount = lattice.fXCount;
  int yDivCount = lattice.fYCount;
  FML_DCHECK((lattice.fRectTypes == nullptr) || (lattice.fColors != nullptr));
  int cellCount = lattice.fRectTypes && lattice.fColors
                      ? (xDivCount + 1) * (yDivCount + 1)
                      : 0;
  size_t bytes =
      (xDivCount + yDivCount) * sizeof(int) +
      cellCount * (sizeof(SkColor) + sizeof(SkCanvas::Lattice::RectType));
  SkIRect src = lattice.fBounds ? *lattice.fBounds : image->bounds();
  void* pod = this->Push<DrawImageLatticeOp>(
      bytes, 1, std::move(image), xDivCount, yDivCount, cellCount, src, dst,
      filter, render_with_attributes);
  CopyV(pod, lattice.fXDivs, xDivCount, lattice.fYDivs, yDivCount,
        lattice.fColors, cellCount, lattice.fRectTypes, cellCount);
  CheckLayerOpacityCompatibility(render_with_attributes);
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
  int bytes = count * (sizeof(SkRSXform) + sizeof(SkRect));
  void* data_ptr;
  if (colors != nullptr) {
    bytes += count * sizeof(DlColor);
    if (cull_rect != nullptr) {
      data_ptr = Push<DrawAtlasCulledOp>(bytes, 1, std::move(atlas), count,
                                         mode, sampling, true, *cull_rect,
                                         render_with_attributes);
    } else {
      data_ptr = Push<DrawAtlasOp>(bytes, 1, std::move(atlas), count, mode,
                                   sampling, true, render_with_attributes);
    }
    CopyV(data_ptr, xform, count, tex, count, colors, count);
  } else {
    if (cull_rect != nullptr) {
      data_ptr = Push<DrawAtlasCulledOp>(bytes, 1, std::move(atlas), count,
                                         mode, sampling, false, *cull_rect,
                                         render_with_attributes);
    } else {
      data_ptr = Push<DrawAtlasOp>(bytes, 1, std::move(atlas), count, mode,
                                   sampling, false, render_with_attributes);
    }
    CopyV(data_ptr, xform, count, tex, count);
  }
  // drawAtlas treats each image as a separate operation so we cannot rely
  // on it to distribute the opacity without overlap without checking all
  // of the transforms and texture rectangles.
  UpdateLayerOpacityCompatibility(false);
}
void DisplayListBuilder::drawAtlas(const sk_sp<DlImage> atlas,
                                   const SkRSXform xform[],
                                   const SkRect tex[],
                                   const DlColor colors[],
                                   int count,
                                   DlBlendMode mode,
                                   DlImageSampling sampling,
                                   const SkRect* cull_rect,
                                   const DlPaint* paint) {
  if (paint != nullptr) {
    setAttributesFromDlPaint(*paint,
                             DisplayListOpFlags::kDrawAtlasWithPaintFlags);
    drawAtlas(atlas, xform, tex, colors, count, mode, sampling, cull_rect,
              true);
  } else {
    drawAtlas(atlas, xform, tex, colors, count, mode, sampling, cull_rect,
              false);
  }
}

void DisplayListBuilder::drawPicture(const sk_sp<SkPicture> picture,
                                     const SkMatrix* matrix,
                                     bool render_with_attributes) {
  matrix  //
      ? Push<DrawSkPictureMatrixOp>(0, 1, std::move(picture), *matrix,
                                    render_with_attributes)
      : Push<DrawSkPictureOp>(0, 1, std::move(picture), render_with_attributes);
  // The non-nested op count accumulated in the |Push| method will include
  // this call to |drawPicture| for non-nested op count metrics.
  // But, for nested op count metrics we want the |drawPicture| call itself
  // to be transparent. So we subtract 1 from our accumulated nested count to
  // balance out against the 1 that was accumulated into the regular count.
  // This behavior is identical to the way SkPicture computes nested op counts.
  nested_op_count_ += picture->approximateOpCount(true) - 1;
  nested_bytes_ += picture->approximateBytesUsed();
  CheckLayerOpacityCompatibility(render_with_attributes);
}
void DisplayListBuilder::drawDisplayList(
    const sk_sp<DisplayList> display_list) {
  Push<DrawDisplayListOp>(0, 1, std::move(display_list));
  // The non-nested op count accumulated in the |Push| method will include
  // this call to |drawDisplayList| for non-nested op count metrics.
  // But, for nested op count metrics we want the |drawDisplayList| call itself
  // to be transparent. So we subtract 1 from our accumulated nested count to
  // balance out against the 1 that was accumulated into the regular count.
  // This behavior is identical to the way SkPicture computes nested op counts.
  nested_op_count_ += display_list->op_count(true) - 1;
  nested_bytes_ += display_list->bytes(true);
  UpdateLayerOpacityCompatibility(display_list->can_apply_group_opacity());
}
void DisplayListBuilder::drawTextBlob(const sk_sp<SkTextBlob> blob,
                                      SkScalar x,
                                      SkScalar y) {
  Push<DrawTextBlobOp>(0, 1, std::move(blob), x, y);
  CheckLayerOpacityCompatibility();
}
void DisplayListBuilder::drawShadow(const SkPath& path,
                                    const DlColor color,
                                    const SkScalar elevation,
                                    bool transparent_occluder,
                                    SkScalar dpr) {
  transparent_occluder  //
      ? Push<DrawShadowTransparentOccluderOp>(0, 1, path, color, elevation, dpr)
      : Push<DrawShadowOp>(0, 1, path, color, elevation, dpr);
  UpdateLayerOpacityCompatibility(false);
}

// clang-format off
// Flags common to all primitives that apply colors
#define PAINT_FLAGS (kUsesDither_ |      \
                     kUsesColor_ |       \
                     kUsesAlpha_ |       \
                     kUsesBlend_ |       \
                     kUsesShader_ |      \
                     kUsesColorFilter_ | \
                     kUsesImageFilter_)

// Flags common to all primitives that stroke or fill
#define STROKE_OR_FILL_FLAGS (kIsDrawnGeometry_ | \
                              kUsesAntiAlias_ |   \
                              kUsesMaskFilter_ |  \
                              kUsesPathEffect_)

// Flags common to primitives that stroke geometry
#define STROKE_FLAGS (kIsStrokedGeometry_ | \
                      kUsesAntiAlias_ |     \
                      kUsesMaskFilter_ |    \
                      kUsesPathEffect_)

// Flags common to primitives that render an image with paint attributes
#define IMAGE_FLAGS_BASE (kIsNonGeometric_ |  \
                          kUsesAlpha_ |       \
                          kUsesDither_ |      \
                          kUsesBlend_ |       \
                          kUsesColorFilter_ | \
                          kUsesImageFilter_)
// clang-format on

const DisplayListAttributeFlags DisplayListOpFlags::kSaveLayerFlags =
    DisplayListAttributeFlags(kIgnoresPaint_);

const DisplayListAttributeFlags DisplayListOpFlags::kSaveLayerWithPaintFlags =
    DisplayListAttributeFlags(kIsNonGeometric_ |   //
                              kUsesAlpha_ |        //
                              kUsesBlend_ |        //
                              kUsesColorFilter_ |  //
                              kUsesImageFilter_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawColorFlags =
    DisplayListAttributeFlags(kFloodsSurface_ | kIgnoresPaint_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawPaintFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | kFloodsSurface_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawHVLineFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_FLAGS | kMayHaveCaps_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawLineFlags =
    kDrawHVLineFlags.with(kMayHaveDiagonalCaps_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawRectFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_OR_FILL_FLAGS |
                              kMayHaveJoins_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawOvalFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_OR_FILL_FLAGS);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawCircleFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_OR_FILL_FLAGS);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawRRectFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_OR_FILL_FLAGS);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawDRRectFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_OR_FILL_FLAGS);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawPathFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_OR_FILL_FLAGS |
                              kMayHaveCaps_ | kMayHaveDiagonalCaps_ |
                              kMayHaveJoins_ | kMayHaveAcuteJoins_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawArcNoCenterFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_OR_FILL_FLAGS |
                              kMayHaveCaps_ | kMayHaveDiagonalCaps_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawArcWithCenterFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_OR_FILL_FLAGS |
                              kMayHaveJoins_ | kMayHaveAcuteJoins_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawPointsAsPointsFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_FLAGS |  //
                              kMayHaveCaps_ | kButtCapIsSquare_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawPointsAsLinesFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_FLAGS |  //
                              kMayHaveCaps_ | kMayHaveDiagonalCaps_);

// Polygon mode just draws (count-1) separate lines, no joins
const DisplayListAttributeFlags DisplayListOpFlags::kDrawPointsAsPolygonFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_FLAGS |  //
                              kMayHaveCaps_ | kMayHaveDiagonalCaps_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawVerticesFlags =
    DisplayListAttributeFlags(kIsNonGeometric_ |   //
                              kUsesDither_ |       //
                              kUsesAlpha_ |        //
                              kUsesShader_ |       //
                              kUsesBlend_ |        //
                              kUsesColorFilter_ |  //
                              kUsesImageFilter_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawImageFlags =
    DisplayListAttributeFlags(kIgnoresPaint_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawImageWithPaintFlags =
    DisplayListAttributeFlags(IMAGE_FLAGS_BASE |  //
                              kUsesAntiAlias_ | kUsesMaskFilter_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawImageRectFlags =
    DisplayListAttributeFlags(kIgnoresPaint_);

const DisplayListAttributeFlags
    DisplayListOpFlags::kDrawImageRectWithPaintFlags =
        DisplayListAttributeFlags(IMAGE_FLAGS_BASE |  //
                                  kUsesAntiAlias_ | kUsesMaskFilter_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawImageNineFlags =
    DisplayListAttributeFlags(kIgnoresPaint_);

const DisplayListAttributeFlags
    DisplayListOpFlags::kDrawImageNineWithPaintFlags =
        DisplayListAttributeFlags(IMAGE_FLAGS_BASE);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawImageLatticeFlags =
    DisplayListAttributeFlags(kIgnoresPaint_);

const DisplayListAttributeFlags
    DisplayListOpFlags::kDrawImageLatticeWithPaintFlags =
        DisplayListAttributeFlags(IMAGE_FLAGS_BASE);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawAtlasFlags =
    DisplayListAttributeFlags(kIgnoresPaint_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawAtlasWithPaintFlags =
    DisplayListAttributeFlags(IMAGE_FLAGS_BASE);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawPictureFlags =
    DisplayListAttributeFlags(kIgnoresPaint_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawPictureWithPaintFlags =
    kSaveLayerWithPaintFlags;

const DisplayListAttributeFlags DisplayListOpFlags::kDrawDisplayListFlags =
    DisplayListAttributeFlags(kIgnoresPaint_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawTextBlobFlags =
    DisplayListAttributeFlags(PAINT_FLAGS | STROKE_OR_FILL_FLAGS |
                              kMayHaveJoins_)
        .without(kUsesAntiAlias_);

const DisplayListAttributeFlags DisplayListOpFlags::kDrawShadowFlags =
    DisplayListAttributeFlags(kIgnoresPaint_);

#undef PAINT_FLAGS
#undef STROKE_OR_FILL_FLAGS
#undef STROKE_FLAGS
#undef IMAGE_FLAGS_BASE

}  // namespace flutter
