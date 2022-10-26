// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_LAYERS_LAYER_STATE_STACK_H_
#define FLUTTER_FLOW_LAYERS_LAYER_STATE_STACK_H_

#include "flutter/display_list/display_list_builder.h"
#include "flutter/display_list/display_list_canvas_recorder.h"
#include "flutter/flow/embedded_views.h"
#include "flutter/flow/paint_utils.h"

namespace flutter {

/// The LayerStateStack manages the inherited state passed down between
/// |Layer| objects in a |LayerTree| during |Preroll| and |Paint|.
///
/// More specifically, it manages the clip and transform state during
/// recursive rendering and will hold and lazily apply opacity, ImageFilter
/// and ColorFilter attributes to recursive content. This is not a truly
/// general state management mechnanism as it makes assumptions that code
/// will be applying the attributes to rendered content that happens in
/// recursive calls. The automatic save/restore mechanisms only work in
/// a context where C++ auto-destruct calls will engage the restore at
/// the end of a code block and that any applied attributes will only
/// be applied to the content rendered inside that block. These restrictions
/// match the organization of the |LayerTree| precisely.
///
/// The stack can manage a single state delegate. The stack will both
/// record the state internally regardless of any delegate and will also
/// apply it to a delegate as needed. The delegate can be swapped out
/// on the fly (as is typically done by PlatformViewLayer when recording
/// the state for multiple inter-embedded-view sub-trees) and the old
/// delegate will be restored to its original state (before it became a
/// delegate) and the new delegate will have all of the state recorded
/// by the stack replayed into it to bring it up to speed with the
/// current rendering context.
///
/// The delegate can be any one of:
///   - MutatorsStack: used during Preroll to remember the outstanding
///                    state for embedded platform layers
///   - SkCanvas: used during Paint for the default output to a Skia
///               surface
///   - DisplayListBuilder: used during Paint to construct a DisplayList
///                         for Impeller output
/// The stack will know which state needs to be conveyed to any of these
/// delegates and when is the best time to convey that state (i.e. lazy
/// saveLayer calls for example).
///
/// The rendering state attributes will be automatically applied to the
/// nested content using a |saveLayer| call at the point at which we
/// encounter rendered content (i.e. various nested layers that exist only
/// to apply new state will not trigger the |saveLayer| and the attributes
/// can accumulate until we reach actual content that is rendered.) Some
/// rendered content can avoid the |saveLayer| if it reports to the object
/// that it is able to apply all of the attributes that happen to be
/// outstanding (accumulated from parent state-modifiers). A |ContainerLayer|
/// can also monitor the attribute rendering capabilities of a list of
/// children and can ask the object to apply a protective |saveLayer| or
/// not based on the negotiated capabilities of the entire group.
///
/// Any code that is planning to modify the clip, transform, or rendering
/// attributes for its child content must start by calling the |save| method
/// which returns a MutatorContext object. The methods that modify such
/// state only exist on the MutatorContext object so it is difficult to get
/// that wrong, but the caller must make sure that the call happens within
/// a C++ code block that will define the "rendering scope" of those
/// state changes as they will be automatically restored on exit from that
/// block. Note that the layer might make similar state calls directly on
/// the canvas or builder during the Paint cycle (via saveLayer, transform,
/// or clip calls), but should avoid doing so if there is any nested content
/// that needs to track or react to those state calls.
///
/// Code that needs to render content can simply inform the parent of their
/// abilities by setting the |PrerollContext::renderable_state_flags| during
/// |Preroll| and then render with those attributes during |Paint| by
/// requesting the outstanding values of those attributes from the state_stack
/// object. Individual leaf layers can ignore this feature as the default
/// behavior during |Preroll| will have their parent |ContainerLayer| assume
/// that they cannot render any outstanding state attributes and will apply
/// the protective saveLayer on their behalf if needed. As such, this object
/// only provides "opt-in" features for leaf layers and no responsibilities
/// otherwise.
/// See |LayerStateStack::fill|
/// See |LayerStateStack::outstanding_opacity|
/// See |LayerStateStack::outstanding_color_filter|
/// See |LayerStateStack::outstanding_image_filter|
///
/// State-modifying layers should contain code similar to this pattern in both
/// their |Preroll| and |Paint| methods.
///
/// void [LayerType]::[Preroll/Paint](context) {
///   auto mutator = context.state_stack.save();
///   mutator.translate(origin.x, origin.y);
///   mutator.applyOpacity(content_bounds, opacity_value);
///   mutator.applyColorFilter(content_bounds, color_filter);
///
///   // Children will react to the state applied above during their
///   // Preroll/Paint methods or ContainerLayer will protect them
///   // conservatively by default.
///   [Preroll/Paint]Children(context);
///
///   // here the mutator will be auto-destructed and the state accumulated
///   // by it will be restored out of the state_stack and its associated
///   // delegates.
/// }
class LayerStateStack {
 public:
  explicit LayerStateStack(const SkRect* cull_rect = nullptr);

