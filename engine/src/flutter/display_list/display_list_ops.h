// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DISPLAY_LIST_OPS_H_
#define FLUTTER_DISPLAY_LIST_DISPLAY_LIST_OPS_H_

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/display_list_blend_mode.h"
#include "flutter/display_list/display_list_dispatcher.h"
#include "flutter/display_list/display_list_sampling_options.h"
#include "flutter/display_list/types.h"
#include "flutter/fml/macros.h"

namespace flutter {

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

// "DLOpPackLabel" is just a label for the pack pragma so it can be popped
// later.
#pragma pack(push, DLOpPackLabel, 8)

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
    explicit Set##name##Op(bool value) : value(value) {}     \
                                                             \
    const bool value;                                        \
                                                             \
    void dispatch(Dispatcher& dispatcher) const {            \
      dispatcher.set##name(value);                           \
    }                                                        \
  };
DEFINE_SET_BOOL_OP(AntiAlias)
DEFINE_SET_BOOL_OP(Dither)
DEFINE_SET_BOOL_OP(InvertColors)
#undef DEFINE_SET_BOOL_OP

// 4 byte header + 4 byte payload packs into minimum 8 bytes
#define DEFINE_SET_ENUM_OP(name)                                         \
  struct SetStroke##name##Op final : DLOp {                              \
    static const auto kType = DisplayListOpType::kSetStroke##name;       \
                                                                         \
    explicit SetStroke##name##Op(DlStroke##name value) : value(value) {} \
                                                                         \
    const DlStroke##name value;                                          \
                                                                         \
    void dispatch(Dispatcher& dispatcher) const {                        \
      dispatcher.setStroke##name(value);                                 \
    }                                                                    \
  };
DEFINE_SET_ENUM_OP(Cap)
DEFINE_SET_ENUM_OP(Join)
#undef DEFINE_SET_ENUM_OP

// 4 byte header + 4 byte payload packs into minimum 8 bytes
struct SetStyleOp final : DLOp {
  static const auto kType = DisplayListOpType::kSetStyle;

  explicit SetStyleOp(DlDrawStyle style) : style(style) {}

  const DlDrawStyle style;

  void dispatch(Dispatcher& dispatcher) const { dispatcher.setStyle(style); }
};
// 4 byte header + 4 byte payload packs into minimum 8 bytes
struct SetStrokeWidthOp final : DLOp {
  static const auto kType = DisplayListOpType::kSetStrokeWidth;

  explicit SetStrokeWidthOp(float width) : width(width) {}

  const float width;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.setStrokeWidth(width);
  }
};
// 4 byte header + 4 byte payload packs into minimum 8 bytes
struct SetStrokeMiterOp final : DLOp {
  static const auto kType = DisplayListOpType::kSetStrokeMiter;

  explicit SetStrokeMiterOp(float limit) : limit(limit) {}

  const float limit;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.setStrokeMiter(limit);
  }
};

// 4 byte header + 4 byte payload packs into minimum 8 bytes
struct SetColorOp final : DLOp {
  static const auto kType = DisplayListOpType::kSetColor;

  explicit SetColorOp(DlColor color) : color(color) {}

  const DlColor color;

  void dispatch(Dispatcher& dispatcher) const { dispatcher.setColor(color); }
};
// 4 byte header + 4 byte payload packs into minimum 8 bytes
struct SetBlendModeOp final : DLOp {
  static const auto kType = DisplayListOpType::kSetBlendMode;

  explicit SetBlendModeOp(DlBlendMode mode) : mode(mode) {}

  const DlBlendMode mode;

  void dispatch(Dispatcher& dispatcher) const { dispatcher.setBlendMode(mode); }
};

