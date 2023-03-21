// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DISPLAY_LIST_BUILDER_H_
#define FLUTTER_DISPLAY_LIST_DISPLAY_LIST_BUILDER_H_

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/dl_blend_mode.h"
#include "flutter/display_list/dl_canvas.h"
#include "flutter/display_list/dl_op_flags.h"
#include "flutter/display_list/dl_op_receiver.h"
#include "flutter/display_list/dl_paint.h"
#include "flutter/display_list/dl_sampling_options.h"
#include "flutter/display_list/effects/dl_path_effect.h"
#include "flutter/display_list/image/dl_image.h"
#include "flutter/display_list/utils/dl_bounds_accumulator.h"
#include "flutter/display_list/utils/dl_comparable.h"
#include "flutter/display_list/utils/dl_matrix_clip_tracker.h"
#include "flutter/fml/macros.h"

namespace flutter {

// The primary class used to build a display list. The list of methods
// here matches the list of methods invoked on a |DlOpReceiver| combined
// with the list of methods invoked on a |DlCanvas|.
class DisplayListBuilder final : public virtual DlCanvas,
                                 public SkRefCnt,
                                 virtual DlOpReceiver,
                                 DisplayListOpFlags {
 public:
  static constexpr SkRect kMaxCullRect =
      SkRect::MakeLTRB(-1E9F, -1E9F, 1E9F, 1E9F);

  explicit DisplayListBuilder(bool prepare_rtree)
      : DisplayListBuilder(kMaxCullRect, prepare_rtree) {}

  explicit DisplayListBuilder(const SkRect& cull_rect = kMaxCullRect,
                              bool prepare_rtree = false);

  ~DisplayListBuilder();

  // |DlCanvas|
  SkISize GetBaseLayerSize() const override;
  // |DlCanvas|
  SkImageInfo GetImageInfo() const override;

  // |DlCanvas|
  void Save() override;

  // |DlCanvas|
  void SaveLayer(const SkRect* bounds,
                 const DlPaint* paint = nullptr,
                 const DlImageFilter* backdrop = nullptr) override;
  // |DlCanvas|
  void Restore() override;
  // |DlCanvas|
  int GetSaveCount() const override { return layer_stack_.size(); }
  // |DlCanvas|
  void RestoreToCount(int restore_count) override;

  // |DlCanvas|
  void Translate(SkScalar tx, SkScalar ty) override;
  // |DlCanvas|
  void Scale(SkScalar sx, SkScalar sy) override;
  // |DlCanvas|
  void Rotate(SkScalar degrees) override;
  // |DlCanvas|
  void Skew(SkScalar sx, SkScalar sy) override;

  // clang-format off
  // 2x3 2D affine subset of a 4x4 transform in row major order
  // |DlCanvas|
  void Transform2DAffine(SkScalar mxx, SkScalar mxy, SkScalar mxt,
                         SkScalar myx, SkScalar myy, SkScalar myt) override;
  // full 4x4 transform in row major order
  // |DlCanvas|
  void TransformFullPerspective(
      SkScalar mxx, SkScalar mxy, SkScalar mxz, SkScalar mxt,
      SkScalar myx, SkScalar myy, SkScalar myz, SkScalar myt,
      SkScalar mzx, SkScalar mzy, SkScalar mzz, SkScalar mzt,
      SkScalar mwx, SkScalar mwy, SkScalar mwz, SkScalar mwt) override;
  // clang-format on
  // |DlCanvas|
  void TransformReset() override;
  // |DlCanvas|
  void Transform(const SkMatrix* matrix) override;
  // |DlCanvas|
  void Transform(const SkM44* matrix44) override;
  // |DlCanvas|
  void SetTransform(const SkMatrix* matrix) override {
    TransformReset();
    Transform(matrix);
  }
  // |DlCanvas|
  void SetTransform(const SkM44* matrix44) override {
    TransformReset();
    Transform(matrix44);
  }
  using DlCanvas::Transform;

  /// Returns the 4x4 full perspective transform representing all transform
  /// operations executed so far in this DisplayList within the enclosing
  /// save stack.
  // |DlCanvas|
  SkM44 GetTransformFullPerspective() const override {
    return tracker_.matrix_4x4();
  }
  /// Returns the 3x3 partial perspective transform representing all transform
  /// operations executed so far in this DisplayList within the enclosing
  /// save stack.
  // |DlCanvas|
  SkMatrix GetTransform() const override { return tracker_.matrix_3x3(); }

  // |DlCanvas|
  void ClipRect(const SkRect& rect, ClipOp clip_op, bool is_aa) override;
  // |DlCanvas|
  void ClipRRect(const SkRRect& rrect, ClipOp clip_op, bool is_aa) override;
  // |DlCanvas|
  void ClipPath(const SkPath& path, ClipOp clip_op, bool is_aa) override;

  /// Conservative estimate of the bounds of all outstanding clip operations
  /// measured in the coordinate space within which this DisplayList will
  /// be rendered.
  // |DlCanvas|
  SkRect GetDestinationClipBounds() const override {
    return tracker_.device_cull_rect();
  }
  /// Conservative estimate of the bounds of all outstanding clip operations
  /// transformed into the local coordinate space in which currently
  /// recorded rendering operations are interpreted.
  // |DlCanvas|
  SkRect GetLocalClipBounds() const override {
    return tracker_.local_cull_rect();
  }

  /// Return true iff the supplied bounds are easily shown to be outside
  /// of the current clip bounds. This method may conservatively return
  /// false if it cannot make the determination.
  // |DlCanvas|
  bool QuickReject(const SkRect& bounds) const override;

  // |DlCanvas|
  void DrawPaint(const DlPaint& paint) override;
  // |DlCanvas|
  void DrawColor(DlColor color, DlBlendMode mode) override;
  // |DlCanvas|
  void DrawLine(const SkPoint& p0,
                const SkPoint& p1,
                const DlPaint& paint) override;
  // |DlCanvas|
  void DrawRect(const SkRect& rect, const DlPaint& paint) override;
  // |DlCanvas|
  void DrawOval(const SkRect& bounds, const DlPaint& paint) override;
  // |DlCanvas|
  void DrawCircle(const SkPoint& center,
                  SkScalar radius,
                  const DlPaint& paint) override;
  // |DlCanvas|
  void DrawRRect(const SkRRect& rrect, const DlPaint& paint) override;
  // |DlCanvas|
  void DrawDRRect(const SkRRect& outer,
                  const SkRRect& inner,
                  const DlPaint& paint) override;
  // |DlCanvas|
  void DrawPath(const SkPath& path, const DlPaint& paint) override;
  // |DlCanvas|
  void DrawArc(const SkRect& bounds,
               SkScalar start,
               SkScalar sweep,
               bool useCenter,
               const DlPaint& paint) override;
  // |DlCanvas|
  void DrawPoints(PointMode mode,
                  uint32_t count,
                  const SkPoint pts[],
                  const DlPaint& paint) override;
  // |DlCanvas|
  void DrawVertices(const DlVertices* vertices,
                    DlBlendMode mode,
                    const DlPaint& paint) override;
  using DlCanvas::DrawVertices;
  // |DlCanvas|
  void DrawImage(const sk_sp<DlImage>& image,
                 const SkPoint point,
                 DlImageSampling sampling,
                 const DlPaint* paint = nullptr) override;
  // |DlCanvas|
  void DrawImageRect(
      const sk_sp<DlImage>& image,
      const SkRect& src,
      const SkRect& dst,
      DlImageSampling sampling,
      const DlPaint* paint = nullptr,
      SrcRectConstraint constraint = SrcRectConstraint::kFast) override;
  // |DlCanvas|
  void DrawImageNine(const sk_sp<DlImage>& image,
                     const SkIRect& center,
                     const SkRect& dst,
                     DlFilterMode filter,
                     const DlPaint* paint = nullptr) override;
  // |DlCanvas|
  void DrawAtlas(const sk_sp<DlImage>& atlas,
                 const SkRSXform xform[],
                 const SkRect tex[],
                 const DlColor colors[],
                 int count,
                 DlBlendMode mode,
                 DlImageSampling sampling,
                 const SkRect* cullRect,
                 const DlPaint* paint = nullptr) override;
  // |DlCanvas|
  void DrawDisplayList(const sk_sp<DisplayList> display_list,
                       SkScalar opacity = SK_Scalar1) override;
  // |DlCanvas|
  void DrawTextBlob(const sk_sp<SkTextBlob>& blob,
                    SkScalar x,
                    SkScalar y,
                    const DlPaint& paint) override;
  // |DlCanvas|
  void DrawShadow(const SkPath& path,
                  const DlColor color,
                  const SkScalar elevation,
                  bool transparent_occluder,
                  SkScalar dpr) override;

  // |DlCanvas|
  void Flush() override {}

  sk_sp<DisplayList> Build();

 private:
  // This method exposes the internal stateful DlOpReceiver implementation
  // of the DisplayListBuilder, primarily for testing purposes. Its use
  // is obsolete and forbidden in every other case and is only shared to a
  // pair of "friend" accessors in the benchmark/unittest files.
  DlOpReceiver& asReceiver() { return *this; }

  friend DlOpReceiver& DisplayListBuilderBenchmarkAccessor(
      DisplayListBuilder& builder);
  friend DlOpReceiver& DisplayListBuilderTestingAccessor(
      DisplayListBuilder& builder);

  void SetAttributesFromPaint(const DlPaint& paint,
                              const DisplayListAttributeFlags flags);

  // |DlOpReceiver|
  void setAntiAlias(bool aa) override {
    if (current_.isAntiAlias() != aa) {
      onSetAntiAlias(aa);
    }
  }
  // |DlOpReceiver|
  void setDither(bool dither) override {
    if (current_.isDither() != dither) {
      onSetDither(dither);
    }
  }
  // |DlOpReceiver|
  void setInvertColors(bool invert) override {
    if (current_.isInvertColors() != invert) {
      onSetInvertColors(invert);
    }
  }
  // |DlOpReceiver|
  void setStrokeCap(DlStrokeCap cap) override {
    if (current_.getStrokeCap() != cap) {
      onSetStrokeCap(cap);
    }
  }
  // |DlOpReceiver|
  void setStrokeJoin(DlStrokeJoin join) override {
    if (current_.getStrokeJoin() != join) {
      onSetStrokeJoin(join);
    }
  }
  // |DlOpReceiver|
  void setStyle(DlDrawStyle style) override {
    if (current_.getDrawStyle() != style) {
      onSetStyle(style);
    }
  }
  // |DlOpReceiver|
  void setStrokeWidth(float width) override {
    if (current_.getStrokeWidth() != width) {
      onSetStrokeWidth(width);
    }
  }
  // |DlOpReceiver|
  void setStrokeMiter(float limit) override {
    if (current_.getStrokeMiter() != limit) {
      onSetStrokeMiter(limit);
    }
  }
  // |DlOpReceiver|
  void setColor(DlColor color) override {
    if (current_.getColor() != color) {
      onSetColor(color);
    }
  }
  // |DlOpReceiver|
  void setBlendMode(DlBlendMode mode) override {
    if (current_.getBlendMode() != mode) {
      onSetBlendMode(mode);
    }
  }
  // |DlOpReceiver|
  void setColorSource(const DlColorSource* source) override {
    if (NotEquals(current_.getColorSource(), source)) {
      onSetColorSource(source);
    }
  }
  // |DlOpReceiver|
  void setImageFilter(const DlImageFilter* filter) override {
    if (NotEquals(current_.getImageFilter(), filter)) {
      onSetImageFilter(filter);
    }
  }
  // |DlOpReceiver|
  void setColorFilter(const DlColorFilter* filter) override {
    if (NotEquals(current_.getColorFilter(), filter)) {
      onSetColorFilter(filter);
    }
  }
  // |DlOpReceiver|
  void setPathEffect(const DlPathEffect* effect) override {
    if (NotEquals(current_.getPathEffect(), effect)) {
      onSetPathEffect(effect);
    }
  }
  // |DlOpReceiver|
  void setMaskFilter(const DlMaskFilter* filter) override {
    if (NotEquals(current_.getMaskFilter(), filter)) {
      onSetMaskFilter(filter);
    }
  }

  // |DlOpReceiver|
  void save() override { Save(); }
  // Only the |renders_with_attributes()| option will be accepted here. Any
  // other flags will be ignored and calculated anew as the DisplayList is
  // built. Alternatively, use the |saveLayer(SkRect, bool)| method.
  // |DlOpReceiver|
  void saveLayer(const SkRect* bounds,
                 const SaveLayerOptions options,
                 const DlImageFilter* backdrop) override;
  // |DlOpReceiver|
  void restore() override { Restore(); }

  // |DlOpReceiver|
  void translate(SkScalar tx, SkScalar ty) override { Translate(tx, ty); }
  // |DlOpReceiver|
  void scale(SkScalar sx, SkScalar sy) override { Scale(sx, sy); }
  // |DlOpReceiver|
  void rotate(SkScalar degrees) override { Rotate(degrees); }
  // |DlOpReceiver|
  void skew(SkScalar sx, SkScalar sy) override { Skew(sx, sy); }

  // clang-format off
  // |DlOpReceiver|
  void transform2DAffine(SkScalar mxx, SkScalar mxy, SkScalar mxt,
                         SkScalar myx, SkScalar myy, SkScalar myt) override {
    Transform2DAffine(mxx, mxy, mxt, myx, myy, myt);
  }
  // |DlOpReceiver|
  void transformFullPerspective(
      SkScalar mxx, SkScalar mxy, SkScalar mxz, SkScalar mxt,
      SkScalar myx, SkScalar myy, SkScalar myz, SkScalar myt,
      SkScalar mzx, SkScalar mzy, SkScalar mzz, SkScalar mzt,
      SkScalar mwx, SkScalar mwy, SkScalar mwz, SkScalar mwt) override {
    TransformFullPerspective(mxx, mxy, mxz, mxt,
                             myx, myy, myz, myt,
                             mzx, mzy, mzz, mzt,
                             mwx, mwy, mwz, mwt);
  }
  // clang-format off
  // |DlOpReceiver|
  void transformReset() override { TransformReset(); }

  // |DlOpReceiver|
  void clipRect(const SkRect& rect, ClipOp clip_op, bool is_aa) override {
    ClipRect(rect, clip_op, is_aa);
  }
  // |DlOpReceiver|
  void clipRRect(const SkRRect& rrect, ClipOp clip_op, bool is_aa) override {
    ClipRRect(rrect, clip_op, is_aa);
  }
  // |DlOpReceiver|
  void clipPath(const SkPath& path, ClipOp clip_op, bool is_aa) override {
    ClipPath(path, clip_op, is_aa);
  }

  // |DlOpReceiver|
  void drawPaint() override;
  // |DlOpReceiver|
  void drawColor(DlColor color, DlBlendMode mode) override {
    DrawColor(color, mode);
  }
  // |DlOpReceiver|
  void drawLine(const SkPoint& p0, const SkPoint& p1) override;
  // |DlOpReceiver|
  void drawRect(const SkRect& rect) override;
  // |DlOpReceiver|
  void drawOval(const SkRect& bounds) override;
  // |DlOpReceiver|
  void drawCircle(const SkPoint& center, SkScalar radius) override;
  // |DlOpReceiver|
  void drawRRect(const SkRRect& rrect) override;
  // |DlOpReceiver|
  void drawDRRect(const SkRRect& outer, const SkRRect& inner) override;
  // |DlOpReceiver|
  void drawPath(const SkPath& path) override;
  // |DlOpReceiver|
  void drawArc(const SkRect& bounds,
               SkScalar start,
               SkScalar sweep,
               bool useCenter) override;
  // |DlOpReceiver|
  void drawPoints(PointMode mode, uint32_t count, const SkPoint pts[]) override;
  // |DlOpReceiver|
  void drawVertices(const DlVertices* vertices, DlBlendMode mode) override;

  // |DlOpReceiver|
  void drawImage(const sk_sp<DlImage> image,
                 const SkPoint point,
                 DlImageSampling sampling,
                 bool render_with_attributes) override;
  // |DlOpReceiver|
  void drawImageRect(
      const sk_sp<DlImage> image,
      const SkRect& src,
      const SkRect& dst,
      DlImageSampling sampling,
      bool render_with_attributes,
      SrcRectConstraint constraint = SrcRectConstraint::kFast) override;
  // |DlOpReceiver|
  void drawImageNine(const sk_sp<DlImage> image,
                     const SkIRect& center,
                     const SkRect& dst,
                     DlFilterMode filter,
                     bool render_with_attributes) override;
  // |DlOpReceiver|
  void drawAtlas(const sk_sp<DlImage> atlas,
                 const SkRSXform xform[],
                 const SkRect tex[],
                 const DlColor colors[],
                 int count,
                 DlBlendMode mode,
                 DlImageSampling sampling,
                 const SkRect* cullRect,
                 bool render_with_attributes) override;

  // |DlOpReceiver|
  void drawDisplayList(const sk_sp<DisplayList> display_list,
                       SkScalar opacity) override {
    DrawDisplayList(display_list, opacity);
  }
  // |DlOpReceiver|
  void drawTextBlob(const sk_sp<SkTextBlob> blob,
                    SkScalar x,
                    SkScalar y) override;
  // |DlOpReceiver|
  void drawShadow(const SkPath& path,
                  const DlColor color,
                  const SkScalar elevation,
                  bool transparent_occluder,
                  SkScalar dpr) override {
    DrawShadow(path, color, elevation, transparent_occluder, dpr);
  }

  void checkForDeferredSave();

  DisplayListStorage storage_;
  size_t used_ = 0;
  size_t allocated_ = 0;
  int render_op_count_ = 0;
  int op_index_ = 0;

  // bytes and ops from |drawPicture| and |drawDisplayList|
  size_t nested_bytes_ = 0;
  int nested_op_count_ = 0;

  template <typename T, typename... Args>
  void* Push(size_t extra, int op_inc, Args&&... args);

  void intersect(const SkRect& rect);

  // kInvalidSigma is used to indicate that no MaskBlur is currently set.
  static constexpr SkScalar kInvalidSigma = 0.0;
  static bool mask_sigma_valid(SkScalar sigma) {
    return SkScalarIsFinite(sigma) && sigma > 0.0;
  }

  class LayerInfo {
   public:
    explicit LayerInfo(size_t save_offset = 0,
                       bool has_layer = false,
                       std::shared_ptr<const DlImageFilter> filter = nullptr)
        : save_offset_(save_offset),
          has_layer_(has_layer),
          cannot_inherit_opacity_(false),
          has_compatible_op_(false),
          filter_(filter),
          is_unbounded_(false) {}

    // The offset into the memory buffer where the saveLayer DLOp record
    // for this saveLayer() call is placed. This may be needed if the
    // eventual restore() call has discovered important information about
    // the records inside the saveLayer that may impact how the saveLayer
    // is handled (e.g., |cannot_inherit_opacity| == false).
    // This offset is only valid if |has_layer| is true.
    size_t save_offset() const { return save_offset_; }

    bool has_layer() const { return has_layer_; }
    bool cannot_inherit_opacity() const { return cannot_inherit_opacity_; }
    bool has_compatible_op() const { return has_compatible_op_; }

    bool is_group_opacity_compatible() const {
      return !cannot_inherit_opacity_;
    }

    void mark_incompatible() { cannot_inherit_opacity_ = true; }

    // For now this only allows a single compatible op to mark the
    // layer as being compatible with group opacity. If we start
    // computing bounds of ops in the Builder methods then we
    // can upgrade this to checking for overlapping ops.
    // See https://github.com/flutter/flutter/issues/93899
    void add_compatible_op() {
      if (!cannot_inherit_opacity_) {
        if (has_compatible_op_) {
          cannot_inherit_opacity_ = true;
        } else {
          has_compatible_op_ = true;
        }
      }
    }

    // The filter to apply to the layer bounds when it is restored
    std::shared_ptr<const DlImageFilter> filter() { return filter_; }

    // is_unbounded should be set to true if we ever encounter an operation
    // on a layer that either is unrestricted (|drawColor| or |drawPaint|)
    // or cannot compute its bounds (some effects and filters) and there
    // was no outstanding clip op at the time.
    // When the layer is restored, the outer layer may then process this
    // unbounded state by accumulating its own clip or transferring the
    // unbounded state to its own outer layer.
    // Typically the DisplayList will have been constructed with a cull
    // rect which will act as a default clip for the outermost layer and
    // the unbounded state of all sub layers will eventually be caught by
    // that cull rect so that the overall unbounded state of the entire
    // DisplayList will never be true.
    //
    // For historical consistency it is worth noting that SkPicture used
    // to treat these same conditions as a Nop (they accumulate the
    // SkPicture cull rect, but if no cull rect was specified then it is
    // an empty Rect and so has no effect on the bounds).
    //
    // Flutter is unlikely to ever run into this as the Dart mechanisms
    // all supply a non-null cull rect for all Dart Picture objects,
    // even if that cull rect is kGiantRect.
    void set_unbounded() { is_unbounded_ = true; }

    // |is_unbounded| should be called after |getLayerBounds| in case
    // a problem was found during the computation of those bounds,
    // the layer will have one last chance to flag an unbounded state.
    bool is_unbounded() const { return is_unbounded_; }

   private:
    size_t save_offset_;
    bool has_layer_;
    bool cannot_inherit_opacity_;
    bool has_compatible_op_;
    std::shared_ptr<const DlImageFilter> filter_;
    bool is_unbounded_;
    bool has_deferred_save_op_ = false;

    friend class DisplayListBuilder;
  };

  std::vector<LayerInfo> layer_stack_;
  LayerInfo* current_layer_;
  DisplayListMatrixClipTracker tracker_;
  std::unique_ptr<BoundsAccumulator> accumulator_;
  BoundsAccumulator* accumulator() { return accumulator_.get(); }

  // This flag indicates whether or not the current rendering attributes
  // are compatible with rendering ops applying an inherited opacity.
  bool current_opacity_compatibility_ = true;

  // Returns the compatibility of a given blend mode for applying an
  // inherited opacity value to modulate the visibility of the op.
  // For now we only accept SrcOver blend modes but this could be expanded
  // in the future to include other (rarely used) modes that also modulate
  // the opacity of a rendering operation at the cost of a switch statement
  // or lookup table.
  static bool IsOpacityCompatible(DlBlendMode mode) {
    return (mode == DlBlendMode::kSrcOver);
  }

  void UpdateCurrentOpacityCompatibility() {
    current_opacity_compatibility_ =             //
        current_.getColorFilter() == nullptr &&  //
        !current_.isInvertColors() &&            //
        IsOpacityCompatible(current_.getBlendMode());
  }

  // Update the opacity compatibility flags of the current layer for an op
  // that has determined its compatibility as indicated by |compatible|.
  void UpdateLayerOpacityCompatibility(bool compatible) {
    if (compatible) {
      current_layer_->add_compatible_op();
    } else {
      current_layer_->mark_incompatible();
    }
  }

  // Check for opacity compatibility for an op that may or may not use the
  // current rendering attributes as indicated by |uses_blend_attribute|.
  // If the flag is false then the rendering op will be able to substitute
  // a default Paint object with the opacity applied using the default SrcOver
  // blend mode which is always compatible with applying an inherited opacity.
  void CheckLayerOpacityCompatibility(bool uses_blend_attribute = true) {
    UpdateLayerOpacityCompatibility(!uses_blend_attribute ||
                                    current_opacity_compatibility_);
  }

  void CheckLayerOpacityHairlineCompatibility() {
    UpdateLayerOpacityCompatibility(
        current_opacity_compatibility_ &&
        (current_.getDrawStyle() == DlDrawStyle::kFill ||
         current_.getStrokeWidth() > 0));
  }

  // Check for opacity compatibility for an op that ignores the current
  // attributes and uses the indicated blend |mode| to render to the layer.
  // This is only used by |drawColor| currently.
  void CheckLayerOpacityCompatibility(DlBlendMode mode) {
    UpdateLayerOpacityCompatibility(IsOpacityCompatible(mode));
  }

  void onSetAntiAlias(bool aa);
  void onSetDither(bool dither);
  void onSetInvertColors(bool invert);
  void onSetStrokeCap(DlStrokeCap cap);
  void onSetStrokeJoin(DlStrokeJoin join);
  void onSetStyle(DlDrawStyle style);
  void onSetStrokeWidth(SkScalar width);
  void onSetStrokeMiter(SkScalar limit);
  void onSetColor(DlColor color);
  void onSetBlendMode(DlBlendMode mode);
  void onSetColorSource(const DlColorSource* source);
  void onSetImageFilter(const DlImageFilter* filter);
  void onSetColorFilter(const DlColorFilter* filter);
  void onSetPathEffect(const DlPathEffect* effect);
  void onSetMaskFilter(const DlMaskFilter* filter);

  // The DisplayList had an unbounded call with no cull rect or clip
  // to contain it. Should only be called after the stream is fully
  // built.
  // Unbounded operations are calls like |drawColor| which are defined
  // to flood the entire surface, or calls that relied on a rendering
  // attribute which is unable to compute bounds (should be rare).
  // In those cases the bounds will represent only the accumulation
  // of the bounded calls and this flag will be set to indicate that
  // condition.
  bool is_unbounded() const {
    FML_DCHECK(layer_stack_.size() == 1);
    return layer_stack_.front().is_unbounded();
  }

  SkRect bounds() const {
    FML_DCHECK(layer_stack_.size() == 1);
    if (is_unbounded()) {
      FML_LOG(INFO) << "returning partial bounds for unbounded DisplayList";
    }

    return accumulator_->bounds();
  }

  sk_sp<DlRTree> rtree() {
    FML_DCHECK(layer_stack_.size() == 1);
    if (is_unbounded()) {
      FML_LOG(INFO) << "returning partial rtree for unbounded DisplayList";
    }

    return accumulator_->rtree();
  }

  bool paint_nops_on_transparency();

  // Computes the bounds of an operation adjusted for a given ImageFilter
  static bool ComputeFilteredBounds(SkRect& bounds,
                                    const DlImageFilter* filter);

  // Adjusts the indicated bounds for the given flags and returns true if
  // the calculation was possible, or false if it could not be estimated.
  bool AdjustBoundsForPaint(SkRect& bounds, DisplayListAttributeFlags flags);

  // Records the fact that we encountered an op that either could not
  // estimate its bounds or that fills all of the destination space.
  void AccumulateUnbounded();

  // Records the bounds for an op after modifying them according to the
  // supplied attribute flags and transforming by the current matrix.
  void AccumulateOpBounds(const SkRect& bounds,
                          DisplayListAttributeFlags flags) {
    SkRect safe_bounds = bounds;
    AccumulateOpBounds(safe_bounds, flags);
  }

  // Records the bounds for an op after modifying them according to the
  // supplied attribute flags and transforming by the current matrix
  // and clipping against the current clip.
  void AccumulateOpBounds(SkRect& bounds, DisplayListAttributeFlags flags);

  // Records the given bounds after transforming by the current matrix
  // and clipping against the current clip.
  void AccumulateBounds(SkRect& bounds);

  DlPaint current_;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DISPLAY_LIST_BUILDER_H_
