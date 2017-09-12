/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All
 * rights reserved.
 * Copyright (C) 2006 Graham Dennis (graham.dennis@gmail.com)
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

#ifndef SKY_ENGINE_CORE_RENDERING_STYLE_RENDERSTYLE_H_
#define SKY_ENGINE_CORE_RENDERING_STYLE_RENDERSTYLE_H_

#include "flutter/sky/engine/core/rendering/style/BorderValue.h"
#include "flutter/sky/engine/core/rendering/style/CounterDirectives.h"
#include "flutter/sky/engine/core/rendering/style/DataRef.h"
#include "flutter/sky/engine/core/rendering/style/OutlineValue.h"
#include "flutter/sky/engine/core/rendering/style/RenderStyleConstants.h"
#include "flutter/sky/engine/core/rendering/style/ShapeValue.h"
#include "flutter/sky/engine/core/rendering/style/StyleBackgroundData.h"
#include "flutter/sky/engine/core/rendering/style/StyleBoxData.h"
#include "flutter/sky/engine/core/rendering/style/StyleDifference.h"
#include "flutter/sky/engine/core/rendering/style/StyleFilterData.h"
#include "flutter/sky/engine/core/rendering/style/StyleFlexibleBoxData.h"
#include "flutter/sky/engine/core/rendering/style/StyleInheritedData.h"
#include "flutter/sky/engine/core/rendering/style/StyleRareInheritedData.h"
#include "flutter/sky/engine/core/rendering/style/StyleRareNonInheritedData.h"
#include "flutter/sky/engine/core/rendering/style/StyleSurroundData.h"
#include "flutter/sky/engine/core/rendering/style/StyleTransformData.h"
#include "flutter/sky/engine/core/rendering/style/StyleVisualData.h"
#include "flutter/sky/engine/platform/Length.h"
#include "flutter/sky/engine/platform/LengthBox.h"
#include "flutter/sky/engine/platform/LengthSize.h"
#include "flutter/sky/engine/platform/fonts/FontBaseline.h"
#include "flutter/sky/engine/platform/fonts/FontDescription.h"
#include "flutter/sky/engine/platform/geometry/FloatRoundedRect.h"
#include "flutter/sky/engine/platform/geometry/LayoutBoxExtent.h"
#include "flutter/sky/engine/platform/geometry/RoundedRect.h"
#include "flutter/sky/engine/platform/graphics/Color.h"
#include "flutter/sky/engine/platform/graphics/GraphicsTypes.h"
#include "flutter/sky/engine/platform/text/TextDirection.h"
#include "flutter/sky/engine/platform/text/UnicodeBidi.h"
#include "flutter/sky/engine/platform/transforms/TransformOperations.h"
#include "flutter/sky/engine/wtf/Forward.h"
#include "flutter/sky/engine/wtf/OwnPtr.h"
#include "flutter/sky/engine/wtf/RefCounted.h"
#include "flutter/sky/engine/wtf/StdLibExtras.h"
#include "flutter/sky/engine/wtf/Vector.h"

template <typename T, typename U>
inline bool compareEqual(const T& t, const U& u) {
  return t == static_cast<T>(u);
}

#define SET_VAR(group, variable, value)      \
  if (!compareEqual(group->variable, value)) \
  group.access()->variable = value

#define SET_VAR_WITH_SETTER(group, getter, setter, value) \
  if (!compareEqual(group->getter(), value))              \
  group.access()->setter(value)

#define SET_BORDERVALUE_COLOR(group, variable, value) \
  if (!compareEqual(group->variable.color(), value))  \
  group.access()->variable.setColor(value)

namespace blink {

using std::max;

class AppliedTextDecoration;
class BorderData;
class Font;
class FontMetrics;
class ShadowList;
class StyleImage;
class StyleInheritedData;
class StyleResolver;
class TransformationMatrix;

class RenderStyle : public RefCounted<RenderStyle> {
  friend class EditingStyle;  // Editing has to only reveal unvisited info.
  friend class CSSComputedStyleDeclaration;  // Ignores visited styles, so needs
                                             // to be able to see unvisited
                                             // info.
  friend class StyleBuilderFunctions;        // Sets color styles

  // FIXME: When we stop resolving currentColor at style time, these can be
  // removed.
  friend class CSSToStyleMap;
  friend class FilterOperationResolver;
  friend class StyleBuilderConverter;
  friend class StyleResolverState;
  friend class StyleResolver;

 protected:
  // non-inherited attributes
  DataRef<StyleBoxData> m_box;
  DataRef<StyleVisualData> visual;
  DataRef<StyleBackgroundData> m_background;
  DataRef<StyleSurroundData> surround;
  DataRef<StyleRareNonInheritedData> rareNonInheritedData;

  // inherited attributes
  DataRef<StyleRareInheritedData> rareInheritedData;
  DataRef<StyleInheritedData> inherited;

  // !START SYNC!: Keep this in sync with the copy constructor in
  // RenderStyle.cpp and implicitlyInherited() in StyleResolver.cpp

  // inherit
  struct InheritedFlags {
    bool operator==(const InheritedFlags& other) const {
      return (_visibility == other._visibility) &&
             (_text_align == other._text_align) &&
             (m_textUnderline == other.m_textUnderline) &&
             (_direction == other._direction) &&
             (_white_space == other._white_space) &&
             (m_rtlOrdering == other.m_rtlOrdering) &&
             (_pointerEvents == other._pointerEvents);
    }

    bool operator!=(const InheritedFlags& other) const {
      return !(*this == other);
    }

    unsigned _visibility : 2;  // EVisibility
    unsigned _text_align : 4;  // ETextAlign
    unsigned m_textUnderline : 1;
    unsigned _direction : 1;    // TextDirection
    unsigned _white_space : 3;  // EWhiteSpace

    // non CSS2 inherited
    unsigned m_rtlOrdering : 1;   // Order
    unsigned _pointerEvents : 4;  // EPointerEvents

    // 19 bits
  } inherited_flags;

  // don't inherit
  struct NonInheritedFlags {
    bool operator==(const NonInheritedFlags& other) const {
      return effectiveDisplay == other.effectiveDisplay &&
             originalDisplay == other.originalDisplay &&
             overflowX == other.overflowX && overflowY == other.overflowY &&
             verticalAlign == other.verticalAlign &&
             position == other.position && styleType == other.styleType &&
             affectedByFocus == other.affectedByFocus &&
             affectedByHover == other.affectedByHover &&
             affectedByActive == other.affectedByActive &&
             unicodeBidi == other.unicodeBidi &&
             explicitInheritance == other.explicitInheritance &&
             currentColor == other.currentColor && unique == other.unique &&
             emptyState == other.emptyState &&
             firstChildState == other.firstChildState &&
             lastChildState == other.lastChildState && isLink == other.isLink;
    }

    bool operator!=(const NonInheritedFlags& other) const {
      return !(*this == other);
    }

    unsigned effectiveDisplay : 5;  // EDisplay
    unsigned originalDisplay : 5;   // EDisplay
    unsigned overflowX : 3;         // EOverflow
    unsigned overflowY : 3;         // EOverflow
    unsigned verticalAlign : 4;     // EVerticalAlign
    unsigned position : 1;          // EPosition
    unsigned unicodeBidi : 3;       // EUnicodeBidi

    // This is set if we used viewport units when resolving a length.
    // It is mutable so we can pass around const RenderStyles to resolve
    // lengths.
    mutable unsigned hasViewportUnits : 1;

    // 32 bits

    unsigned styleType : 6;            // PseudoId
    unsigned explicitInheritance : 1;  // Explicitly inherits a non-inherited
                                       // property
    unsigned
        currentColor : 1;  // At least one color has the value 'currentColor'
    unsigned unique : 1;   // Style can not be shared.

    unsigned emptyState : 1;
    unsigned firstChildState : 1;
    unsigned lastChildState : 1;

    unsigned affectedByFocus : 1;
    unsigned affectedByHover : 1;
    unsigned affectedByActive : 1;

    unsigned isLink : 1;
    // If you add more style bits here, you will also need to update
    // RenderStyle::copyNonInheritedFrom() 63 bits
  } noninherited_flags;

  // !END SYNC!

 protected:
  void setBitDefaults() {
    inherited_flags._visibility = initialVisibility();
    inherited_flags._text_align = initialTextAlign();
    inherited_flags.m_textUnderline = false;
    inherited_flags._direction = initialDirection();
    inherited_flags._white_space = initialWhiteSpace();
    inherited_flags.m_rtlOrdering = initialRTLOrdering();
    inherited_flags._pointerEvents = initialPointerEvents();

    noninherited_flags.effectiveDisplay = noninherited_flags.originalDisplay =
        initialDisplay();
    noninherited_flags.overflowX = initialOverflowX();
    noninherited_flags.overflowY = initialOverflowY();
    noninherited_flags.verticalAlign = initialVerticalAlign();
    noninherited_flags.position = initialPosition();
    noninherited_flags.unicodeBidi = initialUnicodeBidi();
    noninherited_flags.explicitInheritance = false;
    noninherited_flags.currentColor = false;
    noninherited_flags.unique = false;
    noninherited_flags.emptyState = false;
    noninherited_flags.firstChildState = false;
    noninherited_flags.lastChildState = false;
    noninherited_flags.hasViewportUnits = false;
    noninherited_flags.affectedByFocus = false;
    noninherited_flags.affectedByHover = false;
    noninherited_flags.affectedByActive = false;
    noninherited_flags.isLink = false;
  }

