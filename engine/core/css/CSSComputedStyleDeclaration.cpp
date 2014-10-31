/*
 * Copyright (C) 2004 Zack Rusin <zack@kde.org>
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2007 Alexey Proskuryakov <ap@webkit.org>
 * Copyright (C) 2007 Nicholas Shanks <webkit@nickshanks.com>
 * Copyright (C) 2011 Sencha, Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301  USA
 */

#include "config.h"
#include "core/css/CSSComputedStyleDeclaration.h"

#include "bindings/core/v8/ExceptionState.h"
#include "core/CSSPropertyNames.h"
#include "core/StylePropertyShorthand.h"
#include "core/animation/DocumentAnimations.h"
#include "core/css/BasicShapeFunctions.h"
#include "core/css/CSSAspectRatioValue.h"
#include "core/css/CSSBorderImage.h"
#include "core/css/CSSFilterValue.h"
#include "core/css/CSSFontFeatureValue.h"
#include "core/css/CSSFontValue.h"
#include "core/css/CSSFunctionValue.h"
#include "core/css/CSSGridLineNamesValue.h"
#include "core/css/CSSGridTemplateAreasValue.h"
#include "core/css/CSSLineBoxContainValue.h"
#include "core/css/parser/BisonCSSParser.h"
#include "core/css/CSSPrimitiveValue.h"
#include "core/css/CSSPrimitiveValueMappings.h"
#include "core/css/CSSPropertyMetadata.h"
#include "core/css/CSSSelector.h"
#include "core/css/CSSShadowValue.h"
#include "core/css/CSSTimingFunctionValue.h"
#include "core/css/CSSTransformValue.h"
#include "core/css/CSSValueList.h"
#include "core/css/CSSValuePool.h"
#include "core/css/Pair.h"
#include "core/css/Rect.h"
#include "core/css/StylePropertySet.h"
#include "core/css/resolver/StyleResolver.h"
#include "core/dom/Document.h"
#include "core/dom/ExceptionCode.h"
#include "core/rendering/RenderBox.h"
#include "core/rendering/RenderGrid.h"
#include "core/rendering/style/ContentData.h"
#include "core/rendering/style/RenderStyle.h"
#include "core/rendering/style/ShadowList.h"
#include "core/rendering/style/ShapeValue.h"
#include "platform/FontFamilyNames.h"
#include "platform/RuntimeEnabledFeatures.h"
#include "platform/fonts/FontFeatureSettings.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

// List of all properties we know how to compute, omitting shorthands.
// NOTE: Do not use this list, use computableProperties() instead
// to respect runtime enabling of CSS properties.
static const CSSPropertyID staticComputableProperties[] = {
    CSSPropertyAnimationDelay,
    CSSPropertyAnimationDirection,
    CSSPropertyAnimationDuration,
    CSSPropertyAnimationFillMode,
    CSSPropertyAnimationIterationCount,
    CSSPropertyAnimationName,
    CSSPropertyAnimationPlayState,
    CSSPropertyAnimationTimingFunction,
    CSSPropertyBackgroundAttachment,
    CSSPropertyBackgroundBlendMode,
    CSSPropertyBackgroundClip,
    CSSPropertyBackgroundColor,
    CSSPropertyBackgroundImage,
    CSSPropertyBackgroundOrigin,
    CSSPropertyBackgroundPosition, // more-specific background-position-x/y are non-standard
    CSSPropertyBackgroundRepeat,
    CSSPropertyBackgroundSize,
    CSSPropertyBorderBottomColor,
    CSSPropertyBorderBottomLeftRadius,
    CSSPropertyBorderBottomRightRadius,
    CSSPropertyBorderBottomStyle,
    CSSPropertyBorderBottomWidth,
    CSSPropertyBorderCollapse,
    CSSPropertyBorderImageOutset,
    CSSPropertyBorderImageRepeat,
    CSSPropertyBorderImageSlice,
    CSSPropertyBorderImageSource,
    CSSPropertyBorderImageWidth,
    CSSPropertyBorderLeftColor,
    CSSPropertyBorderLeftStyle,
    CSSPropertyBorderLeftWidth,
    CSSPropertyBorderRightColor,
    CSSPropertyBorderRightStyle,
    CSSPropertyBorderRightWidth,
    CSSPropertyBorderTopColor,
    CSSPropertyBorderTopLeftRadius,
    CSSPropertyBorderTopRightRadius,
    CSSPropertyBorderTopStyle,
    CSSPropertyBorderTopWidth,
    CSSPropertyBottom,
    CSSPropertyBoxShadow,
    CSSPropertyBoxSizing,
    CSSPropertyCaptionSide,
    CSSPropertyClear,
    CSSPropertyClip,
    CSSPropertyColor,
    CSSPropertyCursor,
    CSSPropertyDirection,
    CSSPropertyDisplay,
    CSSPropertyEmptyCells,
    CSSPropertyFloat,
    CSSPropertyFontFamily,
    CSSPropertyFontKerning,
    CSSPropertyFontSize,
    CSSPropertyFontStretch,
    CSSPropertyFontStyle,
    CSSPropertyFontVariant,
    CSSPropertyFontVariantLigatures,
    CSSPropertyFontWeight,
    CSSPropertyHeight,
    CSSPropertyImageRendering,
    CSSPropertyIsolation,
    CSSPropertyJustifyItems,
    CSSPropertyJustifySelf,
    CSSPropertyLeft,
    CSSPropertyLetterSpacing,
    CSSPropertyLineHeight,
    CSSPropertyListStyleImage,
    CSSPropertyListStylePosition,
    CSSPropertyListStyleType,
    CSSPropertyMarginBottom,
    CSSPropertyMarginLeft,
    CSSPropertyMarginRight,
    CSSPropertyMarginTop,
    CSSPropertyMaxHeight,
    CSSPropertyMaxWidth,
    CSSPropertyMinHeight,
    CSSPropertyMinWidth,
    CSSPropertyMixBlendMode,
    CSSPropertyObjectFit,
    CSSPropertyObjectPosition,
    CSSPropertyOpacity,
    CSSPropertyOrphans,
    CSSPropertyOutlineColor,
    CSSPropertyOutlineOffset,
    CSSPropertyOutlineStyle,
    CSSPropertyOutlineWidth,
    CSSPropertyOverflowWrap,
    CSSPropertyOverflowX,
    CSSPropertyOverflowY,
    CSSPropertyPaddingBottom,
    CSSPropertyPaddingLeft,
    CSSPropertyPaddingRight,
    CSSPropertyPaddingTop,
    CSSPropertyPageBreakAfter,
    CSSPropertyPageBreakBefore,
    CSSPropertyPageBreakInside,
    CSSPropertyPointerEvents,
    CSSPropertyPosition,
    CSSPropertyResize,
    CSSPropertyRight,
    CSSPropertyScrollBehavior,
    CSSPropertySpeak,
    CSSPropertyTableLayout,
    CSSPropertyTabSize,
    CSSPropertyTextAlign,
    CSSPropertyTextAlignLast,
    CSSPropertyTextDecoration,
    CSSPropertyTextDecorationLine,
    CSSPropertyTextDecorationStyle,
    CSSPropertyTextDecorationColor,
    CSSPropertyTextJustify,
    CSSPropertyTextUnderlinePosition,
    CSSPropertyTextIndent,
    CSSPropertyTextRendering,
    CSSPropertyTextShadow,
    CSSPropertyTextOverflow,
    CSSPropertyTop,
    CSSPropertyTouchAction,
    CSSPropertyTouchActionDelay,
    CSSPropertyTransitionDelay,
    CSSPropertyTransitionDuration,
    CSSPropertyTransitionProperty,
    CSSPropertyTransitionTimingFunction,
    CSSPropertyUnicodeBidi,
    CSSPropertyVerticalAlign,
    CSSPropertyWhiteSpace,
    CSSPropertyWidows,
    CSSPropertyWidth,
    CSSPropertyWillChange,
    CSSPropertyWordBreak,
    CSSPropertyWordSpacing,
    CSSPropertyWordWrap,
    CSSPropertyZIndex,
    CSSPropertyZoom,

    CSSPropertyWebkitAnimationDelay,
    CSSPropertyWebkitAnimationDirection,
    CSSPropertyWebkitAnimationDuration,
    CSSPropertyWebkitAnimationFillMode,
    CSSPropertyWebkitAnimationIterationCount,
    CSSPropertyWebkitAnimationName,
    CSSPropertyWebkitAnimationPlayState,
    CSSPropertyWebkitAnimationTimingFunction,
    CSSPropertyBackfaceVisibility,
    CSSPropertyWebkitBackfaceVisibility,
    CSSPropertyWebkitBackgroundClip,
    CSSPropertyWebkitBackgroundComposite,
    CSSPropertyWebkitBackgroundOrigin,
    CSSPropertyWebkitBackgroundSize,
    CSSPropertyWebkitBorderHorizontalSpacing,
    CSSPropertyWebkitBorderImage,
    CSSPropertyWebkitBorderVerticalSpacing,
    CSSPropertyWebkitBoxDecorationBreak,
    CSSPropertyWebkitBoxShadow,
    CSSPropertyWebkitClipPath,
    CSSPropertyWebkitFilter,
    CSSPropertyAlignContent,
    CSSPropertyAlignItems,
    CSSPropertyAlignSelf,
    CSSPropertyFlexBasis,
    CSSPropertyFlexGrow,
    CSSPropertyFlexShrink,
    CSSPropertyFlexDirection,
    CSSPropertyFlexWrap,
    CSSPropertyJustifyContent,
    CSSPropertyWebkitFontSmoothing,
    CSSPropertyGridAutoColumns,
    CSSPropertyGridAutoFlow,
    CSSPropertyGridAutoRows,
    CSSPropertyGridColumnEnd,
    CSSPropertyGridColumnStart,
    CSSPropertyGridTemplateAreas,
    CSSPropertyGridTemplateColumns,
    CSSPropertyGridTemplateRows,
    CSSPropertyGridRowEnd,
    CSSPropertyGridRowStart,
    CSSPropertyWebkitHighlight,
    CSSPropertyWebkitHyphenateCharacter,
    CSSPropertyWebkitLineBoxContain,
    CSSPropertyWebkitLineBreak,
    CSSPropertyWebkitLineClamp,
    CSSPropertyWebkitLocale,
    CSSPropertyWebkitMarginBeforeCollapse,
    CSSPropertyWebkitMarginAfterCollapse,
    CSSPropertyWebkitMaskBoxImage,
    CSSPropertyWebkitMaskBoxImageOutset,
    CSSPropertyWebkitMaskBoxImageRepeat,
    CSSPropertyWebkitMaskBoxImageSlice,
    CSSPropertyWebkitMaskBoxImageSource,
    CSSPropertyWebkitMaskBoxImageWidth,
    CSSPropertyWebkitMaskClip,
    CSSPropertyWebkitMaskComposite,
    CSSPropertyWebkitMaskImage,
    CSSPropertyWebkitMaskOrigin,
    CSSPropertyWebkitMaskPosition,
    CSSPropertyWebkitMaskRepeat,
    CSSPropertyWebkitMaskSize,
    CSSPropertyOrder,
    CSSPropertyPerspective,
    CSSPropertyWebkitPerspective,
    CSSPropertyPerspectiveOrigin,
    CSSPropertyWebkitPerspectiveOrigin,
    CSSPropertyWebkitPrintColorAdjust,
    CSSPropertyWebkitRtlOrdering,
    CSSPropertyShapeOutside,
    CSSPropertyShapeImageThreshold,
    CSSPropertyShapeMargin,
    CSSPropertyWebkitTapHighlightColor,
    CSSPropertyWebkitTextDecorationsInEffect,
    CSSPropertyWebkitTextEmphasisColor,
    CSSPropertyWebkitTextEmphasisPosition,
    CSSPropertyWebkitTextEmphasisStyle,
    CSSPropertyWebkitTextFillColor,
    CSSPropertyWebkitTextOrientation,
    CSSPropertyWebkitTextStrokeColor,
    CSSPropertyWebkitTextStrokeWidth,
    CSSPropertyTransform,
    CSSPropertyWebkitTransform,
    CSSPropertyTransformOrigin,
    CSSPropertyWebkitTransformOrigin,
    CSSPropertyTransformStyle,
    CSSPropertyWebkitTransformStyle,
    CSSPropertyWebkitTransitionDelay,
    CSSPropertyWebkitTransitionDuration,
    CSSPropertyWebkitTransitionProperty,
    CSSPropertyWebkitTransitionTimingFunction,
    CSSPropertyWebkitUserDrag,
    CSSPropertyWebkitUserModify,
    CSSPropertyWebkitUserSelect,
    CSSPropertyMaskSourceType,
};

static const Vector<CSSPropertyID>& computableProperties()
{
    DEFINE_STATIC_LOCAL(Vector<CSSPropertyID>, properties, ());
    if (properties.isEmpty())
        CSSPropertyMetadata::filterEnabledCSSPropertiesIntoVector(staticComputableProperties, WTF_ARRAY_LENGTH(staticComputableProperties), properties);
    return properties;
}

static CSSValueID valueForRepeatRule(int rule)
{
    switch (rule) {
        case RepeatImageRule:
            return CSSValueRepeat;
        case RoundImageRule:
            return CSSValueRound;
        case SpaceImageRule:
            return CSSValueSpace;
        default:
            return CSSValueStretch;
    }
}

static PassRefPtr<CSSBorderImageSliceValue> valueForNinePieceImageSlice(const NinePieceImage& image)
{
    // Create the slices.
    RefPtr<CSSPrimitiveValue> top = nullptr;
    RefPtr<CSSPrimitiveValue> right = nullptr;
    RefPtr<CSSPrimitiveValue> bottom = nullptr;
    RefPtr<CSSPrimitiveValue> left = nullptr;

    if (image.imageSlices().top().isPercent())
        top = cssValuePool().createValue(image.imageSlices().top().value(), CSSPrimitiveValue::CSS_PERCENTAGE);
    else
        top = cssValuePool().createValue(image.imageSlices().top().value(), CSSPrimitiveValue::CSS_NUMBER);

    if (image.imageSlices().right() == image.imageSlices().top() && image.imageSlices().bottom() == image.imageSlices().top()
        && image.imageSlices().left() == image.imageSlices().top()) {
        right = top;
        bottom = top;
        left = top;
    } else {
        if (image.imageSlices().right().isPercent())
            right = cssValuePool().createValue(image.imageSlices().right().value(), CSSPrimitiveValue::CSS_PERCENTAGE);
        else
            right = cssValuePool().createValue(image.imageSlices().right().value(), CSSPrimitiveValue::CSS_NUMBER);

        if (image.imageSlices().bottom() == image.imageSlices().top() && image.imageSlices().right() == image.imageSlices().left()) {
            bottom = top;
            left = right;
        } else {
            if (image.imageSlices().bottom().isPercent())
                bottom = cssValuePool().createValue(image.imageSlices().bottom().value(), CSSPrimitiveValue::CSS_PERCENTAGE);
            else
                bottom = cssValuePool().createValue(image.imageSlices().bottom().value(), CSSPrimitiveValue::CSS_NUMBER);

            if (image.imageSlices().left() == image.imageSlices().right())
                left = right;
            else {
                if (image.imageSlices().left().isPercent())
                    left = cssValuePool().createValue(image.imageSlices().left().value(), CSSPrimitiveValue::CSS_PERCENTAGE);
                else
                    left = cssValuePool().createValue(image.imageSlices().left().value(), CSSPrimitiveValue::CSS_NUMBER);
            }
        }
    }

    RefPtr<Quad> quad = Quad::create();
    quad->setTop(top);
    quad->setRight(right);
    quad->setBottom(bottom);
    quad->setLeft(left);

    return CSSBorderImageSliceValue::create(cssValuePool().createValue(quad.release()), image.fill());
}

