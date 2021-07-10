// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <type_traits>

#include "flutter/flow/display_list.h"
#include "flutter/flow/display_list_canvas.h"
#include "flutter/flow/display_list_utils.h"
#include "flutter/fml/logging.h"

#include "third_party/skia/include/core/SkImageFilter.h"
#include "third_party/skia/include/core/SkMaskFilter.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkRSXform.h"
#include "third_party/skia/include/core/SkTextBlob.h"

namespace flutter {

const SkSamplingOptions DisplayList::NearestSampling =
    SkSamplingOptions(SkFilterMode::kNearest, SkMipmapMode::kNone);
const SkSamplingOptions DisplayList::LinearSampling =
    SkSamplingOptions(SkFilterMode::kLinear, SkMipmapMode::kNone);
const SkSamplingOptions DisplayList::MipmapSampling =
    SkSamplingOptions(SkFilterMode::kLinear, SkMipmapMode::kLinear);
const SkSamplingOptions DisplayList::CubicSampling =
    SkSamplingOptions(SkCubicResampler{1 / 3.0f, 1 / 3.0f});

// Most Ops can be bulk compared using memcmp because they contain
// only numeric values or constructs that are constructed from numeric
// values.
//
// Some contain sk_sp<> references which can also be bulk compared
// to see if they are pointing to the same reference. (Note that
// two sk_sp<> that refer to the same object are themselves ==.)
//
// Only a DLOp that wants to do a deep compare needs to override the
// DLOp::equals() method and return a value of kEqual or kNotEqual.
enum class DisplayListCompare {
  // The Op is deferring comparisons to a bulk memcmp performed lazily
  // across all bulk-comparable ops.
  kUseBulkCompare,

  // The Op provided a specific equals method that spotted a difference
  kNotEqual,

  // The Op provided a specific equals method that saw no differences
  kEqual,
};

#pragma pack(push, DLOp_Alignment, 8)

// Assuming a 64-bit platform (most of our platforms at this time?)
// the following comments are a "worst case" assessment of how well
// these structures pack into memory. They may be packed more tightly
// on some of the 32-bit platforms that we see in older phones.
//
// Struct allocation in the DL memory is aligned to a void* boundary
// which means that the minimum (aligned) struct size will be 8 bytes.
// The DLOp base uses 4 bytes so each Op-specific struct gets 4 bytes
// of data for "free" and works best when it packs well into an 8-byte
// aligned size.
struct DLOp {
  DisplayListOpType type : 8;
  uint32_t size : 24;

  DisplayListCompare equals(const DLOp* other) const {
    return DisplayListCompare::kUseBulkCompare;
  }
};

// 4 byte header + 4 byte payload packs into minimum 8 bytes
#define DEFINE_SET_BOOL_OP(name)                             \
  struct Set##name##Op final : DLOp {                        \
    static const auto kType = DisplayListOpType::kSet##name; \
                                                             \
    Set##name##Op(bool value) : value(value) {}              \
                                                             \
    const bool value;                                        \
                                                             \
    void dispatch(Dispatcher& dispatcher) const {            \
      dispatcher.set##name(value);                           \
    }                                                        \
  };
DEFINE_SET_BOOL_OP(AA)
DEFINE_SET_BOOL_OP(Dither)
DEFINE_SET_BOOL_OP(InvertColors)
#undef DEFINE_SET_BOOL_OP

// 4 byte header + 4 byte payload packs into minimum 8 bytes
#define DEFINE_SET_ENUM_OP(name)                                \
  struct Set##name##s##Op final : DLOp {                        \
    static const auto kType = DisplayListOpType::kSet##name##s; \
                                                                \
    Set##name##s##Op(SkPaint::name value) : value(value) {}     \
                                                                \
    const SkPaint::name value;                                  \
                                                                \
    void dispatch(Dispatcher& dispatcher) const {               \
      dispatcher.set##name##s(value);                           \
    }                                                           \
  };
DEFINE_SET_ENUM_OP(Cap)
DEFINE_SET_ENUM_OP(Join)
#undef DEFINE_SET_ENUM_OP

// 4 byte header + 4 byte payload packs into minimum 8 bytes
struct SetDrawStyleOp final : DLOp {
  static const auto kType = DisplayListOpType::kSetDrawStyle;

  SetDrawStyleOp(SkPaint::Style style) : style(style) {}

  const SkPaint::Style style;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.setDrawStyle(style);
  }
};
// 4 byte header + 4 byte payload packs into minimum 8 bytes
struct SetStrokeWidthOp final : DLOp {
  static const auto kType = DisplayListOpType::kSetStrokeWidth;

  SetStrokeWidthOp(SkScalar width) : width(width) {}

  const SkScalar width;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.setStrokeWidth(width);
  }
};
// 4 byte header + 4 byte payload packs into minimum 8 bytes
struct SetMiterLimitOp final : DLOp {
  static const auto kType = DisplayListOpType::kSetMiterLimit;

  SetMiterLimitOp(SkScalar limit) : limit(limit) {}

  const SkScalar limit;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.setMiterLimit(limit);
  }
};

// 4 byte header + 4 byte payload packs into minimum 8 bytes
struct SetColorOp final : DLOp {
  static const auto kType = DisplayListOpType::kSetColor;

  SetColorOp(SkColor color) : color(color) {}

  const SkColor color;

  void dispatch(Dispatcher& dispatcher) const { dispatcher.setColor(color); }
};
// 4 byte header + 4 byte payload packs into minimum 8 bytes
struct SetBlendModeOp final : DLOp {
  static const auto kType = DisplayListOpType::kSetBlendMode;

  SetBlendModeOp(SkBlendMode mode) : mode(mode) {}

  const SkBlendMode mode;

  void dispatch(Dispatcher& dispatcher) const { dispatcher.setBlendMode(mode); }
};

// Clear: 4 byte header + unused 4 byte payload uses 8 bytes
//        (4 bytes unused)
// Set: 4 byte header + an sk_sp (ptr) uses 16 bytes due to the
//      alignment of the ptr.
//      (4 bytes unused)
#define DEFINE_SET_CLEAR_SKREF_OP(name, field)                        \
  struct Clear##name##Op final : DLOp {                               \
    static const auto kType = DisplayListOpType::kClear##name;        \
                                                                      \
    Clear##name##Op() {}                                              \
                                                                      \
    void dispatch(Dispatcher& dispatcher) const {                     \
      dispatcher.set##name(nullptr);                                  \
    }                                                                 \
  };                                                                  \
  struct Set##name##Op final : DLOp {                                 \
    static const auto kType = DisplayListOpType::kSet##name;          \
                                                                      \
    Set##name##Op(sk_sp<Sk##name> field) : field(std::move(field)) {} \
                                                                      \
    sk_sp<Sk##name> field;                                            \
                                                                      \
    void dispatch(Dispatcher& dispatcher) const {                     \
      dispatcher.set##name(field);                                    \
    }                                                                 \
  };
