/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2013 Google Inc. All rights reserved.
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
 *
 */

#include "sky/engine/core/css/resolver/FontBuilder.h"

#include "sky/engine/core/css/CSSCalculationValue.h"
#include "sky/engine/core/css/CSSToLengthConversionData.h"
#include "sky/engine/core/css/FontSize.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/core/rendering/RenderTheme.h"
#include "sky/engine/core/rendering/RenderView.h"
#include "sky/engine/platform/fonts/FontDescription.h"
#include "sky/engine/platform/text/LocaleToScriptMapping.h"

namespace blink {

// FIXME: This scoping class is a short-term fix to minimize the changes in
// Font-constructing logic.
class FontDescriptionChangeScope {
    STACK_ALLOCATED();
public:
    FontDescriptionChangeScope(FontBuilder* fontBuilder)
        : m_fontBuilder(fontBuilder)
        , m_fontDescription(fontBuilder->m_style->fontDescription())
    {
    }

    void reset() { m_fontDescription = FontDescription(); }
    void set(const FontDescription& fontDescription) { m_fontDescription = fontDescription; }
    FontDescription& fontDescription() { return m_fontDescription; }

    ~FontDescriptionChangeScope()
    {
        m_fontBuilder->didChangeFontParameters(m_fontBuilder->m_style->setFontDescription(m_fontDescription));
    }

private:
    RawPtr<FontBuilder> m_fontBuilder;
    FontDescription m_fontDescription;
};

FontBuilder::FontBuilder()
    : m_document(nullptr)
    , m_fontSizehasViewportUnits(false)
    , m_style(0)
    , m_fontDirty(false)
{
}

void FontBuilder::initForStyleResolve(const Document& document, RenderStyle* style)
{
    ASSERT(document.frame());
    m_document = &document;
    m_style = style;
    m_fontDirty = false;
}

inline static void setFontFamilyToStandard(FontDescription& fontDescription, const Document* document)
{
    if (!document || !document->settings())
        return;

    fontDescription.setGenericFamily(FontDescription::StandardFamily);
    const AtomicString& standardFontFamily = document->settings()->genericFontFamilySettings().standard();
    if (standardFontFamily.isEmpty())
        return;

    fontDescription.firstFamily().setFamily(standardFontFamily);
    // FIXME: Why is this needed here?
    fontDescription.firstFamily().appendFamily(nullptr);
}

void FontBuilder::setInitial()
{
    ASSERT(m_document && m_document->settings());
    if (!m_document || !m_document->settings())
        return;

    FontDescriptionChangeScope scope(this);

    scope.reset();
    setFontFamilyToStandard(scope.fontDescription(), m_document);
    scope.fontDescription().setKeywordSize(CSSValueMedium - CSSValueXxSmall + 1);
    setSize(scope.fontDescription(), FontSize::fontSizeForKeyword(m_document, CSSValueMedium, NonFixedPitchFont));
}

void FontBuilder::inheritFrom(const FontDescription& fontDescription)
{
    FontDescriptionChangeScope scope(this);

    scope.set(fontDescription);
}

void FontBuilder::didChangeFontParameters(bool changed)
{
    m_fontDirty |= changed;
}

void FontBuilder::fromSystemFont(CSSValueID valueId)
{
    FontDescriptionChangeScope scope(this);

    FontDescription fontDescription;
    RenderTheme::theme().systemFont(valueId, fontDescription);

    // Double-check and see if the theme did anything. If not, don't bother updating the font.
    if (!fontDescription.isAbsoluteSize())
        return;

    // Make sure the rendering mode and printer font settings are updated.
    const Settings* settings = m_document->settings();
    ASSERT(settings); // If we're doing style resolution, this document should always be in a frame and thus have settings
    if (!settings)
        return;

    fontDescription.setComputedSize(getComputedSizeFromSpecifiedSize(fontDescription, fontDescription.specifiedSize()));
    scope.set(fontDescription);
}

void FontBuilder::setFontFamilyInitial()
{
    FontDescriptionChangeScope scope(this);

    setFontFamilyToStandard(scope.fontDescription(), m_document);
}

void FontBuilder::setFontFamilyInherit(const FontDescription& parentFontDescription)
{
    FontDescriptionChangeScope scope(this);

    scope.fontDescription().setGenericFamily(parentFontDescription.genericFamily());
    scope.fontDescription().setFamily(parentFontDescription.family());
}

// FIXME: I am not convinced FontBuilder needs to know anything about CSSValues.
void FontBuilder::setFontFamilyValue(CSSValue* value)
{
    FontDescriptionChangeScope scope(this);

    if (!value->isValueList())
        return;

    FontFamily& firstFamily = scope.fontDescription().firstFamily();
    FontFamily* currFamily = 0;

    // Before mapping in a new font-family property, we should reset the generic family.
    FixedPitchFontType oldFixedPitchFontType = scope.fontDescription().fixedPitchFontType();
    scope.fontDescription().setGenericFamily(FontDescription::NoFamily);

    for (CSSValueListIterator i = value; i.hasMore(); i.advance()) {
        CSSValue* item = i.value();
        if (!item->isPrimitiveValue())
            continue;
        CSSPrimitiveValue* contentValue = toCSSPrimitiveValue(item);
        AtomicString face;
        Settings* settings = m_document->settings();
        if (contentValue->isString()) {
            face = AtomicString(contentValue->getStringValue());
        } else if (settings) {
            switch (contentValue->getValueID()) {
            case CSSValueWebkitBody:
                face = settings->genericFontFamilySettings().standard();
                break;
            case CSSValueSerif:
                face = FontFamilyNames::webkit_serif;
                scope.fontDescription().setGenericFamily(FontDescription::SerifFamily);
                break;
            case CSSValueSansSerif:
                face = FontFamilyNames::webkit_sans_serif;
                scope.fontDescription().setGenericFamily(FontDescription::SansSerifFamily);
                break;
            case CSSValueCursive:
                face = FontFamilyNames::webkit_cursive;
                scope.fontDescription().setGenericFamily(FontDescription::CursiveFamily);
                break;
            case CSSValueFantasy:
                face = FontFamilyNames::webkit_fantasy;
                scope.fontDescription().setGenericFamily(FontDescription::FantasyFamily);
                break;
            case CSSValueMonospace:
                face = FontFamilyNames::webkit_monospace;
                scope.fontDescription().setGenericFamily(FontDescription::MonospaceFamily);
                break;
            case CSSValueWebkitPictograph:
                face = FontFamilyNames::webkit_pictograph;
                scope.fontDescription().setGenericFamily(FontDescription::PictographFamily);
                break;
            default:
                break;
            }
        }

        if (!face.isEmpty()) {
            if (!currFamily) {
                // Filling in the first family.
                firstFamily.setFamily(face);
                firstFamily.appendFamily(nullptr); // Remove any inherited family-fallback list.
                currFamily = &firstFamily;
            } else {
                RefPtr<SharedFontFamily> newFamily = SharedFontFamily::create();
                newFamily->setFamily(face);
                currFamily->appendFamily(newFamily);
                currFamily = newFamily.get();
            }
        }
    }

    // We can't call useFixedDefaultSize() until all new font families have been added
    // If currFamily is non-zero then we set at least one family on this description.
    if (!currFamily)
        return;

    if (scope.fontDescription().keywordSize() && scope.fontDescription().fixedPitchFontType() != oldFixedPitchFontType) {
        scope.fontDescription().setSpecifiedSize(FontSize::fontSizeForKeyword(m_document,
        static_cast<CSSValueID>(CSSValueXxSmall + scope.fontDescription().keywordSize() - 1), scope.fontDescription().fixedPitchFontType()));
    }
}

void FontBuilder::setFontSizeInitial()
{
    FontDescriptionChangeScope scope(this);

    float size = FontSize::fontSizeForKeyword(m_document, CSSValueMedium, scope.fontDescription().fixedPitchFontType());

    if (size < 0)
        return;

    scope.fontDescription().setKeywordSize(CSSValueMedium - CSSValueXxSmall + 1);
    scope.fontDescription().setSpecifiedSize(size);
}

void FontBuilder::setFontSizeInherit(const FontDescription& parentFontDescription)
{
    FontDescriptionChangeScope scope(this);

    float size = parentFontDescription.specifiedSize();

    if (size < 0)
        return;

    scope.fontDescription().setKeywordSize(parentFontDescription.keywordSize());
    scope.fontDescription().setSpecifiedSize(size);
}

// FIXME: Figure out where we fall in the size ranges (xx-small to xxx-large)
// and scale down/up to the next size level.
static float largerFontSize(float size)
{
    return size * 1.2f;
}

static float smallerFontSize(float size)
{
    return size / 1.2f;
}

// FIXME: Have to pass RenderStyles here for calc/computed values. This shouldn't be neecessary.
void FontBuilder::setFontSizeValue(CSSValue* value, RenderStyle* parentStyle)
{
    if (!value->isPrimitiveValue())
        return;

    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value);