 private:
  ALWAYS_INLINE RenderStyle();

  enum DefaultStyleTag { DefaultStyle };
  ALWAYS_INLINE explicit RenderStyle(DefaultStyleTag);
  ALWAYS_INLINE RenderStyle(const RenderStyle&);

 public:
  static PassRefPtr<RenderStyle> create();
  static PassRefPtr<RenderStyle> createDefaultStyle();
  static PassRefPtr<RenderStyle> clone(const RenderStyle*);

  // Computes how the style change should be propagated down the tree.
  static StyleRecalcChange stylePropagationDiff(const RenderStyle* oldStyle,
                                                const RenderStyle* newStyle);

  StyleDifference visualInvalidationDiff(const RenderStyle&) const;

  void inheritFrom(const RenderStyle* inheritParent);
  void copyNonInheritedFrom(const RenderStyle*);

  void setHasViewportUnits(bool hasViewportUnits = true) const {
    noninherited_flags.hasViewportUnits = hasViewportUnits;
  }
  bool hasViewportUnits() const { return noninherited_flags.hasViewportUnits; }

  bool affectedByFocus() const { return noninherited_flags.affectedByFocus; }
  bool affectedByHover() const { return noninherited_flags.affectedByHover; }
  bool affectedByActive() const { return noninherited_flags.affectedByActive; }

  void setAffectedByFocus() { noninherited_flags.affectedByFocus = true; }
  void setAffectedByHover() { noninherited_flags.affectedByHover = true; }
  void setAffectedByActive() { noninherited_flags.affectedByActive = true; }

  bool operator==(const RenderStyle& other) const;
  bool operator!=(const RenderStyle& other) const { return !(*this == other); }
  bool hasMargin() const { return surround->margin.nonZero(); }
  bool hasBorder() const { return surround->border.hasBorder(); }
  bool hasPadding() const { return surround->padding.nonZero(); }
  bool hasOffset() const { return surround->offset.nonZero(); }
  bool hasMarginBeforeQuirk() const { return marginBefore().quirk(); }
  bool hasMarginAfterQuirk() const { return marginAfter().quirk(); }

  bool hasBackgroundImage() const {
    return m_background->background().hasImage();
  }
  bool hasFixedBackgroundImage() const {
    return m_background->background().hasFixedImage();
  }

  bool hasEntirelyFixedBackground() const;

  bool hasBackground() const {
    Color color = resolveColor(backgroundColor());
    if (color.alpha())
      return true;
    return hasBackgroundImage();
  }

  Order rtlOrdering() const {
    return static_cast<Order>(inherited_flags.m_rtlOrdering);
  }
  void setRTLOrdering(Order o) { inherited_flags.m_rtlOrdering = o; }

  // attribute getter methods

  EDisplay display() const {
    return static_cast<EDisplay>(noninherited_flags.effectiveDisplay);
  }
  EDisplay originalDisplay() const {
    return static_cast<EDisplay>(noninherited_flags.originalDisplay);
  }

  const Length& left() const { return surround->offset.left(); }
  const Length& right() const { return surround->offset.right(); }
  const Length& top() const { return surround->offset.top(); }
  const Length& bottom() const { return surround->offset.bottom(); }

  // Accessors for positioned object edges that take into account writing mode.
  const Length& logicalLeft() const { return surround->offset.logicalLeft(); }
  const Length& logicalRight() const { return surround->offset.logicalRight(); }
  const Length& logicalTop() const { return surround->offset.before(); }
  const Length& logicalBottom() const { return surround->offset.after(); }

  // Whether or not a positioned element requires normal flow x/y to be computed
  // to determine its position.
  bool hasAutoLeftAndRight() const {
    return left().isAuto() && right().isAuto();
  }
  bool hasAutoTopAndBottom() const {
    return top().isAuto() && bottom().isAuto();
  }

  EPosition position() const {
    return static_cast<EPosition>(noninherited_flags.position);
  }
  bool hasOutOfFlowPosition() const { return position() == AbsolutePosition; }
  // FIXME(sky): Remove
  bool hasInFlowPosition() const { return false; }

  const Length& width() const { return m_box->width(); }
  const Length& height() const { return m_box->height(); }
  const Length& minWidth() const { return m_box->minWidth(); }
  const Length& maxWidth() const { return m_box->maxWidth(); }
  const Length& minHeight() const { return m_box->minHeight(); }
  const Length& maxHeight() const { return m_box->maxHeight(); }

  const Length& logicalWidth() const { return width(); }
  const Length& logicalHeight() const { return height(); }
  const Length& logicalMinWidth() const { return minWidth(); }
  const Length& logicalMaxWidth() const { return maxWidth(); }
  const Length& logicalMinHeight() const { return minHeight(); }
  const Length& logicalMaxHeight() const { return maxHeight(); }

  const BorderData& border() const { return surround->border; }
  const BorderValue& borderLeft() const { return surround->border.left(); }
  const BorderValue& borderRight() const { return surround->border.right(); }
  const BorderValue& borderTop() const { return surround->border.top(); }
  const BorderValue& borderBottom() const { return surround->border.bottom(); }

  const BorderValue& borderBefore() const;
  const BorderValue& borderAfter() const;
  const BorderValue& borderStart() const;
  const BorderValue& borderEnd() const;

  const LengthSize& borderTopLeftRadius() const {
    return surround->border.topLeft();
  }
  const LengthSize& borderTopRightRadius() const {
    return surround->border.topRight();
  }
  const LengthSize& borderBottomLeftRadius() const {
    return surround->border.bottomLeft();
  }
  const LengthSize& borderBottomRightRadius() const {
    return surround->border.bottomRight();
  }
  bool hasBorderRadius() const { return surround->border.hasBorderRadius(); }

  unsigned borderLeftWidth() const {
    return surround->border.borderLeftWidth();
  }
  EBorderStyle borderLeftStyle() const {
    return surround->border.left().style();
  }
  bool borderLeftIsTransparent() const {
    return surround->border.left().isTransparent();
  }
  unsigned borderRightWidth() const {
    return surround->border.borderRightWidth();
  }
  EBorderStyle borderRightStyle() const {
    return surround->border.right().style();
  }
  bool borderRightIsTransparent() const {
    return surround->border.right().isTransparent();
  }
  unsigned borderTopWidth() const { return surround->border.borderTopWidth(); }
  EBorderStyle borderTopStyle() const { return surround->border.top().style(); }
  bool borderTopIsTransparent() const {
    return surround->border.top().isTransparent();
  }
  unsigned borderBottomWidth() const {
    return surround->border.borderBottomWidth();
  }
  EBorderStyle borderBottomStyle() const {
    return surround->border.bottom().style();
  }
  bool borderBottomIsTransparent() const {
    return surround->border.bottom().isTransparent();
  }

  unsigned short borderBeforeWidth() const;
  unsigned short borderAfterWidth() const;
  unsigned short borderStartWidth() const;
  unsigned short borderEndWidth() const;

  unsigned short outlineSize() const {
    return max(0, outlineWidth() + outlineOffset());
  }
  unsigned short outlineWidth() const {
    if (m_background->outline().style() == BNONE)
      return 0;
    return m_background->outline().width();
  }
  bool hasOutline() const {
    return outlineWidth() > 0 && outlineStyle() > BHIDDEN;
  }
  EBorderStyle outlineStyle() const { return m_background->outline().style(); }
  OutlineIsAuto outlineStyleIsAuto() const {
    return static_cast<OutlineIsAuto>(m_background->outline().isAuto());
  }

  EOverflow overflowX() const {
    return static_cast<EOverflow>(noninherited_flags.overflowX);
  }
  EOverflow overflowY() const {
    return static_cast<EOverflow>(noninherited_flags.overflowY);
  }
  // It's sufficient to just check one direction, since it's illegal to have
  // visible on only one overflow value.
  bool isOverflowVisible() const {
    ASSERT(overflowX() != OVISIBLE || overflowX() == overflowY());
    return overflowX() == OVISIBLE;
  }
  bool isOverflowPaged() const {
    return overflowY() == OPAGEDX || overflowY() == OPAGEDY;
  }

  EVerticalAlign verticalAlign() const {
    return static_cast<EVerticalAlign>(noninherited_flags.verticalAlign);
  }
  const Length& verticalAlignLength() const { return m_box->verticalAlign(); }

