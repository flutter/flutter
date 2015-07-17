/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 2004-2005 Allan Sandfeld Jensen (kde@carewolf.com)
 * Copyright (C) 2006, 2007 Nicholas Shanks (webkit@nickshanks.com)
 * Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2007 Alexey Proskuryakov <ap@webkit.org>
 * Copyright (C) 2007, 2008 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (c) 2011, Code Aurora Forum. All rights reserved.
 * Copyright (C) Research In Motion Limited 2011. All rights reserved.
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
 */

#include "sky/engine/core/css/resolver/CSSToStyleMap.h"

#include "gen/sky/core/CSSValueKeywords.h"
#include "sky/engine/core/css/CSSPrimitiveValue.h"
#include "sky/engine/core/css/CSSPrimitiveValueMappings.h"
#include "sky/engine/core/css/Pair.h"
#include "sky/engine/core/css/resolver/StyleResolverState.h"
#include "sky/engine/core/rendering/style/FillLayer.h"

namespace blink {

const CSSToLengthConversionData& CSSToStyleMap::cssToLengthConversionData() const
{
    return m_state.cssToLengthConversionData();
}

PassRefPtr<StyleImage> CSSToStyleMap::styleImage(CSSPropertyID propertyId, CSSValue* value)
{
    return m_elementStyleResources.styleImage(m_state.document(), m_state.document().textLinkColors(), m_state.style()->color(), propertyId, value);
}

void CSSToStyleMap::mapFillAttachment(FillLayer* layer, CSSValue* value) const
{
    if (value->isInitialValue()) {
        layer->setAttachment(FillLayer::initialFillAttachment(layer->type()));
        return;
    }

    if (!value->isPrimitiveValue())
        return;

    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    switch (primitiveValue->getValueID()) {
    case CSSValueFixed:
        layer->setAttachment(FixedBackgroundAttachment);
        break;
    case CSSValueLocal:
        layer->setAttachment(LocalBackgroundAttachment);
        break;
    default:
        return;
    }
}

void CSSToStyleMap::mapFillClip(FillLayer* layer, CSSValue* value) const
{
    if (value->isInitialValue()) {
        layer->setClip(FillLayer::initialFillClip(layer->type()));
        return;
    }

    if (!value->isPrimitiveValue())
        return;

    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    layer->setClip(*primitiveValue);
}

void CSSToStyleMap::mapFillComposite(FillLayer* layer, CSSValue* value) const
{
    if (value->isInitialValue()) {
        layer->setComposite(FillLayer::initialFillComposite(layer->type()));
        return;
    }

    if (!value->isPrimitiveValue())
        return;

    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    layer->setComposite(*primitiveValue);
}

void CSSToStyleMap::mapFillBlendMode(FillLayer* layer, CSSValue* value) const
{
    if (value->isInitialValue()) {
        layer->setBlendMode(FillLayer::initialFillBlendMode(layer->type()));
        return;
    }

    if (!value->isPrimitiveValue())
        return;

    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    layer->setBlendMode(*primitiveValue);
}

void CSSToStyleMap::mapFillOrigin(FillLayer* layer, CSSValue* value) const
{
    if (value->isInitialValue()) {
        layer->setOrigin(FillLayer::initialFillOrigin(layer->type()));
        return;
    }

    if (!value->isPrimitiveValue())
        return;

    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    layer->setOrigin(*primitiveValue);
}


void CSSToStyleMap::mapFillImage(FillLayer* layer, CSSValue* value)
{
    if (value->isInitialValue()) {
        layer->setImage(FillLayer::initialFillImage(layer->type()));
        return;
    }

    layer->setImage(styleImage(CSSPropertyBackgroundImage, value));
}

void CSSToStyleMap::mapFillRepeatX(FillLayer* layer, CSSValue* value) const
{
    if (value->isInitialValue()) {
        layer->setRepeatX(FillLayer::initialFillRepeatX(layer->type()));
        return;
    }

    if (!value->isPrimitiveValue())
        return;

    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    layer->setRepeatX(*primitiveValue);
}

void CSSToStyleMap::mapFillRepeatY(FillLayer* layer, CSSValue* value) const
{
    if (value->isInitialValue()) {
        layer->setRepeatY(FillLayer::initialFillRepeatY(layer->type()));
        return;
    }

    if (!value->isPrimitiveValue())
        return;

    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    layer->setRepeatY(*primitiveValue);
}

void CSSToStyleMap::mapFillSize(FillLayer* layer, CSSValue* value) const
{
    if (value->isInitialValue()) {
        layer->setSizeType(FillLayer::initialFillSizeType(layer->type()));
        layer->setSizeLength(FillLayer::initialFillSizeLength(layer->type()));
        return;
    }

    if (!value->isPrimitiveValue())
        return;

    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    if (primitiveValue->getValueID() == CSSValueContain)
        layer->setSizeType(Contain);
    else if (primitiveValue->getValueID() == CSSValueCover)
        layer->setSizeType(Cover);
    else
        layer->setSizeType(SizeLength);

    LengthSize b = FillLayer::initialFillSizeLength(layer->type());

    if (primitiveValue->getValueID() == CSSValueContain || primitiveValue->getValueID() == CSSValueCover) {
        layer->setSizeLength(b);
        return;
    }

    Length firstLength;
    Length secondLength;

    if (Pair* pair = primitiveValue->getPairValue()) {
        firstLength = pair->first()->convertToLength<AnyConversion>(cssToLengthConversionData());
        secondLength = pair->second()->convertToLength<AnyConversion>(cssToLengthConversionData());
    } else {
        firstLength = primitiveValue->convertToLength<AnyConversion>(cssToLengthConversionData());
        secondLength = Length();
    }

    b.setWidth(firstLength);
    b.setHeight(secondLength);
    layer->setSizeLength(b);
}

void CSSToStyleMap::mapFillXPosition(FillLayer* layer, CSSValue* value) const
{
    if (value->isInitialValue()) {
        layer->setXPosition(FillLayer::initialFillXPosition(layer->type()));
        return;
    }

    if (!value->isPrimitiveValue())
        return;

    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    Pair* pair = primitiveValue->getPairValue();
    if (pair)
        primitiveValue = pair->second();

    Length length = primitiveValue->convertToLength<FixedConversion | PercentConversion>(cssToLengthConversionData());

    layer->setXPosition(length);
    if (pair)
        layer->setBackgroundXOrigin(*(pair->first()));
}

void CSSToStyleMap::mapFillYPosition(FillLayer* layer, CSSValue* value) const
{
    if (value->isInitialValue()) {
        layer->setYPosition(FillLayer::initialFillYPosition(layer->type()));
        return;
    }

    if (!value->isPrimitiveValue())
        return;

    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);
    Pair* pair = primitiveValue->getPairValue();
    if (pair)
        primitiveValue = pair->second();

    Length length = primitiveValue->convertToLength<FixedConversion | PercentConversion>(cssToLengthConversionData());

    layer->setYPosition(length);
    if (pair)
        layer->setBackgroundYOrigin(*(pair->first()));
}

};
