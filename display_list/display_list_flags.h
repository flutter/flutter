// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_DISPLAY_LIST_FLAGS_H_
#define FLUTTER_DISPLAY_LIST_DISPLAY_LIST_FLAGS_H_

#include "flutter/display_list/display_list_paint.h"
#include "flutter/display_list/types.h"
#include "flutter/fml/logging.h"

namespace flutter {

class DlPathEffect;
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
  explicit constexpr DisplayListFlagsBase(int flags) : flags_(flags) {}

  const int flags_;

  constexpr bool has_any(int qFlags) const { return (flags_ & qFlags) != 0; }
  constexpr bool has_all(int qFlags) const {
    return (flags_ & qFlags) == qFlags;
  }
  constexpr bool has_none(int qFlags) const { return (flags_ & qFlags) == 0; }
};

/// An attribute class for advertising specific properties of
/// a geometric attribute that can affect the computation of
/// the bounds of the primitive.
class DisplayListSpecialGeometryFlags : DisplayListFlagsBase {
 public:
  /// The geometry may have segments that end without closing the path.
  constexpr bool may_have_end_caps() const { return has_any(kMayHaveCaps_); }

  /// The geometry may have segments connect non-continuously.
  constexpr bool may_have_joins() const { return has_any(kMayHaveJoins_); }

  /// Mainly for drawPoints(PointMode) where Butt caps are rendered as squares.
  constexpr bool butt_cap_becomes_square() const {
    return has_any(kButtCapIsSquare_);
  }

  /// The geometry may have segments that end on a diagonal
  /// such that their end caps extend further than the default
  /// |strokeWidth * 0.5| margin around the geometry.
  constexpr bool may_have_diagonal_caps() const {
    return has_any(kMayHaveDiagonalCaps_);
  }

  /// The geometry may have segments that meet at vertices at
  /// an acute angle such that the miter joins will extend
  /// further than the default |strokeWidth * 0.5| margin around
  /// the geometry.
  constexpr bool may_have_acute_joins() const {
    return has_any(kMayHaveAcuteJoins_);
  }

 private:
  explicit constexpr DisplayListSpecialGeometryFlags(int flags)
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
      const DlPathEffect* effect) const;

  constexpr bool ignores_paint() const { return has_any(kIgnoresPaint_); }

  constexpr bool applies_anti_alias() const { return has_any(kUsesAntiAlias_); }
  constexpr bool applies_dither() const { return has_any(kUsesDither_); }
  constexpr bool applies_color() const { return has_any(kUsesColor_); }
  constexpr bool applies_alpha() const { return has_any(kUsesAlpha_); }
  constexpr bool applies_alpha_or_color() const {
    return has_any(kUsesAlpha_ | kUsesColor_);
  }

  /// The primitive dynamically determines whether it is a stroke or fill
  /// operation (or both) based on the setting of the |Style| attribute.
  constexpr bool applies_style() const { return has_any(kIsDrawnGeometry_); }
  /// The primitive can use any of the stroke attributes, such as
  /// StrokeWidth, StrokeMiter, StrokeCap, or StrokeJoin. This
  /// method will return if the primitive is defined as one that
  /// strokes its geometry (such as |drawLine|) or if it is defined
  /// as one that honors the Style attribute. If the Style attribute
  /// is known then a more accurate answer can be returned from
  /// the |is_stroked| method by supplying the actual setting of
  /// the style.
  // bool applies_stroke_attributes() const { return is_stroked(); }

  constexpr bool applies_shader() const { return has_any(kUsesShader_); }
  /// The primitive honors the current DlColorFilter, including
  /// the related attribute InvertColors
  constexpr bool applies_color_filter() const {
    return has_any(kUsesColorFilter_);
  }
  /// The primitive honors the DlBlendMode
  constexpr bool applies_blend() const { return has_any(kUsesBlend_); }
  constexpr bool applies_path_effect() const {
    return has_any(kUsesPathEffect_);
  }
  /// The primitive honors the DlMaskFilter whether set using the
  /// filter object or using the convenience method |setMaskBlurFilter|
  constexpr bool applies_mask_filter() const {
    return has_any(kUsesMaskFilter_);
  }
  constexpr bool applies_image_filter() const {
    return has_any(kUsesImageFilter_);
  }

  constexpr bool is_geometric() const { return has_any(kIsAnyGeometryMask_); }
  constexpr bool always_stroked() const { return has_any(kIsStrokedGeometry_); }
  constexpr bool is_stroked(DlDrawStyle style = DlDrawStyle::kStroke) const {
    return (has_any(kIsStrokedGeometry_) ||
            (style != DlDrawStyle::kFill && has_any(kIsDrawnGeometry_)));
  }

  constexpr bool is_flood() const { return has_any(kFloodsSurface_); }

  constexpr bool operator==(DisplayListAttributeFlags const& other) const {
    return flags_ == other.flags_;
  }

 private:
  explicit constexpr DisplayListAttributeFlags(int flags)
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

  constexpr DisplayListAttributeFlags operator+(int extra) const {
    return extra == 0 ? *this : DisplayListAttributeFlags(flags_ | extra);
  }

  constexpr DisplayListAttributeFlags operator-(int remove) const {
    FML_DCHECK(has_all(remove));
    return DisplayListAttributeFlags(flags_ & ~remove);
  }

  const DisplayListSpecialGeometryFlags special_flags_;

  friend class DisplayListOpFlags;
};

