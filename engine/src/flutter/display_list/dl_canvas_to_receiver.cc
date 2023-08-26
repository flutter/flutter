// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/dl_canvas_to_receiver.h"

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/dl_blend_mode.h"
#include "flutter/display_list/dl_op_flags.h"
#include "flutter/display_list/dl_op_records.h"
#include "flutter/display_list/effects/dl_color_source.h"
#include "flutter/display_list/utils/dl_bounds_accumulator.h"
#include "fml/logging.h"
#include "third_party/skia/include/core/SkScalar.h"

namespace flutter {

DlCanvasToReceiver::DlCanvasToReceiver(
    std::shared_ptr<DlCanvasReceiver> receiver)
    : receiver_(std::move(receiver)) {
  layer_stack_.emplace_back();
  current_layer_ = &layer_stack_.back();
}

SkISize DlCanvasToReceiver::GetBaseLayerSize() const {
  CheckAlive();
  return receiver_->base_device_cull_rect().roundOut().size();
}

SkImageInfo DlCanvasToReceiver::GetImageInfo() const {
  CheckAlive();
  SkISize size = GetBaseLayerSize();
  return SkImageInfo::MakeUnknown(size.width(), size.height());
}

bool DlCanvasToReceiver::SetAttributesFromPaint(
    const DlPaint* paint,
    const DisplayListAttributeFlags flags) {
  if (paint == nullptr) {
    return true;
  }

  bool can_inherit_opacity = true;
  if (flags.applies_anti_alias()) {
    bool aa = paint->isAntiAlias();
    if (current_.isAntiAlias() != aa) {
      current_.setAntiAlias(aa);
      receiver_->setAntiAlias(aa);
    }
  }
  if (flags.applies_dither()) {
    bool dither = paint->isDither();
    if (current_.isDither() != dither) {
      current_.setDither(dither);
      receiver_->setDither(dither);
    }
  }
  if (flags.applies_alpha_or_color()) {
    DlColor color = paint->getColor();
    if (current_.getColor() != color) {
      current_.setColor(color);
      receiver_->setColor(color);
    }
  }
  if (flags.applies_blend()) {
    DlBlendMode mode = paint->getBlendMode();
    if (current_.getBlendMode() != mode) {
      current_.setBlendMode(mode);
      receiver_->setBlendMode(mode);
    }
    if (!IsOpacityCompatible(mode)) {
      can_inherit_opacity = false;
    }
  }
  if (flags.applies_style()) {
    DlDrawStyle style = paint->getDrawStyle();
    if (current_.getDrawStyle() != style) {
      current_.setDrawStyle(style);
      receiver_->setDrawStyle(style);
    }
  }
  if (flags.is_stroked(paint->getDrawStyle())) {
    SkScalar width = paint->getStrokeWidth();
    if (current_.getStrokeWidth() != width) {
      current_.setStrokeWidth(width);
      receiver_->setStrokeWidth(width);
    }
    if (flags.may_have_trouble_with_hairlines() && width <= 0) {
      can_inherit_opacity = false;
    }
    SkScalar miter = paint->getStrokeMiter();
    if (current_.getStrokeMiter() != miter) {
      current_.setStrokeMiter(miter);
      receiver_->setStrokeMiter(miter);
    }
    DlStrokeCap cap = paint->getStrokeCap();
    if (current_.getStrokeCap() != cap) {
      current_.setStrokeCap(cap);
      receiver_->setStrokeCap(cap);
    }
    DlStrokeJoin join = paint->getStrokeJoin();
    if (current_.getStrokeJoin() != join) {
      current_.setStrokeJoin(join);
      receiver_->setStrokeJoin(join);
    }
  }
  if (flags.applies_shader()) {
    auto source = paint->getColorSourcePtr();
    if (NotEquals(current_.getColorSourcePtr(), source)) {
      current_.setColorSource(paint->getColorSource());
      receiver_->setColorSource(source);
    }
  }
  if (flags.applies_color_filter()) {
    bool invert = paint->isInvertColors();
    if (current_.isInvertColors() != invert) {
      current_.setInvertColors(invert);
      receiver_->setInvertColors(invert);
    }
    auto filter = paint->getColorFilterPtr();
    if (NotEquals(current_.getColorFilterPtr(), filter)) {
      current_.setColorFilter(paint->getColorFilter());
      receiver_->setColorFilter(filter);
    }
    if (invert || filter) {
      can_inherit_opacity = false;
    }
  }
  if (flags.applies_image_filter()) {
    auto filter = paint->getImageFilterPtr();
    if (NotEquals(current_.getImageFilterPtr(), filter)) {
      current_.setImageFilter(paint->getImageFilter());
      receiver_->setImageFilter(filter);
    }
  }
  if (flags.applies_path_effect()) {
    auto effect = paint->getPathEffectPtr();
    if (NotEquals(current_.getPathEffectPtr(), effect)) {
      current_.setPathEffect(paint->getPathEffect());
      receiver_->setPathEffect(effect);
    }
  }
  if (flags.applies_mask_filter()) {
    auto filter = paint->getMaskFilterPtr();
    if (NotEquals(current_.getMaskFilterPtr(), filter)) {
      current_.setMaskFilter(paint->getMaskFilter());
      receiver_->setMaskFilter(filter);
    }
  }
  return can_inherit_opacity;
}

void DlCanvasToReceiver::Save() {
  CheckAlive();
  bool is_nop = current_layer_->state_is_nop_;
  layer_stack_.emplace_back();
  current_layer_ = &layer_stack_.back();
  current_layer_->state_is_nop_ = is_nop;
  receiver_->save();
}
void DlCanvasToReceiver::SaveLayer(const SkRect* bounds,
                                   const DlPaint* paint,
                                   const DlImageFilter* backdrop) {
  CheckAlive();
  SaveLayerOptions options = paint ? SaveLayerOptions::kWithAttributes  //
                                   : SaveLayerOptions::kNoAttributes;
  DisplayListAttributeFlags flags = paint ? kSaveLayerWithPaintFlags  //
                                          : kSaveLayerFlags;
  OpResult result = PaintResult(paint, flags);
  if (result == OpResult::kNoEffect) {
    Save();
    current_layer_->state_is_nop_ = true;
    return;
  }

  bool unbounded = false;
  if (backdrop) {
    // A backdrop will pre-fill up to the entire surface, bounded by
    // the clip.
    unbounded = true;
  } else if (!paint_nops_on_transparency(paint)) {
    // The actual flood of the outer layer clip based on the paint
    // will occur after the (eventual) corresponding restore is called,
    // but rather than remember this information in the LayerInfo
    // until the restore method is processed, we just mark the unbounded
    // state up front. Another reason to accumulate the clip here rather
    // than in restore is so that this savelayer will be tagged in the
    // rtree with its full bounds and the right op_index so that it doesn't
    // get culled during rendering.
    unbounded = true;
  }
  if (unbounded) {
    // Accumulate should always return true here because if the clip
    // was empty then that would have been caught up above when we
    // tested the PaintResult.
    [[maybe_unused]] bool unclipped = AccumulateUnbounded();
    FML_DCHECK(unclipped);
  }

  auto image_filter = paint ? paint->getImageFilter() : nullptr;

  bool layer_can_inherit_opacity = SetAttributesFromPaint(paint, flags);
  receiver_->saveLayer(bounds, options, backdrop);
  current_layer_->Update(result, layer_can_inherit_opacity);

  layer_stack_.emplace_back(true, image_filter);
  current_layer_ = &layer_stack_.back();

  if (image_filter != nullptr || !layer_can_inherit_opacity) {
    // The compatibility computed by SetAttributes does not take an
    // ImageFilter into account because an individual primitive with
    // an ImageFilter can apply opacity on top of it. But, if the layer
    // is applying the ImageFilter then it cannot pass the opacity on
    // to its children even if they are compatible.
    // Also, if a layer cannot itself inherit opacity then it cannot
    // pass it along to its children. Arguably this information is
    // not interesting because the saveLayer will have informed its
    // enclosing layers not to send it an opacity to apply in the
    // first place. But some tests check to see if the layer has
    // noticed this situation by testing the inheritance property on
    // the layer itself. Better tests wouldn't expect this property
    // to be recorded there, but we will mark our children incompatible
    // to be explicit about this situation.
    current_layer_->mark_incompatible();
  }

  if (image_filter != nullptr) {
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
    receiver_->resetCullRect(bounds);
  } else if (bounds != nullptr) {
    // Even though Skia claims that the bounds are only a hint, they actually
    // use them as the temporary layer bounds during rendering the layer, so
    // we set them as if a clip operation were performed.
    receiver_->intersectCullRect(*bounds);
  }
}

void DlCanvasToReceiver::Restore() {
  CheckAlive();
  if (layer_stack_.size() > 1) {
    // Grab the current layer info before we push the restore
    // on the stack.
    LayerInfo layer_info = layer_stack_.back();
    layer_stack_.pop_back();
    current_layer_ = &layer_stack_.back();

    if (layer_info.has_layer()) {
      bool can_distribute_opacity =
          layer_info.has_layer() && layer_info.is_group_opacity_compatible();
      receiver_->restoreLayer(layer_info.filter().get(),
                              layer_info.is_unbounded(),
                              can_distribute_opacity);
    } else {
      receiver_->restore();

      // For regular save() ops there was no protecting layer so we have to
      // accumulate the opacity compatibility values into the enclosing layer.
      if (layer_info.cannot_inherit_opacity()) {
        current_layer_->mark_incompatible();
      } else if (layer_info.has_compatible_op()) {
        current_layer_->add_compatible_op();
      }
    }
  }
}
void DlCanvasToReceiver::RestoreToCount(int restore_count) {
  CheckAlive();
  FML_DCHECK(restore_count <= GetSaveCount());
  while (restore_count < GetSaveCount() && GetSaveCount() > 1) {
    Restore();
  }
}

void DlCanvasToReceiver::Translate(SkScalar tx, SkScalar ty) {
  CheckAlive();
  if (SkScalarIsFinite(tx) && SkScalarIsFinite(ty) &&
      (tx != 0.0 || ty != 0.0)) {
    receiver_->translate(tx, ty);
    if (receiver_->is_nop()) {
      current_layer_->state_is_nop_ = true;
    }
  }
}
void DlCanvasToReceiver::Scale(SkScalar sx, SkScalar sy) {
  CheckAlive();
  if (SkScalarIsFinite(sx) && SkScalarIsFinite(sy) &&
      (sx != 1.0 || sy != 1.0)) {
    receiver_->scale(sx, sy);
    if (receiver_->is_nop()) {
      current_layer_->state_is_nop_ = true;
    }
  }
}
void DlCanvasToReceiver::Rotate(SkScalar degrees) {
  CheckAlive();
  if (SkScalarMod(degrees, 360.0) != 0.0) {
    receiver_->rotate(degrees);
    if (receiver_->is_nop()) {
      current_layer_->state_is_nop_ = true;
    }
  }
}
void DlCanvasToReceiver::Skew(SkScalar sx, SkScalar sy) {
  CheckAlive();
  if (SkScalarIsFinite(sx) && SkScalarIsFinite(sy) &&
      (sx != 0.0 || sy != 0.0)) {
    receiver_->skew(sx, sy);
    if (receiver_->is_nop()) {
      current_layer_->state_is_nop_ = true;
    }
  }
}

// clang-format off

// 2x3 2D affine subset of a 4x4 transform in row major order
void DlCanvasToReceiver::Transform2DAffine(
    SkScalar mxx, SkScalar mxy, SkScalar mxt,
    SkScalar myx, SkScalar myy, SkScalar myt) {
  CheckAlive();
  if (SkScalarsAreFinite(mxx, myx) &&
      SkScalarsAreFinite(mxy, myy) &&
      SkScalarsAreFinite(mxt, myt)) {
    if (mxx == 1 && mxy == 0 &&
        myx == 0 && myy == 1) {
      Translate(mxt, myt);
    } else {
      receiver_->transform2DAffine(mxx, mxy, mxt,
                                   myx, myy, myt);
      if (receiver_->is_nop()) {
        current_layer_->state_is_nop_ = true;
      }
    }
  }
}
// full 4x4 transform in row major order
void DlCanvasToReceiver::TransformFullPerspective(
    SkScalar mxx, SkScalar mxy, SkScalar mxz, SkScalar mxt,
    SkScalar myx, SkScalar myy, SkScalar myz, SkScalar myt,
    SkScalar mzx, SkScalar mzy, SkScalar mzz, SkScalar mzt,
    SkScalar mwx, SkScalar mwy, SkScalar mwz, SkScalar mwt) {
  CheckAlive();
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
    receiver_->transformFullPerspective(mxx, mxy, mxz, mxt,
                                        myx, myy, myz, myt,
                                        mzx, mzy, mzz, mzt,
                                        mwx, mwy, mwz, mwt);
    if (receiver_->is_nop()) {
      current_layer_->state_is_nop_ = true;
    }
  }
}
void DlCanvasToReceiver::TransformReset() {
  CheckAlive();
  receiver_->transformReset();
  if (receiver_->is_nop()) {
    current_layer_->state_is_nop_ = true;
  }
}
void DlCanvasToReceiver::Transform(const SkMatrix* matrix) {
  CheckAlive();
  if (matrix != nullptr) {
    if (matrix->hasPerspective()) {
      Transform2DAffine(
          matrix->getScaleX(), matrix->getSkewX(), matrix->getTranslateX(),
          matrix->getSkewY(), matrix->getScaleY(), matrix->getTranslateY());
    } else {
      TransformFullPerspective(
          matrix->rc(0, 0), matrix->rc(0, 1), 0.0f, matrix->rc(0, 2),
          matrix->rc(1, 0), matrix->rc(1, 1), 0.0f, matrix->rc(1, 2),
                  0.0f,             0.0f,     1.0f,         0.0f,
          matrix->rc(2, 0), matrix->rc(2, 1), 0.0f, matrix->rc(2, 2));
    }
  }
}
void DlCanvasToReceiver::Transform(const SkM44* m44) {
  CheckAlive();
  if (m44 != nullptr) {
    TransformFullPerspective(
        m44->rc(0, 0), m44->rc(0, 1), m44->rc(0, 2), m44->rc(0, 3),
        m44->rc(1, 0), m44->rc(1, 1), m44->rc(1, 2), m44->rc(1, 3),
        m44->rc(2, 0), m44->rc(2, 1), m44->rc(2, 2), m44->rc(2, 3),
        m44->rc(3, 0), m44->rc(3, 1), m44->rc(3, 2), m44->rc(3, 3));
  }
}
// clang-format on

