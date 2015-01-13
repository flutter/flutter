/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 *           (C) 2006 Allan Sandfeld Jensen (kde@carewolf.com)
 *           (C) 2006 Samuel Weinig (sam.weinig@gmail.com)
 * Copyright (C) 2003, 2004, 2005, 2006, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2010 Google Inc. All rights reserved.
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
#include "sky/engine/core/rendering/RenderImage.h"

#include "gen/sky/core/HTMLNames.h"
#include "sky/engine/core/editing/FrameSelection.h"
#include "sky/engine/core/fetch/ImageResource.h"
#include "sky/engine/core/fetch/ResourceLoader.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/html/HTMLImageElement.h"
#include "sky/engine/core/inspector/InspectorTraceEvents.h"
#include "sky/engine/core/rendering/HitTestResult.h"
#include "sky/engine/core/rendering/PaintInfo.h"
#include "sky/engine/core/rendering/RenderLayer.h"
#include "sky/engine/core/rendering/RenderView.h"
#include "sky/engine/core/rendering/TextRunConstructor.h"
#include "sky/engine/platform/fonts/Font.h"
#include "sky/engine/platform/fonts/FontCache.h"
#include "sky/engine/platform/graphics/GraphicsContext.h"
#include "sky/engine/platform/graphics/GraphicsContextStateSaver.h"

