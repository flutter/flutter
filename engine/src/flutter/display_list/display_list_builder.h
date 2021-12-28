// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DISPLAY_LIST_BUILDER_H_
#define FLUTTER_DISPLAY_LIST_DISPLAY_LIST_BUILDER_H_

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/display_list_dispatcher.h"
#include "flutter/display_list/display_list_flags.h"
#include "flutter/display_list/types.h"
#include "flutter/fml/macros.h"

namespace flutter {

// The primary class used to build a display list. The list of methods
// here matches the list of methods invoked on a |Dispatcher|.
// If there is some code that already renders to an SkCanvas object,
// those rendering commands can be captured into a DisplayList using
// the DisplayListCanvasRecorder class.
class DisplayListBuilder final : public virtual Dispatcher,
                                 public SkRefCnt,
                                 DisplayListOpFlags {
 public:
  explicit DisplayListBuilder(const SkRect& cull_rect = kMaxCullRect_);

  ~DisplayListBuilder();

  void setAntiAlias(bool aa) override {
    if (current_anti_alias_ != aa) {
      onSetAntiAlias(aa);
    }
  }
  void setDither(bool dither) override {
    if (current_dither_ != dither) {
      onSetDither(dither);
    }
  }
  void setInvertColors(bool invert) override {
    if (current_invert_colors_ != invert) {
      onSetInvertColors(invert);
    }
  }
  void setStrokeCap(SkPaint::Cap cap) override {
    if (current_stroke_cap_ != cap) {
      onSetStrokeCap(cap);
    }
  }
  void setStrokeJoin(SkPaint::Join join) override {
    if (current_stroke_join_ != join) {
      onSetStrokeJoin(join);
    }
  }
  void setStyle(SkPaint::Style style) override {
    if (current_style_ != style) {
      onSetStyle(style);
    }
  }
  void setStrokeWidth(SkScalar width) override {
    if (current_stroke_width_ != width) {
      onSetStrokeWidth(width);
    }
  }
  void setStrokeMiter(SkScalar limit) override {
    if (current_stroke_miter_ != limit) {
      onSetStrokeMiter(limit);
    }
  }
  void setColor(SkColor color) override {
    if (current_color_ != color) {
      onSetColor(color);
    }
  }
  void setBlendMode(SkBlendMode mode) override {
    if (current_blender_ || current_blend_mode_ != mode) {
      onSetBlendMode(mode);
    }
  }
  void setBlender(sk_sp<SkBlender> blender) override {
    if (!blender) {
      setBlendMode(SkBlendMode::kSrcOver);
    } else if (current_blender_ != blender) {
      onSetBlender(std::move(blender));
    }
  }
  void setShader(sk_sp<SkShader> shader) override {
    if (current_shader_ != shader) {
      onSetShader(std::move(shader));
    }
  }
  void setImageFilter(sk_sp<SkImageFilter> filter) override {
    if (current_image_filter_ != filter) {
      onSetImageFilter(std::move(filter));
    }
  }
  void setColorFilter(sk_sp<SkColorFilter> filter) override {
    if (current_color_filter_ != filter) {
      onSetColorFilter(std::move(filter));
    }
  }
  void setPathEffect(sk_sp<SkPathEffect> effect) override {
    if (current_path_effect_ != effect) {
      onSetPathEffect(std::move(effect));
    }
  }
  void setMaskFilter(sk_sp<SkMaskFilter> filter) override {
    if (mask_sigma_valid(current_mask_sigma_) ||
        current_mask_filter_ != filter) {
      onSetMaskFilter(std::move(filter));
    }
  }
  void setMaskBlurFilter(SkBlurStyle style, SkScalar sigma) override {
    if (!mask_sigma_valid(sigma)) {
      // SkMastFilter::MakeBlur(invalid sigma) returns a nullptr, so we
      // reset the mask filter here rather than recording the invalid values.
      setMaskFilter(nullptr);
    } else if (current_mask_style_ != style || current_mask_sigma_ != sigma) {
      onSetMaskBlurFilter(style, sigma);
    }
  }

  bool isAntiAlias() const { return current_anti_alias_; }
  bool isDither() const { return current_dither_; }
  SkPaint::Style getStyle() const { return current_style_; }
  SkColor getColor() const { return current_color_; }
  SkScalar getStrokeWidth() const { return current_stroke_width_; }
  SkScalar getStrokeMiter() const { return current_stroke_miter_; }
  SkPaint::Cap getStrokeCap() const { return current_stroke_cap_; }
  SkPaint::Join getStrokeJoin() const { return current_stroke_join_; }
  sk_sp<SkShader> getShader() const { return current_shader_; }
  sk_sp<SkColorFilter> getColorFilter() const { return current_color_filter_; }
  bool isInvertColors() const { return current_invert_colors_; }
  std::optional<SkBlendMode> getBlendMode() const {
    if (current_blender_) {
      // The setters will turn "Mode" style blenders into "blend_mode"s
      return {};
    }
    return current_blend_mode_;
  }
  sk_sp<SkBlender> getBlender() const {
    return current_blender_ ? current_blender_
                            : SkBlender::Mode(current_blend_mode_);
  }
  sk_sp<SkPathEffect> getPathEffect() const { return current_path_effect_; }
  sk_sp<SkMaskFilter> getMaskFilter() const {
    return mask_sigma_valid(current_mask_sigma_)
               ? SkMaskFilter::MakeBlur(current_mask_style_,
                                        current_mask_sigma_)
               : current_mask_filter_;
  }
  // No utility getter for the utility setter:
  // void setMaskBlurFilter (SkBlurStyle style, SkScalar sigma)
  sk_sp<SkImageFilter> getImageFilter() const { return current_image_filter_; }

  void save() override;
  void saveLayer(const SkRect* bounds, bool restore_with_paint) override;
  void restore() override;
  int getSaveCount() { return layer_stack_.size(); }

  void translate(SkScalar tx, SkScalar ty) override;
  void scale(SkScalar sx, SkScalar sy) override;
  void rotate(SkScalar degrees) override;
  void skew(SkScalar sx, SkScalar sy) override;

  void setAttributesFromPaint(const SkPaint& paint,
                              const DisplayListAttributeFlags flags);

  // clang-format off

  // 2x3 2D affine subset of a 4x4 transform in row major order
  void transform2DAffine(SkScalar mxx, SkScalar mxy, SkScalar mxt,
                         SkScalar myx, SkScalar myy, SkScalar myt) override;
  // full 4x4 transform in row major order
  void transformFullPerspective(
      SkScalar mxx, SkScalar mxy, SkScalar mxz, SkScalar mxt,
      SkScalar myx, SkScalar myy, SkScalar myz, SkScalar myt,
      SkScalar mzx, SkScalar mzy, SkScalar mzz, SkScalar mzt,
      SkScalar mwx, SkScalar mwy, SkScalar mwz, SkScalar mwt) override;

  // clang-format on

  void clipRect(const SkRect& rect, SkClipOp clip_op, bool is_aa) override;
  void clipRRect(const SkRRect& rrect, SkClipOp clip_op, bool is_aa) override;
  void clipPath(const SkPath& path, SkClipOp clip_op, bool is_aa) override;

  void drawPaint() override;
  void drawColor(SkColor color, SkBlendMode mode) override;
  void drawLine(const SkPoint& p0, const SkPoint& p1) override;
  void drawRect(const SkRect& rect) override;
  void drawOval(const SkRect& bounds) override;
  void drawCircle(const SkPoint& center, SkScalar radius) override;
  void drawRRect(const SkRRect& rrect) override;
  void drawDRRect(const SkRRect& outer, const SkRRect& inner) override;
  void drawPath(const SkPath& path) override;
  void drawArc(const SkRect& bounds,
               SkScalar start,
               SkScalar sweep,
               bool useCenter) override;
  void drawPoints(SkCanvas::PointMode mode,
                  uint32_t count,
                  const SkPoint pts[]) override;
  void drawVertices(const sk_sp<SkVertices> vertices,
                    SkBlendMode mode) override;
  void drawImage(const sk_sp<SkImage> image,
                 const SkPoint point,
                 const SkSamplingOptions& sampling,
                 bool render_with_attributes) override;
  void drawImageRect(
      const sk_sp<SkImage> image,
      const SkRect& src,
      const SkRect& dst,
      const SkSamplingOptions& sampling,
      bool render_with_attributes,
      SkCanvas::SrcRectConstraint constraint =
          SkCanvas::SrcRectConstraint::kFast_SrcRectConstraint) override;
  void drawImageNine(const sk_sp<SkImage> image,
                     const SkIRect& center,
                     const SkRect& dst,
                     SkFilterMode filter,
                     bool render_with_attributes) override;
  void drawImageLattice(const sk_sp<SkImage> image,
                        const SkCanvas::Lattice& lattice,
                        const SkRect& dst,
                        SkFilterMode filter,
                        bool render_with_attributes) override;
  void drawAtlas(const sk_sp<SkImage> atlas,
                 const SkRSXform xform[],
                 const SkRect tex[],
                 const SkColor colors[],
                 int count,
                 SkBlendMode mode,
                 const SkSamplingOptions& sampling,
                 const SkRect* cullRect,
                 bool render_with_attributes) override;
  void drawPicture(const sk_sp<SkPicture> picture,
                   const SkMatrix* matrix,
                   bool render_with_attributes) override;
  void drawDisplayList(const sk_sp<DisplayList> display_list) override;
  void drawTextBlob(const sk_sp<SkTextBlob> blob,
                    SkScalar x,
                    SkScalar y) override;
  void drawShadow(const SkPath& path,
                  const SkColor color,
                  const SkScalar elevation,
                  bool transparent_occluder,
                  SkScalar dpr) override;

  sk_sp<DisplayList> Build();

 private:
  SkAutoTMalloc<uint8_t> storage_;
  size_t used_ = 0;
  size_t allocated_ = 0;
  int op_count_ = 0;

  // bytes and ops from |drawPicture| and |drawDisplayList|
  size_t nested_bytes_ = 0;
  int nested_op_count_ = 0;

  SkRect cull_rect_;
  static constexpr SkRect kMaxCullRect_ =
      SkRect::MakeLTRB(-1E9F, -1E9F, 1E9F, 1E9F);

  template <typename T, typename... Args>
  void* Push(size_t extra, int op_inc, Args&&... args);

  // kInvalidSigma is used to indicate that no MaskBlur is currently set.
  static constexpr SkScalar kInvalidSigma = 0.0;
  static bool mask_sigma_valid(SkScalar sigma) {
    return SkScalarIsFinite(sigma) && sigma > 0.0;
  }

  struct LayerInfo {
    LayerInfo(bool has_layer = false)
        : has_layer(has_layer),
          cannot_inherit_opacity(false),
          has_compatible_op(false) {}

    bool has_layer;
    bool cannot_inherit_opacity;
    bool has_compatible_op;

    bool is_group_opacity_compatible() const { return !cannot_inherit_opacity; }

    void mark_incompatible() { cannot_inherit_opacity = true; }

    // For now this only allows a single compatible op to mark the
    // layer as being compatible with group opacity. If we start
    // computing bounds of ops in the Builder methods then we
    // can upgrade this to checking for overlapping ops.
    // See https://github.com/flutter/flutter/issues/93899
    void add_compatible_op() {
      if (!cannot_inherit_opacity) {
        if (has_compatible_op) {
          cannot_inherit_opacity = true;
        } else {
          has_compatible_op = true;
        }
      }
    }
  };

  std::vector<LayerInfo> layer_stack_;
  LayerInfo* current_layer_;

  // This flag indicates whether or not the current rendering attributes
  // are compatible with rendering ops applying an inherited opacity.
  bool current_opacity_compatibility_ = true;

  // Returns the compatibility of a given blend mode for applying an
  // inherited opacity value to modulate the visibility of the op.
  // For now we only accept SrcOver blend modes but this could be expanded
  // in the future to include other (rarely used) modes that also modulate
  // the opacity of a rendering operation at the cost of a switch statement
  // or lookup table.
  static bool IsOpacityCompatible(SkBlendMode mode) {
    return (mode == SkBlendMode::kSrcOver);
  }

  void UpdateCurrentOpacityCompatibility() {
    current_opacity_compatibility_ =         //
        current_color_filter_ == nullptr &&  //
        !current_invert_colors_ &&           //
        current_blender_ == nullptr &&       //
        IsOpacityCompatible(current_blend_mode_);
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
        (current_style_ == SkPaint::kFill_Style || current_stroke_width_ > 0));
  }

