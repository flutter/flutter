/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2005, 2006, 2007, 2008, 2009, 2010 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Graham Dennis (graham.dennis@gmail.com)
 * Copyright (C) 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

#ifndef SKY_ENGINE_CORE_RENDERING_STYLE_RENDERSTYLECONSTANTS_H_
#define SKY_ENGINE_CORE_RENDERING_STYLE_RENDERSTYLECONSTANTS_H_

#include <cstddef>

namespace blink {

enum StyleRecalcChange {
    NoChange,
    NoInherit,
    Inherit,
    Force,
    Reattach,
    ReattachNoRenderer
};

enum ColumnFill { ColumnFillBalance, ColumnFillAuto };

// These have been defined in the order of their precedence for border-collapsing. Do
// not change this order! This order also must match the order in CSSValueKeywords.in.
enum EBorderStyle { BNONE, BHIDDEN, INSET, GROOVE, OUTSET, RIDGE, DOTTED, DASHED, SOLID, DOUBLE };

enum EBorderPrecedence { BOFF, BTABLE, BCOLGROUP, BCOL, BROWGROUP, BROW, BCELL };

enum OutlineIsAuto { AUTO_OFF = 0, AUTO_ON };

enum EPosition {
    StaticPosition = 0,
    AbsolutePosition = 1,
};

// Box decoration attributes. Not inherited.

enum EBoxDecorationBreak { DSLICE, DCLONE };

// Box attributes. Not inherited.

enum EBoxSizing { CONTENT_BOX, BORDER_BOX };

// Random visual rendering model attributes. Not inherited.

enum EOverflow {
    OVISIBLE, OHIDDEN, OAUTO, OOVERLAY, OPAGEDX, OPAGEDY
};

enum EVerticalAlign {
    BASELINE, MIDDLE, SUB, SUPER, TEXT_TOP,
    TEXT_BOTTOM, TOP, BOTTOM, BASELINE_MIDDLE, LENGTH
};

enum EFillAttachment {
    LocalBackgroundAttachment, FixedBackgroundAttachment
};

enum EFillBox {
    BorderFillBox, PaddingFillBox, ContentFillBox
};

enum EFillRepeat {
    RepeatFill, NoRepeatFill, RoundFill, SpaceFill
};

// FIXME(sky): Remove this enum.
enum EFillLayerType {
    BackgroundFillLayer
};

// CSS3 Background Values
enum EFillSizeType { Contain, Cover, SizeLength, SizeNone };

// CSS3 Background Position
enum BackgroundEdgeOrigin { TopEdge, RightEdge, BottomEdge, LeftEdge };

// Deprecated Flexible Box Properties

enum EBoxPack { Start, Center, End, Justify };
enum EBoxAlignment { BSTRETCH, BSTART, BCENTER, BEND, BBASELINE };
enum EBoxOrient { HORIZONTAL, VERTICAL };
enum EBoxLines { SINGLE, MULTIPLE };
enum EBoxDirection { BNORMAL, BREVERSE };

// CSS3 Flexbox Properties

enum EAlignContent { AlignContentFlexStart, AlignContentFlexEnd, AlignContentCenter, AlignContentSpaceBetween, AlignContentSpaceAround, AlignContentStretch };
enum EFlexDirection { FlowRow, FlowRowReverse, FlowColumn, FlowColumnReverse };
enum EFlexWrap { FlexNoWrap, FlexWrap, FlexWrapReverse };
enum EJustifyContent { JustifyFlexStart, JustifyFlexEnd, JustifyCenter, JustifySpaceBetween, JustifySpaceAround };

// CSS3 User Modify Properties

enum EUserModify {
    READ_ONLY, READ_WRITE, READ_WRITE_PLAINTEXT_ONLY
};

// CSS3 User Select Values

enum EUserSelect {
    SELECT_NONE, SELECT_TEXT, SELECT_ALL
};

// CSS3 Image Values
enum ObjectFit { ObjectFitFill, ObjectFitContain, ObjectFitCover, ObjectFitNone, ObjectFitScaleDown };

// Word Break Values. Matches WinIE, rather than CSS3

enum EWordBreak {
    NormalWordBreak, BreakAllWordBreak, BreakWordBreak
};

enum EOverflowWrap {
    NormalOverflowWrap, BreakOverflowWrap
};

enum LineBreak {
    LineBreakAuto, LineBreakLoose, LineBreakNormal, LineBreakStrict, LineBreakAfterWhiteSpace
};

enum EAnimPlayState {
    AnimPlayStatePlaying,
    AnimPlayStatePaused
};

enum EWhiteSpace {
    NORMAL, PRE, PRE_WRAP, PRE_LINE, NOWRAP, KHTML_NOWRAP
};

// The order of this enum must match the order of the values in dart:ui's TextAlign.
enum ETextAlign {
    LEFT, RIGHT, CENTER, JUSTIFY, TASTART, TAEND,
};

static const size_t TextDecorationBits = 4;
enum TextDecoration {
    TextDecorationNone = 0x0,
    TextDecorationUnderline = 0x1,
    TextDecorationOverline = 0x2,
    TextDecorationLineThrough = 0x4,
    TextDecorationBlink = 0x8
};
inline TextDecoration operator| (TextDecoration a, TextDecoration b) { return TextDecoration(int(a) | int(b)); }
inline TextDecoration& operator|= (TextDecoration& a, TextDecoration b) { return a = a | b; }

enum TextDecorationStyle {
    TextDecorationStyleSolid,
    TextDecorationStyleDouble,
    TextDecorationStyleDotted,
    TextDecorationStyleDashed,
    TextDecorationStyleWavy
};

enum TextAlignLast {
    TextAlignLastAuto, TextAlignLastStart, TextAlignLastEnd, TextAlignLastLeft, TextAlignLastRight, TextAlignLastCenter, TextAlignLastJustify
};

enum TextJustify {
    TextJustifyAuto, TextJustifyNone, TextJustifyInterWord, TextJustifyDistribute
};

enum TextUnderlinePosition {
    // FIXME: Implement support for 'under left' and 'under right' values.
    TextUnderlinePositionAuto,
    TextUnderlinePositionUnder
};

enum EVisibility { VISIBLE, HIDDEN, COLLAPSE };

// The order of this enum must match the order of the display values in CSSValueKeywords.in.
enum EDisplay {
    INLINE, PARAGRAPH,
    FLEX, INLINE_FLEX,
    NONE,
};

enum EPointerEvents {
    PE_NONE, PE_AUTO, PE_STROKE, PE_FILL, PE_PAINTED, PE_VISIBLE,
    PE_VISIBLE_STROKE, PE_VISIBLE_FILL, PE_VISIBLE_PAINTED, PE_BOUNDINGBOX,
    PE_ALL
};

enum ETransformStyle3D {
    TransformStyle3DFlat, TransformStyle3DPreserve3D
};

enum Hyphens { HyphensNone, HyphensManual, HyphensAuto };

enum TextEmphasisFill { TextEmphasisFillFilled, TextEmphasisFillOpen };

enum TextEmphasisMark { TextEmphasisMarkNone, TextEmphasisMarkAuto, TextEmphasisMarkDot, TextEmphasisMarkCircle, TextEmphasisMarkDoubleCircle, TextEmphasisMarkTriangle, TextEmphasisMarkSesame, TextEmphasisMarkCustom };

enum TextEmphasisPosition { TextEmphasisPositionOver, TextEmphasisPositionUnder };

enum TextOrientation { TextOrientationVerticalRight, TextOrientationUpright, TextOrientationSideways, TextOrientationSidewaysRight };

enum TextOverflow { TextOverflowClip = 0, TextOverflowEllipsis };

enum EImageRendering { ImageRenderingAuto, ImageRenderingOptimizeSpeed, ImageRenderingOptimizeQuality, ImageRenderingOptimizeContrast, ImageRenderingPixelated };

enum ImageResolutionSource { ImageResolutionSpecified = 0, ImageResolutionFromImage };

enum ImageResolutionSnap { ImageResolutionNoSnap = 0, ImageResolutionSnapPixels };

enum Order { LogicalOrder = 0, VisualOrder };

enum WrapFlow { WrapFlowAuto, WrapFlowBoth, WrapFlowStart, WrapFlowEnd, WrapFlowMaximum, WrapFlowClear };

enum WrapThrough { WrapThroughWrap, WrapThroughNone };

static const size_t TouchActionBits = 4;
enum TouchAction {
    TouchActionAuto = 0x0,
    TouchActionNone = 0x1,
    TouchActionPanX = 0x2,
    TouchActionPanY = 0x4,
    TouchActionPinchZoom = 0x8,
};
inline TouchAction operator| (TouchAction a, TouchAction b) { return TouchAction(int(a) | int(b)); }
inline TouchAction& operator|= (TouchAction& a, TouchAction b) { return a = a | b; }
inline TouchAction operator& (TouchAction a, TouchAction b) { return TouchAction(int(a) & int(b)); }
inline TouchAction& operator&= (TouchAction& a, TouchAction b) { return a = a & b; }

enum TouchActionDelay { TouchActionDelayNone, TouchActionDelayScript };

enum ItemPosition {
    ItemPositionAuto,
    ItemPositionStretch,
    ItemPositionBaseline,
    ItemPositionLastBaseline,
    ItemPositionCenter,
    ItemPositionStart,
    ItemPositionEnd,
    ItemPositionSelfStart,
    ItemPositionSelfEnd,
    ItemPositionFlexStart,
    ItemPositionFlexEnd,
    ItemPositionLeft,
    ItemPositionRight
};

enum OverflowAlignment {
    OverflowAlignmentDefault,
    OverflowAlignmentTrue,
    OverflowAlignmentSafe
};

enum ItemPositionType {
    NonLegacyPosition,
    LegacyPosition
};

// Reasonable maximum to prevent insane font sizes from causing crashes on some platforms (such as Windows).
static const float maximumAllowedFontSize = 1000000.0f;

enum TextIndentLine { TextIndentFirstLine, TextIndentEachLine };
enum TextIndentType { TextIndentNormal, TextIndentHanging };

enum CSSBoxType { BoxMissing = 0, MarginBox, BorderBox, PaddingBox, ContentBox };

enum LineBoxContainFlags {
    LineBoxContainNone = 0x0,
    LineBoxContainBlock = 0x1,
    LineBoxContainInline = 0x2,
    LineBoxContainFont = 0x4,
    LineBoxContainGlyphs = 0x8,
    LineBoxContainReplaced = 0x10,
    LineBoxContainInlineBox = 0x20
};
typedef unsigned LineBoxContain;

} // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_STYLE_RENDERSTYLECONSTANTS_H_
