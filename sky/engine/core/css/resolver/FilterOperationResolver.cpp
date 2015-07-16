/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 2004-2005 Allan Sandfeld Jensen (kde@carewolf.com)
 * Copyright (C) 2006, 2007 Nicholas Shanks (webkit@nickshanks.com)
 * Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013 Apple Inc. All rights reserved.
 * Copyright (C) 2007 Alexey Proskuryakov <ap@webkit.org>
 * Copyright (C) 2007, 2008 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (c) 2011, Code Aurora Forum. All rights reserved.
 * Copyright (C) Research In Motion Limited 2011. All rights reserved.
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#include "sky/engine/core/css/resolver/FilterOperationResolver.h"

#include "sky/engine/core/css/CSSFilterValue.h"
#include "sky/engine/core/css/CSSPrimitiveValueMappings.h"
#include "sky/engine/core/css/CSSShadowValue.h"
#include "sky/engine/core/css/parser/BisonCSSParser.h"
#include "sky/engine/core/css/resolver/TransformBuilder.h"

namespace blink {

static FilterOperation::OperationType filterOperationForType(CSSFilterValue::FilterOperationType type)
{
    switch (type) {
    case CSSFilterValue::GrayscaleFilterOperation:
        return FilterOperation::GRAYSCALE;
    case CSSFilterValue::SepiaFilterOperation:
        return FilterOperation::SEPIA;
    case CSSFilterValue::SaturateFilterOperation:
        return FilterOperation::SATURATE;
    case CSSFilterValue::HueRotateFilterOperation:
        return FilterOperation::HUE_ROTATE;
    case CSSFilterValue::InvertFilterOperation:
        return FilterOperation::INVERT;
    case CSSFilterValue::OpacityFilterOperation:
        return FilterOperation::OPACITY;
    case CSSFilterValue::BrightnessFilterOperation:
        return FilterOperation::BRIGHTNESS;
    case CSSFilterValue::ContrastFilterOperation:
        return FilterOperation::CONTRAST;
    case CSSFilterValue::BlurFilterOperation:
        return FilterOperation::BLUR;
    case CSSFilterValue::DropShadowFilterOperation:
        return FilterOperation::DROP_SHADOW;
    case CSSFilterValue::UnknownFilterOperation:
        return FilterOperation::NONE;
    }
    return FilterOperation::NONE;
}

bool FilterOperationResolver::createFilterOperations(CSSValue* inValue, const CSSToLengthConversionData& conversionData, FilterOperations& outOperations, StyleResolverState& state)
{
    ASSERT(outOperations.isEmpty());

    if (!inValue)
        return false;

    if (inValue->isPrimitiveValue()) {
        CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(inValue);
        if (primitiveValue->getValueID() == CSSValueNone)
            return true;
    }

    if (!inValue->isValueList())
        return false;

    FilterOperations operations;
    for (CSSValueListIterator i = inValue; i.hasMore(); i.advance()) {
        CSSValue* currValue = i.value();
        if (!currValue->isFilterValue())
            continue;

        CSSFilterValue* filterValue = toCSSFilterValue(i.value());
        FilterOperation::OperationType operationType = filterOperationForType(filterValue->operationType());

        // Check that all parameters are primitive values, with the
        // exception of drop shadow which has a CSSShadowValue parameter.
        if (operationType != FilterOperation::DROP_SHADOW) {
            bool haveNonPrimitiveValue = false;
            for (unsigned j = 0; j < filterValue->length(); ++j) {
                if (!filterValue->item(j)->isPrimitiveValue()) {
                    haveNonPrimitiveValue = true;
                    break;
                }
            }
            if (haveNonPrimitiveValue)
                continue;
        }

        CSSPrimitiveValue* firstValue = filterValue->length() && filterValue->item(0)->isPrimitiveValue() ? toCSSPrimitiveValue(filterValue->item(0)) : 0;
        switch (filterValue->operationType()) {
        case CSSFilterValue::GrayscaleFilterOperation:
        case CSSFilterValue::SepiaFilterOperation:
        case CSSFilterValue::SaturateFilterOperation: {
            double amount = 1;
            if (filterValue->length() == 1) {
                amount = firstValue->getDoubleValue();
                if (firstValue->isPercentage())
                    amount /= 100;
            }

            operations.operations().append(BasicColorMatrixFilterOperation::create(amount, operationType));
            break;
        }
        case CSSFilterValue::HueRotateFilterOperation: {
            double angle = 0;
            if (filterValue->length() == 1)
                angle = firstValue->computeDegrees();

            operations.operations().append(BasicColorMatrixFilterOperation::create(angle, operationType));
            break;
        }
        case CSSFilterValue::InvertFilterOperation:
        case CSSFilterValue::BrightnessFilterOperation:
        case CSSFilterValue::ContrastFilterOperation:
        case CSSFilterValue::OpacityFilterOperation: {
            double amount = (filterValue->operationType() == CSSFilterValue::BrightnessFilterOperation) ? 0 : 1;
            if (filterValue->length() == 1) {
                amount = firstValue->getDoubleValue();
                if (firstValue->isPercentage())
                    amount /= 100;
            }

            operations.operations().append(BasicComponentTransferFilterOperation::create(amount, operationType));
            break;
        }
        case CSSFilterValue::BlurFilterOperation: {
            Length stdDeviation = Length(0, Fixed);
            if (filterValue->length() >= 1)
                stdDeviation = firstValue->convertToLength<FixedConversion | PercentConversion>(conversionData);
            operations.operations().append(BlurFilterOperation::create(stdDeviation));
            break;
        }
        case CSSFilterValue::DropShadowFilterOperation: {
            if (filterValue->length() != 1)
                return false;

            CSSValue* cssValue = filterValue->item(0);
            if (!cssValue->isShadowValue())
                continue;

            CSSShadowValue* item = toCSSShadowValue(cssValue);
            IntPoint location(item->x->computeLength<int>(conversionData), item->y->computeLength<int>(conversionData));
            int blur = item->blur ? item->blur->computeLength<int>(conversionData) : 0;
            Color shadowColor = Color::transparent;
            if (item->color)
                shadowColor = state.document().textLinkColors().colorFromPrimitiveValue(item->color.get(), state.style()->color());

            operations.operations().append(DropShadowFilterOperation::create(location, blur, shadowColor));
            break;
        }
        case CSSFilterValue::UnknownFilterOperation:
        default:
            ASSERT_NOT_REACHED();
            break;
        }
    }

    outOperations = operations;
    return true;
}

} // namespace blink
