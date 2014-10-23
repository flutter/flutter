/*
 * Copyright (C) 2011 Adobe Systems Incorporated. All rights reserved.
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
#include "core/css/CSSBasicShapes.h"

#include "core/css/CSSValuePool.h"
#include "core/css/Pair.h"
#include "platform/Length.h"
#include "wtf/text/StringBuilder.h"

using namespace WTF;

namespace blink {

DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(CSSBasicShape)

static String buildCircleString(const String& radius, const String& centerX, const String& centerY, const String& box)
{
    char at[] = "at";
    char separator[] = " ";
    StringBuilder result;
    result.appendLiteral("circle(");
    if (!radius.isNull())
        result.append(radius);

    if (!centerX.isNull() || !centerY.isNull()) {
        if (!radius.isNull())
            result.appendLiteral(separator);
        result.append(at);
        result.appendLiteral(separator);
        result.append(centerX);
        result.appendLiteral(separator);
        result.append(centerY);
    }
    result.append(')');
    if (box.length()) {
        result.appendLiteral(separator);
        result.append(box);
    }
    return result.toString();
}

static String serializePositionOffset(const Pair& offset, const Pair& other)
{
    if ((offset.first()->getValueID() == CSSValueLeft && other.first()->getValueID() == CSSValueTop)
        || (offset.first()->getValueID() == CSSValueTop && other.first()->getValueID() == CSSValueLeft))
        return offset.second()->cssText();
    return offset.cssText();
}

static PassRefPtrWillBeRawPtr<CSSPrimitiveValue> buildSerializablePositionOffset(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> offset, CSSValueID defaultSide)
{
    CSSValueID side = defaultSide;
    RefPtrWillBeRawPtr<CSSPrimitiveValue> amount = nullptr;

    if (!offset) {
        side = CSSValueCenter;
    } else if (offset->isValueID()) {
        side = offset->getValueID();
    } else if (Pair* pair = offset->getPairValue()) {
        side = pair->first()->getValueID();
        amount = pair->second();
    } else {
        amount = offset;
    }

    if (side == CSSValueCenter) {
        side = defaultSide;
        amount = cssValuePool().createValue(50, CSSPrimitiveValue::CSS_PERCENTAGE);
    } else if ((side == CSSValueRight || side == CSSValueBottom)
        && amount->isPercentage()) {
        side = defaultSide;
        amount = cssValuePool().createValue(100 - amount->getFloatValue(), CSSPrimitiveValue::CSS_PERCENTAGE);
    } else if (amount->isLength() && !amount->getFloatValue()) {
        if (side == CSSValueRight || side == CSSValueBottom)
            amount = cssValuePool().createValue(100, CSSPrimitiveValue::CSS_PERCENTAGE);
        else
            amount = cssValuePool().createValue(0, CSSPrimitiveValue::CSS_PERCENTAGE);
        side = defaultSide;
    }

    return cssValuePool().createValue(Pair::create(cssValuePool().createValue(side), amount.release(), Pair::KeepIdenticalValues));
}

String CSSBasicShapeCircle::cssText() const
{
    RefPtrWillBeRawPtr<CSSPrimitiveValue> normalizedCX = buildSerializablePositionOffset(m_centerX, CSSValueLeft);
    RefPtrWillBeRawPtr<CSSPrimitiveValue> normalizedCY = buildSerializablePositionOffset(m_centerY, CSSValueTop);

    String radius;
    if (m_radius && m_radius->getValueID() != CSSValueClosestSide)
        radius = m_radius->cssText();

    return buildCircleString(radius,
        serializePositionOffset(*normalizedCX->getPairValue(), *normalizedCY->getPairValue()),
        serializePositionOffset(*normalizedCY->getPairValue(), *normalizedCX->getPairValue()),
        m_referenceBox ? m_referenceBox->cssText() : String());
}

bool CSSBasicShapeCircle::equals(const CSSBasicShape& shape) const
{
    if (shape.type() != CSSBasicShapeCircleType)
        return false;

    const CSSBasicShapeCircle& other = static_cast<const CSSBasicShapeCircle&>(shape);
    return compareCSSValuePtr(m_centerX, other.m_centerX)
        && compareCSSValuePtr(m_centerY, other.m_centerY)
        && compareCSSValuePtr(m_radius, other.m_radius)
        && compareCSSValuePtr(m_referenceBox, other.m_referenceBox);
}

void CSSBasicShapeCircle::trace(Visitor* visitor)
{
    visitor->trace(m_centerX);
    visitor->trace(m_centerY);
    visitor->trace(m_radius);
    CSSBasicShape::trace(visitor);
}

static String buildEllipseString(const String& radiusX, const String& radiusY, const String& centerX, const String& centerY, const String& box)
{
    char at[] = "at";
    char separator[] = " ";
    StringBuilder result;
    result.appendLiteral("ellipse(");
    bool needsSeparator = false;
    if (!radiusX.isNull()) {
        result.append(radiusX);
        needsSeparator = true;
    }
    if (!radiusY.isNull()) {
        if (needsSeparator)
            result.appendLiteral(separator);
        result.append(radiusY);
        needsSeparator = true;
    }

    if (!centerX.isNull() || !centerY.isNull()) {
        if (needsSeparator)
            result.appendLiteral(separator);
        result.appendLiteral(at);
        result.appendLiteral(separator);
        result.append(centerX);
        result.appendLiteral(separator);
        result.append(centerY);
    }
    result.append(')');
    if (box.length()) {
        result.appendLiteral(separator);
        result.append(box);
    }
    return result.toString();
}

String CSSBasicShapeEllipse::cssText() const
{
    RefPtrWillBeRawPtr<CSSPrimitiveValue> normalizedCX = buildSerializablePositionOffset(m_centerX, CSSValueLeft);
    RefPtrWillBeRawPtr<CSSPrimitiveValue> normalizedCY = buildSerializablePositionOffset(m_centerY, CSSValueTop);

    String radiusX;
    String radiusY;
    if (m_radiusX) {
        bool shouldSerializeRadiusXValue = m_radiusX->getValueID() != CSSValueClosestSide;
        bool shouldSerializeRadiusYValue = false;

        if (m_radiusY) {
            shouldSerializeRadiusYValue = m_radiusY->getValueID() != CSSValueClosestSide;
            if (shouldSerializeRadiusYValue)
                radiusY = m_radiusY->cssText();
        }
        if (shouldSerializeRadiusXValue || (!shouldSerializeRadiusXValue && shouldSerializeRadiusYValue))
            radiusX = m_radiusX->cssText();
    }

    return buildEllipseString(radiusX, radiusY,
        serializePositionOffset(*normalizedCX->getPairValue(), *normalizedCY->getPairValue()),
        serializePositionOffset(*normalizedCY->getPairValue(), *normalizedCX->getPairValue()),
        m_referenceBox ? m_referenceBox->cssText() : String());
}

bool CSSBasicShapeEllipse::equals(const CSSBasicShape& shape) const
{
    if (shape.type() != CSSBasicShapeEllipseType)
        return false;

    const CSSBasicShapeEllipse& other = static_cast<const CSSBasicShapeEllipse&>(shape);
    return compareCSSValuePtr(m_centerX, other.m_centerX)
        && compareCSSValuePtr(m_centerY, other.m_centerY)
        && compareCSSValuePtr(m_radiusX, other.m_radiusX)
        && compareCSSValuePtr(m_radiusY, other.m_radiusY)
        && compareCSSValuePtr(m_referenceBox, other.m_referenceBox);
}

void CSSBasicShapeEllipse::trace(Visitor* visitor)
{
    visitor->trace(m_centerX);
    visitor->trace(m_centerY);
    visitor->trace(m_radiusX);
    visitor->trace(m_radiusY);
    CSSBasicShape::trace(visitor);
}

static String buildPolygonString(const WindRule& windRule, const Vector<String>& points, const String& box)
{
    ASSERT(!(points.size() % 2));

    StringBuilder result;
    const char evenOddOpening[] = "polygon(evenodd, ";
    const char nonZeroOpening[] = "polygon(";
    const char commaSeparator[] = ", ";
    COMPILE_ASSERT(sizeof(evenOddOpening) > sizeof(nonZeroOpening), polygon_string_openings_have_same_length);

    // Compute the required capacity in advance to reduce allocations.
    size_t length = sizeof(evenOddOpening) - 1;
    for (size_t i = 0; i < points.size(); i += 2) {
        if (i)
            length += (sizeof(commaSeparator) - 1);
        // add length of two strings, plus one for the space separator.
        length += points[i].length() + 1 + points[i + 1].length();
    }
    if (!box.isEmpty())
        length += box.length() + 1;
    result.reserveCapacity(length);

    if (windRule == RULE_EVENODD)
        result.appendLiteral(evenOddOpening);
    else
        result.appendLiteral(nonZeroOpening);

    for (size_t i = 0; i < points.size(); i += 2) {
        if (i)
            result.appendLiteral(commaSeparator);
        result.append(points[i]);
        result.append(' ');
        result.append(points[i + 1]);
    }

    result.append(')');

    if (!box.isEmpty()) {
        result.append(' ');
        result.append(box);
    }

    return result.toString();
}

String CSSBasicShapePolygon::cssText() const
{
    Vector<String> points;
    points.reserveInitialCapacity(m_values.size());

    for (size_t i = 0; i < m_values.size(); ++i)
        points.append(m_values.at(i)->cssText());

    return buildPolygonString(m_windRule, points, m_referenceBox ? m_referenceBox->cssText() : String());
}

bool CSSBasicShapePolygon::equals(const CSSBasicShape& shape) const
{
    if (shape.type() != CSSBasicShapePolygonType)
        return false;

    const CSSBasicShapePolygon& rhs = static_cast<const CSSBasicShapePolygon&>(shape);

    if (!compareCSSValuePtr(m_referenceBox, rhs.m_referenceBox))
        return false;

    return compareCSSValueVector(m_values, rhs.m_values);
}

void CSSBasicShapePolygon::trace(Visitor* visitor)
{
    visitor->trace(m_values);
    CSSBasicShape::trace(visitor);
}

static bool buildInsetRadii(Vector<String> &radii, const String& topLeftRadius, const String& topRightRadius, const String& bottomRightRadius, const String& bottomLeftRadius)
{
    bool showBottomLeft = topRightRadius != bottomLeftRadius;
    bool showBottomRight = showBottomLeft || (bottomRightRadius != topLeftRadius);
    bool showTopRight = showBottomRight || (topRightRadius != topLeftRadius);

    radii.append(topLeftRadius);
    if (showTopRight)
        radii.append(topRightRadius);
    if (showBottomRight)
        radii.append(bottomRightRadius);
    if (showBottomLeft)
        radii.append(bottomLeftRadius);

    return radii.size() == 1 && radii[0] == "0px";
}

static String buildInsetString(const String& top, const String& right, const String& bottom, const String& left,
    const String& topLeftRadiusWidth, const String& topLeftRadiusHeight,
    const String& topRightRadiusWidth, const String& topRightRadiusHeight,
    const String& bottomRightRadiusWidth, const String& bottomRightRadiusHeight,
    const String& bottomLeftRadiusWidth, const String& bottomLeftRadiusHeight)
{
    char opening[] = "inset(";
    char separator[] = " ";
    char cornersSeparator[] = "round";
    StringBuilder result;
    result.appendLiteral(opening);
    result.append(top);
    bool showLeftArg = !left.isNull() && left != right;
    bool showBottomArg = !bottom.isNull() && (bottom != top || showLeftArg);
    bool showRightArg = !right.isNull() && (right != top || showBottomArg);
    if (showRightArg) {
        result.appendLiteral(separator);
        result.append(right);
    }
    if (showBottomArg) {
        result.appendLiteral(separator);
        result.append(bottom);
    }
    if (showLeftArg) {
        result.appendLiteral(separator);
        result.append(left);
    }

    if (!topLeftRadiusWidth.isNull() && !topLeftRadiusHeight.isNull()) {
        Vector<String> horizontalRadii;
        bool areDefaultCornerRadii = buildInsetRadii(horizontalRadii, topLeftRadiusWidth, topRightRadiusWidth, bottomRightRadiusWidth, bottomLeftRadiusWidth);

        Vector<String> verticalRadii;
        areDefaultCornerRadii &= buildInsetRadii(verticalRadii, topLeftRadiusHeight, topRightRadiusHeight, bottomRightRadiusHeight, bottomLeftRadiusHeight);

        if (!areDefaultCornerRadii) {
            result.appendLiteral(separator);
            result.appendLiteral(cornersSeparator);

            for (size_t i = 0; i < horizontalRadii.size(); ++i) {
                result.appendLiteral(separator);
                result.append(horizontalRadii[i]);
            }
            if (horizontalRadii != verticalRadii) {
                result.appendLiteral(separator);
                result.appendLiteral("/");

                for (size_t i = 0; i < verticalRadii.size(); ++i) {
                    result.appendLiteral(separator);
                    result.append(verticalRadii[i]);
                }
            }
        }
    }
    result.append(')');

    return result.toString();
}

static inline void updateCornerRadiusWidthAndHeight(CSSPrimitiveValue* corner, String& width, String& height)
{
    if (!corner)
        return;

    Pair* radius = corner->getPairValue();
    width = radius->first() ? radius->first()->cssText() : String("0");
    if (radius->second())
        height = radius->second()->cssText();
}

String CSSBasicShapeInset::cssText() const
{
    String topLeftRadiusWidth;
    String topLeftRadiusHeight;
    String topRightRadiusWidth;
    String topRightRadiusHeight;
    String bottomRightRadiusWidth;
    String bottomRightRadiusHeight;
    String bottomLeftRadiusWidth;
    String bottomLeftRadiusHeight;

    updateCornerRadiusWidthAndHeight(topLeftRadius(), topLeftRadiusWidth, topLeftRadiusHeight);
    updateCornerRadiusWidthAndHeight(topRightRadius(), topRightRadiusWidth, topRightRadiusHeight);
    updateCornerRadiusWidthAndHeight(bottomRightRadius(), bottomRightRadiusWidth, bottomRightRadiusHeight);
    updateCornerRadiusWidthAndHeight(bottomLeftRadius(), bottomLeftRadiusWidth, bottomLeftRadiusHeight);

    return buildInsetString(m_top ? m_top->cssText() : String(),
        m_right ? m_right->cssText() : String(),
        m_bottom ? m_bottom->cssText() : String(),
        m_left ? m_left->cssText() : String(),
        topLeftRadiusWidth,
        topLeftRadiusHeight,
        topRightRadiusWidth,
        topRightRadiusHeight,
        bottomRightRadiusWidth,
        bottomRightRadiusHeight,
        bottomLeftRadiusWidth,
        bottomLeftRadiusHeight);
}

bool CSSBasicShapeInset::equals(const CSSBasicShape& shape) const
{
    if (shape.type() != CSSBasicShapeInsetType)
        return false;

    const CSSBasicShapeInset& other = static_cast<const CSSBasicShapeInset&>(shape);
    return compareCSSValuePtr(m_top, other.m_top)
        && compareCSSValuePtr(m_right, other.m_right)
        && compareCSSValuePtr(m_bottom, other.m_bottom)
        && compareCSSValuePtr(m_left, other.m_left)
        && compareCSSValuePtr(m_topLeftRadius, other.m_topLeftRadius)
        && compareCSSValuePtr(m_topRightRadius, other.m_topRightRadius)
        && compareCSSValuePtr(m_bottomRightRadius, other.m_bottomRightRadius)
        && compareCSSValuePtr(m_bottomLeftRadius, other.m_bottomLeftRadius);
}

void CSSBasicShapeInset::trace(Visitor* visitor)
{
    visitor->trace(m_top);
    visitor->trace(m_right);
    visitor->trace(m_bottom);
    visitor->trace(m_left);
    visitor->trace(m_topLeftRadius);
    visitor->trace(m_topRightRadius);
    visitor->trace(m_bottomRightRadius);
    visitor->trace(m_bottomLeftRadius);
    CSSBasicShape::trace(visitor);
}

} // namespace blink