class DisplayListOpFlags : DisplayListFlags {
 private:
  // Flags common to all primitives that apply colors
  static constexpr int kBASE_PaintFlags_ = (kUsesDither_ |       //
                                            kUsesColor_ |        //
                                            kUsesAlpha_ |        //
                                            kUsesBlend_ |        //
                                            kUsesShader_ |       //
                                            kUsesColorFilter_ |  //
                                            kUsesImageFilter_);

  // Flags common to all primitives that stroke or fill
  static constexpr int kBASE_StrokeOrFillFlags_ = (kIsDrawnGeometry_ |  //
                                                   kUsesAntiAlias_ |    //
                                                   kUsesMaskFilter_ |   //
                                                   kUsesPathEffect_);

  // Flags common to primitives that stroke geometry
  static constexpr int kBASE_StrokeFlags_ = (kIsStrokedGeometry_ |  //
                                             kUsesAntiAlias_ |      //
                                             kUsesMaskFilter_ |     //
                                             kUsesPathEffect_);

  // Flags common to primitives that render an image with paint attributes
  static constexpr int kBASE_ImageFlags_ = (kIsNonGeometric_ |   //
                                            kUsesAlpha_ |        //
                                            kUsesDither_ |       //
                                            kUsesBlend_ |        //
                                            kUsesColorFilter_ |  //
                                            kUsesImageFilter_);