static PassRefPtr<CSSPrimitiveValue> valueForNinePieceImageQuad(const BorderImageLengthBox& box, const RenderStyle& style)
{
    // Create the slices.
    RefPtr<CSSPrimitiveValue> top = nullptr;
    RefPtr<CSSPrimitiveValue> right = nullptr;
    RefPtr<CSSPrimitiveValue> bottom = nullptr;
    RefPtr<CSSPrimitiveValue> left = nullptr;

    if (box.top().isNumber())
        top = cssValuePool().createValue(box.top().number(), CSSPrimitiveValue::CSS_NUMBER);
    else
        top = cssValuePool().createValue(box.top().length(), style);

    if (box.right() == box.top() && box.bottom() == box.top() && box.left() == box.top()) {
        right = top;
        bottom = top;
        left = top;
    } else {
        if (box.right().isNumber())
            right = cssValuePool().createValue(box.right().number(), CSSPrimitiveValue::CSS_NUMBER);
        else
            right = cssValuePool().createValue(box.right().length(), style);

        if (box.bottom() == box.top() && box.right() == box.left()) {
            bottom = top;
            left = right;
        } else {
            if (box.bottom().isNumber())
                bottom = cssValuePool().createValue(box.bottom().number(), CSSPrimitiveValue::CSS_NUMBER);
            else
                bottom = cssValuePool().createValue(box.bottom().length(), style);

            if (box.left() == box.right())
                left = right;
            else {
                if (box.left().isNumber())
                    left = cssValuePool().createValue(box.left().number(), CSSPrimitiveValue::CSS_NUMBER);
                else
                    left = cssValuePool().createValue(box.left().length(), style);
            }
        }
    }

    RefPtr<Quad> quad = Quad::create();
    quad->setTop(top);
    quad->setRight(right);
    quad->setBottom(bottom);
    quad->setLeft(left);

    return cssValuePool().createValue(quad.release());
}

static PassRefPtr<CSSValue> valueForNinePieceImageRepeat(const NinePieceImage& image)
{
    RefPtr<CSSPrimitiveValue> horizontalRepeat = nullptr;
    RefPtr<CSSPrimitiveValue> verticalRepeat = nullptr;

    horizontalRepeat = cssValuePool().createIdentifierValue(valueForRepeatRule(image.horizontalRule()));
    if (image.horizontalRule() == image.verticalRule())
        verticalRepeat = horizontalRepeat;
    else
        verticalRepeat = cssValuePool().createIdentifierValue(valueForRepeatRule(image.verticalRule()));
    return cssValuePool().createValue(Pair::create(horizontalRepeat.release(), verticalRepeat.release(), Pair::DropIdenticalValues));
}

static PassRefPtr<CSSValue> valueForNinePieceImage(const NinePieceImage& image, const RenderStyle& style)
{
    if (!image.hasImage())
        return cssValuePool().createIdentifierValue(CSSValueNone);

    // Image first.
    RefPtr<CSSValue> imageValue = nullptr;
    if (image.image())
        imageValue = image.image()->cssValue();

    // Create the image slice.
    RefPtr<CSSBorderImageSliceValue> imageSlices = valueForNinePieceImageSlice(image);

    // Create the border area slices.
    RefPtr<CSSValue> borderSlices = valueForNinePieceImageQuad(image.borderSlices(), style);

    // Create the border outset.
    RefPtr<CSSValue> outset = valueForNinePieceImageQuad(image.outset(), style);

    // Create the repeat rules.
    RefPtr<CSSValue> repeat = valueForNinePieceImageRepeat(image);

    return createBorderImageValue(imageValue.release(), imageSlices.release(), borderSlices.release(), outset.release(), repeat.release());
}

inline static PassRefPtr<CSSPrimitiveValue> zoomAdjustedPixelValue(double value, const RenderStyle& style)
{
    return cssValuePool().createValue(adjustFloatForAbsoluteZoom(value, style), CSSPrimitiveValue::CSS_PX);
}

inline static PassRefPtr<CSSPrimitiveValue> zoomAdjustedNumberValue(double value, const RenderStyle& style)
{
    return cssValuePool().createValue(value / style.effectiveZoom(), CSSPrimitiveValue::CSS_NUMBER);
}

static PassRefPtr<CSSPrimitiveValue> zoomAdjustedPixelValueForLength(const Length& length, const RenderStyle& style)
{
    if (length.isFixed())
        return zoomAdjustedPixelValue(length.value(), style);
    return cssValuePool().createValue(length, style);
}

static PassRefPtr<CSSValueList> createPositionListForLayer(CSSPropertyID propertyID, const FillLayer& layer, const RenderStyle& style)
{
    RefPtr<CSSValueList> positionList = CSSValueList::createSpaceSeparated();
    if (layer.isBackgroundXOriginSet()) {
        ASSERT_UNUSED(propertyID, propertyID == CSSPropertyBackgroundPosition || propertyID == CSSPropertyWebkitMaskPosition);
        positionList->append(cssValuePool().createValue(layer.backgroundXOrigin()));
    }
    positionList->append(zoomAdjustedPixelValueForLength(layer.xPosition(), style));
    if (layer.isBackgroundYOriginSet()) {
        ASSERT(propertyID == CSSPropertyBackgroundPosition || propertyID == CSSPropertyWebkitMaskPosition);
        positionList->append(cssValuePool().createValue(layer.backgroundYOrigin()));
    }
    positionList->append(zoomAdjustedPixelValueForLength(layer.yPosition(), style));
    return positionList.release();
}

static PassRefPtr<CSSValue> valueForPositionOffset(RenderStyle& style, CSSPropertyID propertyID, const RenderObject* renderer)
{
    Length l;
    switch (propertyID) {
        case CSSPropertyLeft:
            l = style.left();
            break;
        case CSSPropertyRight:
            l = style.right();
            break;
        case CSSPropertyTop:
            l = style.top();
            break;
        case CSSPropertyBottom:
            l = style.bottom();
            break;
        default:
            return nullptr;
    }

    if (l.isPercent() && renderer && renderer->isBox()) {
        LayoutUnit containingBlockSize = (propertyID == CSSPropertyLeft || propertyID == CSSPropertyRight) ?
            toRenderBox(renderer)->containingBlockLogicalWidthForContent() :
            toRenderBox(renderer)->containingBlockLogicalHeightForContent(ExcludeMarginBorderPadding);
        return zoomAdjustedPixelValue(valueForLength(l, containingBlockSize), style);
    }
    if (l.isAuto()) {
        // FIXME: It's not enough to simply return "auto" values for one offset if the other side is defined.
        // In other words if left is auto and right is not auto, then left's computed value is negative right().
        // So we should get the opposite length unit and see if it is auto.
        return cssValuePool().createIdentifierValue(CSSValueAuto);
    }

    return zoomAdjustedPixelValueForLength(l, style);
}

PassRefPtr<CSSPrimitiveValue> CSSComputedStyleDeclaration::currentColorOrValidColor(const RenderStyle& style, const StyleColor& color) const
{
    // This function does NOT look at visited information, so that computed style doesn't expose that.
    return cssValuePool().createColorValue(color.resolve(style.color()).rgb());
}

static PassRefPtr<CSSValueList> valuesForBorderRadiusCorner(LengthSize radius, const RenderStyle& style)
{
    RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
    if (radius.width().type() == Percent)
        list->append(cssValuePool().createValue(radius.width().percent(), CSSPrimitiveValue::CSS_PERCENTAGE));
    else
        list->append(zoomAdjustedPixelValueForLength(radius.width(), style));
    if (radius.height().type() == Percent)
        list->append(cssValuePool().createValue(radius.height().percent(), CSSPrimitiveValue::CSS_PERCENTAGE));
    else
        list->append(zoomAdjustedPixelValueForLength(radius.height(), style));
    return list.release();
}

static PassRefPtr<CSSValue> valueForBorderRadiusCorner(LengthSize radius, const RenderStyle& style)
{
    RefPtr<CSSValueList> list = valuesForBorderRadiusCorner(radius, style);
    if (list->item(0)->equals(*list->item(1)))
        return list->item(0);
    return list.release();
}

static PassRefPtr<CSSValueList> valueForBorderRadiusShorthand(const RenderStyle& style)
{
    RefPtr<CSSValueList> list = CSSValueList::createSlashSeparated();

    bool showHorizontalBottomLeft = style.borderTopRightRadius().width() != style.borderBottomLeftRadius().width();
    bool showHorizontalBottomRight = showHorizontalBottomLeft || (style.borderBottomRightRadius().width() != style.borderTopLeftRadius().width());
    bool showHorizontalTopRight = showHorizontalBottomRight || (style.borderTopRightRadius().width() != style.borderTopLeftRadius().width());

    bool showVerticalBottomLeft = style.borderTopRightRadius().height() != style.borderBottomLeftRadius().height();
    bool showVerticalBottomRight = showVerticalBottomLeft || (style.borderBottomRightRadius().height() != style.borderTopLeftRadius().height());
    bool showVerticalTopRight = showVerticalBottomRight || (style.borderTopRightRadius().height() != style.borderTopLeftRadius().height());

    RefPtr<CSSValueList> topLeftRadius = valuesForBorderRadiusCorner(style.borderTopLeftRadius(), style);
    RefPtr<CSSValueList> topRightRadius = valuesForBorderRadiusCorner(style.borderTopRightRadius(), style);
    RefPtr<CSSValueList> bottomRightRadius = valuesForBorderRadiusCorner(style.borderBottomRightRadius(), style);
    RefPtr<CSSValueList> bottomLeftRadius = valuesForBorderRadiusCorner(style.borderBottomLeftRadius(), style);

    RefPtr<CSSValueList> horizontalRadii = CSSValueList::createSpaceSeparated();
    horizontalRadii->append(topLeftRadius->item(0));
    if (showHorizontalTopRight)
        horizontalRadii->append(topRightRadius->item(0));
    if (showHorizontalBottomRight)
        horizontalRadii->append(bottomRightRadius->item(0));
    if (showHorizontalBottomLeft)
        horizontalRadii->append(bottomLeftRadius->item(0));

    list->append(horizontalRadii.release());

    RefPtr<CSSValueList> verticalRadii = CSSValueList::createSpaceSeparated();
    verticalRadii->append(topLeftRadius->item(1));
    if (showVerticalTopRight)
        verticalRadii->append(topRightRadius->item(1));
    if (showVerticalBottomRight)
        verticalRadii->append(bottomRightRadius->item(1));
    if (showVerticalBottomLeft)
        verticalRadii->append(bottomLeftRadius->item(1));

    if (!verticalRadii->equals(*toCSSValueList(list->item(0))))
        list->append(verticalRadii.release());

    return list.release();
}

static LayoutRect sizingBox(RenderObject* renderer)
{
    if (!renderer->isBox())
        return LayoutRect();

    RenderBox* box = toRenderBox(renderer);
    return box->style()->boxSizing() == BORDER_BOX ? box->borderBoxRect() : box->computedCSSContentBoxRect();
}

static PassRefPtr<CSSTransformValue> valueForMatrixTransform(const TransformationMatrix& transform, const RenderStyle& style)
{
    RefPtr<CSSTransformValue> transformValue = nullptr;
    if (transform.isAffine()) {
        transformValue = CSSTransformValue::create(CSSTransformValue::MatrixTransformOperation);

        transformValue->append(cssValuePool().createValue(transform.a(), CSSPrimitiveValue::CSS_NUMBER));
        transformValue->append(cssValuePool().createValue(transform.b(), CSSPrimitiveValue::CSS_NUMBER));
        transformValue->append(cssValuePool().createValue(transform.c(), CSSPrimitiveValue::CSS_NUMBER));
        transformValue->append(cssValuePool().createValue(transform.d(), CSSPrimitiveValue::CSS_NUMBER));
        transformValue->append(zoomAdjustedNumberValue(transform.e(), style));
        transformValue->append(zoomAdjustedNumberValue(transform.f(), style));
    } else {
        transformValue = CSSTransformValue::create(CSSTransformValue::Matrix3DTransformOperation);

        transformValue->append(cssValuePool().createValue(transform.m11(), CSSPrimitiveValue::CSS_NUMBER));
        transformValue->append(cssValuePool().createValue(transform.m12(), CSSPrimitiveValue::CSS_NUMBER));
        transformValue->append(cssValuePool().createValue(transform.m13(), CSSPrimitiveValue::CSS_NUMBER));
        transformValue->append(cssValuePool().createValue(transform.m14(), CSSPrimitiveValue::CSS_NUMBER));

        transformValue->append(cssValuePool().createValue(transform.m21(), CSSPrimitiveValue::CSS_NUMBER));
        transformValue->append(cssValuePool().createValue(transform.m22(), CSSPrimitiveValue::CSS_NUMBER));
        transformValue->append(cssValuePool().createValue(transform.m23(), CSSPrimitiveValue::CSS_NUMBER));
        transformValue->append(cssValuePool().createValue(transform.m24(), CSSPrimitiveValue::CSS_NUMBER));

        transformValue->append(cssValuePool().createValue(transform.m31(), CSSPrimitiveValue::CSS_NUMBER));
        transformValue->append(cssValuePool().createValue(transform.m32(), CSSPrimitiveValue::CSS_NUMBER));
        transformValue->append(cssValuePool().createValue(transform.m33(), CSSPrimitiveValue::CSS_NUMBER));
        transformValue->append(cssValuePool().createValue(transform.m34(), CSSPrimitiveValue::CSS_NUMBER));

        transformValue->append(zoomAdjustedNumberValue(transform.m41(), style));
        transformValue->append(zoomAdjustedNumberValue(transform.m42(), style));
        transformValue->append(zoomAdjustedNumberValue(transform.m43(), style));
        transformValue->append(cssValuePool().createValue(transform.m44(), CSSPrimitiveValue::CSS_NUMBER));
    }

    return transformValue.release();
}

static PassRefPtr<CSSValue> computedTransform(RenderObject* renderer, const RenderStyle& style)
{
    if (!renderer || !renderer->hasTransform() || !style.hasTransform())
        return cssValuePool().createIdentifierValue(CSSValueNone);

    IntRect box;
    if (renderer->isBox())
        box = pixelSnappedIntRect(toRenderBox(renderer)->borderBoxRect());

    TransformationMatrix transform;
    style.applyTransform(transform, box.size(), RenderStyle::ExcludeTransformOrigin);

    // FIXME: Need to print out individual functions (https://bugs.webkit.org/show_bug.cgi?id=23924)
    RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
    list->append(valueForMatrixTransform(transform, style));

    return list.release();
}

PassRefPtr<CSSValue> CSSComputedStyleDeclaration::valueForFilter(const RenderObject* renderer, const RenderStyle& style) const
{
    if (style.filter().operations().isEmpty())
        return cssValuePool().createIdentifierValue(CSSValueNone);

    RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();

    RefPtr<CSSFilterValue> filterValue = nullptr;

    Vector<RefPtr<FilterOperation> >::const_iterator end = style.filter().operations().end();
    for (Vector<RefPtr<FilterOperation> >::const_iterator it = style.filter().operations().begin(); it != end; ++it) {
        FilterOperation* filterOperation = it->get();
        switch (filterOperation->type()) {
        case FilterOperation::REFERENCE:
            filterValue = CSSFilterValue::create(CSSFilterValue::ReferenceFilterOperation);
            filterValue->append(cssValuePool().createValue(toReferenceFilterOperation(filterOperation)->url(), CSSPrimitiveValue::CSS_STRING));
            break;
        case FilterOperation::GRAYSCALE:
            filterValue = CSSFilterValue::create(CSSFilterValue::GrayscaleFilterOperation);
            filterValue->append(cssValuePool().createValue(toBasicColorMatrixFilterOperation(filterOperation)->amount(), CSSPrimitiveValue::CSS_NUMBER));
            break;
        case FilterOperation::SEPIA:
            filterValue = CSSFilterValue::create(CSSFilterValue::SepiaFilterOperation);
            filterValue->append(cssValuePool().createValue(toBasicColorMatrixFilterOperation(filterOperation)->amount(), CSSPrimitiveValue::CSS_NUMBER));
            break;
        case FilterOperation::SATURATE:
            filterValue = CSSFilterValue::create(CSSFilterValue::SaturateFilterOperation);
            filterValue->append(cssValuePool().createValue(toBasicColorMatrixFilterOperation(filterOperation)->amount(), CSSPrimitiveValue::CSS_NUMBER));
            break;
        case FilterOperation::HUE_ROTATE:
            filterValue = CSSFilterValue::create(CSSFilterValue::HueRotateFilterOperation);
            filterValue->append(cssValuePool().createValue(toBasicColorMatrixFilterOperation(filterOperation)->amount(), CSSPrimitiveValue::CSS_DEG));
            break;
        case FilterOperation::INVERT:
            filterValue = CSSFilterValue::create(CSSFilterValue::InvertFilterOperation);
            filterValue->append(cssValuePool().createValue(toBasicComponentTransferFilterOperation(filterOperation)->amount(), CSSPrimitiveValue::CSS_NUMBER));
            break;
        case FilterOperation::OPACITY:
            filterValue = CSSFilterValue::create(CSSFilterValue::OpacityFilterOperation);
            filterValue->append(cssValuePool().createValue(toBasicComponentTransferFilterOperation(filterOperation)->amount(), CSSPrimitiveValue::CSS_NUMBER));
            break;
        case FilterOperation::BRIGHTNESS:
            filterValue = CSSFilterValue::create(CSSFilterValue::BrightnessFilterOperation);
            filterValue->append(cssValuePool().createValue(toBasicComponentTransferFilterOperation(filterOperation)->amount(), CSSPrimitiveValue::CSS_NUMBER));
            break;
        case FilterOperation::CONTRAST:
            filterValue = CSSFilterValue::create(CSSFilterValue::ContrastFilterOperation);
            filterValue->append(cssValuePool().createValue(toBasicComponentTransferFilterOperation(filterOperation)->amount(), CSSPrimitiveValue::CSS_NUMBER));
            break;
        case FilterOperation::BLUR:
            filterValue = CSSFilterValue::create(CSSFilterValue::BlurFilterOperation);
            filterValue->append(zoomAdjustedPixelValue(toBlurFilterOperation(filterOperation)->stdDeviation().value(), style));
            break;
        case FilterOperation::DROP_SHADOW: {
            DropShadowFilterOperation* dropShadowOperation = toDropShadowFilterOperation(filterOperation);
            filterValue = CSSFilterValue::create(CSSFilterValue::DropShadowFilterOperation);
            // We want our computed style to look like that of a text shadow (has neither spread nor inset style).
            ShadowData shadow(dropShadowOperation->location(), dropShadowOperation->stdDeviation(), 0, Normal, dropShadowOperation->color());
            filterValue->append(valueForShadowData(shadow, style, false));
            break;
        }
        default:
            filterValue = CSSFilterValue::create(CSSFilterValue::UnknownFilterOperation);
            break;
        }
        list->append(filterValue.release());
    }

    return list.release();
}

