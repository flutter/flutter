// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_builder.h"

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
  layer_stack_.emplace_back();
  current_layer_ = &layer_stack_.back();
}

DisplayListBuilder::~DisplayListBuilder() {
  uint8_t* ptr = storage_.get();
  if (ptr) {
    DisplayList::DisposeOps(ptr, ptr + used_);
  }
}

void DisplayListBuilder::onSetAntiAlias(bool aa) {
  Push<SetAntiAliasOp>(0, 0, current_anti_alias_ = aa);
}
void DisplayListBuilder::onSetDither(bool dither) {
  Push<SetDitherOp>(0, 0, current_dither_ = dither);
}
void DisplayListBuilder::onSetInvertColors(bool invert) {
  Push<SetInvertColorsOp>(0, 0, current_invert_colors_ = invert);
  UpdateCurrentOpacityCompatibility();
}
void DisplayListBuilder::onSetStrokeCap(SkPaint::Cap cap) {
  Push<SetStrokeCapOp>(0, 0, current_stroke_cap_ = cap);
}
void DisplayListBuilder::onSetStrokeJoin(SkPaint::Join join) {
  Push<SetStrokeJoinOp>(0, 0, current_stroke_join_ = join);
}
void DisplayListBuilder::onSetStyle(SkPaint::Style style) {
  Push<SetStyleOp>(0, 0, current_style_ = style);
}
void DisplayListBuilder::onSetStrokeWidth(SkScalar width) {
  Push<SetStrokeWidthOp>(0, 0, current_stroke_width_ = width);
}
void DisplayListBuilder::onSetStrokeMiter(SkScalar limit) {
  Push<SetStrokeMiterOp>(0, 0, current_stroke_miter_ = limit);
}
void DisplayListBuilder::onSetColor(SkColor color) {
  Push<SetColorOp>(0, 0, current_color_ = color);
}
void DisplayListBuilder::onSetBlendMode(SkBlendMode mode) {
  current_blender_ = nullptr;
  Push<SetBlendModeOp>(0, 0, current_blend_mode_ = mode);
  UpdateCurrentOpacityCompatibility();
}
void DisplayListBuilder::onSetBlender(sk_sp<SkBlender> blender) {
  // setBlender(nullptr) should be redirected to setBlendMode(SrcOver)
  // by the set method, if not then the following is inefficient but works
  FML_DCHECK(blender);
  SkPaint p;
  p.setBlender(blender);
  if (p.asBlendMode()) {
    setBlendMode(p.asBlendMode().value());
  } else {
    // |current_blender_| supersedes any value of |current_blend_mode_|
    (current_blender_ = blender)  //
        ? Push<SetBlenderOp>(0, 0, std::move(blender))
        : Push<ClearBlenderOp>(0, 0);
    UpdateCurrentOpacityCompatibility();
  }
}
void DisplayListBuilder::onSetShader(sk_sp<SkShader> shader) {
  (current_shader_ = shader)  //
      ? Push<SetShaderOp>(0, 0, std::move(shader))
      : Push<ClearShaderOp>(0, 0);
}
void DisplayListBuilder::onSetImageFilter(sk_sp<SkImageFilter> filter) {
  (current_image_filter_ = filter)  //
      ? Push<SetImageFilterOp>(0, 0, std::move(filter))
      : Push<ClearImageFilterOp>(0, 0);
}
void DisplayListBuilder::onSetColorFilter(sk_sp<SkColorFilter> filter) {
  (current_color_filter_ = filter)  //
      ? Push<SetColorFilterOp>(0, 0, std::move(filter))
      : Push<ClearColorFilterOp>(0, 0);
  UpdateCurrentOpacityCompatibility();
}
void DisplayListBuilder::onSetPathEffect(sk_sp<SkPathEffect> effect) {
  (current_path_effect_ = effect)  //
      ? Push<SetPathEffectOp>(0, 0, std::move(effect))
      : Push<ClearPathEffectOp>(0, 0);
}
void DisplayListBuilder::onSetMaskFilter(sk_sp<SkMaskFilter> filter) {
  current_mask_sigma_ = kInvalidSigma;
  (current_mask_filter_ = filter)  //
      ? Push<SetMaskFilterOp>(0, 0, std::move(filter))
      : Push<ClearMaskFilterOp>(0, 0);
}
void DisplayListBuilder::onSetMaskBlurFilter(SkBlurStyle style,
                                             SkScalar sigma) {
  // Valid sigma is checked by setMaskBlurFilter
  FML_DCHECK(mask_sigma_valid(sigma));
  current_mask_filter_ = nullptr;
  current_mask_style_ = style;
  current_mask_sigma_ = sigma;
  switch (style) {
    case kNormal_SkBlurStyle:
      Push<SetMaskBlurFilterNormalOp>(0, 0, sigma);
      break;
    case kSolid_SkBlurStyle:
      Push<SetMaskBlurFilterSolidOp>(0, 0, sigma);
      break;
    case kOuter_SkBlurStyle:
      Push<SetMaskBlurFilterOuterOp>(0, 0, sigma);
      break;
    case kInner_SkBlurStyle:
      Push<SetMaskBlurFilterInnerOp>(0, 0, sigma);
      break;
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
    skstd::optional<SkBlendMode> mode_optional = paint.asBlendMode();
    if (mode_optional) {
      setBlendMode(mode_optional.value());
    } else {
      setBlender(sk_ref_sp(paint.getBlender()));
    }
  }
  if (flags.applies_style()) {
    setStyle(paint.getStyle());
  }
  if (flags.is_stroked(paint.getStyle())) {
    setStrokeWidth(paint.getStrokeWidth());
    setStrokeMiter(paint.getStrokeMiter());
    setStrokeCap(paint.getStrokeCap());
    setStrokeJoin(paint.getStrokeJoin());
  }
  if (flags.applies_shader()) {
    setShader(sk_ref_sp(paint.getShader()));
  }
  if (flags.applies_color_filter()) {
    // invert colors is a Flutter::Paint thing, not an SkPaint thing
    // we must clear it because it is a second potential color filter
    // that is composed with the paint's color filter.
    setInvertColors(false);
    setColorFilter(sk_ref_sp(paint.getColorFilter()));
  }
  if (flags.applies_image_filter()) {
    setImageFilter(sk_ref_sp(paint.getImageFilter()));
  }
  if (flags.applies_path_effect()) {
    setPathEffect(sk_ref_sp(paint.getPathEffect()));
  }
  if (flags.applies_mask_filter()) {
    setMaskFilter(sk_ref_sp(paint.getMaskFilter()));
  }
}

