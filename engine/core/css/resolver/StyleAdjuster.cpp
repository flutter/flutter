/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 2004-2005 Allan Sandfeld Jensen (kde@carewolf.com)
 * Copyright (C) 2006, 2007 Nicholas Shanks (webkit@nickshanks.com)
 * Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013 Apple Inc. All rights reserved.
 * Copyright (C) 2007 Alexey Proskuryakov <ap@webkit.org>
 * Copyright (C) 2007, 2008 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (c) 2011, Code Aurora Forum. All rights reserved.
 * Copyright (C) Research In Motion Limited 2011. All rights reserved.
 * Copyright (C) 2013 Google Inc. All rights reserved.
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
 */

#include "config.h"
#include "core/css/resolver/StyleAdjuster.h"

#include "core/dom/ContainerNode.h"
#include "core/dom/Document.h"
#include "core/dom/Element.h"
#include "core/dom/NodeRenderStyle.h"
#include "core/rendering/style/RenderStyle.h"
#include "core/rendering/style/RenderStyleConstants.h"
#include "platform/Length.h"
#include "platform/transforms/TransformOperations.h"
#include "wtf/Assertions.h"

namespace blink {

static EDisplay equivalentBlockDisplay(EDisplay display)
{
    switch (display) {
    case BLOCK:
    case FLEX:
        return display;
    case INLINE_FLEX:
        return FLEX;

    case INLINE:
    case INLINE_BLOCK:
        return BLOCK;
    case NONE:
        ASSERT_NOT_REACHED();
        return NONE;
    }
    ASSERT_NOT_REACHED();
    return BLOCK;
}

// CSS requires text-decoration to be reset at each DOM element for tables,
// inline blocks, inline tables, shadow DOM crossings, floating elements,
// and absolute or relatively positioned elements.
static bool doesNotInheritTextDecoration(const RenderStyle* style, const Element& e)
{
    return style->display() == INLINE_BLOCK || isAtShadowBoundary(&e) || style->hasOutOfFlowPosition();
}

static bool parentStyleForcesZIndexToCreateStackingContext(const RenderStyle* parentStyle)
{
    return parentStyle->isDisplayFlexibleBox();
}

static bool hasWillChangeThatCreatesStackingContext(const RenderStyle* style)
{
    for (size_t i = 0; i < style->willChangeProperties().size(); ++i) {
        switch (style->willChangeProperties()[i]) {
        case CSSPropertyOpacity:
        case CSSPropertyTransform:
        case CSSPropertyWebkitTransform:
        case CSSPropertyTransformStyle:
        case CSSPropertyWebkitTransformStyle:
        case CSSPropertyPerspective:
        case CSSPropertyWebkitPerspective:
        case CSSPropertyWebkitMask:
        case CSSPropertyWebkitMaskBoxImage:
        case CSSPropertyWebkitClipPath:
        case CSSPropertyWebkitFilter:
        case CSSPropertyZIndex:
        case CSSPropertyPosition:
            return true;
        default:
            break;
        }
    }
    return false;
}

void StyleAdjuster::adjustRenderStyle(RenderStyle* style, RenderStyle* parentStyle, Element& element)
{
    ASSERT(parentStyle);

    if (style->display() != NONE) {
        // Absolute/fixed positioned elements, floating elements and the document element need block-like outside display.
        if (style->hasOutOfFlowPosition() || element.document().documentElement() == element)
            style->setDisplay(equivalentBlockDisplay(style->display()));

        adjustStyleForDisplay(style, parentStyle);
    }

    // Make sure our z-index value is only applied if the object is positioned.
    if (style->position() == StaticPosition && !parentStyleForcesZIndexToCreateStackingContext(parentStyle))
        style->setHasAutoZIndex();

    // Auto z-index becomes 0 for the root element and transparent objects. This prevents
    // cases where objects that should be blended as a single unit end up with a non-transparent
    // object wedged in between them. Auto z-index also becomes 0 for objects that specify transforms/masks/reflections.
    if (style->hasAutoZIndex() && ((element.document().documentElement() == element)
        || style->hasOpacity()
        || style->hasTransformRelatedProperty()
        || style->hasMask()
        || style->clipPath()
        || style->hasFilter()
        || hasWillChangeThatCreatesStackingContext(style)))
        style->setZIndex(0);

    // will-change:transform should result in the same rendering behavior as having a transform,
    // including the creation of a containing block for fixed position descendants.
    if (!style->hasTransform() && (style->willChangeProperties().contains(CSSPropertyWebkitTransform) || style->willChangeProperties().contains(CSSPropertyTransform))) {
        bool makeIdentity = true;
        style->setTransform(TransformOperations(makeIdentity));
    }

    if (doesNotInheritTextDecoration(style, element))
        style->clearAppliedTextDecorations();

    style->applyTextDecorations();

    if (style->overflowX() != OVISIBLE || style->overflowY() != OVISIBLE)
        adjustOverflow(style);

    // Cull out any useless layers and also repeat patterns into additional layers.
    style->adjustBackgroundLayers();
    style->adjustMaskLayers();

    // If we have transitions, or animations, do not share this style.
    if (style->transitions() || style->animations())
        style->setUnique();

    // FIXME: when dropping the -webkit prefix on transform-style, we should also have opacity < 1 cause flattening.
    if (style->preserves3D() && (style->overflowX() != OVISIBLE
        || style->overflowY() != OVISIBLE
        || style->hasFilter()))
        style->setTransformStyle3D(TransformStyle3DFlat);

    adjustStyleForAlignment(*style, *parentStyle);
}

void StyleAdjuster::adjustStyleForAlignment(RenderStyle& style, const RenderStyle& parentStyle)
{
    bool isFlex = style.isDisplayFlexibleBox();
    bool absolutePositioned = style.position() == AbsolutePosition;

    // If the inherited value of justify-items includes the legacy keyword, 'auto'
    // computes to the the inherited value.
    // Otherwise, auto computes to:
    //  - 'stretch' for flex containers.
    //  - 'start' for everything else.
    if (style.justifyItems() == ItemPositionAuto) {
        if (parentStyle.justifyItemsPositionType() == LegacyPosition) {
            style.setJustifyItems(parentStyle.justifyItems());
            style.setJustifyItemsPositionType(parentStyle.justifyItemsPositionType());
        } else if (isFlex) {
            style.setJustifyItems(ItemPositionStretch);
        }
    }

    // The 'auto' keyword computes to 'stretch' on absolutely-positioned elements,
    // and to the computed value of justify-items on the parent (minus
    // any legacy keywords) on all other boxes.
    if (style.justifySelf() == ItemPositionAuto) {
        if (absolutePositioned) {
            style.setJustifySelf(ItemPositionStretch);
        } else {
            style.setJustifySelf(parentStyle.justifyItems());
            style.setJustifySelfOverflowAlignment(parentStyle.justifyItemsOverflowAlignment());
        }
    }

    // The 'auto' keyword computes to:
    //  - 'stretch' for flex containers,
    //  - 'start' for everything else.
    if (style.alignItems() == ItemPositionAuto) {
        if (isFlex)
            style.setAlignItems(ItemPositionStretch);
    }

    // The 'auto' keyword computes to 'stretch' on absolutely-positioned elements,
    // and to the computed value of align-items on the parent (minus
    // any 'legacy' keywords) on all other boxes.
    if (style.alignSelf() == ItemPositionAuto) {
        if (absolutePositioned) {
            style.setAlignSelf(ItemPositionStretch);
        } else {
            style.setAlignSelf(parentStyle.alignItems());
            style.setAlignSelfOverflowAlignment(parentStyle.alignItemsOverflowAlignment());
        }
    }
}

void StyleAdjuster::adjustOverflow(RenderStyle* style)
{
    ASSERT(style->overflowX() != OVISIBLE || style->overflowY() != OVISIBLE);

    // If either overflow value is not visible, change to auto.
    if (style->overflowX() == OVISIBLE && style->overflowY() != OVISIBLE) {
        // FIXME: Once we implement pagination controls, overflow-x should default to hidden
        // if overflow-y is set to -webkit-paged-x or -webkit-page-y. For now, we'll let it
        // default to auto so we can at least scroll through the pages.
        style->setOverflowX(OAUTO);
    } else if (style->overflowY() == OVISIBLE && style->overflowX() != OVISIBLE) {
        style->setOverflowY(OAUTO);
    }
}

void StyleAdjuster::adjustStyleForDisplay(RenderStyle* style, RenderStyle* parentStyle)
{
    if (parentStyle->isDisplayFlexibleBox()) {
        style->setDisplay(equivalentBlockDisplay(style->display()));
    }
}

}