static PassRefPtr<CSSValue> specifiedValueForGridTrackBreadth(const GridLength& trackBreadth, const RenderStyle& style)
{
    if (!trackBreadth.isLength())
        return cssValuePool().createValue(trackBreadth.flex(), CSSPrimitiveValue::CSS_FR);

    const Length& trackBreadthLength = trackBreadth.length();
    if (trackBreadthLength.isAuto())
        return cssValuePool().createIdentifierValue(CSSValueAuto);
    return zoomAdjustedPixelValueForLength(trackBreadthLength, style);
}

static PassRefPtr<CSSValue> specifiedValueForGridTrackSize(const GridTrackSize& trackSize, const RenderStyle& style)
{
    switch (trackSize.type()) {
    case LengthTrackSizing:
        return specifiedValueForGridTrackBreadth(trackSize.length(), style);
    case MinMaxTrackSizing:
        RefPtr<CSSValueList> minMaxTrackBreadths = CSSValueList::createCommaSeparated();
        minMaxTrackBreadths->append(specifiedValueForGridTrackBreadth(trackSize.minTrackBreadth(), style));
        minMaxTrackBreadths->append(specifiedValueForGridTrackBreadth(trackSize.maxTrackBreadth(), style));
        return CSSFunctionValue::create("minmax(", minMaxTrackBreadths);
    }
    ASSERT_NOT_REACHED();
    return nullptr;
}

static void addValuesForNamedGridLinesAtIndex(const OrderedNamedGridLines& orderedNamedGridLines, size_t i, CSSValueList& list)
{
    const Vector<String>& namedGridLines = orderedNamedGridLines.get(i);
    if (namedGridLines.isEmpty())
        return;

    RefPtr<CSSGridLineNamesValue> lineNames = CSSGridLineNamesValue::create();
    for (size_t j = 0; j < namedGridLines.size(); ++j)
        lineNames->append(cssValuePool().createValue(namedGridLines[j], CSSPrimitiveValue::CSS_STRING));
    list.append(lineNames.release());
}

static PassRefPtr<CSSValue> valueForGridTrackList(GridTrackSizingDirection direction, RenderObject* renderer, const RenderStyle& style)
{
    const Vector<GridTrackSize>& trackSizes = direction == ForColumns ? style.gridTemplateColumns() : style.gridTemplateRows();
    const OrderedNamedGridLines& orderedNamedGridLines = direction == ForColumns ? style.orderedNamedGridColumnLines() : style.orderedNamedGridRowLines();

    // Handle the 'none' case here.
    if (!trackSizes.size()) {
        ASSERT(orderedNamedGridLines.isEmpty());
        return cssValuePool().createIdentifierValue(CSSValueNone);
    }

    RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
    if (renderer && renderer->isRenderGrid()) {
        const Vector<LayoutUnit>& trackPositions = direction == ForColumns ? toRenderGrid(renderer)->columnPositions() : toRenderGrid(renderer)->rowPositions();
        // There are at least #tracks + 1 grid lines (trackPositions). Apart from that, the grid container can generate implicit grid tracks,
        // so we'll have more trackPositions than trackSizes as the latter only contain the explicit grid.
        ASSERT(trackPositions.size() - 1 >= trackSizes.size());

        for (size_t i = 0; i < trackSizes.size(); ++i) {
            addValuesForNamedGridLinesAtIndex(orderedNamedGridLines, i, *list);
            list->append(zoomAdjustedPixelValue(trackPositions[i + 1] - trackPositions[i], style));
        }
    } else {
        for (size_t i = 0; i < trackSizes.size(); ++i) {
            addValuesForNamedGridLinesAtIndex(orderedNamedGridLines, i, *list);
            list->append(specifiedValueForGridTrackSize(trackSizes[i], style));
        }
    }
    // Those are the trailing <string>* allowed in the syntax.
    addValuesForNamedGridLinesAtIndex(orderedNamedGridLines, trackSizes.size(), *list);
    return list.release();
}

static PassRefPtr<CSSValue> valueForGridPosition(const GridPosition& position)
{
    if (position.isAuto())
        return cssValuePool().createIdentifierValue(CSSValueAuto);

    if (position.isNamedGridArea())
        return cssValuePool().createValue(position.namedGridLine(), CSSPrimitiveValue::CSS_STRING);

    RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
    if (position.isSpan()) {
        list->append(cssValuePool().createIdentifierValue(CSSValueSpan));
        list->append(cssValuePool().createValue(position.spanPosition(), CSSPrimitiveValue::CSS_NUMBER));
    } else
        list->append(cssValuePool().createValue(position.integerPosition(), CSSPrimitiveValue::CSS_NUMBER));

    if (!position.namedGridLine().isNull())
        list->append(cssValuePool().createValue(position.namedGridLine(), CSSPrimitiveValue::CSS_STRING));
    return list;
}

static PassRefPtr<CSSValue> createTransitionPropertyValue(const CSSTransitionData::TransitionProperty& property)
{
    if (property.propertyType == CSSTransitionData::TransitionNone)
        return cssValuePool().createIdentifierValue(CSSValueNone);
    if (property.propertyType == CSSTransitionData::TransitionAll)
        return cssValuePool().createIdentifierValue(CSSValueAll);
    if (property.propertyType == CSSTransitionData::TransitionUnknown)
        return cssValuePool().createValue(property.propertyString, CSSPrimitiveValue::CSS_STRING);
    ASSERT(property.propertyType == CSSTransitionData::TransitionSingleProperty);
    return cssValuePool().createValue(getPropertyNameString(property.propertyId), CSSPrimitiveValue::CSS_STRING);
}

static PassRefPtr<CSSValue> valueForTransitionProperty(const CSSTransitionData* transitionData)
{
    RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
    if (transitionData) {
        for (size_t i = 0; i < transitionData->propertyList().size(); ++i)
            list->append(createTransitionPropertyValue(transitionData->propertyList()[i]));
    } else {
        list->append(cssValuePool().createIdentifierValue(CSSValueAll));
    }
    return list.release();
}

static PassRefPtr<CSSValue> valueForAnimationDelay(const CSSTimingData* timingData)
{
    RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
    if (timingData) {
        for (size_t i = 0; i < timingData->delayList().size(); ++i)
            list->append(cssValuePool().createValue(timingData->delayList()[i], CSSPrimitiveValue::CSS_S));
    } else {
        list->append(cssValuePool().createValue(CSSTimingData::initialDelay(), CSSPrimitiveValue::CSS_S));
    }
    return list.release();
}

static PassRefPtr<CSSValue> valueForAnimationDuration(const CSSTimingData* timingData)
{
    RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
    if (timingData) {
        for (size_t i = 0; i < timingData->durationList().size(); ++i)
            list->append(cssValuePool().createValue(timingData->durationList()[i], CSSPrimitiveValue::CSS_S));
    } else {
        list->append(cssValuePool().createValue(CSSTimingData::initialDuration(), CSSPrimitiveValue::CSS_S));
    }
    return list.release();
}

static PassRefPtr<CSSValue> valueForAnimationIterationCount(double iterationCount)
{
    if (iterationCount == std::numeric_limits<double>::infinity())
        return cssValuePool().createIdentifierValue(CSSValueInfinite);
    return cssValuePool().createValue(iterationCount, CSSPrimitiveValue::CSS_NUMBER);
}

static PassRefPtr<CSSValue> valueForAnimationPlayState(EAnimPlayState playState)
{
    if (playState == AnimPlayStatePlaying)
        return cssValuePool().createIdentifierValue(CSSValueRunning);
    ASSERT(playState == AnimPlayStatePaused);
    return cssValuePool().createIdentifierValue(CSSValuePaused);
}

static PassRefPtr<CSSValue> createTimingFunctionValue(const TimingFunction* timingFunction)
{
    switch (timingFunction->type()) {
    case TimingFunction::CubicBezierFunction:
        {
            const CubicBezierTimingFunction* bezierTimingFunction = toCubicBezierTimingFunction(timingFunction);
            if (bezierTimingFunction->subType() != CubicBezierTimingFunction::Custom) {
                CSSValueID valueId = CSSValueInvalid;
                switch (bezierTimingFunction->subType()) {
                case CubicBezierTimingFunction::Ease:
                    valueId = CSSValueEase;
                    break;
                case CubicBezierTimingFunction::EaseIn:
                    valueId = CSSValueEaseIn;
                    break;
                case CubicBezierTimingFunction::EaseOut:
                    valueId = CSSValueEaseOut;
                    break;
                case CubicBezierTimingFunction::EaseInOut:
                    valueId = CSSValueEaseInOut;
                    break;
                default:
                    ASSERT_NOT_REACHED();
                    return nullptr;
                }
                return cssValuePool().createIdentifierValue(valueId);
            }
            return CSSCubicBezierTimingFunctionValue::create(bezierTimingFunction->x1(), bezierTimingFunction->y1(), bezierTimingFunction->x2(), bezierTimingFunction->y2());
        }

    case TimingFunction::StepsFunction:
        {
            const StepsTimingFunction* stepsTimingFunction = toStepsTimingFunction(timingFunction);
            if (stepsTimingFunction->subType() == StepsTimingFunction::Custom)
                return CSSStepsTimingFunctionValue::create(stepsTimingFunction->numberOfSteps(), stepsTimingFunction->stepAtPosition());

            CSSValueID valueId;
            switch (stepsTimingFunction->subType()) {
            case StepsTimingFunction::Start:
                valueId = CSSValueStepStart;
                break;
            case StepsTimingFunction::End:
                valueId = CSSValueStepEnd;
                break;
            default:
                ASSERT_NOT_REACHED();
                return nullptr;
            }
            return cssValuePool().createIdentifierValue(valueId);
        }

    default:
        return cssValuePool().createIdentifierValue(CSSValueLinear);
    }
}

static PassRefPtr<CSSValue> valueForAnimationTimingFunction(const CSSTimingData* timingData)
{
    RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
    if (timingData) {
        for (size_t i = 0; i < timingData->timingFunctionList().size(); ++i)
            list->append(createTimingFunctionValue(timingData->timingFunctionList()[i].get()));
    } else {
        list->append(createTimingFunctionValue(CSSTimingData::initialTimingFunction().get()));
    }
    return list.release();
}

static PassRefPtr<CSSValue> valueForAnimationFillMode(Timing::FillMode fillMode)
{
    switch (fillMode) {
    case Timing::FillModeNone:
        return cssValuePool().createIdentifierValue(CSSValueNone);
    case Timing::FillModeForwards:
        return cssValuePool().createIdentifierValue(CSSValueForwards);
    case Timing::FillModeBackwards:
        return cssValuePool().createIdentifierValue(CSSValueBackwards);
    case Timing::FillModeBoth:
        return cssValuePool().createIdentifierValue(CSSValueBoth);
    default:
        ASSERT_NOT_REACHED();
        return nullptr;
    }
}

static PassRefPtr<CSSValue> valueForAnimationDirection(Timing::PlaybackDirection direction)
{
    switch (direction) {
    case Timing::PlaybackDirectionNormal:
        return cssValuePool().createIdentifierValue(CSSValueNormal);
    case Timing::PlaybackDirectionAlternate:
        return cssValuePool().createIdentifierValue(CSSValueAlternate);
    case Timing::PlaybackDirectionReverse:
        return cssValuePool().createIdentifierValue(CSSValueReverse);
    case Timing::PlaybackDirectionAlternateReverse:
        return cssValuePool().createIdentifierValue(CSSValueAlternateReverse);
    default:
        ASSERT_NOT_REACHED();
        return nullptr;
    }
}

static PassRefPtr<CSSValue> valueForWillChange(const Vector<CSSPropertyID>& willChangeProperties, bool willChangeContents, bool willChangeScrollPosition)
{
    RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
    if (willChangeContents)
        list->append(cssValuePool().createIdentifierValue(CSSValueContents));
    if (willChangeScrollPosition)
        list->append(cssValuePool().createIdentifierValue(CSSValueScrollPosition));
    for (size_t i = 0; i < willChangeProperties.size(); ++i)
        list->append(cssValuePool().createIdentifierValue(willChangeProperties[i]));
    if (!list->length())
        list->append(cssValuePool().createIdentifierValue(CSSValueAuto));
    return list.release();
}

static PassRefPtr<CSSValue> createLineBoxContainValue(unsigned lineBoxContain)
{
    if (!lineBoxContain)
        return cssValuePool().createIdentifierValue(CSSValueNone);
    return CSSLineBoxContainValue::create(lineBoxContain);
}

CSSComputedStyleDeclaration::CSSComputedStyleDeclaration(PassRefPtr<Node> n, bool allowVisitedStyle, const String& pseudoElementName)
    : m_node(n)
    , m_allowVisitedStyle(allowVisitedStyle)
#if !ENABLE(OILPAN)
    , m_refCount(1)
#endif
{
    unsigned nameWithoutColonsStart = pseudoElementName[0] == ':' ? (pseudoElementName[1] == ':' ? 2 : 1) : 0;
    m_pseudoElementSpecifier = CSSSelector::pseudoId(CSSSelector::parsePseudoType(
        AtomicString(pseudoElementName.substring(nameWithoutColonsStart))));
}

CSSComputedStyleDeclaration::~CSSComputedStyleDeclaration()
{
}

#if !ENABLE(OILPAN)
void CSSComputedStyleDeclaration::ref()
{
    ++m_refCount;
}

void CSSComputedStyleDeclaration::deref()
{
    ASSERT(m_refCount);
    if (!--m_refCount)
        delete this;
}
#endif

String CSSComputedStyleDeclaration::cssText() const
{
    StringBuilder result;
    const Vector<CSSPropertyID>& properties = computableProperties();

    for (unsigned i = 0; i < properties.size(); i++) {
        if (i)
            result.append(' ');
        result.append(getPropertyName(properties[i]));
        result.appendLiteral(": ");
        result.append(getPropertyValue(properties[i]));
        result.append(';');
    }

    return result.toString();
}

void CSSComputedStyleDeclaration::setCSSText(const String&, ExceptionState& exceptionState)
{
    exceptionState.throwDOMException(NoModificationAllowedError, "These styles are computed, and therefore read-only.");
}

static CSSValueID cssIdentifierForFontSizeKeyword(int keywordSize)
{
    ASSERT_ARG(keywordSize, keywordSize);
    ASSERT_ARG(keywordSize, keywordSize <= 8);
    return static_cast<CSSValueID>(CSSValueXxSmall + keywordSize - 1);
}