  const Length& clipLeft() const { return visual->clip.left(); }
  const Length& clipRight() const { return visual->clip.right(); }
  const Length& clipTop() const { return visual->clip.top(); }
  const Length& clipBottom() const { return visual->clip.bottom(); }
  const LengthBox& clip() const { return visual->clip; }
  bool hasAutoClip() const { return visual->hasAutoClip; }

  EUnicodeBidi unicodeBidi() const {
    return static_cast<EUnicodeBidi>(noninherited_flags.unicodeBidi);
  }

  const Font& font() const;
  const FontMetrics& fontMetrics() const;
  const FontDescription& fontDescription() const;
  float specifiedFontSize() const;
  float computedFontSize() const;
  int fontSize() const;
  FontWeight fontWeight() const;
  FontStretch fontStretch() const;

  const Length& textIndent() const { return rareInheritedData->indent; }
  TextIndentLine textIndentLine() const {
    return static_cast<TextIndentLine>(rareInheritedData->m_textIndentLine);
  }
  TextIndentType textIndentType() const {
    return static_cast<TextIndentType>(rareInheritedData->m_textIndentType);
  }
  ETextAlign textAlign() const {
    return static_cast<ETextAlign>(inherited_flags._text_align);
  }
  TextAlignLast textAlignLast() const {
    return static_cast<TextAlignLast>(rareInheritedData->m_textAlignLast);
  }
  TextJustify textJustify() const {
    return static_cast<TextJustify>(rareInheritedData->m_textJustify);
  }
  TextDecoration textDecorationsInEffect() const;
  const Vector<AppliedTextDecoration>& appliedTextDecorations() const;
  TextDecoration textDecoration() const {
    return static_cast<TextDecoration>(visual->textDecoration);
  }
  TextUnderlinePosition textUnderlinePosition() const {
    return static_cast<TextUnderlinePosition>(
        rareInheritedData->m_textUnderlinePosition);
  }
  TextDecorationStyle textDecorationStyle() const {
    return static_cast<TextDecorationStyle>(
        rareNonInheritedData->m_textDecorationStyle);
  }
  float wordSpacing() const;
  float letterSpacing() const;

  TextDirection direction() const {
    return static_cast<TextDirection>(inherited_flags._direction);
  }
  bool isLeftToRightDirection() const { return direction() == LTR; }

  const Length& specifiedLineHeight() const;
  Length lineHeight() const;
  int computedLineHeight() const;

  EWhiteSpace whiteSpace() const {
    return static_cast<EWhiteSpace>(inherited_flags._white_space);
  }
  static bool autoWrap(EWhiteSpace ws) {
    // Nowrap and pre don't automatically wrap.
    return ws != NOWRAP && ws != PRE;
  }

  bool autoWrap() const { return autoWrap(whiteSpace()); }

  static bool preserveNewline(EWhiteSpace ws) {
    // Normal and nowrap do not preserve newlines.
    return ws != NORMAL && ws != NOWRAP;
  }

  bool preserveNewline() const { return preserveNewline(whiteSpace()); }

  static bool collapseWhiteSpace(EWhiteSpace ws) {
    // Pre and prewrap do not collapse whitespace.
    return ws != PRE && ws != PRE_WRAP;
  }

  bool collapseWhiteSpace() const { return collapseWhiteSpace(whiteSpace()); }

  bool isCollapsibleWhiteSpace(UChar c) const {
    switch (c) {
      case ' ':
      case '\t':
        return collapseWhiteSpace();
      case '\n':
        return !preserveNewline();
    }
    return false;
  }

  bool breakOnlyAfterWhiteSpace() const {
    return whiteSpace() == PRE_WRAP || lineBreak() == LineBreakAfterWhiteSpace;
  }

  bool breakWords() const {
    return wordBreak() == BreakWordBreak || overflowWrap() == BreakOverflowWrap;
  }

  EFillRepeat backgroundRepeatX() const {
    return static_cast<EFillRepeat>(m_background->background().repeatX());
  }
  EFillRepeat backgroundRepeatY() const {
    return static_cast<EFillRepeat>(m_background->background().repeatY());
  }
  CompositeOperator backgroundComposite() const {
    return static_cast<CompositeOperator>(
        m_background->background().composite());
  }
  EFillAttachment backgroundAttachment() const {
    return static_cast<EFillAttachment>(
        m_background->background().attachment());
  }
  EFillBox backgroundClip() const {
    return static_cast<EFillBox>(m_background->background().clip());
  }
  EFillBox backgroundOrigin() const {
    return static_cast<EFillBox>(m_background->background().origin());
  }
  const Length& backgroundXPosition() const {
    return m_background->background().xPosition();
  }
  const Length& backgroundYPosition() const {
    return m_background->background().yPosition();
  }
  EFillSizeType backgroundSizeType() const {
    return m_background->background().sizeType();
  }
  const LengthSize& backgroundSizeLength() const {
    return m_background->background().sizeLength();
  }
  FillLayer& accessBackgroundLayers() {
    return m_background.access()->m_background;
  }
  const FillLayer& backgroundLayers() const {
    return m_background->background();
  }

  short horizontalBorderSpacing() const;
  short verticalBorderSpacing() const;

  const Length& marginTop() const { return surround->margin.top(); }
  const Length& marginBottom() const { return surround->margin.bottom(); }
  const Length& marginLeft() const { return surround->margin.left(); }
  const Length& marginRight() const { return surround->margin.right(); }
  const Length& marginBefore() const { return surround->margin.before(); }
  const Length& marginAfter() const { return surround->margin.after(); }
  const Length& marginStart() const {
    return surround->margin.start(direction());
  }
  const Length& marginEnd() const { return surround->margin.end(direction()); }
  const Length& marginStartUsing(const RenderStyle* otherStyle) const {
    return surround->margin.start(otherStyle->direction());
  }
  const Length& marginEndUsing(const RenderStyle* otherStyle) const {
    return surround->margin.end(otherStyle->direction());
  }
  const Length& marginBeforeUsing(const RenderStyle* otherStyle) const {
    return surround->margin.before();
  }
  const Length& marginAfterUsing(const RenderStyle* otherStyle) const {
    return surround->margin.after();
  }

  const LengthBox& paddingBox() const { return surround->padding; }
  const Length& paddingTop() const { return surround->padding.top(); }
  const Length& paddingBottom() const { return surround->padding.bottom(); }
  const Length& paddingLeft() const { return surround->padding.left(); }
  const Length& paddingRight() const { return surround->padding.right(); }
  const Length& paddingBefore() const { return surround->padding.before(); }
  const Length& paddingAfter() const { return surround->padding.after(); }
  const Length& paddingStart() const {
    return surround->padding.start(direction());
  }
  const Length& paddingEnd() const {
    return surround->padding.end(direction());
  }

  bool isLink() const { return noninherited_flags.isLink; }

  // CSS3 Getter Methods

  int outlineOffset() const {
    if (m_background->outline().style() == BNONE)
      return 0;
    return m_background->outline().offset();
  }

  ShadowList* textShadow() const { return rareInheritedData->textShadow.get(); }
  void getTextShadowExtent(LayoutUnit& top,
                           LayoutUnit& right,
                           LayoutUnit& bottom,
                           LayoutUnit& left) const {
    getShadowExtent(textShadow(), top, right, bottom, left);
  }
  void getTextShadowHorizontalExtent(LayoutUnit& left,
                                     LayoutUnit& right) const {
    getShadowHorizontalExtent(textShadow(), left, right);
  }
  void getTextShadowVerticalExtent(LayoutUnit& top, LayoutUnit& bottom) const {
    getShadowVerticalExtent(textShadow(), top, bottom);
  }
  void getTextShadowInlineDirectionExtent(LayoutUnit& logicalLeft,
                                          LayoutUnit& logicalRight) {
    getShadowInlineDirectionExtent(textShadow(), logicalLeft, logicalRight);
  }
  void getTextShadowBlockDirectionExtent(LayoutUnit& logicalTop,
                                         LayoutUnit& logicalBottom) {
    getShadowBlockDirectionExtent(textShadow(), logicalTop, logicalBottom);
  }

  float textStrokeWidth() const { return rareInheritedData->textStrokeWidth; }
  float opacity() const { return rareNonInheritedData->opacity; }
  bool hasOpacity() const { return opacity() < 1.0f; }
  // aspect ratio convenience method
  bool hasAspectRatio() const { return rareNonInheritedData->m_hasAspectRatio; }
  float aspectRatio() const {
    return aspectRatioNumerator() / aspectRatioDenominator();
  }
  float aspectRatioDenominator() const {
    return rareNonInheritedData->m_aspectRatioDenominator;
  }
  float aspectRatioNumerator() const {
    return rareNonInheritedData->m_aspectRatioNumerator;
  }

