// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/animation/css/CSSPropertyEquality.h"

#include "sky/engine/core/animation/css/CSSAnimations.h"
#include "sky/engine/core/rendering/style/DataEquivalency.h"
#include "sky/engine/core/rendering/style/RenderStyle.h"
#include "sky/engine/core/rendering/style/ShadowList.h"

namespace blink {

namespace {

template <CSSPropertyID property>
bool fillLayersEqual(const FillLayer& aLayers, const FillLayer& bLayers)
{
    const FillLayer* aLayer = &aLayers;
    const FillLayer* bLayer = &bLayers;
    while (aLayer && bLayer) {
        switch (property) {
        case CSSPropertyBackgroundPositionX:
            if (aLayer->xPosition() != bLayer->xPosition())
                return false;
            break;
        case CSSPropertyBackgroundPositionY:
            if (aLayer->yPosition() != bLayer->yPosition())
                return false;
            break;
        case CSSPropertyBackgroundSize:
        case CSSPropertyWebkitBackgroundSize:
            if (!(aLayer->sizeLength() == bLayer->sizeLength()))
                return false;
            break;
        case CSSPropertyBackgroundImage:
            if (!dataEquivalent(aLayer->image(), bLayer->image()))
                return false;
            break;
        default:
            ASSERT_NOT_REACHED();
            return true;
        }

        aLayer = aLayer->next();
        bLayer = bLayer->next();
    }

    // FIXME: Shouldn't this be return !aLayer && !bLayer; ?
    return true;
}

}

bool CSSPropertyEquality::propertiesEqual(CSSPropertyID prop, const RenderStyle& a, const RenderStyle& b)
{
    switch (prop) {
    case CSSPropertyBackgroundColor:
        return a.backgroundColor().resolve(a.color()) == b.backgroundColor().resolve(b.color());
    case CSSPropertyBackgroundImage:
        return fillLayersEqual<CSSPropertyBackgroundImage>(a.backgroundLayers(), b.backgroundLayers());
    case CSSPropertyBackgroundPositionX:
        return fillLayersEqual<CSSPropertyBackgroundPositionX>(a.backgroundLayers(), b.backgroundLayers());
    case CSSPropertyBackgroundPositionY:
        return fillLayersEqual<CSSPropertyBackgroundPositionY>(a.backgroundLayers(), b.backgroundLayers());
    case CSSPropertyBackgroundSize:
        return fillLayersEqual<CSSPropertyBackgroundSize>(a.backgroundLayers(), b.backgroundLayers());
    case CSSPropertyBorderBottomColor:
        return a.borderBottomColor().resolve(a.color()) == b.borderBottomColor().resolve(b.color());
    case CSSPropertyBorderBottomLeftRadius:
        return a.borderBottomLeftRadius() == b.borderBottomLeftRadius();
    case CSSPropertyBorderBottomRightRadius:
        return a.borderBottomRightRadius() == b.borderBottomRightRadius();
    case CSSPropertyBorderBottomWidth:
        return a.borderBottomWidth() == b.borderBottomWidth();
    case CSSPropertyBorderImageOutset:
        return a.borderImageOutset() == b.borderImageOutset();
    case CSSPropertyBorderImageSlice:
        return a.borderImageSlices() == b.borderImageSlices();
    case CSSPropertyBorderImageSource:
        return dataEquivalent(a.borderImageSource(), b.borderImageSource());
    case CSSPropertyBorderImageWidth:
        return a.borderImageWidth() == b.borderImageWidth();
    case CSSPropertyBorderLeftColor:
        return a.borderLeftColor().resolve(a.color()) == b.borderLeftColor().resolve(b.color());
    case CSSPropertyBorderLeftWidth:
        return a.borderLeftWidth() == b.borderLeftWidth();
    case CSSPropertyBorderRightColor:
        return a.borderRightColor().resolve(a.color()) == b.borderRightColor().resolve(b.color());
    case CSSPropertyBorderRightWidth:
        return a.borderRightWidth() == b.borderRightWidth();
    case CSSPropertyBorderTopColor:
        return a.borderTopColor().resolve(a.color()) == b.borderTopColor().resolve(b.color());
    case CSSPropertyBorderTopLeftRadius:
        return a.borderTopLeftRadius() == b.borderTopLeftRadius();
    case CSSPropertyBorderTopRightRadius:
        return a.borderTopRightRadius() == b.borderTopRightRadius();
    case CSSPropertyBorderTopWidth:
        return a.borderTopWidth() == b.borderTopWidth();
    case CSSPropertyBottom:
        return a.bottom() == b.bottom();
    case CSSPropertyBoxShadow:
        return dataEquivalent(a.boxShadow(), b.boxShadow());
    case CSSPropertyClip:
        return a.clip() == b.clip();
    case CSSPropertyColor:
        return a.color() == b.color();
    case CSSPropertyFilter:
        return a.filter() == b.filter();
    case CSSPropertyFlexBasis:
        return a.flexBasis() == b.flexBasis();
    case CSSPropertyFlexGrow:
        return a.flexGrow() == b.flexGrow();
    case CSSPropertyFlexShrink:
        return a.flexShrink() == b.flexShrink();
    case CSSPropertyFontSize:
        // CSSPropertyFontSize: Must pass a specified size to setFontSize if Text Autosizing is enabled, but a computed size
        // if text zoom is enabled (if neither is enabled it's irrelevant as they're probably the same).
        // FIXME: Should we introduce an option to pass the computed font size here, allowing consumers to
        // enable text zoom rather than Text Autosizing? See http://crbug.com/227545.
        return a.specifiedFontSize() == b.specifiedFontSize();
    case CSSPropertyFontStretch:
        return a.fontStretch() == b.fontStretch();
    case CSSPropertyFontWeight:
        return a.fontWeight() == b.fontWeight();
    case CSSPropertyHeight:
        return a.height() == b.height();
    case CSSPropertyLeft:
        return a.left() == b.left();
    case CSSPropertyLetterSpacing:
        return a.letterSpacing() == b.letterSpacing();
    case CSSPropertyLineHeight:
        return a.specifiedLineHeight() == b.specifiedLineHeight();
    case CSSPropertyMarginBottom:
        return a.marginBottom() == b.marginBottom();
    case CSSPropertyMarginLeft:
        return a.marginLeft() == b.marginLeft();
    case CSSPropertyMarginRight:
        return a.marginRight() == b.marginRight();
    case CSSPropertyMarginTop:
        return a.marginTop() == b.marginTop();
    case CSSPropertyMaxHeight:
        return a.maxHeight() == b.maxHeight();
    case CSSPropertyMaxWidth:
        return a.maxWidth() == b.maxWidth();
    case CSSPropertyMinHeight:
        return a.minHeight() == b.minHeight();
    case CSSPropertyMinWidth:
        return a.minWidth() == b.minWidth();
    case CSSPropertyObjectPosition:
        return a.objectPosition() == b.objectPosition();
    case CSSPropertyOpacity:
        return a.opacity() == b.opacity();
    case CSSPropertyOrphans:
        return a.orphans() == b.orphans();
    case CSSPropertyOutlineColor:
        return a.outlineColor().resolve(a.color()) == b.outlineColor().resolve(b.color());
    case CSSPropertyOutlineOffset:
        return a.outlineOffset() == b.outlineOffset();
    case CSSPropertyOutlineWidth:
        return a.outlineWidth() == b.outlineWidth();
    case CSSPropertyPaddingBottom:
        return a.paddingBottom() == b.paddingBottom();
    case CSSPropertyPaddingLeft:
        return a.paddingLeft() == b.paddingLeft();
    case CSSPropertyPaddingRight:
        return a.paddingRight() == b.paddingRight();
    case CSSPropertyPaddingTop:
        return a.paddingTop() == b.paddingTop();
    case CSSPropertyRight:
        return a.right() == b.right();
    case CSSPropertyTextDecorationColor:
        return a.textDecorationColor().resolve(a.color()) == b.textDecorationColor().resolve(b.color());
    case CSSPropertyTextIndent:
        return a.textIndent() == b.textIndent();
    case CSSPropertyTextShadow:
        return dataEquivalent(a.textShadow(), b.textShadow());
    case CSSPropertyTop:
        return a.top() == b.top();
    case CSSPropertyVerticalAlign:
        return a.verticalAlign() == b.verticalAlign()
            && (a.verticalAlign() != LENGTH || a.verticalAlignLength() == b.verticalAlignLength());
    case CSSPropertyWebkitBackgroundSize:
        return fillLayersEqual<CSSPropertyWebkitBackgroundSize>(a.backgroundLayers(), b.backgroundLayers());
    case CSSPropertyWebkitBorderHorizontalSpacing:
        return a.horizontalBorderSpacing() == b.horizontalBorderSpacing();
    case CSSPropertyWebkitBorderVerticalSpacing:
        return a.verticalBorderSpacing() == b.verticalBorderSpacing();
    case CSSPropertyWebkitBoxShadow:
        return dataEquivalent(a.boxShadow(), b.boxShadow());
    case CSSPropertyWebkitClipPath:
        return dataEquivalent(a.clipPath(), b.clipPath());
    case CSSPropertyPerspective:
        return a.perspective() == b.perspective();
    case CSSPropertyPerspectiveOrigin:
        return a.perspectiveOriginX() == b.perspectiveOriginX() && a.perspectiveOriginY() == b.perspectiveOriginY();
    case CSSPropertyWebkitTextStrokeColor:
        return a.textStrokeColor().resolve(a.color()) == b.textStrokeColor().resolve(b.color());
    case CSSPropertyTransform:
        return a.transform() == b.transform();
    case CSSPropertyTransformOrigin:
        return a.transformOriginX() == b.transformOriginX() && a.transformOriginY() == b.transformOriginY() && a.transformOriginZ() == b.transformOriginZ();
    case CSSPropertyWidows:
        return a.widows() == b.widows();
    case CSSPropertyWidth:
        return a.width() == b.width();
    case CSSPropertyWordSpacing:
        return a.wordSpacing() == b.wordSpacing();
    case CSSPropertyZIndex:
        return a.zIndex() == b.zIndex();
    default:
        ASSERT_NOT_REACHED();
        return true;
    }
}

}