PassRefPtr<CSSValue> CSSComputedStyleDeclaration::getFontSizeCSSValuePreferringKeyword() const
{
    if (!m_node)
        return nullptr;

    m_node->document().updateLayoutIgnorePendingStylesheets();

    RefPtr<RenderStyle> style = m_node->computedStyle(m_pseudoElementSpecifier);
    if (!style)
        return nullptr;

    if (int keywordSize = style->fontDescription().keywordSize())
        return cssValuePool().createIdentifierValue(cssIdentifierForFontSizeKeyword(keywordSize));


    return zoomAdjustedPixelValue(style->fontDescription().computedPixelSize(), *style);
}

FixedPitchFontType CSSComputedStyleDeclaration::fixedPitchFontType() const
{
    if (!m_node)
        return NonFixedPitchFont;

    RefPtr<RenderStyle> style = m_node->computedStyle(m_pseudoElementSpecifier);
    if (!style)
        return NonFixedPitchFont;

    return style->fontDescription().fixedPitchFontType();
}

PassRefPtr<CSSValue> CSSComputedStyleDeclaration::valueForShadowData(const ShadowData& shadow, const RenderStyle& style, bool useSpread) const
{
    RefPtr<CSSPrimitiveValue> x = zoomAdjustedPixelValue(shadow.x(), style);
    RefPtr<CSSPrimitiveValue> y = zoomAdjustedPixelValue(shadow.y(), style);
    RefPtr<CSSPrimitiveValue> blur = zoomAdjustedPixelValue(shadow.blur(), style);
    RefPtr<CSSPrimitiveValue> spread = useSpread ? zoomAdjustedPixelValue(shadow.spread(), style) : PassRefPtr<CSSPrimitiveValue>(nullptr);
    RefPtr<CSSPrimitiveValue> shadowStyle = shadow.style() == Normal ? PassRefPtr<CSSPrimitiveValue>(nullptr) : cssValuePool().createIdentifierValue(CSSValueInset);
    RefPtr<CSSPrimitiveValue> color = currentColorOrValidColor(style, shadow.color());
    return CSSShadowValue::create(x.release(), y.release(), blur.release(), spread.release(), shadowStyle.release(), color.release());
}

PassRefPtr<CSSValue> CSSComputedStyleDeclaration::valueForShadowList(const ShadowList* shadowList, const RenderStyle& style, bool useSpread) const
{
    if (!shadowList)
        return cssValuePool().createIdentifierValue(CSSValueNone);

    RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
    size_t shadowCount = shadowList->shadows().size();
    for (size_t i = 0; i < shadowCount; ++i)
        list->append(valueForShadowData(shadowList->shadows()[i], style, useSpread));
    return list.release();
}

static CSSValueID identifierForFamily(const AtomicString& family)
{
    if (family == FontFamilyNames::webkit_cursive)
        return CSSValueCursive;
    if (family == FontFamilyNames::webkit_fantasy)
        return CSSValueFantasy;
    if (family == FontFamilyNames::webkit_monospace)
        return CSSValueMonospace;
    if (family == FontFamilyNames::webkit_pictograph)
        return CSSValueWebkitPictograph;
    if (family == FontFamilyNames::webkit_sans_serif)
        return CSSValueSansSerif;
    if (family == FontFamilyNames::webkit_serif)
        return CSSValueSerif;
    return CSSValueInvalid;
}

static PassRefPtr<CSSPrimitiveValue> valueForFamily(const AtomicString& family)
{
    if (CSSValueID familyIdentifier = identifierForFamily(family))
        return cssValuePool().createIdentifierValue(familyIdentifier);
    return cssValuePool().createValue(family.string(), CSSPrimitiveValue::CSS_STRING);
}

static PassRefPtr<CSSValue> renderTextDecorationFlagsToCSSValue(int textDecoration)
{
    // Blink value is ignored.
    RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
    if (textDecoration & TextDecorationUnderline)
        list->append(cssValuePool().createIdentifierValue(CSSValueUnderline));
    if (textDecoration & TextDecorationOverline)
        list->append(cssValuePool().createIdentifierValue(CSSValueOverline));
    if (textDecoration & TextDecorationLineThrough)
        list->append(cssValuePool().createIdentifierValue(CSSValueLineThrough));

    if (!list->length())
        return cssValuePool().createIdentifierValue(CSSValueNone);
    return list.release();
}

static PassRefPtr<CSSValue> valueForTextDecorationStyle(TextDecorationStyle textDecorationStyle)
{
    switch (textDecorationStyle) {
    case TextDecorationStyleSolid:
        return cssValuePool().createIdentifierValue(CSSValueSolid);
    case TextDecorationStyleDouble:
        return cssValuePool().createIdentifierValue(CSSValueDouble);
    case TextDecorationStyleDotted:
        return cssValuePool().createIdentifierValue(CSSValueDotted);
    case TextDecorationStyleDashed:
        return cssValuePool().createIdentifierValue(CSSValueDashed);
    case TextDecorationStyleWavy:
        return cssValuePool().createIdentifierValue(CSSValueWavy);
    }

    ASSERT_NOT_REACHED();
    return cssValuePool().createExplicitInitialValue();
}

static PassRefPtr<CSSValue> valueForFillRepeat(EFillRepeat xRepeat, EFillRepeat yRepeat)
{
    // For backwards compatibility, if both values are equal, just return one of them. And
    // if the two values are equivalent to repeat-x or repeat-y, just return the shorthand.
    if (xRepeat == yRepeat)
        return cssValuePool().createValue(xRepeat);
    if (xRepeat == RepeatFill && yRepeat == NoRepeatFill)
        return cssValuePool().createIdentifierValue(CSSValueRepeatX);
    if (xRepeat == NoRepeatFill && yRepeat == RepeatFill)
        return cssValuePool().createIdentifierValue(CSSValueRepeatY);

    RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
    list->append(cssValuePool().createValue(xRepeat));
    list->append(cssValuePool().createValue(yRepeat));
    return list.release();
}

static PassRefPtr<CSSValue> valueForFillSourceType(EMaskSourceType type)
{
    switch (type) {
    case MaskAlpha:
        return cssValuePool().createValue(CSSValueAlpha);
    case MaskLuminance:
        return cssValuePool().createValue(CSSValueLuminance);
    }

    ASSERT_NOT_REACHED();

    return nullptr;
}

static PassRefPtr<CSSValue> valueForFillSize(const FillSize& fillSize, const RenderStyle& style)
{
    if (fillSize.type == Contain)
        return cssValuePool().createIdentifierValue(CSSValueContain);

    if (fillSize.type == Cover)
        return cssValuePool().createIdentifierValue(CSSValueCover);

    if (fillSize.size.height().isAuto())
        return zoomAdjustedPixelValueForLength(fillSize.size.width(), style);

    RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
    list->append(zoomAdjustedPixelValueForLength(fillSize.size.width(), style));
    list->append(zoomAdjustedPixelValueForLength(fillSize.size.height(), style));
    return list.release();
}

static PassRefPtr<CSSValue> valueForContentData(const RenderStyle& style)
{
    RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
    for (const ContentData* contentData = style.contentData(); contentData; contentData = contentData->next()) {
        if (contentData->isImage()) {
            const StyleImage* image = toImageContentData(contentData)->image();
            ASSERT(image);
            list->append(image->cssValue());
        } else if (contentData->isText()) {
            list->append(cssValuePool().createValue(toTextContentData(contentData)->text(), CSSPrimitiveValue::CSS_STRING));
        }
    }
    return list.release();
}

static void logUnimplementedPropertyID(CSSPropertyID propertyID)
{
    DEFINE_STATIC_LOCAL(HashSet<CSSPropertyID>, propertyIDSet, ());
    if (!propertyIDSet.add(propertyID).isNewEntry)
        return;

    WTF_LOG_ERROR("WebKit does not yet implement getComputedStyle for '%s'.", getPropertyName(propertyID));
}

static PassRefPtr<CSSValueList> valueForFontFamily(RenderStyle& style)
{
    const FontFamily& firstFamily = style.fontDescription().family();
    RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
    for (const FontFamily* family = &firstFamily; family; family = family->next())
        list->append(valueForFamily(family->family()));
    return list.release();
}

static PassRefPtr<CSSPrimitiveValue> valueForLineHeight(RenderStyle& style)
{
    Length length = style.lineHeight();
    if (length.isNegative())
        return cssValuePool().createIdentifierValue(CSSValueNormal);

    return zoomAdjustedPixelValue(floatValueForLength(length, style.fontDescription().specifiedSize()), style);
}

static PassRefPtr<CSSPrimitiveValue> valueForFontSize(RenderStyle& style)
{
    return zoomAdjustedPixelValue(style.fontDescription().computedPixelSize(), style);
}

static PassRefPtr<CSSPrimitiveValue> valueForFontStretch(RenderStyle& style)
{
    return cssValuePool().createValue(style.fontDescription().stretch());
}

static PassRefPtr<CSSPrimitiveValue> valueForFontStyle(RenderStyle& style)
{
    return cssValuePool().createValue(style.fontDescription().style());
}

static PassRefPtr<CSSPrimitiveValue> valueForFontVariant(RenderStyle& style)
{
    return cssValuePool().createValue(style.fontDescription().variant());
}

static PassRefPtr<CSSPrimitiveValue> valueForFontWeight(RenderStyle& style)
{
    return cssValuePool().createValue(style.fontDescription().weight());
}

static PassRefPtr<CSSValue> valueForShape(const RenderStyle& style, ShapeValue* shapeValue)
{
    if (!shapeValue)
        return cssValuePool().createIdentifierValue(CSSValueNone);
    if (shapeValue->type() == ShapeValue::Box)
        return cssValuePool().createValue(shapeValue->cssBox());
    if (shapeValue->type() == ShapeValue::Image) {
        if (shapeValue->image())
            return shapeValue->image()->cssValue();
        return cssValuePool().createIdentifierValue(CSSValueNone);
    }

    ASSERT(shapeValue->type() == ShapeValue::Shape);

    RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
    list->append(valueForBasicShape(style, shapeValue->shape()));
    if (shapeValue->cssBox() != BoxMissing)
        list->append(cssValuePool().createValue(shapeValue->cssBox()));
    return list.release();
}

static PassRefPtr<CSSValue> touchActionFlagsToCSSValue(TouchAction touchAction)
{
    RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
    if (touchAction == TouchActionAuto)
        list->append(cssValuePool().createIdentifierValue(CSSValueAuto));
    if (touchAction & TouchActionNone) {
        ASSERT(touchAction == TouchActionNone);
        list->append(cssValuePool().createIdentifierValue(CSSValueNone));
    }
    if (touchAction == (TouchActionPanX | TouchActionPanY | TouchActionPinchZoom)) {
        list->append(cssValuePool().createIdentifierValue(CSSValueManipulation));
    } else {
        if (touchAction & TouchActionPanX)
            list->append(cssValuePool().createIdentifierValue(CSSValuePanX));
        if (touchAction & TouchActionPanY)
            list->append(cssValuePool().createIdentifierValue(CSSValuePanY));
    }
    ASSERT(list->length());
    return list.release();
}

static bool isLayoutDependent(CSSPropertyID propertyID, PassRefPtr<RenderStyle> style, RenderObject* renderer)
{
    // Some properties only depend on layout in certain conditions which
    // are specified in the main switch statement below. So we can avoid
    // forcing layout in those conditions. The conditions in this switch
    // statement must remain in sync with the conditions in the main switch.
    // FIXME: Some of these cases could be narrowed down or optimized better.
    switch (propertyID) {
    case CSSPropertyBottom:
    case CSSPropertyGridTemplateColumns:
    case CSSPropertyGridTemplateRows:
    case CSSPropertyHeight:
    case CSSPropertyLeft:
    case CSSPropertyRight:
    case CSSPropertyTop:
    case CSSPropertyPerspectiveOrigin:
    case CSSPropertyWebkitPerspectiveOrigin:
    case CSSPropertyTransform:
    case CSSPropertyWebkitTransform:
    case CSSPropertyTransformOrigin:
    case CSSPropertyWebkitTransformOrigin:
    case CSSPropertyWidth:
    case CSSPropertyWebkitFilter:
        return true;
    case CSSPropertyMargin:
        return renderer && renderer->isBox() && (!style || !style->marginBottom().isFixed() || !style->marginTop().isFixed() || !style->marginLeft().isFixed() || !style->marginRight().isFixed());
    case CSSPropertyMarginLeft:
        return renderer && renderer->isBox() && (!style || !style->marginLeft().isFixed());
    case CSSPropertyMarginRight:
        return renderer && renderer->isBox() && (!style || !style->marginRight().isFixed());
    case CSSPropertyMarginTop:
        return renderer && renderer->isBox() && (!style || !style->marginTop().isFixed());
    case CSSPropertyMarginBottom:
        return renderer && renderer->isBox() && (!style || !style->marginBottom().isFixed());
    case CSSPropertyPadding:
        return renderer && renderer->isBox() && (!style || !style->paddingBottom().isFixed() || !style->paddingTop().isFixed() || !style->paddingLeft().isFixed() || !style->paddingRight().isFixed());
    case CSSPropertyPaddingBottom:
        return renderer && renderer->isBox() && (!style || !style->paddingBottom().isFixed());
    case CSSPropertyPaddingLeft:
        return renderer && renderer->isBox() && (!style || !style->paddingLeft().isFixed());
    case CSSPropertyPaddingRight:
        return renderer && renderer->isBox() && (!style || !style->paddingRight().isFixed());
    case CSSPropertyPaddingTop:
        return renderer && renderer->isBox() && (!style || !style->paddingTop().isFixed());
    default:
        return false;
    }
}

PassRefPtr<RenderStyle> CSSComputedStyleDeclaration::computeRenderStyle(CSSPropertyID propertyID) const
{
    return m_node->computedStyle(m_pseudoElementSpecifier);
}

static ItemPosition resolveAlignmentAuto(ItemPosition position, Node* element)
{
    if (position != ItemPositionAuto)
        return position;

    bool isFlexOrGrid = element && element->computedStyle()
        && element->computedStyle()->isDisplayFlexibleOrGridBox();

    return isFlexOrGrid ? ItemPositionStretch : ItemPositionStart;
}

static PassRefPtr<CSSValueList> valueForItemPositionWithOverflowAlignment(ItemPosition itemPosition, OverflowAlignment overflowAlignment, ItemPositionType positionType)
{
    RefPtr<CSSValueList> result = CSSValueList::createSpaceSeparated();
    if (positionType == LegacyPosition)
        result->append(CSSPrimitiveValue::createIdentifier(CSSValueLegacy));
    result->append(CSSPrimitiveValue::create(itemPosition));
    if (itemPosition >= ItemPositionCenter && overflowAlignment != OverflowAlignmentDefault)
        result->append(CSSPrimitiveValue::create(overflowAlignment));
    ASSERT(result->length() <= 2);
    return result.release();
}

