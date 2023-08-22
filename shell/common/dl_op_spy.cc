// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/dl_op_spy.h"

namespace flutter {

bool DlOpSpy::did_draw() {
  return did_draw_;
}

void DlOpSpy::setColor(DlColor color) {
  if (color.isTransparent()) {
    will_draw_ = false;
  } else {
    will_draw_ = true;
  }
}
void DlOpSpy::setColorSource(const DlColorSource* source) {
  if (!source) {
    return;
  }
  const DlColorColorSource* color_source = source->asColor();
  if (color_source && color_source->color().isTransparent()) {
    will_draw_ = false;
    return;
  }
  will_draw_ = true;
}
void DlOpSpy::save() {}
void DlOpSpy::saveLayer(const SkRect* bounds,
                        const SaveLayerOptions options,
                        const DlImageFilter* backdrop) {}
void DlOpSpy::restore() {}
void DlOpSpy::drawColor(DlColor color, DlBlendMode mode) {
  did_draw_ |= !color.isTransparent();
}
void DlOpSpy::drawPaint() {
  did_draw_ |= will_draw_;
}
// TODO(cyanglaz): check whether the shape (line, rect, oval, etc) needs to be
// evaluated. https://github.com/flutter/flutter/issues/123803
void DlOpSpy::drawLine(const SkPoint& p0, const SkPoint& p1) {
  did_draw_ |= will_draw_;
}
void DlOpSpy::drawRect(const SkRect& rect) {
  did_draw_ |= will_draw_;
}
void DlOpSpy::drawOval(const SkRect& bounds) {
  did_draw_ |= will_draw_;
}
void DlOpSpy::drawCircle(const SkPoint& center, SkScalar radius) {
  did_draw_ |= will_draw_;
}
void DlOpSpy::drawRRect(const SkRRect& rrect) {
  did_draw_ |= will_draw_;
}
void DlOpSpy::drawDRRect(const SkRRect& outer, const SkRRect& inner) {
  did_draw_ |= will_draw_;
}
void DlOpSpy::drawPath(const SkPath& path) {
  did_draw_ |= will_draw_;
}
void DlOpSpy::drawArc(const SkRect& oval_bounds,
                      SkScalar start_degrees,
                      SkScalar sweep_degrees,
                      bool use_center) {
  did_draw_ |= will_draw_;
}
void DlOpSpy::drawPoints(PointMode mode,
                         uint32_t count,
                         const SkPoint points[]) {
  did_draw_ |= will_draw_;
}
void DlOpSpy::drawVertices(const DlVertices* vertices, DlBlendMode mode) {
  did_draw_ |= will_draw_;
}
// In theory, below drawImage methods can produce a transparent screen when a
// transparent image is provided. The operation of determine whether an image is
// transparent needs examine all the pixels in the image object, which is slow.
// Drawing a completely transparent image is not a valid use case, thus, such
// case is ignored.
void DlOpSpy::drawImage(const sk_sp<DlImage> image,
                        const SkPoint point,
                        DlImageSampling sampling,
                        bool render_with_attributes) {
  did_draw_ = true;
}
void DlOpSpy::drawImageRect(const sk_sp<DlImage> image,
                            const SkRect& src,
                            const SkRect& dst,
                            DlImageSampling sampling,
                            bool render_with_attributes,
                            SrcRectConstraint constraint) {
  did_draw_ = true;
}
void DlOpSpy::drawImageNine(const sk_sp<DlImage> image,
                            const SkIRect& center,
                            const SkRect& dst,
                            DlFilterMode filter,
                            bool render_with_attributes) {
  did_draw_ = true;
}
void DlOpSpy::drawAtlas(const sk_sp<DlImage> atlas,
                        const SkRSXform xform[],
                        const SkRect tex[],
                        const DlColor colors[],
                        int count,
                        DlBlendMode mode,
                        DlImageSampling sampling,
                        const SkRect* cull_rect,
                        bool render_with_attributes) {
  did_draw_ = true;
}
void DlOpSpy::drawDisplayList(const sk_sp<DisplayList> display_list,
                              SkScalar opacity) {
  if (did_draw_ || opacity == 0) {
    return;
  }
  DlOpSpy receiver;
  display_list->Dispatch(receiver);
  did_draw_ |= receiver.did_draw();
}
void DlOpSpy::drawTextBlob(const sk_sp<SkTextBlob> blob,
                           SkScalar x,
                           SkScalar y) {
  did_draw_ |= will_draw_;
}
void DlOpSpy::drawShadow(const SkPath& path,
                         const DlColor color,
                         const SkScalar elevation,
                         bool transparent_occluder,
                         SkScalar dpr) {
  did_draw_ |= !color.isTransparent();
}

}  // namespace flutter