  CheckerboardFunc checkerboard_func() const { return checkerboard_func_; }
  void set_checkerboard_func(CheckerboardFunc checkerboard_func) {
    checkerboard_func_ = checkerboard_func;
  }

  // Clears out any old delegate to make room for a new one.
  void clear_delegate();

  // Return the SkCanvas delegate if the state stack has such a delegate.
  // The state stack will only have one of an SkCanvas, Builder, or Mutators
  // delegate at any given time.
  // See also |builder_delegate| and |mutators_delegate|.
  SkCanvas* canvas_delegate() { return canvas_; }

  // Return the DisplayListBuilder delegate if the state stack has such a
  // delegate.
  // The state stack will only have one of an SkCanvas, Builder, or Mutators
  // delegate at any given time.
  // See also |builder_delegate| and |mutators_delegate|.
  DisplayListBuilder* builder_delegate() { return builder_; }

  // Return the MutatorsStack delegate if the state stack has such a
  // delegate.
  // The state stack will only have one of an SkCanvas, Builder, or Mutators
  // delegate at any given time.
  // See also |builder_delegate| and |mutators_delegate|.
  MutatorsStack* mutators_delegate() { return mutators_; }

  // Clears the old delegate and sets the canvas delegate to the indicated
  // canvas (if not nullptr). This ensures that only one delegate - either
  // a canvas, a builder, or mutator stack - is present at any one time.
  void set_delegate(SkCanvas* canvas);

  // Clears the old delegate and sets the builder delegate to the indicated
  // buider (if not nullptr). This ensures that only one delegate - either
  // a canvas, a builder, or mutator stack - is present at any one time.
  void set_delegate(DisplayListBuilder* builder);
  void set_delegate(sk_sp<DisplayListBuilder> builder) {
    set_delegate(builder.get());
  }
  void set_delegate(DisplayListCanvasRecorder& recorder) {
    set_delegate(recorder.builder().get());
  }

  // Clears the old delegate and sets the mutators delegate to the indicated
  // MutatorsStack (if not null). This ensures that only one delegate - either
  // a canvas, a builder, or mutator stack - is present at any one time.
  void set_delegate(MutatorsStack* stack);

  // Overrides the initial cull rect and/or transform when it is not known at
  // the time that the LayerStateStack is constructed. Must be called before
  // any state has been pushed on the stack.
  void set_initial_cull_rect(const SkRect& cull_rect);
  void set_initial_transform(const SkMatrix& matrix);
  void set_initial_transform(const SkM44& matrix);
  void set_initial_state(const SkRect& cull_rect, const SkMatrix& matrix);
  void set_initial_state(const SkRect& cull_rect, const SkM44& matrix);

  class AutoRestore {
   public:
    ~AutoRestore();

   protected:
    LayerStateStack* layer_state_stack_;

   private:
    AutoRestore(LayerStateStack* stack);
    friend class LayerStateStack;

    const size_t stack_restore_count_;
  };

  static constexpr int kCallerCanApplyOpacity = 0x1;
  static constexpr int kCallerCanApplyColorFilter = 0x2;
  static constexpr int kCallerCanApplyImageFilter = 0x4;
  static constexpr int kCallerCanApplyAnything =
      (kCallerCanApplyOpacity | kCallerCanApplyColorFilter |
       kCallerCanApplyImageFilter);

  class MutatorContext : public AutoRestore {
   public:
    // Immediately executes a saveLayer with all accumulated state
    // onto the canvas or builder to be applied at the next matching
    // restore. A saveLayer is always executed by this method even if
    // there are no outstanding attributes.
    void saveLayer(const SkRect& bounds);

    // Records the opacity for application at the next call to
    // saveLayer or applyState. A saveLayer may be executed at
    // this time if the opacity cannot be batched with other
    // outstanding attributes.
    void applyOpacity(const SkRect& bounds, SkScalar opacity);

    // Records the image filter for application at the next call to
    // saveLayer or applyState. A saveLayer may be executed at
    // this time if the image filter cannot be batched with other
    // outstanding attributes.
    // (Currently only opacity is recorded for batching)
    void applyImageFilter(const SkRect& bounds,
                          const std::shared_ptr<const DlImageFilter>& filter);