// Clear: 4 byte header + unused 4 byte payload uses 8 bytes
//        (4 bytes unused)
// Set: 4 byte header + an sk_sp (ptr) uses 16 bytes due to the
//      alignment of the ptr.
//      (4 bytes unused)
#define DEFINE_SET_CLEAR_SKREF_OP(name, field)                                 \
  struct Clear##name##Op final : DLOp {                                        \
    static const auto kType = DisplayListOpType::kClear##name;                 \
                                                                               \
    Clear##name##Op() {}                                                       \
                                                                               \
    void dispatch(Dispatcher& dispatcher) const {                              \
      dispatcher.set##name(nullptr);                                           \
    }                                                                          \
  };                                                                           \
  struct Set##name##Op final : DLOp {                                          \
    static const auto kType = DisplayListOpType::kSet##name;                   \
                                                                               \
    explicit Set##name##Op(sk_sp<Sk##name> field) : field(std::move(field)) {} \
                                                                               \
    sk_sp<Sk##name> field;                                                     \
                                                                               \
    void dispatch(Dispatcher& dispatcher) const {                              \
      dispatcher.set##name(field);                                             \
    }                                                                          \
  };
DEFINE_SET_CLEAR_SKREF_OP(Blender, blender)
#undef DEFINE_SET_CLEAR_SKREF_OP

// Clear: 4 byte header + unused 4 byte payload uses 8 bytes
//        (4 bytes unused)
// Set: 4 byte header + unused 4 byte struct padding + Dl<name>
//      instance copied to the memory following the record
//      yields a size and efficiency that has somewhere between
//      4 and 8 bytes unused
// SetSk: 4 byte header + an sk_sp (ptr) uses 16 bytes due to the
//        alignment of the ptr.
//        (4 bytes unused)
#define DEFINE_SET_CLEAR_DLATTR_OP(name, sk_name, field)                    \
  struct Clear##name##Op final : DLOp {                                     \
    static const auto kType = DisplayListOpType::kClear##name;              \
                                                                            \
    Clear##name##Op() {}                                                    \
                                                                            \
    void dispatch(Dispatcher& dispatcher) const {                           \
      dispatcher.set##name(nullptr);                                        \
    }                                                                       \
  };                                                                        \
  struct SetPod##name##Op final : DLOp {                                    \
    static const auto kType = DisplayListOpType::kSetPod##name;             \
                                                                            \
    SetPod##name##Op() {}                                                   \
                                                                            \
    void dispatch(Dispatcher& dispatcher) const {                           \
      const Dl##name* filter = reinterpret_cast<const Dl##name*>(this + 1); \
      dispatcher.set##name(filter);                                         \
    }                                                                       \
  };                                                                        \
  struct SetSk##name##Op final : DLOp {                                     \
    static const auto kType = DisplayListOpType::kSetSk##name;              \
                                                                            \
    SetSk##name##Op(sk_sp<Sk##sk_name> field) : field(field) {}             \
                                                                            \
    sk_sp<Sk##sk_name> field;                                               \
                                                                            \
    void dispatch(Dispatcher& dispatcher) const {                           \
      DlUnknown##name dl_filter(field);                                     \
      dispatcher.set##name(&dl_filter);                                     \
    }                                                                       \
  };
DEFINE_SET_CLEAR_DLATTR_OP(ColorFilter, ColorFilter, filter)
DEFINE_SET_CLEAR_DLATTR_OP(ImageFilter, ImageFilter, filter)
DEFINE_SET_CLEAR_DLATTR_OP(MaskFilter, MaskFilter, filter)
DEFINE_SET_CLEAR_DLATTR_OP(ColorSource, Shader, source)
DEFINE_SET_CLEAR_DLATTR_OP(PathEffect, PathEffect, effect)
#undef DEFINE_SET_CLEAR_DLATTR_OP

// 4 byte header + 80 bytes for the embedded DlImageColorSource
// uses 84 total bytes (4 bytes unused)
struct SetImageColorSourceOp : DLOp {
  static const auto kType = DisplayListOpType::kSetImageColorSource;

  SetImageColorSourceOp(const DlImageColorSource* source)
      : source(source->image(),
               source->horizontal_tile_mode(),
               source->vertical_tile_mode(),
               source->sampling(),
               source->matrix_ptr()) {}