DEFINE_SET_CLEAR_SKREF_OP(Shader, shader)
DEFINE_SET_CLEAR_SKREF_OP(ImageFilter, filter)
DEFINE_SET_CLEAR_SKREF_OP(ColorFilter, filter)
DEFINE_SET_CLEAR_SKREF_OP(MaskFilter, filter)
DEFINE_SET_CLEAR_SKREF_OP(PathEffect, effect)
#undef DEFINE_SET_CLEAR_SKREF_OP

// 4 byte header + 4 byte payload packs into minimum 8 bytes
// Note that the "blur style" is packed into the OpType to prevent
// needing an additional 8 bytes for a 4-value enum.
#define DEFINE_MASK_BLUR_FILTER_OP(name, style)                            \
  struct SetMaskBlurFilter##name##Op final : DLOp {                        \
    static const auto kType = DisplayListOpType::kSetMaskBlurFilter##name; \
                                                                           \
    SetMaskBlurFilter##name##Op(SkScalar sigma) : sigma(sigma) {}          \
                                                                           \
    SkScalar sigma;                                                        \
                                                                           \
    void dispatch(Dispatcher& dispatcher) const {                          \
      dispatcher.setMaskBlurFilter(style, sigma);                          \
    }                                                                      \
  };
DEFINE_MASK_BLUR_FILTER_OP(Normal, kNormal_SkBlurStyle)
DEFINE_MASK_BLUR_FILTER_OP(Solid, kSolid_SkBlurStyle)
DEFINE_MASK_BLUR_FILTER_OP(Inner, kInner_SkBlurStyle)
DEFINE_MASK_BLUR_FILTER_OP(Outer, kOuter_SkBlurStyle)
#undef DEFINE_MASK_BLUR_FILTER_OP

// 4 byte header + no payload uses minimum 8 bytes (4 bytes unused)
struct SaveOp final : DLOp {
  static const auto kType = DisplayListOpType::kSave;

  SaveOp() {}

  void dispatch(Dispatcher& dispatcher) const { dispatcher.save(); }
};
// 4 byte header + 4 byte payload packs into minimum 8 bytes
struct SaveLayerOp final : DLOp {
  static const auto kType = DisplayListOpType::kSaveLayer;

  SaveLayerOp(bool with_paint) : with_paint(with_paint) {}

  bool with_paint;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.saveLayer(nullptr, with_paint);
  }
};
// 4 byte header + 20 byte payload packs evenly into 24 bytes
struct SaveLayerBoundsOp final : DLOp {
  static const auto kType = DisplayListOpType::kSaveLayerBounds;

  SaveLayerBoundsOp(SkRect rect, bool with_paint)
      : with_paint(with_paint), rect(rect) {}

  bool with_paint;
  const SkRect rect;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.saveLayer(&rect, with_paint);
  }
};
// 4 byte header + no payload uses minimum 8 bytes (4 bytes unused)
struct RestoreOp final : DLOp {
  static const auto kType = DisplayListOpType::kRestore;

  RestoreOp() {}

  void dispatch(Dispatcher& dispatcher) const { dispatcher.restore(); }
};

// 4 byte header + 8 byte payload uses 12 bytes but is rounded up to 16 bytes
// (4 bytes unused)
struct TranslateOp final : DLOp {
  static const auto kType = DisplayListOpType::kTranslate;

  TranslateOp(SkScalar tx, SkScalar ty) : tx(tx), ty(ty) {}

  const SkScalar tx;
  const SkScalar ty;

  void dispatch(Dispatcher& dispatcher) const { dispatcher.translate(tx, ty); }
};
// 4 byte header + 8 byte payload uses 12 bytes but is rounded up to 16 bytes
// (4 bytes unused)
struct ScaleOp final : DLOp {
  static const auto kType = DisplayListOpType::kScale;

  ScaleOp(SkScalar sx, SkScalar sy) : sx(sx), sy(sy) {}

  const SkScalar sx;
  const SkScalar sy;

  void dispatch(Dispatcher& dispatcher) const { dispatcher.scale(sx, sy); }
};
// 4 byte header + 4 byte payload packs into minimum 8 bytes
struct RotateOp final : DLOp {
  static const auto kType = DisplayListOpType::kRotate;

  RotateOp(SkScalar degrees) : degrees(degrees) {}

  const SkScalar degrees;

  void dispatch(Dispatcher& dispatcher) const { dispatcher.rotate(degrees); }
};
// 4 byte header + 8 byte payload uses 12 bytes but is rounded up to 16 bytes
// (4 bytes unused)
struct SkewOp final : DLOp {
  static const auto kType = DisplayListOpType::kSkew;

  SkewOp(SkScalar sx, SkScalar sy) : sx(sx), sy(sy) {}

  const SkScalar sx;
  const SkScalar sy;

  void dispatch(Dispatcher& dispatcher) const { dispatcher.skew(sx, sy); }
};
// 4 byte header + 24 byte payload uses 28 bytes but is rounded up to 32 bytes
// (4 bytes unused)
struct Transform2x3Op final : DLOp {
  static const auto kType = DisplayListOpType::kTransform2x3;

  Transform2x3Op(SkScalar mxx,
                 SkScalar mxy,
                 SkScalar mxt,
                 SkScalar myx,
                 SkScalar myy,
                 SkScalar myt)
      : mxx(mxx), mxy(mxy), mxt(mxt), myx(myx), myy(myy), myt(myt) {}

  const SkScalar mxx, mxy, mxt;
  const SkScalar myx, myy, myt;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.transform2x3(mxx, mxy, mxt, myx, myy, myt);
  }
};
// 4 byte header + 36 byte payload packs evenly into 40 bytes
struct Transform3x3Op final : DLOp {
  static const auto kType = DisplayListOpType::kTransform3x3;

  Transform3x3Op(SkScalar mxx,
                 SkScalar mxy,
                 SkScalar mxt,
                 SkScalar myx,
                 SkScalar myy,
                 SkScalar myt,
                 SkScalar px,
                 SkScalar py,
                 SkScalar pt)
      : mxx(mxx),
        mxy(mxy),
        mxt(mxt),
        myx(myx),
        myy(myy),
        myt(myt),
        px(px),
        py(py),
        pt(pt) {}

  const SkScalar mxx, mxy, mxt;
  const SkScalar myx, myy, myt;
  const SkScalar px, py, pt;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.transform3x3(mxx, mxy, mxt, myx, myy, myt, px, py, pt);
  }
};