  int order() const { return rareNonInheritedData->m_order; }
  float flexGrow() const {
    return rareNonInheritedData->m_flexibleBox->m_flexGrow;
  }
  float flexShrink() const {
    return rareNonInheritedData->m_flexibleBox->m_flexShrink;
  }
  const Length& flexBasis() const {
    return rareNonInheritedData->m_flexibleBox->m_flexBasis;
  }
  EAlignContent alignContent() const {
    return static_cast<EAlignContent>(rareNonInheritedData->m_alignContent);
  }
  ItemPosition alignItems() const {
    return static_cast<ItemPosition>(rareNonInheritedData->m_alignItems);
  }
  OverflowAlignment alignItemsOverflowAlignment() const {
    return static_cast<OverflowAlignment>(
        rareNonInheritedData->m_alignItemsOverflowAlignment);
  }
  ItemPosition alignSelf() const {
    return static_cast<ItemPosition>(rareNonInheritedData->m_alignSelf);
  }
  OverflowAlignment alignSelfOverflowAlignment() const {
    return static_cast<OverflowAlignment>(
        rareNonInheritedData->m_alignSelfOverflowAlignment);
  }
  EFlexDirection flexDirection() const {
    return static_cast<EFlexDirection>(
        rareNonInheritedData->m_flexibleBox->m_flexDirection);
  }
  bool isColumnFlexDirection() const {
    return flexDirection() == FlowColumn ||
           flexDirection() == FlowColumnReverse;
  }
  bool isReverseFlexDirection() const {
    return flexDirection() == FlowRowReverse ||
           flexDirection() == FlowColumnReverse;
  }
  EFlexWrap flexWrap() const {
    return static_cast<EFlexWrap>(
        rareNonInheritedData->m_flexibleBox->m_flexWrap);
  }
  EJustifyContent justifyContent() const {
    return static_cast<EJustifyContent>(rareNonInheritedData->m_justifyContent);
  }
  ItemPosition justifyItems() const {
    return static_cast<ItemPosition>(rareNonInheritedData->m_justifyItems);
  }
  OverflowAlignment justifyItemsOverflowAlignment() const {
    return static_cast<OverflowAlignment>(
        rareNonInheritedData->m_justifyItemsOverflowAlignment);
  }
  ItemPositionType justifyItemsPositionType() const {
    return static_cast<ItemPositionType>(
        rareNonInheritedData->m_justifyItemsPositionType);
  }
  ItemPosition justifySelf() const {
    return static_cast<ItemPosition>(rareNonInheritedData->m_justifySelf);
  }
  OverflowAlignment justifySelfOverflowAlignment() const {
    return static_cast<OverflowAlignment>(
        rareNonInheritedData->m_justifySelfOverflowAlignment);
  }

  ShadowList* boxShadow() const {
    return rareNonInheritedData->m_boxShadow.get();
  }
  void getBoxShadowExtent(LayoutUnit& top,
                          LayoutUnit& right,
                          LayoutUnit& bottom,
                          LayoutUnit& left) const {
    getShadowExtent(boxShadow(), top, right, bottom, left);
  }
  LayoutBoxExtent getBoxShadowInsetExtent() const {
    return getShadowInsetExtent(boxShadow());
  }
  void getBoxShadowHorizontalExtent(LayoutUnit& left, LayoutUnit& right) const {
    getShadowHorizontalExtent(boxShadow(), left, right);
  }
  void getBoxShadowVerticalExtent(LayoutUnit& top, LayoutUnit& bottom) const {
    getShadowVerticalExtent(boxShadow(), top, bottom);
  }
  void getBoxShadowInlineDirectionExtent(LayoutUnit& logicalLeft,
                                         LayoutUnit& logicalRight) {
    getShadowInlineDirectionExtent(boxShadow(), logicalLeft, logicalRight);
  }
  void getBoxShadowBlockDirectionExtent(LayoutUnit& logicalTop,
                                        LayoutUnit& logicalBottom) {
    getShadowBlockDirectionExtent(boxShadow(), logicalTop, logicalBottom);
  }

  EBoxDecorationBreak boxDecorationBreak() const {
    return m_box->boxDecorationBreak();
  }

  // FIXME: reflections should belong to this helper function but they are
  // currently handled through their self-painting layers. So the rendering code
  // doesn't account for them.
  bool hasVisualOverflowingEffect() const {
    return boxShadow() || hasOutline();
  }

  EBoxSizing boxSizing() const { return m_box->boxSizing(); }
  EUserModify userModify() const {
    return static_cast<EUserModify>(rareInheritedData->userModify);
  }
  EUserSelect userSelect() const {
    return static_cast<EUserSelect>(rareInheritedData->userSelect);
  }
  TextOverflow textOverflow() const {
    return static_cast<TextOverflow>(rareNonInheritedData->textOverflow);
  }
  EWordBreak wordBreak() const {
    return static_cast<EWordBreak>(rareInheritedData->wordBreak);
  }
  EOverflowWrap overflowWrap() const {
    return static_cast<EOverflowWrap>(rareInheritedData->overflowWrap);
  }
  LineBreak lineBreak() const {
    return static_cast<LineBreak>(rareInheritedData->lineBreak);
  }
  const AtomicString& highlight() const { return rareInheritedData->highlight; }
  const AtomicString& hyphenationString() const {
    return rareInheritedData->hyphenationString;
  }
  const AtomicString& locale() const { return rareInheritedData->locale; }
  const TransformOperations& transform() const {
    return rareNonInheritedData->m_transform->m_operations;
  }
  const Length& transformOriginX() const {
    return rareNonInheritedData->m_transform->m_x;
  }
  const Length& transformOriginY() const {
    return rareNonInheritedData->m_transform->m_y;
  }
  float transformOriginZ() const {
    return rareNonInheritedData->m_transform->m_z;
  }
  bool hasTransform() const {
    return !rareNonInheritedData->m_transform->m_operations.operations()
                .isEmpty();
  }
  bool transformDataEquivalent(const RenderStyle& otherStyle) const {
    return rareNonInheritedData->m_transform ==
           otherStyle.rareNonInheritedData->m_transform;
  }

  TextEmphasisFill textEmphasisFill() const {
    return static_cast<TextEmphasisFill>(rareInheritedData->textEmphasisFill);
  }
  TextEmphasisMark textEmphasisMark() const;
  const AtomicString& textEmphasisCustomMark() const {
    return rareInheritedData->textEmphasisCustomMark;
  }
  TextEmphasisPosition textEmphasisPosition() const {
    return static_cast<TextEmphasisPosition>(
        rareInheritedData->textEmphasisPosition);
  }
  const AtomicString& textEmphasisMarkString() const;

  TextOrientation textOrientation() const {
    return static_cast<TextOrientation>(rareInheritedData->m_textOrientation);
  }

  ObjectFit objectFit() const {
    return static_cast<ObjectFit>(rareNonInheritedData->m_objectFit);
  }
  LengthPoint objectPosition() const {
    return rareNonInheritedData->m_objectPosition;
  }

  // Return true if any transform related property (currently transform,
  // transformStyle3D or perspective) indicates that we are transforming
  bool hasTransformRelatedProperty() const {
    return hasTransform() || preserves3D() || hasPerspective();
  }

  enum ApplyTransformOrigin { IncludeTransformOrigin, ExcludeTransformOrigin };
  void applyTransform(TransformationMatrix&,
                      const LayoutSize& borderBoxSize,
                      ApplyTransformOrigin = IncludeTransformOrigin) const;
  void applyTransform(TransformationMatrix&,
                      const FloatRect& boundingBox,
                      ApplyTransformOrigin = IncludeTransformOrigin) const;

  unsigned tabSize() const { return rareInheritedData->m_tabSize; }

  // End CSS3 Getters

  WrapFlow wrapFlow() const {
    return static_cast<WrapFlow>(rareNonInheritedData->m_wrapFlow);
  }
  WrapThrough wrapThrough() const {
    return static_cast<WrapThrough>(rareNonInheritedData->m_wrapThrough);
  }

  // Apple-specific property getter methods
  EPointerEvents pointerEvents() const {
    return static_cast<EPointerEvents>(inherited_flags._pointerEvents);
  }

  ETransformStyle3D transformStyle3D() const {
    return static_cast<ETransformStyle3D>(
        rareNonInheritedData->m_transformStyle3D);
  }
  bool preserves3D() const {
    return rareNonInheritedData->m_transformStyle3D ==
           TransformStyle3DPreserve3D;
  }

  float perspective() const { return rareNonInheritedData->m_perspective; }
  bool hasPerspective() const {
    return rareNonInheritedData->m_perspective > 0;
  }
  const Length& perspectiveOriginX() const {
    return rareNonInheritedData->m_perspectiveOriginX;
  }
  const Length& perspectiveOriginY() const {
    return rareNonInheritedData->m_perspectiveOriginY;
  }

  LineBoxContain lineBoxContain() const {
    return rareInheritedData->m_lineBoxContain;
  }
  Color tapHighlightColor() const {
    return rareInheritedData->tapHighlightColor;
  }

