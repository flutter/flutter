// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DISPLAY_LIST_DISPATCHER_H_
#define FLUTTER_DISPLAY_LIST_DISPLAY_LIST_DISPATCHER_H_

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/dl_blend_mode.h"
#include "flutter/display_list/dl_canvas.h"
#include "flutter/display_list/dl_paint.h"
#include "flutter/display_list/dl_sampling_options.h"
#include "flutter/display_list/dl_vertices.h"
#include "flutter/display_list/effects/dl_color_filter.h"
#include "flutter/display_list/effects/dl_color_source.h"
#include "flutter/display_list/effects/dl_image_filter.h"
#include "flutter/display_list/effects/dl_mask_filter.h"
#include "flutter/display_list/effects/dl_path_effect.h"
#include "flutter/display_list/image/dl_image.h"

namespace flutter {

class DisplayList;

//------------------------------------------------------------------------------
/// @brief      The pure virtual interface for interacting with a display list.
///             This interface represents the methods used to build a list
///             through the DisplayListBuilder and also the methods that will be
///             invoked through the DisplayList::dispatch() method.
///
class DlOpReceiver {
 protected:
  using ClipOp = DlCanvas::ClipOp;
  using PointMode = DlCanvas::PointMode;
  using SrcRectConstraint = DlCanvas::SrcRectConstraint;

 public:
  // MaxDrawPointsCount * sizeof(SkPoint) must be less than 1 << 32
  static constexpr int kMaxDrawPointsCount = ((1 << 29) - 1);

  // The following methods are nearly 1:1 with the methods on DlPaint and
  // carry the same meanings. Each method sets a persistent value for the
  // attribute for the rest of the display list or until it is reset by
  // another method that changes the same attribute. The current set of
  // attributes is not affected by |save| and |restore|.
  virtual void setAntiAlias(bool aa) = 0;
  virtual void setDither(bool dither) = 0;
  virtual void setDrawStyle(DlDrawStyle style) = 0;
  virtual void setColor(DlColor color) = 0;
  virtual void setStrokeWidth(float width) = 0;
  virtual void setStrokeMiter(float limit) = 0;
  virtual void setStrokeCap(DlStrokeCap cap) = 0;
  virtual void setStrokeJoin(DlStrokeJoin join) = 0;
  virtual void setColorSource(const DlColorSource* source) = 0;
  virtual void setColorFilter(const DlColorFilter* filter) = 0;
  // setInvertColors is a quick way to set a ColorFilter that inverts the
  // rgb values of all rendered colors.
  // It is not reset by |setColorFilter|, but instead composed with that
  // filter so that the color inversion happens after the ColorFilter.
  virtual void setInvertColors(bool invert) = 0;
  virtual void setBlendMode(DlBlendMode mode) = 0;
  virtual void setPathEffect(const DlPathEffect* effect) = 0;
  virtual void setMaskFilter(const DlMaskFilter* filter) = 0;
  virtual void setImageFilter(const DlImageFilter* filter) = 0;

  // All of the following methods are nearly 1:1 with their counterparts
  // in |SkCanvas| and have the same behavior and output.
  virtual void save() = 0;
  // The |options| parameter can specify whether the existing rendering
  // attributes will be applied to the save layer surface while rendering
  // it back to the current surface. If the flag is false then this method
  // is equivalent to |SkCanvas::saveLayer| with a null paint object.
  // The |options| parameter may contain other options that indicate some
  // specific optimizations may be made by the underlying implementation
  // to avoid creating a temporary layer, these optimization options will
  // be determined as the |DisplayList| is constructed and should not be
  // specified in calling a |DisplayListBuilder| as they will be ignored.
  // The |backdrop| filter, if not null, is used to initialize the new
  // layer before further rendering happens.
  virtual void saveLayer(const SkRect* bounds,
                         const SaveLayerOptions options,
                         const DlImageFilter* backdrop = nullptr) = 0;
  virtual void restore() = 0;

  virtual void translate(SkScalar tx, SkScalar ty) = 0;
  virtual void scale(SkScalar sx, SkScalar sy) = 0;
  virtual void rotate(SkScalar degrees) = 0;
  virtual void skew(SkScalar sx, SkScalar sy) = 0;