  const DlImageColorSource source;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.setColorSource(&source);
  }
};

// 4 byte header + 16 byte payload uses 24 total bytes (4 bytes unused)
struct SetSharedImageFilterOp : DLOp {
  static const auto kType = DisplayListOpType::kSetSharedImageFilter;

  SetSharedImageFilterOp(const DlImageFilter* filter)
      : filter(filter->shared()) {}

  const std::shared_ptr<DlImageFilter> filter;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.setImageFilter(filter.get());
  }

  DisplayListCompare equals(const SetSharedImageFilterOp* other) const {
    return Equals(filter, other->filter) ? DisplayListCompare::kEqual
                                         : DisplayListCompare::kNotEqual;
  }
};

// 4 byte header + no payload uses minimum 8 bytes (4 bytes unused)
struct SaveOp final : DLOp {
  static const auto kType = DisplayListOpType::kSave;

  SaveOp() {}

  void dispatch(Dispatcher& dispatcher) const { dispatcher.save(); }
};
// 4 byte header + 4 byte payload packs into minimum 8 bytes
struct SaveLayerOp final : DLOp {
  static const auto kType = DisplayListOpType::kSaveLayer;

  explicit SaveLayerOp(const SaveLayerOptions options) : options(options) {}

  SaveLayerOptions options;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.saveLayer(nullptr, options);
  }
};
// 4 byte header + 20 byte payload packs evenly into 24 bytes
struct SaveLayerBoundsOp final : DLOp {
  static const auto kType = DisplayListOpType::kSaveLayerBounds;

  SaveLayerBoundsOp(SkRect rect, const SaveLayerOptions options)
      : options(options), rect(rect) {}

  SaveLayerOptions options;
  const SkRect rect;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.saveLayer(&rect, options);
  }
};
// 4 byte header + 20 byte payload packs into minimum 24 bytes
struct SaveLayerBackdropOp final : DLOp {
  static const auto kType = DisplayListOpType::kSaveLayerBackdrop;

  explicit SaveLayerBackdropOp(const SaveLayerOptions options,
                               const DlImageFilter* backdrop)
      : options(options), backdrop(backdrop->shared()) {}

  SaveLayerOptions options;
  const std::shared_ptr<DlImageFilter> backdrop;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.saveLayer(nullptr, options, backdrop.get());
  }

  DisplayListCompare equals(const SaveLayerBackdropOp* other) const {
    return options == other->options && Equals(backdrop, other->backdrop)
               ? DisplayListCompare::kEqual
               : DisplayListCompare::kNotEqual;
  }
};
// 4 byte header + 36 byte payload packs evenly into 36 bytes
struct SaveLayerBackdropBoundsOp final : DLOp {
  static const auto kType = DisplayListOpType::kSaveLayerBackdropBounds;

  SaveLayerBackdropBoundsOp(SkRect rect,
                            const SaveLayerOptions options,
                            const DlImageFilter* backdrop)
      : options(options), rect(rect), backdrop(backdrop->shared()) {}

  SaveLayerOptions options;
  const SkRect rect;
  const std::shared_ptr<DlImageFilter> backdrop;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.saveLayer(&rect, options, backdrop.get());
  }

  DisplayListCompare equals(const SaveLayerBackdropBoundsOp* other) const {
    return (options == other->options && rect == other->rect &&
            Equals(backdrop, other->backdrop))
               ? DisplayListCompare::kEqual
               : DisplayListCompare::kNotEqual;
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

  explicit RotateOp(SkScalar degrees) : degrees(degrees) {}

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
struct Transform2DAffineOp final : DLOp {
  static const auto kType = DisplayListOpType::kTransform2DAffine;

  // clang-format off
  Transform2DAffineOp(SkScalar mxx, SkScalar mxy, SkScalar mxt,
                      SkScalar myx, SkScalar myy, SkScalar myt)
      : mxx(mxx), mxy(mxy), mxt(mxt), myx(myx), myy(myy), myt(myt) {}
  // clang-format on

  const SkScalar mxx, mxy, mxt;
  const SkScalar myx, myy, myt;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.transform2DAffine(mxx, mxy, mxt,  //
                                 myx, myy, myt);
  }
};
// 4 byte header + 64 byte payload uses 68 bytes which is rounded up to 72 bytes
// (4 bytes unused)
struct TransformFullPerspectiveOp final : DLOp {
  static const auto kType = DisplayListOpType::kTransformFullPerspective;