  EImageRendering imageRendering() const {
    return static_cast<EImageRendering>(rareInheritedData->m_imageRendering);
  }

  TouchAction touchAction() const {
    return static_cast<TouchAction>(rareNonInheritedData->m_touchAction);
  }
  TouchActionDelay touchActionDelay() const {
    return static_cast<TouchActionDelay>(rareInheritedData->m_touchActionDelay);
  }

  // Flutter property getters
  const AtomicString& ellipsis() const {
    return rareNonInheritedData->m_ellipsis;
  }
  int maxLines() const { return rareNonInheritedData->m_maxLines; }

  // attribute setter methods

  void setDisplay(EDisplay v) { noninherited_flags.effectiveDisplay = v; }
  void setOriginalDisplay(EDisplay v) {
    noninherited_flags.originalDisplay = v;
  }
  void setPosition(EPosition v) { noninherited_flags.position = v; }

  void setLeft(const Length& v) { SET_VAR(surround, offset.m_left, v); }
  void setRight(const Length& v) { SET_VAR(surround, offset.m_right, v); }
  void setTop(const Length& v) { SET_VAR(surround, offset.m_top, v); }
  void setBottom(const Length& v) { SET_VAR(surround, offset.m_bottom, v); }

  void setWidth(const Length& v) { SET_VAR(m_box, m_width, v); }
  void setHeight(const Length& v) { SET_VAR(m_box, m_height, v); }

  void setLogicalWidth(const Length& v) {
    // FIXME(sky): Remove
    SET_VAR(m_box, m_width, v);
  }

  void setLogicalHeight(const Length& v) {
    // FIXME(sky): Remove
    SET_VAR(m_box, m_height, v);
  }

  void setMinWidth(const Length& v) { SET_VAR(m_box, m_minWidth, v); }
  void setMaxWidth(const Length& v) { SET_VAR(m_box, m_maxWidth, v); }
  void setMinHeight(const Length& v) { SET_VAR(m_box, m_minHeight, v); }
  void setMaxHeight(const Length& v) { SET_VAR(m_box, m_maxHeight, v); }

  void resetBorder() {
    resetBorderTop();
    resetBorderRight();
    resetBorderBottom();
    resetBorderLeft();
    resetBorderTopLeftRadius();
    resetBorderTopRightRadius();
    resetBorderBottomLeftRadius();
    resetBorderBottomRightRadius();
  }
  void resetBorderTop() { SET_VAR(surround, border.m_top, BorderValue()); }
  void resetBorderRight() { SET_VAR(surround, border.m_right, BorderValue()); }
  void resetBorderBottom() {
    SET_VAR(surround, border.m_bottom, BorderValue());
  }
  void resetBorderLeft() { SET_VAR(surround, border.m_left, BorderValue()); }
  void resetBorderTopLeftRadius() {
    SET_VAR(surround, border.m_topLeft, initialBorderRadius());
  }
  void resetBorderTopRightRadius() {
    SET_VAR(surround, border.m_topRight, initialBorderRadius());
  }
  void resetBorderBottomLeftRadius() {
    SET_VAR(surround, border.m_bottomLeft, initialBorderRadius());
  }
  void resetBorderBottomRightRadius() {
    SET_VAR(surround, border.m_bottomRight, initialBorderRadius());
  }

  void setBackgroundColor(const StyleColor& v) {
    SET_VAR(m_background, m_color, v);
  }

  void setBackgroundXPosition(const Length& length) {
    SET_VAR(m_background, m_background.m_xPosition, length);
  }
  void setBackgroundYPosition(const Length& length) {
    SET_VAR(m_background, m_background.m_yPosition, length);
  }
  void setBackgroundSize(EFillSizeType b) {
    SET_VAR(m_background, m_background.m_sizeType, b);
  }
  void setBackgroundSizeLength(const LengthSize& s) {
    SET_VAR(m_background, m_background.m_sizeLength, s);
  }

  void setBorderTopLeftRadius(const LengthSize& s) {
    SET_VAR(surround, border.m_topLeft, s);
  }
  void setBorderTopRightRadius(const LengthSize& s) {
    SET_VAR(surround, border.m_topRight, s);
  }
  void setBorderBottomLeftRadius(const LengthSize& s) {
    SET_VAR(surround, border.m_bottomLeft, s);
  }
  void setBorderBottomRightRadius(const LengthSize& s) {
    SET_VAR(surround, border.m_bottomRight, s);
  }

  void setBorderRadius(const LengthSize& s) {
    setBorderTopLeftRadius(s);
    setBorderTopRightRadius(s);
    setBorderBottomLeftRadius(s);
    setBorderBottomRightRadius(s);
  }
  void setBorderRadius(const IntSize& s) {
    setBorderRadius(
        LengthSize(Length(s.width(), Fixed), Length(s.height(), Fixed)));
  }

  RoundedRect getRoundedBorderFor(const LayoutRect& borderRect,
                                  bool includeLogicalLeftEdge = true,
                                  bool includeLogicalRightEdge = true) const;
  RoundedRect getRoundedInnerBorderFor(
      const LayoutRect& borderRect,
      bool includeLogicalLeftEdge = true,
      bool includeLogicalRightEdge = true) const;

  RoundedRect getRoundedInnerBorderFor(const LayoutRect& borderRect,
                                       int topWidth,
                                       int bottomWidth,
                                       int leftWidth,
                                       int rightWidth,
                                       bool includeLogicalLeftEdge,
                                       bool includeLogicalRightEdge) const;

  void setBorderLeftWidth(unsigned v) {
    SET_VAR(surround, border.m_left.m_width, v);
  }
  void setBorderLeftStyle(EBorderStyle v) {
    SET_VAR(surround, border.m_left.m_style, v);
  }
  void setBorderLeftColor(const StyleColor& v) {
    SET_BORDERVALUE_COLOR(surround, border.m_left, v);
  }
  void setBorderRightWidth(unsigned v) {
    SET_VAR(surround, border.m_right.m_width, v);
  }
  void setBorderRightStyle(EBorderStyle v) {
    SET_VAR(surround, border.m_right.m_style, v);
  }
  void setBorderRightColor(const StyleColor& v) {
    SET_BORDERVALUE_COLOR(surround, border.m_right, v);
  }
  void setBorderTopWidth(unsigned v) {
    SET_VAR(surround, border.m_top.m_width, v);
  }
  void setBorderTopStyle(EBorderStyle v) {
    SET_VAR(surround, border.m_top.m_style, v);
  }
  void setBorderTopColor(const StyleColor& v) {
    SET_BORDERVALUE_COLOR(surround, border.m_top, v);
  }
  void setBorderBottomWidth(unsigned v) {
    SET_VAR(surround, border.m_bottom.m_width, v);
  }
  void setBorderBottomStyle(EBorderStyle v) {
    SET_VAR(surround, border.m_bottom.m_style, v);
  }
  void setBorderBottomColor(const StyleColor& v) {
    SET_BORDERVALUE_COLOR(surround, border.m_bottom, v);
  }

  void setOutlineWidth(unsigned short v) {
    SET_VAR(m_background, m_outline.m_width, v);
  }
  void setOutlineStyleIsAuto(OutlineIsAuto isAuto) {
    SET_VAR(m_background, m_outline.m_isAuto, isAuto);
  }
  void setOutlineStyle(EBorderStyle v) {
    SET_VAR(m_background, m_outline.m_style, v);
  }
  void setOutlineColor(const StyleColor& v) {
    SET_BORDERVALUE_COLOR(m_background, m_outline, v);
  }

  void setOverflowX(EOverflow v) { noninherited_flags.overflowX = v; }
  void setOverflowY(EOverflow v) { noninherited_flags.overflowY = v; }
  void setVisibility(EVisibility v) { inherited_flags._visibility = v; }
  void setVerticalAlign(EVerticalAlign v) {
    noninherited_flags.verticalAlign = v;
  }
  void setVerticalAlignLength(const Length& length) {
    setVerticalAlign(LENGTH);
    SET_VAR(m_box, m_verticalAlign, length);
  }

  void setHasAutoClip() {
    SET_VAR(visual, hasAutoClip, true);
    SET_VAR(visual, clip, RenderStyle::initialClip());
  }
  void setClip(const LengthBox& box) {
    SET_VAR(visual, hasAutoClip, false);
    SET_VAR(visual, clip, box);
  }

  void setUnicodeBidi(EUnicodeBidi b) { noninherited_flags.unicodeBidi = b; }

  bool setFontDescription(const FontDescription&);
  // Only used for text autosizing.
  void setFontSize(float);
  void setFontStretch(FontStretch);
  void setFontWeight(FontWeight);

