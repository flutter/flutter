/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004, 2006, 2007 Apple Inc. All rights reserved.
 * Copyright (C) Research In Motion Limited 2011-2012. All rights reserved.
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
#include "sky/engine/core/rendering/RenderReplaced.h"

#include "gen/sky/platform/RuntimeEnabledFeatures.h"
#include "sky/engine/core/editing/PositionWithAffinity.h"
#include "sky/engine/core/rendering/GraphicsContextAnnotator.h"
#include "sky/engine/core/rendering/RenderBlock.h"
#include "sky/engine/core/rendering/RenderImage.h"
#include "sky/engine/core/rendering/RenderLayer.h"
#include "sky/engine/core/rendering/RenderView.h"
#include "sky/engine/platform/LengthFunctions.h"
#include "sky/engine/platform/graphics/GraphicsContext.h"

namespace blink {

const int RenderReplaced::defaultWidth = 300;
const int RenderReplaced::defaultHeight = 150;

RenderReplaced::RenderReplaced(Element* element)
    : RenderBox(element)
    , m_intrinsicSize(defaultWidth, defaultHeight)
{
    setReplaced(true);
}

RenderReplaced::RenderReplaced(Element* element, const LayoutSize& intrinsicSize)
    : RenderBox(element)
    , m_intrinsicSize(intrinsicSize)
{
    setReplaced(true);
}

RenderReplaced::~RenderReplaced()
{
}

void RenderReplaced::willBeDestroyed()
{
    if (!documentBeingDestroyed() && parent())
        parent()->dirtyLinesFromChangedChild(this);

    RenderBox::willBeDestroyed();
}

void RenderReplaced::layout()
{
    ASSERT(needsLayout());

    setHeight(minimumReplacedHeight());

    updateLogicalWidth();
    updateLogicalHeight();

    m_overflow.clear();
    addVisualEffectOverflow();
    updateLayerTransformAfterLayout();
    invalidateBackgroundObscurationStatus();

    clearNeedsLayout();
}

void RenderReplaced::intrinsicSizeChanged()
{
    m_intrinsicSize = IntSize(defaultWidth, defaultHeight);
    setNeedsLayoutAndPrefWidthsRecalcAndFullPaintInvalidation();
}

void RenderReplaced::paint(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    ANNOTATE_GRAPHICS_CONTEXT(paintInfo, this);

    if (!shouldPaint(paintInfo, paintOffset))
        return;

    LayoutPoint adjustedPaintOffset = paintOffset + location();

    if (hasBoxDecorationBackground() && (paintInfo.phase == PaintPhaseForeground || paintInfo.phase == PaintPhaseSelection))
        paintBoxDecorationBackground(paintInfo, adjustedPaintOffset);

    if (paintInfo.phase == PaintPhaseMask) {
        paintMask(paintInfo, adjustedPaintOffset);
        return;
    }

    LayoutRect paintRect = LayoutRect(adjustedPaintOffset, size());
    if ((paintInfo.phase == PaintPhaseOutline || paintInfo.phase == PaintPhaseSelfOutline) && style()->outlineWidth())
        paintOutline(paintInfo, paintRect);

    if (paintInfo.phase != PaintPhaseForeground && paintInfo.phase != PaintPhaseSelection && !canHaveChildren())
        return;

    if (!paintInfo.shouldPaintWithinRoot(this))
        return;

    bool drawSelectionTint = selectionState() != SelectionNone;
    if (paintInfo.phase == PaintPhaseSelection) {
        if (selectionState() == SelectionNone)
            return;
        drawSelectionTint = false;
    }

    bool completelyClippedOut = false;
    if (style()->hasBorderRadius()) {
        LayoutRect borderRect = LayoutRect(adjustedPaintOffset, size());

        if (borderRect.isEmpty())
            completelyClippedOut = true;
        else {
            // Push a clip if we have a border radius, since we want to round the foreground content that gets painted.
            paintInfo.context->save();
            RoundedRect roundedInnerRect = style()->getRoundedInnerBorderFor(paintRect,
                paddingTop() + borderTop(), paddingBottom() + borderBottom(), paddingLeft() + borderLeft(), paddingRight() + borderRight(), true, true);
            clipRoundedInnerRect(paintInfo.context, paintRect, roundedInnerRect);
        }
    }

    if (!completelyClippedOut) {
        paintReplaced(paintInfo, adjustedPaintOffset);
        if (style()->hasBorderRadius())
            paintInfo.context->restore();
    }

    // The selection tint never gets clipped by border-radius rounding, since we want it to run right up to the edges of
    // surrounding content.
    if (drawSelectionTint) {
        LayoutRect selectionPaintingRect = localSelectionRect();
        selectionPaintingRect.moveBy(adjustedPaintOffset);
        paintInfo.context->fillRect(pixelSnappedIntRect(selectionPaintingRect), selectionBackgroundColor());
    }
}

bool RenderReplaced::shouldPaint(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    if (paintInfo.phase != PaintPhaseForeground && paintInfo.phase != PaintPhaseOutline && paintInfo.phase != PaintPhaseSelfOutline
        && paintInfo.phase != PaintPhaseSelection && paintInfo.phase != PaintPhaseMask)
        return false;

    if (!paintInfo.shouldPaintWithinRoot(this))
        return false;

    LayoutPoint adjustedPaintOffset = paintOffset + location();

    // Early exit if the element touches the edges.
    LayoutUnit top = adjustedPaintOffset.y() + visualOverflowRect().y();
    LayoutUnit bottom = adjustedPaintOffset.y() + visualOverflowRect().maxY();
    if (isSelected() && inlineBoxWrapper()) {
        LayoutUnit selTop = paintOffset.y() + inlineBoxWrapper()->root().selectionTop();
        LayoutUnit selBottom = paintOffset.y() + selTop + inlineBoxWrapper()->root().selectionHeight();
        top = std::min(selTop, top);
        bottom = std::max(selBottom, bottom);
    }

    if (adjustedPaintOffset.x() + visualOverflowRect().x() >= paintInfo.rect.maxX() || adjustedPaintOffset.x() + visualOverflowRect().maxX() <= paintInfo.rect.x())
        return false;

    if (top >= paintInfo.rect.maxY() || bottom <= paintInfo.rect.y())
        return false;

    return true;
}

bool RenderReplaced::hasReplacedLogicalHeight() const
{
    if (style()->logicalHeight().isAuto())
        return false;

    if (style()->logicalHeight().isSpecified()) {
        if (hasAutoHeightOrContainingBlockWithAutoHeight())
            return false;
        return true;
    }

    if (style()->logicalHeight().isIntrinsic())
        return true;

    return false;
}

bool RenderReplaced::needsPreferredWidthsRecalculation() const
{
    // If the height is a percentage and the width is auto, then the containingBlocks's height changing can cause
    // this node to change it's preferred width because it maintains aspect ratio.
    return hasRelativeLogicalHeight() && style()->logicalWidth().isAuto() && !hasAutoHeightOrContainingBlockWithAutoHeight();
}

static inline bool rendererHasAspectRatio(const RenderObject* renderer)
{
    ASSERT(renderer);
    return renderer->isImage() || renderer->isCanvas();
}

void RenderReplaced::computeAspectRatioInformationForRenderBox(FloatSize& constrainedSize, double& intrinsicRatio) const
{
    FloatSize intrinsicSize;
    computeIntrinsicRatioInformation(intrinsicSize, intrinsicRatio);
    if (intrinsicRatio && !intrinsicSize.isEmpty())
        m_intrinsicSize = LayoutSize(intrinsicSize);

    // Now constrain the intrinsic size along each axis according to minimum and maximum width/heights along the
    // opposite axis. So for example a maximum width that shrinks our width will result in the height we compute here
    // having to shrink in order to preserve the aspect ratio. Because we compute these values independently along
    // each axis, the final returned size may in fact not preserve the aspect ratio.
    // FIXME: In the long term, it might be better to just return this code more to the way it used to be before this
    // function was added, since all it has done is make the code more unclear.
    constrainedSize = intrinsicSize;
    if (intrinsicRatio && !intrinsicSize.isEmpty() && style()->logicalWidth().isAuto() && style()->logicalHeight().isAuto()) {
        // We can't multiply or divide by 'intrinsicRatio' here, it breaks tests, like fast/images/zoomed-img-size.html, which
        // can only be fixed once subpixel precision is available for things like intrinsicWidth/Height.
        constrainedSize.setWidth(RenderBox::computeReplacedLogicalHeight() * intrinsicSize.width() / intrinsicSize.height());
        constrainedSize.setHeight(RenderBox::computeReplacedLogicalWidth() * intrinsicSize.height() / intrinsicSize.width());
    }
}

LayoutRect RenderReplaced::replacedContentRect(const LayoutSize* overriddenIntrinsicSize) const
{
    LayoutRect contentRect = contentBoxRect();
    ObjectFit objectFit = style()->objectFit();

    if (objectFit == ObjectFitFill && style()->objectPosition() == RenderStyle::initialObjectPosition()) {
        if (RuntimeEnabledFeatures::objectFitPositionEnabled())
            return contentRect;
        objectFit = ObjectFitContain;
    }

    LayoutSize intrinsicSize = overriddenIntrinsicSize ? *overriddenIntrinsicSize : this->intrinsicSize();
    if (!intrinsicSize.width() || !intrinsicSize.height())
        return contentRect;

    LayoutRect finalRect = contentRect;
    switch (objectFit) {
    case ObjectFitContain:
    case ObjectFitScaleDown:
    case ObjectFitCover:
        finalRect.setSize(finalRect.size().fitToAspectRatio(intrinsicSize, objectFit == ObjectFitCover ? AspectRatioFitGrow : AspectRatioFitShrink));
        if (objectFit != ObjectFitScaleDown || finalRect.width() <= intrinsicSize.width())
            break;
        // fall through
    case ObjectFitNone:
        finalRect.setSize(intrinsicSize);
        break;
    case ObjectFitFill:
        break;
    default:
        ASSERT_NOT_REACHED();
    }

    LayoutUnit xOffset = minimumValueForLength(style()->objectPosition().x(), contentRect.width() - finalRect.width());
    LayoutUnit yOffset = minimumValueForLength(style()->objectPosition().y(), contentRect.height() - finalRect.height());
    finalRect.move(xOffset, yOffset);

    return finalRect;
}

void RenderReplaced::computeIntrinsicRatioInformation(FloatSize& intrinsicSize, double& intrinsicRatio) const
{
    intrinsicSize = FloatSize(intrinsicLogicalWidth().toFloat(), intrinsicLogicalHeight().toFloat());

    // Figure out if we need to compute an intrinsic ratio.
    if (intrinsicSize.isEmpty() || !rendererHasAspectRatio(this))
        return;

    intrinsicRatio = intrinsicSize.width() / intrinsicSize.height();
}

LayoutUnit RenderReplaced::computeReplacedLogicalWidth(ShouldComputePreferred shouldComputePreferred) const
{
    if (style()->logicalWidth().isSpecified() || style()->logicalWidth().isIntrinsic())
        return computeReplacedLogicalWidthRespectingMinMaxWidth(computeReplacedLogicalWidthUsing(style()->logicalWidth()), shouldComputePreferred);

    // 10.3.2 Inline, replaced elements: http://www.w3.org/TR/CSS21/visudet.html#inline-replaced-width
    double intrinsicRatio = 0;
    FloatSize constrainedSize;
    computeAspectRatioInformationForRenderBox(constrainedSize, intrinsicRatio);

    if (style()->logicalWidth().isAuto()) {
        bool computedHeightIsAuto = hasAutoHeightOrContainingBlockWithAutoHeight();
        bool hasIntrinsicWidth = constrainedSize.width() > 0;

        // If 'height' and 'width' both have computed values of 'auto' and the element also has an intrinsic width, then that intrinsic width is the used value of 'width'.
        if (computedHeightIsAuto && hasIntrinsicWidth)
            return computeReplacedLogicalWidthRespectingMinMaxWidth(constrainedSize.width(), shouldComputePreferred);

        bool hasIntrinsicHeight = constrainedSize.height() > 0;
        if (intrinsicRatio) {
            // If 'height' and 'width' both have computed values of 'auto' and the element has no intrinsic width, but does have an intrinsic height and intrinsic ratio;
            // or if 'width' has a computed value of 'auto', 'height' has some other computed value, and the element does have an intrinsic ratio; then the used value
            // of 'width' is: (used height) * (intrinsic ratio)
            if (intrinsicRatio && ((computedHeightIsAuto && !hasIntrinsicWidth && hasIntrinsicHeight) || !computedHeightIsAuto)) {
                LayoutUnit logicalHeight = computeReplacedLogicalHeight();
                return computeReplacedLogicalWidthRespectingMinMaxWidth(roundToInt(round(logicalHeight * intrinsicRatio)), shouldComputePreferred);
            }

            // If 'height' and 'width' both have computed values of 'auto' and the element has an intrinsic ratio but no intrinsic height or width, then the used value of
            // 'width' is undefined in CSS 2.1. However, it is suggested that, if the containing block's width does not itself depend on the replaced element's width, then
            // the used value of 'width' is calculated from the constraint equation used for block-level, non-replaced elements in normal flow.
            if (computedHeightIsAuto && !hasIntrinsicWidth && !hasIntrinsicHeight) {
                if (shouldComputePreferred == ComputePreferred)
                    return 0;
                // The aforementioned 'constraint equation' used for block-level, non-replaced elements in normal flow:
                // 'margin-left' + 'border-left-width' + 'padding-left' + 'width' + 'padding-right' + 'border-right-width' + 'margin-right' = width of containing block
                LayoutUnit logicalWidth = containingBlock()->availableLogicalWidth();

                // This solves above equation for 'width' (== logicalWidth).
                LayoutUnit marginStart = minimumValueForLength(style()->marginStart(), logicalWidth);
                LayoutUnit marginEnd = minimumValueForLength(style()->marginEnd(), logicalWidth);
                logicalWidth = std::max<LayoutUnit>(0, logicalWidth - (marginStart + marginEnd + (width() - clientWidth())));
                return computeReplacedLogicalWidthRespectingMinMaxWidth(logicalWidth, shouldComputePreferred);
            }
        }

        // Otherwise, if 'width' has a computed value of 'auto', and the element has an intrinsic width, then that intrinsic width is the used value of 'width'.
        if (hasIntrinsicWidth)
            return computeReplacedLogicalWidthRespectingMinMaxWidth(constrainedSize.width(), shouldComputePreferred);

        // Otherwise, if 'width' has a computed value of 'auto', but none of the conditions above are met, then the used value of 'width' becomes 300px. If 300px is too
        // wide to fit the device, UAs should use the width of the largest rectangle that has a 2:1 ratio and fits the device instead.
        // Note: We fall through and instead return intrinsicLogicalWidth() here - to preserve existing WebKit behavior, which might or might not be correct, or desired.
        // Changing this to return cDefaultWidth, will affect lots of test results. Eg. some tests assume that a blank <img> tag (which implies width/height=auto)
        // has no intrinsic size, which is wrong per CSS 2.1, but matches our behavior since a long time.
    }

    return computeReplacedLogicalWidthRespectingMinMaxWidth(intrinsicLogicalWidth(), shouldComputePreferred);
}

LayoutUnit RenderReplaced::computeReplacedLogicalHeight() const
{
    // 10.5 Content height: the 'height' property: http://www.w3.org/TR/CSS21/visudet.html#propdef-height
    if (hasReplacedLogicalHeight())
        return computeReplacedLogicalHeightRespectingMinMaxHeight(computeReplacedLogicalHeightUsing(style()->logicalHeight()));

    // 10.6.2 Inline, replaced elements: http://www.w3.org/TR/CSS21/visudet.html#inline-replaced-height
    double intrinsicRatio = 0;
    FloatSize constrainedSize;
    computeAspectRatioInformationForRenderBox(constrainedSize, intrinsicRatio);

    bool widthIsAuto = style()->logicalWidth().isAuto();
    bool hasIntrinsicHeight = constrainedSize.height() > 0;

    // If 'height' and 'width' both have computed values of 'auto' and the element also has an intrinsic height, then that intrinsic height is the used value of 'height'.
    if (widthIsAuto && hasIntrinsicHeight)
        return computeReplacedLogicalHeightRespectingMinMaxHeight(constrainedSize.height());

    // Otherwise, if 'height' has a computed value of 'auto', and the element has an intrinsic ratio then the used value of 'height' is:
    // (used width) / (intrinsic ratio)
    if (intrinsicRatio)
        return computeReplacedLogicalHeightRespectingMinMaxHeight(roundToInt(round(availableLogicalWidth() / intrinsicRatio)));

    // Otherwise, if 'height' has a computed value of 'auto', and the element has an intrinsic height, then that intrinsic height is the used value of 'height'.
    if (hasIntrinsicHeight)
        return computeReplacedLogicalHeightRespectingMinMaxHeight(constrainedSize.height());

    // Otherwise, if 'height' has a computed value of 'auto', but none of the conditions above are met, then the used value of 'height' must be set to the height
    // of the largest rectangle that has a 2:1 ratio, has a height not greater than 150px, and has a width not greater than the device width.
    return computeReplacedLogicalHeightRespectingMinMaxHeight(intrinsicLogicalHeight());
}

void RenderReplaced::computeIntrinsicLogicalWidths(LayoutUnit& minLogicalWidth, LayoutUnit& maxLogicalWidth) const
{
    minLogicalWidth = maxLogicalWidth = intrinsicLogicalWidth();
}

void RenderReplaced::computePreferredLogicalWidths()
{
    ASSERT(preferredLogicalWidthsDirty());

    // We cannot resolve any percent logical width here as the available logical
    // width may not be set on our containing block.
    if (style()->logicalWidth().isPercent())
        computeIntrinsicLogicalWidths(m_minPreferredLogicalWidth, m_maxPreferredLogicalWidth);
    else
        m_minPreferredLogicalWidth = m_maxPreferredLogicalWidth = computeReplacedLogicalWidth(ComputePreferred);

    RenderStyle* styleToUse = style();
    if (styleToUse->logicalWidth().isPercent() || styleToUse->logicalMaxWidth().isPercent())
        m_minPreferredLogicalWidth = 0;

    if (styleToUse->logicalMinWidth().isFixed() && styleToUse->logicalMinWidth().value() > 0) {
        m_maxPreferredLogicalWidth = std::max(m_maxPreferredLogicalWidth, adjustContentBoxLogicalWidthForBoxSizing(styleToUse->logicalMinWidth().value()));
        m_minPreferredLogicalWidth = std::max(m_minPreferredLogicalWidth, adjustContentBoxLogicalWidthForBoxSizing(styleToUse->logicalMinWidth().value()));
    }

    if (styleToUse->logicalMaxWidth().isFixed()) {
        m_maxPreferredLogicalWidth = std::min(m_maxPreferredLogicalWidth, adjustContentBoxLogicalWidthForBoxSizing(styleToUse->logicalMaxWidth().value()));
        m_minPreferredLogicalWidth = std::min(m_minPreferredLogicalWidth, adjustContentBoxLogicalWidthForBoxSizing(styleToUse->logicalMaxWidth().value()));
    }

    LayoutUnit borderAndPadding = borderAndPaddingLogicalWidth();
    m_minPreferredLogicalWidth += borderAndPadding;
    m_maxPreferredLogicalWidth += borderAndPadding;

    clearPreferredLogicalWidthsDirty();
}

PositionWithAffinity RenderReplaced::positionForPoint(const LayoutPoint& point)
{
    // FIXME: This code is buggy if the replaced element is relative positioned.
    InlineBox* box = inlineBoxWrapper();
    RootInlineBox* rootBox = box ? &box->root() : 0;

    LayoutUnit top = rootBox ? rootBox->selectionTop() : logicalTop();
    LayoutUnit bottom = rootBox ? rootBox->selectionBottom() : logicalBottom();

    LayoutUnit blockDirectionPosition = point.y() + y();
    LayoutUnit lineDirectionPosition = point.x() + x();

    if (blockDirectionPosition < top)
        return createPositionWithAffinity(caretMinOffset(), DOWNSTREAM); // coordinates are above

    if (blockDirectionPosition >= bottom)
        return createPositionWithAffinity(caretMaxOffset(), DOWNSTREAM); // coordinates are below

    if (node()) {
        if (lineDirectionPosition <= logicalLeft() + (logicalWidth() / 2))
            return createPositionWithAffinity(0, DOWNSTREAM);
        return createPositionWithAffinity(1, DOWNSTREAM);
    }

    return RenderBox::positionForPoint(point);
}

LayoutRect RenderReplaced::selectionRectForPaintInvalidation(const RenderLayerModelObject* paintInvalidationContainer, bool clipToVisibleContent)
{
    ASSERT(!needsLayout());

    if (!isSelected())
        return LayoutRect();

    LayoutRect rect = localSelectionRect();
    if (clipToVisibleContent)
        mapRectToPaintInvalidationBacking(paintInvalidationContainer, rect, 0);
    else
        rect = localToContainerQuad(FloatRect(rect), paintInvalidationContainer).enclosingBoundingBox();

    return rect;
}

LayoutRect RenderReplaced::localSelectionRect(bool checkWhetherSelected) const
{
    if (checkWhetherSelected && !isSelected())
        return LayoutRect();

    if (!inlineBoxWrapper())
        // We're a block-level replaced element.  Just return our own dimensions.
        return LayoutRect(LayoutPoint(), size());

    RootInlineBox& root = inlineBoxWrapper()->root();
    LayoutUnit newLogicalTop = root.selectionTop() - inlineBoxWrapper()->logicalTop();
    return LayoutRect(0, newLogicalTop, width(), root.selectionHeight());
}

void RenderReplaced::setSelectionState(SelectionState state)
{
    // The selection state for our containing block hierarchy is updated by the base class call.
    RenderBox::setSelectionState(state);

    if (!inlineBoxWrapper())
        return;

    // We only include the space below the baseline in our layer's cached paint invalidation rect if the
    // image is selected. Since the selection state has changed update the rect.
    if (hasLayer())
        setPreviousPaintInvalidationRect(boundsRectForPaintInvalidation(containerForPaintInvalidation()));

    if (canUpdateSelectionOnRootLineBoxes())
        inlineBoxWrapper()->root().setHasSelectedChildren(isSelected());
}

bool RenderReplaced::isSelected() const
{
    SelectionState s = selectionState();
    if (s == SelectionNone)
        return false;
    if (s == SelectionInside)
        return true;

    int selectionStart, selectionEnd;
    selectionStartEnd(selectionStart, selectionEnd);
    if (s == SelectionStart)
        return selectionStart == 0;

    int end = node()->hasChildren() ? node()->countChildren() : 1;
    if (s == SelectionEnd)
        return selectionEnd == end;
    if (s == SelectionBoth)
        return selectionStart == 0 && selectionEnd == end;

    ASSERT(0);
    return false;
}

LayoutRect RenderReplaced::clippedOverflowRectForPaintInvalidation(const RenderLayerModelObject* paintInvalidationContainer, const PaintInvalidationState* paintInvalidationState) const
{
    // The selectionRect can project outside of the overflowRect, so take their union
    // for paint invalidation to avoid selection painting glitches.
    LayoutRect r = isSelected() ? localSelectionRect() : visualOverflowRect();
    mapRectToPaintInvalidationBacking(paintInvalidationContainer, r, paintInvalidationState);
    return r;
}

}
