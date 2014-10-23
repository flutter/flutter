/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/animation/css/CSSAnimatableValueFactory.h"

#include "core/CSSValueKeywords.h"
#include "core/animation/animatable/AnimatableClipPathOperation.h"
#include "core/animation/animatable/AnimatableColor.h"
#include "core/animation/animatable/AnimatableDouble.h"
#include "core/animation/animatable/AnimatableFilterOperations.h"
#include "core/animation/animatable/AnimatableImage.h"
#include "core/animation/animatable/AnimatableLength.h"
#include "core/animation/animatable/AnimatableLengthBox.h"
#include "core/animation/animatable/AnimatableLengthBoxAndBool.h"
#include "core/animation/animatable/AnimatableLengthPoint.h"
#include "core/animation/animatable/AnimatableLengthPoint3D.h"
#include "core/animation/animatable/AnimatableLengthSize.h"
#include "core/animation/animatable/AnimatableRepeatable.h"
#include "core/animation/animatable/AnimatableShadow.h"
#include "core/animation/animatable/AnimatableShapeValue.h"
#include "core/animation/animatable/AnimatableTransform.h"
#include "core/animation/animatable/AnimatableUnknown.h"
#include "core/css/CSSCalculationValue.h"
#include "core/css/CSSPrimitiveValue.h"
#include "core/css/CSSPrimitiveValueMappings.h"
#include "core/css/CSSPropertyMetadata.h"
#include "core/rendering/style/RenderStyle.h"
#include "platform/Length.h"
#include "platform/LengthBox.h"