  void setColor(const Color&);
  void setTextIndent(const Length& v) { SET_VAR(rareInheritedData, indent, v); }
  void setTextIndentLine(TextIndentLine v) {
    SET_VAR(rareInheritedData, m_textIndentLine, v);
  }
  void setTextIndentType(TextIndentType v) {
    SET_VAR(rareInheritedData, m_textIndentType, v);
  }
  void setTextAlign(ETextAlign v) { inherited_flags._text_align = v; }
  void setTextAlignLast(TextAlignLast v) {
    SET_VAR(rareInheritedData, m_textAlignLast, v);
  }
  void setTextJustify(TextJustify v) {
    SET_VAR(rareInheritedData, m_textJustify, v);
  }
  void applyTextDecorations();
  void clearAppliedTextDecorations();
  void setTextDecoration(TextDecoration v) {
    SET_VAR(visual, textDecoration, v);
  }
  void setTextUnderlinePosition(TextUnderlinePosition v) {
    SET_VAR(rareInheritedData, m_textUnderlinePosition, v);
  }
  void setTextDecorationStyle(TextDecorationStyle v) {
    SET_VAR(rareNonInheritedData, m_textDecorationStyle, v);
  }
  void setDirection(TextDirection v) { inherited_flags._direction = v; }
  void setLineHeight(const Length& specifiedLineHeight);

  void setImageRendering(EImageRendering v) {
    SET_VAR(rareInheritedData, m_imageRendering, v);
  }

  void setWhiteSpace(EWhiteSpace v) { inherited_flags._white_space = v; }

  // FIXME: Remove these two and replace them with respective FontBuilder calls.
  void setWordSpacing(float);
  void setLetterSpacing(float);

  void adjustBackgroundLayers() {
    if (backgroundLayers().next()) {
      accessBackgroundLayers().cullEmptyLayers();
      accessBackgroundLayers().fillUnsetProperties();
    }
  }

  void setHorizontalBorderSpacing(short);
  void setVerticalBorderSpacing(short);

  void setHasAspectRatio(bool b) {
    SET_VAR(rareNonInheritedData, m_hasAspectRatio, b);
  }
  void setAspectRatioDenominator(float v) {
    SET_VAR(rareNonInheritedData, m_aspectRatioDenominator, v);
  }
  void setAspectRatioNumerator(float v) {
    SET_VAR(rareNonInheritedData, m_aspectRatioNumerator, v);
  }

  void setMarginTop(const Length& v) { SET_VAR(surround, margin.m_top, v); }
  void setMarginBottom(const Length& v) {
    SET_VAR(surround, margin.m_bottom, v);
  }
  void setMarginLeft(const Length& v) { SET_VAR(surround, margin.m_left, v); }
  void setMarginRight(const Length& v) { SET_VAR(surround, margin.m_right, v); }
  void setMarginStart(const Length&);
  void setMarginEnd(const Length&);

  void resetPadding() { SET_VAR(surround, padding, LengthBox(Auto)); }
  void setPaddingBox(const LengthBox& b) { SET_VAR(surround, padding, b); }
  void setPaddingTop(const Length& v) { SET_VAR(surround, padding.m_top, v); }
  void setPaddingBottom(const Length& v) {
    SET_VAR(surround, padding.m_bottom, v);
  }
  void setPaddingLeft(const Length& v) { SET_VAR(surround, padding.m_left, v); }
  void setPaddingRight(const Length& v) {
    SET_VAR(surround, padding.m_right, v);
  }

  void setIsLink(bool b) { noninherited_flags.isLink = b; }

  bool hasAutoZIndex() const { return m_box->hasAutoZIndex(); }
  void setHasAutoZIndex() {
    SET_VAR(m_box, m_hasAutoZIndex, true);
    SET_VAR(m_box, m_zIndex, 0);
  }
  unsigned zIndex() const { return m_box->zIndex(); }
  void setZIndex(unsigned v) {
    SET_VAR(m_box, m_hasAutoZIndex, false);
    SET_VAR(m_box, m_zIndex, v);
  }

  // CSS3 Setters
  void setOutlineOffset(int v) { SET_VAR(m_background, m_outline.m_offset, v); }
  void setTextShadow(PassRefPtr<ShadowList>);
  void setTextStrokeColor(const StyleColor& c) {
    SET_VAR_WITH_SETTER(rareInheritedData, textStrokeColor, setTextStrokeColor,
                        c);
  }
  void setTextStrokeWidth(float w) {
    SET_VAR(rareInheritedData, textStrokeWidth, w);
  }
  void setTextFillColor(const StyleColor& c) {
    SET_VAR_WITH_SETTER(rareInheritedData, textFillColor, setTextFillColor, c);
  }
  void setOpacity(float f) {
    float v = clampTo<float>(f, 0, 1);
    SET_VAR(rareNonInheritedData, opacity, v);
  }
  // For valid values of box-align see
  // http://www.w3.org/TR/2009/WD-css3-flexbox-20090723/#alignment
  void setBoxDecorationBreak(EBoxDecorationBreak b) {
    SET_VAR(m_box, m_boxDecorationBreak, b);
  }
  void setBoxShadow(PassRefPtr<ShadowList>);
  void setBoxSizing(EBoxSizing s) { SET_VAR(m_box, m_boxSizing, s); }
  void setFlexGrow(float f) {
    SET_VAR(rareNonInheritedData.access()->m_flexibleBox, m_flexGrow, f);
  }
  void setFlexShrink(float f) {
    SET_VAR(rareNonInheritedData.access()->m_flexibleBox, m_flexShrink, f);
  }
  void setFlexBasis(const Length& length) {
    SET_VAR(rareNonInheritedData.access()->m_flexibleBox, m_flexBasis, length);
  }
  // We restrict the smallest value to int min + 2 because we use int min and
  // int min + 1 as special values in a hash set.
  void setOrder(int o) {
    SET_VAR(rareNonInheritedData, m_order,
            max(std::numeric_limits<int>::min() + 2, o));
  }
  void setAlignContent(EAlignContent p) {
    SET_VAR(rareNonInheritedData, m_alignContent, p);
  }
  void setAlignItems(ItemPosition a) {
    SET_VAR(rareNonInheritedData, m_alignItems, a);
  }
  void setAlignItemsOverflowAlignment(OverflowAlignment overflowAlignment) {
    SET_VAR(rareNonInheritedData, m_alignItemsOverflowAlignment,
            overflowAlignment);
  }
  void setAlignSelf(ItemPosition a) {
    SET_VAR(rareNonInheritedData, m_alignSelf, a);
  }
  void setAlignSelfOverflowAlignment(OverflowAlignment overflowAlignment) {
    SET_VAR(rareNonInheritedData, m_alignSelfOverflowAlignment,
            overflowAlignment);
  }
  void setFlexDirection(EFlexDirection direction) {
    SET_VAR(rareNonInheritedData.access()->m_flexibleBox, m_flexDirection,
            direction);
  }
  void setFlexWrap(EFlexWrap w) {
    SET_VAR(rareNonInheritedData.access()->m_flexibleBox, m_flexWrap, w);
  }
  void setJustifyContent(EJustifyContent p) {
    SET_VAR(rareNonInheritedData, m_justifyContent, p);
  }
  void setJustifyItems(ItemPosition justifyItems) {
    SET_VAR(rareNonInheritedData, m_justifyItems, justifyItems);
  }
  void setJustifyItemsOverflowAlignment(OverflowAlignment overflowAlignment) {
    SET_VAR(rareNonInheritedData, m_justifyItemsOverflowAlignment,
            overflowAlignment);
  }
  void setJustifyItemsPositionType(ItemPositionType positionType) {
    SET_VAR(rareNonInheritedData, m_justifyItemsPositionType, positionType);
  }
  void setJustifySelf(ItemPosition justifySelf) {
    SET_VAR(rareNonInheritedData, m_justifySelf, justifySelf);
  }
  void setJustifySelfOverflowAlignment(OverflowAlignment overflowAlignment) {
    SET_VAR(rareNonInheritedData, m_justifySelfOverflowAlignment,
            overflowAlignment);
  }