    FontDescriptionChangeScope scope(this);

    scope.fontDescription().setKeywordSize(0);
    float parentSize = 0;
    bool parentIsAbsoluteSize = false;
    float size = 0;

    // FIXME: Find out when parentStyle could be 0?
    if (parentStyle) {
        parentSize = parentStyle->fontDescription().specifiedSize();
        parentIsAbsoluteSize = parentStyle->fontDescription().isAbsoluteSize();
    }

    if (CSSValueID valueID = primitiveValue->getValueID()) {
        switch (valueID) {
        case CSSValueXxSmall:
        case CSSValueXSmall:
        case CSSValueSmall:
        case CSSValueMedium:
        case CSSValueLarge:
        case CSSValueXLarge:
        case CSSValueXxLarge:
        case CSSValueWebkitXxxLarge:
            size = FontSize::fontSizeForKeyword(m_document, valueID, scope.fontDescription().fixedPitchFontType());
            scope.fontDescription().setKeywordSize(valueID - CSSValueXxSmall + 1);
            break;
        case CSSValueLarger:
            size = largerFontSize(parentSize);
            break;
        case CSSValueSmaller:
            size = smallerFontSize(parentSize);
            break;
        default:
            return;
        }

        scope.fontDescription().setIsAbsoluteSize(parentIsAbsoluteSize && (valueID == CSSValueLarger || valueID == CSSValueSmaller));
    } else {
        scope.fontDescription().setIsAbsoluteSize(parentIsAbsoluteSize || !(primitiveValue->isPercentage() || primitiveValue->isFontRelativeLength()));
        if (primitiveValue->isPercentage()) {
            size = (primitiveValue->getFloatValue() * parentSize) / 100.0f;
        } else {
            // If we have viewport units the conversion will mark the parent style as having viewport units.
            bool parentHasViewportUnits = parentStyle->hasViewportUnits();
            parentStyle->setHasViewportUnits(false);
            CSSToLengthConversionData conversionData(parentStyle, m_document->renderView(), true);
            if (primitiveValue->isLength())
                size = primitiveValue->computeLength<float>(conversionData);
            else if (primitiveValue->isCalculatedPercentageWithLength())
                size = primitiveValue->cssCalcValue()->toCalcValue(conversionData)->evaluate(parentSize);
            else
                ASSERT_NOT_REACHED();
            m_fontSizehasViewportUnits = parentStyle->hasViewportUnits();
            parentStyle->setHasViewportUnits(parentHasViewportUnits);
        }
    }

