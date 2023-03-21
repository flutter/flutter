// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/utils/dl_matrix_clip_tracker.h"

#include "flutter/display_list/dl_builder.h"
#include "flutter/fml/logging.h"

namespace flutter {

class Data4x4 : public DisplayListMatrixClipTracker::Data {
 public:
  Data4x4(const SkM44& m44, const SkRect& rect) : Data(rect), m44_(m44) {}
  explicit Data4x4(const Data* copy)
      : Data(copy->device_cull_rect()), m44_(copy->matrix_4x4()) {}

  ~Data4x4() override = default;

  bool is_4x4() const override { return true; }

  SkMatrix matrix_3x3() const override { return m44_.asM33(); }
  SkM44 matrix_4x4() const override { return m44_; }
  SkRect local_cull_rect() const override;

  void translate(SkScalar tx, SkScalar ty) override {
    m44_.preTranslate(tx, ty);
  }
  void scale(SkScalar sx, SkScalar sy) override { m44_.preScale(sx, sy); }
  void skew(SkScalar skx, SkScalar sky) override {
    m44_.preConcat(SkMatrix::Skew(skx, sky));
  }
  void rotate(SkScalar degrees) override {
    m44_.preConcat(SkMatrix::RotateDeg(degrees));
  }
  void transform(const SkMatrix& matrix) override { m44_.preConcat(matrix); }
  void transform(const SkM44& m44) override { m44_.preConcat(m44); }
  void setTransform(const SkMatrix& matrix) override { m44_ = SkM44(matrix); }
  void setTransform(const SkM44& m44) override { m44_ = m44; }
  void setIdentity() override { m44_.setIdentity(); }
  bool mapRect(const SkRect& rect, SkRect* mapped) const override {
    return m44_.asM33().mapRect(mapped, rect);
  }
  bool canBeInverted() const override { return m44_.asM33().invert(nullptr); }

 protected:
  bool has_perspective() const override;

 private:
  SkM44 m44_;
};

class Data3x3 : public DisplayListMatrixClipTracker::Data {
 public:
  Data3x3(const SkMatrix& matrix, const SkRect& rect)
      : Data(rect), matrix_(matrix) {}
  explicit Data3x3(const Data* copy)
      : Data(copy->device_cull_rect()), matrix_(copy->matrix_3x3()) {}

  ~Data3x3() override = default;

  bool is_4x4() const override { return false; }

  SkMatrix matrix_3x3() const override { return matrix_; }
  SkM44 matrix_4x4() const override { return SkM44(matrix_); }
  SkRect local_cull_rect() const override;

  void translate(SkScalar tx, SkScalar ty) override {
    matrix_.preTranslate(tx, ty);
  }
  void scale(SkScalar sx, SkScalar sy) override { matrix_.preScale(sx, sy); }
  void skew(SkScalar skx, SkScalar sky) override { matrix_.preSkew(skx, sky); }
  void rotate(SkScalar degrees) override { matrix_.preRotate(degrees); }
  void transform(const SkMatrix& matrix) override { matrix_.preConcat(matrix); }
  void transform(const SkM44& m44) override {
    FML_CHECK(false) << "SkM44 was concatenated without upgrading Data";
  }
  void setTransform(const SkMatrix& matrix) override { matrix_ = matrix; }
  void setTransform(const SkM44& m44) override {
    FML_CHECK(false) << "SkM44 was set without upgrading Data";
  }
  void setIdentity() override { matrix_.setIdentity(); }
  bool mapRect(const SkRect& rect, SkRect* mapped) const override {
    return matrix_.mapRect(mapped, rect);
  }
  bool canBeInverted() const override { return matrix_.invert(nullptr); }

 protected:
  bool has_perspective() const override { return matrix_.hasPerspective(); }

