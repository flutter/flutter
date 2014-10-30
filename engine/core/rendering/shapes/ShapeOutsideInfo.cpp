/*
 * Copyright (C) 2012 Adobe Systems Incorporated. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer.
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include "config.h"
#include "core/rendering/shapes/ShapeOutsideInfo.h"

#include "core/inspector/ConsoleMessage.h"
#include "core/rendering/RenderBlockFlow.h"
#include "core/rendering/RenderBox.h"
#include "core/rendering/RenderImage.h"
#include "platform/LengthFunctions.h"
#include "public/platform/Platform.h"

namespace blink {

CSSBoxType referenceBox(const ShapeValue& shapeValue)
{
    if (shapeValue.cssBox() == BoxMissing)
        return MarginBox;
    return shapeValue.cssBox();
}

void ShapeOutsideInfo::setReferenceBoxLogicalSize(LayoutSize newReferenceBoxLogicalSize)
{
    switch (referenceBox(*m_renderer.style()->shapeOutside())) {
    case MarginBox:
        newReferenceBoxLogicalSize.expand(m_renderer.marginWidth(), m_renderer.marginHeight());
        break;
    case BorderBox:
        break;
    case PaddingBox:
        newReferenceBoxLogicalSize.shrink(m_renderer.borderWidth(), m_renderer.borderHeight());
        break;
    case ContentBox:
        newReferenceBoxLogicalSize.shrink(m_renderer.borderAndPaddingWidth(), m_renderer.borderAndPaddingHeight());
        break;
    case BoxMissing:
        ASSERT_NOT_REACHED();
        break;
    }

    if (m_referenceBoxLogicalSize == newReferenceBoxLogicalSize)
        return;
    markShapeAsDirty();
    m_referenceBoxLogicalSize = newReferenceBoxLogicalSize;
}

static LayoutRect getShapeImageMarginRect(const RenderBox& renderBox, const LayoutSize& referenceBoxLogicalSize)
{
    LayoutPoint marginBoxOrigin(-renderBox.marginLogicalLeft() - renderBox.borderAndPaddingLogicalLeft(), -renderBox.marginBefore() - renderBox.borderBefore() - renderBox.paddingBefore());
    LayoutSize marginBoxSizeDelta(renderBox.marginLogicalWidth() + renderBox.borderAndPaddingLogicalWidth(), renderBox.marginLogicalHeight() + renderBox.borderAndPaddingLogicalHeight());
    return LayoutRect(marginBoxOrigin, referenceBoxLogicalSize + marginBoxSizeDelta);
}

static bool isValidRasterShapeRect(const LayoutRect& rect)
{
    static double maxImageSizeBytes = 0;
    if (!maxImageSizeBytes) {
        size_t size32MaxBytes =  0xFFFFFFFF / 4; // Some platforms don't limit maxDecodedImageBytes.
        maxImageSizeBytes = std::min(size32MaxBytes, Platform::current()->maxDecodedImageBytes());
    }
    return (rect.width().toFloat() * rect.height().toFloat() * 4.0) < maxImageSizeBytes;
}

PassOwnPtr<Shape> ShapeOutsideInfo::createShapeForImage(StyleImage* styleImage, float shapeImageThreshold, float margin) const
{
    const IntSize& imageSize = m_renderer.calculateImageIntrinsicDimensions(styleImage, roundedIntSize(m_referenceBoxLogicalSize), RenderImage::ScaleByEffectiveZoom);
    styleImage->setContainerSizeForRenderer(&m_renderer, imageSize, m_renderer.style()->effectiveZoom());

    const LayoutRect& marginRect = getShapeImageMarginRect(m_renderer, m_referenceBoxLogicalSize);
    const LayoutRect& imageRect = (m_renderer.isRenderImage())
        ? toRenderImage(m_renderer).replacedContentRect()
        : LayoutRect(LayoutPoint(), imageSize);

    if (!isValidRasterShapeRect(marginRect) || !isValidRasterShapeRect(imageRect)) {
        m_renderer.document().addConsoleMessage(ConsoleMessage::create(RenderingMessageSource, ErrorMessageLevel, "The shape-outside image is too large."));
        return Shape::createEmptyRasterShape(margin);
    }

    ASSERT(!styleImage->isPendingImage());
    RefPtr<Image> image = styleImage->image(const_cast<RenderBox*>(&m_renderer), imageSize);

    return Shape::createRasterShape(image.get(), shapeImageThreshold, imageRect, marginRect, margin);
}

const Shape& ShapeOutsideInfo::computedShape() const
{
    if (Shape* shape = m_shape.get())
        return *shape;

    const RenderStyle& style = *m_renderer.style();
    ASSERT(m_renderer.containingBlock());
    LayoutUnit maximumValue = m_renderer.containingBlock() ? m_renderer.containingBlock()->contentWidth() : LayoutUnit();
    float margin = floatValueForLength(m_renderer.style()->shapeMargin(), maximumValue.toFloat());

    float shapeImageThreshold = style.shapeImageThreshold();
    ASSERT(style.shapeOutside());
    const ShapeValue& shapeValue = *style.shapeOutside();

    switch (shapeValue.type()) {
    case ShapeValue::Shape:
        ASSERT(shapeValue.shape());
        m_shape = Shape::createShape(shapeValue.shape(), m_referenceBoxLogicalSize, margin);
        break;
    case ShapeValue::Image:
        ASSERT(shapeValue.isImageValid());
        m_shape = createShapeForImage(shapeValue.image(), shapeImageThreshold, margin);
        break;
    case ShapeValue::Box: {
        const RoundedRect& shapeRect = style.getRoundedBorderFor(LayoutRect(LayoutPoint(), m_referenceBoxLogicalSize), m_renderer.view());
        m_shape = Shape::createLayoutBoxShape(shapeRect, margin);
        break;
    }
    }

    ASSERT(m_shape);
    return *m_shape;
}

inline LayoutUnit borderBeforeInWritingMode(const RenderBox& renderer)
{
    // FIXME(sky): Remove
    return renderer.borderBefore();
}

inline LayoutUnit borderAndPaddingBeforeInWritingMode(const RenderBox& renderer)
{
    // FIXME(sky): Remove
    return renderer.borderAndPaddingBefore();
}

LayoutUnit ShapeOutsideInfo::logicalTopOffset() const
{
    switch (referenceBox(*m_renderer.style()->shapeOutside())) {
    case MarginBox: return -m_renderer.marginBefore(m_renderer.containingBlock()->style());
    case BorderBox: return LayoutUnit();
    case PaddingBox: return borderBeforeInWritingMode(m_renderer);
    case ContentBox: return borderAndPaddingBeforeInWritingMode(m_renderer);
    case BoxMissing: break;
    }

    ASSERT_NOT_REACHED();
    return LayoutUnit();
}

inline LayoutUnit borderStartWithStyleForWritingMode(const RenderBox& renderer, const RenderStyle* style)
{
    if (style->isLeftToRightDirection())
        return renderer.borderLeft();
    return renderer.borderRight();
}

inline LayoutUnit borderAndPaddingStartWithStyleForWritingMode(const RenderBox& renderer, const RenderStyle* style)
{
    if (style->isLeftToRightDirection())
        return renderer.borderLeft() + renderer.paddingLeft();

    return renderer.borderRight() + renderer.paddingRight();
}

LayoutUnit ShapeOutsideInfo::logicalLeftOffset() const
{
    switch (referenceBox(*m_renderer.style()->shapeOutside())) {
    case MarginBox: return -m_renderer.marginStart(m_renderer.containingBlock()->style());
    case BorderBox: return LayoutUnit();
    case PaddingBox: return borderStartWithStyleForWritingMode(m_renderer, m_renderer.containingBlock()->style());
    case ContentBox: return borderAndPaddingStartWithStyleForWritingMode(m_renderer, m_renderer.containingBlock()->style());
    case BoxMissing: break;
    }

    ASSERT_NOT_REACHED();
    return LayoutUnit();
}


bool ShapeOutsideInfo::isEnabledFor(const RenderBox& box)
{
    ShapeValue* shapeValue = box.style()->shapeOutside();
    if (!box.isFloating() || !shapeValue)
        return false;

    switch (shapeValue->type()) {
    case ShapeValue::Shape:
        return shapeValue->shape();
    case ShapeValue::Image:
        return shapeValue->isImageValid();
    case ShapeValue::Box:
        return true;
    }

    return false;
}

ShapeOutsideDeltas ShapeOutsideInfo::computeDeltasForContainingBlockLine(const RenderBlockFlow& containingBlock, const FloatingObject& floatingObject, LayoutUnit lineTop, LayoutUnit lineHeight)
{
    // FIXME(sky): Remove this.
    return ShapeOutsideDeltas();
}

LayoutRect ShapeOutsideInfo::computedShapePhysicalBoundingBox() const
{
    LayoutRect physicalBoundingBox = computedShape().shapeMarginLogicalBoundingBox();
    physicalBoundingBox.setX(physicalBoundingBox.x() + logicalLeftOffset());

    // FIXME(sky): Doing this twice doesn't seem right, but it's what the old code did.
    physicalBoundingBox.setY(physicalBoundingBox.y() + logicalTopOffset());
    physicalBoundingBox.setY(physicalBoundingBox.y() + logicalTopOffset());

    return physicalBoundingBox;
}

FloatPoint ShapeOutsideInfo::shapeToRendererPoint(FloatPoint point) const
{
    return FloatPoint(point.x() + logicalLeftOffset(), point.y() + logicalTopOffset());
}

FloatSize ShapeOutsideInfo::shapeToRendererSize(FloatSize size) const
{
    return size;
}

} // namespace blink
