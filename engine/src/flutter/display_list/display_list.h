// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_DISPLAY_LIST_H_
#define FLUTTER_FLOW_DISPLAY_LIST_H_

#include <optional>

#include "flutter/fml/logging.h"
#include "third_party/skia/include/core/SkBlender.h"
#include "third_party/skia/include/core/SkBlurTypes.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/core/SkImageFilter.h"
#include "third_party/skia/include/core/SkMaskFilter.h"
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

  DisplayList();
  ~DisplayList();

  void Dispatch(Dispatcher& ctx) const {
    uint8_t* ptr = storage_.get();
    Dispatch(ctx, ptr, ptr + byte_count_);
  }

  void RenderTo(SkCanvas* canvas, SkScalar opacity = SK_Scalar1) const;

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

  bool can_apply_group_opacity() { return can_apply_group_opacity_; }

 private:
  DisplayList(uint8_t* ptr,
              size_t byte_count,
              int op_count,
              size_t nested_byte_count,
              int nested_op_count,
              const SkRect& cull_rect,
              bool can_apply_group_opacity);

  std::unique_ptr<uint8_t, SkFunctionWrapper<void(void*), sk_free>> storage_;
  size_t byte_count_;
  int op_count_;

  size_t nested_byte_count_;
  int nested_op_count_;

  uint32_t unique_id_;
  SkRect bounds_;

  // Only used for drawPaint() and drawColor()
  SkRect bounds_cull_;

  bool can_apply_group_opacity_;

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

/// The base class for the classes that maintain a list of
/// attributes that might be important for a number of operations
/// including which rendering attributes need to be set before
/// calling a rendering method (all |drawSomething| calls),
/// or for determining which exceptional conditions may need
/// to be accounted for in bounds calculations.
/// This class contains only protected definitions and helper methods
/// for the public classes |DisplayListAttributeFlags| and
/// |DisplayListSpecialGeometryFlags|.
class DisplayListFlags {
 protected:
  // A drawing operation that is not geometric in nature (but which
  // may still apply a MaskFilter - see |kUsesMaskFilter_| below).
  static constexpr int kIsNonGeometric_ = 0;

  // A geometric operation that is defined as a fill operation
  // regardless of what the current paint Style is set to.
  // This flag will automatically assume |kUsesMaskFilter_|.
  static constexpr int kIsFilledGeometry_ = 1 << 0;

  // A geometric operation that is defined as a stroke operation
  // regardless of what the current paint Style is set to.
  // This flag will automatically assume |kUsesMaskFilter_|.
  static constexpr int kIsStrokedGeometry_ = 1 << 1;

  // A geometric operation that may be a stroke or fill operation
  // depending on the current state of the paint Style attribute.
  // This flag will automatically assume |kUsesMaskFilter_|.
  static constexpr int kIsDrawnGeometry_ = 1 << 2;

  static constexpr int kIsAnyGeometryMask_ =  //
      kIsFilledGeometry_ |                    //
      kIsStrokedGeometry_ |                   //
      kIsDrawnGeometry_;

  // A primitive that floods the surface (or clip) with no
  // natural bounds, such as |drawColor| or |drawPaint|.
  static constexpr int kFloodsSurface_ = 1 << 3;

  static constexpr int kMayHaveCaps_ = 1 << 4;
  static constexpr int kMayHaveJoins_ = 1 << 5;
  static constexpr int kButtCapIsSquare_ = 1 << 6;

  // A geometric operation which has a path that might have
  // end caps that are not rectilinear which means that square
  // end caps might project further than half the stroke width
  // from the geometry bounds.
  // A rectilinear path such as |drawRect| will not have
  // diagonal end caps. |drawLine| might have diagonal end
  // caps depending on the angle of the line, and more likely
  // |drawPath| will often have such end caps.
  static constexpr int kMayHaveDiagonalCaps_ = 1 << 7;

