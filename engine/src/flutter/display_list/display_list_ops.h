// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DISPLAY_LIST_OPS_H_
#define FLUTTER_DISPLAY_LIST_DISPLAY_LIST_OPS_H_

#include "display_list_color_source.h"
#include "flutter/display_list/display_list.h"
#include "flutter/display_list/display_list_blend_mode.h"
#include "flutter/display_list/display_list_sampling_options.h"
#include "flutter/display_list/dl_op_receiver.h"
#include "flutter/display_list/types.h"
#include "flutter/fml/macros.h"

namespace flutter {

// Structure holding the information necessary to dispatch and
// potentially cull the DLOps during playback.
//
// Generally drawing ops will execute as long as |cur_index|
// is at or after |next_render_index|, so setting the latter
// to 0 will render all primitives and setting it to MAX_INT
// will skip all remaining rendering primitives.
//
// Save and saveLayer ops will execute as long as the next
// rendering index is before their closing restore index.
// They will also store their own restore index into the
// |next_restore_index| field for use by clip and transform ops.
//
// Clip and transform ops will only execute if the next
// render index is before the next restore index. Otherwise
// their modified state will not be used before it gets
// restored.
//
// Attribute ops always execute as they are too numerous and
// cheap to deal with a complicated "lifetime" tracking to
// determine if they will be used.
struct DispatchContext {
  DlOpReceiver& receiver;

  int cur_index;
  int next_render_index;

  int next_restore_index;

  struct SaveInfo {
    SaveInfo(int previous_restore_index, bool save_was_needed)
        : previous_restore_index(previous_restore_index),
          save_was_needed(save_was_needed) {}

    int previous_restore_index;
    bool save_was_needed;
  };

  std::vector<SaveInfo> save_infos;
};

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
    void dispatch(DispatchContext& ctx) const {              \
      ctx.receiver.set##name(value);                         \
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
    void dispatch(DispatchContext& ctx) const {                          \
      ctx.receiver.setStroke##name(value);                               \
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

  void dispatch(DispatchContext& ctx) const { ctx.receiver.setStyle(style); }
};
// 4 byte header + 4 byte payload packs into minimum 8 bytes
struct SetStrokeWidthOp final : DLOp {
  static const auto kType = DisplayListOpType::kSetStrokeWidth;

  explicit SetStrokeWidthOp(float width) : width(width) {}

  const float width;

  void dispatch(DispatchContext& ctx) const {
    ctx.receiver.setStrokeWidth(width);
  }
};
// 4 byte header + 4 byte payload packs into minimum 8 bytes
struct SetStrokeMiterOp final : DLOp {
  static const auto kType = DisplayListOpType::kSetStrokeMiter;

  explicit SetStrokeMiterOp(float limit) : limit(limit) {}

  const float limit;

  void dispatch(DispatchContext& ctx) const {
    ctx.receiver.setStrokeMiter(limit);
  }
};

// 4 byte header + 4 byte payload packs into minimum 8 bytes
struct SetColorOp final : DLOp {
  static const auto kType = DisplayListOpType::kSetColor;

  explicit SetColorOp(DlColor color) : color(color) {}

  const DlColor color;

  void dispatch(DispatchContext& ctx) const { ctx.receiver.setColor(color); }
};
// 4 byte header + 4 byte payload packs into minimum 8 bytes
struct SetBlendModeOp final : DLOp {
  static const auto kType = DisplayListOpType::kSetBlendMode;

  explicit SetBlendModeOp(DlBlendMode mode) : mode(mode) {}

  const DlBlendMode mode;

  void dispatch(DispatchContext& ctx) const {  //
    ctx.receiver.setBlendMode(mode);
  }
};

// Clear: 4 byte header + unused 4 byte payload uses 8 bytes
//        (4 bytes unused)
// Set: 4 byte header + unused 4 byte struct padding + Dl<name>
//      instance copied to the memory following the record
//      yields a size and efficiency that has somewhere between
//      4 and 8 bytes unused
#define DEFINE_SET_CLEAR_DLATTR_OP(name, sk_name, field)                    \
  struct Clear##name##Op final : DLOp {                                     \
    static const auto kType = DisplayListOpType::kClear##name;              \
                                                                            \
    Clear##name##Op() {}                                                    \
                                                                            \
    void dispatch(DispatchContext& ctx) const {                             \
      ctx.receiver.set##name(nullptr);                                      \
    }                                                                       \
  };                                                                        \
  struct SetPod##name##Op final : DLOp {                                    \
    static const auto kType = DisplayListOpType::kSetPod##name;             \
                                                                            \
    SetPod##name##Op() {}                                                   \
                                                                            \
    void dispatch(DispatchContext& ctx) const {                             \
      const Dl##name* filter = reinterpret_cast<const Dl##name*>(this + 1); \
      ctx.receiver.set##name(filter);                                       \
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

  void dispatch(DispatchContext& ctx) const {
    ctx.receiver.setColorSource(&source);
  }
};

// 56 bytes: 4 byte header, 4 byte padding, 8 for vtable, 8 * 2 for sk_sps, 24
// for the std::vector.
struct SetRuntimeEffectColorSourceOp : DLOp {
  static const auto kType = DisplayListOpType::kSetRuntimeEffectColorSource;