  // Check for opacity compatibility for an op that ignores the current
  // attributes and uses the indicated blend |mode| to render to the layer.
  // This is only used by |drawColor| currently.
  void CheckLayerOpacityCompatibility(SkBlendMode mode) {
    UpdateLayerOpacityCompatibility(IsOpacityCompatible(mode));
  }

  void onSetAntiAlias(bool aa);
  void onSetDither(bool dither);
  void onSetInvertColors(bool invert);
  void onSetStrokeCap(SkPaint::Cap cap);
  void onSetStrokeJoin(SkPaint::Join join);
  void onSetStyle(SkPaint::Style style);
  void onSetStrokeWidth(SkScalar width);
  void onSetStrokeMiter(SkScalar limit);
  void onSetColor(SkColor color);
  void onSetBlendMode(SkBlendMode mode);
  void onSetBlender(sk_sp<SkBlender> blender);
  void onSetShader(sk_sp<SkShader> shader);
  void onSetImageFilter(sk_sp<SkImageFilter> filter);
  void onSetColorFilter(sk_sp<SkColorFilter> filter);
  void onSetPathEffect(sk_sp<SkPathEffect> effect);
  void onSetMaskFilter(sk_sp<SkMaskFilter> filter);
  void onSetMaskBlurFilter(SkBlurStyle style, SkScalar sigma);

  // These values should match the defaults of the Dart Paint object.
  bool current_anti_alias_ = false;
  bool current_dither_ = false;
  bool current_invert_colors_ = false;
  SkColor current_color_ = 0xFF000000;
  SkPaint::Style current_style_ = SkPaint::Style::kFill_Style;
  SkScalar current_stroke_width_ = 0.0;
  SkScalar current_stroke_miter_ = 4.0;
  SkPaint::Cap current_stroke_cap_ = SkPaint::Cap::kButt_Cap;
  SkPaint::Join current_stroke_join_ = SkPaint::Join::kMiter_Join;
  // If |current_blender_| is set then |current_blend_mode_| should be ignored
  SkBlendMode current_blend_mode_ = SkBlendMode::kSrcOver;
  sk_sp<SkBlender> current_blender_;
  sk_sp<SkShader> current_shader_;
  sk_sp<SkColorFilter> current_color_filter_;
  sk_sp<SkImageFilter> current_image_filter_;
  sk_sp<SkPathEffect> current_path_effect_;
  sk_sp<SkMaskFilter> current_mask_filter_;
  SkBlurStyle current_mask_style_;
  SkScalar current_mask_sigma_ = kInvalidSigma;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DISPLAY_LIST_BUILDER_H_