PassRefPtr<CSSValue> CSSComputedStyleDeclaration::getPropertyCSSValue(CSSPropertyID propertyID, EUpdateLayout updateLayout) const
{
    if (!m_node)
        return nullptr;
    RenderObject* renderer = m_node->renderer();
    RefPtr<RenderStyle> style;

    if (updateLayout) {
        Document& document = m_node->document();

        // A timing update may be required if a compositor animation is running.
        DocumentAnimations::updateAnimationTimingForGetComputedStyle(*m_node, propertyID);

        document.updateRenderTreeForNodeIfNeeded(m_node.get());
        renderer = m_node->renderer();

        style = computeRenderStyle(propertyID);

        bool forceFullLayout = isLayoutDependent(propertyID, style, renderer) || m_node->isInShadowTree();

        if (forceFullLayout) {
            document.updateLayoutIgnorePendingStylesheets();
            style = computeRenderStyle(propertyID);
            renderer = m_node->renderer();
        }
    } else {
        style = computeRenderStyle(propertyID);
    }

    if (!style)
        return nullptr;

    propertyID = CSSProperty::resolveDirectionAwareProperty(propertyID, style->direction());

    switch (propertyID) {
        case CSSPropertyInvalid:
            break;

        case CSSPropertyBackgroundColor:
            return m_allowVisitedStyle ? cssValuePool().createColorValue(style->colorIncludingFallback(CSSPropertyBackgroundColor).rgb()) : currentColorOrValidColor(*style, style->backgroundColor());
        case CSSPropertyBackgroundImage:
        case CSSPropertyWebkitMaskImage: {
            RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
            const FillLayer* currLayer = propertyID == CSSPropertyWebkitMaskImage ? &style->maskLayers() : &style->backgroundLayers();
            for (; currLayer; currLayer = currLayer->next()) {
                if (currLayer->image())
                    list->append(currLayer->image()->cssValue());
                else
                    list->append(cssValuePool().createIdentifierValue(CSSValueNone));
            }
            return list.release();
        }
        case CSSPropertyBackgroundSize:
        case CSSPropertyWebkitBackgroundSize:
        case CSSPropertyWebkitMaskSize: {
            RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
            const FillLayer* currLayer = propertyID == CSSPropertyWebkitMaskSize ? &style->maskLayers() : &style->backgroundLayers();
            for (; currLayer; currLayer = currLayer->next())
                list->append(valueForFillSize(currLayer->size(), *style));
            return list.release();
        }
        case CSSPropertyBackgroundRepeat:
        case CSSPropertyWebkitMaskRepeat: {
            RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
            const FillLayer* currLayer = propertyID == CSSPropertyWebkitMaskRepeat ? &style->maskLayers() : &style->backgroundLayers();
            for (; currLayer; currLayer = currLayer->next())
                list->append(valueForFillRepeat(currLayer->repeatX(), currLayer->repeatY()));
            return list.release();
        }
        case CSSPropertyMaskSourceType: {
            RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
            for (const FillLayer* currLayer = &style->maskLayers(); currLayer; currLayer = currLayer->next())
                list->append(valueForFillSourceType(currLayer->maskSourceType()));
            return list.release();
        }
        case CSSPropertyWebkitBackgroundComposite:
        case CSSPropertyWebkitMaskComposite: {
            RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
            const FillLayer* currLayer = propertyID == CSSPropertyWebkitMaskComposite ? &style->maskLayers() : &style->backgroundLayers();
            for (; currLayer; currLayer = currLayer->next())
                list->append(cssValuePool().createValue(currLayer->composite()));
            return list.release();
        }
        case CSSPropertyBackgroundAttachment: {
            RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
            for (const FillLayer* currLayer = &style->backgroundLayers(); currLayer; currLayer = currLayer->next())
                list->append(cssValuePool().createValue(currLayer->attachment()));
            return list.release();
        }
        case CSSPropertyBackgroundClip:
        case CSSPropertyBackgroundOrigin:
        case CSSPropertyWebkitBackgroundClip:
        case CSSPropertyWebkitBackgroundOrigin:
        case CSSPropertyWebkitMaskClip:
        case CSSPropertyWebkitMaskOrigin: {
            bool isClip = propertyID == CSSPropertyBackgroundClip || propertyID == CSSPropertyWebkitBackgroundClip || propertyID == CSSPropertyWebkitMaskClip;
            RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
            const FillLayer* currLayer = (propertyID == CSSPropertyWebkitMaskClip || propertyID == CSSPropertyWebkitMaskOrigin) ? &style->maskLayers() : &style->backgroundLayers();
            for (; currLayer; currLayer = currLayer->next()) {
                EFillBox box = isClip ? currLayer->clip() : currLayer->origin();
                list->append(cssValuePool().createValue(box));
            }
            return list.release();
        }
        case CSSPropertyBackgroundPosition:
        case CSSPropertyWebkitMaskPosition: {
            RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
            const FillLayer* currLayer = propertyID == CSSPropertyWebkitMaskPosition ? &style->maskLayers() : &style->backgroundLayers();
            for (; currLayer; currLayer = currLayer->next())
                list->append(createPositionListForLayer(propertyID, *currLayer, *style));
            return list.release();
        }
        case CSSPropertyBackgroundPositionX:
        case CSSPropertyWebkitMaskPositionX: {
            RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
            const FillLayer* currLayer = propertyID == CSSPropertyWebkitMaskPositionX ? &style->maskLayers() : &style->backgroundLayers();
            for (; currLayer; currLayer = currLayer->next())
                list->append(zoomAdjustedPixelValueForLength(currLayer->xPosition(), *style));
            return list.release();
        }
        case CSSPropertyBackgroundPositionY:
        case CSSPropertyWebkitMaskPositionY: {
            RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
            const FillLayer* currLayer = propertyID == CSSPropertyWebkitMaskPositionY ? &style->maskLayers() : &style->backgroundLayers();
            for (; currLayer; currLayer = currLayer->next())
                list->append(zoomAdjustedPixelValueForLength(currLayer->yPosition(), *style));
            return list.release();
        }
        case CSSPropertyBorderCollapse:
            if (style->borderCollapse())
                return cssValuePool().createIdentifierValue(CSSValueCollapse);
            return cssValuePool().createIdentifierValue(CSSValueSeparate);
        case CSSPropertyBorderSpacing: {
            RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
            list->append(zoomAdjustedPixelValue(style->horizontalBorderSpacing(), *style));
            list->append(zoomAdjustedPixelValue(style->verticalBorderSpacing(), *style));
            return list.release();
        }
        case CSSPropertyWebkitBorderHorizontalSpacing:
            return zoomAdjustedPixelValue(style->horizontalBorderSpacing(), *style);
        case CSSPropertyWebkitBorderVerticalSpacing:
            return zoomAdjustedPixelValue(style->verticalBorderSpacing(), *style);
        case CSSPropertyBorderImageSource:
            if (style->borderImageSource())
                return style->borderImageSource()->cssValue();
            return cssValuePool().createIdentifierValue(CSSValueNone);
        case CSSPropertyBorderTopColor:
            return m_allowVisitedStyle ? cssValuePool().createColorValue(style->colorIncludingFallback(CSSPropertyBorderTopColor).rgb()) : currentColorOrValidColor(*style, style->borderTopColor());
        case CSSPropertyBorderRightColor:
            return m_allowVisitedStyle ? cssValuePool().createColorValue(style->colorIncludingFallback(CSSPropertyBorderRightColor).rgb()) : currentColorOrValidColor(*style, style->borderRightColor());
        case CSSPropertyBorderBottomColor:
            return m_allowVisitedStyle ? cssValuePool().createColorValue(style->colorIncludingFallback(CSSPropertyBorderBottomColor).rgb()) : currentColorOrValidColor(*style, style->borderBottomColor());
        case CSSPropertyBorderLeftColor:
            return m_allowVisitedStyle ? cssValuePool().createColorValue(style->colorIncludingFallback(CSSPropertyBorderLeftColor).rgb()) : currentColorOrValidColor(*style, style->borderLeftColor());
        case CSSPropertyBorderTopStyle:
            return cssValuePool().createValue(style->borderTopStyle());
        case CSSPropertyBorderRightStyle:
            return cssValuePool().createValue(style->borderRightStyle());
        case CSSPropertyBorderBottomStyle:
            return cssValuePool().createValue(style->borderBottomStyle());
        case CSSPropertyBorderLeftStyle:
            return cssValuePool().createValue(style->borderLeftStyle());
        case CSSPropertyBorderTopWidth:
            return zoomAdjustedPixelValue(style->borderTopWidth(), *style);
        case CSSPropertyBorderRightWidth:
            return zoomAdjustedPixelValue(style->borderRightWidth(), *style);
        case CSSPropertyBorderBottomWidth:
            return zoomAdjustedPixelValue(style->borderBottomWidth(), *style);
        case CSSPropertyBorderLeftWidth:
            return zoomAdjustedPixelValue(style->borderLeftWidth(), *style);
        case CSSPropertyBottom:
            return valueForPositionOffset(*style, CSSPropertyBottom, renderer);
        case CSSPropertyWebkitBoxDecorationBreak:
            if (style->boxDecorationBreak() == DSLICE)
                return cssValuePool().createIdentifierValue(CSSValueSlice);
            return cssValuePool().createIdentifierValue(CSSValueClone);
        case CSSPropertyBoxShadow:
        case CSSPropertyWebkitBoxShadow:
            return valueForShadowList(style->boxShadow(), *style, true);
        case CSSPropertyCaptionSide:
            return cssValuePool().createValue(style->captionSide());
        case CSSPropertyClear:
            return cssValuePool().createValue(style->clear());
        case CSSPropertyColor:
            return cssValuePool().createColorValue(m_allowVisitedStyle ? style->colorIncludingFallback(CSSPropertyColor).rgb() : style->color().rgb());
        case CSSPropertyWebkitPrintColorAdjust:
            return cssValuePool().createValue(style->printColorAdjust());
        case CSSPropertyTabSize:
            return cssValuePool().createValue(style->tabSize(), CSSPrimitiveValue::CSS_NUMBER);
        case CSSPropertyCursor: {
            RefPtr<CSSValueList> list = nullptr;
            CursorList* cursors = style->cursors();
            if (cursors && cursors->size() > 0) {
                list = CSSValueList::createCommaSeparated();
                for (unsigned i = 0; i < cursors->size(); ++i)
                    if (StyleImage* image = cursors->at(i).image())
                        list->append(image->cssValue());
            }
            RefPtr<CSSValue> value = cssValuePool().createValue(style->cursor());
            if (list) {
                list->append(value.release());
                return list.release();
            }
            return value.release();
        }
        case CSSPropertyDirection:
            return cssValuePool().createValue(style->direction());
        case CSSPropertyDisplay:
            return cssValuePool().createValue(style->display());
        case CSSPropertyEmptyCells:
            return cssValuePool().createValue(style->emptyCells());
        case CSSPropertyAlignContent:
            return cssValuePool().createValue(style->alignContent());
        case CSSPropertyAlignItems:
            return valueForItemPositionWithOverflowAlignment(resolveAlignmentAuto(style->alignItems(), m_node.get()), style->alignItemsOverflowAlignment(), NonLegacyPosition);
        case CSSPropertyAlignSelf:
            return valueForItemPositionWithOverflowAlignment(resolveAlignmentAuto(style->alignSelf(), m_node->parentNode()), style->alignSelfOverflowAlignment(), NonLegacyPosition);
        case CSSPropertyFlex:
            return valuesForShorthandProperty(flexShorthand());
        case CSSPropertyFlexBasis:
            return zoomAdjustedPixelValueForLength(style->flexBasis(), *style);
        case CSSPropertyFlexDirection:
            return cssValuePool().createValue(style->flexDirection());
        case CSSPropertyFlexFlow:
            return valuesForShorthandProperty(flexFlowShorthand());
        case CSSPropertyFlexGrow:
            return cssValuePool().createValue(style->flexGrow());
        case CSSPropertyFlexShrink:
            return cssValuePool().createValue(style->flexShrink());
        case CSSPropertyFlexWrap:
            return cssValuePool().createValue(style->flexWrap());
        case CSSPropertyJustifyContent:
            return cssValuePool().createValue(style->justifyContent());
        case CSSPropertyOrder:
            return cssValuePool().createValue(style->order(), CSSPrimitiveValue::CSS_NUMBER);
        case CSSPropertyFloat:
            if (style->display() != NONE && style->hasOutOfFlowPosition())
                return cssValuePool().createIdentifierValue(CSSValueNone);
            return cssValuePool().createValue(style->floating());
        case CSSPropertyFont: {
            RefPtr<CSSFontValue> computedFont = CSSFontValue::create();
            computedFont->style = valueForFontStyle(*style);
            computedFont->variant = valueForFontVariant(*style);
            computedFont->weight = valueForFontWeight(*style);
            computedFont->stretch = valueForFontStretch(*style);
            computedFont->size = valueForFontSize(*style);
            computedFont->lineHeight = valueForLineHeight(*style);
            computedFont->family = valueForFontFamily(*style);
            return computedFont.release();
        }
        case CSSPropertyFontFamily: {
            RefPtr<CSSValueList> fontFamilyList = valueForFontFamily(*style);
            // If there's only a single family, return that as a CSSPrimitiveValue.
            // NOTE: Gecko always returns this as a comma-separated CSSPrimitiveValue string.
            if (fontFamilyList->length() == 1)
                return fontFamilyList->item(0);
            return fontFamilyList.release();
        }
        case CSSPropertyFontSize:
            return valueForFontSize(*style);
        case CSSPropertyFontStretch:
            return valueForFontStretch(*style);
        case CSSPropertyFontStyle:
            return valueForFontStyle(*style);
        case CSSPropertyFontVariant:
            return valueForFontVariant(*style);
        case CSSPropertyFontWeight:
            return valueForFontWeight(*style);
        case CSSPropertyWebkitFontFeatureSettings: {
            const FontFeatureSettings* featureSettings = style->fontDescription().featureSettings();
            if (!featureSettings || !featureSettings->size())
                return cssValuePool().createIdentifierValue(CSSValueNormal);
            RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
            for (unsigned i = 0; i < featureSettings->size(); ++i) {
                const FontFeature& feature = featureSettings->at(i);
                RefPtr<CSSFontFeatureValue> featureValue = CSSFontFeatureValue::create(feature.tag(), feature.value());
                list->append(featureValue.release());
            }
            return list.release();
        }
        case CSSPropertyGridAutoFlow: {
            RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
            switch (style->gridAutoFlow()) {
            case AutoFlowRow:
            case AutoFlowRowDense:
                list->append(cssValuePool().createIdentifierValue(CSSValueRow));
                break;
            case AutoFlowColumn:
            case AutoFlowColumnDense:
                list->append(cssValuePool().createIdentifierValue(CSSValueColumn));
                break;
            case AutoFlowStackRow:
            case AutoFlowStackColumn:
                list->append(cssValuePool().createIdentifierValue(CSSValueStack));
                break;
            default:
                ASSERT_NOT_REACHED();
            }

            switch (style->gridAutoFlow()) {
            case AutoFlowRowDense:
            case AutoFlowColumnDense:
                list->append(cssValuePool().createIdentifierValue(CSSValueDense));
                break;
            case AutoFlowStackRow:
                list->append(cssValuePool().createIdentifierValue(CSSValueRow));
                break;
            case AutoFlowStackColumn:
                list->append(cssValuePool().createIdentifierValue(CSSValueColumn));
                break;
            default:
                // Do nothing.
                break;
            }

            return list.release();
        }
        // Specs mention that getComputedStyle() should return the used value of the property instead of the computed
        // one for grid-definition-{rows|columns} but not for the grid-auto-{rows|columns} as things like
        // grid-auto-columns: 2fr; cannot be resolved to a value in pixels as the '2fr' means very different things
        // depending on the size of the explicit grid or the number of implicit tracks added to the grid. See
        // http://lists.w3.org/Archives/Public/www-style/2013Nov/0014.html
        case CSSPropertyGridAutoColumns:
            return specifiedValueForGridTrackSize(style->gridAutoColumns(), *style);
        case CSSPropertyGridAutoRows:
            return specifiedValueForGridTrackSize(style->gridAutoRows(), *style);

        case CSSPropertyGridTemplateColumns:
            return valueForGridTrackList(ForColumns, renderer, *style);
        case CSSPropertyGridTemplateRows:
            return valueForGridTrackList(ForRows, renderer, *style);

        case CSSPropertyGridColumnStart:
            return valueForGridPosition(style->gridColumnStart());
        case CSSPropertyGridColumnEnd:
            return valueForGridPosition(style->gridColumnEnd());
        case CSSPropertyGridRowStart:
            return valueForGridPosition(style->gridRowStart());
        case CSSPropertyGridRowEnd:
            return valueForGridPosition(style->gridRowEnd());
        case CSSPropertyGridColumn:
            return valuesForGridShorthand(gridColumnShorthand());
        case CSSPropertyGridRow:
            return valuesForGridShorthand(gridRowShorthand());
        case CSSPropertyGridArea:
            return valuesForGridShorthand(gridAreaShorthand());
        case CSSPropertyGridTemplate:
            return valuesForGridShorthand(gridTemplateShorthand());
        case CSSPropertyGrid:
            return valuesForGridShorthand(gridShorthand());
        case CSSPropertyGridTemplateAreas:
            if (!style->namedGridAreaRowCount()) {
                ASSERT(!style->namedGridAreaColumnCount());
                return cssValuePool().createIdentifierValue(CSSValueNone);
            }

            return CSSGridTemplateAreasValue::create(style->namedGridArea(), style->namedGridAreaRowCount(), style->namedGridAreaColumnCount());

        case CSSPropertyHeight:
            if (renderer) {
                // According to http://www.w3.org/TR/CSS2/visudet.html#the-height-property,
                // the "height" property does not apply for non-replaced inline elements.
                if (!renderer->isReplaced() && renderer->isInline())
                    return cssValuePool().createIdentifierValue(CSSValueAuto);
                return zoomAdjustedPixelValue(sizingBox(renderer).height(), *style);
            }
            return zoomAdjustedPixelValueForLength(style->height(), *style);
        case CSSPropertyWebkitHighlight:
            if (style->highlight() == nullAtom)
                return cssValuePool().createIdentifierValue(CSSValueNone);
            return cssValuePool().createValue(style->highlight(), CSSPrimitiveValue::CSS_STRING);
        case CSSPropertyWebkitHyphenateCharacter:
            if (style->hyphenationString().isNull())
                return cssValuePool().createIdentifierValue(CSSValueAuto);
            return cssValuePool().createValue(style->hyphenationString(), CSSPrimitiveValue::CSS_STRING);
        case CSSPropertyImageRendering:
            return CSSPrimitiveValue::create(style->imageRendering());
        case CSSPropertyIsolation:
            return cssValuePool().createValue(style->isolation());
        case CSSPropertyJustifyItems:
            return valueForItemPositionWithOverflowAlignment(resolveAlignmentAuto(style->justifyItems(), m_node.get()), style->justifyItemsOverflowAlignment(), style->justifyItemsPositionType());
        case CSSPropertyJustifySelf:
            return valueForItemPositionWithOverflowAlignment(resolveAlignmentAuto(style->justifySelf(), m_node->parentNode()), style->justifySelfOverflowAlignment(), NonLegacyPosition);
        case CSSPropertyLeft:
            return valueForPositionOffset(*style, CSSPropertyLeft, renderer);
        case CSSPropertyLetterSpacing:
            if (!style->letterSpacing())
                return cssValuePool().createIdentifierValue(CSSValueNormal);
            return zoomAdjustedPixelValue(style->letterSpacing(), *style);
        case CSSPropertyWebkitLineClamp:
            if (style->lineClamp().isNone())
                return cssValuePool().createIdentifierValue(CSSValueNone);
            return cssValuePool().createValue(style->lineClamp().value(), style->lineClamp().isPercentage() ? CSSPrimitiveValue::CSS_PERCENTAGE : CSSPrimitiveValue::CSS_NUMBER);
        case CSSPropertyLineHeight:
            return valueForLineHeight(*style);
        case CSSPropertyListStyleImage:
            if (style->listStyleImage())
                return style->listStyleImage()->cssValue();
            return cssValuePool().createIdentifierValue(CSSValueNone);
        case CSSPropertyListStylePosition:
            return cssValuePool().createValue(style->listStylePosition());
        case CSSPropertyListStyleType:
            return cssValuePool().createValue(style->listStyleType());
        case CSSPropertyWebkitLocale:
            if (style->locale().isNull())
                return cssValuePool().createIdentifierValue(CSSValueAuto);
            return cssValuePool().createValue(style->locale(), CSSPrimitiveValue::CSS_STRING);
        case CSSPropertyMarginTop: {
            Length marginTop = style->marginTop();
            if (marginTop.isFixed() || !renderer || !renderer->isBox())
                return zoomAdjustedPixelValueForLength(marginTop, *style);
            return zoomAdjustedPixelValue(toRenderBox(renderer)->marginTop(), *style);
        }
        case CSSPropertyMarginRight: {
            Length marginRight = style->marginRight();
            if (marginRight.isFixed() || !renderer || !renderer->isBox())
                return zoomAdjustedPixelValueForLength(marginRight, *style);
            float value;
            if (marginRight.isPercent()) {
                // RenderBox gives a marginRight() that is the distance between the right-edge of the child box
                // and the right-edge of the containing box, when display == BLOCK. Let's calculate the absolute
                // value of the specified margin-right % instead of relying on RenderBox's marginRight() value.
                value = minimumValueForLength(marginRight, toRenderBox(renderer)->containingBlockLogicalWidthForContent()).toFloat();
            } else {
                value = toRenderBox(renderer)->marginRight().toFloat();
            }
            return zoomAdjustedPixelValue(value, *style);
        }
        case CSSPropertyMarginBottom: {
            Length marginBottom = style->marginBottom();
            if (marginBottom.isFixed() || !renderer || !renderer->isBox())
                return zoomAdjustedPixelValueForLength(marginBottom, *style);
            return zoomAdjustedPixelValue(toRenderBox(renderer)->marginBottom(), *style);
        }
        case CSSPropertyMarginLeft: {
            Length marginLeft = style->marginLeft();
            if (marginLeft.isFixed() || !renderer || !renderer->isBox())
                return zoomAdjustedPixelValueForLength(marginLeft, *style);
            return zoomAdjustedPixelValue(toRenderBox(renderer)->marginLeft(), *style);
        }
        case CSSPropertyWebkitUserModify:
            return cssValuePool().createValue(style->userModify());
        case CSSPropertyMaxHeight: {
            const Length& maxHeight = style->maxHeight();
            if (maxHeight.isMaxSizeNone())
                return cssValuePool().createIdentifierValue(CSSValueNone);
            return zoomAdjustedPixelValueForLength(maxHeight, *style);
        }
        case CSSPropertyMaxWidth: {
            const Length& maxWidth = style->maxWidth();
            if (maxWidth.isMaxSizeNone())
                return cssValuePool().createIdentifierValue(CSSValueNone);
            return zoomAdjustedPixelValueForLength(maxWidth, *style);
        }
        case CSSPropertyMinHeight:
            // FIXME: For flex-items, min-height:auto should compute to min-content.
            if (style->minHeight().isAuto())
                return zoomAdjustedPixelValue(0, *style);
            return zoomAdjustedPixelValueForLength(style->minHeight(), *style);
        case CSSPropertyMinWidth:
            // FIXME: For flex-items, min-width:auto should compute to min-content.
            if (style->minWidth().isAuto())
                return zoomAdjustedPixelValue(0, *style);
            return zoomAdjustedPixelValueForLength(style->minWidth(), *style);
        case CSSPropertyObjectFit:
            return cssValuePool().createValue(style->objectFit());
        case CSSPropertyObjectPosition:
            return cssValuePool().createValue(
                Pair::create(
                    zoomAdjustedPixelValueForLength(style->objectPosition().x(), *style),
                    zoomAdjustedPixelValueForLength(style->objectPosition().y(), *style),
                    Pair::KeepIdenticalValues));
        case CSSPropertyOpacity:
            return cssValuePool().createValue(style->opacity(), CSSPrimitiveValue::CSS_NUMBER);
        case CSSPropertyOrphans:
            if (style->hasAutoOrphans())
                return cssValuePool().createIdentifierValue(CSSValueAuto);
            return cssValuePool().createValue(style->orphans(), CSSPrimitiveValue::CSS_NUMBER);
        case CSSPropertyOutlineColor:
            return m_allowVisitedStyle ? cssValuePool().createColorValue(style->colorIncludingFallback(CSSPropertyOutlineColor).rgb()) : currentColorOrValidColor(*style, style->outlineColor());
        case CSSPropertyOutlineOffset:
            return zoomAdjustedPixelValue(style->outlineOffset(), *style);
        case CSSPropertyOutlineStyle:
            if (style->outlineStyleIsAuto())
                return cssValuePool().createIdentifierValue(CSSValueAuto);
            return cssValuePool().createValue(style->outlineStyle());
        case CSSPropertyOutlineWidth:
            return zoomAdjustedPixelValue(style->outlineWidth(), *style);
        case CSSPropertyOverflow:
            return cssValuePool().createValue(max(style->overflowX(), style->overflowY()));
        case CSSPropertyOverflowWrap:
            return cssValuePool().createValue(style->overflowWrap());
        case CSSPropertyOverflowX:
            return cssValuePool().createValue(style->overflowX());
        case CSSPropertyOverflowY:
            return cssValuePool().createValue(style->overflowY());
        case CSSPropertyPaddingTop: {
            Length paddingTop = style->paddingTop();
            if (paddingTop.isFixed() || !renderer || !renderer->isBox())
                return zoomAdjustedPixelValueForLength(paddingTop, *style);
            return zoomAdjustedPixelValue(toRenderBox(renderer)->computedCSSPaddingTop(), *style);
        }
        case CSSPropertyPaddingRight: {
            Length paddingRight = style->paddingRight();
            if (paddingRight.isFixed() || !renderer || !renderer->isBox())
                return zoomAdjustedPixelValueForLength(paddingRight, *style);
            return zoomAdjustedPixelValue(toRenderBox(renderer)->computedCSSPaddingRight(), *style);
        }
        case CSSPropertyPaddingBottom: {
            Length paddingBottom = style->paddingBottom();
            if (paddingBottom.isFixed() || !renderer || !renderer->isBox())
                return zoomAdjustedPixelValueForLength(paddingBottom, *style);
            return zoomAdjustedPixelValue(toRenderBox(renderer)->computedCSSPaddingBottom(), *style);
        }
        case CSSPropertyPaddingLeft: {
            Length paddingLeft = style->paddingLeft();
            if (paddingLeft.isFixed() || !renderer || !renderer->isBox())
                return zoomAdjustedPixelValueForLength(paddingLeft, *style);
            return zoomAdjustedPixelValue(toRenderBox(renderer)->computedCSSPaddingLeft(), *style);
        }
        case CSSPropertyPageBreakAfter:
            return cssValuePool().createValue(style->pageBreakAfter());
        case CSSPropertyPageBreakBefore:
            return cssValuePool().createValue(style->pageBreakBefore());
        case CSSPropertyPageBreakInside: {
            EPageBreak pageBreak = style->pageBreakInside();
            ASSERT(pageBreak != PBALWAYS);
            if (pageBreak == PBALWAYS)
                return nullptr;
            return cssValuePool().createValue(style->pageBreakInside());
        }
        case CSSPropertyPosition:
            return cssValuePool().createValue(style->position());
        case CSSPropertyRight:
            return valueForPositionOffset(*style, CSSPropertyRight, renderer);
        case CSSPropertyScrollBehavior:
            return cssValuePool().createValue(style->scrollBehavior());
        case CSSPropertyTableLayout:
            return cssValuePool().createValue(style->tableLayout());
        case CSSPropertyTextAlign:
            return cssValuePool().createValue(style->textAlign());
        case CSSPropertyTextAlignLast:
            return cssValuePool().createValue(style->textAlignLast());
        case CSSPropertyTextDecoration:
            if (RuntimeEnabledFeatures::css3TextDecorationsEnabled())
                return valuesForShorthandProperty(textDecorationShorthand());
            // Fall through.
        case CSSPropertyTextDecorationLine:
            return renderTextDecorationFlagsToCSSValue(style->textDecoration());
        case CSSPropertyTextDecorationStyle:
            return valueForTextDecorationStyle(style->textDecorationStyle());
        case CSSPropertyTextDecorationColor:
            return currentColorOrValidColor(*style, style->textDecorationColor());
        case CSSPropertyTextJustify:
            return cssValuePool().createValue(style->textJustify());
        case CSSPropertyTextUnderlinePosition:
            return cssValuePool().createValue(style->textUnderlinePosition());
        case CSSPropertyWebkitTextDecorationsInEffect:
            return renderTextDecorationFlagsToCSSValue(style->textDecorationsInEffect());
        case CSSPropertyWebkitTextFillColor:
            return currentColorOrValidColor(*style, style->textFillColor());
        case CSSPropertyWebkitTextEmphasisColor:
            return currentColorOrValidColor(*style, style->textEmphasisColor());
        case CSSPropertyWebkitTextEmphasisPosition:
            return cssValuePool().createValue(style->textEmphasisPosition());
        case CSSPropertyWebkitTextEmphasisStyle:
            switch (style->textEmphasisMark()) {
            case TextEmphasisMarkNone:
                return cssValuePool().createIdentifierValue(CSSValueNone);
            case TextEmphasisMarkCustom:
                return cssValuePool().createValue(style->textEmphasisCustomMark(), CSSPrimitiveValue::CSS_STRING);
            case TextEmphasisMarkAuto:
                ASSERT_NOT_REACHED();
                // Fall through
            case TextEmphasisMarkDot:
            case TextEmphasisMarkCircle:
            case TextEmphasisMarkDoubleCircle:
            case TextEmphasisMarkTriangle:
            case TextEmphasisMarkSesame: {
                RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
                list->append(cssValuePool().createValue(style->textEmphasisFill()));
                list->append(cssValuePool().createValue(style->textEmphasisMark()));
                return list.release();
            }
            }
        case CSSPropertyTextIndent: {
            // If RuntimeEnabledFeatures::css3TextEnabled() returns false or text-indent has only one value(<length> | <percentage>),
            // getPropertyCSSValue() returns CSSValue.
            // If RuntimeEnabledFeatures::css3TextEnabled() returns true and text-indent has each-line or hanging,
            // getPropertyCSSValue() returns CSSValueList.
            RefPtr<CSSValue> textIndent = zoomAdjustedPixelValueForLength(style->textIndent(), *style);
            if (RuntimeEnabledFeatures::css3TextEnabled() && (style->textIndentLine() == TextIndentEachLine || style->textIndentType() == TextIndentHanging)) {
                RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
                list->append(textIndent.release());
                if (style->textIndentLine() == TextIndentEachLine)
                    list->append(cssValuePool().createIdentifierValue(CSSValueEachLine));
                if (style->textIndentType() == TextIndentHanging)
                    list->append(cssValuePool().createIdentifierValue(CSSValueHanging));
                return list.release();
            }
            return textIndent.release();
        }
        case CSSPropertyTextShadow:
            return valueForShadowList(style->textShadow(), *style, false);
        case CSSPropertyTextRendering:
            return cssValuePool().createValue(style->fontDescription().textRendering());
        case CSSPropertyTextOverflow:
            if (style->textOverflow())
                return cssValuePool().createIdentifierValue(CSSValueEllipsis);
            return cssValuePool().createIdentifierValue(CSSValueClip);
        case CSSPropertyWebkitTextStrokeColor:
            return currentColorOrValidColor(*style, style->textStrokeColor());
        case CSSPropertyWebkitTextStrokeWidth:
            return zoomAdjustedPixelValue(style->textStrokeWidth(), *style);
        case CSSPropertyTop:
            return valueForPositionOffset(*style, CSSPropertyTop, renderer);
        case CSSPropertyTouchAction:
            return touchActionFlagsToCSSValue(style->touchAction());
        case CSSPropertyTouchActionDelay:
            return cssValuePool().createValue(style->touchActionDelay());
        case CSSPropertyUnicodeBidi:
            return cssValuePool().createValue(style->unicodeBidi());
        case CSSPropertyVerticalAlign:
            switch (style->verticalAlign()) {
                case BASELINE:
                    return cssValuePool().createIdentifierValue(CSSValueBaseline);
                case MIDDLE:
                    return cssValuePool().createIdentifierValue(CSSValueMiddle);
                case SUB:
                    return cssValuePool().createIdentifierValue(CSSValueSub);
                case SUPER:
                    return cssValuePool().createIdentifierValue(CSSValueSuper);
                case TEXT_TOP:
                    return cssValuePool().createIdentifierValue(CSSValueTextTop);
                case TEXT_BOTTOM:
                    return cssValuePool().createIdentifierValue(CSSValueTextBottom);
                case TOP:
                    return cssValuePool().createIdentifierValue(CSSValueTop);
                case BOTTOM:
                    return cssValuePool().createIdentifierValue(CSSValueBottom);
                case BASELINE_MIDDLE:
                    return cssValuePool().createIdentifierValue(CSSValueWebkitBaselineMiddle);
                case LENGTH:
                    return zoomAdjustedPixelValueForLength(style->verticalAlignLength(), *style);
            }
            ASSERT_NOT_REACHED();
            return nullptr;
        case CSSPropertyWhiteSpace:
            return cssValuePool().createValue(style->whiteSpace());
        case CSSPropertyWidows:
            if (style->hasAutoWidows())
                return cssValuePool().createIdentifierValue(CSSValueAuto);
            return cssValuePool().createValue(style->widows(), CSSPrimitiveValue::CSS_NUMBER);
        case CSSPropertyWidth:
            if (renderer) {
                // According to http://www.w3.org/TR/CSS2/visudet.html#the-width-property,
                // the "width" property does not apply for non-replaced inline elements.
                if (!renderer->isReplaced() && renderer->isInline())
                    return cssValuePool().createIdentifierValue(CSSValueAuto);
                return zoomAdjustedPixelValue(sizingBox(renderer).width(), *style);
            }
            return zoomAdjustedPixelValueForLength(style->width(), *style);
        case CSSPropertyWillChange:
            return valueForWillChange(style->willChangeProperties(), style->willChangeContents(), style->willChangeScrollPosition());
        case CSSPropertyWordBreak:
            return cssValuePool().createValue(style->wordBreak());
        case CSSPropertyWordSpacing:
            return zoomAdjustedPixelValue(style->wordSpacing(), *style);
        case CSSPropertyWordWrap:
            return cssValuePool().createValue(style->overflowWrap());
        case CSSPropertyWebkitLineBreak:
            return cssValuePool().createValue(style->lineBreak());
        case CSSPropertyResize:
            return cssValuePool().createValue(style->resize());
        case CSSPropertyFontKerning:
            return cssValuePool().createValue(style->fontDescription().kerning());
        case CSSPropertyWebkitFontSmoothing:
            return cssValuePool().createValue(style->fontDescription().fontSmoothing());
        case CSSPropertyFontVariantLigatures: {
            FontDescription::LigaturesState commonLigaturesState = style->fontDescription().commonLigaturesState();
            FontDescription::LigaturesState discretionaryLigaturesState = style->fontDescription().discretionaryLigaturesState();
            FontDescription::LigaturesState historicalLigaturesState = style->fontDescription().historicalLigaturesState();
            FontDescription::LigaturesState contextualLigaturesState = style->fontDescription().contextualLigaturesState();
            if (commonLigaturesState == FontDescription::NormalLigaturesState && discretionaryLigaturesState == FontDescription::NormalLigaturesState
                && historicalLigaturesState == FontDescription::NormalLigaturesState && contextualLigaturesState == FontDescription::NormalLigaturesState)
                return cssValuePool().createIdentifierValue(CSSValueNormal);

            RefPtr<CSSValueList> valueList = CSSValueList::createSpaceSeparated();
            if (commonLigaturesState != FontDescription::NormalLigaturesState)
                valueList->append(cssValuePool().createIdentifierValue(commonLigaturesState == FontDescription::DisabledLigaturesState ? CSSValueNoCommonLigatures : CSSValueCommonLigatures));
            if (discretionaryLigaturesState != FontDescription::NormalLigaturesState)
                valueList->append(cssValuePool().createIdentifierValue(discretionaryLigaturesState == FontDescription::DisabledLigaturesState ? CSSValueNoDiscretionaryLigatures : CSSValueDiscretionaryLigatures));
            if (historicalLigaturesState != FontDescription::NormalLigaturesState)
                valueList->append(cssValuePool().createIdentifierValue(historicalLigaturesState == FontDescription::DisabledLigaturesState ? CSSValueNoHistoricalLigatures : CSSValueHistoricalLigatures));
            if (contextualLigaturesState != FontDescription::NormalLigaturesState)
                valueList->append(cssValuePool().createIdentifierValue(contextualLigaturesState == FontDescription::DisabledLigaturesState ? CSSValueNoContextual : CSSValueContextual));
            return valueList;
        }
        case CSSPropertyZIndex:
            if (style->hasAutoZIndex())
                return cssValuePool().createIdentifierValue(CSSValueAuto);
            return cssValuePool().createValue(style->zIndex(), CSSPrimitiveValue::CSS_NUMBER);
        case CSSPropertyZoom:
            return cssValuePool().createValue(style->zoom(), CSSPrimitiveValue::CSS_NUMBER);
        case CSSPropertyBoxSizing:
            if (style->boxSizing() == CONTENT_BOX)
                return cssValuePool().createIdentifierValue(CSSValueContentBox);
            return cssValuePool().createIdentifierValue(CSSValueBorderBox);
        case CSSPropertyAnimationDelay:
            ASSERT(RuntimeEnabledFeatures::cssAnimationUnprefixedEnabled());
        case CSSPropertyWebkitAnimationDelay:
            return valueForAnimationDelay(style->animations());
        case CSSPropertyAnimationDirection:
            ASSERT(RuntimeEnabledFeatures::cssAnimationUnprefixedEnabled());
        case CSSPropertyWebkitAnimationDirection: {
            RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
            const CSSAnimationData* animationData = style->animations();
            if (animationData) {
                for (size_t i = 0; i < animationData->directionList().size(); ++i)
                    list->append(valueForAnimationDirection(animationData->directionList()[i]));
            } else {
                list->append(cssValuePool().createIdentifierValue(CSSValueNormal));
            }
            return list.release();
        }
        case CSSPropertyAnimationDuration:
            ASSERT(RuntimeEnabledFeatures::cssAnimationUnprefixedEnabled());
        case CSSPropertyWebkitAnimationDuration:
            return valueForAnimationDuration(style->animations());
        case CSSPropertyAnimationFillMode:
            ASSERT(RuntimeEnabledFeatures::cssAnimationUnprefixedEnabled());
        case CSSPropertyWebkitAnimationFillMode: {
            RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
            const CSSAnimationData* animationData = style->animations();
            if (animationData) {
                for (size_t i = 0; i < animationData->fillModeList().size(); ++i)
                    list->append(valueForAnimationFillMode(animationData->fillModeList()[i]));
            } else {
                list->append(cssValuePool().createIdentifierValue(CSSValueNone));
            }
            return list.release();
        }
        case CSSPropertyAnimationIterationCount:
            ASSERT(RuntimeEnabledFeatures::cssAnimationUnprefixedEnabled());
        case CSSPropertyWebkitAnimationIterationCount: {
            RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
            const CSSAnimationData* animationData = style->animations();
            if (animationData) {
                for (size_t i = 0; i < animationData->iterationCountList().size(); ++i)
                    list->append(valueForAnimationIterationCount(animationData->iterationCountList()[i]));
            } else {
                list->append(cssValuePool().createValue(CSSAnimationData::initialIterationCount(), CSSPrimitiveValue::CSS_NUMBER));
            }
            return list.release();
        }
        case CSSPropertyAnimationName:
            ASSERT(RuntimeEnabledFeatures::cssAnimationUnprefixedEnabled());
        case CSSPropertyWebkitAnimationName: {
            RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
            const CSSAnimationData* animationData = style->animations();
            if (animationData) {
                for (size_t i = 0; i < animationData->nameList().size(); ++i)
                    list->append(cssValuePool().createValue(animationData->nameList()[i], CSSPrimitiveValue::CSS_STRING));
            } else {
                list->append(cssValuePool().createIdentifierValue(CSSValueNone));
            }
            return list.release();
        }
        case CSSPropertyAnimationPlayState:
            ASSERT(RuntimeEnabledFeatures::cssAnimationUnprefixedEnabled());
        case CSSPropertyWebkitAnimationPlayState: {
            RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
            const CSSAnimationData* animationData = style->animations();
            if (animationData) {
                for (size_t i = 0; i < animationData->playStateList().size(); ++i)
                    list->append(valueForAnimationPlayState(animationData->playStateList()[i]));
            } else {
                list->append(cssValuePool().createIdentifierValue(CSSValueRunning));
            }
            return list.release();
        }
        case CSSPropertyAnimationTimingFunction:
            ASSERT(RuntimeEnabledFeatures::cssAnimationUnprefixedEnabled());
        case CSSPropertyWebkitAnimationTimingFunction:
            return valueForAnimationTimingFunction(style->animations());
        case CSSPropertyAnimation:
        case CSSPropertyWebkitAnimation: {
            const CSSAnimationData* animationData = style->animations();
            if (animationData) {
                RefPtr<CSSValueList> animationsList = CSSValueList::createCommaSeparated();
                for (size_t i = 0; i < animationData->nameList().size(); ++i) {
                    RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
                    list->append(cssValuePool().createValue(animationData->nameList()[i], CSSPrimitiveValue::CSS_STRING));
                    list->append(cssValuePool().createValue(CSSTimingData::getRepeated(animationData->durationList(), i), CSSPrimitiveValue::CSS_S));
                    list->append(createTimingFunctionValue(CSSTimingData::getRepeated(animationData->timingFunctionList(), i).get()));
                    list->append(cssValuePool().createValue(CSSTimingData::getRepeated(animationData->delayList(), i), CSSPrimitiveValue::CSS_S));
                    list->append(valueForAnimationIterationCount(CSSTimingData::getRepeated(animationData->iterationCountList(), i)));
                    list->append(valueForAnimationDirection(CSSTimingData::getRepeated(animationData->directionList(), i)));
                    list->append(valueForAnimationFillMode(CSSTimingData::getRepeated(animationData->fillModeList(), i)));
                    list->append(valueForAnimationPlayState(CSSTimingData::getRepeated(animationData->playStateList(), i)));
                    animationsList->append(list);
                }
                return animationsList.release();
            }

            RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
            // animation-name default value.
            list->append(cssValuePool().createIdentifierValue(CSSValueNone));
            list->append(cssValuePool().createValue(CSSAnimationData::initialDuration(), CSSPrimitiveValue::CSS_S));
            list->append(createTimingFunctionValue(CSSAnimationData::initialTimingFunction().get()));
            list->append(cssValuePool().createValue(CSSAnimationData::initialDelay(), CSSPrimitiveValue::CSS_S));
            list->append(cssValuePool().createValue(CSSAnimationData::initialIterationCount(), CSSPrimitiveValue::CSS_NUMBER));
            list->append(valueForAnimationDirection(CSSAnimationData::initialDirection()));
            list->append(valueForAnimationFillMode(CSSAnimationData::initialFillMode()));
            // Initial animation-play-state.
            list->append(cssValuePool().createIdentifierValue(CSSValueRunning));
            return list.release();
        }
        case CSSPropertyWebkitAspectRatio:
            if (!style->hasAspectRatio())
                return cssValuePool().createIdentifierValue(CSSValueNone);
            return CSSAspectRatioValue::create(style->aspectRatioNumerator(), style->aspectRatioDenominator());
        case CSSPropertyBackfaceVisibility:
        case CSSPropertyWebkitBackfaceVisibility:
            return cssValuePool().createIdentifierValue((style->backfaceVisibility() == BackfaceVisibilityHidden) ? CSSValueHidden : CSSValueVisible);
        case CSSPropertyWebkitBorderImage:
            return valueForNinePieceImage(style->borderImage(), *style);
        case CSSPropertyBorderImageOutset:
            return valueForNinePieceImageQuad(style->borderImage().outset(), *style);
        case CSSPropertyBorderImageRepeat:
            return valueForNinePieceImageRepeat(style->borderImage());
        case CSSPropertyBorderImageSlice:
            return valueForNinePieceImageSlice(style->borderImage());
        case CSSPropertyBorderImageWidth:
            return valueForNinePieceImageQuad(style->borderImage().borderSlices(), *style);
        case CSSPropertyWebkitMaskBoxImage:
            return valueForNinePieceImage(style->maskBoxImage(), *style);
        case CSSPropertyWebkitMaskBoxImageOutset:
            return valueForNinePieceImageQuad(style->maskBoxImage().outset(), *style);
        case CSSPropertyWebkitMaskBoxImageRepeat:
            return valueForNinePieceImageRepeat(style->maskBoxImage());
        case CSSPropertyWebkitMaskBoxImageSlice:
            return valueForNinePieceImageSlice(style->maskBoxImage());
        case CSSPropertyWebkitMaskBoxImageWidth:
            return valueForNinePieceImageQuad(style->maskBoxImage().borderSlices(), *style);
        case CSSPropertyWebkitMaskBoxImageSource:
            if (style->maskBoxImageSource())
                return style->maskBoxImageSource()->cssValue();
            return cssValuePool().createIdentifierValue(CSSValueNone);
        case CSSPropertyWebkitFontSizeDelta:
            // Not a real style property -- used by the editing engine -- so has no computed value.
            break;
        case CSSPropertyWebkitMarginBottomCollapse:
        case CSSPropertyWebkitMarginAfterCollapse:
            return cssValuePool().createValue(style->marginAfterCollapse());
        case CSSPropertyWebkitMarginTopCollapse:
        case CSSPropertyWebkitMarginBeforeCollapse:
            return cssValuePool().createValue(style->marginBeforeCollapse());
        case CSSPropertyPerspective:
        case CSSPropertyWebkitPerspective:
            if (!style->hasPerspective())
                return cssValuePool().createIdentifierValue(CSSValueNone);
            return zoomAdjustedPixelValue(style->perspective(), *style);
        case CSSPropertyPerspectiveOrigin:
        case CSSPropertyWebkitPerspectiveOrigin: {
            RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
            if (renderer) {
                LayoutRect box;
                if (renderer->isBox())
                    box = toRenderBox(renderer)->borderBoxRect();

                list->append(zoomAdjustedPixelValue(minimumValueForLength(style->perspectiveOriginX(), box.width()), *style));
                list->append(zoomAdjustedPixelValue(minimumValueForLength(style->perspectiveOriginY(), box.height()), *style));
            }
            else {
                list->append(zoomAdjustedPixelValueForLength(style->perspectiveOriginX(), *style));
                list->append(zoomAdjustedPixelValueForLength(style->perspectiveOriginY(), *style));

            }
            return list.release();
        }
        case CSSPropertyWebkitRtlOrdering:
            return cssValuePool().createIdentifierValue(style->rtlOrdering() ? CSSValueVisual : CSSValueLogical);
        case CSSPropertyWebkitTapHighlightColor:
            return currentColorOrValidColor(*style, style->tapHighlightColor());
        case CSSPropertyWebkitUserDrag:
            return cssValuePool().createValue(style->userDrag());
        case CSSPropertyWebkitUserSelect:
            return cssValuePool().createValue(style->userSelect());
        case CSSPropertyBorderBottomLeftRadius:
            return valueForBorderRadiusCorner(style->borderBottomLeftRadius(), *style);
        case CSSPropertyBorderBottomRightRadius:
            return valueForBorderRadiusCorner(style->borderBottomRightRadius(), *style);
        case CSSPropertyBorderTopLeftRadius:
            return valueForBorderRadiusCorner(style->borderTopLeftRadius(), *style);
        case CSSPropertyBorderTopRightRadius:
            return valueForBorderRadiusCorner(style->borderTopRightRadius(), *style);
        case CSSPropertyClip: {
            if (style->hasAutoClip())
                return cssValuePool().createIdentifierValue(CSSValueAuto);
            RefPtr<Rect> rect = Rect::create();
            rect->setTop(zoomAdjustedPixelValue(style->clip().top().value(), *style));
            rect->setRight(zoomAdjustedPixelValue(style->clip().right().value(), *style));
            rect->setBottom(zoomAdjustedPixelValue(style->clip().bottom().value(), *style));
            rect->setLeft(zoomAdjustedPixelValue(style->clip().left().value(), *style));
            return cssValuePool().createValue(rect.release());
        }
        case CSSPropertySpeak:
            return cssValuePool().createValue(style->speak());
        case CSSPropertyTransform:
        case CSSPropertyWebkitTransform:
            return computedTransform(renderer, *style);
        case CSSPropertyTransformOrigin:
        case CSSPropertyWebkitTransformOrigin: {
            RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
            if (renderer) {
                LayoutRect box;
                if (renderer->isBox())
                    box = toRenderBox(renderer)->borderBoxRect();

                list->append(zoomAdjustedPixelValue(minimumValueForLength(style->transformOriginX(), box.width()), *style));
                list->append(zoomAdjustedPixelValue(minimumValueForLength(style->transformOriginY(), box.height()), *style));
                if (style->transformOriginZ() != 0)
                    list->append(zoomAdjustedPixelValue(style->transformOriginZ(), *style));
            } else {
                list->append(zoomAdjustedPixelValueForLength(style->transformOriginX(), *style));
                list->append(zoomAdjustedPixelValueForLength(style->transformOriginY(), *style));
                if (style->transformOriginZ() != 0)
                    list->append(zoomAdjustedPixelValue(style->transformOriginZ(), *style));
            }
            return list.release();
        }
        case CSSPropertyTransformStyle:
        case CSSPropertyWebkitTransformStyle:
            return cssValuePool().createIdentifierValue((style->transformStyle3D() == TransformStyle3DPreserve3D) ? CSSValuePreserve3d : CSSValueFlat);
        case CSSPropertyTransitionDelay:
        case CSSPropertyWebkitTransitionDelay:
            return valueForAnimationDelay(style->transitions());
        case CSSPropertyTransitionDuration:
        case CSSPropertyWebkitTransitionDuration:
            return valueForAnimationDuration(style->transitions());
        case CSSPropertyTransitionProperty:
        case CSSPropertyWebkitTransitionProperty:
            return valueForTransitionProperty(style->transitions());
        case CSSPropertyTransitionTimingFunction:
        case CSSPropertyWebkitTransitionTimingFunction:
            return valueForAnimationTimingFunction(style->transitions());
        case CSSPropertyTransition:
        case CSSPropertyWebkitTransition: {
            const CSSTransitionData* transitionData = style->transitions();
            if (transitionData) {
                RefPtr<CSSValueList> transitionsList = CSSValueList::createCommaSeparated();
                for (size_t i = 0; i < transitionData->propertyList().size(); ++i) {
                    RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
                    list->append(createTransitionPropertyValue(transitionData->propertyList()[i]));
                    list->append(cssValuePool().createValue(CSSTimingData::getRepeated(transitionData->durationList(), i), CSSPrimitiveValue::CSS_S));
                    list->append(createTimingFunctionValue(CSSTimingData::getRepeated(transitionData->timingFunctionList(), i).get()));
                    list->append(cssValuePool().createValue(CSSTimingData::getRepeated(transitionData->delayList(), i), CSSPrimitiveValue::CSS_S));
                    transitionsList->append(list);
                }
                return transitionsList.release();
            }

            RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
            // transition-property default value.
            list->append(cssValuePool().createIdentifierValue(CSSValueAll));
            list->append(cssValuePool().createValue(CSSTransitionData::initialDuration(), CSSPrimitiveValue::CSS_S));
            list->append(createTimingFunctionValue(CSSTransitionData::initialTimingFunction().get()));
            list->append(cssValuePool().createValue(CSSTransitionData::initialDelay(), CSSPrimitiveValue::CSS_S));
            return list.release();
        }
        case CSSPropertyPointerEvents:
            return cssValuePool().createValue(style->pointerEvents());
        case CSSPropertyWebkitTextOrientation:
            return CSSPrimitiveValue::create(style->textOrientation());
        case CSSPropertyWebkitLineBoxContain:
            return createLineBoxContainValue(style->lineBoxContain());
        case CSSPropertyContent:
            return valueForContentData(*style);
        case CSSPropertyWebkitClipPath:
            if (ClipPathOperation* operation = style->clipPath()) {
                if (operation->type() == ClipPathOperation::SHAPE)
                    return valueForBasicShape(*style, toShapeClipPathOperation(operation)->basicShape());
            }
            return cssValuePool().createIdentifierValue(CSSValueNone);
        case CSSPropertyShapeMargin:
            return cssValuePool().createValue(style->shapeMargin(), *style);
        case CSSPropertyShapeImageThreshold:
            return cssValuePool().createValue(style->shapeImageThreshold(), CSSPrimitiveValue::CSS_NUMBER);
        case CSSPropertyShapeOutside:
            return valueForShape(*style, style->shapeOutside());
        case CSSPropertyWebkitFilter:
            return valueForFilter(renderer, *style);
        case CSSPropertyMixBlendMode:
            return cssValuePool().createValue(style->blendMode());

        case CSSPropertyBackgroundBlendMode: {
            RefPtr<CSSValueList> list = CSSValueList::createCommaSeparated();
            for (const FillLayer* currLayer = &style->backgroundLayers(); currLayer; currLayer = currLayer->next())
                list->append(cssValuePool().createValue(currLayer->blendMode()));
            return list.release();
        }
        case CSSPropertyBackground:
            return valuesForBackgroundShorthand();
        case CSSPropertyBorder: {
            RefPtr<CSSValue> value = getPropertyCSSValue(CSSPropertyBorderTop, DoNotUpdateLayout);
            const CSSPropertyID properties[3] = { CSSPropertyBorderRight, CSSPropertyBorderBottom,
                                        CSSPropertyBorderLeft };
            for (size_t i = 0; i < WTF_ARRAY_LENGTH(properties); ++i) {
                if (!compareCSSValuePtr<CSSValue>(value, getPropertyCSSValue(properties[i], DoNotUpdateLayout)))
                    return nullptr;
            }
            return value.release();
        }
        case CSSPropertyBorderBottom:
            return valuesForShorthandProperty(borderBottomShorthand());
        case CSSPropertyBorderColor:
            return valuesForSidesShorthand(borderColorShorthand());
        case CSSPropertyBorderLeft:
            return valuesForShorthandProperty(borderLeftShorthand());
        case CSSPropertyBorderImage:
            return valueForNinePieceImage(style->borderImage(), *style);
        case CSSPropertyBorderRadius:
            return valueForBorderRadiusShorthand(*style);
        case CSSPropertyBorderRight:
            return valuesForShorthandProperty(borderRightShorthand());
        case CSSPropertyBorderStyle:
            return valuesForSidesShorthand(borderStyleShorthand());
        case CSSPropertyBorderTop:
            return valuesForShorthandProperty(borderTopShorthand());
        case CSSPropertyBorderWidth:
            return valuesForSidesShorthand(borderWidthShorthand());
        case CSSPropertyListStyle:
            return valuesForShorthandProperty(listStyleShorthand());
        case CSSPropertyMargin:
            return valuesForSidesShorthand(marginShorthand());
        case CSSPropertyOutline:
            return valuesForShorthandProperty(outlineShorthand());
        case CSSPropertyPadding:
            return valuesForSidesShorthand(paddingShorthand());
        /* Individual properties not part of the spec */
        case CSSPropertyBackgroundRepeatX:
        case CSSPropertyBackgroundRepeatY:
            break;

        /* Unimplemented CSS 3 properties (including CSS3 shorthand properties) */
        case CSSPropertyWebkitTextEmphasis:
            break;

        /* Directional properties are resolved by resolveDirectionAwareProperty() before the switch. */
        case CSSPropertyWebkitBorderEnd:
        case CSSPropertyWebkitBorderEndColor:
        case CSSPropertyWebkitBorderEndStyle:
        case CSSPropertyWebkitBorderEndWidth:
        case CSSPropertyWebkitBorderStart:
        case CSSPropertyWebkitBorderStartColor:
        case CSSPropertyWebkitBorderStartStyle:
        case CSSPropertyWebkitBorderStartWidth:
        case CSSPropertyWebkitBorderAfter:
        case CSSPropertyWebkitBorderAfterColor:
        case CSSPropertyWebkitBorderAfterStyle:
        case CSSPropertyWebkitBorderAfterWidth:
        case CSSPropertyWebkitBorderBefore:
        case CSSPropertyWebkitBorderBeforeColor:
        case CSSPropertyWebkitBorderBeforeStyle:
        case CSSPropertyWebkitBorderBeforeWidth:
        case CSSPropertyWebkitMarginEnd:
        case CSSPropertyWebkitMarginStart:
        case CSSPropertyWebkitMarginAfter:
        case CSSPropertyWebkitMarginBefore:
        case CSSPropertyWebkitPaddingEnd:
        case CSSPropertyWebkitPaddingStart:
        case CSSPropertyWebkitPaddingAfter:
        case CSSPropertyWebkitPaddingBefore:
        case CSSPropertyWebkitLogicalWidth:
        case CSSPropertyWebkitLogicalHeight:
        case CSSPropertyWebkitMinLogicalWidth:
        case CSSPropertyWebkitMinLogicalHeight:
        case CSSPropertyWebkitMaxLogicalWidth:
        case CSSPropertyWebkitMaxLogicalHeight:
            ASSERT_NOT_REACHED();
            break;

        /* Unimplemented @font-face properties */
        case CSSPropertySrc:
        case CSSPropertyUnicodeRange:
            break;

        /* Other unimplemented properties */
        case CSSPropertyPage: // for @page
        case CSSPropertyQuotes: // FIXME: needs implementation
        case CSSPropertySize: // for @page
            break;

        /* Unimplemented -webkit- properties */
        case CSSPropertyWebkitBorderRadius:
        case CSSPropertyWebkitMarginCollapse:
        case CSSPropertyWebkitMask:
        case CSSPropertyWebkitMaskRepeatX:
        case CSSPropertyWebkitMaskRepeatY:
        case CSSPropertyWebkitPerspectiveOriginX:
        case CSSPropertyWebkitPerspectiveOriginY:
        case CSSPropertyWebkitTextStroke:
        case CSSPropertyWebkitTransformOriginX:
        case CSSPropertyWebkitTransformOriginY:
        case CSSPropertyWebkitTransformOriginZ:
            break;

        /* @viewport rule properties */
        case CSSPropertyMaxZoom:
        case CSSPropertyMinZoom:
        case CSSPropertyOrientation:
        case CSSPropertyUserZoom:
            break;

        case CSSPropertyAll:
            return nullptr;
    }

    logUnimplementedPropertyID(propertyID);
    return nullptr;
}