    // Records the color filter for application at the next call to
    // saveLayer or applyState. A saveLayer may be executed at
    // this time if the color filter cannot be batched with other
    // outstanding attributes.
    // (Currently only opacity is recorded for batching)
    void applyColorFilter(const SkRect& bounds,
                          const std::shared_ptr<const DlColorFilter>& filter);

    // Saves the state stack and immediately executes a saveLayer
    // with the indicated backdrop filter and any outstanding
    // state attributes. Since the backdrop filter only applies
    // to the pixels alrady on the screen when this call is made,
    // the backdrop filter will only be applied to the canvas or
    // builder installed at the time that this call is made, and
    // subsequent canvas or builder objects that are made delegates
    // will only see a saveLayer with the indicated blend_mode.
    void applyBackdropFilter(const SkRect& bounds,
                             const std::shared_ptr<const DlImageFilter>& filter,
                             DlBlendMode blend_mode);

    void translate(SkScalar tx, SkScalar ty);
    void translate(SkPoint tp) { translate(tp.fX, tp.fY); }
    void transform(const SkM44& m44);
    void transform(const SkMatrix& matrix);
    void integralTransform();

    void clipRect(const SkRect& rect, bool is_aa);
    void clipRRect(const SkRRect& rrect, bool is_aa);
    void clipPath(const SkPath& path, bool is_aa);

   private:
    MutatorContext(LayerStateStack* stack) : AutoRestore(stack) {}
    friend class LayerStateStack;
  };

  // Apply the outstanding state via saveLayer if necessary,
  // respecting the flags representing which potentially
  // outstanding attributes the calling layer can apply
  // themselves.
  //
  // A saveLayer may or may not be sent to the delegates depending
  // on how the outstanding state intersects with the flags supplied
  // by the caller.
  //
  // An AutoRestore instance will always be returned even if there
  // was no saveLayer applied.
  [[nodiscard]] AutoRestore applyState(const SkRect& bounds,
                                       int can_apply_flags = 0);

  SkScalar outstanding_opacity() const { return outstanding_.opacity; }

  std::shared_ptr<const DlColorFilter> outstanding_color_filter() const {
    return outstanding_.color_filter;
  }

  std::shared_ptr<const DlImageFilter> outstanding_image_filter() const {
    return outstanding_.image_filter;
  }

  SkRect outstanding_bounds() const { return outstanding_.save_layer_bounds; }

  // Fill the provided paint object with any oustanding attributes and
  // return a pointer to it, or return a nullptr if there were no
  // outstanding attributes to paint with.
  SkPaint* fill(SkPaint& paint) const { return outstanding_.fill(paint); }

  // Fill the provided paint object with any oustanding attributes and
  // return a pointer to it, or return a nullptr if there were no
  // outstanding attributes to paint with.
  DlPaint* fill(DlPaint& paint) const { return outstanding_.fill(paint); }

  SkRect device_cull_rect() const { return cull_rect_; }
  SkRect local_cull_rect() const;
  SkM44 transform_4x4() const { return matrix_; }
  SkMatrix transform_3x3() const { return matrix_.asM33(); }

  // Tests if painting content with the current outstanding attributes
  // will produce any content.
  bool painting_is_nop() const { return outstanding_.opacity <= 0; }

  // Tests if painting content with the given bounds will produce any output.
  bool content_culled(const SkRect& content_bounds) const;

  // Saves the current state of the state stack and returns a
  // MutatorContext which can be used to manipulate the state.
  // The state stack will be restored to its current state
  // when the MutatorContext object goes out of scope.
  [[nodiscard]] MutatorContext save();

  bool is_empty() const { return state_stack_.empty(); }

 private:
  size_t stack_count() const { return state_stack_.size(); }
  void restore_to_count(size_t restore_count);
  void reapply_all();

  void apply_last_entry() { state_stack_.back()->apply(this); }

  // The push methods simply push an associated StateEntry on the stack
  // and then apply it to the current canvas and builder.
  // ---------------------
  void push_attributes();
  void push_opacity(const SkRect& rect, SkScalar opacity);
  void push_color_filter(const SkRect& bounds,
                         const std::shared_ptr<const DlColorFilter>& filter);
  void push_image_filter(const SkRect& bounds,
                         const std::shared_ptr<const DlImageFilter>& filter);
  void push_backdrop(const SkRect& bounds,
                     const std::shared_ptr<const DlImageFilter>& filter,
                     DlBlendMode blend_mode);

  void push_translate(SkScalar tx, SkScalar ty);
  void push_transform(const SkM44& matrix);
  void push_transform(const SkMatrix& matrix);
  void push_integral_transform();