  SetRuntimeEffectColorSourceOp(const DlRuntimeEffectColorSource* source)
      : source(source->runtime_effect(),
               source->samplers(),
               source->uniform_data()) {}

  const DlRuntimeEffectColorSource source;

  void dispatch(DispatchContext& ctx) const {
    ctx.receiver.setColorSource(&source);
  }

  DisplayListCompare equals(const SetRuntimeEffectColorSourceOp* other) const {
    return (source == other->source) ? DisplayListCompare::kEqual
                                     : DisplayListCompare::kNotEqual;
  }
};

#ifdef IMPELLER_ENABLE_3D
struct SetSceneColorSourceOp : DLOp {
  static const auto kType = DisplayListOpType::kSetSceneColorSource;

  SetSceneColorSourceOp(const DlSceneColorSource* source)
      : source(source->scene_node(), source->camera_matrix()) {}

  const DlSceneColorSource source;

  void dispatch(DispatchContext& ctx) const {
    ctx.receiver.setColorSource(&source);
  }

  DisplayListCompare equals(const SetSceneColorSourceOp* other) const {
    return (source == other->source) ? DisplayListCompare::kEqual
                                     : DisplayListCompare::kNotEqual;
  }
};
#endif  // IMPELLER_ENABLE_3D

// 4 byte header + 16 byte payload uses 24 total bytes (4 bytes unused)
struct SetSharedImageFilterOp : DLOp {
  static const auto kType = DisplayListOpType::kSetSharedImageFilter;

  SetSharedImageFilterOp(const DlImageFilter* filter)
      : filter(filter->shared()) {}

  const std::shared_ptr<DlImageFilter> filter;

  void dispatch(DispatchContext& ctx) const {
    ctx.receiver.setImageFilter(filter.get());
  }

  DisplayListCompare equals(const SetSharedImageFilterOp* other) const {
    return Equals(filter, other->filter) ? DisplayListCompare::kEqual
                                         : DisplayListCompare::kNotEqual;
  }
};

// The base object for all save() and saveLayer() ops
// 4 byte header + 8 byte payload packs neatly into 16 bytes (4 bytes unused)
struct SaveOpBase : DLOp {
  SaveOpBase() : options(), restore_index(0) {}

  SaveOpBase(const SaveLayerOptions options)
      : options(options), restore_index(0) {}

  // options parameter is only used by saveLayer operations, but since
  // it packs neatly into the empty space created by laying out the 64-bit
  // offsets, it can be stored for free and defaulted to 0 for save operations.
  SaveLayerOptions options;
  int restore_index;

  inline bool save_needed(DispatchContext& ctx) const {
    bool needed = ctx.next_render_index <= restore_index;
    ctx.save_infos.emplace_back(ctx.next_restore_index, needed);
    ctx.next_restore_index = restore_index;
    return needed;
  }
};
// 24 byte SaveOpBase with no additional data (options is unsed here)
struct SaveOp final : SaveOpBase {
  static const auto kType = DisplayListOpType::kSave;

  SaveOp() : SaveOpBase() {}

  void dispatch(DispatchContext& ctx) const {
    if (save_needed(ctx)) {
      ctx.receiver.save();
    }
  }
};
// 16 byte SaveOpBase with no additional data
struct SaveLayerOp final : SaveOpBase {
  static const auto kType = DisplayListOpType::kSaveLayer;