String CSSComputedStyleDeclaration::getPropertyValue(CSSPropertyID propertyID) const
{
    RefPtr<CSSValue> value = getPropertyCSSValue(propertyID);
    if (value)
        return value->cssText();
    return "";
}


unsigned CSSComputedStyleDeclaration::length() const
{
    Node* node = m_node.get();
    if (!node)
        return 0;

    RenderStyle* style = node->computedStyle(m_pseudoElementSpecifier);
    if (!style)
        return 0;

    return computableProperties().size();
}

String CSSComputedStyleDeclaration::item(unsigned i) const
{
    if (i >= length())
        return "";

    return getPropertyNameString(computableProperties()[i]);
}

bool CSSComputedStyleDeclaration::cssPropertyMatches(CSSPropertyID propertyID, const CSSValue* propertyValue) const
{
    if (propertyID == CSSPropertyFontSize && propertyValue->isPrimitiveValue() && m_node) {
        m_node->document().updateLayoutIgnorePendingStylesheets();
        RenderStyle* style = m_node->computedStyle(m_pseudoElementSpecifier);
        if (style && style->fontDescription().keywordSize()) {
            CSSValueID sizeValue = cssIdentifierForFontSizeKeyword(style->fontDescription().keywordSize());
            const CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(propertyValue);
            if (primitiveValue->isValueID() && primitiveValue->getValueID() == sizeValue)
                return true;
        }
    }
    RefPtr<CSSValue> value = getPropertyCSSValue(propertyID);
    return value && propertyValue && value->equals(*propertyValue);
}