// 4 byte header + 4 byte common payload packs into minimum 8 bytes
// SkRect is 16 more bytes, which packs efficiently into 24 bytes total
// SkRRect is 52 more bytes, which rounds up to 56 bytes (4 bytes unused)
//         which packs into 64 bytes total
// SkPath is 16 more bytes, which packs efficiently into 24 bytes total
//
// We could pack the clip_op and the bool both into the free 4 bytes after
// the header, but the Windows compiler keeps wanting to expand that
// packing into more bytes than needed (even when they are declared as
// packed bit fields!)
#define DEFINE_CLIP_SHAPE_OP(shapetype, clipop)                            \
  struct Clip##clipop##shapetype##Op final : DLOp {                        \
    static const auto kType = DisplayListOpType::kClip##clipop##shapetype; \
                                                                           \
    Clip##clipop##shapetype##Op(Sk##shapetype shape, bool is_aa)           \
        : is_aa(is_aa), shape(shape) {}                                    \
                                                                           \
    const bool is_aa;                                                      \
    const Sk##shapetype shape;                                             \
                                                                           \
    void dispatch(Dispatcher& dispatcher) const {                          \
      dispatcher.clip##shapetype(shape, is_aa, SkClipOp::k##clipop);       \
    }                                                                      \
  };
DEFINE_CLIP_SHAPE_OP(Rect, Intersect)
DEFINE_CLIP_SHAPE_OP(RRect, Intersect)
DEFINE_CLIP_SHAPE_OP(Rect, Difference)
DEFINE_CLIP_SHAPE_OP(RRect, Difference)
#undef DEFINE_CLIP_SHAPE_OP

#define DEFINE_CLIP_PATH_OP(clipop)                                      \
  struct Clip##clipop##PathOp final : DLOp {                             \
    static const auto kType = DisplayListOpType::kClip##clipop##Path;    \
                                                                         \
    Clip##clipop##PathOp(SkPath path, bool is_aa)                        \
        : is_aa(is_aa), path(path) {}                                    \
                                                                         \
    const bool is_aa;                                                    \
    const SkPath path;                                                   \
                                                                         \
    void dispatch(Dispatcher& dispatcher) const {                        \
      dispatcher.clipPath(path, is_aa, SkClipOp::k##clipop);             \
    }                                                                    \
                                                                         \
    DisplayListCompare equals(const Clip##clipop##PathOp* other) const { \
      return is_aa == other->is_aa && path == other->path                \
                 ? DisplayListCompare::kEqual                            \
                 : DisplayListCompare::kNotEqual;                        \
    }                                                                    \
  };
DEFINE_CLIP_PATH_OP(Intersect)
DEFINE_CLIP_PATH_OP(Difference)
#undef DEFINE_CLIP_PATH_OP

// 4 byte header + no payload uses minimum 8 bytes (4 bytes unused)
struct DrawPaintOp final : DLOp {
  static const auto kType = DisplayListOpType::kDrawPaint;

  DrawPaintOp() {}

  void dispatch(Dispatcher& dispatcher) const { dispatcher.drawPaint(); }
};
// 4 byte header + 8 byte payload uses 12 bytes but is rounded up to 16 bytes
// (4 bytes unused)
struct DrawColorOp final : DLOp {
  static const auto kType = DisplayListOpType::kDrawColor;

  DrawColorOp(SkColor color, SkBlendMode mode) : color(color), mode(mode) {}

  const SkColor color;
  const SkBlendMode mode;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.drawColor(color, mode);
  }
};

// The common data is a 4 byte header with an unused 4 bytes
// SkRect is 16 more bytes, using 20 bytes which rounds up to 24 bytes total
//        (4 bytes unused)
// SkOval is same as SkRect
// SkRRect is 52 more bytes, which packs efficiently into 56 bytes total
#define DEFINE_DRAW_1ARG_OP(op_name, arg_type, arg_name)         \
  struct Draw##op_name##Op final : DLOp {                        \
    static const auto kType = DisplayListOpType::kDraw##op_name; \
                                                                 \
    Draw##op_name##Op(arg_type arg_name) : arg_name(arg_name) {} \
                                                                 \
    const arg_type arg_name;                                     \
                                                                 \
    void dispatch(Dispatcher& dispatcher) const {                \
      dispatcher.draw##op_name(arg_name);                        \
    }                                                            \
  };
DEFINE_DRAW_1ARG_OP(Rect, SkRect, rect)
DEFINE_DRAW_1ARG_OP(Oval, SkRect, oval)
DEFINE_DRAW_1ARG_OP(RRect, SkRRect, rrect)
#undef DEFINE_DRAW_1ARG_OP

// 4 byte header + 16 byte payload uses 20 bytes but is rounded up to 24 bytes
// (4 bytes unused)
struct DrawPathOp final : DLOp {
  static const auto kType = DisplayListOpType::kDrawPath;

  DrawPathOp(SkPath path) : path(path) {}

  const SkPath path;

  void dispatch(Dispatcher& dispatcher) const { dispatcher.drawPath(path); }

  DisplayListCompare equals(const DrawPathOp* other) const {
    return path == other->path ? DisplayListCompare::kEqual
                               : DisplayListCompare::kNotEqual;
  }
};

// The common data is a 4 byte header with an unused 4 bytes
// 2 x SkPoint is 16 more bytes, using 20 bytes rounding up to 24 bytes total
//             (4 bytes unused)
// SkPoint + SkScalar is 12 more bytes, packing efficiently into 16 bytes total
// 2 x SkRRect is 104 more bytes, using 108 and rounding up to 112 bytes total
//             (4 bytes unused)
#define DEFINE_DRAW_2ARG_OP(op_name, type1, name1, type2, name2) \
  struct Draw##op_name##Op final : DLOp {                        \
    static const auto kType = DisplayListOpType::kDraw##op_name; \
                                                                 \
    Draw##op_name##Op(type1 name1, type2 name2)                  \
        : name1(name1), name2(name2) {}                          \
                                                                 \
    const type1 name1;                                           \
    const type2 name2;                                           \
                                                                 \
    void dispatch(Dispatcher& dispatcher) const {                \
      dispatcher.draw##op_name(name1, name2);                    \
    }                                                            \
  };
DEFINE_DRAW_2ARG_OP(Line, SkPoint, p0, SkPoint, p1)
DEFINE_DRAW_2ARG_OP(Circle, SkPoint, center, SkScalar, radius)
DEFINE_DRAW_2ARG_OP(DRRect, SkRRect, outer, SkRRect, inner)
#undef DEFINE_DRAW_2ARG_OP

// 4 byte header + 28 byte payload packs efficiently into 32 bytes
struct DrawArcOp final : DLOp {
  static const auto kType = DisplayListOpType::kDrawArc;

  DrawArcOp(SkRect bounds, SkScalar start, SkScalar sweep, bool center)
      : bounds(bounds), start(start), sweep(sweep), center(center) {}

  const SkRect bounds;
  const SkScalar start;
  const SkScalar sweep;
  const bool center;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.drawArc(bounds, start, sweep, center);
  }
};

