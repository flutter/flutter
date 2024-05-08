// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_UTILS_DL_MATRIX_CLIP_TRACKER_H_
#define FLUTTER_DISPLAY_LIST_UTILS_DL_MATRIX_CLIP_TRACKER_H_

#include <vector>

#include "flutter/display_list/dl_canvas.h"
#include "flutter/display_list/geometry/dl_geometry_types.h"
#include "flutter/fml/logging.h"

#include "third_party/skia/include/core/SkM44.h"
#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkRRect.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/core/SkScalar.h"

namespace flutter {

class DisplayListMatrixClipState {
 private:
  using ClipOp = DlCanvas::ClipOp;

 public:
  explicit DisplayListMatrixClipState(const DlRect& cull_rect,
                                      const DlMatrix& matrix = DlMatrix());
  explicit DisplayListMatrixClipState(const SkRect& cull_rect);
  DisplayListMatrixClipState(const SkRect& cull_rect, const SkMatrix& matrix);
  DisplayListMatrixClipState(const SkRect& cull_rect, const SkM44& matrix);
  DisplayListMatrixClipState(const DisplayListMatrixClipState& other) = default;

  // This method should almost never be used as it breaks the encapsulation
  // of the enclosing clips. However it is needed for practical purposes in
  // some rare cases - such as when a saveLayer is collecting rendering
  // operations prior to applying a filter on the entire layer bounds and
  // some of those operations fall outside the enclosing clip, but their
  // filtered content will spread out from where they were rendered on the
  // layer into the enclosing clipped area.
  // Omitting the |cull_rect| argument, or passing nullptr, will restore the
  // cull rect to the initial value it had when the tracker was constructed.
  void resetDeviceCullRect(const DlRect& cull_rect);
  void resetDeviceCullRect(const SkRect& cull_rect) {
    resetDeviceCullRect(ToDlRect(cull_rect));
  }
  void resetLocalCullRect(const DlRect& cull_rect);
  void resetLocalCullRect(const SkRect& cull_rect) {
    resetLocalCullRect(ToDlRect(cull_rect));
  }

  bool using_4x4_matrix() const { return !matrix_.IsAffine(); }
  bool is_matrix_invertable() const { return matrix_.GetDeterminant() != 0.0f; }
  bool has_perspective() const { return matrix_.HasPerspective(); }

  const DlMatrix& matrix() const { return matrix_; }
  SkM44 matrix_4x4() const { return SkM44::ColMajor(matrix_.m); }
  SkMatrix matrix_3x3() const { return ToSkMatrix(matrix_); }

  SkRect local_cull_rect() const;
  SkRect device_cull_rect() const { return ToSkRect(cull_rect_); }

  bool content_culled(const DlRect& content_bounds) const;
  bool content_culled(const SkRect& content_bounds) const {
    return content_culled(ToDlRect(content_bounds));
  }
  bool is_cull_rect_empty() const { return cull_rect_.IsEmpty(); }

  void translate(SkScalar tx, SkScalar ty) {
    matrix_ = matrix_.Translate({tx, ty});
  }
  void scale(SkScalar sx, SkScalar sy) {
    matrix_ = matrix_.Scale({sx, sy, 1.0f});
  }
  void skew(SkScalar skx, SkScalar sky) {
    matrix_ = matrix_ * DlMatrix::MakeSkew(skx, sky);
  }
  void rotate(SkScalar degrees) {
    matrix_ = matrix_ * DlMatrix::MakeRotationZ(DlDegrees(degrees));
  }
  void transform(const DlMatrix& matrix) { matrix_ = matrix_ * matrix; }
  void transform(const SkM44& m44) { transform(ToDlMatrix(m44)); }
  void transform(const SkMatrix& matrix) { transform(ToDlMatrix(matrix)); }
  // clang-format off
  void transform2DAffine(
      SkScalar mxx, SkScalar mxy, SkScalar mxt,
      SkScalar myx, SkScalar myy, SkScalar myt) {
    matrix_ = matrix_ * DlMatrix::MakeColumn(
         mxx,  myx, 0.0f, 0.0f,
         mxy,  myy, 0.0f, 0.0f,
        0.0f, 0.0f, 1.0f, 0.0f,
         mxt,  myt, 0.0f, 1.0f
    );
  }
  void transformFullPerspective(
      SkScalar mxx, SkScalar mxy, SkScalar mxz, SkScalar mxt,
      SkScalar myx, SkScalar myy, SkScalar myz, SkScalar myt,
      SkScalar mzx, SkScalar mzy, SkScalar mzz, SkScalar mzt,
      SkScalar mwx, SkScalar mwy, SkScalar mwz, SkScalar mwt) {
    matrix_ = matrix_ * DlMatrix::MakeColumn(
        mxx, myx, mzx, mwx,
        mxy, myy, mzy, mwy,
        mxz, myz, mzz, mwz,
        mxt, myt, mzt, mwt
    );
  }
  // clang-format on
  void setTransform(const DlMatrix& matrix) { matrix_ = matrix; }
  void setTransform(const SkMatrix& matrix) { matrix_ = ToDlMatrix(matrix); }
  void setTransform(const SkM44& m44) { matrix_ = ToDlMatrix(m44); }
  void setIdentity() { matrix_ = DlMatrix(); }
  // If the matrix in |other_tracker| is invertible then transform this
  // tracker by the inverse of its matrix and return true. Otherwise,
  // return false and leave this tracker unmodified.
  bool inverseTransform(const DisplayListMatrixClipState& other_tracker);