void DisplayListBuilder::save() {
  Push<SaveOp>(0, 1);
  layer_stack_.emplace_back();
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
    if (!layer_info.has_layer) {
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
void DisplayListBuilder::saveLayer(const SkRect* bounds,
                                   bool restore_with_paint) {
  bounds  //
      ? Push<SaveLayerBoundsOp>(0, 1, *bounds, restore_with_paint)
      : Push<SaveLayerOp>(0, 1, restore_with_paint);
  CheckLayerOpacityCompatibility(restore_with_paint);
  layer_stack_.emplace_back(true);
  current_layer_ = &layer_stack_.back();
}

void DisplayListBuilder::translate(SkScalar tx, SkScalar ty) {
  if (SkScalarIsFinite(tx) && SkScalarIsFinite(ty) &&
      (tx != 0.0 || ty != 0.0)) {
    Push<TranslateOp>(0, 1, tx, ty);
  }
}
void DisplayListBuilder::scale(SkScalar sx, SkScalar sy) {
  if (SkScalarIsFinite(sx) && SkScalarIsFinite(sy) &&
      (sx != 1.0 || sy != 1.0)) {
    Push<ScaleOp>(0, 1, sx, sy);
  }
}
void DisplayListBuilder::rotate(SkScalar degrees) {
  if (SkScalarMod(degrees, 360.0) != 0.0) {
    Push<RotateOp>(0, 1, degrees);
  }
}
void DisplayListBuilder::skew(SkScalar sx, SkScalar sy) {
  if (SkScalarIsFinite(sx) && SkScalarIsFinite(sy) &&
      (sx != 0.0 || sy != 0.0)) {
    Push<SkewOp>(0, 1, sx, sy);
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
  }
}

// clang-format on

void DisplayListBuilder::clipRect(const SkRect& rect,
                                  SkClipOp clip_op,
                                  bool is_aa) {
  clip_op == SkClipOp::kIntersect  //
      ? Push<ClipIntersectRectOp>(0, 1, rect, is_aa)
      : Push<ClipDifferenceRectOp>(0, 1, rect, is_aa);
}
void DisplayListBuilder::clipRRect(const SkRRect& rrect,
                                   SkClipOp clip_op,
                                   bool is_aa) {
  if (rrect.isRect()) {
    clipRect(rrect.rect(), clip_op, is_aa);
  } else {
    clip_op == SkClipOp::kIntersect  //
        ? Push<ClipIntersectRRectOp>(0, 1, rrect, is_aa)
        : Push<ClipDifferenceRRectOp>(0, 1, rrect, is_aa);
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
  clip_op == SkClipOp::kIntersect  //
      ? Push<ClipIntersectPathOp>(0, 1, path, is_aa)
      : Push<ClipDifferencePathOp>(0, 1, path, is_aa);
}

void DisplayListBuilder::drawPaint() {
  Push<DrawPaintOp>(0, 1);
  CheckLayerOpacityCompatibility();
}
void DisplayListBuilder::drawColor(SkColor color, SkBlendMode mode) {
  Push<DrawColorOp>(0, 1, color, mode);
  CheckLayerOpacityCompatibility(mode);
}
void DisplayListBuilder::drawLine(const SkPoint& p0, const SkPoint& p1) {
  Push<DrawLineOp>(0, 1, p0, p1);
  CheckLayerOpacityCompatibility();
}
void DisplayListBuilder::drawRect(const SkRect& rect) {
  Push<DrawRectOp>(0, 1, rect);
  CheckLayerOpacityCompatibility();
}
void DisplayListBuilder::drawOval(const SkRect& bounds) {
  Push<DrawOvalOp>(0, 1, bounds);
  CheckLayerOpacityCompatibility();
}
void DisplayListBuilder::drawCircle(const SkPoint& center, SkScalar radius) {
  Push<DrawCircleOp>(0, 1, center, radius);
  CheckLayerOpacityCompatibility();
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
void DisplayListBuilder::drawDRRect(const SkRRect& outer,
                                    const SkRRect& inner) {
  Push<DrawDRRectOp>(0, 1, outer, inner);
  CheckLayerOpacityCompatibility();
}
void DisplayListBuilder::drawPath(const SkPath& path) {
  Push<DrawPathOp>(0, 1, path);
  CheckLayerOpacityHairlineCompatibility();
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
void DisplayListBuilder::drawVertices(const sk_sp<SkVertices> vertices,
                                      SkBlendMode mode) {
  Push<DrawVerticesOp>(0, 1, std::move(vertices), mode);
  // DrawVertices applies its colors to the paint so we have no way
  // of controlling opacity using the current paint attributes.
  UpdateLayerOpacityCompatibility(false);
}

void DisplayListBuilder::drawImage(const sk_sp<SkImage> image,
                                   const SkPoint point,
                                   const SkSamplingOptions& sampling,
                                   bool render_with_attributes) {
  render_with_attributes
      ? Push<DrawImageWithAttrOp>(0, 1, std::move(image), point, sampling)
      : Push<DrawImageOp>(0, 1, std::move(image), point, sampling);
  CheckLayerOpacityCompatibility(render_with_attributes);
}
void DisplayListBuilder::drawImageRect(const sk_sp<SkImage> image,
                                       const SkRect& src,
                                       const SkRect& dst,
                                       const SkSamplingOptions& sampling,
                                       bool render_with_attributes,
                                       SkCanvas::SrcRectConstraint constraint) {
  Push<DrawImageRectOp>(0, 1, std::move(image), src, dst, sampling,
                        render_with_attributes, constraint);
  CheckLayerOpacityCompatibility(render_with_attributes);
}
void DisplayListBuilder::drawImageNine(const sk_sp<SkImage> image,
                                       const SkIRect& center,
                                       const SkRect& dst,
                                       SkFilterMode filter,
                                       bool render_with_attributes) {
  render_with_attributes
      ? Push<DrawImageNineWithAttrOp>(0, 1, std::move(image), center, dst,
                                      filter)
      : Push<DrawImageNineOp>(0, 1, std::move(image), center, dst, filter);
  CheckLayerOpacityCompatibility(render_with_attributes);
}
void DisplayListBuilder::drawImageLattice(const sk_sp<SkImage> image,
                                          const SkCanvas::Lattice& lattice,
                                          const SkRect& dst,
                                          SkFilterMode filter,
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
void DisplayListBuilder::drawAtlas(const sk_sp<SkImage> atlas,
                                   const SkRSXform xform[],
                                   const SkRect tex[],
                                   const SkColor colors[],
                                   int count,
                                   SkBlendMode mode,
                                   const SkSamplingOptions& sampling,
                                   const SkRect* cull_rect,
                                   bool render_with_attributes) {
  int bytes = count * (sizeof(SkRSXform) + sizeof(SkRect));
  void* data_ptr;
  if (colors != nullptr) {
    bytes += count * sizeof(SkColor);
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
                                    const SkColor color,
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