// 4 byte header + 4 byte fixed payload packs efficiently into 8 bytes
// But then there is a list of points following the structure which
// is guaranteed to be a multiple of 8 bytes (SkPoint is 8 bytes)
// so this op will always pack efficiently
// The point type is packed into 3 different OpTypes to avoid expanding
// the fixed payload beyond the 8 bytes
#define DEFINE_DRAW_POINTS_OP(name, mode)                              \
  struct Draw##name##Op final : DLOp {                                 \
    static const auto kType = DisplayListOpType::kDraw##name;          \
                                                                       \
    Draw##name##Op(uint32_t count) : count(count) {}                   \
                                                                       \
    const uint32_t count;                                              \
                                                                       \
    void dispatch(Dispatcher& dispatcher) const {                      \
      const SkPoint* pts = reinterpret_cast<const SkPoint*>(this + 1); \
      dispatcher.drawPoints(SkCanvas::PointMode::mode, count, pts);    \
    }                                                                  \
  };
DEFINE_DRAW_POINTS_OP(Points, kPoints_PointMode);
DEFINE_DRAW_POINTS_OP(Lines, kLines_PointMode);
DEFINE_DRAW_POINTS_OP(Polygon, kPolygon_PointMode);
#undef DEFINE_DRAW_POINTS_OP

// 4 byte header + 12 byte payload packs efficiently into 16 bytes
struct DrawVerticesOp final : DLOp {
  static const auto kType = DisplayListOpType::kDrawVertices;

  DrawVerticesOp(sk_sp<SkVertices> vertices, SkBlendMode mode)
      : mode(mode), vertices(std::move(vertices)) {}

  const SkBlendMode mode;
  const sk_sp<SkVertices> vertices;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.drawVertices(vertices, mode);
  }
};

// 4 byte header + 36 byte payload packs efficiently into 40 bytes
struct DrawImageOp final : DLOp {
  static const auto kType = DisplayListOpType::kDrawImage;

  DrawImageOp(const sk_sp<SkImage> image,
              const SkPoint& point,
              const SkSamplingOptions& sampling)
      : point(point), sampling(sampling), image(std::move(image)) {}

  const SkPoint point;
  const SkSamplingOptions sampling;
  const sk_sp<SkImage> image;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.drawImage(image, point, sampling);
  }
};

// 4 byte header + 60 byte payload packs efficiently into 64 bytes
//
// The constraint could be stored in the struct, but it would not pack
// efficiently so 2 variants are defined instead.
#define DEFINE_DRAW_IMAGE_RECT_OP(name, constraint)                          \
  struct Draw##name##Op final : DLOp {                                       \
    static const auto kType = DisplayListOpType::kDraw##name;                \
                                                                             \
    Draw##name##Op(const sk_sp<SkImage> image,                               \
                   const SkRect& src,                                        \
                   const SkRect& dst,                                        \
                   const SkSamplingOptions& sampling)                        \
        : src(src), dst(dst), sampling(sampling), image(std::move(image)) {} \
                                                                             \
    const SkRect src;                                                        \
    const SkRect dst;                                                        \
    const SkSamplingOptions sampling;                                        \
    const sk_sp<SkImage> image;                                              \
                                                                             \
    void dispatch(Dispatcher& dispatcher) const {                            \
      dispatcher.drawImageRect(image, src, dst, sampling, constraint);       \
    }                                                                        \
  };
DEFINE_DRAW_IMAGE_RECT_OP(ImageRectStrict, SkCanvas::kStrict_SrcRectConstraint)
DEFINE_DRAW_IMAGE_RECT_OP(ImageRectFast, SkCanvas::kFast_SrcRectConstraint)
#undef DEFINE_DRAW_IMAGE_RECT_OP

// 4 byte header + 44 byte payload packs efficiently into 48 bytes
struct DrawImageNineOp final : DLOp {
  static const auto kType = DisplayListOpType::kDrawImageNine;

  DrawImageNineOp(const sk_sp<SkImage> image,
                  const SkIRect& center,
                  const SkRect& dst,
                  SkFilterMode filter)
      : center(center), dst(dst), filter(filter), image(std::move(image)) {}

  const SkIRect center;
  const SkRect dst;
  const SkFilterMode filter;
  const sk_sp<SkImage> image;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.drawImageNine(image, center, dst, filter);
  }
};

// 4 byte header + 60 byte payload packs evenly into 64 bytes
struct DrawImageLatticeOp final : DLOp {
  static const auto kType = DisplayListOpType::kDrawImageLattice;

  DrawImageLatticeOp(const sk_sp<SkImage> image,
                     int x_count,
                     int y_count,
                     int cell_count,
                     const SkIRect& src,
                     const SkRect& dst,
                     SkFilterMode filter,
                     bool with_paint)
      : with_paint(with_paint),
        x_count(x_count),
        y_count(y_count),
        cell_count(cell_count),
        filter(filter),
        src(src),
        dst(dst),
        image(std::move(image)) {}

  const bool with_paint;
  const int x_count;
  const int y_count;
  const int cell_count;
  const SkFilterMode filter;
  const SkIRect src;
  const SkRect dst;
  const sk_sp<SkImage> image;

  void dispatch(Dispatcher& dispatcher) const {
    const int* xDivs = reinterpret_cast<const int*>(this + 1);
    const int* yDivs = reinterpret_cast<const int*>(xDivs + x_count);
    const SkColor* colors =
        (cell_count == 0) ? nullptr
                          : reinterpret_cast<const SkColor*>(yDivs + y_count);
    const SkCanvas::Lattice::RectType* types =
        (cell_count == 0)
            ? nullptr
            : reinterpret_cast<const SkCanvas::Lattice::RectType*>(colors +
                                                                   cell_count);
    dispatcher.drawImageLattice(
        image, {xDivs, yDivs, types, x_count, y_count, &src, colors}, dst,
        filter, with_paint);
  }
};

#define DRAW_ATLAS_NO_COLORS_ARRAY(tex, count) nullptr
#define DRAW_ATLAS_HAS_COLORS_ARRAY(tex, count) \
  reinterpret_cast<const SkColor*>(tex + count)

#define DRAW_ATLAS_NO_CULLING_ARGS                         \
  const sk_sp<SkImage> atlas, int count, SkBlendMode mode, \
      const SkSamplingOptions &sampling
#define DRAW_ATLAS_NO_CULLING_INIT \
  count(count), mode(mode), sampling(sampling), atlas(std::move(atlas))
#define DRAW_ATLAS_NO_CULLING_FIELDS \
  const int count;                   \
  const SkBlendMode mode;            \
  const SkSamplingOptions sampling;  \
  const sk_sp<SkImage> atlas
#define DRAW_ATLAS_NO_CULLING_P_ARG nullptr