  explicit SaveLayerOp(const SaveLayerOptions options) : SaveOpBase(options) {}

  void dispatch(DispatchContext& ctx) const {
    if (save_needed(ctx)) {
      ctx.receiver.saveLayer(nullptr, options);
    }
  }
};
// 24 byte SaveOpBase + 16 byte payload packs evenly into 40 bytes
struct SaveLayerBoundsOp final : SaveOpBase {
  static const auto kType = DisplayListOpType::kSaveLayerBounds;

  SaveLayerBoundsOp(const SaveLayerOptions options, const SkRect& rect)
      : SaveOpBase(options), rect(rect) {}

  const SkRect rect;

  void dispatch(DispatchContext& ctx) const {
    if (save_needed(ctx)) {
      ctx.receiver.saveLayer(&rect, options);
    }
  }
};
// 24 byte SaveOpBase + 16 byte payload packs into minimum 40 bytes
struct SaveLayerBackdropOp final : SaveOpBase {
  static const auto kType = DisplayListOpType::kSaveLayerBackdrop;

  explicit SaveLayerBackdropOp(const SaveLayerOptions options,
                               const DlImageFilter* backdrop)
      : SaveOpBase(options), backdrop(backdrop->shared()) {}

  const std::shared_ptr<DlImageFilter> backdrop;

  void dispatch(DispatchContext& ctx) const {
    if (save_needed(ctx)) {
      ctx.receiver.saveLayer(nullptr, options, backdrop.get());
    }
  }

  DisplayListCompare equals(const SaveLayerBackdropOp* other) const {
    return options == other->options && Equals(backdrop, other->backdrop)
               ? DisplayListCompare::kEqual
               : DisplayListCompare::kNotEqual;
  }
};
// 24 byte SaveOpBase + 32 byte payload packs into minimum 56 bytes
struct SaveLayerBackdropBoundsOp final : SaveOpBase {
  static const auto kType = DisplayListOpType::kSaveLayerBackdropBounds;

  SaveLayerBackdropBoundsOp(const SaveLayerOptions options,
                            const SkRect& rect,
                            const DlImageFilter* backdrop)
      : SaveOpBase(options), rect(rect), backdrop(backdrop->shared()) {}

  const SkRect rect;
  const std::shared_ptr<DlImageFilter> backdrop;

  void dispatch(DispatchContext& ctx) const {
    if (save_needed(ctx)) {
      ctx.receiver.saveLayer(&rect, options, backdrop.get());
    }
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

  void dispatch(DispatchContext& ctx) const {
    DispatchContext::SaveInfo& info = ctx.save_infos.back();
    if (info.save_was_needed) {
      ctx.receiver.restore();
    }
    ctx.next_restore_index = info.previous_restore_index;
    ctx.save_infos.pop_back();
  }
};

struct TransformClipOpBase : DLOp {
  inline bool op_needed(const DispatchContext& context) const {
    return context.next_render_index <= context.next_restore_index;
  }
};
// 4 byte header + 8 byte payload uses 12 bytes but is rounded up to 16 bytes
// (4 bytes unused)
struct TranslateOp final : TransformClipOpBase {
  static const auto kType = DisplayListOpType::kTranslate;

  TranslateOp(SkScalar tx, SkScalar ty) : tx(tx), ty(ty) {}

  const SkScalar tx;
  const SkScalar ty;

  void dispatch(DispatchContext& ctx) const {
    if (op_needed(ctx)) {
      ctx.receiver.translate(tx, ty);
    }
  }
};
// 4 byte header + 8 byte payload uses 12 bytes but is rounded up to 16 bytes
// (4 bytes unused)
struct ScaleOp final : TransformClipOpBase {
  static const auto kType = DisplayListOpType::kScale;

  ScaleOp(SkScalar sx, SkScalar sy) : sx(sx), sy(sy) {}

  const SkScalar sx;
  const SkScalar sy;

  void dispatch(DispatchContext& ctx) const {
    if (op_needed(ctx)) {
      ctx.receiver.scale(sx, sy);
    }
  }
};
// 4 byte header + 4 byte payload packs into minimum 8 bytes
struct RotateOp final : TransformClipOpBase {
  static const auto kType = DisplayListOpType::kRotate;

  explicit RotateOp(SkScalar degrees) : degrees(degrees) {}

  const SkScalar degrees;