  // clang-format off
  TransformFullPerspectiveOp(
      SkScalar mxx, SkScalar mxy, SkScalar mxz, SkScalar mxt,
      SkScalar myx, SkScalar myy, SkScalar myz, SkScalar myt,
      SkScalar mzx, SkScalar mzy, SkScalar mzz, SkScalar mzt,
      SkScalar mwx, SkScalar mwy, SkScalar mwz, SkScalar mwt)
      : mxx(mxx), mxy(mxy), mxz(mxz), mxt(mxt),
        myx(myx), myy(myy), myz(myz), myt(myt),
        mzx(mzx), mzy(mzy), mzz(mzz), mzt(mzt),
        mwx(mwx), mwy(mwy), mwz(mwz), mwt(mwt) {}
  // clang-format on

  const SkScalar mxx, mxy, mxz, mxt;
  const SkScalar myx, myy, myz, myt;
  const SkScalar mzx, mzy, mzz, mzt;
  const SkScalar mwx, mwy, mwz, mwt;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.transformFullPerspective(mxx, mxy, mxz, mxt,  //
                                        myx, myy, myz, myt,  //
                                        mzx, mzy, mzz, mzt,  //
                                        mwx, mwy, mwz, mwt);
  }
};

// 4 byte header with no payload.
struct TransformResetOp final : DLOp {
  static const auto kType = DisplayListOpType::kTransformReset;

  TransformResetOp() = default;

  void dispatch(Dispatcher& dispatcher) const { dispatcher.transformReset(); }
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
      dispatcher.clip##shapetype(shape, SkClipOp::k##clipop, is_aa);       \
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
      dispatcher.clipPath(path, SkClipOp::k##clipop, is_aa);             \
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

  DrawColorOp(DlColor color, DlBlendMode mode) : color(color), mode(mode) {}

  const DlColor color;
  const DlBlendMode mode;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.drawColor(color, mode);
  }
};

// The common data is a 4 byte header with an unused 4 bytes
// SkRect is 16 more bytes, using 20 bytes which rounds up to 24 bytes total
//        (4 bytes unused)
// SkOval is same as SkRect
// SkRRect is 52 more bytes, which packs efficiently into 56 bytes total
#define DEFINE_DRAW_1ARG_OP(op_name, arg_type, arg_name)                  \
  struct Draw##op_name##Op final : DLOp {                                 \
    static const auto kType = DisplayListOpType::kDraw##op_name;          \
                                                                          \
    explicit Draw##op_name##Op(arg_type arg_name) : arg_name(arg_name) {} \
                                                                          \
    const arg_type arg_name;                                              \
                                                                          \
    void dispatch(Dispatcher& dispatcher) const {                         \
      dispatcher.draw##op_name(arg_name);                                 \
    }                                                                     \
  };
DEFINE_DRAW_1ARG_OP(Rect, SkRect, rect)
DEFINE_DRAW_1ARG_OP(Oval, SkRect, oval)
DEFINE_DRAW_1ARG_OP(RRect, SkRRect, rrect)
#undef DEFINE_DRAW_1ARG_OP

// 4 byte header + 16 byte payload uses 20 bytes but is rounded up to 24 bytes
// (4 bytes unused)
struct DrawPathOp final : DLOp {
  static const auto kType = DisplayListOpType::kDrawPath;

