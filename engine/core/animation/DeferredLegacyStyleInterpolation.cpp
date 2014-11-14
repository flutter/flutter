// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/animation/DeferredLegacyStyleInterpolation.h"

#include "core/animation/LegacyStyleInterpolation.h"
#include "core/css/CSSImageValue.h"
#include "core/css/CSSPrimitiveValue.h"
#include "core/css/CSSShadowValue.h"
#include "core/css/CSSValueList.h"
#include "core/css/Pair.h"
#include "core/css/Rect.h"
#include "core/css/resolver/StyleResolver.h"
#include "core/css/resolver/StyleResolverState.h"

namespace blink {

void DeferredLegacyStyleInterpolation::apply(StyleResolverState& state) const
{
    RefPtr<LegacyStyleInterpolation> innerInterpolation = LegacyStyleInterpolation::create(
        StyleResolver::createAnimatableValueSnapshot(state, m_id, *m_startCSSValue),
        StyleResolver::createAnimatableValueSnapshot(state, m_id, *m_endCSSValue),
        m_id);
    innerInterpolation->interpolate(m_cachedIteration, m_cachedFraction);
    innerInterpolation->apply(state);
}

bool DeferredLegacyStyleInterpolation::interpolationRequiresStyleResolve(const CSSValue& value)
{
    switch (value.cssValueType()) {
    case CSSValue::CSS_INHERIT:
        return true;
    case CSSValue::CSS_PRIMITIVE_VALUE:
        return interpolationRequiresStyleResolve(toCSSPrimitiveValue(value));
    case CSSValue::CSS_VALUE_LIST:
        return interpolationRequiresStyleResolve(toCSSValueList(value));
    case CSSValue::CSS_CUSTOM:
        if (value.isImageValue())
            return interpolationRequiresStyleResolve(toCSSImageValue(value));
        if (value.isShadowValue())
            return interpolationRequiresStyleResolve(toCSSShadowValue(value));
        // FIXME: consider other custom types.
        return true;
    case CSSValue::CSS_INITIAL:
        // FIXME: should not require resolving styles for initial.
        return true;
    default:
        ASSERT_NOT_REACHED();
        return true;
    }
}

bool DeferredLegacyStyleInterpolation::interpolationRequiresStyleResolve(const CSSPrimitiveValue& primitiveValue)
{
    // FIXME: consider other types.
    if (primitiveValue.isNumber() || primitiveValue.isPercentage() || primitiveValue.isAngle() || primitiveValue.isRGBColor() || primitiveValue.isURI())
        return false;

    if (primitiveValue.isLength())
        return primitiveValue.isFontRelativeLength() || primitiveValue.isViewportPercentageLength();

    if (primitiveValue.isCalculated()) {
        CSSLengthArray lengthArray(CSSPrimitiveValue::LengthUnitTypeCount);
        primitiveValue.accumulateLengthArray(lengthArray);
        return lengthArray[CSSPrimitiveValue::UnitTypeFontSize] != 0
            || lengthArray[CSSPrimitiveValue::UnitTypeFontXSize] != 0
            || lengthArray[CSSPrimitiveValue::UnitTypeRootFontSize] != 0
            || lengthArray[CSSPrimitiveValue::UnitTypeZeroCharacterWidth] != 0
            || lengthArray[CSSPrimitiveValue::UnitTypeViewportWidth] != 0
            || lengthArray[CSSPrimitiveValue::UnitTypeViewportHeight] != 0
            || lengthArray[CSSPrimitiveValue::UnitTypeViewportMin] != 0
            || lengthArray[CSSPrimitiveValue::UnitTypeViewportMax] != 0;
    }

    if (Pair* pair = primitiveValue.getPairValue()) {
        return interpolationRequiresStyleResolve(*pair->first())
            || interpolationRequiresStyleResolve(*pair->second());
    }

    if (Rect* rect = primitiveValue.getRectValue()) {
        return interpolationRequiresStyleResolve(*rect->top())
            || interpolationRequiresStyleResolve(*rect->right())
            || interpolationRequiresStyleResolve(*rect->bottom())
            || interpolationRequiresStyleResolve(*rect->left());
    }

    if (Quad* quad = primitiveValue.getQuadValue()) {
        return interpolationRequiresStyleResolve(*quad->top())
            || interpolationRequiresStyleResolve(*quad->right())
            || interpolationRequiresStyleResolve(*quad->bottom())
            || interpolationRequiresStyleResolve(*quad->left());
    }

    if (primitiveValue.isShape())
        return interpolationRequiresStyleResolve(*primitiveValue.getShapeValue());

    return (primitiveValue.getValueID() != CSSValueNone);
}

bool DeferredLegacyStyleInterpolation::interpolationRequiresStyleResolve(const CSSImageValue& imageValue)
{
    return false;
}

bool DeferredLegacyStyleInterpolation::interpolationRequiresStyleResolve(const CSSShadowValue& shadowValue)
{
    return (shadowValue.x && interpolationRequiresStyleResolve(*shadowValue.x))
        || (shadowValue.y && interpolationRequiresStyleResolve(*shadowValue.y))
        || (shadowValue.blur && interpolationRequiresStyleResolve(*shadowValue.blur))
        || (shadowValue.spread && interpolationRequiresStyleResolve(*shadowValue.spread))
        || (shadowValue.style && interpolationRequiresStyleResolve(*shadowValue.style))
        || (shadowValue.color && interpolationRequiresStyleResolve(*shadowValue.color));
}

bool DeferredLegacyStyleInterpolation::interpolationRequiresStyleResolve(const CSSValueList& valueList)
{
    size_t length = valueList.length();
    for (size_t index = 0; index < length; ++index) {
        if (interpolationRequiresStyleResolve(*valueList.item(index)))
            return true;
    }
    return false;
}

bool DeferredLegacyStyleInterpolation::interpolationRequiresStyleResolve(const CSSBasicShape& shape)
{
    // FIXME: Should determine the specific shape, and inspect the members.
    return false;
}

}