  void dispatch(DispatchContext& ctx) const {
    if (op_needed(ctx)) {
      ctx.receiver.rotate(degrees);
    }
  }
};
// 4 byte header + 8 byte payload uses 12 bytes but is rounded up to 16 bytes
// (4 bytes unused)
struct SkewOp final : TransformClipOpBase {
  static const auto kType = DisplayListOpType::kSkew;

  SkewOp(SkScalar sx, SkScalar sy) : sx(sx), sy(sy) {}

  const SkScalar sx;
  const SkScalar sy;

  void dispatch(DispatchContext& ctx) const {
    if (op_needed(ctx)) {
      ctx.receiver.skew(sx, sy);
    }
  }
};
// 4 byte header + 24 byte payload uses 28 bytes but is rounded up to 32 bytes
// (4 bytes unused)
struct Transform2DAffineOp final : TransformClipOpBase {
  static const auto kType = DisplayListOpType::kTransform2DAffine;

  // clang-format off
  Transform2DAffineOp(SkScalar mxx, SkScalar mxy, SkScalar mxt,
                      SkScalar myx, SkScalar myy, SkScalar myt)
      : mxx(mxx), mxy(mxy), mxt(mxt), myx(myx), myy(myy), myt(myt) {}
  // clang-format on

  const SkScalar mxx, mxy, mxt;
  const SkScalar myx, myy, myt;

  void dispatch(DispatchContext& ctx) const {
    if (op_needed(ctx)) {
      ctx.receiver.transform2DAffine(mxx, mxy, mxt,  //
                                     myx, myy, myt);
    }
  }
};
// 4 byte header + 64 byte payload uses 68 bytes which is rounded up to 72 bytes
// (4 bytes unused)
struct TransformFullPerspectiveOp final : TransformClipOpBase {
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

  void dispatch(DispatchContext& ctx) const {
    if (op_needed(ctx)) {
      ctx.receiver.transformFullPerspective(mxx, mxy, mxz, mxt,  //
                                            myx, myy, myz, myt,  //
                                            mzx, mzy, mzz, mzt,  //
                                            mwx, mwy, mwz, mwt);
    }
  }
};

// 4 byte header with no payload.
struct TransformResetOp final : TransformClipOpBase {
  static const auto kType = DisplayListOpType::kTransformReset;

  TransformResetOp() = default;