  explicit DrawPathOp(SkPath path) : path(path) {}

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
    explicit Draw##name##Op(uint32_t count) : count(count) {}          \
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

// 4 byte header + 4 byte payload packs efficiently into 8 bytes
// The DlVertices object will be pod-allocated after this structure
// and can take any number of bytes so the final efficiency will
// depend on the size of the DlVertices.
// Note that the DlVertices object ends with an array of 16-bit
// indices so the alignment can be up to 6 bytes off leading to
// up to 6 bytes of overhead
struct DrawVerticesOp final : DLOp {
  static const auto kType = DisplayListOpType::kDrawVertices;

  DrawVerticesOp(DlBlendMode mode) : mode(mode) {}

  const DlBlendMode mode;

  void dispatch(Dispatcher& dispatcher) const {
    const DlVertices* vertices = reinterpret_cast<const DlVertices*>(this + 1);
    dispatcher.drawVertices(vertices, mode);
  }
};

// 4 byte header + 12 byte payload packs efficiently into 16 bytes
struct DrawSkVerticesOp final : DLOp {
  static const auto kType = DisplayListOpType::kDrawSkVertices;

  DrawSkVerticesOp(sk_sp<SkVertices> vertices, SkBlendMode mode)
      : mode(mode), vertices(std::move(vertices)) {}

  const SkBlendMode mode;
  const sk_sp<SkVertices> vertices;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.drawSkVertices(vertices, mode);
  }
};

// 4 byte header + 40 byte payload uses 44 bytes but is rounded up to 48 bytes
// (4 bytes unused)
#define DEFINE_DRAW_IMAGE_OP(name, with_attributes)                    \
  struct name##Op final : DLOp {                                       \
    static const auto kType = DisplayListOpType::k##name;              \
                                                                       \
    name##Op(const sk_sp<DlImage> image,                               \
             const SkPoint& point,                                     \
             DlImageSampling sampling)                                 \
        : point(point), sampling(sampling), image(std::move(image)) {} \
                                                                       \
    const SkPoint point;                                               \
    const DlImageSampling sampling;                                    \
    const sk_sp<DlImage> image;                                        \
                                                                       \
    void dispatch(Dispatcher& dispatcher) const {                      \
      dispatcher.drawImage(image, point, sampling, with_attributes);   \
    }                                                                  \
  };
DEFINE_DRAW_IMAGE_OP(DrawImage, false)
DEFINE_DRAW_IMAGE_OP(DrawImageWithAttr, true)
#undef DEFINE_DRAW_IMAGE_OP

// 4 byte header + 72 byte payload uses 76 bytes but is rounded up to 80 bytes
// (4 bytes unused)
struct DrawImageRectOp final : DLOp {
  static const auto kType = DisplayListOpType::kDrawImageRect;

  DrawImageRectOp(const sk_sp<DlImage> image,
                  const SkRect& src,
                  const SkRect& dst,
                  DlImageSampling sampling,
                  bool render_with_attributes,
                  SkCanvas::SrcRectConstraint constraint)
      : src(src),
        dst(dst),
        sampling(sampling),
        render_with_attributes(render_with_attributes),
        constraint(constraint),
        image(std::move(image)) {}

  const SkRect src;
  const SkRect dst;
  const DlImageSampling sampling;
  const bool render_with_attributes;
  const SkCanvas::SrcRectConstraint constraint;
  const sk_sp<DlImage> image;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.drawImageRect(image, src, dst, sampling, render_with_attributes,
                             constraint);
  }
};

// 4 byte header + 44 byte payload packs efficiently into 48 bytes
#define DEFINE_DRAW_IMAGE_NINE_OP(name, render_with_attributes)                \
  struct name##Op final : DLOp {                                               \
    static const auto kType = DisplayListOpType::k##name;                      \
                                                                               \
    name##Op(const sk_sp<DlImage> image,                                       \
             const SkIRect& center,                                            \
             const SkRect& dst,                                                \
             DlFilterMode filter)                                              \
        : center(center), dst(dst), filter(filter), image(std::move(image)) {} \
                                                                               \
    const SkIRect center;                                                      \
    const SkRect dst;                                                          \
    const DlFilterMode filter;                                                 \
    const sk_sp<DlImage> image;                                                \
                                                                               \
    void dispatch(Dispatcher& dispatcher) const {                              \
      dispatcher.drawImageNine(image, center, dst, filter,                     \
                               render_with_attributes);                        \
    }                                                                          \
  };