void DlCanvasToReceiver::ClipRect(const SkRect& rect,
                                  ClipOp clip_op,
                                  bool is_aa) {
  CheckAlive();
  if (!rect.isFinite()) {
    return;
  }
  receiver_->clipRect(rect, clip_op, is_aa);
  if (receiver_->is_nop()) {
    current_layer_->state_is_nop_ = true;
  }
}
void DlCanvasToReceiver::ClipRRect(const SkRRect& rrect,
                                   ClipOp clip_op,
                                   bool is_aa) {
  CheckAlive();
  if (rrect.isRect()) {
    ClipRect(rrect.rect(), clip_op, is_aa);
  } else {
    receiver_->clipRRect(rrect, clip_op, is_aa);
    if (receiver_->is_nop()) {
      current_layer_->state_is_nop_ = true;
    }
  }
}
void DlCanvasToReceiver::ClipPath(const SkPath& path,
                                  ClipOp clip_op,
                                  bool is_aa) {
  CheckAlive();
  if (!path.isInverseFillType()) {
    SkRect rect;
    if (path.isRect(&rect)) {
      this->ClipRect(rect, clip_op, is_aa);
      return;
    }
    SkRRect rrect;
    if (path.isOval(&rect)) {
      rrect.setOval(rect);
      this->ClipRRect(rrect, clip_op, is_aa);
      return;
    }
    if (path.isRRect(&rrect)) {
      this->ClipRRect(rrect, clip_op, is_aa);
      return;
    }
  }
  receiver_->clipPath(path, clip_op, is_aa);
  if (receiver_->is_nop()) {
    current_layer_->state_is_nop_ = true;
  }
}