  void dispatch(DispatchContext& ctx) const {
    if (op_needed(ctx)) {
      ctx.receiver.transformReset();
    }
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
  struct Clip##clipop##shapetype##Op final : TransformClipOpBase {         \
    static const auto kType = DisplayListOpType::kClip##clipop##shapetype; \
                                                                           \
    Clip##clipop##shapetype##Op(Sk##shapetype shape, bool is_aa)           \
        : is_aa(is_aa), shape(shape) {}                                    \
                                                                           \
    const bool is_aa;                                                      \
    const Sk##shapetype shape;                                             \
                                                                           \
    void dispatch(DispatchContext& ctx) const {                            \
      if (op_needed(ctx)) {                                                \
        ctx.receiver.clip##shapetype(shape, DlCanvas::ClipOp::k##clipop,   \
                                     is_aa);                               \
      }                                                                    \
    }                                                                      \
  };
DEFINE_CLIP_SHAPE_OP(Rect, Intersect)
DEFINE_CLIP_SHAPE_OP(RRect, Intersect)
DEFINE_CLIP_SHAPE_OP(Rect, Difference)
DEFINE_CLIP_SHAPE_OP(RRect, Difference)
#undef DEFINE_CLIP_SHAPE_OP

#define DEFINE_CLIP_PATH_OP(clipop)                                      \
  struct Clip##clipop##PathOp final : TransformClipOpBase {              \
    static const auto kType = DisplayListOpType::kClip##clipop##Path;    \
                                                                         \
    Clip##clipop##PathOp(SkPath path, bool is_aa)                        \
        : is_aa(is_aa), path(path) {}                                    \
                                                                         \
    const bool is_aa;                                                    \
    const SkPath path;                                                   \
                                                                         \
    void dispatch(DispatchContext& ctx) const {                          \
      if (op_needed(ctx)) {                                              \
        ctx.receiver.clipPath(path, DlCanvas::ClipOp::k##clipop, is_aa); \
      }                                                                  \
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

struct DrawOpBase : DLOp {
  inline bool op_needed(const DispatchContext& ctx) const {
    return ctx.cur_index >= ctx.next_render_index;
  }
};

// 4 byte header + no payload uses minimum 8 bytes (4 bytes unused)
struct DrawPaintOp final : DrawOpBase {
  static const auto kType = DisplayListOpType::kDrawPaint;

  DrawPaintOp() {}

  void dispatch(DispatchContext& ctx) const {
    if (op_needed(ctx)) {
      ctx.receiver.drawPaint();
    }
  }
};
// 4 byte header + 8 byte payload uses 12 bytes but is rounded up to 16 bytes
// (4 bytes unused)
struct DrawColorOp final : DrawOpBase {
  static const auto kType = DisplayListOpType::kDrawColor;

  DrawColorOp(DlColor color, DlBlendMode mode) : color(color), mode(mode) {}

  const DlColor color;
  const DlBlendMode mode;

  void dispatch(DispatchContext& ctx) const {
    if (op_needed(ctx)) {
      ctx.receiver.drawColor(color, mode);
    }
  }
};

// The common data is a 4 byte header with an unused 4 bytes
// SkRect is 16 more bytes, using 20 bytes which rounds up to 24 bytes total
//        (4 bytes unused)
// SkOval is same as SkRect
// SkRRect is 52 more bytes, which packs efficiently into 56 bytes total
#define DEFINE_DRAW_1ARG_OP(op_name, arg_type, arg_name)                  \
  struct Draw##op_name##Op final : DrawOpBase {                           \
    static const auto kType = DisplayListOpType::kDraw##op_name;          \
                                                                          \
    explicit Draw##op_name##Op(arg_type arg_name) : arg_name(arg_name) {} \
                                                                          \
    const arg_type arg_name;                                              \
                                                                          \
    void dispatch(DispatchContext& ctx) const {                           \
      if (op_needed(ctx)) {                                               \
        ctx.receiver.draw##op_name(arg_name);                             \
      }                                                                   \
    }                                                                     \
  };
DEFINE_DRAW_1ARG_OP(Rect, SkRect, rect)
DEFINE_DRAW_1ARG_OP(Oval, SkRect, oval)
DEFINE_DRAW_1ARG_OP(RRect, SkRRect, rrect)
#undef DEFINE_DRAW_1ARG_OP

// 4 byte header + 16 byte payload uses 20 bytes but is rounded up to 24 bytes
// (4 bytes unused)
struct DrawPathOp final : DrawOpBase {
  static const auto kType = DisplayListOpType::kDrawPath;

  explicit DrawPathOp(SkPath path) : path(path) {}

  const SkPath path;

  void dispatch(DispatchContext& ctx) const {
    if (op_needed(ctx)) {
      ctx.receiver.drawPath(path);
    }
  }

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
  struct Draw##op_name##Op final : DrawOpBase {                  \
    static const auto kType = DisplayListOpType::kDraw##op_name; \
                                                                 \
    Draw##op_name##Op(type1 name1, type2 name2)                  \
        : name1(name1), name2(name2) {}                          \
                                                                 \
    const type1 name1;                                           \
    const type2 name2;                                           \
                                                                 \
    void dispatch(DispatchContext& ctx) const {                  \
      if (op_needed(ctx)) {                                      \
        ctx.receiver.draw##op_name(name1, name2);                \
      }                                                          \
    }                                                            \
  };
DEFINE_DRAW_2ARG_OP(Line, SkPoint, p0, SkPoint, p1)
DEFINE_DRAW_2ARG_OP(Circle, SkPoint, center, SkScalar, radius)
DEFINE_DRAW_2ARG_OP(DRRect, SkRRect, outer, SkRRect, inner)
#undef DEFINE_DRAW_2ARG_OP

// 4 byte header + 28 byte payload packs efficiently into 32 bytes
struct DrawArcOp final : DrawOpBase {
  static const auto kType = DisplayListOpType::kDrawArc;

  DrawArcOp(SkRect bounds, SkScalar start, SkScalar sweep, bool center)
      : bounds(bounds), start(start), sweep(sweep), center(center) {}

  const SkRect bounds;
  const SkScalar start;
  const SkScalar sweep;
  const bool center;

  void dispatch(DispatchContext& ctx) const {
    if (op_needed(ctx)) {
      ctx.receiver.drawArc(bounds, start, sweep, center);
    }
  }
};

// 4 byte header + 4 byte fixed payload packs efficiently into 8 bytes
// But then there is a list of points following the structure which
// is guaranteed to be a multiple of 8 bytes (SkPoint is 8 bytes)
// so this op will always pack efficiently
// The point type is packed into 3 different OpTypes to avoid expanding
// the fixed payload beyond the 8 bytes
#define DEFINE_DRAW_POINTS_OP(name, mode)                                \
  struct Draw##name##Op final : DrawOpBase {                             \
    static const auto kType = DisplayListOpType::kDraw##name;            \
                                                                         \
    explicit Draw##name##Op(uint32_t count) : count(count) {}            \
                                                                         \
    const uint32_t count;                                                \
                                                                         \
    void dispatch(DispatchContext& ctx) const {                          \
      if (op_needed(ctx)) {                                              \
        const SkPoint* pts = reinterpret_cast<const SkPoint*>(this + 1); \
        ctx.receiver.drawPoints(DlCanvas::PointMode::mode, count, pts);  \
      }                                                                  \
    }                                                                    \
  };
DEFINE_DRAW_POINTS_OP(Points, kPoints);
DEFINE_DRAW_POINTS_OP(Lines, kLines);
DEFINE_DRAW_POINTS_OP(Polygon, kPolygon);
#undef DEFINE_DRAW_POINTS_OP

// 4 byte header + 4 byte payload packs efficiently into 8 bytes
// The DlVertices object will be pod-allocated after this structure
// and can take any number of bytes so the final efficiency will
// depend on the size of the DlVertices.
// Note that the DlVertices object ends with an array of 16-bit
// indices so the alignment can be up to 6 bytes off leading to
// up to 6 bytes of overhead
struct DrawVerticesOp final : DrawOpBase {
  static const auto kType = DisplayListOpType::kDrawVertices;

