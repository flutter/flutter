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

#include "sky/engine/core/css/FontSize.h"
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
    : m_fontSizehasViewportUnits(false)
    , m_style(0)
    , m_fontDirty(false)
{
}

void FontBuilder::initForStyleResolve(RenderStyle* style)
{
    m_style = style;
    m_fontDirty = false;
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

void FontBuilder::setFontFamilyInitial()
{
    FontDescriptionChangeScope scope(this);
}

void FontBuilder::setFontFamilyInherit(const FontDescription& parentFontDescription)
{
    FontDescriptionChangeScope scope(this);

    scope.fontDescription().setGenericFamily(parentFontDescription.genericFamily());
    scope.fontDescription().setFamily(parentFontDescription.family());
}

void FontBuilder::setFontSizeInherit(const FontDescription& parentFontDescription)
{
    FontDescriptionChangeScope scope(this);

    float size = parentFontDescription.specifiedSize();
    if (size < 0)
        return;
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
    return FontSize::getComputedSizeFromSpecifiedSize(fontDescription.isAbsoluteSize(), specifiedSize);
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
    float fixedScaleFactor = 1.0f;
    float size = parentFontDescription.fixedPitchFontType() == FixedPitchFont ?
        scope.fontDescription().specifiedSize() / fixedScaleFactor :
        scope.fontDescription().specifiedSize() * fixedScaleFactor;

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

    // Using 14px default to match Material Design English Body1:
    // http://www.google.com/design/spec/style/typography.html#typography-typeface
    const int defaultFontSize = 14;

    fontDescription.setSpecifiedSize(defaultFontSize);
    fontDescription.setComputedSize(getComputedSizeFromSpecifiedSize(fontDescription, defaultFontSize));

    FontOrientation fontOrientation;
    NonCJKGlyphOrientation glyphOrientation;
    getFontAndGlyphOrientation(documentStyle, fontOrientation, glyphOrientation);
    fontDescription.setOrientation(fontOrientation);
    fontDescription.setNonCJKGlyphOrientation(glyphOrientation);
    documentStyle->setFontDescription(fontDescription);
    documentStyle->font().update(fontSelector);
}

}
