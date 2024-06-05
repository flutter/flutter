// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/utils/dl_matrix_clip_tracker.h"

#include "flutter/display_list/dl_builder.h"
#include "flutter/fml/logging.h"

namespace flutter {

bool DisplayListMatrixClipState::is_3x3(const SkM44& m) {
  // clang-format off
  return (                                      m.rc(0, 2) == 0 &&
                                                m.rc(1, 2) == 0 &&
          m.rc(2, 0) == 0 && m.rc(2, 1) == 0 && m.rc(2, 2) == 1 && m.rc(2, 3) == 0 &&
                                                m.rc(3, 2) == 0);
  // clang-format on
}

static constexpr DlRect kEmpty = DlRect();

static const DlRect& ProtectEmpty(const SkRect& rect) {
  // isEmpty protects us against NaN while we normalize any empty cull rects
  return rect.isEmpty() ? kEmpty : ToDlRect(rect);
}

static const DlRect& ProtectEmpty(const DlRect& rect) {
  // isEmpty protects us against NaN while we normalize any empty cull rects
  return rect.IsEmpty() ? kEmpty : rect;
}

DisplayListMatrixClipState::DisplayListMatrixClipState(const DlRect& cull_rect,
                                                       const DlMatrix& matrix)
    : cull_rect_(ProtectEmpty(cull_rect)), matrix_(matrix) {}

DisplayListMatrixClipState::DisplayListMatrixClipState(const SkRect& cull_rect)
    : cull_rect_(ProtectEmpty(cull_rect)), matrix_(DlMatrix()) {}

DisplayListMatrixClipState::DisplayListMatrixClipState(const SkRect& cull_rect,
                                                       const SkMatrix& matrix)
    : cull_rect_(ProtectEmpty(cull_rect)), matrix_(ToDlMatrix(matrix)) {}

DisplayListMatrixClipState::DisplayListMatrixClipState(const SkRect& cull_rect,
                                                       const SkM44& matrix)
    : cull_rect_(ProtectEmpty(cull_rect)), matrix_(ToDlMatrix(matrix)) {}

bool DisplayListMatrixClipState::inverseTransform(
    const DisplayListMatrixClipState& tracker) {
  if (tracker.is_matrix_invertable()) {
    matrix_ = matrix_ * tracker.matrix_.Invert();
    return true;
  }
  return false;
}

bool DisplayListMatrixClipState::mapAndClipRect(const SkRect& src,
                                                SkRect* mapped) const {
  DlRect dl_mapped = ToDlRect(src).TransformAndClipBounds(matrix_);
  auto dl_intersected = dl_mapped.Intersection(cull_rect_);
  if (dl_intersected.has_value()) {
    *mapped = ToSkRect(dl_intersected.value());
    return true;
  }
  mapped->setEmpty();
  return false;
}

void DisplayListMatrixClipState::clipRect(const DlRect& rect,
                                          ClipOp op,
                                          bool is_aa) {
  adjustCullRect(rect, op, is_aa);
}

void DisplayListMatrixClipState::clipRRect(const SkRRect& rrect,
                                           ClipOp op,
                                           bool is_aa) {
  SkRect bounds = rrect.getBounds();
  switch (op) {
    case ClipOp::kIntersect:
      break;
    case ClipOp::kDifference:
      if (!rrect.isRect()) {
        return;
      }
      break;
  }
  adjustCullRect(ToDlRect(bounds), op, is_aa);
}

void DisplayListMatrixClipState::clipPath(const SkPath& path,
                                          ClipOp op,
                                          bool is_aa) {
  // Map "kDifference of inverse path" to "kIntersect of the original path" and
  // map "kIntersect of inverse path" to "kDifference of the original path"
  if (path.isInverseFillType()) {
    switch (op) {
      case ClipOp::kIntersect:
        op = ClipOp::kDifference;
        break;
      case ClipOp::kDifference:
        op = ClipOp::kIntersect;
        break;
    }
  }

  SkRect bounds;
  switch (op) {
    case ClipOp::kIntersect:
      bounds = path.getBounds();
      break;
    case ClipOp::kDifference:
      if (!path.isRect(&bounds)) {
        return;
      }
      break;
  }
  adjustCullRect(ToDlRect(bounds), op, is_aa);
}

bool DisplayListMatrixClipState::content_culled(
    const DlRect& content_bounds) const {
  if (cull_rect_.IsEmpty() || content_bounds.IsEmpty()) {
    return true;
  }
  if (!is_matrix_invertable()) {
    return true;
  }
  if (has_perspective()) {
    return false;
  }
  DlRect mapped;
  mapRect(content_bounds, &mapped);
  return !mapped.IntersectsWithRect(cull_rect_);
}

void DisplayListMatrixClipState::resetDeviceCullRect(const DlRect& cull_rect) {
  if (cull_rect.IsEmpty()) {
    cull_rect_ = DlRect();
  } else {
    cull_rect_ = cull_rect;
  }
}

void DisplayListMatrixClipState::resetLocalCullRect(const DlRect& cull_rect) {
  if (!cull_rect.IsEmpty()) {
    mapRect(cull_rect, &cull_rect_);
    if (!cull_rect_.IsEmpty()) {
      return;
    }
  }
  cull_rect_ = DlRect();
}

void DisplayListMatrixClipState::adjustCullRect(const DlRect& clip,
                                                ClipOp op,
                                                bool is_aa) {
  if (cull_rect_.IsEmpty()) {
    // No point in constraining further.
    return;
  }
  if (matrix_.HasPerspective()) {
    // We can conservatively ignore this clip.
    return;
  }
  switch (op) {
    case ClipOp::kIntersect: {
      if (clip.IsEmpty()) {
        cull_rect_ = DlRect();
        break;
      }
      DlRect rect;
      mapRect(clip, &rect);
      if (is_aa) {
        rect = DlRect::RoundOut(rect);
      }
      cull_rect_ = cull_rect_.Intersection(rect).value_or(DlRect());
      break;
    }
    case ClipOp::kDifference: {
      if (clip.IsEmpty()) {
        break;
      }
      DlRect rect;
      if (mapRect(clip, &rect)) {
        // This technique only works if the transform is rect -> rect
        if (is_aa) {
          rect = DlRect::Round(rect);
          if (rect.IsEmpty()) {
            break;
          }
        }
        cull_rect_ = cull_rect_.CutoutOrEmpty(rect);
      }
      break;
    }
  }
}

SkRect DisplayListMatrixClipState::local_cull_rect() const {
  if (cull_rect_.IsEmpty()) {
    return SkRect::MakeEmpty();
  }
  if (!is_matrix_invertable()) {
    return SkRect::MakeEmpty();
  }
  if (matrix_.HasPerspective2D()) {
    // We could do a 4-point long-form conversion, but since this is
    // only used for culling, let's just return a non-constricting
    // cull rect.
    return DisplayListBuilder::kMaxCullRect;
  }
  DlMatrix inverse = matrix_.Invert();
  // We eliminated perspective above so we can use the cheaper non-clipping
  // bounds transform method.
  return ToSkRect(cull_rect_.TransformBounds(inverse));
}

}  // namespace flutter