    if (size < 0)
        return;

    // Overly large font sizes will cause crashes on some platforms (such as Windows).
    // Cap font size here to make sure that doesn't happen.
    size = std::min(maximumAllowedFontSize, size);


    scope.fontDescription().setSpecifiedSize(size);
}

void FontBuilder::setWeight(FontWeight fontWeight)
{
    FontDescriptionChangeScope scope(this);

    scope.fontDescription().setWeight(fontWeight);
}

void FontBuilder::setStretch(FontStretch fontStretch)
{
    FontDescriptionChangeScope scope(this);

    scope.fontDescription().setStretch(fontStretch);
}

void FontBuilder::setScript(const String& locale)
{
    FontDescriptionChangeScope scope(this);

    scope.fontDescription().setLocale(locale);
    scope.fontDescription().setScript(localeToScriptCodeForFontSelection(locale));
}

void FontBuilder::setStyle(FontStyle italic)
{
    FontDescriptionChangeScope scope(this);

    scope.fontDescription().setStyle(italic);
}

void FontBuilder::setVariant(FontVariant smallCaps)
{
    FontDescriptionChangeScope scope(this);

    scope.fontDescription().setVariant(smallCaps);
}

void FontBuilder::setVariantLigatures(const FontDescription::VariantLigatures& ligatures)
{
    FontDescriptionChangeScope scope(this);

    scope.fontDescription().setVariantLigatures(ligatures);
}

void FontBuilder::setTextRendering(TextRenderingMode textRenderingMode)
{
    FontDescriptionChangeScope scope(this);

    scope.fontDescription().setTextRendering(textRenderingMode);
}

void FontBuilder::setKerning(FontDescription::Kerning kerning)
{
    FontDescriptionChangeScope scope(this);

    scope.fontDescription().setKerning(kerning);
}

void FontBuilder::setFontSmoothing(FontSmoothingMode foontSmoothingMode)
{
    FontDescriptionChangeScope scope(this);

    scope.fontDescription().setFontSmoothing(foontSmoothingMode);
}

void FontBuilder::setFeatureSettings(PassRefPtr<FontFeatureSettings> settings)
{
    FontDescriptionChangeScope scope(this);

    scope.fontDescription().setFeatureSettings(settings);
}

void FontBuilder::setSize(FontDescription& fontDescription, float size)
{
    fontDescription.setSpecifiedSize(size);
    fontDescription.setComputedSize(getComputedSizeFromSpecifiedSize(fontDescription, size));
}

