/*
 * Copyright (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010 Apple Inc.
 * All rights reserved.
 * Copyright (C) 2011 Adobe Systems Incorporated. All rights reserved.
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

#include "flutter/sky/engine/core/rendering/style/RenderStyle.h"

#include <algorithm>
#include "flutter/sky/engine/core/rendering/RenderTheme.h"
#include "flutter/sky/engine/core/rendering/style/AppliedTextDecoration.h"
#include "flutter/sky/engine/core/rendering/style/DataEquivalency.h"
#include "flutter/sky/engine/core/rendering/style/ShadowList.h"
#include "flutter/sky/engine/core/rendering/style/StyleImage.h"
#include "flutter/sky/engine/core/rendering/style/StyleInheritedData.h"
#include "flutter/sky/engine/platform/LengthFunctions.h"
#include "flutter/sky/engine/platform/fonts/Font.h"
#include "flutter/sky/engine/platform/fonts/FontSelector.h"
#include "flutter/sky/engine/platform/geometry/FloatRoundedRect.h"
#include "flutter/sky/engine/wtf/MathExtras.h"

namespace blink {

struct SameSizeAsBorderValue {
  RGBA32 m_color;
  unsigned m_width;
};

COMPILE_ASSERT(sizeof(BorderValue) == sizeof(SameSizeAsBorderValue),
               BorderValue_should_not_grow);

inline RenderStyle* defaultStyle() {
  DEFINE_STATIC_REF(RenderStyle, s_defaultStyle,
                    (RenderStyle::createDefaultStyle()));
  return s_defaultStyle;
}

PassRefPtr<RenderStyle> RenderStyle::create() {
  return adoptRef(new RenderStyle());
}

PassRefPtr<RenderStyle> RenderStyle::createDefaultStyle() {
  return adoptRef(new RenderStyle(DefaultStyle));
}

PassRefPtr<RenderStyle> RenderStyle::clone(const RenderStyle* other) {
  return adoptRef(new RenderStyle(*other));
}

ALWAYS_INLINE RenderStyle::RenderStyle()
    : m_box(defaultStyle()->m_box),
      visual(defaultStyle()->visual),
      m_background(defaultStyle()->m_background),
      surround(defaultStyle()->surround),
      rareNonInheritedData(defaultStyle()->rareNonInheritedData),
      rareInheritedData(defaultStyle()->rareInheritedData),
      inherited(defaultStyle()->inherited) {
  setBitDefaults();  // Would it be faster to copy this from the default style?
  COMPILE_ASSERT((sizeof(InheritedFlags) <= 8), InheritedFlags_does_not_grow);
  COMPILE_ASSERT((sizeof(NonInheritedFlags) <= 8),
                 NonInheritedFlags_does_not_grow);
}

ALWAYS_INLINE RenderStyle::RenderStyle(DefaultStyleTag) {
  setBitDefaults();

  m_box.init();
  visual.init();
  m_background.init();
  surround.init();
  rareNonInheritedData.init();
  rareNonInheritedData.access()->m_flexibleBox.init();
  rareNonInheritedData.access()->m_transform.init();
  rareNonInheritedData.access()->m_filter.init();
  rareInheritedData.init();
  inherited.init();
}

ALWAYS_INLINE RenderStyle::RenderStyle(const RenderStyle& o)
    : RefCounted<RenderStyle>(),
      m_box(o.m_box),
      visual(o.visual),
      m_background(o.m_background),
      surround(o.surround),
      rareNonInheritedData(o.rareNonInheritedData),
      rareInheritedData(o.rareInheritedData),
      inherited(o.inherited),
      inherited_flags(o.inherited_flags),
      noninherited_flags(o.noninherited_flags) {}

StyleRecalcChange RenderStyle::stylePropagationDiff(
    const RenderStyle* oldStyle,
    const RenderStyle* newStyle) {
  if ((!oldStyle && newStyle) || (oldStyle && !newStyle))
    return Reattach;

  if (!oldStyle && !newStyle)
    return NoChange;

  if (oldStyle->display() != newStyle->display() ||
      oldStyle->justifyItems() != newStyle->justifyItems() ||
      oldStyle->alignItems() != newStyle->alignItems())
    return Reattach;

  if (*oldStyle == *newStyle)
    return NoChange;

  if (oldStyle->inheritedNotEqual(newStyle) ||
      oldStyle->hasExplicitlyInheritedProperties() ||
      newStyle->hasExplicitlyInheritedProperties())
    return Inherit;

  return NoInherit;
}

void RenderStyle::inheritFrom(const RenderStyle* inheritParent) {
  rareInheritedData = inheritParent->rareInheritedData;
  inherited = inheritParent->inherited;
  inherited_flags = inheritParent->inherited_flags;
}

void RenderStyle::copyNonInheritedFrom(const RenderStyle* other) {
  m_box = other->m_box;
  visual = other->visual;
  m_background = other->m_background;
  surround = other->surround;
  rareNonInheritedData = other->rareNonInheritedData;
  // The flags are copied one-by-one because noninherited_flags contains a bunch
  // of stuff other than real style data.
  noninherited_flags.effectiveDisplay =
      other->noninherited_flags.effectiveDisplay;
  noninherited_flags.originalDisplay =
      other->noninherited_flags.originalDisplay;
  noninherited_flags.overflowX = other->noninherited_flags.overflowX;
  noninherited_flags.overflowY = other->noninherited_flags.overflowY;
  noninherited_flags.verticalAlign = other->noninherited_flags.verticalAlign;
  noninherited_flags.position = other->noninherited_flags.position;
  noninherited_flags.unicodeBidi = other->noninherited_flags.unicodeBidi;
  noninherited_flags.explicitInheritance =
      other->noninherited_flags.explicitInheritance;
  noninherited_flags.currentColor = other->noninherited_flags.currentColor;
  noninherited_flags.hasViewportUnits =
      other->noninherited_flags.hasViewportUnits;
}

bool RenderStyle::operator==(const RenderStyle& o) const {
  // compare everything except the pseudoStyle pointer
  return inherited_flags == o.inherited_flags &&
         noninherited_flags == o.noninherited_flags && m_box == o.m_box &&
         visual == o.visual && m_background == o.m_background &&
         surround == o.surround &&
         rareNonInheritedData == o.rareNonInheritedData &&
         rareInheritedData == o.rareInheritedData && inherited == o.inherited;
}

bool RenderStyle::inheritedNotEqual(const RenderStyle* other) const {
  return inherited_flags != other->inherited_flags ||
         inherited != other->inherited ||
         rareInheritedData != other->rareInheritedData;
}

bool RenderStyle::inheritedDataShared(const RenderStyle* other) const {
  // This is a fast check that only looks if the data structures are shared.
  return inherited_flags == other->inherited_flags &&
         inherited.get() == other->inherited.get() &&
         rareInheritedData.get() == other->rareInheritedData.get();
}

bool RenderStyle::requiresOnlyBlockChildren() const {
  switch (display()) {
    case PARAGRAPH:
    case INLINE:
      return false;

    case FLEX:
    case INLINE_FLEX:
      return true;

    case NONE:
      ASSERT_NOT_REACHED();
      return false;
  }

  ASSERT_NOT_REACHED();
  return false;
}

static bool positionedObjectMovedOnly(const LengthBox& a,
                                      const LengthBox& b,
                                      const Length& width) {
  // If any unit types are different, then we can't guarantee
  // that this was just a movement.
  if (a.left().type() != b.left().type() ||
      a.right().type() != b.right().type() ||
      a.top().type() != b.top().type() ||
      a.bottom().type() != b.bottom().type())
    return false;

  // Only one unit can be non-auto in the horizontal direction and
  // in the vertical direction.  Otherwise the adjustment of values
  // is changing the size of the box.
  if (!a.left().isIntrinsicOrAuto() && !a.right().isIntrinsicOrAuto())
    return false;
  if (!a.top().isIntrinsicOrAuto() && !a.bottom().isIntrinsicOrAuto())
    return false;
  // If our width is auto and left or right is specified and changed then this
  // is not just a movement - we need to resize to our container.
  if (width.isIntrinsicOrAuto() &&
      ((!a.left().isIntrinsicOrAuto() && a.left() != b.left()) ||
       (!a.right().isIntrinsicOrAuto() && a.right() != b.right())))
    return false;

  // One of the units is fixed or percent in both directions and stayed
  // that way in the new style.  Therefore all we are doing is moving.
  return true;
}

StyleDifference RenderStyle::visualInvalidationDiff(
    const RenderStyle& other) const {
  // Note, we use .get() on each DataRef below because DataRef::operator== will
  // do a deep compare, which is duplicate work when we're going to compare each
  // property inside this function anyway.

  StyleDifference diff;

  if (diffNeedsFullLayout(other)) {
    diff.setNeedsFullLayout();
  } else if (position() != StaticPosition &&
             surround->offset != other.surround->offset) {
    // Optimize for the case where a positioned layer is moving but not changing
    // size.
    if (positionedObjectMovedOnly(surround->offset, other.surround->offset,
                                  m_box->width()))
      diff.setNeedsPositionedMovementLayout();
    else
      diff.setNeedsFullLayout();
  }

  updatePropertySpecificDifferences(other, diff);

  // Cursors are not checked, since they will be set appropriately in response
  // to mouse events, so they don't need to cause any paint invalidation or
  // layout.

  return diff;
}

bool RenderStyle::diffNeedsFullLayout(const RenderStyle& other) const {
  // FIXME: Not all cases in this method need both full layout and paint
  // invalidation. Should move cases into diffNeedsFullLayout() if
  // - don't need paint invalidation at all;
  // - or the renderer knows how to exactly invalidate paints caused by the
  // layout change
  //   instead of forced full paint invalidation.

  if (surround.get() != other.surround.get()) {
    // If our border widths change, then we need to layout. Other changes to
    // borders only necessitate a paint invalidation.
    if (borderLeftWidth() != other.borderLeftWidth() ||
        borderTopWidth() != other.borderTopWidth() ||
        borderBottomWidth() != other.borderBottomWidth() ||
        borderRightWidth() != other.borderRightWidth())
      return true;
  }

  if (rareNonInheritedData.get() != other.rareNonInheritedData.get()) {
    if (rareNonInheritedData->textOverflow !=
            other.rareNonInheritedData->textOverflow ||
        rareNonInheritedData->m_wrapFlow !=
            other.rareNonInheritedData->m_wrapFlow ||
        rareNonInheritedData->m_wrapThrough !=
            other.rareNonInheritedData->m_wrapThrough ||
        rareNonInheritedData->m_order != other.rareNonInheritedData->m_order ||
        rareNonInheritedData->m_alignContent !=
            other.rareNonInheritedData->m_alignContent ||
        rareNonInheritedData->m_alignItems !=
            other.rareNonInheritedData->m_alignItems ||
        rareNonInheritedData->m_alignSelf !=
            other.rareNonInheritedData->m_alignSelf ||
        rareNonInheritedData->m_justifyContent !=
            other.rareNonInheritedData->m_justifyContent)
      return true;

    if (rareNonInheritedData->m_flexibleBox.get() !=
            other.rareNonInheritedData->m_flexibleBox.get() &&
        *rareNonInheritedData->m_flexibleBox.get() !=
            *other.rareNonInheritedData->m_flexibleBox.get())
      return true;

    // FIXME: We should add an optimized form of layout that just recomputes
    // visual overflow.
    if (!rareNonInheritedData->shadowDataEquivalent(
            *other.rareNonInheritedData.get()))
      return true;

    // If the counter directives change, trigger a relayout to re-calculate
    // counter values and rebuild the counter node tree.
    const CounterDirectiveMap* mapA =
        rareNonInheritedData->m_counterDirectives.get();
    const CounterDirectiveMap* mapB =
        other.rareNonInheritedData->m_counterDirectives.get();
    if (!(mapA == mapB || (mapA && mapB && *mapA == *mapB)))
      return true;

    // We only need do layout for opacity changes if adding or losing opacity
    // could trigger a change in us being a stacking context.
    if (hasAutoZIndex() != other.hasAutoZIndex() &&
        rareNonInheritedData->hasOpacity() !=
            other.rareNonInheritedData->hasOpacity()) {
      // FIXME: We would like to use SimplifiedLayout here, but we can't quite
      // do that yet. We need to make sure SimplifiedLayout can operate
      // correctly on RenderInlines (we will need to add a
      // selfNeedsSimplifiedLayout bit in order to not get confused and taint
      // every line). In addition we need to solve the floating object issue
      // when layers come and go. Right now a full layout is necessary to keep
      // floating object lists sane.
      return true;
    }
  }

  if (rareInheritedData.get() != other.rareInheritedData.get()) {
    if (rareInheritedData->highlight != other.rareInheritedData->highlight ||
        rareInheritedData->indent != other.rareInheritedData->indent ||
        rareInheritedData->m_textAlignLast !=
            other.rareInheritedData->m_textAlignLast ||
        rareInheritedData->m_textIndentLine !=
            other.rareInheritedData->m_textIndentLine ||
        rareInheritedData->wordBreak != other.rareInheritedData->wordBreak ||
        rareInheritedData->overflowWrap !=
            other.rareInheritedData->overflowWrap ||
        rareInheritedData->lineBreak != other.rareInheritedData->lineBreak ||
        rareInheritedData->hyphens != other.rareInheritedData->hyphens ||
        rareInheritedData->hyphenationLimitBefore !=
            other.rareInheritedData->hyphenationLimitBefore ||
        rareInheritedData->hyphenationLimitAfter !=
            other.rareInheritedData->hyphenationLimitAfter ||
        rareInheritedData->hyphenationString !=
            other.rareInheritedData->hyphenationString ||
        rareInheritedData->locale != other.rareInheritedData->locale ||
        rareInheritedData->textEmphasisMark !=
            other.rareInheritedData->textEmphasisMark ||
        rareInheritedData->textEmphasisPosition !=
            other.rareInheritedData->textEmphasisPosition ||
        rareInheritedData->textEmphasisCustomMark !=
            other.rareInheritedData->textEmphasisCustomMark ||
        rareInheritedData->m_textJustify !=
            other.rareInheritedData->m_textJustify ||
        rareInheritedData->m_textOrientation !=
            other.rareInheritedData->m_textOrientation ||
        rareInheritedData->m_tabSize != other.rareInheritedData->m_tabSize ||
        rareInheritedData->m_lineBoxContain !=
            other.rareInheritedData->m_lineBoxContain ||
        rareInheritedData->textStrokeWidth !=
            other.rareInheritedData->textStrokeWidth)
      return true;

    if (!rareInheritedData->shadowDataEquivalent(
            *other.rareInheritedData.get()))
      return true;
  }

  if (inherited.get() != other.inherited.get()) {
    if (inherited->line_height != other.inherited->line_height ||
        inherited->font != other.inherited->font ||
        inherited->horizontal_border_spacing !=
            other.inherited->horizontal_border_spacing ||
        inherited->vertical_border_spacing !=
            other.inherited->vertical_border_spacing)
      return true;
  }

  if (inherited_flags.m_rtlOrdering != other.inherited_flags.m_rtlOrdering ||
      inherited_flags._text_align != other.inherited_flags._text_align ||
      inherited_flags._direction != other.inherited_flags._direction ||
      inherited_flags._white_space != other.inherited_flags._white_space)
    return true;

  if (noninherited_flags.overflowX != other.noninherited_flags.overflowX ||
      noninherited_flags.overflowY != other.noninherited_flags.overflowY ||
      noninherited_flags.unicodeBidi != other.noninherited_flags.unicodeBidi ||
      noninherited_flags.position != other.noninherited_flags.position ||
      noninherited_flags.originalDisplay !=
          other.noninherited_flags.originalDisplay)
    return true;

  if (!m_background->outline().visuallyEqual(other.m_background->outline())) {
    // FIXME: We only really need to recompute the overflow but we don't have an
    // optimized layout for it.
    return true;
  }

  if (m_box.get() != other.m_box.get()) {
    if (m_box->width() != other.m_box->width() ||
        m_box->minWidth() != other.m_box->minWidth() ||
        m_box->maxWidth() != other.m_box->maxWidth() ||
        m_box->height() != other.m_box->height() ||
        m_box->minHeight() != other.m_box->minHeight() ||
        m_box->maxHeight() != other.m_box->maxHeight())
      return true;

    if (m_box->verticalAlign() != other.m_box->verticalAlign())
      return true;

    if (m_box->boxSizing() != other.m_box->boxSizing())
      return true;
  }

  if (noninherited_flags.verticalAlign !=
      other.noninherited_flags.verticalAlign)
    return true;

  if (surround.get() != other.surround.get()) {
    if (surround->margin != other.surround->margin)
      return true;

    if (surround->padding != other.surround->padding)
      return true;
  }

  // Movement of non-static-positioned object is special cased in
  // RenderStyle::visualInvalidationDiff().

  return false;
}

void RenderStyle::updatePropertySpecificDifferences(
    const RenderStyle& other,
    StyleDifference& diff) const {
  // StyleAdjuster has ensured that zIndex is non-auto only if it's applicable.
  if (m_box->zIndex() != other.m_box->zIndex() ||
      m_box->hasAutoZIndex() != other.m_box->hasAutoZIndex())
    diff.setZIndexChanged();

  if (rareNonInheritedData.get() != other.rareNonInheritedData.get()) {
    if (!transformDataEquivalent(other))
      diff.setTransformChanged();

    if (rareNonInheritedData->opacity != other.rareNonInheritedData->opacity)
      diff.setOpacityChanged();

    if (rareNonInheritedData->m_filter != other.rareNonInheritedData->m_filter)
      diff.setFilterChanged();
  }
}

inline bool requireTransformOrigin(
    const Vector<RefPtr<TransformOperation>>& transformOperations,
    RenderStyle::ApplyTransformOrigin applyOrigin) {
  // transform-origin brackets the transform with translate operations.
  // Optimize for the case where the only transform is a translation, since the
  // transform-origin is irrelevant in that case.
  if (applyOrigin != RenderStyle::IncludeTransformOrigin)
    return false;

  unsigned size = transformOperations.size();
  for (unsigned i = 0; i < size; ++i) {
    TransformOperation::OperationType type = transformOperations[i]->type();
    if (type != TransformOperation::TranslateX &&
        type != TransformOperation::TranslateY &&
        type != TransformOperation::Translate &&
        type != TransformOperation::TranslateZ &&
        type != TransformOperation::Translate3D)
      return true;
  }

  return false;
}

void RenderStyle::applyTransform(TransformationMatrix& transform,
                                 const LayoutSize& borderBoxSize,
                                 ApplyTransformOrigin applyOrigin) const {
  applyTransform(transform, FloatRect(FloatPoint(), borderBoxSize),
                 applyOrigin);
}

void RenderStyle::applyTransform(TransformationMatrix& transform,
                                 const FloatRect& boundingBox,
                                 ApplyTransformOrigin applyOrigin) const {
  const Vector<RefPtr<TransformOperation>>& transformOperations =
      rareNonInheritedData->m_transform->m_operations.operations();
  bool applyTransformOrigin =
      requireTransformOrigin(transformOperations, applyOrigin);

  float offsetX = transformOriginX().type() == Percent ? boundingBox.x() : 0;
  float offsetY = transformOriginY().type() == Percent ? boundingBox.y() : 0;

  if (applyTransformOrigin) {
    transform.translate3d(
        floatValueForLength(transformOriginX(), boundingBox.width()) + offsetX,
        floatValueForLength(transformOriginY(), boundingBox.height()) + offsetY,
        transformOriginZ());
  }

  unsigned size = transformOperations.size();
  for (unsigned i = 0; i < size; ++i)
    transformOperations[i]->apply(transform, boundingBox.size());

  if (applyTransformOrigin) {
    transform.translate3d(
        -floatValueForLength(transformOriginX(), boundingBox.width()) - offsetX,
        -floatValueForLength(transformOriginY(), boundingBox.height()) -
            offsetY,
        -transformOriginZ());
  }
}

void RenderStyle::setTextShadow(PassRefPtr<ShadowList> s) {
  rareInheritedData.access()->textShadow = s;
}

void RenderStyle::setBoxShadow(PassRefPtr<ShadowList> s) {
  rareNonInheritedData.access()->m_boxShadow = s;
}

static RoundedRect::Radii calcRadiiFor(const BorderData& border, IntSize size) {
  return RoundedRect::Radii(
      IntSize(valueForLength(border.topLeft().width(), size.width()),
              valueForLength(border.topLeft().height(), size.height())),
      IntSize(valueForLength(border.topRight().width(), size.width()),
              valueForLength(border.topRight().height(), size.height())),
      IntSize(valueForLength(border.bottomLeft().width(), size.width()),
              valueForLength(border.bottomLeft().height(), size.height())),
      IntSize(valueForLength(border.bottomRight().width(), size.width()),
              valueForLength(border.bottomRight().height(), size.height())));
}

Color RenderStyle::color() const {
  return inherited->color;
}
void RenderStyle::setColor(const Color& v) {
  SET_VAR(inherited, color, v);
}

short RenderStyle::horizontalBorderSpacing() const {
  return inherited->horizontal_border_spacing;
}
short RenderStyle::verticalBorderSpacing() const {
  return inherited->vertical_border_spacing;
}
void RenderStyle::setHorizontalBorderSpacing(short v) {
  SET_VAR(inherited, horizontal_border_spacing, v);
}
void RenderStyle::setVerticalBorderSpacing(short v) {
  SET_VAR(inherited, vertical_border_spacing, v);
}

RoundedRect RenderStyle::getRoundedBorderFor(
    const LayoutRect& borderRect,
    bool includeLogicalLeftEdge,
    bool includeLogicalRightEdge) const {
  IntRect snappedBorderRect(pixelSnappedIntRect(borderRect));
  RoundedRect roundedRect(snappedBorderRect);
  if (hasBorderRadius()) {
    RoundedRect::Radii radii =
        calcRadiiFor(surround->border, snappedBorderRect.size());
    radii.scale(calcBorderRadiiConstraintScaleFor(borderRect, radii));
    roundedRect.includeLogicalEdges(radii, includeLogicalLeftEdge,
                                    includeLogicalRightEdge);
  }
  return roundedRect;
}

RoundedRect RenderStyle::getRoundedInnerBorderFor(
    const LayoutRect& borderRect,
    bool includeLogicalLeftEdge,
    bool includeLogicalRightEdge) const {
  int leftWidth = (includeLogicalLeftEdge) ? borderLeftWidth() : 0;
  int rightWidth = (includeLogicalRightEdge) ? borderRightWidth() : 0;
  int topWidth = borderTopWidth();
  int bottomWidth = borderBottomWidth();

  return getRoundedInnerBorderFor(borderRect, topWidth, bottomWidth, leftWidth,
                                  rightWidth, includeLogicalLeftEdge,
                                  includeLogicalRightEdge);
}

RoundedRect RenderStyle::getRoundedInnerBorderFor(
    const LayoutRect& borderRect,
    int topWidth,
    int bottomWidth,
    int leftWidth,
    int rightWidth,
    bool includeLogicalLeftEdge,
    bool includeLogicalRightEdge) const {
  LayoutRect innerRect(borderRect.x() + leftWidth, borderRect.y() + topWidth,
                       borderRect.width() - leftWidth - rightWidth,
                       borderRect.height() - topWidth - bottomWidth);

  RoundedRect roundedRect(pixelSnappedIntRect(innerRect));

  if (hasBorderRadius()) {
    RoundedRect::Radii radii = getRoundedBorderFor(borderRect).radii();
    radii.shrink(topWidth, bottomWidth, leftWidth, rightWidth);
    roundedRect.includeLogicalEdges(radii, includeLogicalLeftEdge,
                                    includeLogicalRightEdge);
  }
  return roundedRect;
}

static bool allLayersAreFixed(const FillLayer& layer) {
  for (const FillLayer* currLayer = &layer; currLayer;
       currLayer = currLayer->next()) {
    if (!currLayer->image() ||
        currLayer->attachment() != FixedBackgroundAttachment)
      return false;
  }

  return true;
}

bool RenderStyle::hasEntirelyFixedBackground() const {
  return allLayersAreFixed(backgroundLayers());
}

const CounterDirectiveMap* RenderStyle::counterDirectives() const {
  return rareNonInheritedData->m_counterDirectives.get();
}

CounterDirectiveMap& RenderStyle::accessCounterDirectives() {
  OwnPtr<CounterDirectiveMap>& map =
      rareNonInheritedData.access()->m_counterDirectives;
  if (!map)
    map = adoptPtr(new CounterDirectiveMap);
  return *map;
}

const CounterDirectives RenderStyle::getCounterDirectives(
    const AtomicString& identifier) const {
  if (const CounterDirectiveMap* directives = counterDirectives())
    return directives->get(identifier);
  return CounterDirectives();
}

const AtomicString& RenderStyle::hyphenString() const {
  const AtomicString& hyphenationString =
      rareInheritedData.get()->hyphenationString;
  if (!hyphenationString.isNull())
    return hyphenationString;

  // FIXME: This should depend on locale.
  DEFINE_STATIC_LOCAL(AtomicString, hyphenMinusString, (&hyphenMinus, 1));
  DEFINE_STATIC_LOCAL(AtomicString, hyphenString, (&hyphen, 1));
  return font().primaryFontHasGlyphForCharacter(hyphen) ? hyphenString
                                                        : hyphenMinusString;
}

const AtomicString& RenderStyle::textEmphasisMarkString() const {
  switch (textEmphasisMark()) {
    case TextEmphasisMarkNone:
      return nullAtom;
    case TextEmphasisMarkCustom:
      return textEmphasisCustomMark();
    case TextEmphasisMarkDot: {
      DEFINE_STATIC_LOCAL(AtomicString, filledDotString, (&bullet, 1));
      DEFINE_STATIC_LOCAL(AtomicString, openDotString, (&whiteBullet, 1));
      return textEmphasisFill() == TextEmphasisFillFilled ? filledDotString
                                                          : openDotString;
    }
    case TextEmphasisMarkCircle: {
      DEFINE_STATIC_LOCAL(AtomicString, filledCircleString, (&blackCircle, 1));
      DEFINE_STATIC_LOCAL(AtomicString, openCircleString, (&whiteCircle, 1));
      return textEmphasisFill() == TextEmphasisFillFilled ? filledCircleString
                                                          : openCircleString;
    }
    case TextEmphasisMarkDoubleCircle: {
      DEFINE_STATIC_LOCAL(AtomicString, filledDoubleCircleString,
                          (&fisheye, 1));
      DEFINE_STATIC_LOCAL(AtomicString, openDoubleCircleString, (&bullseye, 1));
      return textEmphasisFill() == TextEmphasisFillFilled
                 ? filledDoubleCircleString
                 : openDoubleCircleString;
    }
    case TextEmphasisMarkTriangle: {
      DEFINE_STATIC_LOCAL(AtomicString, filledTriangleString,
                          (&blackUpPointingTriangle, 1));
      DEFINE_STATIC_LOCAL(AtomicString, openTriangleString,
                          (&whiteUpPointingTriangle, 1));
      return textEmphasisFill() == TextEmphasisFillFilled ? filledTriangleString
                                                          : openTriangleString;
    }
    case TextEmphasisMarkSesame: {
      DEFINE_STATIC_LOCAL(AtomicString, filledSesameString, (&sesameDot, 1));
      DEFINE_STATIC_LOCAL(AtomicString, openSesameString, (&whiteSesameDot, 1));
      return textEmphasisFill() == TextEmphasisFillFilled ? filledSesameString
                                                          : openSesameString;
    }
    case TextEmphasisMarkAuto:
      ASSERT_NOT_REACHED();
      return nullAtom;
  }

  ASSERT_NOT_REACHED();
  return nullAtom;
}

const Font& RenderStyle::font() const {
  return inherited->font;
}
const FontMetrics& RenderStyle::fontMetrics() const {
  return inherited->font.fontMetrics();
}
const FontDescription& RenderStyle::fontDescription() const {
  return inherited->font.fontDescription();
}
float RenderStyle::specifiedFontSize() const {
  return fontDescription().specifiedSize();
}
float RenderStyle::computedFontSize() const {
  return fontDescription().computedSize();
}
int RenderStyle::fontSize() const {
  return fontDescription().computedPixelSize();
}
FontWeight RenderStyle::fontWeight() const {
  return fontDescription().weight();
}
FontStretch RenderStyle::fontStretch() const {
  return fontDescription().stretch();
}

TextDecoration RenderStyle::textDecorationsInEffect() const {
  int decorations = 0;

  const Vector<AppliedTextDecoration>& applied = appliedTextDecorations();

  for (size_t i = 0; i < applied.size(); ++i)
    decorations |= applied[i].line();

  return static_cast<TextDecoration>(decorations);
}

const Vector<AppliedTextDecoration>& RenderStyle::appliedTextDecorations()
    const {
  if (!inherited_flags.m_textUnderline &&
      !rareInheritedData->appliedTextDecorations) {
    DEFINE_STATIC_LOCAL(Vector<AppliedTextDecoration>, empty, ());
    return empty;
  }
  if (inherited_flags.m_textUnderline) {
    DEFINE_STATIC_LOCAL(Vector<AppliedTextDecoration>, underline,
                        (1, AppliedTextDecoration(TextDecorationUnderline)));
    return underline;
  }

  return rareInheritedData->appliedTextDecorations->vector();
}

float RenderStyle::wordSpacing() const {
  return fontDescription().wordSpacing();
}
float RenderStyle::letterSpacing() const {
  return fontDescription().letterSpacing();
}

bool RenderStyle::setFontDescription(const FontDescription& v) {
  if (inherited->font.fontDescription() != v) {
    inherited.access()->font = Font(v);
    return true;
  }
  return false;
}

const Length& RenderStyle::specifiedLineHeight() const {
  return inherited->line_height;
}
Length RenderStyle::lineHeight() const {
  return inherited->line_height;
}

void RenderStyle::setLineHeight(const Length& specifiedLineHeight) {
  SET_VAR(inherited, line_height, specifiedLineHeight);
}

int RenderStyle::computedLineHeight() const {
  const Length& lh = lineHeight();

  // Negative value means the line height is not set. Use the font's built-in
  // spacing.
  if (lh.isNegative())
    return fontMetrics().lineSpacing();

  if (lh.isPercent())
    return minimumValueForLength(lh, fontSize());

  return lh.value();
}

void RenderStyle::setWordSpacing(float wordSpacing) {
  FontSelector* currentFontSelector = font().fontSelector();
  FontDescription desc(fontDescription());
  desc.setWordSpacing(wordSpacing);
  setFontDescription(desc);
  font().update(currentFontSelector);
}

void RenderStyle::setLetterSpacing(float letterSpacing) {
  FontSelector* currentFontSelector = font().fontSelector();
  FontDescription desc(fontDescription());
  desc.setLetterSpacing(letterSpacing);
  setFontDescription(desc);
  font().update(currentFontSelector);
}

void RenderStyle::setFontSize(float size) {
  ASSERT(std::isfinite(size));
  if (!std::isfinite(size) || size < 0)
    size = 0;

  FontSelector* currentFontSelector = font().fontSelector();
  FontDescription desc(fontDescription());
  desc.setSpecifiedSize(size);
  desc.setComputedSize(size);

  setFontDescription(desc);
  font().update(currentFontSelector);
}

void RenderStyle::setFontWeight(FontWeight weight) {
  FontSelector* currentFontSelector = font().fontSelector();
  FontDescription desc(fontDescription());
  desc.setWeight(weight);
  setFontDescription(desc);
  font().update(currentFontSelector);
}

void RenderStyle::addAppliedTextDecoration(
    const AppliedTextDecoration& decoration) {
  RefPtr<AppliedTextDecorationList>& list =
      rareInheritedData.access()->appliedTextDecorations;

  if (!list)
    list = AppliedTextDecorationList::create();
  else if (!list->hasOneRef())
    list = list->copy();

  if (inherited_flags.m_textUnderline) {
    inherited_flags.m_textUnderline = false;
    list->append(AppliedTextDecoration(TextDecorationUnderline));
  }

  list->append(decoration);
}

void RenderStyle::applyTextDecorations() {
  if (textDecoration() == TextDecorationNone)
    return;

  TextDecorationStyle style = textDecorationStyle();
  StyleColor styleColor = decorationStyleColor();

  int decorations = textDecoration();

  if (decorations & TextDecorationUnderline) {
    // To save memory, we don't use AppliedTextDecoration objects in the
    // common case of a single simple underline.
    AppliedTextDecoration underline(TextDecorationUnderline, style, styleColor);

    if (!rareInheritedData->appliedTextDecorations &&
        underline.isSimpleUnderline())
      inherited_flags.m_textUnderline = true;
    else
      addAppliedTextDecoration(underline);
  }
  if (decorations & TextDecorationOverline)
    addAppliedTextDecoration(
        AppliedTextDecoration(TextDecorationOverline, style, styleColor));
  if (decorations & TextDecorationLineThrough)
    addAppliedTextDecoration(
        AppliedTextDecoration(TextDecorationLineThrough, style, styleColor));
}

void RenderStyle::clearAppliedTextDecorations() {
  inherited_flags.m_textUnderline = false;

  if (rareInheritedData->appliedTextDecorations)
    rareInheritedData.access()->appliedTextDecorations = nullptr;
}

void RenderStyle::setFontStretch(FontStretch stretch) {
  FontSelector* currentFontSelector = font().fontSelector();
  FontDescription desc(fontDescription());
  desc.setStretch(stretch);
  setFontDescription(desc);
  font().update(currentFontSelector);
}

void RenderStyle::getShadowExtent(const ShadowList* shadowList,
                                  LayoutUnit& top,
                                  LayoutUnit& right,
                                  LayoutUnit& bottom,
                                  LayoutUnit& left) const {
  top = 0;
  right = 0;
  bottom = 0;
  left = 0;

  size_t shadowCount = shadowList ? shadowList->shadows().size() : 0;
  for (size_t i = 0; i < shadowCount; ++i) {
    const ShadowData& shadow = shadowList->shadows()[i];
    if (shadow.style() == Inset)
      continue;
    float blurAndSpread = shadow.blur() + shadow.spread();

    top = std::min<LayoutUnit>(top, shadow.y() - blurAndSpread);
    right = std::max<LayoutUnit>(right, shadow.x() + blurAndSpread);
    bottom = std::max<LayoutUnit>(bottom, shadow.y() + blurAndSpread);
    left = std::min<LayoutUnit>(left, shadow.x() - blurAndSpread);
  }
}

LayoutBoxExtent RenderStyle::getShadowInsetExtent(
    const ShadowList* shadowList) const {
  LayoutUnit top = 0;
  LayoutUnit right = 0;
  LayoutUnit bottom = 0;
  LayoutUnit left = 0;

  size_t shadowCount = shadowList ? shadowList->shadows().size() : 0;
  for (size_t i = 0; i < shadowCount; ++i) {
    const ShadowData& shadow = shadowList->shadows()[i];
    if (shadow.style() == Normal)
      continue;
    float blurAndSpread = shadow.blur() + shadow.spread();
    top = std::max<LayoutUnit>(top, shadow.y() + blurAndSpread);
    right = std::min<LayoutUnit>(right, shadow.x() - blurAndSpread);
    bottom = std::min<LayoutUnit>(bottom, shadow.y() - blurAndSpread);
    left = std::max<LayoutUnit>(left, shadow.x() + blurAndSpread);
  }

  return LayoutBoxExtent(top, right, bottom, left);
}

void RenderStyle::getShadowHorizontalExtent(const ShadowList* shadowList,
                                            LayoutUnit& left,
                                            LayoutUnit& right) const {
  left = 0;
  right = 0;

  size_t shadowCount = shadowList ? shadowList->shadows().size() : 0;
  for (size_t i = 0; i < shadowCount; ++i) {
    const ShadowData& shadow = shadowList->shadows()[i];
    if (shadow.style() == Inset)
      continue;
    float blurAndSpread = shadow.blur() + shadow.spread();

    left = std::min<LayoutUnit>(left, shadow.x() - blurAndSpread);
    right = std::max<LayoutUnit>(right, shadow.x() + blurAndSpread);
  }
}

void RenderStyle::getShadowVerticalExtent(const ShadowList* shadowList,
                                          LayoutUnit& top,
                                          LayoutUnit& bottom) const {
  top = 0;
  bottom = 0;

  size_t shadowCount = shadowList ? shadowList->shadows().size() : 0;
  for (size_t i = 0; i < shadowCount; ++i) {
    const ShadowData& shadow = shadowList->shadows()[i];
    if (shadow.style() == Inset)
      continue;
    float blurAndSpread = shadow.blur() + shadow.spread();

    top = std::min<LayoutUnit>(top, shadow.y() - blurAndSpread);
    bottom = std::max<LayoutUnit>(bottom, shadow.y() + blurAndSpread);
  }
}

StyleColor RenderStyle::decorationStyleColor() const {
  StyleColor styleColor = textDecorationColor();

  if (!styleColor.isCurrentColor())
    return styleColor;

  if (textStrokeWidth()) {
    // Prefer stroke color if possible, but not if it's fully transparent.
    StyleColor textStrokeStyleColor = textStrokeColor();
    if (!textStrokeStyleColor.isCurrentColor() &&
        textStrokeStyleColor.color().alpha())
      return textStrokeStyleColor;
  }

  return textFillColor();
}

Color RenderStyle::decorationColor() const {
  return decorationStyleColor().resolve(color());
}

const BorderValue& RenderStyle::borderBefore() const {
  // FIXME(sky): Remove
  return borderTop();
}

const BorderValue& RenderStyle::borderAfter() const {
  // FIXME(sky): Remove
  return borderBottom();
}

const BorderValue& RenderStyle::borderStart() const {
  return isLeftToRightDirection() ? borderLeft() : borderRight();
}

const BorderValue& RenderStyle::borderEnd() const {
  return isLeftToRightDirection() ? borderRight() : borderLeft();
}

unsigned short RenderStyle::borderBeforeWidth() const {
  // FIXME(sky): Remove
  return borderTopWidth();
}

unsigned short RenderStyle::borderAfterWidth() const {
  // FIXME(sky): Remove
  return borderBottomWidth();
}

unsigned short RenderStyle::borderStartWidth() const {
  return isLeftToRightDirection() ? borderLeftWidth() : borderRightWidth();
}

unsigned short RenderStyle::borderEndWidth() const {
  return isLeftToRightDirection() ? borderRightWidth() : borderLeftWidth();
}

void RenderStyle::setMarginStart(const Length& margin) {
  if (isLeftToRightDirection())
    setMarginLeft(margin);
  else
    setMarginRight(margin);
}

void RenderStyle::setMarginEnd(const Length& margin) {
  if (isLeftToRightDirection())
    setMarginRight(margin);
  else
    setMarginLeft(margin);
}

TextEmphasisMark RenderStyle::textEmphasisMark() const {
  TextEmphasisMark mark =
      static_cast<TextEmphasisMark>(rareInheritedData->textEmphasisMark);
  if (mark != TextEmphasisMarkAuto)
    return mark;
  return TextEmphasisMarkDot;
}

Color RenderStyle::initialTapHighlightColor() {
  return RenderTheme::tapHighlightColor();
}

float calcBorderRadiiConstraintScaleFor(const FloatRect& rect,
                                        const FloatRoundedRect::Radii& radii) {
  // Constrain corner radii using CSS3 rules:
  // http://www.w3.org/TR/css3-background/#the-border-radius

  float factor = 1;
  float radiiSum;

  // top
  radiiSum = radii.topLeft().width() +
             radii.topRight().width();  // Casts to avoid integer overflow.
  if (radiiSum > rect.width())
    factor = std::min(rect.width() / radiiSum, factor);

  // bottom
  radiiSum = radii.bottomLeft().width() + radii.bottomRight().width();
  if (radiiSum > rect.width())
    factor = std::min(rect.width() / radiiSum, factor);

  // left
  radiiSum = radii.topLeft().height() + radii.bottomLeft().height();
  if (radiiSum > rect.height())
    factor = std::min(rect.height() / radiiSum, factor);

  // right
  radiiSum = radii.topRight().height() + radii.bottomRight().height();
  if (radiiSum > rect.height())
    factor = std::min(rect.height() / radiiSum, factor);

  ASSERT(factor <= 1);
  return factor;
}

}  // namespace blink