  bool mapRect(DlRect* rect) const { return mapRect(*rect, rect); }
  bool mapRect(const DlRect& src, DlRect* mapped) const {
    *mapped = src.TransformAndClipBounds(matrix_);
    return matrix_.IsAligned2D();
  }
  bool mapRect(SkRect* rect) const { return mapRect(*rect, rect); }
  bool mapRect(const SkRect& src, SkRect* mapped) const {
    *mapped = ToSkRect(ToDlRect(src).TransformAndClipBounds(matrix_));
    return matrix_.IsAligned2D();
  }

  void clipRect(const DlRect& rect, ClipOp op, bool is_aa);
  void clipRect(const SkRect& rect, ClipOp op, bool is_aa) {
    clipRect(ToDlRect(rect), op, is_aa);
  }
  void clipRRect(const SkRRect& rrect, ClipOp op, bool is_aa);
  void clipPath(const SkPath& path, ClipOp op, bool is_aa);

 private:
  DlRect cull_rect_;
  DlMatrix matrix_;

  void adjustCullRect(const DlRect& clip, ClipOp op, bool is_aa);

  friend class DisplayListMatrixClipTracker;
};

class DisplayListMatrixClipTracker {
 private:
  using ClipOp = DlCanvas::ClipOp;
  using DlRect = impeller::Rect;
  using DlMatrix = impeller::Matrix;

 public:
  DisplayListMatrixClipTracker(const DlRect& cull_rect, const DlMatrix& matrix);
  DisplayListMatrixClipTracker(const SkRect& cull_rect, const SkMatrix& matrix);
  DisplayListMatrixClipTracker(const SkRect& cull_rect, const SkM44& matrix);

  // These methods should almost never be used as they breaks the encapsulation
  // of the enclosing clips. However they are needed for practical purposes in
  // some rare cases - such as when a saveLayer is collecting rendering
  // operations prior to applying a filter on the entire layer bounds and
  // some of those operations fall outside the enclosing clip, but their
  // filtered content will spread out from where they were rendered on the
  // layer into the enclosing clipped area.
  // Omitting the |cull_rect| argument, or passing nullptr, will restore the
  // cull rect to the initial value it had when the tracker was constructed.
  void resetDeviceCullRect(const DlRect* cull_rect = nullptr) {
    if (cull_rect) {
      current_->resetDeviceCullRect(*cull_rect);
    } else {
      current_->resetDeviceCullRect(saved_[0].cull_rect_);
    }
  }
  void resetDeviceCullRect(const SkRect* cull_rect = nullptr) {
    if (cull_rect) {
      current_->resetDeviceCullRect(*cull_rect);
    } else {
      current_->resetDeviceCullRect(saved_[0].cull_rect_);
    }
  }
  void resetLocalCullRect(const DlRect* cull_rect = nullptr) {
    if (cull_rect) {
      current_->resetLocalCullRect(*cull_rect);
    } else {
      current_->resetDeviceCullRect(saved_[0].cull_rect_);
    }
  }
  void resetLocalCullRect(const SkRect* cull_rect = nullptr) {
    if (cull_rect) {
      current_->resetLocalCullRect(*cull_rect);
    } else {
      current_->resetDeviceCullRect(saved_[0].cull_rect_);
    }
  }