float FontBuilder::getComputedSizeFromSpecifiedSize(FontDescription& fontDescription, float specifiedSize)
{
    return FontSize::getComputedSizeFromSpecifiedSize(m_document, fontDescription.isAbsoluteSize(), specifiedSize);
}

static void getFontAndGlyphOrientation(const RenderStyle* style, FontOrientation& fontOrientation, NonCJKGlyphOrientation& glyphOrientation)
{
    // FIXME(sky): Remove this function now that we don't have writing modes.
    fontOrientation = Horizontal;
    glyphOrientation = NonCJKGlyphOrientationVerticalRight;
}

void FontBuilder::checkForOrientationChange(RenderStyle* style)
{
    FontOrientation fontOrientation;
    NonCJKGlyphOrientation glyphOrientation;
    getFontAndGlyphOrientation(style, fontOrientation, glyphOrientation);

    FontDescriptionChangeScope scope(this);

    if (scope.fontDescription().orientation() == fontOrientation && scope.fontDescription().nonCJKGlyphOrientation() == glyphOrientation)
        return;

    scope.fontDescription().setNonCJKGlyphOrientation(glyphOrientation);
    scope.fontDescription().setOrientation(fontOrientation);
}

void FontBuilder::checkForGenericFamilyChange(RenderStyle* style, const RenderStyle* parentStyle)
{
    FontDescriptionChangeScope scope(this);

    if (scope.fontDescription().isAbsoluteSize() || !parentStyle)
        return;

    const FontDescription& parentFontDescription = parentStyle->fontDescription();
    if (scope.fontDescription().fixedPitchFontType() == parentFontDescription.fixedPitchFontType())
        return;

    // For now, lump all families but monospace together.
    if (scope.fontDescription().genericFamily() != FontDescription::MonospaceFamily
        && parentFontDescription.genericFamily() != FontDescription::MonospaceFamily)
        return;

    // We know the parent is monospace or the child is monospace, and that font
    // size was unspecified. We want to scale our font size as appropriate.
    // If the font uses a keyword size, then we refetch from the table rather than
    // multiplying by our scale factor.
    float size;
    if (scope.fontDescription().keywordSize()) {
        size = FontSize::fontSizeForKeyword(m_document, static_cast<CSSValueID>(CSSValueXxSmall + scope.fontDescription().keywordSize() - 1), scope.fontDescription().fixedPitchFontType());
    } else {
        Settings* settings = m_document->settings();
        float fixedScaleFactor = (settings && settings->defaultFixedFontSize() && settings->defaultFontSize())
            ? static_cast<float>(settings->defaultFixedFontSize()) / settings->defaultFontSize()
            : 1;
        size = parentFontDescription.fixedPitchFontType() == FixedPitchFont ?
            scope.fontDescription().specifiedSize() / fixedScaleFactor :
            scope.fontDescription().specifiedSize() * fixedScaleFactor;
    }

    setSize(scope.fontDescription(), size);
}

void FontBuilder::updateComputedSize(RenderStyle* style, const RenderStyle* parentStyle)
{
    FontDescriptionChangeScope scope(this);

    float computedSize = getComputedSizeFromSpecifiedSize(scope.fontDescription(), scope.fontDescription().specifiedSize());
    scope.fontDescription().setComputedSize(computedSize);
}

// FIXME: style param should come first
void FontBuilder::createFont(PassRefPtr<FontSelector> fontSelector, const RenderStyle* parentStyle, RenderStyle* style)
{
    if (!m_fontDirty)
        return;

    updateComputedSize(style, parentStyle);
    checkForGenericFamilyChange(style, parentStyle);
    checkForOrientationChange(style);
    style->font().update(fontSelector);
    m_fontDirty = false;
}

void FontBuilder::createFontForDocument(PassRefPtr<FontSelector> fontSelector, RenderStyle* documentStyle)
{
    FontDescription fontDescription = FontDescription();
    fontDescription.setScript(localeToScriptCodeForFontSelection(documentStyle->locale()));

    setFontFamilyToStandard(fontDescription, m_document);
    fontDescription.setKeywordSize(CSSValueMedium - CSSValueXxSmall + 1);
    int size = FontSize::fontSizeForKeyword(m_document, CSSValueMedium, NonFixedPitchFont);
    fontDescription.setSpecifiedSize(size);
    fontDescription.setComputedSize(getComputedSizeFromSpecifiedSize(fontDescription, size));

    FontOrientation fontOrientation;
    NonCJKGlyphOrientation glyphOrientation;
    getFontAndGlyphOrientation(documentStyle, fontOrientation, glyphOrientation);
    fontDescription.setOrientation(fontOrientation);
    fontDescription.setNonCJKGlyphOrientation(glyphOrientation);
    documentStyle->setFontDescription(fontDescription);
    documentStyle->font().update(fontSelector);
}

}