PassRefPtr<MutableStylePropertySet> CSSComputedStyleDeclaration::copyProperties() const
{
    return copyPropertiesInSet(computableProperties());
}

PassRefPtr<CSSValueList> CSSComputedStyleDeclaration::valuesForShorthandProperty(const StylePropertyShorthand& shorthand) const
{
    RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
    for (size_t i = 0; i < shorthand.length(); ++i) {
        RefPtr<CSSValue> value = getPropertyCSSValue(shorthand.properties()[i], DoNotUpdateLayout);
        list->append(value);
    }
    return list.release();
}

PassRefPtr<CSSValueList> CSSComputedStyleDeclaration::valuesForSidesShorthand(const StylePropertyShorthand& shorthand) const
{
    RefPtr<CSSValueList> list = CSSValueList::createSpaceSeparated();
    // Assume the properties are in the usual order top, right, bottom, left.
    RefPtr<CSSValue> topValue = getPropertyCSSValue(shorthand.properties()[0], DoNotUpdateLayout);
    RefPtr<CSSValue> rightValue = getPropertyCSSValue(shorthand.properties()[1], DoNotUpdateLayout);
    RefPtr<CSSValue> bottomValue = getPropertyCSSValue(shorthand.properties()[2], DoNotUpdateLayout);
    RefPtr<CSSValue> leftValue = getPropertyCSSValue(shorthand.properties()[3], DoNotUpdateLayout);

    // All 4 properties must be specified.
    if (!topValue || !rightValue || !bottomValue || !leftValue)
        return nullptr;

    bool showLeft = !compareCSSValuePtr(rightValue, leftValue);
    bool showBottom = !compareCSSValuePtr(topValue, bottomValue) || showLeft;
    bool showRight = !compareCSSValuePtr(topValue, rightValue) || showBottom;

    list->append(topValue.release());
    if (showRight)
        list->append(rightValue.release());
    if (showBottom)
        list->append(bottomValue.release());
    if (showLeft)
        list->append(leftValue.release());

    return list.release();
}

