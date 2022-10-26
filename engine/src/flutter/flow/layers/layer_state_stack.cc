// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/layer_state_stack.h"
#include "flutter/flow/layers/layer.h"
#include "flutter/flow/paint_utils.h"
#include "flutter/flow/raster_cache_util.h"

namespace flutter {

using AutoRestore = LayerStateStack::AutoRestore;
using MutatorContext = LayerStateStack::MutatorContext;

static inline bool has_perspective(const SkM44& matrix) {
  return (matrix.rc(3, 0) != 0 ||  //
          matrix.rc(3, 1) != 0 ||  //
          matrix.rc(3, 2) != 0 ||  //
          matrix.rc(3, 3) != 1);
}

LayerStateStack::LayerStateStack(const SkRect* cull_rect) {
  if (cull_rect) {
    initial_cull_rect_ = cull_rect_ = *cull_rect;
  } else {
    initial_cull_rect_ = cull_rect_ = kGiantRect;
  }
}

void LayerStateStack::clear_delegate() {
  if (canvas_) {
    canvas_->restoreToCount(restore_count_);
    canvas_ = nullptr;
  }
  if (builder_) {
    builder_->restoreToCount(restore_count_);
    builder_ = nullptr;
  }
  if (mutators_) {
    mutators_->PopTo(restore_count_);
    mutators_ = nullptr;
  }
}

void LayerStateStack::set_delegate(SkCanvas* canvas) {
  if (canvas == canvas_) {
    return;
  }
  clear_delegate();
  if (canvas) {
    restore_count_ = canvas->getSaveCount();
    canvas_ = canvas;
    reapply_all();
  }
}

void LayerStateStack::set_delegate(DisplayListBuilder* builder) {
  if (builder == builder_) {
    return;
  }
  clear_delegate();
  if (builder) {
    restore_count_ = builder->getSaveCount();
    builder_ = builder;
    reapply_all();
  }
}

void LayerStateStack::set_delegate(MutatorsStack* stack) {
  if (stack == mutators_) {
    return;
  }
  clear_delegate();
  if (stack) {
    restore_count_ = stack->stack_count();
    mutators_ = stack;
    reapply_all();
  }
}

void LayerStateStack::set_initial_cull_rect(const SkRect& cull_rect) {
  FML_DCHECK(is_empty()) << "set_initial_cull_rect() must be called before any "
                            "state is pushed onto the state stack";
  initial_cull_rect_ = cull_rect_ = cull_rect;
}

void LayerStateStack::set_initial_transform(const SkMatrix& matrix) {
  FML_DCHECK(is_empty()) << "set_initial_transform() must be called before any "
                            "state is pushed onto the state stack";
  initial_matrix_ = matrix_ = SkM44(matrix);
}

void LayerStateStack::set_initial_transform(const SkM44& matrix) {
  FML_DCHECK(is_empty()) << "set_initial_transform() must be called before any "
                            "state is pushed onto the state stack";
  initial_matrix_ = matrix_ = matrix;
}

void LayerStateStack::set_initial_state(const SkRect& cull_rect,
                                        const SkMatrix& matrix) {
  FML_DCHECK(is_empty()) << "set_initial_state() must be called before any "
                            "state is pushed onto the state stack";
  initial_cull_rect_ = cull_rect_ = cull_rect;
  initial_matrix_ = matrix_ = SkM44(matrix);
}

void LayerStateStack::set_initial_state(const SkRect& cull_rect,
                                        const SkM44& matrix) {
  FML_DCHECK(is_empty()) << "set_initial_state() must be called before any "
                            "state is pushed onto the state stack";
  initial_cull_rect_ = cull_rect_ = cull_rect;
  initial_matrix_ = matrix_ = matrix;
}

void LayerStateStack::reapply_all() {
  // We use a local RenderingAttributes instance so that it can track the
  // necessary state changes independently as they occur in the stack.
  // Reusing |outstanding_| would wreak havoc on the current state of
  // the stack. When we are finished, though, the local attributes
  // contents should match the current outstanding_ values;
  RenderingAttributes attributes = outstanding_;
  SkM44 matrix = matrix_;
  SkRect cull_rect = cull_rect_;
  outstanding_ = {};
  matrix_ = initial_matrix_;
  cull_rect_ = initial_cull_rect_;
  for (auto& state : state_stack_) {
    state->reapply(this);
  }
  FML_DCHECK(attributes == outstanding_);
  FML_DCHECK(matrix == matrix_);
  FML_DCHECK(cull_rect == cull_rect_);
}

AutoRestore::AutoRestore(LayerStateStack* stack)
    : layer_state_stack_(stack), stack_restore_count_(stack->stack_count()) {}

AutoRestore::~AutoRestore() {
  layer_state_stack_->restore_to_count(stack_restore_count_);
}

AutoRestore LayerStateStack::applyState(const SkRect& bounds,
                                        int can_apply_flags) {
  auto ret = AutoRestore(this);
  if (needs_save_layer(can_apply_flags)) {
    save_layer(bounds);
  }
  return ret;
}

SkPaint* LayerStateStack::RenderingAttributes::fill(SkPaint& paint,
                                                    DlBlendMode mode) const {
  SkPaint* ret = nullptr;
  if (opacity < SK_Scalar1) {
    paint.setAlphaf(std::max(opacity, 0.0f));
    ret = &paint;
  } else {
    paint.setAlphaf(SK_Scalar1);
  }
  if (color_filter) {
    paint.setColorFilter(color_filter->skia_object());
    ret = &paint;
  } else {
    paint.setColorFilter(nullptr);
  }
  if (image_filter) {
    paint.setImageFilter(image_filter->skia_object());
    ret = &paint;
  } else {
    paint.setImageFilter(nullptr);
  }
  paint.setBlendMode(ToSk(mode));
  if (mode != DlBlendMode::kSrcOver) {
    ret = &paint;
  }
  return ret;
}

DlPaint* LayerStateStack::RenderingAttributes::fill(DlPaint& paint,
                                                    DlBlendMode mode) const {
  DlPaint* ret = nullptr;
  if (opacity < SK_Scalar1) {
    paint.setOpacity(std::max(opacity, 0.0f));
    ret = &paint;
  } else {
    paint.setOpacity(SK_Scalar1);
  }
  paint.setColorFilter(color_filter);
  if (color_filter) {
    ret = &paint;
  }
  paint.setImageFilter(image_filter);
  if (image_filter) {
    ret = &paint;
  }
  paint.setBlendMode(mode);
  if (mode != DlBlendMode::kSrcOver) {
    ret = &paint;
  }
  return ret;
}

SkRect LayerStateStack::local_cull_rect() const {
  SkM44 inverse;
  if (cull_rect_.isEmpty() || !matrix_.invert(&inverse)) {
    // Either rendering is clipped out or transformed into emptiness
    return SkRect::MakeEmpty();
  }
  if (has_perspective(inverse)) {
    // We could do a 4-point long-form conversion, but since this is
    // only used for culling, let's just return a non-constricting
    // cull rect.
    return kGiantRect;
  }
  return inverse.asM33().mapRect(cull_rect_);
}

bool LayerStateStack::content_culled(const SkRect& content_bounds) const {
  if (cull_rect_.isEmpty() || content_bounds.isEmpty()) {
    return true;
  }
  if (has_perspective(matrix_)) {
    return false;
  }
  return !matrix_.asM33().mapRect(content_bounds).intersects(cull_rect_);
}

MutatorContext LayerStateStack::save() {
  auto ret = MutatorContext(this);
  state_stack_.emplace_back(std::make_unique<SaveEntry>());
  state_stack_.back()->apply(this);
  return ret;
}

void MutatorContext::saveLayer(const SkRect& bounds) {
  layer_state_stack_->save_layer(bounds);
}

void MutatorContext::applyOpacity(const SkRect& bounds, SkScalar opacity) {
  if (opacity < SK_Scalar1) {
    layer_state_stack_->push_attributes();
    layer_state_stack_->maybe_save_layer(opacity);
    layer_state_stack_->push_opacity(bounds, opacity);
  }
}

void MutatorContext::applyImageFilter(
    const SkRect& bounds,
    const std::shared_ptr<const DlImageFilter>& filter) {
  if (filter) {
    layer_state_stack_->push_attributes();
    layer_state_stack_->maybe_save_layer(filter);
    layer_state_stack_->push_image_filter(bounds, filter);
  }
}

void MutatorContext::applyColorFilter(
    const SkRect& bounds,
    const std::shared_ptr<const DlColorFilter>& filter) {
  if (filter) {
    layer_state_stack_->push_attributes();
    layer_state_stack_->maybe_save_layer(filter);
    layer_state_stack_->push_color_filter(bounds, filter);
  }
}

void MutatorContext::applyBackdropFilter(
    const SkRect& bounds,
    const std::shared_ptr<const DlImageFilter>& filter,
    DlBlendMode blend_mode) {
  layer_state_stack_->push_backdrop(bounds, filter, blend_mode);
}

void MutatorContext::translate(SkScalar tx, SkScalar ty) {
  if (!(tx == 0 && ty == 0)) {
    layer_state_stack_->maybe_save_layer_for_transform();
    layer_state_stack_->push_translate(tx, ty);
  }
}

void MutatorContext::transform(const SkMatrix& matrix) {
  if (matrix.isTranslate()) {
    translate(matrix.getTranslateX(), matrix.getTranslateY());
  } else if (!matrix.isIdentity()) {
    layer_state_stack_->maybe_save_layer_for_transform();
    layer_state_stack_->push_transform(matrix);
  }
}

void MutatorContext::transform(const SkM44& m44) {
  layer_state_stack_->maybe_save_layer_for_transform();
  layer_state_stack_->push_transform(m44);
}

void MutatorContext::integralTransform() {
  layer_state_stack_->maybe_save_layer_for_transform();
  layer_state_stack_->push_integral_transform();
}

void MutatorContext::clipRect(const SkRect& rect, bool is_aa) {
  layer_state_stack_->maybe_save_layer_for_clip();
  layer_state_stack_->push_clip_rect(rect, is_aa);
}

void MutatorContext::clipRRect(const SkRRect& rrect, bool is_aa) {
  layer_state_stack_->maybe_save_layer_for_clip();
  layer_state_stack_->push_clip_rrect(rrect, is_aa);
}

void MutatorContext::clipPath(const SkPath& path, bool is_aa) {
  layer_state_stack_->maybe_save_layer_for_clip();
  layer_state_stack_->push_clip_path(path, is_aa);
}

void LayerStateStack::restore_to_count(size_t restore_count) {
  while (state_stack_.size() > restore_count) {
    state_stack_.back()->restore(this);
    state_stack_.pop_back();
  }
}

void LayerStateStack::push_attributes() {
  state_stack_.emplace_back(std::make_unique<AttributesEntry>(outstanding_));
}

void LayerStateStack::push_opacity(const SkRect& bounds, SkScalar opacity) {
  state_stack_.emplace_back(std::make_unique<OpacityEntry>(bounds, opacity));
  apply_last_entry();
}

void LayerStateStack::push_color_filter(
    const SkRect& bounds,
    const std::shared_ptr<const DlColorFilter>& filter) {
  state_stack_.emplace_back(std::make_unique<ColorFilterEntry>(bounds, filter));
  apply_last_entry();
}

void LayerStateStack::push_image_filter(
    const SkRect& bounds,
    const std::shared_ptr<const DlImageFilter>& filter) {
  state_stack_.emplace_back(std::make_unique<ImageFilterEntry>(bounds, filter));
  apply_last_entry();
}

void LayerStateStack::push_backdrop(
    const SkRect& bounds,
    const std::shared_ptr<const DlImageFilter>& filter,
    DlBlendMode blend_mode) {
  state_stack_.emplace_back(
      std::make_unique<BackdropFilterEntry>(bounds, filter, blend_mode));
  apply_last_entry();
}

void LayerStateStack::push_translate(SkScalar tx, SkScalar ty) {
  state_stack_.emplace_back(std::make_unique<TranslateEntry>(matrix_, tx, ty));
  apply_last_entry();
}

void LayerStateStack::push_transform(const SkM44& m44) {
  state_stack_.emplace_back(std::make_unique<TransformM44Entry>(matrix_, m44));
  apply_last_entry();
}

void LayerStateStack::push_transform(const SkMatrix& matrix) {
  state_stack_.emplace_back(
      std::make_unique<TransformMatrixEntry>(matrix_, matrix));
  apply_last_entry();
}

void LayerStateStack::push_integral_transform() {
  state_stack_.emplace_back(std::make_unique<IntegralTransformEntry>(matrix_));
  apply_last_entry();
}

void LayerStateStack::push_clip_rect(const SkRect& rect, bool is_aa) {
  state_stack_.emplace_back(
      std::make_unique<ClipRectEntry>(cull_rect_, rect, is_aa));
  apply_last_entry();
}

void LayerStateStack::push_clip_rrect(const SkRRect& rrect, bool is_aa) {
  state_stack_.emplace_back(
      std::make_unique<ClipRRectEntry>(cull_rect_, rrect, is_aa));
  apply_last_entry();
}

void LayerStateStack::push_clip_path(const SkPath& path, bool is_aa) {
  state_stack_.emplace_back(
      std::make_unique<ClipPathEntry>(cull_rect_, path, is_aa));
  apply_last_entry();
}

bool LayerStateStack::needs_save_layer(int flags) const {
  if (outstanding_.opacity < SK_Scalar1 &&
      (flags & LayerStateStack::kCallerCanApplyOpacity) == 0) {
    return true;
  }
  if (outstanding_.image_filter &&
      (flags & LayerStateStack::kCallerCanApplyImageFilter) == 0) {
    return true;
  }
  if (outstanding_.color_filter &&
      (flags & LayerStateStack::kCallerCanApplyColorFilter) == 0) {
    return true;
  }
  return false;
}

void LayerStateStack::save_layer(const SkRect& bounds) {
  push_attributes();
  state_stack_.emplace_back(
      std::make_unique<SaveLayerEntry>(bounds, DlBlendMode::kSrcOver));
  apply_last_entry();
}

void LayerStateStack::maybe_save_layer_for_transform() {
  // Alpha and ColorFilter don't care about transform
  if (outstanding_.image_filter) {
    save_layer(outstanding_.save_layer_bounds);
  }
}

void LayerStateStack::maybe_save_layer_for_clip() {
  // Alpha and ColorFilter don't care about clipping
  // - Alpha of clipped content == clip of alpha content
  // - Color-filtering of clipped content == clip of color-filtered content
  if (outstanding_.image_filter) {
    save_layer(outstanding_.save_layer_bounds);
  }
}

void LayerStateStack::maybe_save_layer(int apply_flags) {
  if (needs_save_layer(apply_flags)) {
    save_layer(outstanding_.save_layer_bounds);
  }
}

void LayerStateStack::maybe_save_layer(SkScalar opacity) {
  if (outstanding_.image_filter) {
    save_layer(outstanding_.save_layer_bounds);
  }
}

void LayerStateStack::maybe_save_layer(
    const std::shared_ptr<const DlColorFilter>& filter) {
  if (outstanding_.color_filter || outstanding_.image_filter ||
      (outstanding_.opacity < SK_Scalar1 &&
       !filter->can_commute_with_opacity())) {
    // TBD: compose the 2 color filters together.
    save_layer(outstanding_.save_layer_bounds);
  }
}

void LayerStateStack::maybe_save_layer(
    const std::shared_ptr<const DlImageFilter>& filter) {
  if (outstanding_.image_filter) {
    // TBD: compose the 2 image filters together.
    save_layer(outstanding_.save_layer_bounds);
  }
}

void LayerStateStack::intersect_cull_rect(const SkRRect& clip,
                                          SkClipOp op,
                                          bool is_aa) {
  switch (op) {
    case SkClipOp::kIntersect:
      break;
    case SkClipOp::kDifference:
      if (!clip.isRect()) {
        return;
      }
      break;
  }
  intersect_cull_rect(clip.getBounds(), op, is_aa);
}

void LayerStateStack::intersect_cull_rect(const SkPath& clip,
                                          SkClipOp op,
                                          bool is_aa) {
  SkRect bounds;
  switch (op) {
    case SkClipOp::kIntersect:
      bounds = clip.getBounds();
      break;
    case SkClipOp::kDifference:
      if (!clip.isRect(&bounds)) {
        return;
      }
      break;
  }
  intersect_cull_rect(bounds, op, is_aa);
}

void LayerStateStack::intersect_cull_rect(const SkRect& clip,
                                          SkClipOp op,
                                          bool is_aa) {
  if (has_perspective(matrix_)) {
    // We can conservatively ignore this clip.
    return;
  }
  if (cull_rect_.isEmpty()) {
    // No point in intersecting further.
    return;
  }
  SkRect rect = clip;
  switch (op) {
    case SkClipOp::kIntersect:
      if (rect.isEmpty()) {
        cull_rect_.setEmpty();
        break;
      }
      rect = matrix_.asM33().mapRect(rect);
      if (is_aa) {
        rect.roundOut(&rect);
      }
      if (!cull_rect_.intersect(rect)) {
        cull_rect_.setEmpty();
      }
      break;
    case SkClipOp::kDifference:
      if (rect.isEmpty() || !rect.intersects(cull_rect_)) {
        break;
      }
      if (matrix_.asM33().mapRect(&rect)) {
        // This technique only works if it is rect -> rect
        if (is_aa) {
          SkIRect rounded;
          rect.round(&rounded);
          if (rounded.isEmpty()) {
            break;
          }
          rect.set(rounded);
        }
        if (rect.fLeft <= cull_rect_.fLeft &&
            rect.fRight >= cull_rect_.fRight) {
          // bounds spans entire width of cull_rect_
          // therefore we can slice off a top or bottom
          // edge of the cull_rect_.
          SkScalar top = std::max(rect.fBottom, cull_rect_.fTop);
          SkScalar btm = std::min(rect.fTop, cull_rect_.fBottom);
          if (top < btm) {
            cull_rect_.fTop = top;
            cull_rect_.fBottom = btm;
          } else {
            cull_rect_.setEmpty();
          }
        } else if (rect.fTop <= cull_rect_.fTop &&
                   rect.fBottom >= cull_rect_.fBottom) {
          // bounds spans entire height of cull_rect_
          // therefore we can slice off a left or right
          // edge of the cull_rect_.
          SkScalar lft = std::max(rect.fRight, cull_rect_.fLeft);
          SkScalar rgt = std::min(rect.fLeft, cull_rect_.fRight);
          if (lft < rgt) {
            cull_rect_.fLeft = lft;
            cull_rect_.fRight = rgt;
          } else {
            cull_rect_.setEmpty();
          }
        }
      }
      break;
  }
}

void LayerStateStack::AttributesEntry::restore(LayerStateStack* stack) const {
  stack->outstanding_ = attributes_;
}

void LayerStateStack::SaveEntry::apply(LayerStateStack* stack) const {
  if (stack->canvas_) {
    stack->canvas_->save();
  }
  if (stack->builder_) {
    stack->builder_->save();
  }
}

void LayerStateStack::SaveEntry::restore(LayerStateStack* stack) const {
  do_checkerboard(stack);
  if (stack->canvas_) {
    stack->canvas_->restore();
  }
  if (stack->builder_) {
    stack->builder_->restore();
  }
}

void LayerStateStack::SaveLayerEntry::apply(LayerStateStack* stack) const {
  if (stack->canvas_) {
    TRACE_EVENT0("flutter", "Canvas::saveLayer");
    SkPaint paint;
    stack->canvas_->saveLayer(bounds_,
                              stack->outstanding_.fill(paint, blend_mode_));
  }
  if (stack->builder_) {
    TRACE_EVENT0("flutter", "Canvas::saveLayer");
    DlPaint paint;
    stack->builder_->saveLayer(&bounds_,
                               stack->outstanding_.fill(paint, blend_mode_));
  }
  stack->outstanding_ = {};
}

void LayerStateStack::SaveLayerEntry::do_checkerboard(
    LayerStateStack* stack) const {
  if (stack->checkerboard_func_) {
    (*stack->checkerboard_func_)(stack->canvas_, stack->builder_, bounds_);
  }
}

void LayerStateStack::OpacityEntry::apply(LayerStateStack* stack) const {
  stack->outstanding_.save_layer_bounds = bounds_;
  stack->outstanding_.opacity *= opacity_;
  if (stack->mutators_) {
    stack->mutators_->PushOpacity(DlColor::toAlpha(opacity_));
  }
}

void LayerStateStack::OpacityEntry::restore(LayerStateStack* stack) const {
  if (stack->mutators_) {
    stack->mutators_->Pop();
  }
}

void LayerStateStack::ImageFilterEntry::apply(LayerStateStack* stack) const {
  stack->outstanding_.save_layer_bounds = bounds_;
  stack->outstanding_.image_filter = filter_;
  if (stack->mutators_) {
    // MutatorsStack::PushImageFilter does not exist...
  }
}

void LayerStateStack::ColorFilterEntry::apply(LayerStateStack* stack) const {
  stack->outstanding_.save_layer_bounds = bounds_;
  stack->outstanding_.color_filter = filter_;
  if (stack->mutators_) {
    // MutatorsStack::PushColorFilter does not exist...
  }
}

void LayerStateStack::BackdropFilterEntry::apply(LayerStateStack* stack) const {
  if (stack->canvas_) {
    TRACE_EVENT0("flutter", "Canvas::saveLayer");
    sk_sp<SkImageFilter> backdrop_filter =
        filter_ ? filter_->skia_object() : nullptr;
    SkPaint paint;
    SkPaint* pPaint = stack->outstanding_.fill(paint, blend_mode_);
    stack->canvas_->saveLayer(
        SkCanvas::SaveLayerRec{&bounds_, pPaint, backdrop_filter.get(), 0});
  }
  if (stack->builder_) {
    TRACE_EVENT0("flutter", "Canvas::saveLayer");
    DlPaint paint;
    DlPaint* pPaint = stack->outstanding_.fill(paint, blend_mode_);
    stack->builder_->saveLayer(&bounds_, pPaint, filter_.get());
  }
  if (stack->mutators_) {
    stack->mutators_->PushBackdropFilter(filter_);
  }
  stack->outstanding_ = {};
}

void LayerStateStack::BackdropFilterEntry::restore(
    LayerStateStack* stack) const {
  if (stack->mutators_) {
    stack->mutators_->Pop();
  }
  LayerStateStack::SaveLayerEntry::restore(stack);
}

void LayerStateStack::BackdropFilterEntry::reapply(
    LayerStateStack* stack) const {
  // On the reapply for subsequent overlay layers, we do not
  // want to reapply the backdrop filter, but we do need to
  // do a saveLayer to encapsulate the contents and match the
  // restore that will be forthcoming. Note that this is not
  // perfect if the BlendMode is not associative as we will be
  // compositing multiple parts of the content in batches.
  // Luckily the most common SrcOver is associative.
  SaveLayerEntry::apply(stack);
}

void LayerStateStack::TransformEntry::restore(LayerStateStack* stack) const {
  stack->matrix_ = previous_matrix_;
  if (stack->mutators_) {
    stack->mutators_->Pop();
  }
}

void LayerStateStack::TranslateEntry::apply(LayerStateStack* stack) const {
  if (stack->canvas_) {
    stack->canvas_->translate(tx_, ty_);
  }
  if (stack->builder_) {
    stack->builder_->translate(tx_, ty_);
  }
  if (stack->mutators_) {
    stack->mutators_->PushTransform(SkMatrix::Translate(tx_, ty_));
  }
  stack->matrix_.preConcat(SkM44::Translate(tx_, ty_));
}

void LayerStateStack::TransformMatrixEntry::apply(
    LayerStateStack* stack) const {
  if (stack->canvas_) {
    stack->canvas_->concat(matrix_);
  }
  if (stack->builder_) {
    stack->builder_->transform(matrix_);
  }
  if (stack->mutators_) {
    stack->mutators_->PushTransform(matrix_);
  }
  stack->matrix_.preConcat(matrix_);
}

void LayerStateStack::TransformM44Entry::apply(LayerStateStack* stack) const {
  if (stack->canvas_) {
    stack->canvas_->concat(m44_);
  }
  if (stack->builder_) {
    stack->builder_->transform(m44_);
  }
  if (stack->mutators_) {
    stack->mutators_->PushTransform(m44_.asM33());
  }
  stack->matrix_.preConcat(m44_);
}

void LayerStateStack::IntegralTransformEntry::apply(
    LayerStateStack* stack) const {
  SkM44 matrix = RasterCacheUtil::GetIntegralTransCTM(stack->matrix_);
  if (stack->canvas_) {
    stack->canvas_->setMatrix(matrix);
  }
  if (stack->builder_) {
    stack->builder_->transformReset();
    stack->builder_->transform(matrix);
  }
  if (stack->mutators_) {
    // There is no "SetMatrix" on MutatorsStack, but we need to push
    // something to match the corresponding pop on the transform
    // restore.
    stack->mutators_->PushTransform(SkMatrix::I());
  }
  stack->matrix_ = matrix;
}

void LayerStateStack::ClipEntry::restore(LayerStateStack* stack) const {
  stack->cull_rect_ = previous_cull_rect_;
  if (stack->mutators_) {
    stack->mutators_->Pop();
  }
}

void LayerStateStack::ClipRectEntry::apply(LayerStateStack* stack) const {
  if (stack->canvas_) {
    stack->canvas_->clipRect(clip_rect_, SkClipOp::kIntersect, is_aa_);
  }
  if (stack->builder_) {
    stack->builder_->clipRect(clip_rect_, SkClipOp::kIntersect, is_aa_);
  }
  if (stack->mutators_) {
    stack->mutators_->PushClipRect(clip_rect_);
  }
  stack->intersect_cull_rect(clip_rect_, SkClipOp::kIntersect, is_aa_);
}

void LayerStateStack::ClipRRectEntry::apply(LayerStateStack* stack) const {
  if (stack->canvas_) {
    stack->canvas_->clipRRect(clip_rrect_, SkClipOp::kIntersect, is_aa_);
  }
  if (stack->builder_) {
    stack->builder_->clipRRect(clip_rrect_, SkClipOp::kIntersect, is_aa_);
  }
  if (stack->mutators_) {
    stack->mutators_->PushClipRRect(clip_rrect_);
  }
  stack->intersect_cull_rect(clip_rrect_, SkClipOp::kIntersect, is_aa_);
}

void LayerStateStack::ClipPathEntry::apply(LayerStateStack* stack) const {
  if (stack->canvas_) {
    stack->canvas_->clipPath(clip_path_, SkClipOp::kIntersect, is_aa_);
  }
  if (stack->builder_) {
    stack->builder_->clipPath(clip_path_, SkClipOp::kIntersect, is_aa_);
  }
  if (stack->mutators_) {
    stack->mutators_->PushClipPath(clip_path_);
  }
  stack->intersect_cull_rect(clip_path_, SkClipOp::kIntersect, is_aa_);
}

}  // namespace flutter
