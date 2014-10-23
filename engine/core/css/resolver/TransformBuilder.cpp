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

#include "config.h"
#include "core/css/resolver/TransformBuilder.h"

#include "core/css/CSSPrimitiveValueMappings.h"
#include "core/css/CSSTransformValue.h"
#include "core/rendering/style/RenderStyle.h"
#include "platform/heap/Handle.h"
#include "platform/transforms/Matrix3DTransformOperation.h"
#include "platform/transforms/MatrixTransformOperation.h"
#include "platform/transforms/PerspectiveTransformOperation.h"
#include "platform/transforms/RotateTransformOperation.h"
#include "platform/transforms/ScaleTransformOperation.h"
#include "platform/transforms/SkewTransformOperation.h"
#include "platform/transforms/TransformationMatrix.h"
#include "platform/transforms/TranslateTransformOperation.h"

namespace blink {

static Length convertToFloatLength(CSSPrimitiveValue* primitiveValue, const CSSToLengthConversionData& conversionData)
{
    ASSERT(primitiveValue);
    return primitiveValue->convertToLength<FixedConversion | PercentConversion>(conversionData);
}

static TransformOperation::OperationType getTransformOperationType(CSSTransformValue::TransformOperationType type)
{
    switch (type) {
    case CSSTransformValue::ScaleTransformOperation: return TransformOperation::Scale;
    case CSSTransformValue::ScaleXTransformOperation: return TransformOperation::ScaleX;
    case CSSTransformValue::ScaleYTransformOperation: return TransformOperation::ScaleY;
    case CSSTransformValue::ScaleZTransformOperation: return TransformOperation::ScaleZ;
    case CSSTransformValue::Scale3DTransformOperation: return TransformOperation::Scale3D;
    case CSSTransformValue::TranslateTransformOperation: return TransformOperation::Translate;
    case CSSTransformValue::TranslateXTransformOperation: return TransformOperation::TranslateX;
    case CSSTransformValue::TranslateYTransformOperation: return TransformOperation::TranslateY;
    case CSSTransformValue::TranslateZTransformOperation: return TransformOperation::TranslateZ;
    case CSSTransformValue::Translate3DTransformOperation: return TransformOperation::Translate3D;
    case CSSTransformValue::RotateTransformOperation: return TransformOperation::Rotate;
    case CSSTransformValue::RotateXTransformOperation: return TransformOperation::RotateX;
    case CSSTransformValue::RotateYTransformOperation: return TransformOperation::RotateY;
    case CSSTransformValue::RotateZTransformOperation: return TransformOperation::RotateZ;
    case CSSTransformValue::Rotate3DTransformOperation: return TransformOperation::Rotate3D;
    case CSSTransformValue::SkewTransformOperation: return TransformOperation::Skew;
    case CSSTransformValue::SkewXTransformOperation: return TransformOperation::SkewX;
    case CSSTransformValue::SkewYTransformOperation: return TransformOperation::SkewY;
    case CSSTransformValue::MatrixTransformOperation: return TransformOperation::Matrix;
    case CSSTransformValue::Matrix3DTransformOperation: return TransformOperation::Matrix3D;
    case CSSTransformValue::PerspectiveTransformOperation: return TransformOperation::Perspective;
    case CSSTransformValue::UnknownTransformOperation: return TransformOperation::None;
    }
    return TransformOperation::None;
}

bool TransformBuilder::createTransformOperations(CSSValue* inValue, const CSSToLengthConversionData& conversionData, TransformOperations& outOperations)
{
    if (!inValue || !inValue->isValueList()) {
        outOperations.clear();
        return false;
    }

    float zoomFactor = conversionData.zoom();
    TransformOperations operations;
    for (CSSValueListIterator i = inValue; i.hasMore(); i.advance()) {
        CSSValue* currValue = i.value();

        if (!currValue->isTransformValue())
            continue;

        CSSTransformValue* transformValue = toCSSTransformValue(i.value());
        if (!transformValue->length())
            continue;

        bool haveNonPrimitiveValue = false;
        for (unsigned j = 0; j < transformValue->length(); ++j) {
            if (!transformValue->item(j)->isPrimitiveValue()) {
                haveNonPrimitiveValue = true;
                break;
            }
        }
        if (haveNonPrimitiveValue)
            continue;

        CSSPrimitiveValue* firstValue = toCSSPrimitiveValue(transformValue->item(0));

        switch (transformValue->operationType()) {
        case CSSTransformValue::ScaleTransformOperation:
        case CSSTransformValue::ScaleXTransformOperation:
        case CSSTransformValue::ScaleYTransformOperation: {
            double sx = 1.0;
            double sy = 1.0;
            if (transformValue->operationType() == CSSTransformValue::ScaleYTransformOperation)
                sy = firstValue->getDoubleValue();
            else {
                sx = firstValue->getDoubleValue();
                if (transformValue->operationType() != CSSTransformValue::ScaleXTransformOperation) {
                    if (transformValue->length() > 1) {
                        CSSPrimitiveValue* secondValue = toCSSPrimitiveValue(transformValue->item(1));
                        sy = secondValue->getDoubleValue();
                    } else
                        sy = sx;
                }
            }
            operations.operations().append(ScaleTransformOperation::create(sx, sy, 1.0, getTransformOperationType(transformValue->operationType())));
            break;
        }
        case CSSTransformValue::ScaleZTransformOperation:
        case CSSTransformValue::Scale3DTransformOperation: {
            double sx = 1.0;
            double sy = 1.0;
            double sz = 1.0;
            if (transformValue->operationType() == CSSTransformValue::ScaleZTransformOperation)
                sz = firstValue->getDoubleValue();
            else if (transformValue->operationType() == CSSTransformValue::ScaleYTransformOperation)
                sy = firstValue->getDoubleValue();
            else {
                sx = firstValue->getDoubleValue();
                if (transformValue->operationType() != CSSTransformValue::ScaleXTransformOperation) {
                    if (transformValue->length() > 2) {
                        CSSPrimitiveValue* thirdValue = toCSSPrimitiveValue(transformValue->item(2));
                        sz = thirdValue->getDoubleValue();
                    }
                    if (transformValue->length() > 1) {
                        CSSPrimitiveValue* secondValue = toCSSPrimitiveValue(transformValue->item(1));
                        sy = secondValue->getDoubleValue();
                    } else
                        sy = sx;
                }
            }
            operations.operations().append(ScaleTransformOperation::create(sx, sy, sz, getTransformOperationType(transformValue->operationType())));
            break;
        }
        case CSSTransformValue::TranslateTransformOperation:
        case CSSTransformValue::TranslateXTransformOperation:
        case CSSTransformValue::TranslateYTransformOperation: {
            Length tx = Length(0, Fixed);
            Length ty = Length(0, Fixed);
            if (transformValue->operationType() == CSSTransformValue::TranslateYTransformOperation)
                ty = convertToFloatLength(firstValue, conversionData);
            else {
                tx = convertToFloatLength(firstValue, conversionData);
                if (transformValue->operationType() != CSSTransformValue::TranslateXTransformOperation) {
                    if (transformValue->length() > 1) {
                        CSSPrimitiveValue* secondValue = toCSSPrimitiveValue(transformValue->item(1));
                        ty = convertToFloatLength(secondValue, conversionData);
                    }
                }
            }

            operations.operations().append(TranslateTransformOperation::create(tx, ty, 0, getTransformOperationType(transformValue->operationType())));
            break;
        }
        case CSSTransformValue::TranslateZTransformOperation:
        case CSSTransformValue::Translate3DTransformOperation: {
            Length tx = Length(0, Fixed);
            Length ty = Length(0, Fixed);
            double tz = 0;
            if (transformValue->operationType() == CSSTransformValue::TranslateZTransformOperation)
                tz = firstValue->computeLength<double>(conversionData);
            else if (transformValue->operationType() == CSSTransformValue::TranslateYTransformOperation)
                ty = convertToFloatLength(firstValue, conversionData);
            else {
                tx = convertToFloatLength(firstValue, conversionData);
                if (transformValue->operationType() != CSSTransformValue::TranslateXTransformOperation) {
                    if (transformValue->length() > 2) {
                        CSSPrimitiveValue* thirdValue = toCSSPrimitiveValue(transformValue->item(2));
                        tz = thirdValue->computeLength<double>(conversionData);
                    }
                    if (transformValue->length() > 1) {
                        CSSPrimitiveValue* secondValue = toCSSPrimitiveValue(transformValue->item(1));
                        ty = convertToFloatLength(secondValue, conversionData);
                    }
                }
            }

            operations.operations().append(TranslateTransformOperation::create(tx, ty, tz, getTransformOperationType(transformValue->operationType())));
            break;
        }
        case CSSTransformValue::RotateTransformOperation: {
            double angle = firstValue->computeDegrees();
            operations.operations().append(RotateTransformOperation::create(0, 0, 1, angle, getTransformOperationType(transformValue->operationType())));
            break;
        }
        case CSSTransformValue::RotateXTransformOperation:
        case CSSTransformValue::RotateYTransformOperation:
        case CSSTransformValue::RotateZTransformOperation: {
            double x = 0;
            double y = 0;
            double z = 0;
            double angle = firstValue->computeDegrees();

            if (transformValue->operationType() == CSSTransformValue::RotateXTransformOperation)
                x = 1;
            else if (transformValue->operationType() == CSSTransformValue::RotateYTransformOperation)
                y = 1;
            else
                z = 1;
            operations.operations().append(RotateTransformOperation::create(x, y, z, angle, getTransformOperationType(transformValue->operationType())));
            break;
        }
        case CSSTransformValue::Rotate3DTransformOperation: {
            if (transformValue->length() < 4)
                break;
            CSSPrimitiveValue* secondValue = toCSSPrimitiveValue(transformValue->item(1));
            CSSPrimitiveValue* thirdValue = toCSSPrimitiveValue(transformValue->item(2));
            CSSPrimitiveValue* fourthValue = toCSSPrimitiveValue(transformValue->item(3));
            double x = firstValue->getDoubleValue();
            double y = secondValue->getDoubleValue();
            double z = thirdValue->getDoubleValue();
            double angle = fourthValue->computeDegrees();
            operations.operations().append(RotateTransformOperation::create(x, y, z, angle, getTransformOperationType(transformValue->operationType())));
            break;
        }
        case CSSTransformValue::SkewTransformOperation:
        case CSSTransformValue::SkewXTransformOperation:
        case CSSTransformValue::SkewYTransformOperation: {
            double angleX = 0;
            double angleY = 0;
            double angle = firstValue->computeDegrees();
            if (transformValue->operationType() == CSSTransformValue::SkewYTransformOperation)
                angleY = angle;
            else {
                angleX = angle;
                if (transformValue->operationType() == CSSTransformValue::SkewTransformOperation) {
                    if (transformValue->length() > 1) {
                        CSSPrimitiveValue* secondValue = toCSSPrimitiveValue(transformValue->item(1));
                        angleY = secondValue->computeDegrees();
                    }
                }
            }
            operations.operations().append(SkewTransformOperation::create(angleX, angleY, getTransformOperationType(transformValue->operationType())));
            break;
        }
        case CSSTransformValue::MatrixTransformOperation: {
            if (transformValue->length() < 6)
                break;
            double a = firstValue->getDoubleValue();
            double b = toCSSPrimitiveValue(transformValue->item(1))->getDoubleValue();
            double c = toCSSPrimitiveValue(transformValue->item(2))->getDoubleValue();
            double d = toCSSPrimitiveValue(transformValue->item(3))->getDoubleValue();
            double e = zoomFactor * toCSSPrimitiveValue(transformValue->item(4))->getDoubleValue();
            double f = zoomFactor * toCSSPrimitiveValue(transformValue->item(5))->getDoubleValue();
            operations.operations().append(MatrixTransformOperation::create(a, b, c, d, e, f));
            break;
        }
        case CSSTransformValue::Matrix3DTransformOperation: {
            if (transformValue->length() < 16)
                break;
            TransformationMatrix matrix(toCSSPrimitiveValue(transformValue->item(0))->getDoubleValue(),
                toCSSPrimitiveValue(transformValue->item(1))->getDoubleValue(),
                toCSSPrimitiveValue(transformValue->item(2))->getDoubleValue(),
                toCSSPrimitiveValue(transformValue->item(3))->getDoubleValue(),
                toCSSPrimitiveValue(transformValue->item(4))->getDoubleValue(),
                toCSSPrimitiveValue(transformValue->item(5))->getDoubleValue(),
                toCSSPrimitiveValue(transformValue->item(6))->getDoubleValue(),
                toCSSPrimitiveValue(transformValue->item(7))->getDoubleValue(),
                toCSSPrimitiveValue(transformValue->item(8))->getDoubleValue(),
                toCSSPrimitiveValue(transformValue->item(9))->getDoubleValue(),
                toCSSPrimitiveValue(transformValue->item(10))->getDoubleValue(),
                toCSSPrimitiveValue(transformValue->item(11))->getDoubleValue(),
                zoomFactor * toCSSPrimitiveValue(transformValue->item(12))->getDoubleValue(),
                zoomFactor * toCSSPrimitiveValue(transformValue->item(13))->getDoubleValue(),
                toCSSPrimitiveValue(transformValue->item(14))->getDoubleValue(),
                toCSSPrimitiveValue(transformValue->item(15))->getDoubleValue());
            operations.operations().append(Matrix3DTransformOperation::create(matrix));
            break;
        }
        case CSSTransformValue::PerspectiveTransformOperation: {
            double p;
            if (firstValue->isLength())
                p = firstValue->computeLength<double>(conversionData);
            else {
                // This is a quirk that should go away when 3d transforms are finalized.
                double val = firstValue->getDoubleValue();
                if (val < 0)
                    return false;
                p = clampToPositiveInteger(val);
            }

            operations.operations().append(PerspectiveTransformOperation::create(p));
            break;
        }
        case CSSTransformValue::UnknownTransformOperation:
            ASSERT_NOT_REACHED();
            break;
        }
    }

    outOperations = operations;
    return true;
}

} // namespace blink