  // The transform methods all assume the following math for transforming
  // an arbitrary 3D homogenous point (x, y, z, w).
  // All coordinates in the rendering methods (and SkPoint and SkRect objects)
  // represent a simplified coordinate (x, y, 0, 1).
  //   x' = x * mxx + y * mxy + z * mxz + w * mxt
  //   y' = x * myx + y * myy + z * myz + w * myt
  //   z' = x * mzx + y * mzy + z * mzz + w * mzt
  //   w' = x * mwx + y * mwy + z * mwz + w * mwt
  // Note that for non-homogenous 2D coordinates, the last column in those
  // equations is multiplied by 1 and is simply adding a translation and
  // so is referred to with the final letter "t" here instead of "w".
  //
  // In 2D coordinates, z=0 and so the 3rd column always evaluates to 0.
  //
  // In non-perspective transforms, the 4th row has identity values
  // and so w` = w. (i.e. w'=1 for 2d points transformed by a matrix
  // with identity values in the last row).
  //
  // In affine 2D transforms, the 3rd and 4th row and 3rd column are all
  // identity values and so z` = z (which is 0 for 2D coordinates) and
  // the x` and y` equations don't see a contribution from a z coordinate
  // and the w' ends up being the same as the w from the source coordinate
  // (which is 1 for a 2D coordinate).
  //
  // Here is the math for transforming a 2D source coordinate and
  // looking for the destination 2D coordinate (for a surface that
  // does not have a Z buffer or track the Z coordinates in any way)
  //  Source coordinate = (x, y, 0, 1)
  //   x' = x * mxx + y * mxy + 0 * mxz + 1 * mxt
  //   y' = x * myx + y * myy + 0 * myz + 1 * myt
  //   z' = x * mzx + y * mzy + 0 * mzz + 1 * mzt
  //   w' = x * mwx + y * mwy + 0 * mwz + 1 * mwt
  //  Destination coordinate does not need z', so this reduces to:
  //   x' = x * mxx + y * mxy + mxt
  //   y' = x * myx + y * myy + myt
  //   w' = x * mwx + y * mwy + mwt
  //  Destination coordinate is (x' / w', y' / w', 0, 1)
  // Note that these are the matrix values in SkMatrix which means that
  // an SkMatrix contains enough data to transform a 2D source coordinate
  // and place it on a 2D surface, but is otherwise not enough to continue
  // concatenating with further matrices as its missing elements will not
  // be able to model the interplay between the rows and columns that
  // happens during a full 4x4 by 4x4 matrix multiplication.
  //
  // If the transform doesn't have any perspective parts (the last
  // row is identity - 0, 0, 0, 1), then this further simplifies to:
  //   x' = x * mxx + y * mxy + mxt
  //   y' = x * myx + y * myy + myt
  //   w' = x * 0 + y * 0 + 1         = 1
  //
  // In short, while the full 4x4 set of matrix entries needs to be
  // maintained for accumulating transform mutations accurately, the
  // actual end work of transforming a single 2D coordinate (or, in
  // the case of bounds transformations, 4 of them) can be accomplished
  // with the 9 values from transform3x3 or SkMatrix.
  //
  // The only need for the w value here is for homogenous coordinates
  // which only come up if the perspective elements (the 4th row) of
  // a transform are non-identity. Otherwise the w always ends up
  // being 1 in all calculations. If the matrix has perspecitve elements
  // then the final transformed coordinates will have a w that is not 1
  // and the actual coordinates are determined by dividing out that w
  // factor resulting in a real-world point expressed as (x, y, z, 1).
  //
  // Because of the predominance of 2D affine transforms the
  // 2x3 subset of the 4x4 transform matrix is special cased with
  // its own dispatch method that omits the last 2 rows and the 3rd
  // column. Even though a 3x3 subset is enough for transforming
  // leaf coordinates as shown above, no method is provided for
  // representing a 3x3 transform in the DisplayList since if there
  // is perspective involved then a full 4x4 matrix should be provided
  // for accurate concatenations. Providing a 3x3 method or record
  // in the stream would encourage developers to prematurely subset
  // a full perspective matrix.

  // clang-format off