  void setUserModify(EUserModify u) {
    SET_VAR(rareInheritedData, userModify, u);
  }
  void setUserSelect(EUserSelect s) {
    SET_VAR(rareInheritedData, userSelect, s);
  }
  void setTextOverflow(TextOverflow overflow) {
    SET_VAR(rareNonInheritedData, textOverflow, overflow);
  }
  void setWordBreak(EWordBreak b) { SET_VAR(rareInheritedData, wordBreak, b); }
  void setOverflowWrap(EOverflowWrap b) {
    SET_VAR(rareInheritedData, overflowWrap, b);
  }
  void setLineBreak(LineBreak b) { SET_VAR(rareInheritedData, lineBreak, b); }
  void setHighlight(const AtomicString& h) {
    SET_VAR(rareInheritedData, highlight, h);
  }
  void setHyphens(Hyphens h) { SET_VAR(rareInheritedData, hyphens, h); }
  void setHyphenationString(const AtomicString& h) {
    SET_VAR(rareInheritedData, hyphenationString, h);
  }
  void setLocale(const AtomicString& locale) {
    SET_VAR(rareInheritedData, locale, locale);
  }
  void setTransform(const TransformOperations& ops) {
    SET_VAR(rareNonInheritedData.access()->m_transform, m_operations, ops);
  }
  void setTransformOriginX(const Length& l) {
    SET_VAR(rareNonInheritedData.access()->m_transform, m_x, l);
  }
  void setTransformOriginY(const Length& l) {
    SET_VAR(rareNonInheritedData.access()->m_transform, m_y, l);
  }
  void setTransformOriginZ(float f) {
    SET_VAR(rareNonInheritedData.access()->m_transform, m_z, f);
  }
  void setTextDecorationColor(const StyleColor& c) {
    SET_VAR(rareNonInheritedData, m_textDecorationColor, c);
  }
  void setTextEmphasisColor(const StyleColor& c) {
    SET_VAR_WITH_SETTER(rareInheritedData, textEmphasisColor,
                        setTextEmphasisColor, c);
  }
  void setTextEmphasisFill(TextEmphasisFill fill) {
    SET_VAR(rareInheritedData, textEmphasisFill, fill);
  }
  void setTextEmphasisMark(TextEmphasisMark mark) {
    SET_VAR(rareInheritedData, textEmphasisMark, mark);
  }
  void setTextEmphasisCustomMark(const AtomicString& mark) {
    SET_VAR(rareInheritedData, textEmphasisCustomMark, mark);
  }
  void setTextEmphasisPosition(TextEmphasisPosition position) {
    SET_VAR(rareInheritedData, textEmphasisPosition, position);
  }
  bool setTextOrientation(TextOrientation);

  void setObjectFit(ObjectFit f) {
    SET_VAR(rareNonInheritedData, m_objectFit, f);
  }
  void setObjectPosition(LengthPoint position) {
    SET_VAR(rareNonInheritedData, m_objectPosition, position);
  }

  void setTabSize(unsigned size) {
    SET_VAR(rareInheritedData, m_tabSize, size);
  }

  // End CSS3 Setters

  void setWrapFlow(WrapFlow wrapFlow) {
    SET_VAR(rareNonInheritedData, m_wrapFlow, wrapFlow);
  }
  void setWrapThrough(WrapThrough wrapThrough) {
    SET_VAR(rareNonInheritedData, m_wrapThrough, wrapThrough);
  }

  // Apple-specific property setters
  void setPointerEvents(EPointerEvents p) {
    inherited_flags._pointerEvents = p;
  }

  void setTransformStyle3D(ETransformStyle3D b) {
    SET_VAR(rareNonInheritedData, m_transformStyle3D, b);
  }
  void setPerspective(float p) {
    SET_VAR(rareNonInheritedData, m_perspective, p);
  }
  void setPerspectiveOriginX(const Length& l) {
    SET_VAR(rareNonInheritedData, m_perspectiveOriginX, l);
  }
  void setPerspectiveOriginY(const Length& l) {
    SET_VAR(rareNonInheritedData, m_perspectiveOriginY, l);
  }

  void setLineBoxContain(LineBoxContain c) {
    SET_VAR(rareInheritedData, m_lineBoxContain, c);
  }
  void setTapHighlightColor(const Color& c) {
    SET_VAR(rareInheritedData, tapHighlightColor, c);
  }
  void setTouchAction(TouchAction t) {
    SET_VAR(rareNonInheritedData, m_touchAction, t);
  }
  void setTouchActionDelay(TouchActionDelay t) {
    SET_VAR(rareInheritedData, m_touchActionDelay, t);
  }

  void setClipPath(PassRefPtr<ClipPathOperation> operation) {
    if (rareNonInheritedData->m_clipPath != operation)
      rareNonInheritedData.access()->m_clipPath = operation;
  }
  ClipPathOperation* clipPath() const {
    return rareNonInheritedData->m_clipPath.get();
  }

  // Flutter property setters
  void setEllipsis(const AtomicString& e) {
    SET_VAR(rareNonInheritedData, m_ellipsis, e);
  }
  void setMaxLines(int m) { SET_VAR(rareNonInheritedData, m_maxLines, m); }

  static ClipPathOperation* initialClipPath() { return 0; }

  const CounterDirectiveMap* counterDirectives() const;
  CounterDirectiveMap& accessCounterDirectives();
  const CounterDirectives getCounterDirectives(
      const AtomicString& identifier) const;

  const AtomicString& hyphenString() const;

  bool inheritedNotEqual(const RenderStyle*) const;
  bool inheritedDataShared(const RenderStyle*) const;

  bool requiresOnlyBlockChildren() const;
  bool isDisplayReplacedType() const {
    return isDisplayReplacedType(display());
  }
  bool isDisplayInlineType() const { return isDisplayInlineType(display()); }
  bool isOriginalDisplayInlineType() const {
    return isDisplayInlineType(originalDisplay());
  }
  bool isDisplayFlexibleBox() const { return isDisplayFlexibleBox(display()); }

  // A unique style is one that has matches something that makes it impossible
  // to share.
  bool unique() const { return noninherited_flags.unique; }
  void setUnique() { noninherited_flags.unique = true; }

  bool isSharable() const;

  bool emptyState() const { return noninherited_flags.emptyState; }
  void setEmptyState(bool b) {
    setUnique();
    noninherited_flags.emptyState = b;
  }
  bool firstChildState() const { return noninherited_flags.firstChildState; }
  void setFirstChildState() {
    setUnique();
    noninherited_flags.firstChildState = true;
  }
  bool lastChildState() const { return noninherited_flags.lastChildState; }
  void setLastChildState() {
    setUnique();
    noninherited_flags.lastChildState = true;
  }

  StyleColor decorationStyleColor() const;
  Color decorationColor() const;

  void setHasExplicitlyInheritedProperties() {
    noninherited_flags.explicitInheritance = true;
  }
  bool hasExplicitlyInheritedProperties() const {
    return noninherited_flags.explicitInheritance;
  }

  void setHasCurrentColor() { noninherited_flags.currentColor = true; }
  bool hasCurrentColor() const { return noninherited_flags.currentColor; }

  bool hasBoxDecorations() const {
    return hasBorder() || hasBorderRadius() || hasOutline() || boxShadow();
  }

