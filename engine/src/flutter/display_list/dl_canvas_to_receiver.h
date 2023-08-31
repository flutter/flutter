// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DL_CANVAS_TO_RECEIVER_H_
#define FLUTTER_DISPLAY_LIST_DL_CANVAS_TO_RECEIVER_H_

#include "flutter/display_list/dl_canvas.h"
#include "flutter/display_list/dl_op_flags.h"
#include "flutter/display_list/dl_op_receiver.h"
#include "flutter/fml/macros.h"

namespace impeller {
struct Picture;
}

namespace flutter {

class DlCanvasReceiver : public DlOpReceiver {
 private:
  using ClipOp = DlCanvas::ClipOp;

 public:
  virtual ~DlCanvasReceiver() = default;

  virtual SkRect base_device_cull_rect() const = 0;

  virtual SkM44 matrix_4x4() const = 0;
  virtual SkMatrix matrix_3x3() const { return matrix_4x4().asM33(); }

  virtual SkRect device_cull_rect() const = 0;
  virtual SkRect local_cull_rect() const = 0;
  virtual bool is_cull_rect_empty() const = 0;
  virtual bool content_culled(const SkRect& content_bounds) const = 0;

  /*--------- Methods below here are optional optimizations --------*/

  /// Optional - only needed if performing bounds culling via the accumulate
  ///            methods
  /// Note: The bounds are only advisory for implementing bounds culling
  /// and should not trigger an actual clip operation.
  /// The default implementation ignores the advisory information.
  ///
  /// This method should almost never be used as it breaks the encapsulation
  /// of the enclosing clips. However it is needed for practical purposes in
  /// some rare cases - such as when a saveLayer is collecting rendering
  /// operations prior to applying a filter on the entire layer bounds and
  /// some of those operations fall outside the enclosing clip, but their
  /// filtered content will spread out from where they were rendered on the
  /// layer into the enclosing clipped area.
  /// Omitting the |cull_rect| argument, or passing nullptr, will restore the
  /// cull rect to the initial value it had when the tracker was constructed.
  virtual void resetCullRect(const SkRect* cull_rect = nullptr) {}

  /// Optional - only needed if performing bounds culling via the accumulate
  ///            methods
  /// Note: The bounds are only advisory for implementing bounds culling
  /// and should not trigger an actual clip operation.
  /// The default implementation ignores the advisory information.
  ///
  /// This method is used to add an additional culling bounds without
  /// actually performing a clip on the destination. The bounds will
  /// help avoid recording content of a saveLayer that lies entirely
  /// outside the save layer bounds if it had them.
  virtual void intersectCullRect(const SkRect& cull_rect) {}

  /// Optional - only needed if implementing the accumulate methods
  /// The default implementation returns false to prevent extra work in
  /// the adapter.
  ///
  /// If the receiver is accumulating bounds into, say, an rtree format,
  /// or wants granular bounds for any other reason, this query will let
  /// the adapter know that it should deliver the bounds of methods such
  /// as DrawDisplayList granularly if possible (i.e. if the DL being
  /// drawn itself has an RTree for its bounds).
  ///
  /// Returns: true if the implementation can make use of granular bounds
  virtual bool wants_granular_bounds() const { return false; }

  /// Optional - only needed if accumulating bounds or implementing bounds
  ///            culling
  /// The default implementation ignores the bounds and returns true to
  /// prevent culling.
  ///
  /// The indicated bounds were calculated for the next rendering op call.
  /// The receiver can ignore them if it is not accumulating the bounds,
  /// and can tag them appropriately if recording the bounds per rendering op.
  /// The receiver can also indicate if the bounds are clipped out with
  /// the returned boolean.
  ///
  /// Returns: true if the bounds were not clipped
  ///          or false if there is no way for these bounds to be visible
  virtual bool accumulateLocalBoundsForNextOp(const SkRect& r) { return true; }

  /// Optional - only needed if accumulating bounds or implementing bounds
  ///            culling
  /// The default implementation ignores the condition and returns true to
  /// prevent culling.
  ///
  /// The bounds for the next rendering op will be "unbounded" by anything
  /// other than the current clip, whether because it is a |drawPaint| or
  /// |drawColor| call or because it is rendered with a filter that modifies
  /// all pixels (even transparent) out to infinity (or the clip).
  /// The receiver can ignore the information if it is not accumulating
  /// the bounds, and can tag them appropriately if recording the bounds
  /// per rendering op.
  /// The receiver can also indicate if the bounds are clipped out with
  /// the returned boolean.
  ///
  /// Returns: true if the bounds were not clipped
  ///          or false if there is no way for these bounds to be visible
  virtual bool accumulateUnboundedForNextOp() { return true; }