  DrawVerticesOp(DlBlendMode mode) : mode(mode) {}

  const DlBlendMode mode;

  void dispatch(DispatchContext& ctx) const {
    if (op_needed(ctx)) {
      const DlVertices* vertices =
          reinterpret_cast<const DlVertices*>(this + 1);
      ctx.receiver.drawVertices(vertices, mode);
    }
  }
};

// 4 byte header + 40 byte payload uses 44 bytes but is rounded up to 48 bytes
// (4 bytes unused)
#define DEFINE_DRAW_IMAGE_OP(name, with_attributes)                      \
  struct name##Op final : DrawOpBase {                                   \
    static const auto kType = DisplayListOpType::k##name;                \
                                                                         \
    name##Op(const sk_sp<DlImage> image,                                 \
             const SkPoint& point,                                       \
             DlImageSampling sampling)                                   \
        : point(point), sampling(sampling), image(std::move(image)) {}   \
                                                                         \
    const SkPoint point;                                                 \
    const DlImageSampling sampling;                                      \
    const sk_sp<DlImage> image;                                          \
                                                                         \
    void dispatch(DispatchContext& ctx) const {                          \
      if (op_needed(ctx)) {                                              \
        ctx.receiver.drawImage(image, point, sampling, with_attributes); \
      }                                                                  \
    }                                                                    \
                                                                         \
    DisplayListCompare equals(const name##Op* other) const {             \
      return (point == other->point && sampling == other->sampling &&    \
              image->Equals(other->image))                               \
                 ? DisplayListCompare::kEqual                            \
                 : DisplayListCompare::kNotEqual;                        \
    }                                                                    \
  };
DEFINE_DRAW_IMAGE_OP(DrawImage, false)
DEFINE_DRAW_IMAGE_OP(DrawImageWithAttr, true)
#undef DEFINE_DRAW_IMAGE_OP

// 4 byte header + 72 byte payload uses 76 bytes but is rounded up to 80 bytes
// (4 bytes unused)
struct DrawImageRectOp final : DrawOpBase {
  static const auto kType = DisplayListOpType::kDrawImageRect;

  DrawImageRectOp(const sk_sp<DlImage> image,
                  const SkRect& src,
                  const SkRect& dst,
                  DlImageSampling sampling,
                  bool render_with_attributes,
                  bool enforce_src_edges)
      : src(src),
        dst(dst),
        sampling(sampling),
        render_with_attributes(render_with_attributes),
        enforce_src_edges(enforce_src_edges),
        image(std::move(image)) {}