bool DlCanvasToReceiver::QuickReject(const SkRect& bounds) const {
  CheckAlive();
  return receiver_->content_culled(bounds);
}

void DlCanvasToReceiver::DrawPaint(const DlPaint& paint) {
  CheckAlive();
  OpResult result = PaintResult(paint, kDrawPaintFlags);
  if (result != OpResult::kNoEffect && AccumulateUnbounded()) {
    bool can_inherit_opacity = SetAttributesFromPaint(&paint, kDrawPaintFlags);
    receiver_->drawPaint();
    current_layer_->Update(result, can_inherit_opacity);
  }
}
void DlCanvasToReceiver::DrawColor(DlColor color, DlBlendMode mode) {
  CheckAlive();
  // We use DrawPaint flags here because the DrawColor flags indicate
  // that they will ignore the values in the paint that we are creating.
  // But we need the PaintResult to actually look at this paint object
  // so DrawPaint flags tell it to check all the required values.
  // Alternately, we could just call |DrawPaint(DlPaint(...));| which
  // is the equivalent call and the same thing would happen.
  OpResult result =
      PaintResult(DlPaint(color).setBlendMode(mode), kDrawPaintFlags);
  if (result != OpResult::kNoEffect && AccumulateUnbounded()) {
    receiver_->drawColor(color, mode);
    current_layer_->Update(result, IsOpacityCompatible(mode));
  }
}
void DlCanvasToReceiver::DrawLine(const SkPoint& p0,
                                  const SkPoint& p1,
                                  const DlPaint& paint) {
  CheckAlive();
  SkRect bounds = SkRect::MakeLTRB(p0.fX, p0.fY, p1.fX, p1.fY).makeSorted();
  DisplayListAttributeFlags flags =
      (bounds.width() > 0.0f && bounds.height() > 0.0f) ? kDrawLineFlags
                                                        : kDrawHVLineFlags;
  OpResult result = PaintResult(paint, flags);
  if (result != OpResult::kNoEffect &&
      AccumulateOpBounds(bounds, &paint, flags)) {
    bool can_inherit_opacity = SetAttributesFromPaint(&paint, flags);
    receiver_->drawLine(p0, p1);
    current_layer_->Update(result, can_inherit_opacity);
  }
}
void DlCanvasToReceiver::DrawRect(const SkRect& rect, const DlPaint& paint) {
  CheckAlive();
  DisplayListAttributeFlags flags = kDrawRectFlags;
  OpResult result = PaintResult(paint, flags);
  if (result != OpResult::kNoEffect &&
      AccumulateOpBounds(rect.makeSorted(), &paint, flags)) {
    bool can_inherit_opacity = SetAttributesFromPaint(&paint, flags);
    receiver_->drawRect(rect);
    current_layer_->Update(result, can_inherit_opacity);
  }
}
void DlCanvasToReceiver::DrawOval(const SkRect& bounds, const DlPaint& paint) {
  CheckAlive();
  DisplayListAttributeFlags flags = kDrawOvalFlags;
  OpResult result = PaintResult(paint, flags);
  if (result != OpResult::kNoEffect &&
      AccumulateOpBounds(bounds.makeSorted(), &paint, flags)) {
    bool can_inherit_opacity = SetAttributesFromPaint(&paint, flags);
    receiver_->drawOval(bounds);
    current_layer_->Update(result, can_inherit_opacity);
  }
}
void DlCanvasToReceiver::DrawCircle(const SkPoint& center,
                                    SkScalar radius,
                                    const DlPaint& paint) {
  CheckAlive();
  DisplayListAttributeFlags flags = kDrawCircleFlags;
  OpResult result = PaintResult(paint, flags);
  if (result != OpResult::kNoEffect) {
    SkRect bounds = SkRect::MakeLTRB(center.fX - radius, center.fY - radius,
                                     center.fX + radius, center.fY + radius);
    if (AccumulateOpBounds(bounds, &paint, flags)) {
      bool can_inherit_opacity = SetAttributesFromPaint(&paint, flags);
      receiver_->drawCircle(center, radius);
      current_layer_->Update(result, can_inherit_opacity);
    }
  }
}
void DlCanvasToReceiver::DrawRRect(const SkRRect& rrect, const DlPaint& paint) {
  CheckAlive();
  if (rrect.isRect()) {
    DrawRect(rrect.rect(), paint);
  } else if (rrect.isOval()) {
    DrawOval(rrect.rect(), paint);
  } else {
    DisplayListAttributeFlags flags = kDrawRRectFlags;
    OpResult result = PaintResult(paint, flags);
    if (result != OpResult::kNoEffect &&
        AccumulateOpBounds(rrect.getBounds(), &paint, flags)) {
      bool can_inherit_opacity = SetAttributesFromPaint(&paint, flags);
      receiver_->drawRRect(rrect);
      current_layer_->Update(result, can_inherit_opacity);
    }
  }
}
void DlCanvasToReceiver::DrawDRRect(const SkRRect& outer,
                                    const SkRRect& inner,
                                    const DlPaint& paint) {
  CheckAlive();
  DisplayListAttributeFlags flags = kDrawDRRectFlags;
  OpResult result = PaintResult(paint, flags);
  if (result != OpResult::kNoEffect &&
      AccumulateOpBounds(outer.getBounds(), &paint, flags)) {
    bool can_inherit_opacity = SetAttributesFromPaint(&paint, flags);
    receiver_->drawDRRect(outer, inner);
    current_layer_->Update(result, can_inherit_opacity);
  }
}
void DlCanvasToReceiver::DrawPath(const SkPath& path, const DlPaint& paint) {
  CheckAlive();
  DisplayListAttributeFlags flags = kDrawPathFlags;
  OpResult result = PaintResult(paint, flags);
  if (result != OpResult::kNoEffect) {
    bool is_visible = path.isInverseFillType()
                          ? AccumulateUnbounded()
                          : AccumulateOpBounds(path.getBounds(), &paint, flags);
    if (is_visible) {
      bool can_inherit_opacity = SetAttributesFromPaint(&paint, flags);
      receiver_->drawPath(path);
      current_layer_->Update(result, can_inherit_opacity);
    }
  }
}