namespace blink {

float deviceScaleFactor(LocalFrame*);

RenderImage::RenderImage(Element* element)
    : RenderReplaced(element, IntSize())
    , m_imageDevicePixelRatio(1.0f)
{
}

RenderImage* RenderImage::createAnonymous(Document* document)
{
    RenderImage* image = new RenderImage(0);
    image->setDocumentForAnonymous(document);
    return image;
}

RenderImage::~RenderImage()
{
}

void RenderImage::destroy()
{
    ASSERT(m_imageResource);
    m_imageResource->shutdown();
    RenderReplaced::destroy();
}

void RenderImage::intrinsicSizeChanged()
{
    if (m_imageResource)
        imageChanged(m_imageResource->imagePtr());
}

void RenderImage::setImageResource(PassOwnPtr<RenderImageResource> imageResource)
{
    ASSERT(!m_imageResource);
    m_imageResource = imageResource;
    m_imageResource->initialize(this);
}

void RenderImage::imageChanged(WrappedImagePtr newImage, const IntRect* rect)
{
    if (documentBeingDestroyed())
        return;

    if (!m_imageResource)
        return;

    if (newImage != m_imageResource->imagePtr())
        return;

    // Per the spec, we let the server-sent header override srcset/other sources of dpr.
    // https://github.com/igrigorik/http-client-hints/blob/master/draft-grigorik-http-client-hints-01.txt#L255
    if (m_imageResource->cachedImage() && m_imageResource->cachedImage()->hasDevicePixelRatioHeaderValue())
        m_imageDevicePixelRatio = 1 / m_imageResource->cachedImage()->devicePixelRatioHeaderValue();

    // If the RenderImage was just created we don't have style() or a parent()
    // yet so all we can do is update our intrinsic size. Once we're inserted
    // the resulting layout will do the rest of the work.
    if (!parent()) {
        updateIntrinsicSizeIfNeeded(m_imageResource->intrinsicSize());
        return;
    }

    if (hasBoxDecorationBackground() || hasMask())
        RenderReplaced::imageChanged(newImage, rect);

    paintInvalidationOrMarkForLayout(rect);
}

void RenderImage::updateIntrinsicSizeIfNeeded(const LayoutSize& newSize)
{
    if (m_imageResource->errorOccurred() || !m_imageResource->hasImage())
        return;
    setIntrinsicSize(newSize);
}

void RenderImage::updateInnerContentRect()
{
    // Propagate container size to the image resource.
    LayoutRect containerRect = replacedContentRect();
    IntSize containerSize(containerRect.width(), containerRect.height());
    if (!containerSize.isEmpty())
        m_imageResource->setContainerSizeForRenderer(containerSize);
}

void RenderImage::paintInvalidationOrMarkForLayout(const IntRect* rect)
{
    ASSERT(isRooted());

    LayoutSize oldIntrinsicSize = intrinsicSize();
    LayoutSize newIntrinsicSize = m_imageResource->intrinsicSize();
    updateIntrinsicSizeIfNeeded(newIntrinsicSize);

    bool imageSourceHasChangedSize = oldIntrinsicSize != newIntrinsicSize;
    if (imageSourceHasChangedSize)
        setPreferredLogicalWidthsDirty();

    // If the actual area occupied by the image has changed and it is not constrained by style then a layout is required.
    bool imageSizeIsConstrained = style()->logicalWidth().isSpecified() && style()->logicalHeight().isSpecified();

    // FIXME: We only need to recompute the containing block's preferred size if the containing block's size
    // depends on the image's size (i.e., the container uses shrink-to-fit sizing).
    // There's no easy way to detect that shrink-to-fit is needed, always force a layout.
    bool containingBlockNeedsToRecomputePreferredSize = style()->logicalWidth().isPercent() || style()->logicalMaxWidth().isPercent()  || style()->logicalMinWidth().isPercent();

    if (imageSourceHasChangedSize && (!imageSizeIsConstrained || containingBlockNeedsToRecomputePreferredSize)) {
        setNeedsLayout();
        return;
    }

    // The image hasn't changed in size or its style constrains its size, so a paint invalidation will suffice.
    if (everHadLayout() && !selfNeedsLayout()) {
        // The inner content rectangle is calculated during layout, but may need an update now
        // (unless the box has already been scheduled for layout). In order to calculate it, we
        // may need values from the containing block, though, so make sure that we're not too
        // early. It may be that layout hasn't even taken place once yet.
        updateInnerContentRect();
    }
}

void RenderImage::notifyFinished(Resource* newImage)
{
    if (!m_imageResource)
        return;

    if (documentBeingDestroyed())
        return;

    invalidateBackgroundObscurationStatus();
}

void RenderImage::paintReplaced(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    GraphicsContext* context = paintInfo.context;

    if (m_imageResource->hasImage() && contentWidth() > 0 && contentHeight() > 0) {
        LayoutRect contentRect = contentBoxRect();
        contentRect.moveBy(paintOffset);
        LayoutRect paintRect = replacedContentRect();
        paintRect.moveBy(paintOffset);
        bool clip = !contentRect.contains(paintRect);
        if (clip) {
            context->save();
            context->clip(contentRect);
        }

        paintIntoRect(context, paintRect);

        if (clip)
            context->restore();
    }
}

void RenderImage::paint(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    RenderReplaced::paint(paintInfo, paintOffset);

    if (paintInfo.phase == PaintPhaseOutline)
        paintAreaElementFocusRing(paintInfo);
}

void RenderImage::paintAreaElementFocusRing(PaintInfo& paintInfo)
{
}

void RenderImage::paintIntoRect(GraphicsContext* context, const LayoutRect& rect)
{
    IntRect alignedRect = pixelSnappedIntRect(rect);
    if (!m_imageResource->hasImage() || m_imageResource->errorOccurred() || alignedRect.width() <= 0 || alignedRect.height() <= 0)
        return;

    RefPtr<Image> img = m_imageResource->image(alignedRect.width(), alignedRect.height());
    if (!img || img->isNull())
        return;

    Image* image = img.get();
    InterpolationQuality interpolationQuality = chooseInterpolationQuality(context, image, image, alignedRect.size());

    TRACE_EVENT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "PaintImage", "data", InspectorPaintImageEvent::data(*this));
    InterpolationQuality previousInterpolationQuality = context->imageInterpolationQuality();
    context->setImageInterpolationQuality(interpolationQuality);
    context->drawImage(image, alignedRect, CompositeSourceOver, shouldRespectImageOrientation());
    context->setImageInterpolationQuality(previousInterpolationQuality);
}

bool RenderImage::boxShadowShouldBeAppliedToBackground(BackgroundBleedAvoidance bleedAvoidance, InlineFlowBox*) const
{
    if (!RenderBoxModelObject::boxShadowShouldBeAppliedToBackground(bleedAvoidance))
        return false;

    return !const_cast<RenderImage*>(this)->boxDecorationBackgroundIsKnownToBeObscured();
}