  const SkRect src;
  const SkRect dst;
  const DlImageSampling sampling;
  const bool render_with_attributes;
  const bool enforce_src_edges;
  const sk_sp<DlImage> image;

  void dispatch(DispatchContext& ctx) const {
    if (op_needed(ctx)) {
      ctx.receiver.drawImageRect(image, src, dst, sampling,
                                 render_with_attributes, enforce_src_edges);
    }
  }

  DisplayListCompare equals(const DrawImageRectOp* other) const {
    return (src == other->src && dst == other->dst &&
            sampling == other->sampling &&
            render_with_attributes == other->render_with_attributes &&
            enforce_src_edges == other->enforce_src_edges &&
            image->Equals(other->image))
               ? DisplayListCompare::kEqual
               : DisplayListCompare::kNotEqual;
  }
};

// 4 byte header + 44 byte payload packs efficiently into 48 bytes
#define DEFINE_DRAW_IMAGE_NINE_OP(name, render_with_attributes)            \
  struct name##Op final : DrawOpBase {                                     \
    static const auto kType = DisplayListOpType::k##name;                  \
                                                                           \
    name##Op(const sk_sp<DlImage> image,                                   \
             const SkIRect& center,                                        \
             const SkRect& dst,                                            \
             DlFilterMode mode)                                            \
        : center(center), dst(dst), mode(mode), image(std::move(image)) {} \
                                                                           \
    const SkIRect center;                                                  \
    const SkRect dst;                                                      \
    const DlFilterMode mode;                                               \
    const sk_sp<DlImage> image;                                            \
                                                                           \
    void dispatch(DispatchContext& ctx) const {                            \
      if (op_needed(ctx)) {                                                \
        ctx.receiver.drawImageNine(image, center, dst, mode,               \
                                   render_with_attributes);                \
      }                                                                    \
    }                                                                      \
                                                                           \
    DisplayListCompare equals(const name##Op* other) const {               \
      return (center == other->center && dst == other->dst &&              \
              mode == other->mode && image->Equals(other->image))          \
                 ? DisplayListCompare::kEqual                              \
                 : DisplayListCompare::kNotEqual;                          \
    }                                                                      \
  };
DEFINE_DRAW_IMAGE_NINE_OP(DrawImageNine, false)
DEFINE_DRAW_IMAGE_NINE_OP(DrawImageNineWithAttr, true)
#undef DEFINE_DRAW_IMAGE_NINE_OP

// 4 byte header + 40 byte payload uses 44 bytes but is rounded up to 48 bytes
// (4 bytes unused)
// Each of these is then followed by a number of lists.
// SkRSXform list is a multiple of 16 bytes so it is always packed well
// SkRect list is also a multiple of 16 bytes so it also packs well
// DlColor list only packs well if the count is even, otherwise there
// can be 4 unusued bytes at the end.
struct DrawAtlasBaseOp : DrawOpBase {
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

  bool equals(const DrawAtlasBaseOp* other,
              const void* pod_this,
              const void* pod_other) const {
    bool ret = (count == other->count && mode_index == other->mode_index &&
                has_colors == other->has_colors &&
                render_with_attributes == other->render_with_attributes &&
                sampling == other->sampling && atlas->Equals(other->atlas));
    if (ret) {
      size_t bytes = count * (sizeof(SkRSXform) + sizeof(SkRect));
      if (has_colors) {
        bytes += count * sizeof(DlColor);
      }
      ret = (memcmp(pod_this, pod_other, bytes) == 0);
    }
    return ret;
  }
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

  void dispatch(DispatchContext& ctx) const {
    if (op_needed(ctx)) {
      const SkRSXform* xform = reinterpret_cast<const SkRSXform*>(this + 1);
      const SkRect* tex = reinterpret_cast<const SkRect*>(xform + count);
      const DlColor* colors =
          has_colors ? reinterpret_cast<const DlColor*>(tex + count) : nullptr;
      const DlBlendMode mode = static_cast<DlBlendMode>(mode_index);
      ctx.receiver.drawAtlas(atlas, xform, tex, colors, count, mode, sampling,
                             nullptr, render_with_attributes);
    }
  }