#define DRAW_ATLAS_HAS_CULLING_ARGS \
  DRAW_ATLAS_NO_CULLING_ARGS, const SkRect& cull
#define DRAW_ATLAS_HAS_CULLING_INIT DRAW_ATLAS_NO_CULLING_INIT, cull(cull)
#define DRAW_ATLAS_HAS_CULLING_FIELDS \
  DRAW_ATLAS_NO_CULLING_FIELDS;       \
  const SkRect cull
#define DRAW_ATLAS_HAS_CULLING_P_ARG &cull

// 4 byte header + 36 byte common payload packs efficiently into 40 bytes
// Culling version has an additional 16 bytes of payload for 56 bytes
// So all 4 versions of the base structure pack well.
// Each of these is then followed by a number of lists.
// SkRSXform list is a multiple of 16 bytes so it is always packed well
// SkRect list is also a multiple of 16 bytes so it also packs well
// SkColor list only packs well if the count is even, otherwise there
// can be 4 unusued bytes at the end.
#define DEFINE_DRAW_ATLAS_OP(name, colors, cull)                             \
  struct Draw##name##Op final : DLOp {                                       \
    static const auto kType = DisplayListOpType::kDraw##name;                \
                                                                             \
    Draw##name##Op(DRAW_ATLAS_##cull##_ARGS) : DRAW_ATLAS_##cull##_INIT {}   \
                                                                             \
    DRAW_ATLAS_##cull##_FIELDS;                                              \
                                                                             \
    void dispatch(Dispatcher& dispatcher) const {                            \
      const SkRSXform* xform = reinterpret_cast<const SkRSXform*>(this + 1); \
      const SkRect* tex = reinterpret_cast<const SkRect*>(xform + count);    \
      const SkColor* colors = DRAW_ATLAS_##colors##_ARRAY(tex, count);       \
      dispatcher.drawAtlas(atlas, xform, tex, colors, count, mode, sampling, \
                           DRAW_ATLAS_##cull##_P_ARG);                       \
    }                                                                        \
  };
DEFINE_DRAW_ATLAS_OP(Atlas, NO_COLORS, NO_CULLING)
DEFINE_DRAW_ATLAS_OP(AtlasColored, HAS_COLORS, NO_CULLING)
DEFINE_DRAW_ATLAS_OP(AtlasCulled, NO_COLORS, HAS_CULLING)
DEFINE_DRAW_ATLAS_OP(AtlasColoredCulled, HAS_COLORS, HAS_CULLING)
#undef DEFINE_DRAW_ATLAS_OP
#undef DRAW_ATLAS_NO_COLORS_ARRAY
#undef DRAW_ATLAS_HAS_COLORS_ARRAY
#undef DRAW_ATLAS_NO_CULLING_ARGS
#undef DRAW_ATLAS_NO_CULLING_INIT
#undef DRAW_ATLAS_NO_CULLING_FIELDS
#undef DRAW_ATLAS_NO_CULLING_P_ARG
#undef DRAW_ATLAS_HAS_CULLING_ARGS
#undef DRAW_ATLAS_HAS_CULLING_INIT
#undef DRAW_ATLAS_HAS_CULLING_FIELDS
#undef DRAW_ATLAS_HAS_CULLING_P_ARG

// 4 byte header + 12 byte payload packs evenly into 16 bytes
struct DrawSkPictureOp final : DLOp {
  static const auto kType = DisplayListOpType::kDrawSkPicture;

  DrawSkPictureOp(sk_sp<SkPicture> picture, bool with_layer)
      : with_layer(with_layer), picture(std::move(picture)) {}

  const bool with_layer;
  const sk_sp<SkPicture> picture;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.drawPicture(picture, nullptr, with_layer);
  }
};

// 4 byte header + 52 byte payload packs evenly into 56 bytes
struct DrawSkPictureMatrixOp final : DLOp {
  static const auto kType = DisplayListOpType::kDrawSkPictureMatrix;

  DrawSkPictureMatrixOp(sk_sp<SkPicture> picture,
                        const SkMatrix matrix,
                        bool with_layer)
      : with_layer(with_layer), picture(std::move(picture)), matrix(matrix) {}

  const bool with_layer;
  const sk_sp<SkPicture> picture;
  const SkMatrix matrix;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.drawPicture(picture, &matrix, with_layer);
  }
};

// 4 byte header + ptr aligned payload uses 12 bytes rounde up to 16
// (4 bytes unused)
struct DrawDisplayListOp final : DLOp {
  static const auto kType = DisplayListOpType::kDrawDisplayList;

  DrawDisplayListOp(const sk_sp<DisplayList> display_list)
      : display_list(std::move(display_list)) {}

  sk_sp<DisplayList> display_list;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.drawDisplayList(display_list);
  }
};

// 4 byte header + 8 payload bytes + an aligned pointer take 24 bytes
// (4 unused to align the pointer)
struct DrawTextBlobOp final : DLOp {
  static const auto kType = DisplayListOpType::kDrawTextBlob;

  DrawTextBlobOp(const sk_sp<SkTextBlob> blob, SkScalar x, SkScalar y)
      : x(x), y(y), blob(std::move(blob)) {}

  const SkScalar x;
  const SkScalar y;
  const sk_sp<SkTextBlob> blob;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.drawTextBlob(blob, x, y);
  }
};

// 4 byte header + 28 byte payload packs evenly into 32 bytes
#define DEFINE_DRAW_SHADOW_OP(name, occludes)                         \
  struct Draw##name##Op final : DLOp {                                \
    static const auto kType = DisplayListOpType::kDraw##name;         \
                                                                      \
    Draw##name##Op(const SkPath& path,                                \
                   SkColor color,                                     \
                   SkScalar elevation,                                \
                   SkScalar dpr)                                      \
        : color(color), elevation(elevation), dpr(dpr), path(path) {} \
                                                                      \
    const SkColor color;                                              \
    const SkScalar elevation;                                         \
    const SkScalar dpr;                                               \
    const SkPath path;                                                \
                                                                      \
    void dispatch(Dispatcher& dispatcher) const {                     \
      dispatcher.drawShadow(path, color, elevation, occludes, dpr);   \
    }                                                                 \
  };
DEFINE_DRAW_SHADOW_OP(Shadow, false)
DEFINE_DRAW_SHADOW_OP(ShadowOccludes, true)
#undef DEFINE_DRAW_SHADOW_OP

#pragma pack(pop, DLOp_Alignment)

void DisplayList::ComputeBounds() {
  DisplayListBoundsCalculator calculator(bounds_cull_);
  Dispatch(calculator);
  bounds_ = calculator.getBounds();
}