void DlCanvasToReceiver::DrawArc(const SkRect& bounds,
                                 SkScalar start,
                                 SkScalar sweep,
                                 bool useCenter,
                                 const DlPaint& paint) {
  CheckAlive();
  DisplayListAttributeFlags flags =  //
      useCenter                      //
          ? kDrawArcWithCenterFlags
          : kDrawArcNoCenterFlags;
  OpResult result = PaintResult(paint, flags);
  // This could be tighter if we compute where the start and end
  // angles are and then also consider the quadrants swept and
  // the center if specified.
  if (result != OpResult::kNoEffect &&
      AccumulateOpBounds(bounds, &paint, flags)) {
    bool can_inherit_opacity = SetAttributesFromPaint(&paint, flags);
    receiver_->drawArc(bounds, start, sweep, useCenter);
    current_layer_->Update(result, can_inherit_opacity);
  }
}

DisplayListAttributeFlags DlCanvasToReceiver::FlagsForPointMode(
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
void DlCanvasToReceiver::DrawPoints(PointMode mode,
                                    uint32_t count,
                                    const SkPoint pts[],
                                    const DlPaint& paint) {
  CheckAlive();
  if (count == 0) {
    return;
  }
  DisplayListAttributeFlags flags = FlagsForPointMode(mode);
  OpResult result = PaintResult(paint, flags);
  if (result == OpResult::kNoEffect) {
    return;
  }

  FML_DCHECK(count < DlOpReceiver::kMaxDrawPointsCount);
  RectBoundsAccumulator ptBounds;
  for (size_t i = 0; i < count; i++) {
    ptBounds.accumulate(pts[i]);
  }
  SkRect point_bounds = ptBounds.bounds();
  if (!AccumulateOpBounds(point_bounds, &paint, flags)) {
    return;
  }

  (void)SetAttributesFromPaint(&paint, flags);
  receiver_->drawPoints(mode, count, pts);
  // drawPoints treats every point or line (or segment of a polygon)
  // as a completely separate operation meaning we cannot ensure
  // distribution of group opacity without analyzing the mode and the
  // bounds of every sub-primitive.
  // See: https://fiddle.skia.org/c/228459001d2de8db117ce25ef5cedb0c
  current_layer_->Update(result, false);
}
void DlCanvasToReceiver::DrawVertices(const DlVertices* vertices,
                                      DlBlendMode mode,
                                      const DlPaint& paint) {
  CheckAlive();
  DisplayListAttributeFlags flags = kDrawVerticesFlags;
  OpResult result = PaintResult(paint, flags);
  if (result != OpResult::kNoEffect &&
      AccumulateOpBounds(vertices->bounds(), &paint, flags)) {
    (void)SetAttributesFromPaint(&paint, flags);
    receiver_->drawVertices(vertices, mode);
    // DrawVertices applies its colors to the paint so we have no way
    // of controlling opacity using the current paint attributes.
    // Although, examination of the |mode| might find some predictable
    // cases.
    current_layer_->Update(result, false);
  }
}

void DlCanvasToReceiver::DrawImage(const sk_sp<DlImage>& image,
                                   const SkPoint point,
                                   DlImageSampling sampling,
                                   const DlPaint* paint) {
  CheckAlive();
  DisplayListAttributeFlags flags = paint ? kDrawImageWithPaintFlags  //
                                          : kDrawImageFlags;
  OpResult result = PaintResult(paint, flags);
  if (result == OpResult::kNoEffect) {
    return;
  }
  SkRect bounds = SkRect::MakeXYWH(point.fX, point.fY,  //
                                   image->width(), image->height());
  if (AccumulateOpBounds(bounds, paint, flags)) {
    bool can_inherit_opacity = SetAttributesFromPaint(paint, flags);
    receiver_->drawImage(image, point, sampling, paint != nullptr);
    current_layer_->Update(result, can_inherit_opacity);
  }
}
void DlCanvasToReceiver::DrawImageRect(const sk_sp<DlImage>& image,
                                       const SkRect& src,
                                       const SkRect& dst,
                                       DlImageSampling sampling,
                                       const DlPaint* paint,
                                       SrcRectConstraint constraint) {
  CheckAlive();
  DisplayListAttributeFlags flags = paint ? kDrawImageRectWithPaintFlags  //
                                          : kDrawImageRectFlags;
  OpResult result = PaintResult(paint, flags);
  if (result != OpResult::kNoEffect && AccumulateOpBounds(dst, paint, flags)) {
    bool can_inherit_opacity = SetAttributesFromPaint(paint, flags);
    receiver_->drawImageRect(image, src, dst, sampling, paint != nullptr,
                             constraint);
    current_layer_->Update(result, can_inherit_opacity);
  }
}
void DlCanvasToReceiver::DrawImageNine(const sk_sp<DlImage>& image,
                                       const SkIRect& center,
                                       const SkRect& dst,
                                       DlFilterMode filter,
                                       const DlPaint* paint) {
  CheckAlive();
  DisplayListAttributeFlags flags = paint ? kDrawImageNineWithPaintFlags  //
                                          : kDrawImageNineFlags;
  OpResult result = PaintResult(paint, flags);
  if (result != OpResult::kNoEffect && AccumulateOpBounds(dst, paint, flags)) {
    bool can_inherit_opacity = SetAttributesFromPaint(paint, flags);
    receiver_->drawImageNine(image, center, dst, filter, paint != nullptr);
    current_layer_->Update(result, can_inherit_opacity);
  }
}
void DlCanvasToReceiver::DrawAtlas(const sk_sp<DlImage>& atlas,
                                   const SkRSXform xform[],
                                   const SkRect tex[],
                                   const DlColor colors[],
                                   int count,
                                   DlBlendMode mode,
                                   DlImageSampling sampling,
                                   const SkRect* cull_rect,
                                   const DlPaint* paint) {
  CheckAlive();
  DisplayListAttributeFlags flags = paint ? kDrawAtlasWithPaintFlags  //
                                          : kDrawAtlasFlags;
  OpResult result = PaintResult(paint, flags);
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
      !AccumulateOpBounds(atlasBounds.bounds(), paint, flags)) {
    return;
  }

  (void)SetAttributesFromPaint(paint, flags);
  receiver_->drawAtlas(atlas, xform, tex, colors, count, mode, sampling,
                       cull_rect, paint != nullptr);
  // drawAtlas treats each image as a separate operation so we cannot rely
  // on it to distribute the opacity without overlap without checking all
  // of the transforms and texture rectangles.
  current_layer_->Update(result, false);
}

