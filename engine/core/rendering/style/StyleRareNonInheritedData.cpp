/*
 * Copyright (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
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

#include "sky/engine/config.h"
#include "sky/engine/core/rendering/style/StyleRareNonInheritedData.h"

#include "sky/engine/core/rendering/style/DataEquivalency.h"
#include "sky/engine/core/rendering/style/RenderStyle.h"
#include "sky/engine/core/rendering/style/ShadowList.h"
#include "sky/engine/core/rendering/style/StyleFilterData.h"
#include "sky/engine/core/rendering/style/StyleTransformData.h"

namespace blink {

StyleRareNonInheritedData::StyleRareNonInheritedData()
    : opacity(RenderStyle::initialOpacity())
    , m_aspectRatioDenominator(RenderStyle::initialAspectRatioDenominator())
    , m_aspectRatioNumerator(RenderStyle::initialAspectRatioNumerator())
    , m_perspective(RenderStyle::initialPerspective())
    , m_perspectiveOriginX(RenderStyle::initialPerspectiveOriginX())
    , m_perspectiveOriginY(RenderStyle::initialPerspectiveOriginY())
    , m_mask(MaskFillLayer, true)
    , m_pageSize()
    , m_clipPath(RenderStyle::initialClipPath())
    , m_textDecorationColor(StyleColor::currentColor())
    , m_order(RenderStyle::initialOrder())
    , m_objectPosition(RenderStyle::initialObjectPosition())
    , m_pageSizeType(PAGE_SIZE_AUTO)
    , m_transformStyle3D(RenderStyle::initialTransformStyle3D())
    , m_backfaceVisibility(RenderStyle::initialBackfaceVisibility())
    , m_alignContent(RenderStyle::initialAlignContent())
    , m_alignItems(RenderStyle::initialAlignItems())
    , m_alignItemsOverflowAlignment(RenderStyle::initialAlignItemsOverflowAlignment())
    , m_alignSelf(RenderStyle::initialAlignSelf())
    , m_alignSelfOverflowAlignment(RenderStyle::initialAlignSelfOverflowAlignment())
    , m_justifyContent(RenderStyle::initialJustifyContent())
    , userDrag(RenderStyle::initialUserDrag())
    , textOverflow(RenderStyle::initialTextOverflow())
    , m_textDecorationStyle(RenderStyle::initialTextDecorationStyle())
    , m_wrapFlow(RenderStyle::initialWrapFlow())
    , m_wrapThrough(RenderStyle::initialWrapThrough())
    , m_hasAspectRatio(false)
    , m_touchAction(RenderStyle::initialTouchAction())
    , m_objectFit(RenderStyle::initialObjectFit())
    , m_justifyItems(RenderStyle::initialJustifyItems())
    , m_justifyItemsOverflowAlignment(RenderStyle::initialJustifyItemsOverflowAlignment())
    , m_justifyItemsPositionType(RenderStyle::initialJustifyItemsPositionType())
    , m_justifySelf(RenderStyle::initialJustifySelf())
    , m_justifySelfOverflowAlignment(RenderStyle::initialJustifySelfOverflowAlignment())
    , m_scrollBehavior(RenderStyle::initialScrollBehavior())
{
    m_maskBoxImage.setMaskDefaults();
}

StyleRareNonInheritedData::StyleRareNonInheritedData(const StyleRareNonInheritedData& o)
    : RefCounted<StyleRareNonInheritedData>()
    , opacity(o.opacity)
    , m_aspectRatioDenominator(o.m_aspectRatioDenominator)
    , m_aspectRatioNumerator(o.m_aspectRatioNumerator)
    , m_perspective(o.m_perspective)
    , m_perspectiveOriginX(o.m_perspectiveOriginX)
    , m_perspectiveOriginY(o.m_perspectiveOriginY)
    , m_flexibleBox(o.m_flexibleBox)
    , m_transform(o.m_transform)
    , m_willChange(o.m_willChange)
    , m_filter(o.m_filter)
    , m_counterDirectives(o.m_counterDirectives ? clone(*o.m_counterDirectives) : nullptr)
    , m_boxShadow(o.m_boxShadow)
    , m_animations(o.m_animations ? CSSAnimationData::create(*o.m_animations) : nullptr)
    , m_transitions(o.m_transitions ? CSSTransitionData::create(*o.m_transitions) : nullptr)
    , m_mask(o.m_mask)
    , m_maskBoxImage(o.m_maskBoxImage)
    , m_pageSize(o.m_pageSize)
    , m_clipPath(o.m_clipPath)
    , m_textDecorationColor(o.m_textDecorationColor)
    , m_order(o.m_order)
    , m_objectPosition(o.m_objectPosition)
    , m_pageSizeType(o.m_pageSizeType)
    , m_transformStyle3D(o.m_transformStyle3D)
    , m_backfaceVisibility(o.m_backfaceVisibility)
    , m_alignContent(o.m_alignContent)
    , m_alignItems(o.m_alignItems)
    , m_alignItemsOverflowAlignment(o.m_alignItemsOverflowAlignment)
    , m_alignSelf(o.m_alignSelf)
    , m_alignSelfOverflowAlignment(o.m_alignSelfOverflowAlignment)
    , m_justifyContent(o.m_justifyContent)
    , userDrag(o.userDrag)
    , textOverflow(o.textOverflow)
    , m_textDecorationStyle(o.m_textDecorationStyle)
    , m_wrapFlow(o.m_wrapFlow)
    , m_wrapThrough(o.m_wrapThrough)
    , m_hasAspectRatio(o.m_hasAspectRatio)
    , m_touchAction(o.m_touchAction)
    , m_objectFit(o.m_objectFit)
    , m_justifyItems(o.m_justifyItems)
    , m_justifyItemsOverflowAlignment(o.m_justifyItemsOverflowAlignment)
    , m_justifyItemsPositionType(o.m_justifyItemsPositionType)
    , m_justifySelf(o.m_justifySelf)
    , m_justifySelfOverflowAlignment(o.m_justifySelfOverflowAlignment)
    , m_scrollBehavior(o.m_scrollBehavior)
{
}

StyleRareNonInheritedData::~StyleRareNonInheritedData()
{
}

bool StyleRareNonInheritedData::operator==(const StyleRareNonInheritedData& o) const
{
    return opacity == o.opacity
        && m_aspectRatioDenominator == o.m_aspectRatioDenominator
        && m_aspectRatioNumerator == o.m_aspectRatioNumerator
        && m_perspective == o.m_perspective
        && m_perspectiveOriginX == o.m_perspectiveOriginX
        && m_perspectiveOriginY == o.m_perspectiveOriginY
        && m_flexibleBox == o.m_flexibleBox
        && m_transform == o.m_transform
        && m_willChange == o.m_willChange
        && m_filter == o.m_filter
        && counterDataEquivalent(o)
        && shadowDataEquivalent(o)
        && animationDataEquivalent(o)
        && transitionDataEquivalent(o)
        && m_mask == o.m_mask
        && m_maskBoxImage == o.m_maskBoxImage
        && m_pageSize == o.m_pageSize
        && m_clipPath == o.m_clipPath
        && m_textDecorationColor == o.m_textDecorationColor
        && m_order == o.m_order
        && m_objectPosition == o.m_objectPosition
        && m_pageSizeType == o.m_pageSizeType
        && m_transformStyle3D == o.m_transformStyle3D
        && m_backfaceVisibility == o.m_backfaceVisibility
        && m_alignContent == o.m_alignContent
        && m_alignItems == o.m_alignItems
        && m_alignItemsOverflowAlignment == o.m_alignItemsOverflowAlignment
        && m_alignSelf == o.m_alignSelf
        && m_alignSelfOverflowAlignment == o.m_alignSelfOverflowAlignment
        && m_justifyContent == o.m_justifyContent
        && userDrag == o.userDrag
        && textOverflow == o.textOverflow
        && m_textDecorationStyle == o.m_textDecorationStyle
        && m_wrapFlow == o.m_wrapFlow
        && m_wrapThrough == o.m_wrapThrough
        && m_hasAspectRatio == o.m_hasAspectRatio
        && m_touchAction == o.m_touchAction
        && m_objectFit == o.m_objectFit
        && m_justifyItems == o.m_justifyItems
        && m_justifyItemsOverflowAlignment == o.m_justifyItemsOverflowAlignment
        && m_justifyItemsPositionType == o.m_justifyItemsPositionType
        && m_justifySelf == o.m_justifySelf
        && m_justifySelfOverflowAlignment == o.m_justifySelfOverflowAlignment
        && m_scrollBehavior == o.m_scrollBehavior;
}

bool StyleRareNonInheritedData::counterDataEquivalent(const StyleRareNonInheritedData& o) const
{
    return dataEquivalent(m_counterDirectives, o.m_counterDirectives);
}

bool StyleRareNonInheritedData::shadowDataEquivalent(const StyleRareNonInheritedData& o) const
{
    return dataEquivalent(m_boxShadow, o.m_boxShadow);
}

bool StyleRareNonInheritedData::animationDataEquivalent(const StyleRareNonInheritedData& o) const
{
    if (!m_animations && !o.m_animations)
        return true;
    if (!m_animations || !o.m_animations)
        return false;
    return m_animations->animationsMatchForStyleRecalc(*o.m_animations);
}

bool StyleRareNonInheritedData::transitionDataEquivalent(const StyleRareNonInheritedData& o) const
{
    if (!m_transitions && !o.m_transitions)
        return true;
    if (!m_transitions || !o.m_transitions)
        return false;
    return m_transitions->transitionsMatchForStyleRecalc(*o.m_transitions);
}

bool StyleRareNonInheritedData::hasFilters() const
{
    return m_filter.get() && !m_filter->m_operations.isEmpty();
}

} // namespace blink