  // |transform2DAffine| is equivalent to concatenating the internal
  // 4x4 transform with the following row major transform matrix:
  //   [ mxx  mxy   0   mxt ]
  //   [ myx  myy   0   myt ]
  //   [  0    0    1    0  ]
  //   [  0    0    0    1  ]
  virtual void transform2DAffine(SkScalar mxx, SkScalar mxy, SkScalar mxt,
                                 SkScalar myx, SkScalar myy, SkScalar myt) = 0;
  // |transformFullPerspective| is equivalent to concatenating the internal
  // 4x4 transform with the following row major transform matrix:
  //   [ mxx  mxy  mxz  mxt ]
  //   [ myx  myy  myz  myt ]
  //   [ mzx  mzy  mzz  mzt ]
  //   [ mwx  mwy  mwz  mwt ]
  virtual void transformFullPerspective(
      SkScalar mxx, SkScalar mxy, SkScalar mxz, SkScalar mxt,
      SkScalar myx, SkScalar myy, SkScalar myz, SkScalar myt,
      SkScalar mzx, SkScalar mzy, SkScalar mzz, SkScalar mzt,
      SkScalar mwx, SkScalar mwy, SkScalar mwz, SkScalar mwt) = 0;
  // clang-format on

  // Clears the transformation stack.
  virtual void transformReset() = 0;

  virtual void clipRect(const SkRect& rect, ClipOp clip_op, bool is_aa) = 0;
  virtual void clipRRect(const SkRRect& rrect, ClipOp clip_op, bool is_aa) = 0;
  virtual void clipPath(const SkPath& path, ClipOp clip_op, bool is_aa) = 0;

  // The following rendering methods all take their rendering attributes
  // from the last value set by the attribute methods above (regardless
  // of any |save| or |restore| operations which do not affect attributes).
  // In cases where a paint object may have been optional in the SkCanvas
  // method, the methods here will generally offer a boolean parameter
  // which specifies whether to honor the attributes of the display list
  // stream, or assume default attributes.
  virtual void drawColor(DlColor color, DlBlendMode mode) = 0;
  virtual void drawPaint() = 0;
  virtual void drawLine(const SkPoint& p0, const SkPoint& p1) = 0;
  virtual void drawRect(const SkRect& rect) = 0;
  virtual void drawOval(const SkRect& bounds) = 0;
  virtual void drawCircle(const SkPoint& center, SkScalar radius) = 0;
  virtual void drawRRect(const SkRRect& rrect) = 0;
  virtual void drawDRRect(const SkRRect& outer, const SkRRect& inner) = 0;
  virtual void drawPath(const SkPath& path) = 0;
  virtual void drawArc(const SkRect& oval_bounds,
                       SkScalar start_degrees,
                       SkScalar sweep_degrees,
                       bool use_center) = 0;
  virtual void drawPoints(PointMode mode,
                          uint32_t count,
                          const SkPoint points[]) = 0;
  virtual void drawVertices(const DlVertices* vertices, DlBlendMode mode) = 0;
  virtual void drawImage(const sk_sp<DlImage> image,
                         const SkPoint point,
                         DlImageSampling sampling,
                         bool render_with_attributes) = 0;
  virtual void drawImageRect(
      const sk_sp<DlImage> image,
      const SkRect& src,
      const SkRect& dst,
      DlImageSampling sampling,
      bool render_with_attributes,
      SrcRectConstraint constraint = SrcRectConstraint::kFast) = 0;
  virtual void drawImageNine(const sk_sp<DlImage> image,
                             const SkIRect& center,
                             const SkRect& dst,
                             DlFilterMode filter,
                             bool render_with_attributes) = 0;
  virtual void drawAtlas(const sk_sp<DlImage> atlas,
                         const SkRSXform xform[],
                         const SkRect tex[],
                         const DlColor colors[],
                         int count,
                         DlBlendMode mode,
                         DlImageSampling sampling,
                         const SkRect* cull_rect,
                         bool render_with_attributes) = 0;
  virtual void drawDisplayList(const sk_sp<DisplayList> display_list,
                               SkScalar opacity = SK_Scalar1) = 0;
  virtual void drawTextBlob(const sk_sp<SkTextBlob> blob,
                            SkScalar x,
                            SkScalar y) = 0;
  virtual void drawShadow(const SkPath& path,
                          const DlColor color,
                          const SkScalar elevation,
                          bool transparent_occluder,
                          SkScalar dpr) = 0;
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DISPLAY_LIST_DISPATCHER_H_
