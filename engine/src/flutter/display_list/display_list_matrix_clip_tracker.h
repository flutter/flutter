// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DISPLAY_LIST_MATRIX_CLIP_TRACKER_H_
#define FLUTTER_DISPLAY_LIST_DISPLAY_LIST_MATRIX_CLIP_TRACKER_H_

#include <vector>

#include "flutter/fml/logging.h"
#include "third_party/skia/include/core/SkClipOp.h"
#include "third_party/skia/include/core/SkM44.h"
#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkRRect.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/core/SkScalar.h"

namespace flutter {

class DisplayListMatrixClipTracker {
 public:
  DisplayListMatrixClipTracker(const SkRect& cull_rect, const SkMatrix& matrix);
  DisplayListMatrixClipTracker(const SkRect& cull_rect, const SkM44& matrix);

  bool using_4x4_matrix() const { return current_->is_4x4(); }

  SkM44 matrix_4x4() const { return current_->matrix_4x4(); }
  SkMatrix matrix_3x3() const { return current_->matrix_3x3(); }
  SkRect local_cull_rect() const { return current_->local_cull_rect(); }
  SkRect device_cull_rect() const { return current_->device_cull_rect(); }
  bool content_culled(const SkRect& content_bounds) const {
    return current_->content_culled(content_bounds);
  }

  void save();
  void restore();
  int getSaveCount() { return saved_.size(); }
  void restoreToCount(int restore_count);

  void translate(SkScalar tx, SkScalar ty) { current_->translate(tx, ty); }
  void scale(SkScalar sx, SkScalar sy) { current_->scale(sx, sy); }
  void skew(SkScalar skx, SkScalar sky) { current_->skew(skx, sky); }
  void rotate(SkScalar degrees) { current_->rotate(degrees); }
  void transform(const SkM44& m44);
  void transform(const SkMatrix& matrix) { current_->transform(matrix); }
  // clang-format off
  void transform2DAffine(
      SkScalar mxx, SkScalar mxy, SkScalar mxt,
      SkScalar myx, SkScalar myy, SkScalar myt);
  void transformFullPerspective(
      SkScalar mxx, SkScalar mxy, SkScalar mxz, SkScalar mxt,
      SkScalar myx, SkScalar myy, SkScalar myz, SkScalar myt,
      SkScalar mzx, SkScalar mzy, SkScalar mzz, SkScalar mzt,
      SkScalar mwx, SkScalar mwy, SkScalar mwz, SkScalar mwt);
  // clang-format on
  void setTransform(const SkMatrix& matrix) { current_->setTransform(matrix); }
  void setTransform(const SkM44& m44);
  void setIdentity() { current_->setIdentity(); }
  bool mapRect(SkRect* rect) const { return current_->mapRect(*rect, rect); }

  void clipRect(const SkRect& rect, SkClipOp op, bool is_aa) {
    current_->clipBounds(rect, op, is_aa);
  }
  void clipRRect(const SkRRect& rrect, SkClipOp op, bool is_aa);
  void clipPath(const SkPath& path, SkClipOp op, bool is_aa);

 private:
  class Data {
   public:
    virtual ~Data() = default;

    virtual bool is_4x4() const = 0;

    virtual SkMatrix matrix_3x3() const = 0;
    virtual SkM44 matrix_4x4() const = 0;

    virtual SkRect device_cull_rect() const { return cull_rect_; }
    virtual SkRect local_cull_rect() const = 0;
    virtual bool content_culled(const SkRect& content_bounds) const;

    virtual void translate(SkScalar tx, SkScalar ty) = 0;
    virtual void scale(SkScalar sx, SkScalar sy) = 0;
    virtual void skew(SkScalar skx, SkScalar sky) = 0;
    virtual void rotate(SkScalar degrees) = 0;
    virtual void transform(const SkMatrix& matrix) = 0;
    virtual void transform(const SkM44& m44) = 0;
    virtual void setTransform(const SkMatrix& matrix) = 0;
    virtual void setTransform(const SkM44& m44) = 0;
    virtual void setIdentity() = 0;
    virtual bool mapRect(const SkRect& rect, SkRect* mapped) const = 0;
    virtual bool canBeInverted() const = 0;

    virtual void clipBounds(const SkRect& clip, SkClipOp op, bool is_aa);

   protected:
    Data(const SkRect& rect) : cull_rect_(rect) {}

    virtual bool has_perspective() const = 0;

    SkRect cull_rect_;
  };
  friend class Data3x3;
  friend class Data4x4;

  Data* current_;
  std::vector<std::unique_ptr<Data>> saved_;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DISPLAY_LIST_MATRIX_CLIP_TRACKER_H_