  /// Optional - only needed if the provided information is useful to the
  ///            implementation
  /// By default this method will simply call the regular |restore| method
  /// and the information will be ignored.
  ///
  /// Called in lieue of a call to |restore| when the upstream code calls
  /// a restore on a |saveLayer| and there is information about the contents
  /// of the layer that the receiver might find interesting.
  virtual void restoreLayer(const DlImageFilter* filter,
                            bool layer_content_was_unbounded,
                            bool layer_could_distribute_opacity) {
    restore();
  }

  /// Optional - useful to indicate non-renderable state such as an empty
  ///            clip or collapsed transform to suspend rendering calls
  ///            until the state is overridden or popped by a |restore|.
  /// By default this method returns false to prevent state culling.
  ///
  /// The |is_nop| method will be called after any of the clip or
  /// transform methods to detect if the current conditions are
  /// now a NOP. The receiver will receive no more calls until the
  /// associated restore() call which will be dispatched to it, or
  /// a subsequent clip or transform "reset" operation.
  ///
  /// Returns: true if either the clip or transform prevent rendering
  virtual bool is_nop() { return false; }
};

// The primary class used to build a display list. The list of methods
// here matches the list of methods invoked on a |DlOpReceiver| combined
// with the list of methods invoked on a |DlCanvas|.
class DlCanvasToReceiver : public virtual DlCanvas,  //
                           DisplayListOpFlags {
 public:
  explicit DlCanvasToReceiver(std::shared_ptr<DlCanvasReceiver> receiver);

  ~DlCanvasToReceiver() = default;

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
  int GetSaveCount() const override {
    CheckAlive();
    return layer_stack_.size();
  }
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
    CheckAlive();
    TransformReset();
    Transform(matrix);
  }
  // |DlCanvas|
  void SetTransform(const SkM44* matrix44) override {
    CheckAlive();
    TransformReset();
    Transform(matrix44);
  }
  using DlCanvas::Transform;

  /// Returns the 4x4 full perspective transform representing all transform
  /// operations executed so far in this DisplayList within the enclosing
  /// save stack.
  // |DlCanvas|
  SkM44 GetTransformFullPerspective() const override {
    CheckAlive();
    return receiver_->matrix_4x4();
  }
  /// Returns the 3x3 partial perspective transform representing all transform
  /// operations executed so far in this DisplayList within the enclosing
  /// save stack.
  // |DlCanvas|
  SkMatrix GetTransform() const override {
    CheckAlive();
    return receiver_->matrix_3x3();
  }

  // |DlCanvas|
  void ClipRect(const SkRect& rect,
                ClipOp clip_op = ClipOp::kIntersect,
                bool is_aa = false) override;
  // |DlCanvas|
  void ClipRRect(const SkRRect& rrect,
                 ClipOp clip_op = ClipOp::kIntersect,
                 bool is_aa = false) override;
  // |DlCanvas|
  void ClipPath(const SkPath& path,
                ClipOp clip_op = ClipOp::kIntersect,
                bool is_aa = false) override;