 public:
  static constexpr DisplayListAttributeFlags kSaveLayerFlags{
      kIgnoresPaint_  //
  };
  static constexpr DisplayListAttributeFlags kSaveLayerWithPaintFlags{
      kIsNonGeometric_ |   //
      kUsesAlpha_ |        //
      kUsesBlend_ |        //
      kUsesColorFilter_ |  //
      kUsesImageFilter_    //
  };
  static constexpr DisplayListAttributeFlags kDrawColorFlags{
      kFloodsSurface_ |  //
      kIgnoresPaint_     //
  };
  static constexpr DisplayListAttributeFlags kDrawPaintFlags{
      kBASE_PaintFlags_ |  //
      kFloodsSurface_      //
  };
  // Special case flags for horizonal and vertical lines
  static constexpr DisplayListAttributeFlags kDrawHVLineFlags{
      kBASE_PaintFlags_ |   //
      kBASE_StrokeFlags_ |  //
      kMayHaveCaps_         //
  };
  static constexpr DisplayListAttributeFlags kDrawLineFlags{
      kDrawHVLineFlags         //
      + kMayHaveDiagonalCaps_  //
  };
  static constexpr DisplayListAttributeFlags kDrawRectFlags{
      kBASE_PaintFlags_ |         //
      kBASE_StrokeOrFillFlags_ |  //
      kMayHaveJoins_              //
  };
  static constexpr DisplayListAttributeFlags kDrawOvalFlags{
      kBASE_PaintFlags_ |       //
      kBASE_StrokeOrFillFlags_  //
  };
  static constexpr DisplayListAttributeFlags kDrawCircleFlags{
      kBASE_PaintFlags_ |       //
      kBASE_StrokeOrFillFlags_  //
  };
  static constexpr DisplayListAttributeFlags kDrawRRectFlags{
      kBASE_PaintFlags_ |       //
      kBASE_StrokeOrFillFlags_  //
  };
  static constexpr DisplayListAttributeFlags kDrawDRRectFlags{
      kBASE_PaintFlags_ |       //
      kBASE_StrokeOrFillFlags_  //
  };
  static constexpr DisplayListAttributeFlags kDrawPathFlags{
      kBASE_PaintFlags_ |         //
      kBASE_StrokeOrFillFlags_ |  //
      kMayHaveCaps_ |             //
      kMayHaveDiagonalCaps_ |     //
      kMayHaveJoins_ |            //
      kMayHaveAcuteJoins_         //
  };
  static constexpr DisplayListAttributeFlags kDrawArcNoCenterFlags{
      kBASE_PaintFlags_ |         //
      kBASE_StrokeOrFillFlags_ |  //
      kMayHaveCaps_ |             //
      kMayHaveDiagonalCaps_       //
  };
  static constexpr DisplayListAttributeFlags kDrawArcWithCenterFlags{
      kBASE_PaintFlags_ |         //
      kBASE_StrokeOrFillFlags_ |  //
      kMayHaveJoins_ |            //
      kMayHaveAcuteJoins_         //
  };
  static constexpr DisplayListAttributeFlags kDrawPointsAsPointsFlags{
      kBASE_PaintFlags_ |   //
      kBASE_StrokeFlags_ |  //
      kMayHaveCaps_ |       //
      kButtCapIsSquare_     //
  };
  static constexpr DisplayListAttributeFlags kDrawPointsAsLinesFlags{
      kBASE_PaintFlags_ |    //
      kBASE_StrokeFlags_ |   //
      kMayHaveCaps_ |        //
      kMayHaveDiagonalCaps_  //
  };
  // Polygon mode just draws (count-1) separate lines, no joins
  static constexpr DisplayListAttributeFlags kDrawPointsAsPolygonFlags{
      kBASE_PaintFlags_ |    //
      kBASE_StrokeFlags_ |   //
      kMayHaveCaps_ |        //
      kMayHaveDiagonalCaps_  //
  };
  static constexpr DisplayListAttributeFlags kDrawVerticesFlags{
      kIsNonGeometric_ |   //
      kUsesDither_ |       //
      kUsesAlpha_ |        //
      kUsesShader_ |       //
      kUsesBlend_ |        //
      kUsesColorFilter_ |  //
      kUsesImageFilter_    //
  };
  static constexpr DisplayListAttributeFlags kDrawImageFlags{
      kIgnoresPaint_  //
  };
  static constexpr DisplayListAttributeFlags kDrawImageWithPaintFlags{
      kBASE_ImageFlags_ |  //
      kUsesAntiAlias_ |    //
      kUsesMaskFilter_     //
  };
  static constexpr DisplayListAttributeFlags kDrawImageRectFlags{
      kIgnoresPaint_  //
  };
  static constexpr DisplayListAttributeFlags kDrawImageRectWithPaintFlags{
      kBASE_ImageFlags_ |  //
      kUsesAntiAlias_ |    //
      kUsesMaskFilter_     //
  };
  static constexpr DisplayListAttributeFlags kDrawImageNineFlags{
      kIgnoresPaint_  //
  };
  static constexpr DisplayListAttributeFlags kDrawImageNineWithPaintFlags{
      kBASE_ImageFlags_  //
  };
  static constexpr DisplayListAttributeFlags kDrawAtlasFlags{
      kIgnoresPaint_  //
  };
  static constexpr DisplayListAttributeFlags kDrawAtlasWithPaintFlags{
      kBASE_ImageFlags_  //
  };
  static constexpr DisplayListAttributeFlags kDrawDisplayListFlags{
      kIgnoresPaint_  //
  };
  static constexpr DisplayListAttributeFlags kDrawTextBlobFlags{
      DisplayListAttributeFlags(kBASE_PaintFlags_ |         //
                                kBASE_StrokeOrFillFlags_ |  //
                                kMayHaveJoins_)             //
      - kUsesAntiAlias_                                     //
  };
  static constexpr DisplayListAttributeFlags kDrawShadowFlags{
      kIgnoresPaint_  //
  };
};

}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_DISPLAY_LIST_FLAGS_H_