void DlCanvasToReceiver::DrawDisplayList(const sk_sp<DisplayList> display_list,
                                         SkScalar opacity) {
  CheckAlive();
  if (!SkScalarIsFinite(opacity) || opacity <= SK_ScalarNearlyZero ||
      display_list->op_count() == 0 || display_list->bounds().isEmpty() ||
      current_layer_->state_is_nop_) {
    return;
  }

  const SkRect bounds = display_list->bounds();
  bool accumulated;
  if (receiver_->wants_granular_bounds()) {
    auto rtree = display_list->rtree();
    if (rtree) {
      std::list<SkRect> rects = rtree->searchAndConsolidateRects(bounds, false);
      accumulated = false;
      for (const SkRect& rect : rects) {
        // TODO (https://github.com/flutter/flutter/issues/114919): Attributes
        // are not necessarily `kDrawDisplayListFlags`.
        if (AccumulateOpBounds(rect, nullptr, kDrawDisplayListFlags)) {
          accumulated = true;
        }
      }
    } else {
      accumulated = AccumulateOpBounds(bounds, nullptr, kDrawDisplayListFlags);
    }
  } else {
    accumulated = AccumulateOpBounds(bounds, nullptr, kDrawDisplayListFlags);
  }
  if (!accumulated) {
    return;
  }

  receiver_->drawDisplayList(display_list,
                             opacity < SK_Scalar1 ? opacity : SK_Scalar1);

  // The non-nested op count accumulated in the |Push| method will include
  // this call to |drawDisplayList| for non-nested op count metrics.
  // But, for nested op count metrics we want the |drawDisplayList| call itself
  // to be transparent. So we subtract 1 from our accumulated nested count to
  // balance out against the 1 that was accumulated into the regular count.
  // This behavior is identical to the way SkPicture computed nested op counts.
  // nested_op_count_ += display_list->op_count(true) - 1;
  // nested_bytes_ += display_list->bytes(true);
  current_layer_->Update(
      // Nop DisplayLists are eliminated above so we either affect transparent
      // pixels or we do not. We should not have [kNoEffect].
      display_list->modifies_transparent_black()
          ? OpResult::kAffectsAll
          : OpResult::kPreservesTransparency,
      display_list->can_apply_group_opacity());
}
void DlCanvasToReceiver::DrawImpellerPicture(
    const std::shared_ptr<const impeller::Picture>& picture,
    SkScalar opacity) {
  FML_LOG(ERROR) << "Cannot draw Impeller Picture in to a a display list.";
  FML_DCHECK(false);
}
void DlCanvasToReceiver::DrawTextBlob(const sk_sp<SkTextBlob>& blob,
                                      SkScalar x,
                                      SkScalar y,
                                      const DlPaint& paint) {
  CheckAlive();
  DisplayListAttributeFlags flags = kDrawTextBlobFlags;
  OpResult result = PaintResult(paint, flags);
  if (result == OpResult::kNoEffect) {
    return;
  }
  bool unclipped =
      AccumulateOpBounds(blob->bounds().makeOffset(x, y), &paint, flags);
  // TODO(https://github.com/flutter/flutter/issues/82202): Remove once the
  // unit tests can use Fuchsia's font manager instead of the empty default.
  // Until then we might encounter empty bounds for otherwise valid text and
  // thus we ignore the results from AccumulateOpBounds.
#if defined(OS_FUCHSIA)
  unclipped = true;
#endif  // OS_FUCHSIA
  if (unclipped) {
    (void)SetAttributesFromPaint(&paint, flags);
    receiver_->drawTextBlob(blob, x, y);
    // There is no way to query if the glyphs of a text blob overlap and
    // there are no current guarantees from either Skia or Impeller that
    // they will protect overlapping glyphs from the effects of overdraw
    // so we must make the conservative assessment that this DL layer is
    // not compatible with group opacity inheritance.
    current_layer_->Update(result, false);
  }
}
void DlCanvasToReceiver::DrawShadow(const SkPath& path,
                                    const DlColor color,
                                    const SkScalar elevation,
                                    bool transparent_occluder,
                                    SkScalar dpr) {
  CheckAlive();
  OpResult result = PaintResult(DlPaint(color));
  if (result != OpResult::kNoEffect) {
    SkRect shadow_bounds =
        DlCanvas::ComputeShadowBounds(path, elevation, dpr, GetTransform());
    if (AccumulateOpBounds(shadow_bounds, nullptr, kDrawShadowFlags)) {
      receiver_->drawShadow(path, color, elevation, transparent_occluder, dpr);
      current_layer_->Update(result, false);
    }
  }
}