PassRefPtr<CSSValueList> CSSComputedStyleDeclaration::valuesForGridShorthand(const StylePropertyShorthand& shorthand) const
{
    RefPtr<CSSValueList> list = CSSValueList::createSlashSeparated();
    for (size_t i = 0; i < shorthand.length(); ++i) {
        RefPtr<CSSValue> value = getPropertyCSSValue(shorthand.properties()[i], DoNotUpdateLayout);
        list->append(value.release());
    }
    return list.release();
}

PassRefPtr<MutableStylePropertySet> CSSComputedStyleDeclaration::copyPropertiesInSet(const Vector<CSSPropertyID>& properties) const
{
    Vector<CSSProperty, 256> list;
    list.reserveInitialCapacity(properties.size());
    for (unsigned i = 0; i < properties.size(); ++i) {
        RefPtr<CSSValue> value = getPropertyCSSValue(properties[i]);
        if (value)
            list.append(CSSProperty(properties[i], value.release(), false));
    }
    return MutableStylePropertySet::create(list.data(), list.size());
}

CSSRule* CSSComputedStyleDeclaration::parentRule() const
{
    return 0;
}

PassRefPtr<CSSValue> CSSComputedStyleDeclaration::getPropertyCSSValue(const String& propertyName)
{
    CSSPropertyID propertyID = cssPropertyID(propertyName);
    if (!propertyID)
        return nullptr;
    RefPtr<CSSValue> value = getPropertyCSSValue(propertyID);
    return value ? value->cloneForCSSOM() : nullptr;
}

String CSSComputedStyleDeclaration::getPropertyValue(const String& propertyName)
{
    CSSPropertyID propertyID = cssPropertyID(propertyName);
    if (!propertyID)
        return String();
    ASSERT(CSSPropertyMetadata::isEnabledProperty(propertyID));
    return getPropertyValue(propertyID);
}

String CSSComputedStyleDeclaration::getPropertyPriority(const String&)
{
    // All computed styles have a priority of not "important".
    return "";
}

String CSSComputedStyleDeclaration::getPropertyShorthand(const String&)
{
    return "";
}

bool CSSComputedStyleDeclaration::isPropertyImplicit(const String&)
{
    return false;
}

void CSSComputedStyleDeclaration::setProperty(const String& name, const String&, const String&, ExceptionState& exceptionState)
{
    exceptionState.throwDOMException(NoModificationAllowedError, "These styles are computed, and therefore the '" + name + "' property is read-only.");
}

String CSSComputedStyleDeclaration::removeProperty(const String& name, ExceptionState& exceptionState)
{
    exceptionState.throwDOMException(NoModificationAllowedError, "These styles are computed, and therefore the '" + name + "' property is read-only.");
    return String();
}

PassRefPtr<CSSValue> CSSComputedStyleDeclaration::getPropertyCSSValueInternal(CSSPropertyID propertyID)
{
    return getPropertyCSSValue(propertyID);
}

String CSSComputedStyleDeclaration::getPropertyValueInternal(CSSPropertyID propertyID)
{
    return getPropertyValue(propertyID);
}

void CSSComputedStyleDeclaration::setPropertyInternal(CSSPropertyID id, const String&, bool, ExceptionState& exceptionState)
{
    exceptionState.throwDOMException(NoModificationAllowedError, "These styles are computed, and therefore the '" + getPropertyNameString(id) + "' property is read-only.");
}

PassRefPtr<CSSValueList> CSSComputedStyleDeclaration::valuesForBackgroundShorthand() const
{
    static const CSSPropertyID propertiesBeforeSlashSeperator[5] = { CSSPropertyBackgroundColor, CSSPropertyBackgroundImage,
                                                                     CSSPropertyBackgroundRepeat, CSSPropertyBackgroundAttachment,
                                                                     CSSPropertyBackgroundPosition };
    static const CSSPropertyID propertiesAfterSlashSeperator[3] = { CSSPropertyBackgroundSize, CSSPropertyBackgroundOrigin,
                                                                    CSSPropertyBackgroundClip };

    RefPtr<CSSValueList> list = CSSValueList::createSlashSeparated();
    list->append(valuesForShorthandProperty(StylePropertyShorthand(CSSPropertyBackground, propertiesBeforeSlashSeperator, WTF_ARRAY_LENGTH(propertiesBeforeSlashSeperator))));
    list->append(valuesForShorthandProperty(StylePropertyShorthand(CSSPropertyBackground, propertiesAfterSlashSeperator, WTF_ARRAY_LENGTH(propertiesAfterSlashSeperator))));
    return list.release();
}

void CSSComputedStyleDeclaration::trace(Visitor* visitor)
{
    visitor->trace(m_node);
    CSSStyleDeclaration::trace(visitor);
}

} // namespace blink