  void push_clip_rect(const SkRect& rect, bool is_aa);
  void push_clip_rrect(const SkRRect& rrect, bool is_aa);
  void push_clip_path(const SkPath& path, bool is_aa);
  // ---------------------

  // The maybe/needs_save_layer methods will determine if the indicated
  // attribute can be incorporated into the outstanding attributes as is,
  // or if the apply_flags are compatible with the outstanding attributes.
  // If the oustanding attributes are incompatible with the new attribute
  // or the apply flags, then a protective saveLayer will be executed.
  // ---------------------
  bool needs_save_layer(int flags) const;
  void save_layer(const SkRect& bounds);
  void maybe_save_layer_for_transform();
  void maybe_save_layer_for_clip();
  void maybe_save_layer(int apply_flags);
  void maybe_save_layer(SkScalar opacity);
  void maybe_save_layer(const std::shared_ptr<const DlColorFilter>& filter);
  void maybe_save_layer(const std::shared_ptr<const DlImageFilter>& filter);
  // ---------------------

  void intersect_cull_rect(const SkRect& clip, SkClipOp op, bool is_aa);
  void intersect_cull_rect(const SkRRect& clip, SkClipOp op, bool is_aa);
  void intersect_cull_rect(const SkPath& clip, SkClipOp op, bool is_aa);

  struct RenderingAttributes {
    // We need to record the last bounds we received for the last
    // attribute that we recorded so that we can perform a saveLayer
    // on the proper area. When an attribute is applied that cannot
    // be merged with the existing attributes, it will be submitted
    // with a bounds for its own source content, not the bounds for
    // the content that will be included in the saveLayer that applies
    // the existing outstanding attributes - thus we need to record
    // the bounds that were supplied with the most recent previous
    // attribute to be applied.
    SkRect save_layer_bounds{0, 0, 0, 0};

    SkScalar opacity = SK_Scalar1;
    std::shared_ptr<const DlColorFilter> color_filter;
    std::shared_ptr<const DlImageFilter> image_filter;

    SkPaint* fill(SkPaint& paint,
                  DlBlendMode mode = DlBlendMode::kSrcOver) const;
    DlPaint* fill(DlPaint& paint,
                  DlBlendMode mode = DlBlendMode::kSrcOver) const;

    bool operator==(const RenderingAttributes& other) const {
      return save_layer_bounds == other.save_layer_bounds &&
             opacity == other.opacity &&
             Equals(color_filter, other.color_filter) &&
             Equals(image_filter, other.image_filter);
    }
  };

  class StateEntry {
   public:
    virtual ~StateEntry() = default;

    virtual void apply(LayerStateStack* stack) const = 0;

    virtual void reapply(LayerStateStack* stack) const { apply(stack); }

    virtual void restore(LayerStateStack* stack) const {}
  };

  class AttributesEntry : public StateEntry {
   public:
    AttributesEntry(RenderingAttributes attributes) : attributes_(attributes) {}

    virtual void apply(LayerStateStack* stack) const override {}

    void restore(LayerStateStack* stack) const override;

   private:
    const RenderingAttributes attributes_;
  };

  class SaveEntry : public StateEntry {
   public:
    SaveEntry() = default;

    void apply(LayerStateStack* stack) const override;
    void restore(LayerStateStack* stack) const override;

   protected:
    virtual void do_checkerboard(LayerStateStack* stack) const {}
  };

  class SaveLayerEntry : public SaveEntry {
   public:
    SaveLayerEntry(const SkRect& bounds, DlBlendMode blend_mode)
        : bounds_(bounds), blend_mode_(blend_mode) {}

    void apply(LayerStateStack* stack) const override;

   protected:
    const SkRect bounds_;
    const DlBlendMode blend_mode_;

    void do_checkerboard(LayerStateStack* stack) const override;
  };

  class OpacityEntry : public StateEntry {
   public:
    OpacityEntry(const SkRect& bounds, SkScalar opacity)
        : bounds_(bounds), opacity_(opacity) {}

    void apply(LayerStateStack* stack) const override;
    void restore(LayerStateStack* stack) const override;

   private:
    const SkRect bounds_;
    const SkScalar opacity_;
  };

  class ImageFilterEntry : public StateEntry {
   public:
    ImageFilterEntry(const SkRect& bounds,
                     const std::shared_ptr<const DlImageFilter>& filter)
        : bounds_(bounds), filter_(filter) {}
    ~ImageFilterEntry() override = default;

    void apply(LayerStateStack* stack) const override;

   private:
    const SkRect bounds_;
    const std::shared_ptr<const DlImageFilter> filter_;
  };