void DisplayList::Dispatch(Dispatcher& dispatcher,
                           uint8_t* ptr,
                           uint8_t* end) const {
  while (ptr < end) {
    auto op = (const DLOp*)ptr;
    ptr += op->size;
    FML_DCHECK(ptr <= end);
    switch (op->type) {
#define DL_OP_DISPATCH(name)                                \
  case DisplayListOpType::k##name:                          \
    static_cast<const name##Op*>(op)->dispatch(dispatcher); \
    break;

      FOR_EACH_DISPLAY_LIST_OP(DL_OP_DISPATCH)

#undef DL_OP_DISPATCH

      default:
        FML_DCHECK(false);
        return;
    }
  }
}

static void DisposeOps(uint8_t* ptr, uint8_t* end) {
  while (ptr < end) {
    auto op = (const DLOp*)ptr;
    ptr += op->size;
    FML_DCHECK(ptr <= end);
    switch (op->type) {
#define DL_OP_DISPOSE(name)                            \
  case DisplayListOpType::k##name:                     \
    if (!std::is_trivially_destructible_v<name##Op>) { \
      static_cast<const name##Op*>(op)->~name##Op();   \
    }                                                  \
    break;

      FOR_EACH_DISPLAY_LIST_OP(DL_OP_DISPOSE)

#undef DL_OP_DISPATCH

      default:
        FML_DCHECK(false);
        return;
    }
  }
}

static bool CompareOps(uint8_t* ptrA,
                       uint8_t* endA,
                       uint8_t* ptrB,
                       uint8_t* endB) {
  // These conditions are checked by the caller...
  FML_DCHECK((endA - ptrA) == (endB - ptrB));
  FML_DCHECK(ptrA != ptrB);
  uint8_t* bulkStartA = ptrA;
  uint8_t* bulkStartB = ptrB;
  while (ptrA < endA && ptrB < endB) {
    auto opA = (const DLOp*)ptrA;
    auto opB = (const DLOp*)ptrB;
    if (opA->type != opB->type || opA->size != opB->size) {
      return false;
    }
    ptrA += opA->size;
    ptrB += opB->size;
    FML_DCHECK(ptrA <= endA);
    FML_DCHECK(ptrB <= endB);
    DisplayListCompare result;
    switch (opA->type) {
#define DL_OP_EQUALS(name)                              \
  case DisplayListOpType::k##name:                      \
    result = static_cast<const name##Op*>(opA)->equals( \
        static_cast<const name##Op*>(opB));             \
    break;

      FOR_EACH_DISPLAY_LIST_OP(DL_OP_EQUALS)

#undef DL_OP_DISPATCH

      default:
        FML_DCHECK(false);
        return false;
    }
    switch (result) {
      case DisplayListCompare::kNotEqual:
        return false;
      case DisplayListCompare::kUseBulkCompare:
        break;
      case DisplayListCompare::kEqual:
        // Check if we have a backlog of bytes to bulk compare and then
        // reset the bulk compare pointers to the address following this op
        auto bulkBytes = reinterpret_cast<const uint8_t*>(opA) - bulkStartA;
        if (bulkBytes > 0) {
          if (memcmp(bulkStartA, bulkStartB, bulkBytes) != 0) {
            return false;
          }
        }
        bulkStartA = ptrA;
        bulkStartB = ptrB;
        break;
    }
  }
  if (ptrA != endA || ptrB != endB) {
    return false;
  }
  if (bulkStartA < ptrA) {
    // Perform a final bulk compare if we have remaining bytes waiting
    if (memcmp(bulkStartA, bulkStartB, ptrA - bulkStartA) != 0) {
      return false;
    }
  }
  return true;
}

void DisplayList::RenderTo(SkCanvas* canvas) const {
  DisplayListCanvasDispatcher dispatcher(canvas);
  Dispatch(dispatcher);
}

bool DisplayList::Equals(const DisplayList& other) const {
  if (used_ != other.used_ || op_count_ != other.op_count_) {
    return false;
  }
  if (ptr_ == other.ptr_) {
    return true;
  }
  return CompareOps(ptr_, ptr_ + used_, other.ptr_, other.ptr_ + other.used_);
}

DisplayList::DisplayList(uint8_t* ptr,
                         size_t used,
                         int op_count,
                         const SkRect& cull)
    : ptr_(ptr),
      used_(used),
      op_count_(op_count),
      bounds_({0, 0, -1, -1}),
      bounds_cull_(cull) {
  static std::atomic<uint32_t> nextID{1};
  do {
    unique_id_ = nextID.fetch_add(+1, std::memory_order_relaxed);
  } while (unique_id_ == 0);
}

DisplayList::~DisplayList() {
  DisposeOps(ptr_, ptr_ + used_);
}

#define DL_BUILDER_PAGE 4096

// CopyV(dst, src,n, src,n, ...) copies any number of typed srcs into dst.
static void CopyV(void* dst) {}

template <typename S, typename... Rest>
static void CopyV(void* dst, const S* src, int n, Rest&&... rest) {
  FML_DCHECK(((uintptr_t)dst & (alignof(S) - 1)) == 0)
      << "Expected " << dst << " to be aligned for at least " << alignof(S)
      << " bytes.";
  sk_careful_memcpy(dst, src, n * sizeof(S));
  CopyV(SkTAddOffset<void>(dst, n * sizeof(S)), std::forward<Rest>(rest)...);
}

template <typename T, typename... Args>
void* DisplayListBuilder::Push(size_t pod, Args&&... args) {
  size_t size = SkAlignPtr(sizeof(T) + pod);
  FML_DCHECK(size < (1 << 24));
  if (used_ + size > allocated_) {
    static_assert(SkIsPow2(DL_BUILDER_PAGE),
                  "This math needs updating for non-pow2.");
    // Next greater multiple of DL_BUILDER_PAGE.
    allocated_ = (used_ + size + DL_BUILDER_PAGE) & ~(DL_BUILDER_PAGE - 1);
    storage_.realloc(allocated_);
    FML_DCHECK(storage_.get());
    memset(storage_.get() + used_, 0, allocated_ - used_);
  }
  FML_DCHECK(used_ + size <= allocated_);
  auto op = (T*)(storage_.get() + used_);
  used_ += size;
  new (op) T{std::forward<Args>(args)...};
  op->type = T::kType;
  op->size = size;
  op_count_++;
  return op + 1;
}

sk_sp<DisplayList> DisplayListBuilder::Build() {
  while (save_level_ > 0) {
    restore();
  }
  size_t used = used_;
  int count = op_count_;
  used_ = allocated_ = op_count_ = 0;
  storage_.realloc(used);
  return sk_sp<DisplayList>(
      new DisplayList(storage_.release(), used, count, cull_));
}

DisplayListBuilder::DisplayListBuilder(const SkRect& cull) : cull_(cull) {}

DisplayListBuilder::~DisplayListBuilder() {
  uint8_t* ptr = storage_.get();
  if (ptr) {
    DisposeOps(ptr, ptr + used_);
  }
}