  // A geometric operation which has joined vertices that are
  // not guaranteed to be smooth (angles of incoming and outgoing)
  // segments at some joins may not have the same angle) or
  // rectilinear (squares have right angles at the corners, but
  // those corners will never extend past the bounding box of
  // the geometry pre-transform).
  // |drawRect|, |drawOval| and |drawRRect| all have well
  // behaved joins, but |drawPath| might have joins that cause
  // mitered extensions outside the pre-transformed bounding box.
  static constexpr int kMayHaveAcuteJoins_ = 1 << 8;

  static constexpr int kAnySpecialGeometryMask_ =           //
      kMayHaveCaps_ | kMayHaveJoins_ | kButtCapIsSquare_ |  //
      kMayHaveDiagonalCaps_ | kMayHaveAcuteJoins_;

  // clang-format off
  static constexpr int kUsesAntiAlias_       = 1 << 10;
  static constexpr int kUsesDither_          = 1 << 11;
  static constexpr int kUsesAlpha_           = 1 << 12;
  static constexpr int kUsesColor_           = 1 << 13;
  static constexpr int kUsesBlend_           = 1 << 14;
  static constexpr int kUsesShader_          = 1 << 15;
  static constexpr int kUsesColorFilter_     = 1 << 16;
  static constexpr int kUsesPathEffect_      = 1 << 17;
  static constexpr int kUsesMaskFilter_      = 1 << 18;
  static constexpr int kUsesImageFilter_     = 1 << 19;

  // Some ops have an optional paint argument. If the version
  // stored in the DisplayList ignores the paint, but there
  // is an option to render the same op with a paint then
  // both of the following flags are set to indicate that
  // a default paint object can be constructed when rendering
  // the op to carry information imposed from outside the
  // DisplayList (for example, the opacity override).
  static constexpr int kIgnoresPaint_        = 1 << 30;
  // clang-format on

  static constexpr int kAnyAttributeMask_ =  //
      kUsesAntiAlias_ | kUsesDither_ | kUsesAlpha_ | kUsesColor_ | kUsesBlend_ |
      kUsesShader_ | kUsesColorFilter_ | kUsesPathEffect_ | kUsesMaskFilter_ |
      kUsesImageFilter_;
};

class DisplayListFlagsBase : protected DisplayListFlags {
 protected:
  explicit DisplayListFlagsBase(int flags) : flags_(flags) {}

  const int flags_;

  bool has_any(int qFlags) const { return (flags_ & qFlags) != 0; }
  bool has_all(int qFlags) const { return (flags_ & qFlags) == qFlags; }
  bool has_none(int qFlags) const { return (flags_ & qFlags) == 0; }
};

/// An attribute class for advertising specific properties of
/// a geometric attribute that can affect the computation of
/// the bounds of the primitive.
class DisplayListSpecialGeometryFlags : DisplayListFlagsBase {
 public:
  /// The geometry may have segments that end without closing the path.
  bool may_have_end_caps() const { return has_any(kMayHaveCaps_); }

  /// The geometry may have segments connect non-continuously.
  bool may_have_joins() const { return has_any(kMayHaveJoins_); }

  /// Mainly for drawPoints(PointMode) where Butt caps are rendered as squares.
  bool butt_cap_becomes_square() const { return has_any(kButtCapIsSquare_); }

  /// The geometry may have segments that end on a diagonal
  /// such that their end caps extend further than the default
  /// |strokeWidth * 0.5| margin around the geometry.
  bool may_have_diagonal_caps() const { return has_any(kMayHaveDiagonalCaps_); }

  /// The geometry may have segments that meet at vertices at
  /// an acute angle such that the miter joins will extend
  /// further than the default |strokeWidth * 0.5| margin around
  /// the geometry.
  bool may_have_acute_joins() const { return has_any(kMayHaveAcuteJoins_); }

 private:
  explicit DisplayListSpecialGeometryFlags(int flags)
      : DisplayListFlagsBase(flags) {
    FML_DCHECK((flags & kAnySpecialGeometryMask_) == flags);
  }