bool RenderImage::foregroundIsKnownToBeOpaqueInRect(const LayoutRect& localRect, unsigned) const
{
    if (!m_imageResource->hasImage() || m_imageResource->errorOccurred())
        return false;
    if (m_imageResource->cachedImage() && !m_imageResource->cachedImage()->isLoaded())
        return false;
    if (!contentBoxRect().contains(localRect))
        return false;
    EFillBox backgroundClip = style()->backgroundClip();
    // Background paints under borders.
    if (backgroundClip == BorderFillBox && style()->hasBorder() && !borderObscuresBackground())
        return false;
    // Background shows in padding area.
    if ((backgroundClip == BorderFillBox || backgroundClip == PaddingFillBox) && style()->hasPadding())
        return false;
    // Object-position may leave parts of the content box empty, regardless of the value of object-fit.
    if (style()->objectPosition() != RenderStyle::initialObjectPosition())
        return false;
    // Object-fit may leave parts of the content box empty.
    ObjectFit objectFit = style()->objectFit();
    if (objectFit != ObjectFitFill && objectFit != ObjectFitCover)
        return false;
    // Check for image with alpha.
    return m_imageResource->cachedImage() && m_imageResource->cachedImage()->currentFrameKnownToBeOpaque(this);
}

bool RenderImage::computeBackgroundIsKnownToBeObscured()
{
    if (!hasBackground())
        return false;

    LayoutRect paintedExtent;
    if (!getBackgroundPaintedExtent(paintedExtent))
        return false;
    return foregroundIsKnownToBeOpaqueInRect(paintedExtent, 0);
}

LayoutUnit RenderImage::minimumReplacedHeight() const
{
    return m_imageResource->errorOccurred() ? intrinsicSize().height() : LayoutUnit();
}

bool RenderImage::nodeAtPoint(const HitTestRequest& request, HitTestResult& result, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset, HitTestAction hitTestAction)
{
    HitTestResult tempResult(result.hitTestLocation());
    bool inside = RenderReplaced::nodeAtPoint(request, tempResult, locationInContainer, accumulatedOffset, hitTestAction);

    if (!inside && result.isRectBasedTest())
        result.append(tempResult);
    if (inside)
        result = tempResult;
    return inside;
}

void RenderImage::layout()
{
    LayoutRect oldContentRect = replacedContentRect();
    RenderReplaced::layout();
    if (replacedContentRect() != oldContentRect) {
        updateInnerContentRect();
    }
}

void RenderImage::computeIntrinsicRatioInformation(FloatSize& intrinsicSize, double& intrinsicRatio) const
{
    RenderReplaced::computeIntrinsicRatioInformation(intrinsicSize, intrinsicRatio);

    // Our intrinsicSize is empty if we're rendering generated images with relative width/height. Figure out the right intrinsic size to use.
    if (intrinsicSize.isEmpty() && (m_imageResource->imageHasRelativeWidth() || m_imageResource->imageHasRelativeHeight())) {
        RenderObject* containingBlock = isOutOfFlowPositioned() ? container() : this->containingBlock();
        if (containingBlock->isBox()) {
            RenderBox* box = toRenderBox(containingBlock);
            intrinsicSize.setWidth(box->availableLogicalWidth().toFloat());
            intrinsicSize.setHeight(box->availableLogicalHeight(IncludeMarginBorderPadding).toFloat());
        }
    }
    // Don't compute an intrinsic ratio to preserve historical WebKit behavior if we're painting alt text and/or a broken image.
    // Video is excluded from this behavior because video elements have a default aspect ratio that a failed poster image load should not override.
    if (m_imageResource && m_imageResource->errorOccurred()) {
        intrinsicRatio = 1;
        return;
    }
}

bool RenderImage::needsPreferredWidthsRecalculation() const
{
    return RenderReplaced::needsPreferredWidthsRecalculation();
}

} // namespace blink