DEFINE_DRAW_IMAGE_NINE_OP(DrawImageNine, false)
DEFINE_DRAW_IMAGE_NINE_OP(DrawImageNineWithAttr, true)
#undef DEFINE_DRAW_IMAGE_NINE_OP

// 4 byte header + 60 byte payload packs evenly into 64 bytes
struct DrawImageLatticeOp final : DLOp {
  static const auto kType = DisplayListOpType::kDrawImageLattice;

  DrawImageLatticeOp(const sk_sp<DlImage> image,
                     int x_count,
                     int y_count,
                     int cell_count,
                     const SkIRect& src,
                     const SkRect& dst,
                     DlFilterMode filter,
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
  const DlFilterMode filter;
  const SkIRect src;
  const SkRect dst;
  const sk_sp<DlImage> image;

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

// 4 byte header + 40 byte payload uses 44 bytes but is rounded up to 48 bytes
// (4 bytes unused)
// Each of these is then followed by a number of lists.
// SkRSXform list is a multiple of 16 bytes so it is always packed well
// SkRect list is also a multiple of 16 bytes so it also packs well
// DlColor list only packs well if the count is even, otherwise there
// can be 4 unusued bytes at the end.
struct DrawAtlasBaseOp : DLOp {
  DrawAtlasBaseOp(const sk_sp<DlImage> atlas,
                  int count,
                  DlBlendMode mode,
                  DlImageSampling sampling,
                  bool has_colors,
                  bool render_with_attributes)
      : count(count),
        mode_index(static_cast<uint16_t>(mode)),
        has_colors(has_colors),
        render_with_attributes(render_with_attributes),
        sampling(sampling),
        atlas(std::move(atlas)) {}

  const int count;
  const uint16_t mode_index;
  const uint8_t has_colors;
  const uint8_t render_with_attributes;
  const DlImageSampling sampling;
  const sk_sp<DlImage> atlas;
};

// Packs into 48 bytes as per DrawAtlasBaseOp
// with array data following the struct also as per DrawAtlasBaseOp
struct DrawAtlasOp final : DrawAtlasBaseOp {
  static const auto kType = DisplayListOpType::kDrawAtlas;

  DrawAtlasOp(const sk_sp<DlImage> atlas,
              int count,
              DlBlendMode mode,
              DlImageSampling sampling,
              bool has_colors,
              bool render_with_attributes)
      : DrawAtlasBaseOp(atlas,
                        count,
                        mode,
                        sampling,
                        has_colors,
                        render_with_attributes) {}

  void dispatch(Dispatcher& dispatcher) const {
    const SkRSXform* xform = reinterpret_cast<const SkRSXform*>(this + 1);
    const SkRect* tex = reinterpret_cast<const SkRect*>(xform + count);
    const DlColor* colors =
        has_colors ? reinterpret_cast<const DlColor*>(tex + count) : nullptr;
    const DlBlendMode mode = static_cast<DlBlendMode>(mode_index);
    dispatcher.drawAtlas(atlas, xform, tex, colors, count, mode, sampling,
                         nullptr, render_with_attributes);
  }
};

// Packs into 48 bytes as per DrawAtlasBaseOp plus
// an additional 16 bytes for the cull rect resulting in a total
// of 56 bytes for the Culled drawAtlas.
// Also with array data following the struct as per DrawAtlasBaseOp
struct DrawAtlasCulledOp final : DrawAtlasBaseOp {
  static const auto kType = DisplayListOpType::kDrawAtlasCulled;

  DrawAtlasCulledOp(const sk_sp<DlImage> atlas,
                    int count,
                    DlBlendMode mode,
                    DlImageSampling sampling,
                    bool has_colors,
                    const SkRect& cull_rect,
                    bool render_with_attributes)
      : DrawAtlasBaseOp(atlas,
                        count,
                        mode,
                        sampling,
                        has_colors,
                        render_with_attributes),
        cull_rect(cull_rect) {}

  const SkRect cull_rect;

  void dispatch(Dispatcher& dispatcher) const {
    const SkRSXform* xform = reinterpret_cast<const SkRSXform*>(this + 1);
    const SkRect* tex = reinterpret_cast<const SkRect*>(xform + count);
    const DlColor* colors =
        has_colors ? reinterpret_cast<const DlColor*>(tex + count) : nullptr;
    const DlBlendMode mode = static_cast<DlBlendMode>(mode_index);
    dispatcher.drawAtlas(atlas, xform, tex, colors, count, mode, sampling,
                         &cull_rect, render_with_attributes);
  }
};

// 4 byte header + 12 byte payload packs evenly into 16 bytes
struct DrawSkPictureOp final : DLOp {
  static const auto kType = DisplayListOpType::kDrawSkPicture;

  DrawSkPictureOp(sk_sp<SkPicture> picture, bool render_with_attributes)
      : render_with_attributes(render_with_attributes),
        picture(std::move(picture)) {}

  const bool render_with_attributes;
  const sk_sp<SkPicture> picture;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.drawPicture(picture, nullptr, render_with_attributes);
  }
};

// 4 byte header + 52 byte payload packs evenly into 56 bytes
struct DrawSkPictureMatrixOp final : DLOp {
  static const auto kType = DisplayListOpType::kDrawSkPictureMatrix;