  static bool is_3x3(const SkM44& m44);

  SkRect base_device_cull_rect() const { return saved_[0].device_cull_rect(); }

  bool using_4x4_matrix() const { return current_->using_4x4_matrix(); }

  DlMatrix matrix() const { return current_->matrix(); }
  SkM44 matrix_4x4() const { return current_->matrix_4x4(); }
  SkMatrix matrix_3x3() const { return current_->matrix_3x3(); }
  SkRect local_cull_rect() const { return current_->local_cull_rect(); }
  SkRect device_cull_rect() const { return current_->device_cull_rect(); }
  bool content_culled(const SkRect& content_bounds) const {
    return current_->content_culled(content_bounds);
  }
  bool is_cull_rect_empty() const { return current_->is_cull_rect_empty(); }

  void save();
  void restore();
  void reset();
  int getSaveCount() {
    // saved_[0] is always the untouched initial conditions
    // saved_[1] is the first editable stack entry
    return saved_.size() - 1;
  }
  void restoreToCount(int restore_count);

  void translate(SkScalar tx, SkScalar ty) { current_->translate(tx, ty); }
  void scale(SkScalar sx, SkScalar sy) { current_->scale(sx, sy); }
  void skew(SkScalar skx, SkScalar sky) { current_->skew(skx, sky); }
  void rotate(SkScalar degrees) { current_->rotate(degrees); }
  void transform(const DlMatrix& matrix) { current_->transform(matrix); }
  void transform(const SkM44& m44) { current_->transform(m44); }
  void transform(const SkMatrix& matrix) { current_->transform(matrix); }
  // clang-format off
  void transform2DAffine(
      SkScalar mxx, SkScalar mxy, SkScalar mxt,
      SkScalar myx, SkScalar myy, SkScalar myt) {
    current_->transform2DAffine(mxx, mxy, mxt, myx, myy, myt);
  }
  void transformFullPerspective(
      SkScalar mxx, SkScalar mxy, SkScalar mxz, SkScalar mxt,
      SkScalar myx, SkScalar myy, SkScalar myz, SkScalar myt,
      SkScalar mzx, SkScalar mzy, SkScalar mzz, SkScalar mzt,
      SkScalar mwx, SkScalar mwy, SkScalar mwz, SkScalar mwt) {
    current_->transformFullPerspective(
        mxx, mxy, mxz, mxt,
        myx, myy, myz, myt,
        mzx, mzy, mzz, mzt,
        mwx, mwy, mwz, mwt
    );
  }
  // clang-format on
  void setTransform(const DlMatrix& matrix) { current_->setTransform(matrix); }
  void setTransform(const SkMatrix& matrix) { current_->setTransform(matrix); }
  void setTransform(const SkM44& m44) { current_->setTransform(m44); }
  void setIdentity() { current_->setIdentity(); }
  // If the matrix in |other_tracker| is invertible then transform this
  // tracker by the inverse of its matrix and return true. Otherwise,
  // return false and leave this tracker unmodified.
  bool inverseTransform(const DisplayListMatrixClipTracker& other_tracker) {
    return current_->inverseTransform(*other_tracker.current_);
  }

  bool mapRect(DlRect* rect) const { return current_->mapRect(*rect, rect); }
  bool mapRect(const DlRect& src, DlRect* mapped) {
    return current_->mapRect(src, mapped);
  }
  bool mapRect(SkRect* rect) const { return current_->mapRect(*rect, rect); }
  bool mapRect(const SkRect& src, SkRect* mapped) {
    return current_->mapRect(src, mapped);
  }

  void clipRect(const DlRect& rect, ClipOp op, bool is_aa) {
    current_->clipRect(rect, op, is_aa);
  }
  void clipRect(const SkRect& rect, ClipOp op, bool is_aa) {
    current_->clipRect(rect, op, is_aa);
  }
  void clipRRect(const SkRRect& rrect, ClipOp op, bool is_aa) {
    current_->clipRRect(rrect, op, is_aa);
  }
  void clipPath(const SkPath& path, ClipOp op, bool is_aa) {
    current_->clipPath(path, op, is_aa);
  }

 private:
  DisplayListMatrixClipState* current_;
  std::vector<DisplayListMatrixClipState> saved_;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_UTILS_DL_MATRIX_CLIP_TRACKER_H_
