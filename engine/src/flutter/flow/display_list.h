// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_DISPLAY_LIST_H_
#define FLUTTER_FLOW_DISPLAY_LIST_H_

#include "third_party/skia/include/core/SkBlender.h"
#include "third_party/skia/include/core/SkBlurTypes.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkImageFilter.h"
#include "third_party/skia/include/core/SkPathEffect.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkShader.h"
#include "third_party/skia/include/core/SkVertices.h"

// The Flutter DisplayList mechanism encapsulates a persistent sequence of
// rendering operations.
//
// This file contains the definitions for:
// DisplayList: the base class that holds the information about the
//              sequence of operations and can dispatch them to a Dispatcher
// Dispatcher: a pure virtual interface which can be implemented to field
//             the requests for purposes such as sending them to an SkCanvas
//             or detecting various rendering optimization scenarios
// DisplayListBuilder: a class for constructing a DisplayList from the same
//                     calls defined in the Dispatcher
//
// Other files include various class definitions for dealing with display
// lists, such as:
// display_list_canvas.h: classes to interact between SkCanvas and DisplayList
//                        (SkCanvas->DisplayList adapter and vice versa)
//
// display_list_utils.h: various utility classes to ease implementing
//                       a Dispatcher, including NOP implementations of
//                       the attribute, clip, and transform methods,
//                       classes to track attributes, clips, and transforms
//                       and a class to compute the bounds of a DisplayList
//                       Any class implementing Dispatcher can inherit from
//                       these utility classes to simplify its creation
//
// The Flutter DisplayList mechanism can be used in place of the Skia
// SkPicture mechanism. The primary means of communication into and out
// of the DisplayList is through the Dispatcher virtual class which
// provides a nearly 1:1 translation between the records of the DisplayList
// to method calls.
//
// A DisplayList can be created directly using a DisplayListBuilder and
// the Dispatcher methods that it implements, or it can be created from
// a sequence of SkCanvas calls using the DisplayListCanvasRecorder class.
//
// A DisplayList can be read back by implementing the Dispatcher virtual
// methods (with help from some of the classes in the utils file) and
// passing an instance to the dispatch() method, or it can be rendered
// to Skia using a DisplayListCanvasDispatcher or simply by passing an
// SkCanvas pointer to its renderTo() method.
//
// The mechanism is inspired by the SkLiteDL class that is not directly
// supported by Skia, but has been recommended as a basis for custom
// display lists for a number of their customers.

