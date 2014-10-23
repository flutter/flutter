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
#include "core/css/BasicShapeFunctions.h"

#include "core/css/CSSBasicShapes.h"
#include "core/css/CSSPrimitiveValueMappings.h"
#include "core/css/CSSValuePool.h"
#include "core/css/Pair.h"
#include "core/css/resolver/StyleResolverState.h"
#include "core/rendering/style/BasicShapes.h"
#include "core/rendering/style/RenderStyle.h"

namespace blink {

static PassRefPtrWillBeRawPtr<CSSPrimitiveValue> valueForCenterCoordinate(CSSValuePool& pool, const RenderStyle& style, const BasicShapeCenterCoordinate& center, EBoxOrient orientation)
{
    if (center.direction() == BasicShapeCenterCoordinate::TopLeft)
        return pool.createValue(center.length(), style);

    CSSValueID keyword = orientation == HORIZONTAL ? CSSValueRight : CSSValueBottom;

    return pool.createValue(Pair::create(pool.createIdentifierValue(keyword), pool.createValue(center.length(), style), Pair::DropIdenticalValues));
}

static PassRefPtrWillBeRawPtr<CSSPrimitiveValue> basicShapeRadiusToCSSValue(CSSValuePool& pool, const RenderStyle& style, const BasicShapeRadius& radius)
{
    switch (radius.type()) {
    case BasicShapeRadius::Value:
        return pool.createValue(radius.value(), style);
    case BasicShapeRadius::ClosestSide:
        return pool.createIdentifierValue(CSSValueClosestSide);
    case BasicShapeRadius::FarthestSide:
        return pool.createIdentifierValue(CSSValueFarthestSide);
    }

    ASSERT_NOT_REACHED();
    return nullptr;
}

PassRefPtrWillBeRawPtr<CSSValue> valueForBasicShape(const RenderStyle& style, const BasicShape* basicShape)
{
    CSSValuePool& pool = cssValuePool();

    RefPtrWillBeRawPtr<CSSBasicShape> basicShapeValue = nullptr;
    switch (basicShape->type()) {
    case BasicShape::BasicShapeCircleType: {
        const BasicShapeCircle* circle = toBasicShapeCircle(basicShape);
        RefPtrWillBeRawPtr<CSSBasicShapeCircle> circleValue = CSSBasicShapeCircle::create();

        circleValue->setCenterX(valueForCenterCoordinate(pool, style, circle->centerX(), HORIZONTAL));
        circleValue->setCenterY(valueForCenterCoordinate(pool, style, circle->centerY(), VERTICAL));
        circleValue->setRadius(basicShapeRadiusToCSSValue(pool, style, circle->radius()));
        basicShapeValue = circleValue.release();
        break;
    }
    case BasicShape::BasicShapeEllipseType: {
        const BasicShapeEllipse* ellipse = toBasicShapeEllipse(basicShape);
        RefPtrWillBeRawPtr<CSSBasicShapeEllipse> ellipseValue = CSSBasicShapeEllipse::create();

        ellipseValue->setCenterX(valueForCenterCoordinate(pool, style, ellipse->centerX(), HORIZONTAL));
        ellipseValue->setCenterY(valueForCenterCoordinate(pool, style, ellipse->centerY(), VERTICAL));
        ellipseValue->setRadiusX(basicShapeRadiusToCSSValue(pool, style, ellipse->radiusX()));
        ellipseValue->setRadiusY(basicShapeRadiusToCSSValue(pool, style, ellipse->radiusY()));
        basicShapeValue = ellipseValue.release();
        break;
    }
    case BasicShape::BasicShapePolygonType: {
        const BasicShapePolygon* polygon = toBasicShapePolygon(basicShape);
        RefPtrWillBeRawPtr<CSSBasicShapePolygon> polygonValue = CSSBasicShapePolygon::create();

        polygonValue->setWindRule(polygon->windRule());
        const Vector<Length>& values = polygon->values();
        for (unsigned i = 0; i < values.size(); i += 2)
            polygonValue->appendPoint(pool.createValue(values.at(i), style), pool.createValue(values.at(i + 1), style));

        basicShapeValue = polygonValue.release();
        break;
    }
    case BasicShape::BasicShapeInsetType: {
        const BasicShapeInset* inset = toBasicShapeInset(basicShape);
        RefPtrWillBeRawPtr<CSSBasicShapeInset> insetValue = CSSBasicShapeInset::create();

        insetValue->setTop(pool.createValue(inset->top(), style));
        insetValue->setRight(pool.createValue(inset->right(), style));
        insetValue->setBottom(pool.createValue(inset->bottom(), style));
        insetValue->setLeft(pool.createValue(inset->left(), style));

        insetValue->setTopLeftRadius(CSSPrimitiveValue::create(inset->topLeftRadius(), style));
        insetValue->setTopRightRadius(CSSPrimitiveValue::create(inset->topRightRadius(), style));
        insetValue->setBottomRightRadius(CSSPrimitiveValue::create(inset->bottomRightRadius(), style));
        insetValue->setBottomLeftRadius(CSSPrimitiveValue::create(inset->bottomLeftRadius(), style));

        basicShapeValue = insetValue.release();
        break;
    }
    default:
        break;
    }

    return pool.createValue(basicShapeValue.release());
}

static Length convertToLength(const StyleResolverState& state, CSSPrimitiveValue* value)
{
    if (!value)
        return Length(0, Fixed);
    return value->convertToLength<FixedConversion | PercentConversion>(state.cssToLengthConversionData());
}

static LengthSize convertToLengthSize(const StyleResolverState& state, CSSPrimitiveValue* value)
{
    if (!value)
        return LengthSize(Length(0, Fixed), Length(0, Fixed));

    Pair* pair = value->getPairValue();
    return LengthSize(convertToLength(state, pair->first()), convertToLength(state, pair->second()));
}

static BasicShapeCenterCoordinate convertToCenterCoordinate(const StyleResolverState& state, CSSPrimitiveValue* value)
{
    BasicShapeCenterCoordinate::Direction direction;
    Length offset = Length(0, Fixed);

    CSSValueID keyword = CSSValueTop;
    if (!value) {
        keyword = CSSValueCenter;
    } else if (value->isValueID()) {
        keyword = value->getValueID();
    } else if (Pair* pair = value->getPairValue()) {
        keyword = pair->first()->getValueID();
        offset = convertToLength(state, pair->second());
    } else {
        offset = convertToLength(state, value);
    }

    switch (keyword) {
    case CSSValueTop:
    case CSSValueLeft:
        direction = BasicShapeCenterCoordinate::TopLeft;
        break;
    case CSSValueRight:
    case CSSValueBottom:
        direction = BasicShapeCenterCoordinate::BottomRight;
        break;
    case CSSValueCenter:
        direction = BasicShapeCenterCoordinate::TopLeft;
        offset = Length(50, Percent);
        break;
    default:
        ASSERT_NOT_REACHED();
        direction = BasicShapeCenterCoordinate::TopLeft;
        break;
    }

    return BasicShapeCenterCoordinate(direction, offset);
}

static BasicShapeRadius cssValueToBasicShapeRadius(const StyleResolverState& state, PassRefPtrWillBeRawPtr<CSSPrimitiveValue> radius)
{
    if (!radius)
        return BasicShapeRadius(BasicShapeRadius::ClosestSide);

    if (radius->isValueID()) {
        switch (radius->getValueID()) {
        case CSSValueClosestSide:
            return BasicShapeRadius(BasicShapeRadius::ClosestSide);
        case CSSValueFarthestSide:
            return BasicShapeRadius(BasicShapeRadius::FarthestSide);
        default:
            ASSERT_NOT_REACHED();
            break;
        }
    }

    return BasicShapeRadius(convertToLength(state, radius.get()));
}

PassRefPtr<BasicShape> basicShapeForValue(const StyleResolverState& state, const CSSBasicShape* basicShapeValue)
{
    RefPtr<BasicShape> basicShape;

    switch (basicShapeValue->type()) {
    case CSSBasicShape::CSSBasicShapeCircleType: {
        const CSSBasicShapeCircle* circleValue = static_cast<const CSSBasicShapeCircle *>(basicShapeValue);
        RefPtr<BasicShapeCircle> circle = BasicShapeCircle::create();

        circle->setCenterX(convertToCenterCoordinate(state, circleValue->centerX()));
        circle->setCenterY(convertToCenterCoordinate(state, circleValue->centerY()));
        circle->setRadius(cssValueToBasicShapeRadius(state, circleValue->radius()));

        basicShape = circle.release();
        break;
    }
    case CSSBasicShape::CSSBasicShapeEllipseType: {
        const CSSBasicShapeEllipse* ellipseValue = static_cast<const CSSBasicShapeEllipse *>(basicShapeValue);
        RefPtr<BasicShapeEllipse> ellipse = BasicShapeEllipse::create();

        ellipse->setCenterX(convertToCenterCoordinate(state, ellipseValue->centerX()));
        ellipse->setCenterY(convertToCenterCoordinate(state, ellipseValue->centerY()));
        ellipse->setRadiusX(cssValueToBasicShapeRadius(state, ellipseValue->radiusX()));
        ellipse->setRadiusY(cssValueToBasicShapeRadius(state, ellipseValue->radiusY()));

        basicShape = ellipse.release();
        break;
    }
    case CSSBasicShape::CSSBasicShapePolygonType: {
        const CSSBasicShapePolygon* polygonValue = static_cast<const CSSBasicShapePolygon *>(basicShapeValue);
        RefPtr<BasicShapePolygon> polygon = BasicShapePolygon::create();

        polygon->setWindRule(polygonValue->windRule());
        const WillBeHeapVector<RefPtrWillBeMember<CSSPrimitiveValue> >& values = polygonValue->values();
        for (unsigned i = 0; i < values.size(); i += 2)
            polygon->appendPoint(convertToLength(state, values.at(i).get()), convertToLength(state, values.at(i + 1).get()));

        basicShape = polygon.release();
        break;
    }
    case CSSBasicShape::CSSBasicShapeInsetType: {
        const CSSBasicShapeInset* rectValue = static_cast<const CSSBasicShapeInset* >(basicShapeValue);
        RefPtr<BasicShapeInset> rect = BasicShapeInset::create();

        rect->setTop(convertToLength(state, rectValue->top()));
        rect->setRight(convertToLength(state, rectValue->right()));
        rect->setBottom(convertToLength(state, rectValue->bottom()));
        rect->setLeft(convertToLength(state, rectValue->left()));

        rect->setTopLeftRadius(convertToLengthSize(state, rectValue->topLeftRadius()));
        rect->setTopRightRadius(convertToLengthSize(state, rectValue->topRightRadius()));
        rect->setBottomRightRadius(convertToLengthSize(state, rectValue->bottomRightRadius()));
        rect->setBottomLeftRadius(convertToLengthSize(state, rectValue->bottomLeftRadius()));

        basicShape = rect.release();
        break;
    }
    default:
        break;
    }

    return basicShape.release();
}

FloatPoint floatPointForCenterCoordinate(const BasicShapeCenterCoordinate& centerX, const BasicShapeCenterCoordinate& centerY, FloatSize boxSize)
{
    float x = floatValueForLength(centerX.computedLength(), boxSize.width());
    float y = floatValueForLength(centerY.computedLength(), boxSize.height());
    return FloatPoint(x, y);
}

}
