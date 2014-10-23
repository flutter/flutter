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
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER "AS IS" AND ANY
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
#include "core/rendering/style/BasicShapes.h"

#include "core/css/BasicShapeFunctions.h"
#include "platform/CalculationValue.h"
#include "platform/LengthFunctions.h"
#include "platform/geometry/FloatRect.h"
#include "platform/graphics/Path.h"

namespace blink {

bool BasicShape::canBlend(const BasicShape* other) const
{
    // FIXME: Support animations between different shapes in the future.
    if (!other || !isSameType(*other))
        return false;

    // Just polygons with same number of vertices can be animated.
    if (type() == BasicShape::BasicShapePolygonType
        && (toBasicShapePolygon(this)->values().size() != toBasicShapePolygon(other)->values().size()
        || toBasicShapePolygon(this)->windRule() != toBasicShapePolygon(other)->windRule()))
        return false;

    // Circles with keywords for radii or center coordinates cannot be animated.
    if (type() == BasicShape::BasicShapeCircleType) {
        if (!toBasicShapeCircle(this)->radius().canBlend(toBasicShapeCircle(other)->radius()))
            return false;
    }

    // Ellipses with keywords for radii or center coordinates cannot be animated.
    if (type() != BasicShape::BasicShapeEllipseType)
        return true;

    return (toBasicShapeEllipse(this)->radiusX().canBlend(toBasicShapeEllipse(other)->radiusX())
        && toBasicShapeEllipse(this)->radiusY().canBlend(toBasicShapeEllipse(other)->radiusY()));
}

bool BasicShapeCircle::operator==(const BasicShape& o) const
{
    if (!isSameType(o))
        return false;
    const BasicShapeCircle& other = toBasicShapeCircle(o);
    return m_centerX == other.m_centerX && m_centerY == other.m_centerY && m_radius == other.m_radius;
}

float BasicShapeCircle::floatValueForRadiusInBox(FloatSize boxSize) const
{
    if (m_radius.type() == BasicShapeRadius::Value)
        return floatValueForLength(m_radius.value(), hypotf(boxSize.width(), boxSize.height()) / sqrtf(2));

    FloatPoint center = floatPointForCenterCoordinate(m_centerX, m_centerY, boxSize);

    if (m_radius.type() == BasicShapeRadius::ClosestSide)
        return std::min(std::min(center.x(), boxSize.width() - center.x()), std::min(center.y(), boxSize.height() - center.y()));

    // If radius.type() == BasicShapeRadius::FarthestSide.
    return std::max(std::max(center.x(), boxSize.width() - center.x()), std::max(center.y(), boxSize.height() - center.y()));
}

void BasicShapeCircle::path(Path& path, const FloatRect& boundingBox)
{
    ASSERT(path.isEmpty());
    FloatPoint center = floatPointForCenterCoordinate(m_centerX, m_centerY, boundingBox.size());
    float radius = floatValueForRadiusInBox(boundingBox.size());
    path.addEllipse(FloatRect(
        center.x() - radius + boundingBox.x(),
        center.y() - radius + boundingBox.y(),
        radius * 2,
        radius * 2
    ));
}

PassRefPtr<BasicShape> BasicShapeCircle::blend(const BasicShape* other, double progress) const
{
    ASSERT(type() == other->type());
    const BasicShapeCircle* o = toBasicShapeCircle(other);
    RefPtr<BasicShapeCircle> result =  BasicShapeCircle::create();

    result->setCenterX(m_centerX.blend(o->centerX(), progress));
    result->setCenterY(m_centerY.blend(o->centerY(), progress));
    result->setRadius(m_radius.blend(o->radius(), progress));
    return result.release();
}

bool BasicShapeEllipse::operator==(const BasicShape& o) const
{
    if (!isSameType(o))
        return false;
    const BasicShapeEllipse& other = toBasicShapeEllipse(o);
    return m_centerX == other.m_centerX && m_centerY == other.m_centerY && m_radiusX == other.m_radiusX && m_radiusY == other.m_radiusY;
}

float BasicShapeEllipse::floatValueForRadiusInBox(const BasicShapeRadius& radius, float center, float boxWidthOrHeight) const
{
    if (radius.type() == BasicShapeRadius::Value)
        return floatValueForLength(radius.value(), boxWidthOrHeight);

    if (radius.type() == BasicShapeRadius::ClosestSide)
        return std::min(center, boxWidthOrHeight - center);

    ASSERT(radius.type() == BasicShapeRadius::FarthestSide);
    return std::max(center, boxWidthOrHeight - center);
}

void BasicShapeEllipse::path(Path& path, const FloatRect& boundingBox)
{
    ASSERT(path.isEmpty());
    FloatPoint center = floatPointForCenterCoordinate(m_centerX, m_centerY, boundingBox.size());
    float radiusX = floatValueForRadiusInBox(m_radiusX, center.x(), boundingBox.width());
    float radiusY = floatValueForRadiusInBox(m_radiusY, center.y(), boundingBox.height());
    path.addEllipse(FloatRect(
        center.x() - radiusX + boundingBox.x(),
        center.y() - radiusY + boundingBox.y(),
        radiusX * 2,
        radiusY * 2
    ));
}

PassRefPtr<BasicShape> BasicShapeEllipse::blend(const BasicShape* other, double progress) const
{
    ASSERT(type() == other->type());
    const BasicShapeEllipse* o = toBasicShapeEllipse(other);
    RefPtr<BasicShapeEllipse> result =  BasicShapeEllipse::create();

    if (m_radiusX.type() != BasicShapeRadius::Value || o->radiusX().type() != BasicShapeRadius::Value
        || m_radiusY.type() != BasicShapeRadius::Value || o->radiusY().type() != BasicShapeRadius::Value) {
        result->setCenterX(o->centerX());
        result->setCenterY(o->centerY());
        result->setRadiusX(o->radiusX());
        result->setRadiusY(o->radiusY());
        return result;
    }

    result->setCenterX(m_centerX.blend(o->centerX(), progress));
    result->setCenterY(m_centerY.blend(o->centerY(), progress));
    result->setRadiusX(m_radiusX.blend(o->radiusX(), progress));
    result->setRadiusY(m_radiusY.blend(o->radiusY(), progress));
    return result.release();
}

void BasicShapePolygon::path(Path& path, const FloatRect& boundingBox)
{
    ASSERT(path.isEmpty());
    ASSERT(!(m_values.size() % 2));
    size_t length = m_values.size();

    if (!length)
        return;

    path.moveTo(FloatPoint(floatValueForLength(m_values.at(0), boundingBox.width()) + boundingBox.x(),
        floatValueForLength(m_values.at(1), boundingBox.height()) + boundingBox.y()));
    for (size_t i = 2; i < length; i = i + 2) {
        path.addLineTo(FloatPoint(floatValueForLength(m_values.at(i), boundingBox.width()) + boundingBox.x(),
            floatValueForLength(m_values.at(i + 1), boundingBox.height()) + boundingBox.y()));
    }
    path.closeSubpath();
}

PassRefPtr<BasicShape> BasicShapePolygon::blend(const BasicShape* other, double progress) const
{
    ASSERT(other && isSameType(*other));

    const BasicShapePolygon* o = toBasicShapePolygon(other);
    ASSERT(m_values.size() == o->values().size());
    ASSERT(!(m_values.size() % 2));

    size_t length = m_values.size();
    RefPtr<BasicShapePolygon> result = BasicShapePolygon::create();
    if (!length)
        return result.release();

    result->setWindRule(o->windRule());

    for (size_t i = 0; i < length; i = i + 2) {
        result->appendPoint(m_values.at(i).blend(o->values().at(i), progress, ValueRangeAll),
            m_values.at(i + 1).blend(o->values().at(i + 1), progress, ValueRangeAll));
    }

    return result.release();
}

bool BasicShapePolygon::operator==(const BasicShape& o) const
{
    if (!isSameType(o))
        return false;
    const BasicShapePolygon& other = toBasicShapePolygon(o);
    return m_windRule == other.m_windRule && m_values == other.m_values;
}

static FloatSize floatSizeForLengthSize(const LengthSize& lengthSize, const FloatRect& boundingBox)
{
    return FloatSize(floatValueForLength(lengthSize.width(), boundingBox.width()),
        floatValueForLength(lengthSize.height(), boundingBox.height()));
}

void BasicShapeInset::path(Path& path, const FloatRect& boundingBox)
{
    ASSERT(path.isEmpty());
    float left = floatValueForLength(m_left, boundingBox.width());
    float top = floatValueForLength(m_top, boundingBox.height());
    path.addRoundedRect(
        FloatRect(
            left + boundingBox.x(),
            top + boundingBox.y(),
            std::max<float>(boundingBox.width() - left - floatValueForLength(m_right, boundingBox.width()), 0),
            std::max<float>(boundingBox.height() - top - floatValueForLength(m_bottom, boundingBox.height()), 0)
        ),
        floatSizeForLengthSize(m_topLeftRadius, boundingBox),
        floatSizeForLengthSize(m_topRightRadius, boundingBox),
        floatSizeForLengthSize(m_bottomLeftRadius, boundingBox),
        floatSizeForLengthSize(m_bottomRightRadius, boundingBox)
    );
}

PassRefPtr<BasicShape> BasicShapeInset::blend(const BasicShape* other, double) const
{
    ASSERT(type() == other->type());
    // FIXME: Implement blend for BasicShapeInset.
    return nullptr;
}

bool BasicShapeInset::operator==(const BasicShape& o) const
{
    if (!isSameType(o))
        return false;
    const BasicShapeInset& other = toBasicShapeInset(o);
    return m_right == other.m_right
        && m_top == other.m_top
        && m_bottom == other.m_bottom
        && m_left == other.m_left
        && m_topLeftRadius == other.m_topLeftRadius
        && m_topRightRadius == other.m_topRightRadius
        && m_bottomRightRadius == other.m_bottomRightRadius
        && m_bottomLeftRadius == other.m_bottomLeftRadius;
}

}