namespace flutter {

#define FOR_EACH_DISPLAY_LIST_OP(V) \
  V(SetAntiAlias)                   \
  V(SetDither)                      \
  V(SetInvertColors)                \
                                    \
  V(SetStrokeCap)                   \
  V(SetStrokeJoin)                  \
                                    \
  V(SetStyle)                       \
  V(SetStrokeWidth)                 \
  V(SetStrokeMiter)                 \
                                    \
  V(SetColor)                       \
  V(SetBlendMode)                   \
                                    \
  V(SetBlender)                     \
  V(ClearBlender)                   \
  V(SetShader)                      \
  V(ClearShader)                    \
  V(SetColorFilter)                 \
  V(ClearColorFilter)               \
  V(SetImageFilter)                 \
  V(ClearImageFilter)               \
  V(SetPathEffect)                  \
  V(ClearPathEffect)                \
                                    \
  V(ClearMaskFilter)                \
  V(SetMaskFilter)                  \
  V(SetMaskBlurFilterNormal)        \
  V(SetMaskBlurFilterSolid)         \
  V(SetMaskBlurFilterOuter)         \
  V(SetMaskBlurFilterInner)         \
                                    \
  V(Save)                           \
  V(SaveLayer)                      \
  V(SaveLayerBounds)                \
  V(Restore)                        \
                                    \
  V(Translate)                      \
  V(Scale)                          \
  V(Rotate)                         \
  V(Skew)                           \
  V(Transform2DAffine)              \
  V(TransformFullPerspective)       \
                                    \
  V(ClipIntersectRect)              \
  V(ClipIntersectRRect)             \
  V(ClipIntersectPath)              \
  V(ClipDifferenceRect)             \
  V(ClipDifferenceRRect)            \
  V(ClipDifferencePath)             \
                                    \
  V(DrawPaint)                      \
  V(DrawColor)                      \
                                    \
  V(DrawLine)                       \
  V(DrawRect)                       \
  V(DrawOval)                       \
  V(DrawCircle)                     \
  V(DrawRRect)                      \
  V(DrawDRRect)                     \
  V(DrawArc)                        \
  V(DrawPath)                       \
                                    \
  V(DrawPoints)                     \
  V(DrawLines)                      \
  V(DrawPolygon)                    \
  V(DrawVertices)                   \
                                    \
  V(DrawImage)                      \
  V(DrawImageWithAttr)              \
  V(DrawImageRect)                  \
  V(DrawImageNine)                  \
  V(DrawImageNineWithAttr)          \
  V(DrawImageLattice)               \
  V(DrawAtlas)                      \
  V(DrawAtlasCulled)                \
                                    \
  V(DrawSkPicture)                  \
  V(DrawSkPictureMatrix)            \
  V(DrawDisplayList)                \
  V(DrawTextBlob)                   \
                                    \
  V(DrawShadow)                     \
  V(DrawShadowTransparentOccluder)

#define DL_OP_TO_ENUM_VALUE(name) k##name,
enum class DisplayListOpType { FOR_EACH_DISPLAY_LIST_OP(DL_OP_TO_ENUM_VALUE) };
#undef DL_OP_TO_ENUM_VALUE

class Dispatcher;
class DisplayListBuilder;

// The base class that contains a sequence of rendering operations
// for dispatch to a Dispatcher. These objects must be instantiated
// through an instance of DisplayListBuilder::build().
class DisplayList : public SkRefCnt {
 public:
  static const SkSamplingOptions NearestSampling;
  static const SkSamplingOptions LinearSampling;
  static const SkSamplingOptions MipmapSampling;
  static const SkSamplingOptions CubicSampling;

  DisplayList()
      : byte_count_(0),
        op_count_(0),
        nested_byte_count_(0),
        nested_op_count_(0),
        unique_id_(0),
        bounds_({0, 0, 0, 0}),
        bounds_cull_({0, 0, 0, 0}) {}

  ~DisplayList();

  void Dispatch(Dispatcher& ctx) const {
    uint8_t* ptr = storage_.get();
    Dispatch(ctx, ptr, ptr + byte_count_);
  }

  void RenderTo(SkCanvas* canvas) const;

  // SkPicture always includes nested bytes, but nested ops are
  // only included if requested. The defaults used here for these
  // accessors follow that pattern.
  size_t bytes(bool nested = true) const {
    return sizeof(DisplayList) + byte_count_ +
           (nested ? nested_byte_count_ : 0);
  }
  int op_count(bool nested = false) const {
    return op_count_ + (nested ? nested_op_count_ : 0);
  }
  uint32_t unique_id() const { return unique_id_; }

  const SkRect& bounds() {
    if (bounds_.width() < 0.0) {
      // ComputeBounds() will leave the variable with a
      // non-negative width and height
      ComputeBounds();
    }
    return bounds_;
  }

  bool Equals(const DisplayList& other) const;

 private:
  DisplayList(uint8_t* ptr,
              size_t byte_count,
              int op_count,
              size_t nested_byte_count,
              int nested_op_count,
              const SkRect& cull_rect);

  std::unique_ptr<uint8_t, SkFunctionWrapper<void(void*), sk_free>> storage_;
  size_t byte_count_;
  int op_count_;

  size_t nested_byte_count_;
  int nested_op_count_;

  uint32_t unique_id_;
  SkRect bounds_;

  // Only used for drawPaint() and drawColor()
  SkRect bounds_cull_;

  void ComputeBounds();
  void Dispatch(Dispatcher& ctx, uint8_t* ptr, uint8_t* end) const;