namespace blink {

static PassRefPtrWillBeRawPtr<AnimatableValue> createFromLength(const Length& length, const RenderStyle& style)
{
    switch (length.type()) {
    case Fixed:
    case Percent:
    case Calculated:
        return AnimatableLength::create(length, style.effectiveZoom());
    case Auto:
    case Intrinsic:
    case MinIntrinsic:
    case MinContent:
    case MaxContent:
    case FillAvailable:
    case FitContent:
        return AnimatableUnknown::create(CSSPrimitiveValue::create(length, 1));
    case MaxSizeNone:
        return AnimatableUnknown::create(CSSValueNone);
    case ExtendToZoom: // Does not apply to elements.
    case DeviceWidth:
    case DeviceHeight:
        ASSERT_NOT_REACHED();
        return nullptr;
    }
    ASSERT_NOT_REACHED();
    return nullptr;
}

static PassRefPtrWillBeRawPtr<AnimatableValue> createFromLineHeight(const Length& length, const RenderStyle& style)
{
    if (length.type() == Percent) {
        double value = length.value();
        // -100% is used to represent "normal" line height.
        if (value == -100)
            return AnimatableUnknown::create(CSSValueNormal);
        return AnimatableDouble::create(value);
    }
    return createFromLength(length, style);
}

inline static PassRefPtrWillBeRawPtr<AnimatableValue> createFromDouble(double value, AnimatableDouble::Constraint constraint = AnimatableDouble::Unconstrained)
{
    return AnimatableDouble::create(value, constraint);
}

inline static PassRefPtrWillBeRawPtr<AnimatableValue> createFromLengthBox(const LengthBox& lengthBox, const RenderStyle& style)
{
    return AnimatableLengthBox::create(
        createFromLength(lengthBox.left(), style),
        createFromLength(lengthBox.right(), style),
        createFromLength(lengthBox.top(), style),
        createFromLength(lengthBox.bottom(), style));
}

static PassRefPtrWillBeRawPtr<AnimatableValue> createFromBorderImageLength(const BorderImageLength& borderImageLength, const RenderStyle& style)
{
    if (borderImageLength.isNumber())
        return createFromDouble(borderImageLength.number());
    return createFromLength(borderImageLength.length(), style);
}

inline static PassRefPtrWillBeRawPtr<AnimatableValue> createFromBorderImageLengthBox(const BorderImageLengthBox& borderImageLengthBox, const RenderStyle& style)
{
    return AnimatableLengthBox::create(
        createFromBorderImageLength(borderImageLengthBox.left(), style),
        createFromBorderImageLength(borderImageLengthBox.right(), style),
        createFromBorderImageLength(borderImageLengthBox.top(), style),
        createFromBorderImageLength(borderImageLengthBox.bottom(), style));
}

inline static PassRefPtrWillBeRawPtr<AnimatableValue> createFromLengthBoxAndBool(const LengthBox lengthBox, const bool flag, const RenderStyle& style)
{
    return AnimatableLengthBoxAndBool::create(
        createFromLengthBox(lengthBox, style),
        flag);
}

inline static PassRefPtrWillBeRawPtr<AnimatableValue> createFromLengthPoint(const LengthPoint& lengthPoint, const RenderStyle& style)
{
    return AnimatableLengthPoint::create(
        createFromLength(lengthPoint.x(), style),
        createFromLength(lengthPoint.y(), style));
}

inline static PassRefPtrWillBeRawPtr<AnimatableValue> createFromLengthSize(const LengthSize& lengthSize, const RenderStyle& style)
{
    return AnimatableLengthSize::create(
        createFromLength(lengthSize.width(), style),
        createFromLength(lengthSize.height(), style));
}

inline static PassRefPtrWillBeRawPtr<AnimatableValue> createFromStyleImage(StyleImage* image)
{
    if (image) {
        if (RefPtrWillBeRawPtr<CSSValue> cssValue = image->cssValue())
            return AnimatableImage::create(cssValue.release());
    }
    return AnimatableUnknown::create(CSSValueNone);
}

inline static PassRefPtrWillBeRawPtr<AnimatableValue> createFromFillSize(const FillSize& fillSize, const RenderStyle& style)
{
    switch (fillSize.type) {
    case SizeLength:
        return createFromLengthSize(fillSize.size, style);
    case Contain:
    case Cover:
    case SizeNone:
        return AnimatableUnknown::create(CSSPrimitiveValue::create(fillSize.type));
    default:
        ASSERT_NOT_REACHED();
        return nullptr;
    }
}

inline static PassRefPtrWillBeRawPtr<AnimatableValue> createFromBackgroundPosition(const Length& length, bool originIsSet, BackgroundEdgeOrigin origin, const RenderStyle& style)
{
    if (!originIsSet || origin == LeftEdge || origin == TopEdge)
        return createFromLength(length, style);
    return createFromLength(length.subtractFromOneHundredPercent(), style);
}

template<CSSPropertyID property>
inline static PassRefPtrWillBeRawPtr<AnimatableValue> createFromFillLayers(const FillLayer& fillLayers, const RenderStyle& style)
{
    WillBeHeapVector<RefPtrWillBeMember<AnimatableValue> > values;
    for (const FillLayer* fillLayer = &fillLayers; fillLayer; fillLayer = fillLayer->next()) {
        if (property == CSSPropertyBackgroundImage || property == CSSPropertyWebkitMaskImage) {
            if (!fillLayer->isImageSet())
                break;
            values.append(createFromStyleImage(fillLayer->image()));
        } else if (property == CSSPropertyBackgroundPositionX || property == CSSPropertyWebkitMaskPositionX) {
            if (!fillLayer->isXPositionSet())
                break;
            values.append(createFromBackgroundPosition(fillLayer->xPosition(), fillLayer->isBackgroundXOriginSet(), fillLayer->backgroundXOrigin(), style));
        } else if (property == CSSPropertyBackgroundPositionY || property == CSSPropertyWebkitMaskPositionY) {
            if (!fillLayer->isYPositionSet())
                break;
            values.append(createFromBackgroundPosition(fillLayer->yPosition(), fillLayer->isBackgroundYOriginSet(), fillLayer->backgroundYOrigin(), style));
        } else if (property == CSSPropertyBackgroundSize || property == CSSPropertyWebkitMaskSize) {
            if (!fillLayer->isSizeSet())
                break;
            values.append(createFromFillSize(fillLayer->size(), style));
        } else {
            ASSERT_NOT_REACHED();
        }
    }
    return AnimatableRepeatable::create(values);
}

PassRefPtrWillBeRawPtr<AnimatableValue> CSSAnimatableValueFactory::createFromColor(CSSPropertyID property, const RenderStyle& style)
{
    Color color = style.colorIncludingFallback(property, false);
    Color visitedLinkColor = style.colorIncludingFallback(property, true);
    return AnimatableColor::create(color, visitedLinkColor);
}

inline static PassRefPtrWillBeRawPtr<AnimatableValue> createFromShapeValue(ShapeValue* value)
{
    if (value)
        return AnimatableShapeValue::create(value);
    return AnimatableUnknown::create(CSSValueNone);
}

static double fontStretchToDouble(FontStretch fontStretch)
{
    return static_cast<unsigned>(fontStretch);
}

static PassRefPtrWillBeRawPtr<AnimatableValue> createFromFontStretch(FontStretch fontStretch)
{
    return createFromDouble(fontStretchToDouble(fontStretch));
}

static double fontWeightToDouble(FontWeight fontWeight)
{
    switch (fontWeight) {
    case FontWeight100:
        return 100;
    case FontWeight200:
        return 200;
    case FontWeight300:
        return 300;
    case FontWeight400:
        return 400;
    case FontWeight500:
        return 500;
    case FontWeight600:
        return 600;
    case FontWeight700:
        return 700;
    case FontWeight800:
        return 800;
    case FontWeight900:
        return 900;
    }

    ASSERT_NOT_REACHED();
    return 400;
}

static PassRefPtrWillBeRawPtr<AnimatableValue> createFromFontWeight(FontWeight fontWeight)
{
    return createFromDouble(fontWeightToDouble(fontWeight));
}

// FIXME: Generate this function.
PassRefPtrWillBeRawPtr<AnimatableValue> CSSAnimatableValueFactory::create(CSSPropertyID property, const RenderStyle& style)
{
    ASSERT(CSSPropertyMetadata::isAnimatableProperty(property));
    switch (property) {
    case CSSPropertyBackgroundColor:
        return createFromColor(property, style);
    case CSSPropertyBackgroundImage:
        return createFromFillLayers<CSSPropertyBackgroundImage>(style.backgroundLayers(), style);
    case CSSPropertyBackgroundPositionX:
        return createFromFillLayers<CSSPropertyBackgroundPositionX>(style.backgroundLayers(), style);
    case CSSPropertyBackgroundPositionY:
        return createFromFillLayers<CSSPropertyBackgroundPositionY>(style.backgroundLayers(), style);
    case CSSPropertyBackgroundSize:
    case CSSPropertyWebkitBackgroundSize:
        return createFromFillLayers<CSSPropertyBackgroundSize>(style.backgroundLayers(), style);
    case CSSPropertyBorderBottomColor:
        return createFromColor(property, style);
    case CSSPropertyBorderBottomLeftRadius:
        return createFromLengthSize(style.borderBottomLeftRadius(), style);
    case CSSPropertyBorderBottomRightRadius:
        return createFromLengthSize(style.borderBottomRightRadius(), style);
    case CSSPropertyBorderBottomWidth:
        return createFromDouble(style.borderBottomWidth());
    case CSSPropertyBorderImageOutset:
        return createFromBorderImageLengthBox(style.borderImageOutset(), style);
    case CSSPropertyBorderImageSlice:
        return createFromLengthBox(style.borderImageSlices(), style);
    case CSSPropertyBorderImageSource:
        return createFromStyleImage(style.borderImageSource());
    case CSSPropertyBorderImageWidth:
        return createFromBorderImageLengthBox(style.borderImageWidth(), style);
    case CSSPropertyBorderLeftColor:
        return createFromColor(property, style);
    case CSSPropertyBorderLeftWidth:
        return createFromDouble(style.borderLeftWidth());
    case CSSPropertyBorderRightColor:
        return createFromColor(property, style);
    case CSSPropertyBorderRightWidth:
        return createFromDouble(style.borderRightWidth());
    case CSSPropertyBorderTopColor:
        return createFromColor(property, style);
    case CSSPropertyBorderTopLeftRadius:
        return createFromLengthSize(style.borderTopLeftRadius(), style);
    case CSSPropertyBorderTopRightRadius:
        return createFromLengthSize(style.borderTopRightRadius(), style);
    case CSSPropertyBorderTopWidth:
        return createFromDouble(style.borderTopWidth());
    case CSSPropertyBottom:
        return createFromLength(style.bottom(), style);
    case CSSPropertyBoxShadow:
    case CSSPropertyWebkitBoxShadow:
        return AnimatableShadow::create(style.boxShadow());
    case CSSPropertyClip:
        if (style.hasAutoClip())
            return AnimatableUnknown::create(CSSPrimitiveValue::create(CSSValueAuto));
        return createFromLengthBox(style.clip(), style);
    case CSSPropertyColor:
        return createFromColor(property, style);
    case CSSPropertyFlexGrow:
        return createFromDouble(style.flexGrow(), AnimatableDouble::InterpolationIsNonContinuousWithZero);
    case CSSPropertyFlexShrink:
        return createFromDouble(style.flexShrink(), AnimatableDouble::InterpolationIsNonContinuousWithZero);
    case CSSPropertyFlexBasis:
        return createFromLength(style.flexBasis(), style);
    case CSSPropertyFontSize:
        // Must pass a specified size to setFontSize if Text Autosizing is enabled, but a computed size
        // if text zoom is enabled (if neither is enabled it's irrelevant as they're probably the same).
        // FIXME: Should we introduce an option to pass the computed font size here, allowing consumers to
        // enable text zoom rather than Text Autosizing? See http://crbug.com/227545.
        return createFromDouble(style.specifiedFontSize());
    case CSSPropertyFontStretch:
        return createFromFontStretch(style.fontStretch());
    case CSSPropertyFontWeight:
        return createFromFontWeight(style.fontWeight());
    case CSSPropertyHeight:
        return createFromLength(style.height(), style);
    case CSSPropertyListStyleImage:
        return createFromStyleImage(style.listStyleImage());
    case CSSPropertyLeft:
        return createFromLength(style.left(), style);
    case CSSPropertyLetterSpacing:
        return createFromDouble(style.letterSpacing());
    case CSSPropertyLineHeight:
        return createFromLineHeight(style.specifiedLineHeight(), style);
    case CSSPropertyMarginBottom:
        return createFromLength(style.marginBottom(), style);
    case CSSPropertyMarginLeft:
        return createFromLength(style.marginLeft(), style);
    case CSSPropertyMarginRight:
        return createFromLength(style.marginRight(), style);
    case CSSPropertyMarginTop:
        return createFromLength(style.marginTop(), style);
    case CSSPropertyMaxHeight:
        return createFromLength(style.maxHeight(), style);
    case CSSPropertyMaxWidth:
        return createFromLength(style.maxWidth(), style);
    case CSSPropertyMinHeight:
        return createFromLength(style.minHeight(), style);
    case CSSPropertyMinWidth:
        return createFromLength(style.minWidth(), style);
    case CSSPropertyObjectPosition:
        return createFromLengthPoint(style.objectPosition(), style);
    case CSSPropertyOpacity:
        return createFromDouble(style.opacity());
    case CSSPropertyOrphans:
        return createFromDouble(style.orphans());
    case CSSPropertyOutlineColor:
        return createFromColor(property, style);
    case CSSPropertyOutlineOffset:
        return createFromDouble(style.outlineOffset());
    case CSSPropertyOutlineWidth:
        return createFromDouble(style.outlineWidth());
    case CSSPropertyPaddingBottom:
        return createFromLength(style.paddingBottom(), style);
    case CSSPropertyPaddingLeft:
        return createFromLength(style.paddingLeft(), style);
    case CSSPropertyPaddingRight:
        return createFromLength(style.paddingRight(), style);
    case CSSPropertyPaddingTop:
        return createFromLength(style.paddingTop(), style);
    case CSSPropertyRight:
        return createFromLength(style.right(), style);
    case CSSPropertyTextDecorationColor:
        return AnimatableColor::create(style.textDecorationColor().resolve(style.color()), style.visitedLinkTextDecorationColor().resolve(style.visitedLinkColor()));
    case CSSPropertyTextIndent:
        return createFromLength(style.textIndent(), style);
    case CSSPropertyTextShadow:
        return AnimatableShadow::create(style.textShadow());
    case CSSPropertyTop:
        return createFromLength(style.top(), style);
    case CSSPropertyWebkitBorderHorizontalSpacing:
        return createFromDouble(style.horizontalBorderSpacing());
    case CSSPropertyWebkitBorderVerticalSpacing:
        return createFromDouble(style.verticalBorderSpacing());
    case CSSPropertyWebkitClipPath:
        if (ClipPathOperation* operation = style.clipPath())
            return AnimatableClipPathOperation::create(operation);
        return AnimatableUnknown::create(CSSValueNone);
    case CSSPropertyWebkitFilter:
        return AnimatableFilterOperations::create(style.filter());
    case CSSPropertyWebkitMaskBoxImageOutset:
        return createFromBorderImageLengthBox(style.maskBoxImageOutset(), style);
    case CSSPropertyWebkitMaskBoxImageSlice:
        return createFromLengthBoxAndBool(style.maskBoxImageSlices(), style.maskBoxImageSlicesFill(), style);
    case CSSPropertyWebkitMaskBoxImageSource:
        return createFromStyleImage(style.maskBoxImageSource());
    case CSSPropertyWebkitMaskBoxImageWidth:
        return createFromBorderImageLengthBox(style.maskBoxImageWidth(), style);
    case CSSPropertyWebkitMaskImage:
        return createFromFillLayers<CSSPropertyWebkitMaskImage>(style.maskLayers(), style);
    case CSSPropertyWebkitMaskPositionX:
        return createFromFillLayers<CSSPropertyWebkitMaskPositionX>(style.maskLayers(), style);
    case CSSPropertyWebkitMaskPositionY:
        return createFromFillLayers<CSSPropertyWebkitMaskPositionY>(style.maskLayers(), style);
    case CSSPropertyWebkitMaskSize:
        return createFromFillLayers<CSSPropertyWebkitMaskSize>(style.maskLayers(), style);
    case CSSPropertyPerspective:
        return createFromDouble(style.perspective());
    case CSSPropertyPerspectiveOrigin:
        return AnimatableLengthPoint::create(
            createFromLength(style.perspectiveOriginX(), style),
            createFromLength(style.perspectiveOriginY(), style));
    case CSSPropertyShapeOutside:
        return createFromShapeValue(style.shapeOutside());
    case CSSPropertyShapeMargin:
        return createFromLength(style.shapeMargin(), style);
    case CSSPropertyShapeImageThreshold:
        return createFromDouble(style.shapeImageThreshold());
    case CSSPropertyWebkitTextStrokeColor:
        return createFromColor(property, style);
    case CSSPropertyTransform:
        return AnimatableTransform::create(style.transform());
    case CSSPropertyTransformOrigin:
        return AnimatableLengthPoint3D::create(
            createFromLength(style.transformOriginX(), style),
            createFromLength(style.transformOriginY(), style),
            createFromDouble(style.transformOriginZ()));
    case CSSPropertyWidows:
        return createFromDouble(style.widows());
    case CSSPropertyWidth:
        return createFromLength(style.width(), style);
    case CSSPropertyWordSpacing:
        return createFromDouble(style.wordSpacing());
    case CSSPropertyVerticalAlign:
        if (style.verticalAlign() == LENGTH)
            return createFromLength(style.verticalAlignLength(), style);
        return AnimatableUnknown::create(CSSPrimitiveValue::create(style.verticalAlign()));
    case CSSPropertyZIndex:
        return createFromDouble(style.zIndex());
    case CSSPropertyZoom:
        return createFromDouble(style.zoom());
    default:
        ASSERT_NOT_REACHED();
        // This return value is to avoid a release crash if possible.
        return AnimatableUnknown::create(nullptr);
    }
}

} // namespace blink