void DisplayListBuilder::setAA(bool aa) {
  Push<SetAAOp>(0, aa);
}
void DisplayListBuilder::setDither(bool dither) {
  Push<SetDitherOp>(0, dither);
}
void DisplayListBuilder::setInvertColors(bool invert) {
  Push<SetInvertColorsOp>(0, invert);
}
void DisplayListBuilder::setCaps(SkPaint::Cap cap) {
  Push<SetCapsOp>(0, cap);
}
void DisplayListBuilder::setJoins(SkPaint::Join join) {
  Push<SetJoinsOp>(0, join);
}
void DisplayListBuilder::setDrawStyle(SkPaint::Style style) {
  Push<SetDrawStyleOp>(0, style);
}
void DisplayListBuilder::setStrokeWidth(SkScalar width) {
  Push<SetStrokeWidthOp>(0, width);
}
void DisplayListBuilder::setMiterLimit(SkScalar limit) {
  Push<SetMiterLimitOp>(0, limit);
}
void DisplayListBuilder::setColor(SkColor color) {
  Push<SetColorOp>(0, color);
}
void DisplayListBuilder::setBlendMode(SkBlendMode mode) {
  Push<SetBlendModeOp>(0, mode);
}
void DisplayListBuilder::setShader(sk_sp<SkShader> shader) {
  shader  //
      ? Push<SetShaderOp>(0, std::move(shader))
      : Push<ClearShaderOp>(0);
}
void DisplayListBuilder::setImageFilter(sk_sp<SkImageFilter> filter) {
  filter  //
      ? Push<SetImageFilterOp>(0, std::move(filter))
      : Push<ClearImageFilterOp>(0);
}
void DisplayListBuilder::setColorFilter(sk_sp<SkColorFilter> filter) {
  filter  //
      ? Push<SetColorFilterOp>(0, std::move(filter))
      : Push<ClearColorFilterOp>(0);
}
void DisplayListBuilder::setPathEffect(sk_sp<SkPathEffect> effect) {
  effect  //
      ? Push<SetPathEffectOp>(0, std::move(effect))
      : Push<ClearPathEffectOp>(0);
}
void DisplayListBuilder::setMaskFilter(sk_sp<SkMaskFilter> filter) {
  Push<SetMaskFilterOp>(0, std::move(filter));
}
void DisplayListBuilder::setMaskBlurFilter(SkBlurStyle style, SkScalar sigma) {
  switch (style) {
    case kNormal_SkBlurStyle:
      Push<SetMaskBlurFilterNormalOp>(0, sigma);
      break;
    case kSolid_SkBlurStyle:
      Push<SetMaskBlurFilterSolidOp>(0, sigma);
      break;
    case kOuter_SkBlurStyle:
      Push<SetMaskBlurFilterOuterOp>(0, sigma);
      break;
    case kInner_SkBlurStyle:
      Push<SetMaskBlurFilterInnerOp>(0, sigma);
      break;
  }
}

void DisplayListBuilder::save() {
  save_level_++;
  Push<SaveOp>(0);
}
void DisplayListBuilder::restore() {
  if (save_level_ > 0) {
    Push<RestoreOp>(0);
    save_level_--;
  }
}
void DisplayListBuilder::saveLayer(const SkRect* bounds, bool with_paint) {
  save_level_++;
  bounds  //
      ? Push<SaveLayerBoundsOp>(0, *bounds, with_paint)
      : Push<SaveLayerOp>(0, with_paint);
}

void DisplayListBuilder::translate(SkScalar tx, SkScalar ty) {
  Push<TranslateOp>(0, tx, ty);
}
void DisplayListBuilder::scale(SkScalar sx, SkScalar sy) {
  Push<ScaleOp>(0, sx, sy);
}
void DisplayListBuilder::rotate(SkScalar degrees) {
  Push<RotateOp>(0, degrees);
}
void DisplayListBuilder::skew(SkScalar sx, SkScalar sy) {
  Push<SkewOp>(0, sx, sy);
}
void DisplayListBuilder::transform2x3(SkScalar mxx,
                                      SkScalar mxy,
                                      SkScalar mxt,
                                      SkScalar myx,
                                      SkScalar myy,
                                      SkScalar myt) {
  Push<Transform2x3Op>(0, mxx, mxy, mxt, myx, myy, myt);
}
void DisplayListBuilder::transform3x3(SkScalar mxx,
                                      SkScalar mxy,
                                      SkScalar mxt,
                                      SkScalar myx,
                                      SkScalar myy,
                                      SkScalar myt,
                                      SkScalar px,
                                      SkScalar py,
                                      SkScalar pt) {
  Push<Transform3x3Op>(0, mxx, mxy, mxt, myx, myy, myt, px, py, pt);
}

void DisplayListBuilder::clipRect(const SkRect& rect,
                                  bool is_aa,
                                  SkClipOp clip_op) {
  clip_op == SkClipOp::kIntersect  //
      ? Push<ClipIntersectRectOp>(0, rect, is_aa)
      : Push<ClipDifferenceRectOp>(0, rect, is_aa);
}
void DisplayListBuilder::clipRRect(const SkRRect& rrect,
                                   bool is_aa,
                                   SkClipOp clip_op) {
  if (rrect.isRect()) {
    clipRect(rrect.rect(), is_aa, clip_op);
  } else {
    clip_op == SkClipOp::kIntersect  //
        ? Push<ClipIntersectRRectOp>(0, rrect, is_aa)
        : Push<ClipDifferenceRRectOp>(0, rrect, is_aa);
  }
}
void DisplayListBuilder::clipPath(const SkPath& path,
                                  bool is_aa,
                                  SkClipOp clip_op) {
  if (!path.isInverseFillType()) {
    SkRect rect;
    if (path.isRect(&rect)) {
      this->clipRect(rect, is_aa, clip_op);
      return;
    }
    SkRRect rrect;
    if (path.isOval(&rect)) {
      rrect.setOval(rect);
      this->clipRRect(rrect, is_aa, clip_op);
      return;
    }
    if (path.isRRect(&rrect)) {
      this->clipRRect(rrect, is_aa, clip_op);
      return;
    }
  }
  clip_op == SkClipOp::kIntersect  //
      ? Push<ClipIntersectPathOp>(0, path, is_aa)
      : Push<ClipDifferencePathOp>(0, path, is_aa);
}