  const DisplayListSpecialGeometryFlags with(int extra) const {
    return extra == 0 ? *this : DisplayListSpecialGeometryFlags(flags_ | extra);
  }

  friend class DisplayListAttributeFlags;
};

class DisplayListAttributeFlags : DisplayListFlagsBase {
 public:
  const DisplayListSpecialGeometryFlags WithPathEffect(
      sk_sp<SkPathEffect> effect) const {
    if (is_geometric() && effect) {
      SkPathEffect::DashInfo info;
      if (effect->asADash(&info) == SkPathEffect::kDash_DashType) {
        // A dash effect has a very simple impact. It cannot introduce any
        // miter joins that weren't already present in the original path
        // and it does not grow the bounds of the path, but it can add
        // end caps to areas that might not have had them before so all
        // we need to do is to indicate the potential for diagonal
        // end caps and move on.
        return special_flags_.with(kMayHaveCaps_ | kMayHaveDiagonalCaps_);
      } else {
        // An arbitrary path effect can introduce joins at an arbitrary
        // angle and may change the geometry of the end caps
        return special_flags_.with(kMayHaveCaps_ | kMayHaveDiagonalCaps_ |
                                   kMayHaveJoins_ | kMayHaveAcuteJoins_);
      }
    }
    return special_flags_;
  }

  bool ignores_paint() const { return has_any(kIgnoresPaint_); }

  bool applies_anti_alias() const { return has_any(kUsesAntiAlias_); }
  bool applies_dither() const { return has_any(kUsesDither_); }
  bool applies_color() const { return has_any(kUsesColor_); }
  bool applies_alpha() const { return has_any(kUsesAlpha_); }
  bool applies_alpha_or_color() const {
    return has_any(kUsesAlpha_ | kUsesColor_);
  }

  /// The primitive dynamically determines whether it is a stroke or fill
  /// operation (or both) based on the setting of the |Style| attribute.
  bool applies_style() const { return has_any(kIsDrawnGeometry_); }
  /// The primitive can use any of the stroke attributes, such as
  /// StrokeWidth, StrokeMiter, StrokeCap, or StrokeJoin. This
  /// method will return if the primitive is defined as one that
  /// strokes its geometry (such as |drawLine|) or if it is defined
  /// as one that honors the Style attribute. If the Style attribute
  /// is known then a more accurate answer can be returned from
  /// the |is_stroked| method by supplying the actual setting of
  /// the style.
  // bool applies_stroke_attributes() const { return is_stroked(); }

  bool applies_shader() const { return has_any(kUsesShader_); }
  /// The primitive honors the current SkColorFilter, including
  /// the related attribute InvertColors
  bool applies_color_filter() const { return has_any(kUsesColorFilter_); }
  /// The primitive honors the SkBlendMode or SkBlender
  bool applies_blend() const { return has_any(kUsesBlend_); }
  bool applies_path_effect() const { return has_any(kUsesPathEffect_); }
  /// The primitive honors the SkMaskFilter whether set using the
  /// filter object or using the convenience method |setMaskBlurFilter|
  bool applies_mask_filter() const { return has_any(kUsesMaskFilter_); }
  bool applies_image_filter() const { return has_any(kUsesImageFilter_); }

  bool is_geometric() const { return has_any(kIsAnyGeometryMask_); }
  bool always_stroked() const { return has_any(kIsStrokedGeometry_); }
  bool is_stroked(SkPaint::Style style = SkPaint::Style::kStroke_Style) const {
    return (
        has_any(kIsStrokedGeometry_) ||
        (style != SkPaint::Style::kFill_Style && has_any(kIsDrawnGeometry_)));
  }

  bool is_flood() const { return has_any(kFloodsSurface_); }