  friend class DisplayListBuilder;
};

// The pure virtual interface for interacting with a display list.
// This interface represents the methods used to build a list
// through the DisplayListBuilder and also the methods that will
// be invoked through the DisplayList::dispatch() method.
class Dispatcher {
 public:
  // MaxDrawPointsCount * sizeof(SkPoint) must be less than 1 << 32
  static constexpr int kMaxDrawPointsCount = ((1 << 29) - 1);

  // The following methods are nearly 1:1 with the methods on SkPaint and
  // carry the same meanings. Each method sets a persistent value for the
  // attribute for the rest of the display list or until it is reset by
  // another method that changes the same attribute. The current set of
  // attributes is not affected by |save| and |restore|.
  virtual void setAntiAlias(bool aa) = 0;
  virtual void setDither(bool dither) = 0;
  virtual void setStyle(SkPaint::Style style) = 0;
  virtual void setColor(SkColor color) = 0;
  virtual void setStrokeWidth(SkScalar width) = 0;
  virtual void setStrokeMiter(SkScalar limit) = 0;
  virtual void setStrokeCap(SkPaint::Cap cap) = 0;
  virtual void setStrokeJoin(SkPaint::Join join) = 0;
  virtual void setShader(sk_sp<SkShader> shader) = 0;
  virtual void setColorFilter(sk_sp<SkColorFilter> filter) = 0;
  // setInvertColors does not exist in SkPaint, but is a quick way to set
  // a ColorFilter that inverts the rgb values of all rendered colors.
  // It is not reset by |setColorFilter|, but instead composed with that
  // filter so that the color inversion happens after the ColorFilter.
  virtual void setInvertColors(bool invert) = 0;
  virtual void setBlendMode(SkBlendMode mode) = 0;
  virtual void setBlender(sk_sp<SkBlender> blender) = 0;
  virtual void setPathEffect(sk_sp<SkPathEffect> effect) = 0;
  virtual void setMaskFilter(sk_sp<SkMaskFilter> filter) = 0;
  // setMaskBlurFilter is a quick way to set the parameters for a
  // mask blur filter without constructing an SkMaskFilter object.
  // It is equivalent to setMaskFilter(SkMaskFilter::MakeBlur(style, sigma)).
  // To reset the filter use setMaskFilter(nullptr).
  virtual void setMaskBlurFilter(SkBlurStyle style, SkScalar sigma) = 0;
  virtual void setImageFilter(sk_sp<SkImageFilter> filter) = 0;

  // All of the following methods are nearly 1:1 with their counterparts
  // in |SkCanvas| and have the same behavior and output.
  virtual void save() = 0;
  // The |restore_with_paint| parameter determines whether the existing
  // rendering attributes will be applied to the save layer surface while
  // rendering it back to the current surface. If the parameter is false
  // then this method is equivalent to |SkCanvas::saveLayer| with a null
  // paint object.
  virtual void saveLayer(const SkRect* bounds, bool restore_with_paint) = 0;
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

  virtual void clipRect(const SkRect& rect, SkClipOp clip_op, bool is_aa) = 0;
  virtual void clipRRect(const SkRRect& rrect,
                         SkClipOp clip_op,
                         bool is_aa) = 0;
  virtual void clipPath(const SkPath& path, SkClipOp clip_op, bool is_aa) = 0;