  // Initial values for all the properties
  static EBorderStyle initialBorderStyle() { return BNONE; }
  static OutlineIsAuto initialOutlineStyleIsAuto() { return AUTO_OFF; }
  static LengthSize initialBorderRadius() {
    return LengthSize(Length(0, Fixed), Length(0, Fixed));
  }
  static LengthBox initialClip() { return LengthBox(); }
  static TextDirection initialDirection() { return LTR; }
  static TextOrientation initialTextOrientation() {
    return TextOrientationVerticalRight;
  }
  static ObjectFit initialObjectFit() { return ObjectFitFill; }
  static LengthPoint initialObjectPosition() {
    return LengthPoint(Length(50.0, Percent), Length(50.0, Percent));
  }
  static EDisplay initialDisplay() { return FLEX; }
  static EOverflow initialOverflowX() { return OVISIBLE; }
  static EOverflow initialOverflowY() { return OVISIBLE; }
  static EPosition initialPosition() { return StaticPosition; }
  static EUnicodeBidi initialUnicodeBidi() { return UBNormal; }
  static EVisibility initialVisibility() { return VISIBLE; }
  static EWhiteSpace initialWhiteSpace() { return PRE_WRAP; }
  static short initialHorizontalBorderSpacing() { return 0; }
  static short initialVerticalBorderSpacing() { return 0; }
  static Color initialColor() { return Color::white; }
  static unsigned initialBorderWidth() { return 3; }
  static unsigned short initialColumnRuleWidth() { return 3; }
  static unsigned short initialOutlineWidth() { return 3; }
  static float initialLetterWordSpacing() { return 0.0f; }
  static Length initialSize() { return Length(); }
  static Length initialMinSize() { return Length(Fixed); }
  static Length initialMaxSize() { return Length(MaxSizeNone); }
  static Length initialOffset() { return Length(); }
  static Length initialMargin() { return Length(Fixed); }
  static Length initialPadding() { return Length(Fixed); }
  static Length initialTextIndent() { return Length(Fixed); }
  static TextIndentLine initialTextIndentLine() { return TextIndentFirstLine; }
  static TextIndentType initialTextIndentType() { return TextIndentNormal; }
  static EVerticalAlign initialVerticalAlign() { return BASELINE; }
  static Length initialLineHeight() { return Length(-100.0, Percent); }
  static ETextAlign initialTextAlign() { return TASTART; }
  static TextAlignLast initialTextAlignLast() { return TextAlignLastAuto; }
  static TextJustify initialTextJustify() { return TextJustifyAuto; }
  static TextDecoration initialTextDecoration() { return TextDecorationNone; }
  static TextUnderlinePosition initialTextUnderlinePosition() {
    return TextUnderlinePositionAuto;
  }
  static TextDecorationStyle initialTextDecorationStyle() {
    return TextDecorationStyleSolid;
  }
  static int initialOutlineOffset() { return 0; }
  static float initialOpacity() { return 1.0f; }
  static EBoxAlignment initialBoxAlign() { return BSTRETCH; }
  static EBoxDecorationBreak initialBoxDecorationBreak() { return DSLICE; }
  static EBoxDirection initialBoxDirection() { return BNORMAL; }
  static EBoxLines initialBoxLines() { return SINGLE; }
  static EBoxOrient initialBoxOrient() { return HORIZONTAL; }
  static EBoxPack initialBoxPack() { return Start; }
  static float initialBoxFlex() { return 0.0f; }
  static unsigned initialBoxFlexGroup() { return 1; }
  static unsigned initialBoxOrdinalGroup() { return 1; }
  static EBoxSizing initialBoxSizing() { return CONTENT_BOX; }
  static float initialFlexGrow() { return 0; }
  static float initialFlexShrink() { return 0; }
  static Length initialFlexBasis() { return Length(Auto); }
  static int initialOrder() { return 0; }
  static EAlignContent initialAlignContent() { return AlignContentStretch; }
  static ItemPosition initialAlignItems() { return ItemPositionStretch; }
  static OverflowAlignment initialAlignItemsOverflowAlignment() {
    return OverflowAlignmentDefault;
  }
  static ItemPosition initialAlignSelf() { return ItemPositionAuto; }
  static OverflowAlignment initialAlignSelfOverflowAlignment() {
    return OverflowAlignmentDefault;
  }
  static EFlexDirection initialFlexDirection() { return FlowColumn; }
  static EFlexWrap initialFlexWrap() { return FlexNoWrap; }
  static EJustifyContent initialJustifyContent() { return JustifyFlexStart; }
  static ItemPosition initialJustifyItems() { return ItemPositionAuto; }
  static OverflowAlignment initialJustifyItemsOverflowAlignment() {
    return OverflowAlignmentDefault;
  }
  static ItemPositionType initialJustifyItemsPositionType() {
    return NonLegacyPosition;
  }
  static ItemPosition initialJustifySelf() { return ItemPositionAuto; }
  static OverflowAlignment initialJustifySelfOverflowAlignment() {
    return OverflowAlignmentDefault;
  }
  static EUserModify initialUserModify() { return READ_ONLY; }
  static EUserSelect initialUserSelect() { return SELECT_TEXT; }
  static TextOverflow initialTextOverflow() { return TextOverflowClip; }
  static EWordBreak initialWordBreak() { return NormalWordBreak; }
  static EOverflowWrap initialOverflowWrap() { return BreakOverflowWrap; }
  static LineBreak initialLineBreak() { return LineBreakAuto; }
  static const AtomicString& initialHighlight() { return nullAtom; }
  static const AtomicString& initialHyphenationString() { return nullAtom; }
  static const AtomicString& initialLocale() { return nullAtom; }
  static bool initialHasAspectRatio() { return false; }
  static float initialAspectRatioDenominator() { return 1; }
  static float initialAspectRatioNumerator() { return 1; }
  static Order initialRTLOrdering() { return LogicalOrder; }
  static float initialTextStrokeWidth() { return 0; }
  static unsigned short initialColumnCount() { return 1; }
  static ColumnFill initialColumnFill() { return ColumnFillBalance; }
  static const TransformOperations& initialTransform() {
    DEFINE_STATIC_LOCAL(TransformOperations, ops, ());
    return ops;
  }
  static Length initialTransformOriginX() { return Length(50.0, Percent); }
  static Length initialTransformOriginY() { return Length(50.0, Percent); }
  static EPointerEvents initialPointerEvents() { return PE_AUTO; }
  static float initialTransformOriginZ() { return 0; }
  static ETransformStyle3D initialTransformStyle3D() {
    return TransformStyle3DFlat;
  }
  static float initialPerspective() { return 0; }
  static Length initialPerspectiveOriginX() { return Length(50.0, Percent); }
  static Length initialPerspectiveOriginY() { return Length(50.0, Percent); }
  static Color initialBackgroundColor() { return Color::transparent; }
  static TextEmphasisFill initialTextEmphasisFill() {
    return TextEmphasisFillFilled;
  }
  static TextEmphasisMark initialTextEmphasisMark() {
    return TextEmphasisMarkNone;
  }
  static const AtomicString& initialTextEmphasisCustomMark() {
    return nullAtom;
  }
  static TextEmphasisPosition initialTextEmphasisPosition() {
    return TextEmphasisPositionOver;
  }
  static LineBoxContain initialLineBoxContain() {
    return LineBoxContainBlock | LineBoxContainInline | LineBoxContainReplaced;
  }
  static ImageOrientationEnum initialImageOrientation() {
    return OriginTopLeft;
  }
  static EImageRendering initialImageRendering() { return ImageRenderingAuto; }
  static ImageResolutionSource initialImageResolutionSource() {
    return ImageResolutionSpecified;
  }
  static ImageResolutionSnap initialImageResolutionSnap() {
    return ImageResolutionNoSnap;
  }
  static float initialImageResolution() { return 1; }
  static TouchAction initialTouchAction() { return TouchActionAuto; }
  static TouchActionDelay initialTouchActionDelay() {
    return TouchActionDelayScript;
  }
  static ShadowList* initialBoxShadow() { return 0; }
  static ShadowList* initialTextShadow() { return 0; }

  static unsigned initialTabSize() { return 8; }

  static WrapFlow initialWrapFlow() { return WrapFlowAuto; }
  static WrapThrough initialWrapThrough() { return WrapThroughWrap; }

  // Keep these at the end.
  // FIXME: Why? Seems these should all be one big sorted list.
  static Color initialTapHighlightColor();

  Color resolveColor(StyleColor unresolvedColor) const {
    return unresolvedColor.resolve(color());
  }

  StyleColor borderLeftColor() const { return surround->border.left().color(); }
  StyleColor borderRightColor() const {
    return surround->border.right().color();
  }
  StyleColor borderTopColor() const { return surround->border.top().color(); }
  StyleColor borderBottomColor() const {
    return surround->border.bottom().color();
  }
  StyleColor backgroundColor() const { return m_background->color(); }
  Color color() const;
  StyleColor textEmphasisColor() const {
    return rareInheritedData->textEmphasisColor();
  }
  StyleColor textFillColor() const {
    return rareInheritedData->textFillColor();
  }
  StyleColor textStrokeColor() const {
    return rareInheritedData->textStrokeColor();
  }

 private:
  void inheritUnicodeBidiFrom(const RenderStyle* parent) {
    noninherited_flags.unicodeBidi = parent->noninherited_flags.unicodeBidi;
  }
  void getShadowExtent(const ShadowList*,
                       LayoutUnit& top,
                       LayoutUnit& right,
                       LayoutUnit& bottom,
                       LayoutUnit& left) const;
  LayoutBoxExtent getShadowInsetExtent(const ShadowList*) const;
  void getShadowHorizontalExtent(const ShadowList*,
                                 LayoutUnit& left,
                                 LayoutUnit& right) const;
  void getShadowVerticalExtent(const ShadowList*,
                               LayoutUnit& top,
                               LayoutUnit& bottom) const;
  void getShadowInlineDirectionExtent(const ShadowList* shadow,
                                      LayoutUnit& logicalLeft,
                                      LayoutUnit& logicalRight) const {
    return getShadowHorizontalExtent(shadow, logicalLeft, logicalRight);
  }
  void getShadowBlockDirectionExtent(const ShadowList* shadow,
                                     LayoutUnit& logicalTop,
                                     LayoutUnit& logicalBottom) const {
    return getShadowVerticalExtent(shadow, logicalTop, logicalBottom);
  }

  bool isDisplayFlexibleBox(EDisplay display) const {
    return display == FLEX || display == INLINE_FLEX;
  }

  bool isDisplayReplacedType(EDisplay display) const {
    return display == INLINE_FLEX;
  }

  bool isDisplayInlineType(EDisplay display) const {
    return display == INLINE || isDisplayReplacedType(display);
  }

  StyleColor textDecorationColor() const {
    return rareNonInheritedData->m_textDecorationColor;
  }

  void addAppliedTextDecoration(const AppliedTextDecoration&);

  bool diffNeedsFullLayout(const RenderStyle& other) const;
  bool diffNeedsRecompositeLayer(const RenderStyle& other) const;
  void updatePropertySpecificDifferences(const RenderStyle& other,
                                         StyleDifference&) const;
};

inline bool RenderStyle::isSharable() const {
  return !unique();
}

inline bool RenderStyle::setTextOrientation(TextOrientation textOrientation) {
  if (compareEqual(rareInheritedData->m_textOrientation, textOrientation))
    return false;

  rareInheritedData.access()->m_textOrientation = textOrientation;
  return true;
}

float calcBorderRadiiConstraintScaleFor(const FloatRect&,
                                        const FloatRoundedRect::Radii&);

}  // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_STYLE_RENDERSTYLE_H_