bool DlCanvasToReceiver::ComputeFilteredBounds(SkRect& bounds,
                                               const DlImageFilter* filter) {
  if (filter) {
    if (!filter->map_local_bounds(bounds, bounds)) {
      return false;
    }
  }
  return true;
}

bool DlCanvasToReceiver::AdjustBoundsForPaint(SkRect& bounds,
                                              const DlPaint* in_paint,
                                              DisplayListAttributeFlags flags) {
  if (flags.ignores_paint()) {
    return true;
  }

  const DlPaint& paint = in_paint ? *in_paint : kDefaultPaint_;
  if (flags.is_geometric()) {
    bool is_stroked = flags.is_stroked(paint.getDrawStyle());

    // Path effect occurs before stroking...
    DisplayListSpecialGeometryFlags special_flags =
        flags.WithPathEffect(paint.getPathEffectPtr(), is_stroked);
    if (paint.getPathEffect()) {
      auto effect_bounds = paint.getPathEffect()->effect_bounds(bounds);
      if (!effect_bounds.has_value()) {
        return false;
      }
      bounds = effect_bounds.value();
    }

    if (is_stroked) {
      // Determine the max multiplier to the stroke width first.
      SkScalar pad = 1.0f;
      if (paint.getStrokeJoin() == DlStrokeJoin::kMiter &&
          special_flags.may_have_acute_joins()) {
        pad = std::max(pad, paint.getStrokeMiter());
      }
      if (paint.getStrokeCap() == DlStrokeCap::kSquare &&
          special_flags.may_have_diagonal_caps()) {
        pad = std::max(pad, SK_ScalarSqrt2);
      }
      SkScalar min_stroke_width = 0.01;
      pad *= std::max(paint.getStrokeWidth() * 0.5f, min_stroke_width);
      bounds.outset(pad, pad);
    }
  }

  if (flags.applies_mask_filter()) {
    auto filter = paint.getMaskFilter();
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
    return ComputeFilteredBounds(bounds, paint.getImageFilter().get());
  }

  return true;
}