  DrawSkPictureMatrixOp(sk_sp<SkPicture> picture,
                        const SkMatrix matrix,
                        bool render_with_attributes)
      : render_with_attributes(render_with_attributes),
        picture(std::move(picture)),
        matrix(matrix) {}

  const bool render_with_attributes;
  const sk_sp<SkPicture> picture;
  const SkMatrix matrix;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.drawPicture(picture, &matrix, render_with_attributes);
  }
};

// 4 byte header + ptr aligned payload uses 12 bytes round up to 16
// (4 bytes unused)
struct DrawDisplayListOp final : DLOp {
  static const auto kType = DisplayListOpType::kDrawDisplayList;

  explicit DrawDisplayListOp(const sk_sp<DisplayList> display_list)
      : display_list(std::move(display_list)) {}

  sk_sp<DisplayList> display_list;

  void dispatch(Dispatcher& dispatcher) const {
    dispatcher.drawDisplayList(display_list);
  }

  DisplayListCompare equals(const DrawDisplayListOp* other) const {
    return display_list->Equals(other->display_list)
               ? DisplayListCompare::kEqual
               : DisplayListCompare::kNotEqual;
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
#define DEFINE_DRAW_SHADOW_OP(name, transparent_occluder)                 \
  struct Draw##name##Op final : DLOp {                                    \
    static const auto kType = DisplayListOpType::kDraw##name;             \
                                                                          \
    Draw##name##Op(const SkPath& path,                                    \
                   DlColor color,                                         \
                   SkScalar elevation,                                    \
                   SkScalar dpr)                                          \
        : color(color), elevation(elevation), dpr(dpr), path(path) {}     \
                                                                          \
    const DlColor color;                                                  \
    const SkScalar elevation;                                             \
    const SkScalar dpr;                                                   \
    const SkPath path;                                                    \
                                                                          \
    void dispatch(Dispatcher& dispatcher) const {                         \
      dispatcher.drawShadow(path, color, elevation, transparent_occluder, \
                            dpr);                                         \
    }                                                                     \
  };
DEFINE_DRAW_SHADOW_OP(Shadow, false)
DEFINE_DRAW_SHADOW_OP(ShadowTransparentOccluder, true)
#undef DEFINE_DRAW_SHADOW_OP

#pragma pack(pop, DLOpPackLabel)

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DISPLAY_LIST_OPS_H_