  class ColorFilterEntry : public StateEntry {
   public:
    ColorFilterEntry(const SkRect& bounds,
                     const std::shared_ptr<const DlColorFilter>& filter)
        : bounds_(bounds), filter_(filter) {}
    ~ColorFilterEntry() override = default;

    void apply(LayerStateStack* stack) const override;

   private:
    const SkRect bounds_;
    const std::shared_ptr<const DlColorFilter> filter_;
  };

  class BackdropFilterEntry : public SaveLayerEntry {
   public:
    BackdropFilterEntry(const SkRect& bounds,
                        const std::shared_ptr<const DlImageFilter>& filter,
                        DlBlendMode blend_mode)
        : SaveLayerEntry(bounds, blend_mode), filter_(filter) {}
    ~BackdropFilterEntry() override = default;

    void apply(LayerStateStack* stack) const override;
    void restore(LayerStateStack* stack) const override;

    void reapply(LayerStateStack* stack) const override;

   private:
    const std::shared_ptr<const DlImageFilter> filter_;
    friend class LayerStateStack;
  };

  class TransformEntry : public StateEntry {
   public:
    TransformEntry(const SkM44& matrix) : previous_matrix_(matrix) {}

    void restore(LayerStateStack* stack) const override;

   private:
    const SkM44 previous_matrix_;
  };

  class TranslateEntry : public TransformEntry {
   public:
    TranslateEntry(const SkM44& previous_matrix, SkScalar tx, SkScalar ty)
        : TransformEntry(previous_matrix), tx_(tx), ty_(ty) {}

    void apply(LayerStateStack* stack) const override;

   private:
    const SkScalar tx_;
    const SkScalar ty_;
  };

  class TransformMatrixEntry : public TransformEntry {
   public:
    TransformMatrixEntry(const SkM44 previous_matrix, const SkMatrix& matrix)
        : TransformEntry(previous_matrix), matrix_(matrix) {}

    void apply(LayerStateStack* stack) const override;

   private:
    const SkMatrix matrix_;
  };

  class TransformM44Entry : public TransformEntry {
   public:
    TransformM44Entry(const SkM44 previous_matrix, const SkM44& m44)
        : TransformEntry(previous_matrix), m44_(m44) {}

    void apply(LayerStateStack* stack) const override;

   private:
    const SkM44 m44_;
  };

  class IntegralTransformEntry : public TransformEntry {
   public:
    IntegralTransformEntry(const SkM44 previous_matrix)
        : TransformEntry(previous_matrix) {}

    void apply(LayerStateStack* stack) const override;
  };

  class ClipEntry : public StateEntry {
   protected:
    ClipEntry(const SkRect& cull_rect, bool is_aa)
        : previous_cull_rect_(cull_rect), is_aa_(is_aa) {}

    void restore(LayerStateStack* stack) const override;

    const SkRect previous_cull_rect_;
    const bool is_aa_;
  };

  class ClipRectEntry : public ClipEntry {
   public:
    ClipRectEntry(const SkRect& cull_rect, const SkRect& clip_rect, bool is_aa)
        : ClipEntry(cull_rect, is_aa), clip_rect_(clip_rect) {}

    void apply(LayerStateStack* stack) const override;

   private:
    const SkRect clip_rect_;
  };

  class ClipRRectEntry : public ClipEntry {
   public:
    ClipRRectEntry(const SkRect& cull_rect,
                   const SkRRect& clip_rrect,
                   bool is_aa)
        : ClipEntry(cull_rect, is_aa), clip_rrect_(clip_rrect) {}

    void apply(LayerStateStack* stack) const override;

   private:
    const SkRRect clip_rrect_;
  };

  class ClipPathEntry : public ClipEntry {
   public:
    ClipPathEntry(const SkRect& cull_rect, const SkPath& clip_path, bool is_aa)
        : ClipEntry(cull_rect, is_aa), clip_path_(clip_path) {}
    ~ClipPathEntry() override = default;

    void apply(LayerStateStack* stack) const override;

   private:
    const SkPath clip_path_;
  };

  std::vector<std::unique_ptr<StateEntry>> state_stack_;
  friend class MutatorContext;

  SkM44 initial_matrix_;
  SkM44 matrix_;
  SkRect initial_cull_rect_;
  SkRect cull_rect_;

  SkCanvas* canvas_ = nullptr;
  DisplayListBuilder* builder_ = nullptr;
  MutatorsStack* mutators_ = nullptr;
  int restore_count_ = 0;
  RenderingAttributes outstanding_;
  CheckerboardFunc checkerboard_func_ = nullptr;

  friend class SaveLayerEntry;
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_LAYERS_LAYER_STATE_STACK_H_
