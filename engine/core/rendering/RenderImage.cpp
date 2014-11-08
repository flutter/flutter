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

#include "config.h"
#include "core/rendering/RenderImage.h"

#include "core/editing/FrameSelection.h"
#include "core/fetch/ImageResource.h"
#include "core/fetch/ResourceLoadPriorityOptimizer.h"
#include "core/fetch/ResourceLoader.h"
#include "core/frame/LocalFrame.h"
#include "core/html/HTMLImageElement.h"
#include "core/inspector/InspectorTraceEvents.h"
#include "core/rendering/HitTestResult.h"
#include "core/rendering/PaintInfo.h"
#include "core/rendering/RenderLayer.h"
#include "core/rendering/RenderView.h"
#include "core/rendering/TextRunConstructor.h"
#include "platform/fonts/Font.h"
#include "platform/fonts/FontCache.h"
#include "platform/graphics/GraphicsContext.h"
#include "platform/graphics/GraphicsContextStateSaver.h"

namespace blink {

float deviceScaleFactor(LocalFrame*);

RenderImage::RenderImage(Element* element)
    : RenderReplaced(element, IntSize())
    , m_isGeneratedContent(false)
    , m_imageDevicePixelRatio(1.0f)
{
    updateAltText();
    ResourceLoadPriorityOptimizer::resourceLoadPriorityOptimizer()->addRenderObject(this);
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

void RenderImage::setImageResource(PassOwnPtr<RenderImageResource> imageResource)
{
    ASSERT(!m_imageResource);
    m_imageResource = imageResource;
    m_imageResource->initialize(this);
}

// If we'll be displaying either alt text or an image, add some padding.
static const unsigned short paddingWidth = 4;
static const unsigned short paddingHeight = 4;

// Alt text is restricted to this maximum size, in pixels.  These are
// signed integers because they are compared with other signed values.
static const float maxAltTextWidth = 1024;
static const int maxAltTextHeight = 256;

IntSize RenderImage::imageSizeForError(ImageResource* newImage) const
{
    ASSERT_ARG(newImage, newImage);
    ASSERT_ARG(newImage, newImage->imageForRenderer(this));

    IntSize imageSize;
    if (newImage->willPaintBrokenImage()) {
        float deviceScaleFactor = blink::deviceScaleFactor(frame());
        pair<Image*, float> brokenImageAndImageScaleFactor = ImageResource::brokenImage(deviceScaleFactor);
        imageSize = brokenImageAndImageScaleFactor.first->size();
        imageSize.scale(1 / brokenImageAndImageScaleFactor.second);
    } else
        imageSize = newImage->imageForRenderer(this)->size();

    // imageSize() returns 0 for the error image. We need the true size of the
    // error image, so we have to get it by grabbing image() directly.
    return IntSize(paddingWidth + imageSize.width() * style()->effectiveZoom(), paddingHeight + imageSize.height() * style()->effectiveZoom());
}

// Sets the image height and width to fit the alt text.  Returns true if the
// image size changed.
bool RenderImage::setImageSizeForAltText(ImageResource* newImage /* = 0 */)
{
    IntSize imageSize;
    if (newImage && newImage->imageForRenderer(this))
        imageSize = imageSizeForError(newImage);
    else if (!m_altText.isEmpty() || newImage) {
        // If we'll be displaying either text or an image, add a little padding.
        imageSize = IntSize(paddingWidth, paddingHeight);
    }

    // we have an alt and the user meant it (its not a text we invented)
    if (!m_altText.isEmpty()) {
        FontCachePurgePreventer fontCachePurgePreventer;

        const Font& font = style()->font();
        IntSize paddedTextSize(paddingWidth + std::min(ceilf(font.width(constructTextRun(this, font, m_altText, style()))), maxAltTextWidth), paddingHeight + std::min(font.fontMetrics().height(), maxAltTextHeight));
        imageSize = imageSize.expandedTo(paddedTextSize);
    }

    if (imageSize == intrinsicSize())
        return false;

    setIntrinsicSize(imageSize);
    return true;
}

void RenderImage::imageChanged(WrappedImagePtr newImage, const IntRect* rect)
{
    if (documentBeingDestroyed())
        return;

    if (hasBoxDecorationBackground() || hasMask())
        RenderReplaced::imageChanged(newImage, rect);

    if (!m_imageResource)
        return;

    if (newImage != m_imageResource->imagePtr())
        return;

    // Per the spec, we let the server-sent header override srcset/other sources of dpr.
    // https://github.com/igrigorik/http-client-hints/blob/master/draft-grigorik-http-client-hints-01.txt#L255
    if (m_imageResource->cachedImage() && m_imageResource->cachedImage()->hasDevicePixelRatioHeaderValue())
        m_imageDevicePixelRatio = 1 / m_imageResource->cachedImage()->devicePixelRatioHeaderValue();

    bool imageSizeChanged = false;

    // Set image dimensions, taking into account the size of the alt text.
    if (m_imageResource->errorOccurred() || !newImage)
        imageSizeChanged = setImageSizeForAltText(m_imageResource->cachedImage());

    paintInvalidationOrMarkForLayout(imageSizeChanged, rect);
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

void RenderImage::paintInvalidationOrMarkForLayout(bool imageSizeChangedToAccomodateAltText, const IntRect* rect)
{
    LayoutSize oldIntrinsicSize = intrinsicSize();
    LayoutSize newIntrinsicSize = m_imageResource->intrinsicSize(style()->effectiveZoom());
    updateIntrinsicSizeIfNeeded(newIntrinsicSize);

    // In the case of generated image content using :before/:after/content, we might not be
    // in the render tree yet. In that case, we just need to update our intrinsic size.
    // layout() will be called after we are inserted in the tree which will take care of
    // what we are doing here.
    if (!containingBlock())
        return;

    bool imageSourceHasChangedSize = oldIntrinsicSize != newIntrinsicSize || imageSizeChangedToAccomodateAltText;
    if (imageSourceHasChangedSize)
        setPreferredLogicalWidthsDirty();

    // If the actual area occupied by the image has changed and it is not constrained by style then a layout is required.
    bool imageSizeIsConstrained = style()->logicalWidth().isSpecified() && style()->logicalHeight().isSpecified();

    // FIXME: We only need to recompute the containing block's preferred size if the containing block's size
    // depends on the image's size (i.e., the container uses shrink-to-fit sizing).
    // There's no easy way to detect that shrink-to-fit is needed, always force a layout.
    bool containingBlockNeedsToRecomputePreferredSize = style()->logicalWidth().isPercent() || style()->logicalMaxWidth().isPercent()  || style()->logicalMinWidth().isPercent();

    if (imageSourceHasChangedSize && (!imageSizeIsConstrained || containingBlockNeedsToRecomputePreferredSize)) {
        setNeedsLayoutAndFullPaintInvalidation();
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

    LayoutRect paintInvalidationRect;
    if (rect) {
        // The image changed rect is in source image coordinates (without zoom),
        // so map from the bounds of the image to the contentsBox.
        const LayoutSize imageSizeWithoutZoom = m_imageResource->imageSize(1 / style()->effectiveZoom());
        paintInvalidationRect = enclosingIntRect(mapRect(*rect, FloatRect(FloatPoint(), imageSizeWithoutZoom), contentBoxRect()));
        // Guard against too-large changed rects.
        paintInvalidationRect.intersect(contentBoxRect());
    } else {
        paintInvalidationRect = contentBoxRect();
    }

    {
        // FIXME: We should not be allowing paint invalidations during layout. crbug.com/339584
        AllowPaintInvalidationScope scoper(frameView());
        DisableCompositingQueryAsserts disabler;
        invalidatePaintRectangle(paintInvalidationRect);
    }

    // Tell any potential compositing layers that the image needs updating.
    contentChanged(ImageChanged);
}

void RenderImage::notifyFinished(Resource* newImage)
{
    if (!m_imageResource)
        return;

    if (documentBeingDestroyed())
        return;

    invalidateBackgroundObscurationStatus();

    if (newImage == m_imageResource->cachedImage()) {
        // tell any potential compositing layers
        // that the image is done and they can reference it directly.
        contentChanged(ImageChanged);
    }
}

void RenderImage::paintReplaced(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    LayoutUnit cWidth = contentWidth();
    LayoutUnit cHeight = contentHeight();

    GraphicsContext* context = paintInfo.context;

    if (!m_imageResource->hasImage() || m_imageResource->errorOccurred()) {
        if (paintInfo.phase == PaintPhaseSelection)
            return;

        if (cWidth > 2 && cHeight > 2) {
            const int borderWidth = 1;

            LayoutUnit leftBorder = borderLeft();
            LayoutUnit topBorder = borderTop();
            LayoutUnit leftPad = paddingLeft();
            LayoutUnit topPad = paddingTop();

            // Draw an outline rect where the image should be.
            context->setStrokeStyle(SolidStroke);
            context->setStrokeColor(Color::lightGray);
            context->setFillColor(Color::transparent);
            context->drawRect(pixelSnappedIntRect(LayoutRect(paintOffset.x() + leftBorder + leftPad, paintOffset.y() + topBorder + topPad, cWidth, cHeight)));

            bool errorPictureDrawn = false;
            LayoutSize imageOffset;
            // When calculating the usable dimensions, exclude the pixels of
            // the ouline rect so the error image/alt text doesn't draw on it.
            LayoutUnit usableWidth = cWidth - 2 * borderWidth;
            LayoutUnit usableHeight = cHeight - 2 * borderWidth;

            RefPtr<Image> image = m_imageResource->image();

            if (m_imageResource->errorOccurred() && !image->isNull() && usableWidth >= image->width() && usableHeight >= image->height()) {
                float deviceScaleFactor = blink::deviceScaleFactor(frame());
                // Call brokenImage() explicitly to ensure we get the broken image icon at the appropriate resolution.
                pair<Image*, float> brokenImageAndImageScaleFactor = ImageResource::brokenImage(deviceScaleFactor);
                image = brokenImageAndImageScaleFactor.first;
                IntSize imageSize = image->size();
                imageSize.scale(1 / brokenImageAndImageScaleFactor.second);
                // Center the error image, accounting for border and padding.
                LayoutUnit centerX = (usableWidth - imageSize.width()) / 2;
                if (centerX < 0)
                    centerX = 0;
                LayoutUnit centerY = (usableHeight - imageSize.height()) / 2;
                if (centerY < 0)
                    centerY = 0;
                imageOffset = LayoutSize(leftBorder + leftPad + centerX + borderWidth, topBorder + topPad + centerY + borderWidth);
                context->drawImage(image.get(), pixelSnappedIntRect(LayoutRect(paintOffset + imageOffset, imageSize)), CompositeSourceOver, shouldRespectImageOrientation());
                errorPictureDrawn = true;
            }

            if (!m_altText.isEmpty()) {
                const Font& font = style()->font();
                const FontMetrics& fontMetrics = font.fontMetrics();
                LayoutUnit ascent = fontMetrics.ascent();
                LayoutPoint textRectOrigin = paintOffset;
                textRectOrigin.move(leftBorder + leftPad + (paddingWidth / 2) - borderWidth, topBorder + topPad + (paddingHeight / 2) - borderWidth);
                LayoutPoint textOrigin(textRectOrigin.x(), textRectOrigin.y() + ascent);

                // Only draw the alt text if it'll fit within the content box,
                // and only if it fits above the error image.
                TextRun textRun = constructTextRun(this, font, m_altText, style(), TextRun::AllowTrailingExpansion | TextRun::ForbidLeadingExpansion, DefaultTextRunFlags | RespectDirection);
                float textWidth = font.width(textRun);
                TextRunPaintInfo textRunPaintInfo(textRun);
                textRunPaintInfo.bounds = FloatRect(textRectOrigin, FloatSize(textWidth, fontMetrics.height()));
                context->setFillColor(resolveColor(CSSPropertyColor));
                if (textRun.direction() == RTL) {
                    int availableWidth = cWidth - static_cast<int>(paddingWidth);
                    textOrigin.move(availableWidth - ceilf(textWidth), 0);
                }
                if (errorPictureDrawn) {
                    if (usableWidth >= textWidth && fontMetrics.height() <= imageOffset.height())
                        context->drawBidiText(font, textRunPaintInfo, textOrigin);
                } else if (usableWidth >= textWidth && usableHeight >= fontMetrics.height()) {
                    context->drawBidiText(font, textRunPaintInfo, textOrigin);
                }
            }
        }
    } else if (m_imageResource->hasImage() && cWidth > 0 && cHeight > 0) {
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

void RenderImage::updateAltText()
{
    if (!node())
        return;

    if (isHTMLImageElement(*node()))
        m_altText = toHTMLImageElement(node())->altText();
}

void RenderImage::layout()
{
    LayoutRect oldContentRect = replacedContentRect();
    RenderReplaced::layout();
    if (replacedContentRect() != oldContentRect) {
        setShouldDoFullPaintInvalidation(true);
        updateInnerContentRect();
    }
}

bool RenderImage::updateImageLoadingPriorities()
{
    if (!m_imageResource || !m_imageResource->cachedImage() || m_imageResource->cachedImage()->isLoaded())
        return false;

    LayoutRect viewBounds = viewRect();
    LayoutRect objectBounds = absoluteContentBox();

    // The object bounds might be empty right now, so intersects will fail since it doesn't deal
    // with empty rects. Use LayoutRect::contains in that case.
    bool isVisible;
    if (!objectBounds.isEmpty())
        isVisible =  viewBounds.intersects(objectBounds);
    else
        isVisible = viewBounds.contains(objectBounds);

    ResourceLoadPriorityOptimizer::VisibilityStatus status = isVisible ?
        ResourceLoadPriorityOptimizer::Visible : ResourceLoadPriorityOptimizer::NotVisible;

    LayoutRect screenArea;
    if (!objectBounds.isEmpty()) {
        screenArea = viewBounds;
        screenArea.intersect(objectBounds);
    }

    ResourceLoadPriorityOptimizer::resourceLoadPriorityOptimizer()->notifyImageResourceVisibility(m_imageResource->cachedImage(), status, screenArea);

    return true;
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