 private:
  explicit DisplayListAttributeFlags(int flags)
      : DisplayListFlagsBase(flags),
        special_flags_(flags & kAnySpecialGeometryMask_) {
    FML_DCHECK((flags & kIsAnyGeometryMask_) == kIsNonGeometric_ ||
               (flags & kIsAnyGeometryMask_) == kIsFilledGeometry_ ||
               (flags & kIsAnyGeometryMask_) == kIsStrokedGeometry_ ||
               (flags & kIsAnyGeometryMask_) == kIsDrawnGeometry_);
    FML_DCHECK(((flags & kAnyAttributeMask_) == 0) !=
               ((flags & kIgnoresPaint_) == 0));
    FML_DCHECK((flags & kIsAnyGeometryMask_) != 0 ||
               (flags & kAnySpecialGeometryMask_) == 0);
  }

  const DisplayListAttributeFlags with(int extra) const {
    return extra == 0 ? *this : DisplayListAttributeFlags(flags_ | extra);
  }

  const DisplayListAttributeFlags without(int remove) const {
    FML_DCHECK(has_all(remove));
    return DisplayListAttributeFlags(flags_ & ~remove);
  }

  const DisplayListSpecialGeometryFlags special_flags_;

  friend class DisplayListOpFlags;
};

class DisplayListOpFlags : DisplayListFlags {
 public:
  static const DisplayListAttributeFlags kSaveLayerFlags;
  static const DisplayListAttributeFlags kSaveLayerWithPaintFlags;
  static const DisplayListAttributeFlags kDrawColorFlags;
  static const DisplayListAttributeFlags kDrawPaintFlags;
  static const DisplayListAttributeFlags kDrawLineFlags;
  // Special case flags for horizonal and vertical lines
  static const DisplayListAttributeFlags kDrawHVLineFlags;
  static const DisplayListAttributeFlags kDrawRectFlags;
  static const DisplayListAttributeFlags kDrawOvalFlags;
  static const DisplayListAttributeFlags kDrawCircleFlags;
  static const DisplayListAttributeFlags kDrawRRectFlags;
  static const DisplayListAttributeFlags kDrawDRRectFlags;
  static const DisplayListAttributeFlags kDrawPathFlags;
  static const DisplayListAttributeFlags kDrawArcNoCenterFlags;
  static const DisplayListAttributeFlags kDrawArcWithCenterFlags;
  static const DisplayListAttributeFlags kDrawPointsAsPointsFlags;
  static const DisplayListAttributeFlags kDrawPointsAsLinesFlags;
  static const DisplayListAttributeFlags kDrawPointsAsPolygonFlags;
  static const DisplayListAttributeFlags kDrawVerticesFlags;
  static const DisplayListAttributeFlags kDrawImageFlags;
  static const DisplayListAttributeFlags kDrawImageWithPaintFlags;
  static const DisplayListAttributeFlags kDrawImageRectFlags;
  static const DisplayListAttributeFlags kDrawImageRectWithPaintFlags;
  static const DisplayListAttributeFlags kDrawImageNineFlags;
  static const DisplayListAttributeFlags kDrawImageNineWithPaintFlags;
  static const DisplayListAttributeFlags kDrawImageLatticeFlags;
  static const DisplayListAttributeFlags kDrawImageLatticeWithPaintFlags;
  static const DisplayListAttributeFlags kDrawAtlasFlags;
  static const DisplayListAttributeFlags kDrawAtlasWithPaintFlags;
  static const DisplayListAttributeFlags kDrawPictureFlags;
  static const DisplayListAttributeFlags kDrawPictureWithPaintFlags;
  static const DisplayListAttributeFlags kDrawDisplayListFlags;
  static const DisplayListAttributeFlags kDrawTextBlobFlags;
  static const DisplayListAttributeFlags kDrawShadowFlags;
};