  // The following rendering methods all take their rendering attributes
  // from the last value set by the attribute methods above (regardless
  // of any |save| or |restore| operations which do not affect attributes).
  // In cases where a paint object may have been optional in the SkCanvas
  // method, the methods here will generally offer a boolean parameter
  // which specifies whether to honor the attributes of the display list
  // stream, or assume default attributes.
  virtual void drawColor(SkColor color, SkBlendMode mode) = 0;
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
  virtual void drawPoints(SkCanvas::PointMode mode,
                          uint32_t count,
                          const SkPoint points[]) = 0;
  virtual void drawVertices(const sk_sp<SkVertices> vertices,
                            SkBlendMode mode) = 0;
  virtual void drawImage(const sk_sp<SkImage> image,
                         const SkPoint point,
                         const SkSamplingOptions& sampling,
                         bool render_with_attributes) = 0;
  virtual void drawImageRect(const sk_sp<SkImage> image,
                             const SkRect& src,
                             const SkRect& dst,
                             const SkSamplingOptions& sampling,
                             bool render_with_attributes,
                             SkCanvas::SrcRectConstraint constraint) = 0;
  virtual void drawImageNine(const sk_sp<SkImage> image,
                             const SkIRect& center,
                             const SkRect& dst,
                             SkFilterMode filter,
                             bool render_with_attributes) = 0;
  virtual void drawImageLattice(const sk_sp<SkImage> image,
                                const SkCanvas::Lattice& lattice,
                                const SkRect& dst,
                                SkFilterMode filter,
                                bool render_with_attributes) = 0;
  virtual void drawAtlas(const sk_sp<SkImage> atlas,
                         const SkRSXform xform[],
                         const SkRect tex[],
                         const SkColor colors[],
                         int count,
                         SkBlendMode mode,
                         const SkSamplingOptions& sampling,
                         const SkRect* cull_rect,
                         bool render_with_attributes) = 0;
  virtual void drawPicture(const sk_sp<SkPicture> picture,
                           const SkMatrix* matrix,
                           bool render_with_attributes) = 0;
  virtual void drawDisplayList(const sk_sp<DisplayList> display_list) = 0;
  virtual void drawTextBlob(const sk_sp<SkTextBlob> blob,
                            SkScalar x,
                            SkScalar y) = 0;
  virtual void drawShadow(const SkPath& path,
                          const SkColor color,
                          const SkScalar elevation,
                          bool transparent_occluder,
                          SkScalar dpr) = 0;
};

// The primary class used to build a display list. The list of methods
// here matches the list of methods invoked on a |Dispatcher|.
// If there is some code that already renders to an SkCanvas object,
// those rendering commands can be captured into a DisplayList using
// the DisplayListCanvasRecorder class.
class DisplayListBuilder final : public virtual Dispatcher, public SkRefCnt {
 public:
  DisplayListBuilder(const SkRect& cull_rect = kMaxCullRect_);
  ~DisplayListBuilder();

  void setAntiAlias(bool aa) override;
  void setDither(bool dither) override;
  void setInvertColors(bool invert) override;
  void setStrokeCap(SkPaint::Cap cap) override;
  void setStrokeJoin(SkPaint::Join join) override;
  void setStyle(SkPaint::Style style) override;
  void setStrokeWidth(SkScalar width) override;
  void setStrokeMiter(SkScalar limit) override;
  void setColor(SkColor color) override;
  void setBlendMode(SkBlendMode mode) override;
  void setBlender(sk_sp<SkBlender> blender) override;
  void setShader(sk_sp<SkShader> shader) override;
  void setImageFilter(sk_sp<SkImageFilter> filter) override;
  void setColorFilter(sk_sp<SkColorFilter> filter) override;
  void setPathEffect(sk_sp<SkPathEffect> effect) override;
  void setMaskFilter(sk_sp<SkMaskFilter> filter) override;
  void setMaskBlurFilter(SkBlurStyle style, SkScalar sigma) override;

  void save() override;
  void saveLayer(const SkRect* bounds, bool restoreWithPaint) override;
  void restore() override;

  void translate(SkScalar tx, SkScalar ty) override;
  void scale(SkScalar sx, SkScalar sy) override;
  void rotate(SkScalar degrees) override;
  void skew(SkScalar sx, SkScalar sy) override;

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

  void clipRect(const SkRect& rect, SkClipOp clip_op, bool isAA) override;
  void clipRRect(const SkRRect& rrect, SkClipOp clip_op, bool isAA) override;
  void clipPath(const SkPath& path, SkClipOp clip_op, bool isAA) override;

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
  int save_level_ = 0;

  // bytes and ops from |drawPicture| and |drawDisplayList|
  size_t nested_bytes_ = 0;
  int nested_op_count_ = 0;

  SkRect cull_rect_;
  static constexpr SkRect kMaxCullRect_ =
      SkRect::MakeLTRB(-1E9F, -1E9F, 1E9F, 1E9F);

  template <typename T, typename... Args>
  void* Push(size_t extra, int op_inc, Args&&... args);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_DISPLAY_LIST_H_