bool DlCanvasToReceiver::AccumulateUnbounded() {
  return receiver_->accumulateUnboundedForNextOp();
}

bool DlCanvasToReceiver::AccumulateOpBounds(SkRect& bounds,
                                            const DlPaint* paint,
                                            DisplayListAttributeFlags flags) {
  if (AdjustBoundsForPaint(bounds, paint, flags)) {
    return AccumulateBounds(bounds);
  } else {
    return AccumulateUnbounded();
  }
}
bool DlCanvasToReceiver::AccumulateBounds(SkRect& bounds) {
  return receiver_->accumulateLocalBoundsForNextOp(bounds);
}

bool DlCanvasToReceiver::paint_nops_on_transparency(const DlPaint* paint) {
  if (paint == nullptr) {
    return true;
  }

  // SkImageFilter::canComputeFastBounds tests for transparency behavior
  // This test assumes that the blend mode checked down below will
  // NOP on transparent black.
  if (paint->getImageFilterPtr() &&
      paint->getImageFilterPtr()->modifies_transparent_black()) {
    return false;
  }

  // We filter the transparent black that is used for the background of a
  // saveLayer and make sure it returns transparent black. If it does, then
  // the color filter will leave all area surrounding the contents of the
  // save layer untouched out to the edge of the output surface.
  // This test assumes that the blend mode checked down below will
  // NOP on transparent black.
  if (paint->getColorFilterPtr() &&
      paint->getColorFilterPtr()->modifies_transparent_black()) {
    return false;
  }

  // Unusual blendmodes require us to process a saved layer
  // even with operations outside the clip.
  // For example, DstIn is used by masking layers.
  // https://code.google.com/p/skia/issues/detail?id=1291
  // https://crbug.com/401593
  switch (paint->getBlendMode()) {
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

DlColor DlCanvasToReceiver::GetEffectiveColor(const DlPaint& paint,
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

DlCanvasToReceiver::OpResult DlCanvasToReceiver::PaintResult(
    const DlPaint& paint,
    DisplayListAttributeFlags flags) {
  if (current_layer_->state_is_nop_) {
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

DlPaint DlCanvasToReceiver::kDefaultPaint_;

}  // namespace flutter