// The primary class used to build a display list. The list of methods
// here matches the list of methods invoked on a |Dispatcher|.
// If there is some code that already renders to an SkCanvas object,
// those rendering commands can be captured into a DisplayList using
// the DisplayListCanvasRecorder class.
class DisplayListBuilder final : public virtual Dispatcher,
                                 public SkRefCnt,
                                 DisplayListOpFlags {
 public:
  explicit DisplayListBuilder(const SkRect& cull_rect = kMaxCullRect_);
  ~DisplayListBuilder();

  void setAntiAlias(bool aa) override {
    if (current_anti_alias_ != aa) {
      onSetAntiAlias(aa);
    }
  }
  void setDither(bool dither) override {
    if (current_dither_ != dither) {
      onSetDither(dither);
    }
  }
  void setInvertColors(bool invert) override {
    if (current_invert_colors_ != invert) {
      onSetInvertColors(invert);
    }
  }
  void setStrokeCap(SkPaint::Cap cap) override {
    if (current_stroke_cap_ != cap) {
      onSetStrokeCap(cap);
    }
  }
  void setStrokeJoin(SkPaint::Join join) override {
    if (current_stroke_join_ != join) {
      onSetStrokeJoin(join);
    }
  }
  void setStyle(SkPaint::Style style) override {
    if (current_style_ != style) {
      onSetStyle(style);
    }
  }
  void setStrokeWidth(SkScalar width) override {
    if (current_stroke_width_ != width) {
      onSetStrokeWidth(width);
    }
  }
  void setStrokeMiter(SkScalar limit) override {
    if (current_stroke_miter_ != limit) {
      onSetStrokeMiter(limit);
    }
  }
  void setColor(SkColor color) override {
    if (current_color_ != color) {
      onSetColor(color);
    }
  }
  void setBlendMode(SkBlendMode mode) override {
    if (current_blender_ || current_blend_mode_ != mode) {
      onSetBlendMode(mode);
    }
  }
  void setBlender(sk_sp<SkBlender> blender) override {
    if (!blender) {
      setBlendMode(SkBlendMode::kSrcOver);
    } else if (current_blender_ != blender) {
      onSetBlender(std::move(blender));
    }
  }
  void setShader(sk_sp<SkShader> shader) override {
    if (current_shader_ != shader) {
      onSetShader(std::move(shader));
    }
  }
  void setImageFilter(sk_sp<SkImageFilter> filter) override {
    if (current_image_filter_ != filter) {
      onSetImageFilter(std::move(filter));
    }
  }
  void setColorFilter(sk_sp<SkColorFilter> filter) override {
    if (current_color_filter_ != filter) {
      onSetColorFilter(std::move(filter));
    }
  }
  void setPathEffect(sk_sp<SkPathEffect> effect) override {
    if (current_path_effect_ != effect) {
      onSetPathEffect(std::move(effect));
    }
  }
  void setMaskFilter(sk_sp<SkMaskFilter> filter) override {
    if (mask_sigma_valid(current_mask_sigma_) ||
        current_mask_filter_ != filter) {
      onSetMaskFilter(std::move(filter));
    }
  }
  void setMaskBlurFilter(SkBlurStyle style, SkScalar sigma) override {
    if (!mask_sigma_valid(sigma)) {
      // SkMastFilter::MakeBlur(invalid sigma) returns a nullptr, so we
      // reset the mask filter here rather than recording the invalid values.
      setMaskFilter(nullptr);
    } else if (current_mask_style_ != style || current_mask_sigma_ != sigma) {
      onSetMaskBlurFilter(style, sigma);
    }
  }

  bool isAntiAlias() const { return current_anti_alias_; }
  bool isDither() const { return current_dither_; }
  SkPaint::Style getStyle() const { return current_style_; }
  SkColor getColor() const { return current_color_; }
  SkScalar getStrokeWidth() const { return current_stroke_width_; }
  SkScalar getStrokeMiter() const { return current_stroke_miter_; }
  SkPaint::Cap getStrokeCap() const { return current_stroke_cap_; }
  SkPaint::Join getStrokeJoin() const { return current_stroke_join_; }
  sk_sp<SkShader> getShader() const { return current_shader_; }
  sk_sp<SkColorFilter> getColorFilter() const { return current_color_filter_; }
  bool isInvertColors() const { return current_invert_colors_; }
  std::optional<SkBlendMode> getBlendMode() const {
    if (current_blender_) {
      // The setters will turn "Mode" style blenders into "blend_mode"s
      return {};
    }
    return current_blend_mode_;
  }
  sk_sp<SkBlender> getBlender() const {
    return current_blender_ ? current_blender_
                            : SkBlender::Mode(current_blend_mode_);
  }
  sk_sp<SkPathEffect> getPathEffect() const { return current_path_effect_; }
  sk_sp<SkMaskFilter> getMaskFilter() const {
    return mask_sigma_valid(current_mask_sigma_)
               ? SkMaskFilter::MakeBlur(current_mask_style_,
                                        current_mask_sigma_)
               : current_mask_filter_;
  }
  // No utility getter for the utility setter:
  // void setMaskBlurFilter (SkBlurStyle style, SkScalar sigma)
  sk_sp<SkImageFilter> getImageFilter() const { return current_image_filter_; }

  void save() override;
  void saveLayer(const SkRect* bounds, bool restore_with_paint) override;
  void restore() override;
  int getSaveCount() { return layer_stack_.size(); }

  void translate(SkScalar tx, SkScalar ty) override;
  void scale(SkScalar sx, SkScalar sy) override;
  void rotate(SkScalar degrees) override;
  void skew(SkScalar sx, SkScalar sy) override;

  void setAttributesFromPaint(const SkPaint& paint,
                              const DisplayListAttributeFlags flags);

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

  void clipRect(const SkRect& rect, SkClipOp clip_op, bool is_aa) override;
  void clipRRect(const SkRRect& rrect, SkClipOp clip_op, bool is_aa) override;
  void clipPath(const SkPath& path, SkClipOp clip_op, bool is_aa) override;

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

  // bytes and ops from |drawPicture| and |drawDisplayList|
  size_t nested_bytes_ = 0;
  int nested_op_count_ = 0;

  SkRect cull_rect_;
  static constexpr SkRect kMaxCullRect_ =
      SkRect::MakeLTRB(-1E9F, -1E9F, 1E9F, 1E9F);

  template <typename T, typename... Args>
  void* Push(size_t extra, int op_inc, Args&&... args);

  // kInvalidSigma is used to indicate that no MaskBlur is currently set.
  static constexpr SkScalar kInvalidSigma = 0.0;
  static bool mask_sigma_valid(SkScalar sigma) {
    return SkScalarIsFinite(sigma) && sigma > 0.0;
  }

  struct LayerInfo {
    LayerInfo(bool has_layer = false)
        : has_layer(has_layer),
          cannot_inherit_opacity(false),
          has_compatible_op(false) {}

    bool has_layer;
    bool cannot_inherit_opacity;
    bool has_compatible_op;

    bool is_group_opacity_compatible() const { return !cannot_inherit_opacity; }

    void mark_incompatible() { cannot_inherit_opacity = true; }

    // For now this only allows a single compatible op to mark the
    // layer as being compatible with group opacity. If we start
    // computing bounds of ops in the Builder methods then we
    // can upgrade this to checking for overlapping ops.
    // See https://github.com/flutter/flutter/issues/93899
    void add_compatible_op() {
      if (!cannot_inherit_opacity) {
        if (has_compatible_op) {
          cannot_inherit_opacity = true;
        } else {
          has_compatible_op = true;
        }
      }
    }
  };

  std::vector<LayerInfo> layer_stack_;
  LayerInfo* current_layer_;

  // This flag indicates whether or not the current rendering attributes
  // are compatible with rendering ops applying an inherited opacity.
  bool current_opacity_compatibility_ = true;

  // Returns the compatibility of a given blend mode for applying an
  // inherited opacity value to modulate the visibility of the op.
  // For now we only accept SrcOver blend modes but this could be expanded
  // in the future to include other (rarely used) modes that also modulate
  // the opacity of a rendering operation at the cost of a switch statement
  // or lookup table.
  static bool IsOpacityCompatible(SkBlendMode mode) {
    return (mode == SkBlendMode::kSrcOver);
  }

  void UpdateCurrentOpacityCompatibility() {
    current_opacity_compatibility_ =         //
        current_color_filter_ == nullptr &&  //
        !current_invert_colors_ &&           //
        current_blender_ == nullptr &&       //
        IsOpacityCompatible(current_blend_mode_);
  }

  // Update the opacity compatibility flags of the current layer for an op
  // that has determined its compatibility as indicated by |compatible|.
  void UpdateLayerOpacityCompatibility(bool compatible) {
    if (compatible) {
      current_layer_->add_compatible_op();
    } else {
      current_layer_->mark_incompatible();
    }
  }

  // Check for opacity compatibility for an op that may or may not use the
  // current rendering attributes as indicated by |uses_blend_attribute|.
  // If the flag is false then the rendering op will be able to substitute
  // a default Paint object with the opacity applied using the default SrcOver
  // blend mode which is always compatible with applying an inherited opacity.
  void CheckLayerOpacityCompatibility(bool uses_blend_attribute = true) {
    UpdateLayerOpacityCompatibility(!uses_blend_attribute ||
                                    current_opacity_compatibility_);
  }

  void CheckLayerOpacityHairlineCompatibility() {
    UpdateLayerOpacityCompatibility(
        current_opacity_compatibility_ &&
        (current_style_ == SkPaint::kFill_Style || current_stroke_width_ > 0));
  }

  // Check for opacity compatibility for an op that ignores the current
  // attributes and uses the indicated blend |mode| to render to the layer.
  // This is only used by |drawColor| currently.
  void CheckLayerOpacityCompatibility(SkBlendMode mode) {
    UpdateLayerOpacityCompatibility(IsOpacityCompatible(mode));
  }

  void onSetAntiAlias(bool aa);
  void onSetDither(bool dither);
  void onSetInvertColors(bool invert);
  void onSetStrokeCap(SkPaint::Cap cap);
  void onSetStrokeJoin(SkPaint::Join join);
  void onSetStyle(SkPaint::Style style);
  void onSetStrokeWidth(SkScalar width);
  void onSetStrokeMiter(SkScalar limit);
  void onSetColor(SkColor color);
  void onSetBlendMode(SkBlendMode mode);
  void onSetBlender(sk_sp<SkBlender> blender);
  void onSetShader(sk_sp<SkShader> shader);
  void onSetImageFilter(sk_sp<SkImageFilter> filter);
  void onSetColorFilter(sk_sp<SkColorFilter> filter);
  void onSetPathEffect(sk_sp<SkPathEffect> effect);
  void onSetMaskFilter(sk_sp<SkMaskFilter> filter);
  void onSetMaskBlurFilter(SkBlurStyle style, SkScalar sigma);

  // These values should match the defaults of the Dart Paint object.
  bool current_anti_alias_ = false;
  bool current_dither_ = false;
  bool current_invert_colors_ = false;
  SkColor current_color_ = 0xFF000000;
  SkPaint::Style current_style_ = SkPaint::Style::kFill_Style;
  SkScalar current_stroke_width_ = 0.0;
  SkScalar current_stroke_miter_ = 4.0;
  SkPaint::Cap current_stroke_cap_ = SkPaint::Cap::kButt_Cap;
  SkPaint::Join current_stroke_join_ = SkPaint::Join::kMiter_Join;
  // If |current_blender_| is set then |current_blend_mode_| should be ignored
  SkBlendMode current_blend_mode_ = SkBlendMode::kSrcOver;
  sk_sp<SkBlender> current_blender_;
  sk_sp<SkShader> current_shader_;
  sk_sp<SkColorFilter> current_color_filter_;
  sk_sp<SkImageFilter> current_image_filter_;
  sk_sp<SkPathEffect> current_path_effect_;
  sk_sp<SkMaskFilter> current_mask_filter_;
  SkBlurStyle current_mask_style_;
  SkScalar current_mask_sigma_ = kInvalidSigma;
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_DISPLAY_LIST_H_
