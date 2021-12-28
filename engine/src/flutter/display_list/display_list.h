// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_DISPLAY_LIST_H_
#define FLUTTER_FLOW_DISPLAY_LIST_H_

#include <optional>

#include "flutter/display_list/types.h"
#include "flutter/fml/logging.h"

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

  static void DisposeOps(uint8_t* ptr, uint8_t* end);

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

}  // namespace flutter

#endif  // FLUTTER_FLOW_DISPLAY_LIST_H_
