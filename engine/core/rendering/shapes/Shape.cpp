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
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/rendering/shapes/Shape.h"

#include "core/css/BasicShapeFunctions.h"
#include "core/fetch/ImageResource.h"
#include "core/rendering/shapes/BoxShape.h"
#include "core/rendering/shapes/PolygonShape.h"
#include "core/rendering/shapes/RasterShape.h"
#include "core/rendering/shapes/RectangleShape.h"
#include "core/rendering/style/RenderStyle.h"
#include "platform/LengthFunctions.h"
#include "platform/geometry/FloatSize.h"
#include "platform/graphics/GraphicsContext.h"
#include "platform/graphics/GraphicsTypes.h"
#include "platform/graphics/ImageBuffer.h"
#include "wtf/MathExtras.h"
#include "wtf/OwnPtr.h"

namespace blink {

static PassOwnPtr<Shape> createInsetShape(const FloatRoundedRect& bounds)
{
    ASSERT(bounds.rect().width() >= 0 && bounds.rect().height() >= 0);
    return adoptPtr(new BoxShape(bounds));
}

static PassOwnPtr<Shape> createCircleShape(const FloatPoint& center, float radius)
{
    ASSERT(radius >= 0);
    return adoptPtr(new RectangleShape(FloatRect(center.x() - radius, center.y() - radius, radius*2, radius*2), FloatSize(radius, radius)));
}

static PassOwnPtr<Shape> createEllipseShape(const FloatPoint& center, const FloatSize& radii)
{
    ASSERT(radii.width() >= 0 && radii.height() >= 0);
    return adoptPtr(new RectangleShape(FloatRect(center.x() - radii.width(), center.y() - radii.height(), radii.width()*2, radii.height()*2), radii));
}

static PassOwnPtr<Shape> createPolygonShape(PassOwnPtr<Vector<FloatPoint> > vertices, WindRule fillRule)
{
    return adoptPtr(new PolygonShape(vertices, fillRule));
}

static inline FloatRect physicalRectToLogical(const FloatRect& rect, float logicalBoxHeight, WritingMode writingMode)
{
    if (isHorizontalWritingMode(writingMode))
        return rect;
    if (isFlippedBlocksWritingMode(writingMode))
        return FloatRect(rect.y(), logicalBoxHeight - rect.maxX(), rect.height(), rect.width());
    return rect.transposedRect();
}

static inline FloatPoint physicalPointToLogical(const FloatPoint& point, float logicalBoxHeight, WritingMode writingMode)
{
    if (isHorizontalWritingMode(writingMode))
        return point;
    if (isFlippedBlocksWritingMode(writingMode))
        return FloatPoint(point.y(), logicalBoxHeight - point.x());
    return point.transposedPoint();
}

static inline FloatSize physicalSizeToLogical(const FloatSize& size, WritingMode writingMode)
{
    if (isHorizontalWritingMode(writingMode))
        return size;
    return size.transposedSize();
}

PassOwnPtr<Shape> Shape::createShape(const BasicShape* basicShape, const LayoutSize& logicalBoxSize, WritingMode writingMode, float margin)
{
    ASSERT(basicShape);

    bool horizontalWritingMode = isHorizontalWritingMode(writingMode);
    float boxWidth = horizontalWritingMode ? logicalBoxSize.width().toFloat() : logicalBoxSize.height().toFloat();
    float boxHeight = horizontalWritingMode ? logicalBoxSize.height().toFloat() : logicalBoxSize.width().toFloat();
    OwnPtr<Shape> shape;

    switch (basicShape->type()) {

    case BasicShape::BasicShapeCircleType: {
        const BasicShapeCircle* circle = toBasicShapeCircle(basicShape);
        FloatPoint center = floatPointForCenterCoordinate(circle->centerX(), circle->centerY(), FloatSize(boxWidth, boxHeight));
        float radius = circle->floatValueForRadiusInBox(FloatSize(boxWidth, boxHeight));
        FloatPoint logicalCenter = physicalPointToLogical(center, logicalBoxSize.height().toFloat(), writingMode);

        shape = createCircleShape(logicalCenter, radius);
        break;
    }

    case BasicShape::BasicShapeEllipseType: {
        const BasicShapeEllipse* ellipse = toBasicShapeEllipse(basicShape);
        FloatPoint center = floatPointForCenterCoordinate(ellipse->centerX(), ellipse->centerY(), FloatSize(boxWidth, boxHeight));
        float radiusX = ellipse->floatValueForRadiusInBox(ellipse->radiusX(), center.x(), boxWidth);
        float radiusY = ellipse->floatValueForRadiusInBox(ellipse->radiusY(), center.y(), boxHeight);
        FloatPoint logicalCenter = physicalPointToLogical(center, logicalBoxSize.height().toFloat(), writingMode);

        shape = createEllipseShape(logicalCenter, FloatSize(radiusX, radiusY));
        break;
    }

    case BasicShape::BasicShapePolygonType: {
        const BasicShapePolygon* polygon = toBasicShapePolygon(basicShape);
        const Vector<Length>& values = polygon->values();
        size_t valuesSize = values.size();
        ASSERT(!(valuesSize % 2));
        OwnPtr<Vector<FloatPoint> > vertices = adoptPtr(new Vector<FloatPoint>(valuesSize / 2));
        for (unsigned i = 0; i < valuesSize; i += 2) {
            FloatPoint vertex(
                floatValueForLength(values.at(i), boxWidth),
                floatValueForLength(values.at(i + 1), boxHeight));
            (*vertices)[i / 2] = physicalPointToLogical(vertex, logicalBoxSize.height().toFloat(), writingMode);
        }
        shape = createPolygonShape(vertices.release(), polygon->windRule());
        break;
    }

    case BasicShape::BasicShapeInsetType: {
        const BasicShapeInset& inset = *toBasicShapeInset(basicShape);
        float left = floatValueForLength(inset.left(), boxWidth);
        float top = floatValueForLength(inset.top(), boxHeight);
        float right = floatValueForLength(inset.right(), boxWidth);
        float bottom = floatValueForLength(inset.bottom(), boxHeight);
        FloatRect rect(left, top, std::max<float>(boxWidth - left - right, 0), std::max<float>(boxHeight - top - bottom, 0));
        FloatRect logicalRect = physicalRectToLogical(rect, logicalBoxSize.height().toFloat(), writingMode);

        FloatSize boxSize(boxWidth, boxHeight);
        FloatSize topLeftRadius = physicalSizeToLogical(floatSizeForLengthSize(inset.topLeftRadius(), boxSize), writingMode);
        FloatSize topRightRadius = physicalSizeToLogical(floatSizeForLengthSize(inset.topRightRadius(), boxSize), writingMode);
        FloatSize bottomLeftRadius = physicalSizeToLogical(floatSizeForLengthSize(inset.bottomLeftRadius(), boxSize), writingMode);
        FloatSize bottomRightRadius = physicalSizeToLogical(floatSizeForLengthSize(inset.bottomRightRadius(), boxSize), writingMode);
        FloatRoundedRect::Radii cornerRadii(topLeftRadius, topRightRadius, bottomLeftRadius, bottomRightRadius);

        cornerRadii.scale(calcBorderRadiiConstraintScaleFor(logicalRect, cornerRadii));

        shape = createInsetShape(FloatRoundedRect(logicalRect, cornerRadii));
        break;
    }

    default:
        ASSERT_NOT_REACHED();
    }

    shape->m_writingMode = writingMode;
    shape->m_margin = margin;

    return shape.release();
}

PassOwnPtr<Shape> Shape::createEmptyRasterShape(WritingMode writingMode, float margin)
{
    OwnPtr<RasterShapeIntervals> intervals = adoptPtr(new RasterShapeIntervals(0, 0));
    OwnPtr<RasterShape> rasterShape = adoptPtr(new RasterShape(intervals.release(), IntSize()));
    rasterShape->m_writingMode = writingMode;
    rasterShape->m_margin = margin;
    return rasterShape.release();
}

PassOwnPtr<Shape> Shape::createRasterShape(Image* image, float threshold, const LayoutRect& imageR, const LayoutRect& marginR, WritingMode writingMode, float margin)
{
    IntRect imageRect = pixelSnappedIntRect(imageR);
    IntRect marginRect = pixelSnappedIntRect(marginR);

    OwnPtr<RasterShapeIntervals> intervals = adoptPtr(new RasterShapeIntervals(marginRect.height(), -marginRect.y()));
    OwnPtr<ImageBuffer> imageBuffer = ImageBuffer::create(imageRect.size());

    if (imageBuffer) {
        GraphicsContext* graphicsContext = imageBuffer->context();
        graphicsContext->drawImage(image, IntRect(IntPoint(), imageRect.size()));

        RefPtr<Uint8ClampedArray> pixelArray = imageBuffer->getImageData(Unmultiplied, IntRect(IntPoint(), imageRect.size()));
        unsigned pixelArrayOffset = 3; // Each pixel is four bytes: RGBA.
        uint8_t alphaPixelThreshold = threshold * 255;

        ASSERT(static_cast<unsigned>(imageRect.width() * imageRect.height() * 4) == pixelArray->length());

        int minBufferY = std::max(0, marginRect.y() - imageRect.y());
        int maxBufferY = std::min(imageRect.height(), marginRect.maxY() - imageRect.y());

        for (int y = minBufferY; y < maxBufferY; ++y) {
            int startX = -1;
            for (int x = 0; x < imageRect.width(); ++x, pixelArrayOffset += 4) {
                uint8_t alpha = pixelArray->item(pixelArrayOffset);
                bool alphaAboveThreshold = alpha > alphaPixelThreshold;
                if (startX == -1 && alphaAboveThreshold) {
                    startX = x;
                } else if (startX != -1 && (!alphaAboveThreshold || x == imageRect.width() - 1)) {
                    int endX = alphaAboveThreshold ? x + 1 : x;
                    intervals->intervalAt(y + imageRect.y()).unite(IntShapeInterval(startX + imageRect.x(), endX + imageRect.x()));
                    startX = -1;
                }
            }
        }
    }

    OwnPtr<RasterShape> rasterShape = adoptPtr(new RasterShape(intervals.release(), marginRect.size()));
    rasterShape->m_writingMode = writingMode;
    rasterShape->m_margin = margin;
    return rasterShape.release();
}

PassOwnPtr<Shape> Shape::createLayoutBoxShape(const RoundedRect& roundedRect, WritingMode writingMode, float margin)
{
    FloatRect rect(0, 0, roundedRect.rect().width(), roundedRect.rect().height());
    FloatRoundedRect bounds(rect, roundedRect.radii());
    OwnPtr<Shape> shape = createInsetShape(bounds);
    shape->m_writingMode = writingMode;
    shape->m_margin = margin;

    return shape.release();
}

} // namespace blink