 private:
  SkMatrix matrix_;
};

static bool is_3x3(const SkM44& m) {
  // clang-format off
  return (                                      m.rc(0, 2) == 0 &&
                                                m.rc(1, 2) == 0 &&
          m.rc(2, 0) == 0 && m.rc(2, 1) == 0 && m.rc(2, 2) == 1 && m.rc(2, 3) == 0 &&
                                                m.rc(3, 2) == 0);
  // clang-format on
}

DisplayListMatrixClipTracker::DisplayListMatrixClipTracker(
    const SkRect& cull_rect,
    const SkMatrix& matrix) {
  // isEmpty protects us against NaN as we normalize any empty cull rects
  SkRect cull = cull_rect.isEmpty() ? SkRect::MakeEmpty() : cull_rect;
  saved_.emplace_back(std::make_unique<Data3x3>(matrix, cull));
  current_ = saved_.back().get();
}

DisplayListMatrixClipTracker::DisplayListMatrixClipTracker(
    const SkRect& cull_rect,
    const SkM44& m44) {
  // isEmpty protects us against NaN as we normalize any empty cull rects
  SkRect cull = cull_rect.isEmpty() ? SkRect::MakeEmpty() : cull_rect;
  if (is_3x3(m44)) {
    saved_.emplace_back(std::make_unique<Data3x3>(m44.asM33(), cull));
  } else {
    saved_.emplace_back(std::make_unique<Data4x4>(m44, cull));
  }
  current_ = saved_.back().get();
}

// clang-format off
void DisplayListMatrixClipTracker::transform2DAffine(
    SkScalar mxx, SkScalar mxy, SkScalar mxt,
    SkScalar myx, SkScalar myy, SkScalar myt) {
  if (!current_->is_4x4()) {
    transform(SkMatrix::MakeAll(mxx, mxy, mxt,
                                myx, myy, myt,
                                0,   0,   1));
  } else {
    transform(SkM44(mxx, mxy, 0, mxt,
                    myx, myy, 0, myt,
                    0,   0,   1, 0,
                    0,   0,   0, 1));
  }
}
void DisplayListMatrixClipTracker::transformFullPerspective(
    SkScalar mxx, SkScalar mxy, SkScalar mxz, SkScalar mxt,
    SkScalar myx, SkScalar myy, SkScalar myz, SkScalar myt,
    SkScalar mzx, SkScalar mzy, SkScalar mzz, SkScalar mzt,
    SkScalar mwx, SkScalar mwy, SkScalar mwz, SkScalar mwt) {
  if (!current_->is_4x4()) {
    if (                        mxz == 0 &&
                                myz == 0 &&
        mzx == 0 && mzy == 0 && mzz == 1 && mzt == 0 &&
                                mwz == 0) {
        transform(SkMatrix::MakeAll(mxx, mxy, mxt,
                                    myx, myy, myt,
                                    mwx, mwy, mwt));
        return;
    }
  }

  transform(SkM44(mxx, mxy, mxz, mxt,
                  myx, myy, myz, myt,
                  mzx, mzy, mzz, mzt,
                  mwx, mwy, mwz, mwt));
}
// clang-format on

void DisplayListMatrixClipTracker::save() {
  if (current_->is_4x4()) {
    saved_.emplace_back(std::make_unique<Data4x4>(current_));
  } else {
    saved_.emplace_back(std::make_unique<Data3x3>(current_));
  }
  current_ = saved_.back().get();
}

void DisplayListMatrixClipTracker::restore() {
  saved_.pop_back();
  current_ = saved_.back().get();
}

void DisplayListMatrixClipTracker::restoreToCount(int restore_count) {
  FML_DCHECK(restore_count <= getSaveCount());
  if (restore_count < 1) {
    restore_count = 1;
  }
  while (restore_count < getSaveCount()) {
    restore();
  }
}

void DisplayListMatrixClipTracker::transform(const SkM44& m44) {
  if (!current_->is_4x4()) {
    if (is_3x3(m44)) {
      current_->transform(m44.asM33());
      return;
    }
    saved_.back() = std::make_unique<Data4x4>(current_);
    current_ = saved_.back().get();
  }
  current_->transform(m44);
}

void DisplayListMatrixClipTracker::setTransform(const SkM44& m44) {
  if (!current_->is_4x4()) {
    if (is_3x3(m44)) {
      current_->setTransform(m44.asM33());
      return;
    }
    saved_.back() = std::make_unique<Data4x4>(current_);
    current_ = saved_.back().get();
  }
  current_->setTransform(m44);
}

void DisplayListMatrixClipTracker::clipRRect(const SkRRect& rrect,
                                             ClipOp op,
                                             bool is_aa) {
  switch (op) {
    case ClipOp::kIntersect:
      break;
    case ClipOp::kDifference:
      if (!rrect.isRect()) {
        return;
      }
      break;
  }
  current_->clipBounds(rrect.getBounds(), op, is_aa);
}
void DisplayListMatrixClipTracker::clipPath(const SkPath& path,
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
  current_->clipBounds(bounds, op, is_aa);
}

bool DisplayListMatrixClipTracker::Data::content_culled(
    const SkRect& content_bounds) const {
  if (cull_rect_.isEmpty() || content_bounds.isEmpty()) {
    return true;
  }
  if (!canBeInverted()) {
    return true;
  }
  if (has_perspective()) {
    return false;
  }
  SkRect mapped;
  mapRect(content_bounds, &mapped);
  return !mapped.intersects(cull_rect_);
}

void DisplayListMatrixClipTracker::Data::clipBounds(const SkRect& clip,
                                                    ClipOp op,
                                                    bool is_aa) {
  if (cull_rect_.isEmpty()) {
    // No point in intersecting further.
    return;
  }
  if (has_perspective()) {
    // We can conservatively ignore this clip.
    return;
  }
  switch (op) {
    case ClipOp::kIntersect: {
      if (clip.isEmpty()) {
        cull_rect_.setEmpty();
        break;
      }
      SkRect rect;
      mapRect(clip, &rect);
      if (is_aa) {
        rect.roundOut(&rect);
      }
      if (!cull_rect_.intersect(rect)) {
        cull_rect_.setEmpty();
      }
      break;
    }
    case ClipOp::kDifference: {
      if (clip.isEmpty() || !clip.intersects(cull_rect_)) {
        break;
      }
      SkRect rect;
      if (mapRect(clip, &rect)) {
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
}

SkRect Data4x4::local_cull_rect() const {
  if (cull_rect_.isEmpty()) {
    return cull_rect_;
  }
  SkMatrix inverse;
  if (!m44_.asM33().invert(&inverse)) {
    return SkRect::MakeEmpty();
  }
  if (has_perspective()) {
    // We could do a 4-point long-form conversion, but since this is
    // only used for culling, let's just return a non-constricting
    // cull rect.
    return DisplayListBuilder::kMaxCullRect;
  }
  return inverse.mapRect(cull_rect_);
}

bool Data4x4::has_perspective() const {
  return (m44_.rc(3, 0) != 0 ||  //
          m44_.rc(3, 1) != 0 ||  //
          m44_.rc(3, 2) != 0 ||  //
          m44_.rc(3, 3) != 1);
}

SkRect Data3x3::local_cull_rect() const {
  if (cull_rect_.isEmpty()) {
    return cull_rect_;
  }
  SkMatrix inverse;
  if (!matrix_.invert(&inverse)) {
    return SkRect::MakeEmpty();
  }
  if (matrix_.hasPerspective()) {
    // We could do a 4-point long-form conversion, but since this is
    // only used for culling, let's just return a non-constricting
    // cull rect.
    return DisplayListBuilder::kMaxCullRect;
  }
  return inverse.mapRect(cull_rect_);
}

}  // namespace flutter
