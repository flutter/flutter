/*
 * Copyright (C) 2008 Apple Inc.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/css/CSSGradientValue.h"

#include "core/CSSValueKeywords.h"
#include "core/css/CSSCalculationValue.h"
#include "core/css/CSSToLengthConversionData.h"
#include "core/css/Pair.h"
#include "core/dom/NodeRenderStyle.h"
#include "core/dom/TextLinkColors.h"
#include "core/rendering/RenderObject.h"
#include "platform/geometry/IntSize.h"
#include "platform/graphics/Gradient.h"
#include "platform/graphics/GradientGeneratedImage.h"
#include "platform/graphics/Image.h"
#include "wtf/text/StringBuilder.h"
#include "wtf/text/WTFString.h"

namespace blink {

void CSSGradientColorStop::trace(Visitor* visitor)
{
    visitor->trace(m_position);
    visitor->trace(m_color);
}

PassRefPtr<Image> CSSGradientValue::image(RenderObject* renderer, const IntSize& size)
{
    if (size.isEmpty())
        return nullptr;

    bool cacheable = isCacheable();
    if (cacheable) {
        if (!clients().contains(renderer))
            return nullptr;

        // Need to look up our size.  Create a string of width*height to use as a hash key.
        Image* result = getImage(renderer, size);
        if (result)
            return result;
    }

    // We need to create an image.
    RefPtr<Gradient> gradient;

    RenderStyle* rootStyle = renderer->document().documentElement()->renderStyle();
    CSSToLengthConversionData conversionData(renderer->style(), rootStyle, renderer->view());
    if (isLinearGradientValue())
        gradient = toCSSLinearGradientValue(this)->createGradient(conversionData, size);
    else
        gradient = toCSSRadialGradientValue(this)->createGradient(conversionData, size);

    RefPtr<Image> newImage = GradientGeneratedImage::create(gradient, size);
    if (cacheable)
        putImage(size, newImage);

    return newImage.release();
}

// Should only ever be called for deprecated gradients.
static inline bool compareStops(const CSSGradientColorStop& a, const CSSGradientColorStop& b)
{
    double aVal = a.m_position->getDoubleValue(CSSPrimitiveValue::CSS_NUMBER);
    double bVal = b.m_position->getDoubleValue(CSSPrimitiveValue::CSS_NUMBER);

    return aVal < bVal;
}

void CSSGradientValue::sortStopsIfNeeded()
{
    ASSERT(m_gradientType == CSSDeprecatedLinearGradient || m_gradientType == CSSDeprecatedRadialGradient);
    if (!m_stopsSorted) {
        if (m_stops.size())
            std::stable_sort(m_stops.begin(), m_stops.end(), compareStops);
        m_stopsSorted = true;
    }
}

struct GradientStop {
    Color color;
    float offset;
    bool specified;

    GradientStop()
        : offset(0)
        , specified(false)
    { }
};

PassRefPtrWillBeRawPtr<CSSGradientValue> CSSGradientValue::gradientWithStylesResolved(const TextLinkColors& textLinkColors, Color currentColor)
{
    bool derived = false;
    for (unsigned i = 0; i < m_stops.size(); i++)
        if (m_stops[i].m_color->colorIsDerivedFromElement()) {
            m_stops[i].m_colorIsDerivedFromElement = true;
            derived = true;
            break;
        }

    RefPtrWillBeRawPtr<CSSGradientValue> result = nullptr;
    if (!derived)
        result = this;
    else if (isLinearGradientValue())
        result = toCSSLinearGradientValue(this)->clone();
    else if (isRadialGradientValue())
        result = toCSSRadialGradientValue(this)->clone();
    else {
        ASSERT_NOT_REACHED();
        return nullptr;
    }

    for (unsigned i = 0; i < result->m_stops.size(); i++)
        result->m_stops[i].m_resolvedColor = textLinkColors.colorFromPrimitiveValue(result->m_stops[i].m_color.get(), currentColor);

    return result.release();
}

void CSSGradientValue::addStops(Gradient* gradient, const CSSToLengthConversionData& conversionData, float maxLengthForRepeat)
{
    if (m_gradientType == CSSDeprecatedLinearGradient || m_gradientType == CSSDeprecatedRadialGradient) {
        sortStopsIfNeeded();

        for (unsigned i = 0; i < m_stops.size(); i++) {
            const CSSGradientColorStop& stop = m_stops[i];

            float offset;
            if (stop.m_position->isPercentage())
                offset = stop.m_position->getFloatValue(CSSPrimitiveValue::CSS_PERCENTAGE) / 100;
            else
                offset = stop.m_position->getFloatValue(CSSPrimitiveValue::CSS_NUMBER);

            gradient->addColorStop(offset, stop.m_resolvedColor);
        }

        return;
    }

    size_t numStops = m_stops.size();

    Vector<GradientStop> stops(numStops);

    float gradientLength = 0;
    bool computedGradientLength = false;

    FloatPoint gradientStart = gradient->p0();
    FloatPoint gradientEnd;
    if (isLinearGradientValue())
        gradientEnd = gradient->p1();
    else if (isRadialGradientValue())
        gradientEnd = gradientStart + FloatSize(gradient->endRadius(), 0);

    for (size_t i = 0; i < numStops; ++i) {
        const CSSGradientColorStop& stop = m_stops[i];

        stops[i].color = stop.m_resolvedColor;

        if (stop.m_position) {
            if (stop.m_position->isPercentage())
                stops[i].offset = stop.m_position->getFloatValue(CSSPrimitiveValue::CSS_PERCENTAGE) / 100;
            else if (stop.m_position->isLength() || stop.m_position->isCalculatedPercentageWithLength()) {
                if (!computedGradientLength) {
                    FloatSize gradientSize(gradientStart - gradientEnd);
                    gradientLength = gradientSize.diagonalLength();
                }
                float length;
                if (stop.m_position->isLength())
                    length = stop.m_position->computeLength<float>(conversionData);
                else
                    length = stop.m_position->cssCalcValue()->toCalcValue(conversionData)->evaluate(gradientLength);
                stops[i].offset = (gradientLength > 0) ? length / gradientLength : 0;
            } else {
                ASSERT_NOT_REACHED();
                stops[i].offset = 0;
            }
            stops[i].specified = true;
        } else {
            // If the first color-stop does not have a position, its position defaults to 0%.
            // If the last color-stop does not have a position, its position defaults to 100%.
            if (!i) {
                stops[i].offset = 0;
                stops[i].specified = true;
            } else if (numStops > 1 && i == numStops - 1) {
                stops[i].offset = 1;
                stops[i].specified = true;
            }
        }

        // If a color-stop has a position that is less than the specified position of any
        // color-stop before it in the list, its position is changed to be equal to the
        // largest specified position of any color-stop before it.
        if (stops[i].specified && i > 0) {
            size_t prevSpecifiedIndex;
            for (prevSpecifiedIndex = i - 1; prevSpecifiedIndex; --prevSpecifiedIndex) {
                if (stops[prevSpecifiedIndex].specified)
                    break;
            }

            if (stops[i].offset < stops[prevSpecifiedIndex].offset)
                stops[i].offset = stops[prevSpecifiedIndex].offset;
        }
    }

    ASSERT(stops[0].specified && stops[numStops - 1].specified);

    // If any color-stop still does not have a position, then, for each run of adjacent
    // color-stops without positions, set their positions so that they are evenly spaced
    // between the preceding and following color-stops with positions.
    if (numStops > 2) {
        size_t unspecifiedRunStart = 0;
        bool inUnspecifiedRun = false;

        for (size_t i = 0; i < numStops; ++i) {
            if (!stops[i].specified && !inUnspecifiedRun) {
                unspecifiedRunStart = i;
                inUnspecifiedRun = true;
            } else if (stops[i].specified && inUnspecifiedRun) {
                size_t unspecifiedRunEnd = i;

                if (unspecifiedRunStart < unspecifiedRunEnd) {
                    float lastSpecifiedOffset = stops[unspecifiedRunStart - 1].offset;
                    float nextSpecifiedOffset = stops[unspecifiedRunEnd].offset;
                    float delta = (nextSpecifiedOffset - lastSpecifiedOffset) / (unspecifiedRunEnd - unspecifiedRunStart + 1);

                    for (size_t j = unspecifiedRunStart; j < unspecifiedRunEnd; ++j)
                        stops[j].offset = lastSpecifiedOffset + (j - unspecifiedRunStart + 1) * delta;
                }

                inUnspecifiedRun = false;
            }
        }
    }

    // If the gradient is repeating, repeat the color stops.
    // We can't just push this logic down into the platform-specific Gradient code,
    // because we have to know the extent of the gradient, and possible move the end points.
    if (m_repeating && numStops > 1) {
        // If the difference in the positions of the first and last color-stops is 0,
        // the gradient defines a solid-color image with the color of the last color-stop in the rule.
        float gradientRange = stops[numStops - 1].offset - stops[0].offset;
        if (!gradientRange) {
            stops.first().offset = 0;
            stops.first().color = stops.last().color;
            stops.shrink(1);
        } else {
            float maxExtent = 1;

            // Radial gradients may need to extend further than the endpoints, because they have
            // to repeat out to the corners of the box.
            if (isRadialGradientValue()) {
                if (!computedGradientLength) {
                    FloatSize gradientSize(gradientStart - gradientEnd);
                    gradientLength = gradientSize.diagonalLength();
                }

                if (maxLengthForRepeat > gradientLength)
                    maxExtent = gradientLength > 0 ? maxLengthForRepeat / gradientLength : 0;
            }

            size_t originalNumStops = numStops;
            size_t originalFirstStopIndex = 0;

            // Work backwards from the first, adding stops until we get one before 0.
            float firstOffset = stops[0].offset;
            if (firstOffset > 0) {
                float currOffset = firstOffset;
                size_t srcStopOrdinal = originalNumStops - 1;

                while (true) {
                    GradientStop newStop = stops[originalFirstStopIndex + srcStopOrdinal];
                    newStop.offset = currOffset;
                    stops.prepend(newStop);
                    ++originalFirstStopIndex;
                    if (currOffset < 0)
                        break;

                    if (srcStopOrdinal)
                        currOffset -= stops[originalFirstStopIndex + srcStopOrdinal].offset - stops[originalFirstStopIndex + srcStopOrdinal - 1].offset;
                    srcStopOrdinal = (srcStopOrdinal + originalNumStops - 1) % originalNumStops;
                }
            }

            // Work forwards from the end, adding stops until we get one after 1.
            float lastOffset = stops[stops.size() - 1].offset;
            if (lastOffset < maxExtent) {
                float currOffset = lastOffset;
                size_t srcStopOrdinal = 0;

                while (true) {
                    size_t srcStopIndex = originalFirstStopIndex + srcStopOrdinal;
                    GradientStop newStop = stops[srcStopIndex];
                    newStop.offset = currOffset;
                    stops.append(newStop);
                    if (currOffset > maxExtent)
                        break;
                    if (srcStopOrdinal < originalNumStops - 1)
                        currOffset += stops[srcStopIndex + 1].offset - stops[srcStopIndex].offset;
                    srcStopOrdinal = (srcStopOrdinal + 1) % originalNumStops;
                }
            }
        }
    }

    numStops = stops.size();

    // If the gradient goes outside the 0-1 range, normalize it by moving the endpoints, and adjusting the stops.
    if (numStops > 1 && (stops[0].offset < 0 || stops[numStops - 1].offset > 1)) {
        if (isLinearGradientValue()) {
            float firstOffset = stops[0].offset;
            float lastOffset = stops[numStops - 1].offset;
            float scale = lastOffset - firstOffset;

            for (size_t i = 0; i < numStops; ++i)
                stops[i].offset = (stops[i].offset - firstOffset) / scale;

            FloatPoint p0 = gradient->p0();
            FloatPoint p1 = gradient->p1();
            gradient->setP0(FloatPoint(p0.x() + firstOffset * (p1.x() - p0.x()), p0.y() + firstOffset * (p1.y() - p0.y())));
            gradient->setP1(FloatPoint(p1.x() + (lastOffset - 1) * (p1.x() - p0.x()), p1.y() + (lastOffset - 1) * (p1.y() - p0.y())));
        } else if (isRadialGradientValue()) {
            // Rather than scaling the points < 0, we truncate them, so only scale according to the largest point.
            float firstOffset = 0;
            float lastOffset = stops[numStops - 1].offset;
            float scale = lastOffset - firstOffset;

            // Reset points below 0 to the first visible color.
            size_t firstZeroOrGreaterIndex = numStops;
            for (size_t i = 0; i < numStops; ++i) {
                if (stops[i].offset >= 0) {
                    firstZeroOrGreaterIndex = i;
                    break;
                }
            }

            if (firstZeroOrGreaterIndex > 0) {
                if (firstZeroOrGreaterIndex < numStops && stops[firstZeroOrGreaterIndex].offset > 0) {
                    float prevOffset = stops[firstZeroOrGreaterIndex - 1].offset;
                    float nextOffset = stops[firstZeroOrGreaterIndex].offset;

                    float interStopProportion = -prevOffset / (nextOffset - prevOffset);
                    // FIXME: when we interpolate gradients using premultiplied colors, this should do premultiplication.
                    Color blendedColor = blend(stops[firstZeroOrGreaterIndex - 1].color, stops[firstZeroOrGreaterIndex].color, interStopProportion);

                    // Clamp the positions to 0 and set the color.
                    for (size_t i = 0; i < firstZeroOrGreaterIndex; ++i) {
                        stops[i].offset = 0;
                        stops[i].color = blendedColor;
                    }
                } else {
                    // All stops are below 0; just clamp them.
                    for (size_t i = 0; i < firstZeroOrGreaterIndex; ++i)
                        stops[i].offset = 0;
                }
            }

            for (size_t i = 0; i < numStops; ++i)
                stops[i].offset /= scale;

            gradient->setStartRadius(gradient->startRadius() * scale);
            gradient->setEndRadius(gradient->endRadius() * scale);
        }
    }

    for (unsigned i = 0; i < numStops; i++)
        gradient->addColorStop(stops[i].offset, stops[i].color);
}

static float positionFromValue(CSSPrimitiveValue* value, const CSSToLengthConversionData& conversionData, const IntSize& size, bool isHorizontal)
{
    int origin = 0;
    int sign = 1;
    int edgeDistance = isHorizontal ? size.width() : size.height();

    // In this case the center of the gradient is given relative to an edge in the form of:
    // [ top | bottom | right | left ] [ <percentage> | <length> ].
    if (Pair* pair = value->getPairValue()) {
        CSSValueID originID = pair->first()->getValueID();
        value = pair->second();

        if (originID == CSSValueRight || originID == CSSValueBottom) {
            // For right/bottom, the offset is relative to the far edge.
            origin = edgeDistance;
            sign = -1;
        }
    }

    if (value->isNumber())
        return origin + sign * value->getFloatValue() * conversionData.zoom();

    if (value->isPercentage())
        return origin + sign * value->getFloatValue() / 100.f * edgeDistance;

    if (value->isCalculatedPercentageWithLength())
        return origin + sign * value->cssCalcValue()->toCalcValue(conversionData)->evaluate(edgeDistance);

    switch (value->getValueID()) {
    case CSSValueTop:
        ASSERT(!isHorizontal);
        return 0;
    case CSSValueLeft:
        ASSERT(isHorizontal);
        return 0;
    case CSSValueBottom:
        ASSERT(!isHorizontal);
        return size.height();
    case CSSValueRight:
        ASSERT(isHorizontal);
        return size.width();
    default:
        break;
    }

    return origin + sign * value->computeLength<float>(conversionData);
}

FloatPoint CSSGradientValue::computeEndPoint(CSSPrimitiveValue* horizontal, CSSPrimitiveValue* vertical, const CSSToLengthConversionData& conversionData, const IntSize& size)
{
    FloatPoint result;

    if (horizontal)
        result.setX(positionFromValue(horizontal, conversionData, size, true));

    if (vertical)
        result.setY(positionFromValue(vertical, conversionData, size, false));

    return result;
}

bool CSSGradientValue::isCacheable() const
{
    for (size_t i = 0; i < m_stops.size(); ++i) {
        const CSSGradientColorStop& stop = m_stops[i];

        if (stop.m_colorIsDerivedFromElement)
            return false;

        if (!stop.m_position)
            continue;

        if (stop.m_position->isFontRelativeLength())
            return false;
    }

    return true;
}

bool CSSGradientValue::knownToBeOpaque(const RenderObject*) const
{
    for (size_t i = 0; i < m_stops.size(); ++i) {
        if (m_stops[i].m_resolvedColor.hasAlpha())
            return false;
    }
    return true;
}

void CSSGradientValue::traceAfterDispatch(Visitor* visitor)
{
    visitor->trace(m_firstX);
    visitor->trace(m_firstY);
    visitor->trace(m_secondX);
    visitor->trace(m_secondY);
    visitor->trace(m_stops);
    CSSImageGeneratorValue::traceAfterDispatch(visitor);
}

String CSSLinearGradientValue::customCSSText() const
{
    StringBuilder result;
    if (m_gradientType == CSSDeprecatedLinearGradient) {
        result.appendLiteral("-webkit-gradient(linear, ");
        result.append(m_firstX->cssText());
        result.append(' ');
        result.append(m_firstY->cssText());
        result.appendLiteral(", ");
        result.append(m_secondX->cssText());
        result.append(' ');
        result.append(m_secondY->cssText());

        for (unsigned i = 0; i < m_stops.size(); i++) {
            const CSSGradientColorStop& stop = m_stops[i];
            result.appendLiteral(", ");
            if (stop.m_position->getDoubleValue(CSSPrimitiveValue::CSS_NUMBER) == 0) {
                result.appendLiteral("from(");
                result.append(stop.m_color->cssText());
                result.append(')');
            } else if (stop.m_position->getDoubleValue(CSSPrimitiveValue::CSS_NUMBER) == 1) {
                result.appendLiteral("to(");
                result.append(stop.m_color->cssText());
                result.append(')');
            } else {
                result.appendLiteral("color-stop(");
                result.append(String::number(stop.m_position->getDoubleValue(CSSPrimitiveValue::CSS_NUMBER)));
                result.appendLiteral(", ");
                result.append(stop.m_color->cssText());
                result.append(')');
            }
        }
    } else if (m_gradientType == CSSPrefixedLinearGradient) {
        if (m_repeating)
            result.appendLiteral("-webkit-repeating-linear-gradient(");
        else
            result.appendLiteral("-webkit-linear-gradient(");

        if (m_angle)
            result.append(m_angle->cssText());
        else {
            if (m_firstX && m_firstY) {
                result.append(m_firstX->cssText());
                result.append(' ');
                result.append(m_firstY->cssText());
            } else if (m_firstX || m_firstY) {
                if (m_firstX)
                    result.append(m_firstX->cssText());

                if (m_firstY)
                    result.append(m_firstY->cssText());
            }
        }

        for (unsigned i = 0; i < m_stops.size(); i++) {
            const CSSGradientColorStop& stop = m_stops[i];
            result.appendLiteral(", ");
            result.append(stop.m_color->cssText());
            if (stop.m_position) {
                result.append(' ');
                result.append(stop.m_position->cssText());
            }
        }
    } else {
        if (m_repeating)
            result.appendLiteral("repeating-linear-gradient(");
        else
            result.appendLiteral("linear-gradient(");

        bool wroteSomething = false;

        if (m_angle && m_angle->computeDegrees() != 180) {
            result.append(m_angle->cssText());
            wroteSomething = true;
        } else if ((m_firstX || m_firstY) && !(!m_firstX && m_firstY && m_firstY->getValueID() == CSSValueBottom)) {
            result.appendLiteral("to ");
            if (m_firstX && m_firstY) {
                result.append(m_firstX->cssText());
                result.append(' ');
                result.append(m_firstY->cssText());
            } else if (m_firstX)
                result.append(m_firstX->cssText());
            else
                result.append(m_firstY->cssText());
            wroteSomething = true;
        }

        if (wroteSomething)
            result.appendLiteral(", ");

        for (unsigned i = 0; i < m_stops.size(); i++) {
            const CSSGradientColorStop& stop = m_stops[i];
            if (i)
                result.appendLiteral(", ");
            result.append(stop.m_color->cssText());
            if (stop.m_position) {
                result.append(' ');
                result.append(stop.m_position->cssText());
            }
        }

    }

    result.append(')');
    return result.toString();
}

// Compute the endpoints so that a gradient of the given angle covers a box of the given size.
static void endPointsFromAngle(float angleDeg, const IntSize& size, FloatPoint& firstPoint, FloatPoint& secondPoint, CSSGradientType type)
{
    // Prefixed gradients use "polar coordinate" angles, rather than "bearing" angles.
    if (type == CSSPrefixedLinearGradient)
        angleDeg = 90 - angleDeg;

    angleDeg = fmodf(angleDeg, 360);
    if (angleDeg < 0)
        angleDeg += 360;

    if (!angleDeg) {
        firstPoint.set(0, size.height());
        secondPoint.set(0, 0);
        return;
    }

    if (angleDeg == 90) {
        firstPoint.set(0, 0);
        secondPoint.set(size.width(), 0);
        return;
    }

    if (angleDeg == 180) {
        firstPoint.set(0, 0);
        secondPoint.set(0, size.height());
        return;
    }

    if (angleDeg == 270) {
        firstPoint.set(size.width(), 0);
        secondPoint.set(0, 0);
        return;
    }

    // angleDeg is a "bearing angle" (0deg = N, 90deg = E),
    // but tan expects 0deg = E, 90deg = N.
    float slope = tan(deg2rad(90 - angleDeg));

    // We find the endpoint by computing the intersection of the line formed by the slope,
    // and a line perpendicular to it that intersects the corner.
    float perpendicularSlope = -1 / slope;

    // Compute start corner relative to center, in Cartesian space (+y = up).
    float halfHeight = size.height() / 2;
    float halfWidth = size.width() / 2;
    FloatPoint endCorner;
    if (angleDeg < 90)
        endCorner.set(halfWidth, halfHeight);
    else if (angleDeg < 180)
        endCorner.set(halfWidth, -halfHeight);
    else if (angleDeg < 270)
        endCorner.set(-halfWidth, -halfHeight);
    else
        endCorner.set(-halfWidth, halfHeight);

    // Compute c (of y = mx + c) using the corner point.
    float c = endCorner.y() - perpendicularSlope * endCorner.x();
    float endX = c / (slope - perpendicularSlope);
    float endY = perpendicularSlope * endX + c;

    // We computed the end point, so set the second point,
    // taking into account the moved origin and the fact that we're in drawing space (+y = down).
    secondPoint.set(halfWidth + endX, halfHeight - endY);
    // Reflect around the center for the start point.
    firstPoint.set(halfWidth - endX, halfHeight + endY);
}

PassRefPtr<Gradient> CSSLinearGradientValue::createGradient(const CSSToLengthConversionData& conversionData, const IntSize& size)
{
    ASSERT(!size.isEmpty());

    FloatPoint firstPoint;
    FloatPoint secondPoint;
    if (m_angle) {
        float angle = m_angle->getFloatValue(CSSPrimitiveValue::CSS_DEG);
        endPointsFromAngle(angle, size, firstPoint, secondPoint, m_gradientType);
    } else {
        switch (m_gradientType) {
        case CSSDeprecatedLinearGradient:
            firstPoint = computeEndPoint(m_firstX.get(), m_firstY.get(), conversionData, size);
            if (m_secondX || m_secondY)
                secondPoint = computeEndPoint(m_secondX.get(), m_secondY.get(), conversionData, size);
            else {
                if (m_firstX)
                    secondPoint.setX(size.width() - firstPoint.x());
                if (m_firstY)
                    secondPoint.setY(size.height() - firstPoint.y());
            }
            break;
        case CSSPrefixedLinearGradient:
            firstPoint = computeEndPoint(m_firstX.get(), m_firstY.get(), conversionData, size);
            if (m_firstX)
                secondPoint.setX(size.width() - firstPoint.x());
            if (m_firstY)
                secondPoint.setY(size.height() - firstPoint.y());
            break;
        case CSSLinearGradient:
            if (m_firstX && m_firstY) {
                // "Magic" corners, so the 50% line touches two corners.
                float rise = size.width();
                float run = size.height();
                if (m_firstX && m_firstX->getValueID() == CSSValueLeft)
                    run *= -1;
                if (m_firstY && m_firstY->getValueID() == CSSValueBottom)
                    rise *= -1;
                // Compute angle, and flip it back to "bearing angle" degrees.
                float angle = 90 - rad2deg(atan2(rise, run));
                endPointsFromAngle(angle, size, firstPoint, secondPoint, m_gradientType);
            } else if (m_firstX || m_firstY) {
                secondPoint = computeEndPoint(m_firstX.get(), m_firstY.get(), conversionData, size);
                if (m_firstX)
                    firstPoint.setX(size.width() - secondPoint.x());
                if (m_firstY)
                    firstPoint.setY(size.height() - secondPoint.y());
            } else
                secondPoint.setY(size.height());
            break;
        default:
            ASSERT_NOT_REACHED();
        }

    }

    RefPtr<Gradient> gradient = Gradient::create(firstPoint, secondPoint);

    gradient->setDrawsInPMColorSpace(true);

    // Now add the stops.
    addStops(gradient.get(), conversionData, 1);

    return gradient.release();
}

bool CSSLinearGradientValue::equals(const CSSLinearGradientValue& other) const
{
    if (m_gradientType == CSSDeprecatedLinearGradient)
        return other.m_gradientType == m_gradientType
            && compareCSSValuePtr(m_firstX, other.m_firstX)
            && compareCSSValuePtr(m_firstY, other.m_firstY)
            && compareCSSValuePtr(m_secondX, other.m_secondX)
            && compareCSSValuePtr(m_secondY, other.m_secondY)
            && m_stops == other.m_stops;

    if (m_repeating != other.m_repeating)
        return false;

    if (m_angle)
        return compareCSSValuePtr(m_angle, other.m_angle) && m_stops == other.m_stops;

    if (other.m_angle)
        return false;

    bool equalXandY = false;
    if (m_firstX && m_firstY)
        equalXandY = compareCSSValuePtr(m_firstX, other.m_firstX) && compareCSSValuePtr(m_firstY, other.m_firstY);
    else if (m_firstX)
        equalXandY = compareCSSValuePtr(m_firstX, other.m_firstX) && !other.m_firstY;
    else if (m_firstY)
        equalXandY = compareCSSValuePtr(m_firstY, other.m_firstY) && !other.m_firstX;
    else
        equalXandY = !other.m_firstX && !other.m_firstY;

    return equalXandY && m_stops == other.m_stops;
}

void CSSLinearGradientValue::traceAfterDispatch(Visitor* visitor)
{
    visitor->trace(m_angle);
    CSSGradientValue::traceAfterDispatch(visitor);
}

String CSSRadialGradientValue::customCSSText() const
{
    StringBuilder result;

    if (m_gradientType == CSSDeprecatedRadialGradient) {
        result.appendLiteral("-webkit-gradient(radial, ");
        result.append(m_firstX->cssText());
        result.append(' ');
        result.append(m_firstY->cssText());
        result.appendLiteral(", ");
        result.append(m_firstRadius->cssText());
        result.appendLiteral(", ");
        result.append(m_secondX->cssText());
        result.append(' ');
        result.append(m_secondY->cssText());
        result.appendLiteral(", ");
        result.append(m_secondRadius->cssText());

        // FIXME: share?
        for (unsigned i = 0; i < m_stops.size(); i++) {
            const CSSGradientColorStop& stop = m_stops[i];
            result.appendLiteral(", ");
            if (stop.m_position->getDoubleValue(CSSPrimitiveValue::CSS_NUMBER) == 0) {
                result.appendLiteral("from(");
                result.append(stop.m_color->cssText());
                result.append(')');
            } else if (stop.m_position->getDoubleValue(CSSPrimitiveValue::CSS_NUMBER) == 1) {
                result.appendLiteral("to(");
                result.append(stop.m_color->cssText());
                result.append(')');
            } else {
                result.appendLiteral("color-stop(");
                result.append(String::number(stop.m_position->getDoubleValue(CSSPrimitiveValue::CSS_NUMBER)));
                result.appendLiteral(", ");
                result.append(stop.m_color->cssText());
                result.append(')');
            }
        }
    } else if (m_gradientType == CSSPrefixedRadialGradient) {
        if (m_repeating)
            result.appendLiteral("-webkit-repeating-radial-gradient(");
        else
            result.appendLiteral("-webkit-radial-gradient(");

        if (m_firstX && m_firstY) {
            result.append(m_firstX->cssText());
            result.append(' ');
            result.append(m_firstY->cssText());
        } else if (m_firstX)
            result.append(m_firstX->cssText());
         else if (m_firstY)
            result.append(m_firstY->cssText());
        else
            result.appendLiteral("center");

        if (m_shape || m_sizingBehavior) {
            result.appendLiteral(", ");
            if (m_shape) {
                result.append(m_shape->cssText());
                result.append(' ');
            } else
                result.appendLiteral("ellipse ");

            if (m_sizingBehavior)
                result.append(m_sizingBehavior->cssText());
            else
                result.appendLiteral("cover");

        } else if (m_endHorizontalSize && m_endVerticalSize) {
            result.appendLiteral(", ");
            result.append(m_endHorizontalSize->cssText());
            result.append(' ');
            result.append(m_endVerticalSize->cssText());
        }

        for (unsigned i = 0; i < m_stops.size(); i++) {
            const CSSGradientColorStop& stop = m_stops[i];
            result.appendLiteral(", ");
            result.append(stop.m_color->cssText());
            if (stop.m_position) {
                result.append(' ');
                result.append(stop.m_position->cssText());
            }
        }
    } else {
        if (m_repeating)
            result.appendLiteral("repeating-radial-gradient(");
        else
            result.appendLiteral("radial-gradient(");

        bool wroteSomething = false;

        // The only ambiguous case that needs an explicit shape to be provided
        // is when a sizing keyword is used (or all sizing is omitted).
        if (m_shape && m_shape->getValueID() != CSSValueEllipse && (m_sizingBehavior || (!m_sizingBehavior && !m_endHorizontalSize))) {
            result.appendLiteral("circle");
            wroteSomething = true;
        }

        if (m_sizingBehavior && m_sizingBehavior->getValueID() != CSSValueFarthestCorner) {
            if (wroteSomething)
                result.append(' ');
            result.append(m_sizingBehavior->cssText());
            wroteSomething = true;
        } else if (m_endHorizontalSize) {
            if (wroteSomething)
                result.append(' ');
            result.append(m_endHorizontalSize->cssText());
            if (m_endVerticalSize) {
                result.append(' ');
                result.append(m_endVerticalSize->cssText());
            }
            wroteSomething = true;
        }

        if (m_firstX || m_firstY) {
            if (wroteSomething)
                result.append(' ');
            result.appendLiteral("at ");
            if (m_firstX && m_firstY) {
                result.append(m_firstX->cssText());
                result.append(' ');
                result.append(m_firstY->cssText());
            } else if (m_firstX)
                result.append(m_firstX->cssText());
            else
                result.append(m_firstY->cssText());
            wroteSomething = true;
        }

        if (wroteSomething)
            result.appendLiteral(", ");

        for (unsigned i = 0; i < m_stops.size(); i++) {
            const CSSGradientColorStop& stop = m_stops[i];
            if (i)
                result.appendLiteral(", ");
            result.append(stop.m_color->cssText());
            if (stop.m_position) {
                result.append(' ');
                result.append(stop.m_position->cssText());
            }
        }

    }

    result.append(')');
    return result.toString();
}

float CSSRadialGradientValue::resolveRadius(CSSPrimitiveValue* radius, const CSSToLengthConversionData& conversionData, float* widthOrHeight)
{
    float result = 0;
    if (radius->isNumber()) // Can the radius be a percentage?
        result = radius->getFloatValue() * conversionData.zoom();
    else if (widthOrHeight && radius->isPercentage())
        result = *widthOrHeight * radius->getFloatValue() / 100;
    else
        result = radius->computeLength<float>(conversionData);

    return result;
}

static float distanceToClosestCorner(const FloatPoint& p, const FloatSize& size, FloatPoint& corner)
{
    FloatPoint topLeft;
    float topLeftDistance = FloatSize(p - topLeft).diagonalLength();

    FloatPoint topRight(size.width(), 0);
    float topRightDistance = FloatSize(p - topRight).diagonalLength();

    FloatPoint bottomLeft(0, size.height());
    float bottomLeftDistance = FloatSize(p - bottomLeft).diagonalLength();

    FloatPoint bottomRight(size.width(), size.height());
    float bottomRightDistance = FloatSize(p - bottomRight).diagonalLength();

    corner = topLeft;
    float minDistance = topLeftDistance;
    if (topRightDistance < minDistance) {
        minDistance = topRightDistance;
        corner = topRight;
    }

    if (bottomLeftDistance < minDistance) {
        minDistance = bottomLeftDistance;
        corner = bottomLeft;
    }

    if (bottomRightDistance < minDistance) {
        minDistance = bottomRightDistance;
        corner = bottomRight;
    }
    return minDistance;
}

static float distanceToFarthestCorner(const FloatPoint& p, const FloatSize& size, FloatPoint& corner)
{
    FloatPoint topLeft;
    float topLeftDistance = FloatSize(p - topLeft).diagonalLength();

    FloatPoint topRight(size.width(), 0);
    float topRightDistance = FloatSize(p - topRight).diagonalLength();

    FloatPoint bottomLeft(0, size.height());
    float bottomLeftDistance = FloatSize(p - bottomLeft).diagonalLength();

    FloatPoint bottomRight(size.width(), size.height());
    float bottomRightDistance = FloatSize(p - bottomRight).diagonalLength();

    corner = topLeft;
    float maxDistance = topLeftDistance;
    if (topRightDistance > maxDistance) {
        maxDistance = topRightDistance;
        corner = topRight;
    }

    if (bottomLeftDistance > maxDistance) {
        maxDistance = bottomLeftDistance;
        corner = bottomLeft;
    }

    if (bottomRightDistance > maxDistance) {
        maxDistance = bottomRightDistance;
        corner = bottomRight;
    }
    return maxDistance;
}

// Compute horizontal radius of ellipse with center at 0,0 which passes through p, and has
// width/height given by aspectRatio.
static inline float horizontalEllipseRadius(const FloatSize& p, float aspectRatio)
{
    // x^2/a^2 + y^2/b^2 = 1
    // a/b = aspectRatio, b = a/aspectRatio
    // a = sqrt(x^2 + y^2/(1/r^2))
    return sqrtf(p.width() * p.width() + (p.height() * p.height()) / (1 / (aspectRatio * aspectRatio)));
}

// FIXME: share code with the linear version
PassRefPtr<Gradient> CSSRadialGradientValue::createGradient(const CSSToLengthConversionData& conversionData, const IntSize& size)
{
    ASSERT(!size.isEmpty());

    FloatPoint firstPoint = computeEndPoint(m_firstX.get(), m_firstY.get(), conversionData, size);
    if (!m_firstX)
        firstPoint.setX(size.width() / 2);
    if (!m_firstY)
        firstPoint.setY(size.height() / 2);

    FloatPoint secondPoint = computeEndPoint(m_secondX.get(), m_secondY.get(), conversionData, size);
    if (!m_secondX)
        secondPoint.setX(size.width() / 2);
    if (!m_secondY)
        secondPoint.setY(size.height() / 2);

    float firstRadius = 0;
    if (m_firstRadius)
        firstRadius = resolveRadius(m_firstRadius.get(), conversionData);

    float secondRadius = 0;
    float aspectRatio = 1; // width / height.
    if (m_secondRadius)
        secondRadius = resolveRadius(m_secondRadius.get(), conversionData);
    else if (m_endHorizontalSize) {
        float width = size.width();
        float height = size.height();
        secondRadius = resolveRadius(m_endHorizontalSize.get(), conversionData, &width);
        if (m_endVerticalSize)
            aspectRatio = secondRadius / resolveRadius(m_endVerticalSize.get(), conversionData, &height);
        else
            aspectRatio = 1;
    } else {
        enum GradientShape { Circle, Ellipse };
        GradientShape shape = Ellipse;
        if ((m_shape && m_shape->getValueID() == CSSValueCircle)
            || (!m_shape && !m_sizingBehavior && m_endHorizontalSize && !m_endVerticalSize))
            shape = Circle;

        enum GradientFill { ClosestSide, ClosestCorner, FarthestSide, FarthestCorner };
        GradientFill fill = FarthestCorner;

        switch (m_sizingBehavior ? m_sizingBehavior->getValueID() : 0) {
        case CSSValueContain:
        case CSSValueClosestSide:
            fill = ClosestSide;
            break;
        case CSSValueClosestCorner:
            fill = ClosestCorner;
            break;
        case CSSValueFarthestSide:
            fill = FarthestSide;
            break;
        case CSSValueCover:
        case CSSValueFarthestCorner:
            fill = FarthestCorner;
            break;
        default:
            break;
        }

        // Now compute the end radii based on the second point, shape and fill.

        // Horizontal
        switch (fill) {
        case ClosestSide: {
            float xDist = std::min(secondPoint.x(), size.width() - secondPoint.x());
            float yDist = std::min(secondPoint.y(), size.height() - secondPoint.y());
            if (shape == Circle) {
                float smaller = std::min(xDist, yDist);
                xDist = smaller;
                yDist = smaller;
            }
            secondRadius = xDist;
            aspectRatio = xDist / yDist;
            break;
        }
        case FarthestSide: {
            float xDist = std::max(secondPoint.x(), size.width() - secondPoint.x());
            float yDist = std::max(secondPoint.y(), size.height() - secondPoint.y());
            if (shape == Circle) {
                float larger = std::max(xDist, yDist);
                xDist = larger;
                yDist = larger;
            }
            secondRadius = xDist;
            aspectRatio = xDist / yDist;
            break;
        }
        case ClosestCorner: {
            FloatPoint corner;
            float distance = distanceToClosestCorner(secondPoint, size, corner);
            if (shape == Circle)
                secondRadius = distance;
            else {
                // If <shape> is ellipse, the gradient-shape has the same ratio of width to height
                // that it would if closest-side or farthest-side were specified, as appropriate.
                float xDist = std::min(secondPoint.x(), size.width() - secondPoint.x());
                float yDist = std::min(secondPoint.y(), size.height() - secondPoint.y());

                secondRadius = horizontalEllipseRadius(corner - secondPoint, xDist / yDist);
                aspectRatio = xDist / yDist;
            }
            break;
        }

        case FarthestCorner: {
            FloatPoint corner;
            float distance = distanceToFarthestCorner(secondPoint, size, corner);
            if (shape == Circle)
                secondRadius = distance;
            else {
                // If <shape> is ellipse, the gradient-shape has the same ratio of width to height
                // that it would if closest-side or farthest-side were specified, as appropriate.
                float xDist = std::max(secondPoint.x(), size.width() - secondPoint.x());
                float yDist = std::max(secondPoint.y(), size.height() - secondPoint.y());

                secondRadius = horizontalEllipseRadius(corner - secondPoint, xDist / yDist);
                aspectRatio = xDist / yDist;
            }
            break;
        }
        }
    }

    RefPtr<Gradient> gradient = Gradient::create(firstPoint, firstRadius, secondPoint, secondRadius, aspectRatio);

    gradient->setDrawsInPMColorSpace(true);

    // addStops() only uses maxExtent for repeating gradients.
    float maxExtent = 0;
    if (m_repeating) {
        FloatPoint corner;
        maxExtent = distanceToFarthestCorner(secondPoint, size, corner);
    }

    // Now add the stops.
    addStops(gradient.get(), conversionData, maxExtent);

    return gradient.release();
}

bool CSSRadialGradientValue::equals(const CSSRadialGradientValue& other) const
{
    if (m_gradientType == CSSDeprecatedRadialGradient)
        return other.m_gradientType == m_gradientType
            && compareCSSValuePtr(m_firstX, other.m_firstX)
            && compareCSSValuePtr(m_firstY, other.m_firstY)
            && compareCSSValuePtr(m_secondX, other.m_secondX)
            && compareCSSValuePtr(m_secondY, other.m_secondY)
            && compareCSSValuePtr(m_firstRadius, other.m_firstRadius)
            && compareCSSValuePtr(m_secondRadius, other.m_secondRadius)
            && m_stops == other.m_stops;

    if (m_repeating != other.m_repeating)
        return false;

    bool equalXandY = false;
    if (m_firstX && m_firstY)
        equalXandY = compareCSSValuePtr(m_firstX, other.m_firstX) && compareCSSValuePtr(m_firstY, other.m_firstY);
    else if (m_firstX)
        equalXandY = compareCSSValuePtr(m_firstX, other.m_firstX) && !other.m_firstY;
    else if (m_firstY)
        equalXandY = compareCSSValuePtr(m_firstY, other.m_firstY) && !other.m_firstX;
    else
        equalXandY = !other.m_firstX && !other.m_firstY;

    if (!equalXandY)
        return false;

    bool equalShape = true;
    bool equalSizingBehavior = true;
    bool equalHorizontalAndVerticalSize = true;

    if (m_shape)
        equalShape = compareCSSValuePtr(m_shape, other.m_shape);
    else if (m_sizingBehavior)
        equalSizingBehavior = compareCSSValuePtr(m_sizingBehavior, other.m_sizingBehavior);
    else if (m_endHorizontalSize && m_endVerticalSize)
        equalHorizontalAndVerticalSize = compareCSSValuePtr(m_endHorizontalSize, other.m_endHorizontalSize) && compareCSSValuePtr(m_endVerticalSize, other.m_endVerticalSize);
    else {
        equalShape = !other.m_shape;
        equalSizingBehavior = !other.m_sizingBehavior;
        equalHorizontalAndVerticalSize = !other.m_endHorizontalSize && !other.m_endVerticalSize;
    }
    return equalShape && equalSizingBehavior && equalHorizontalAndVerticalSize && m_stops == other.m_stops;
}

void CSSRadialGradientValue::traceAfterDispatch(Visitor* visitor)
{
    visitor->trace(m_firstRadius);
    visitor->trace(m_secondRadius);
    visitor->trace(m_shape);
    visitor->trace(m_sizingBehavior);
    visitor->trace(m_endHorizontalSize);
    visitor->trace(m_endVerticalSize);
    CSSGradientValue::traceAfterDispatch(visitor);
}

} // namespace blink