  /// Conservative estimate of the bounds of all outstanding clip operations
  /// measured in the coordinate space within which this DisplayList will
  /// be rendered.
  // |DlCanvas|
  SkRect GetDestinationClipBounds() const override {
    CheckAlive();
    return receiver_->device_cull_rect();
  }
  /// Conservative estimate of the bounds of all outstanding clip operations
  /// transformed into the local coordinate space in which currently
  /// recorded rendering operations are interpreted.
  // |DlCanvas|
  SkRect GetLocalClipBounds() const override {
    CheckAlive();
    return receiver_->local_cull_rect();
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
  using DlCanvas::DrawImageRect;
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
  void DrawImpellerPicture(
      const std::shared_ptr<const impeller::Picture>& picture,
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
  void Flush() override { CheckAlive(); }

 protected:
  inline void CheckAlive() const { FML_CHECK(receiver_ != nullptr); }

  std::shared_ptr<DlCanvasReceiver> receiver_;

  bool current_group_opacity_compatibility() {
    return current_layer_->is_group_opacity_compatible();
  }
  bool current_affects_transparent_layer() {
    return current_layer_->affects_transparent_layer();
  }

  DlPaint CurrentAttributes() const { return current_; }

 private:
  // Returns whether or not the paint was compatible with opacity inheritance
  [[nodiscard]] bool SetAttributesFromPaint(
      const DlPaint* paint,
      const DisplayListAttributeFlags flags);

  enum class OpResult {
    kNoEffect,
    kPreservesTransparency,
    kAffectsAll,
  };

  class LayerInfo {
   public:
    explicit LayerInfo(
        bool has_layer = false,
        const std::shared_ptr<const DlImageFilter>& filter = nullptr)
        : has_layer_(has_layer), filter_(filter) {}

    bool has_layer() const { return has_layer_; }
    bool cannot_inherit_opacity() const { return cannot_inherit_opacity_; }
    bool has_compatible_op() const { return has_compatible_op_; }
    bool affects_transparent_layer() const {
      return affects_transparent_layer_;
    }

    void Update(OpResult result, bool can_inherit_opacity) {
      switch (result) {
        case OpResult::kNoEffect:
          // We should have stopped processing the rendering operation
          // well before we tried to update the layer information.
          FML_DCHECK(result != OpResult::kNoEffect);
          return;

        case OpResult::kPreservesTransparency:
          break;

        case OpResult::kAffectsAll:
          add_visible_op();
          break;
      }

      if (can_inherit_opacity) {
        add_compatible_op();
      } else {
        mark_incompatible();
      }
    }

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

    // Records that the current layer contains an op that produces visible
    // output on a transparent surface.
    void add_visible_op() { affects_transparent_layer_ = true; }

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
    bool has_layer_;
    bool cannot_inherit_opacity_ = false;
    bool has_compatible_op_ = false;
    std::shared_ptr<const DlImageFilter> filter_;
    bool is_unbounded_ = false;
    bool state_is_nop_ = false;
    bool affects_transparent_layer_ = false;

    friend class DlCanvasToReceiver;
  };

  std::vector<LayerInfo> layer_stack_;
  LayerInfo* current_layer_;

  // Returns the compatibility of a given blend mode for applying an
  // inherited opacity value to modulate the visibility of the op.
  // For now we only accept SrcOver blend modes but this could be expanded
  // in the future to include other (rarely used) modes that also modulate
  // the opacity of a rendering operation at the cost of a switch statement
  // or lookup table.
  static inline bool IsOpacityCompatible(DlBlendMode mode) {
    return (mode == DlBlendMode::kSrcOver);
  }

  static DisplayListAttributeFlags FlagsForPointMode(PointMode mode);

  bool paint_nops_on_transparency(const DlPaint* paint);
  OpResult PaintResult(const DlPaint& paint,
                       DisplayListAttributeFlags flags = kDrawPaintFlags);
  OpResult PaintResult(const DlPaint* paint,
                       DisplayListAttributeFlags flags = kDrawPaintFlags) {
    if (paint) {
      return PaintResult(*paint, flags);
    } else if (current_layer_->state_is_nop_) {
      return OpResult::kNoEffect;
    } else {
      FML_DCHECK(PaintResult(kDefaultPaint_, flags) == OpResult::kAffectsAll);
      return OpResult::kAffectsAll;
    }
  }

  // kAnyColor is a non-opaque and non-transparent color that will not
  // trigger any short-circuit tests about the results of a blend.
  static constexpr DlColor kAnyColor = DlColor::kMidGrey().withAlpha(0x80);
  static_assert(!kAnyColor.isOpaque());
  static_assert(!kAnyColor.isTransparent());
  static DlColor GetEffectiveColor(const DlPaint& paint,
                                   DisplayListAttributeFlags flags);

  // Computes the bounds of an operation adjusted for a given ImageFilter
  // and returns whether the computation was possible. If the method
  // returns false then the caller should assume the worst about the bounds.
  static bool ComputeFilteredBounds(SkRect& bounds,
                                    const DlImageFilter* filter);

  // Adjusts the indicated bounds for the given flags and returns true if
  // the calculation was possible, or false if it could not be estimated.
  bool AdjustBoundsForPaint(SkRect& bounds,
                            const DlPaint* paint,
                            DisplayListAttributeFlags flags);

  // Records the fact that we encountered an op that either could not
  // estimate its bounds or that fills all of the destination space.
  bool AccumulateUnbounded();

  // Records the bounds for an op after modifying them according to the
  // supplied attribute flags and transforming by the current matrix.
  bool AccumulateOpBounds(const SkRect& bounds,
                          const DlPaint* paint,
                          DisplayListAttributeFlags flags) {
    SkRect safe_bounds = bounds;
    return AccumulateOpBounds(safe_bounds, paint, flags);
  }

  // Records the bounds for an op after modifying them according to the
  // supplied attribute flags and transforming by the current matrix
  // and clipping against the current clip.
  bool AccumulateOpBounds(SkRect& bounds,
                          const DlPaint* paint,
                          DisplayListAttributeFlags flags);

  // Records the given bounds after transforming by the current matrix
  // and clipping against the current clip.
  bool AccumulateBounds(SkRect& bounds);

  DlPaint current_;
  static DlPaint kDefaultPaint_;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DL_CANVAS_TO_RECEIVER_H_