  DisplayListCompare equals(const DrawAtlasOp* other) const {
    const void* pod_this = reinterpret_cast<const void*>(this + 1);
    const void* pod_other = reinterpret_cast<const void*>(other + 1);
    return (DrawAtlasBaseOp::equals(other, pod_this, pod_other))
               ? DisplayListCompare::kEqual
               : DisplayListCompare::kNotEqual;
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

  void dispatch(DispatchContext& ctx) const {
    if (op_needed(ctx)) {
      const SkRSXform* xform = reinterpret_cast<const SkRSXform*>(this + 1);
      const SkRect* tex = reinterpret_cast<const SkRect*>(xform + count);
      const DlColor* colors =
          has_colors ? reinterpret_cast<const DlColor*>(tex + count) : nullptr;
      const DlBlendMode mode = static_cast<DlBlendMode>(mode_index);
      ctx.receiver.drawAtlas(atlas, xform, tex, colors, count, mode, sampling,
                             &cull_rect, render_with_attributes);
    }
  }

  DisplayListCompare equals(const DrawAtlasCulledOp* other) const {
    const void* pod_this = reinterpret_cast<const void*>(this + 1);
    const void* pod_other = reinterpret_cast<const void*>(other + 1);
    return (cull_rect == other->cull_rect &&
            DrawAtlasBaseOp::equals(other, pod_this, pod_other))
               ? DisplayListCompare::kEqual
               : DisplayListCompare::kNotEqual;
  }
};

// 4 byte header + ptr aligned payload uses 12 bytes round up to 16
// (4 bytes unused)
struct DrawDisplayListOp final : DrawOpBase {
  static const auto kType = DisplayListOpType::kDrawDisplayList;

  explicit DrawDisplayListOp(const sk_sp<DisplayList> display_list,
                             SkScalar opacity)
      : opacity(opacity), display_list(std::move(display_list)) {}

  SkScalar opacity;
  const sk_sp<DisplayList> display_list;

  void dispatch(DispatchContext& ctx) const {
    if (op_needed(ctx)) {
      ctx.receiver.drawDisplayList(display_list, opacity);
    }
  }

  DisplayListCompare equals(const DrawDisplayListOp* other) const {
    return (opacity == other->opacity &&
            display_list->Equals(other->display_list))
               ? DisplayListCompare::kEqual
               : DisplayListCompare::kNotEqual;
  }
};

// 4 byte header + 8 payload bytes + an aligned pointer take 24 bytes
// (4 unused to align the pointer)
struct DrawTextBlobOp final : DrawOpBase {
  static const auto kType = DisplayListOpType::kDrawTextBlob;

  DrawTextBlobOp(const sk_sp<SkTextBlob> blob, SkScalar x, SkScalar y)
      : x(x), y(y), blob(std::move(blob)) {}

  const SkScalar x;
  const SkScalar y;
  const sk_sp<SkTextBlob> blob;

  void dispatch(DispatchContext& ctx) const {
    if (op_needed(ctx)) {
      ctx.receiver.drawTextBlob(blob, x, y);
    }
  }
};

// 4 byte header + 28 byte payload packs evenly into 32 bytes
#define DEFINE_DRAW_SHADOW_OP(name, transparent_occluder)                     \
  struct Draw##name##Op final : DrawOpBase {                                  \
    static const auto kType = DisplayListOpType::kDraw##name;                 \
                                                                              \
    Draw##name##Op(const SkPath& path,                                        \
                   DlColor color,                                             \
                   SkScalar elevation,                                        \
                   SkScalar dpr)                                              \
        : color(color), elevation(elevation), dpr(dpr), path(path) {}         \
                                                                              \
    const DlColor color;                                                      \
    const SkScalar elevation;                                                 \
    const SkScalar dpr;                                                       \
    const SkPath path;                                                        \
                                                                              \
    void dispatch(DispatchContext& ctx) const {                               \
      if (op_needed(ctx)) {                                                   \
        ctx.receiver.drawShadow(path, color, elevation, transparent_occluder, \
                                dpr);                                         \
      }                                                                       \
    }                                                                         \
  };
DEFINE_DRAW_SHADOW_OP(Shadow, false)
DEFINE_DRAW_SHADOW_OP(ShadowTransparentOccluder, true)
#undef DEFINE_DRAW_SHADOW_OP

#pragma pack(pop, DLOpPackLabel)

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DISPLAY_LIST_OPS_H_