void DisplayListBuilder::drawPaint() {
  Push<DrawPaintOp>(0);
}
void DisplayListBuilder::drawColor(SkColor color, SkBlendMode mode) {
  Push<DrawColorOp>(0, color, mode);
}
void DisplayListBuilder::drawLine(const SkPoint& p0, const SkPoint& p1) {
  Push<DrawLineOp>(0, p0, p1);
}
void DisplayListBuilder::drawRect(const SkRect& rect) {
  Push<DrawRectOp>(0, rect);
}
void DisplayListBuilder::drawOval(const SkRect& bounds) {
  Push<DrawOvalOp>(0, bounds);
}
void DisplayListBuilder::drawCircle(const SkPoint& center, SkScalar radius) {
  Push<DrawCircleOp>(0, center, radius);
}
void DisplayListBuilder::drawRRect(const SkRRect& rrect) {
  if (rrect.isRect()) {
    drawRect(rrect.rect());
  } else if (rrect.isOval()) {
    drawOval(rrect.rect());
  } else {
    Push<DrawRRectOp>(0, rrect);
  }
}
void DisplayListBuilder::drawDRRect(const SkRRect& outer,
                                    const SkRRect& inner) {
  Push<DrawDRRectOp>(0, outer, inner);
}
void DisplayListBuilder::drawPath(const SkPath& path) {
  Push<DrawPathOp>(0, path);
}

void DisplayListBuilder::drawArc(const SkRect& bounds,
                                 SkScalar start,
                                 SkScalar sweep,
                                 bool useCenter) {
  Push<DrawArcOp>(0, bounds, start, sweep, useCenter);
}
void DisplayListBuilder::drawPoints(SkCanvas::PointMode mode,
                                    uint32_t count,
                                    const SkPoint pts[]) {
  void* data_ptr;
  FML_DCHECK(count < MaxDrawPointsCount);
  int bytes = count * sizeof(SkPoint);
  switch (mode) {
    case SkCanvas::PointMode::kPoints_PointMode:
      data_ptr = Push<DrawPointsOp>(bytes, count);
      break;
    case SkCanvas::PointMode::kLines_PointMode:
      data_ptr = Push<DrawLinesOp>(bytes, count);
      break;
    case SkCanvas::PointMode::kPolygon_PointMode:
      data_ptr = Push<DrawPolygonOp>(bytes, count);
      break;
    default:
      FML_DCHECK(false);
      return;
  }
  CopyV(data_ptr, pts, count);
}
void DisplayListBuilder::drawVertices(const sk_sp<SkVertices> vertices,
                                      SkBlendMode mode) {
  Push<DrawVerticesOp>(0, std::move(vertices), mode);
}

void DisplayListBuilder::drawImage(const sk_sp<SkImage> image,
                                   const SkPoint point,
                                   const SkSamplingOptions& sampling) {
  Push<DrawImageOp>(0, std::move(image), point, sampling);
}
void DisplayListBuilder::drawImageRect(const sk_sp<SkImage> image,
                                       const SkRect& src,
                                       const SkRect& dst,
                                       const SkSamplingOptions& sampling,
                                       SkCanvas::SrcRectConstraint constraint) {
  constraint == SkCanvas::kFast_SrcRectConstraint  //
      ? Push<DrawImageRectFastOp>(0, std::move(image), src, dst, sampling)
      : Push<DrawImageRectStrictOp>(0, std::move(image), src, dst, sampling);
}
void DisplayListBuilder::drawImageNine(const sk_sp<SkImage> image,
                                       const SkIRect& center,
                                       const SkRect& dst,
                                       SkFilterMode filter) {
  Push<DrawImageNineOp>(0, std::move(image), center, dst, filter);
}
void DisplayListBuilder::drawImageLattice(const sk_sp<SkImage> image,
                                          const SkCanvas::Lattice& lattice,
                                          const SkRect& dst,
                                          SkFilterMode filter,
                                          bool with_paint) {
  int xDivCount = lattice.fXCount;
  int yDivCount = lattice.fYCount;
  FML_DCHECK((lattice.fRectTypes == nullptr) || (lattice.fColors != nullptr));
  int cellCount = lattice.fRectTypes && lattice.fColors
                      ? (xDivCount + 1) * (yDivCount + 1)
                      : 0;
  size_t bytes =
      (xDivCount + yDivCount) * sizeof(int) +
      cellCount * (sizeof(SkColor) + sizeof(SkCanvas::Lattice::RectType));
  SkIRect src = lattice.fBounds ? *lattice.fBounds : image->bounds();
  void* pod = this->Push<DrawImageLatticeOp>(bytes, std::move(image), xDivCount,
                                             yDivCount, cellCount, src, dst,
                                             filter, with_paint);
  CopyV(pod, lattice.fXDivs, xDivCount, lattice.fYDivs, yDivCount,
        lattice.fColors, cellCount, lattice.fRectTypes, cellCount);
}
void DisplayListBuilder::drawAtlas(const sk_sp<SkImage> atlas,
                                   const SkRSXform xform[],
                                   const SkRect tex[],
                                   const SkColor colors[],
                                   int count,
                                   SkBlendMode mode,
                                   const SkSamplingOptions& sampling,
                                   const SkRect* cullRect) {
  int bytes = count * (sizeof(SkRSXform) + sizeof(SkRect));
  void* data_ptr;
  if (colors) {
    bytes += count * sizeof(SkColor);
    if (cullRect) {
      data_ptr = Push<DrawAtlasColoredCulledOp>(bytes, std::move(atlas), count,
                                                mode, sampling, *cullRect);
    } else {
      data_ptr = Push<DrawAtlasColoredOp>(bytes, std::move(atlas), count, mode,
                                          sampling);
    }
    CopyV(data_ptr, xform, count, tex, count, colors, count);
  } else {
    if (cullRect) {
      data_ptr = Push<DrawAtlasCulledOp>(bytes, std::move(atlas), count, mode,
                                         sampling, *cullRect);
    } else {
      data_ptr =
          Push<DrawAtlasOp>(bytes, std::move(atlas), count, mode, sampling);
    }
    CopyV(data_ptr, xform, count, tex, count);
  }
}

void DisplayListBuilder::drawPicture(const sk_sp<SkPicture> picture,
                                     const SkMatrix* matrix,
                                     bool with_layer) {
  matrix  //
      ? Push<DrawSkPictureMatrixOp>(0, std::move(picture), *matrix, with_layer)
      : Push<DrawSkPictureOp>(0, std::move(picture), with_layer);
}
void DisplayListBuilder::drawDisplayList(
    const sk_sp<DisplayList> display_list) {
  Push<DrawDisplayListOp>(0, std::move(display_list));
}
void DisplayListBuilder::drawTextBlob(const sk_sp<SkTextBlob> blob,
                                      SkScalar x,
                                      SkScalar y) {
  Push<DrawTextBlobOp>(0, std::move(blob), x, y);
}
void DisplayListBuilder::drawShadow(const SkPath& path,
                                    const SkColor color,
                                    const SkScalar elevation,
                                    bool occludes,
                                    SkScalar dpr) {
  occludes  //
      ? Push<DrawShadowOccludesOp>(0, path, color, elevation, dpr)
      : Push<DrawShadowOp>(0, path, color, elevation, dpr);
}

}  // namespace flutter
