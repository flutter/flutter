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

#ifndef FontBuilder_h
#define FontBuilder_h

#include "core/CSSValueKeywords.h"

#include "platform/fonts/FontDescription.h"
#include "platform/heap/Handle.h"
#include "wtf/PassRefPtr.h"

namespace blink {

class CSSValue;
class FontSelector;
class RenderStyle;

class FontDescriptionChangeScope;

class FontBuilder {
    STACK_ALLOCATED();
    WTF_MAKE_NONCOPYABLE(FontBuilder);
public:
    FontBuilder();

    // FIXME: The name is probably wrong, but matches StyleResolverState callsite for consistency.
    void initForStyleResolve(const Document&, RenderStyle*);

    void setInitial(float effectiveZoom);

    void didChangeFontParameters(bool);

    void inheritFrom(const FontDescription&);
    void fromSystemFont(CSSValueID, float effectiveZoom);

    void setFontFamilyInitial();
    void setFontFamilyInherit(const FontDescription&);
    void setFontFamilyValue(CSSValue*);

    void setFontSizeInitial();
    void setFontSizeInherit(const FontDescription&);
    void setFontSizeValue(CSSValue*, RenderStyle* parentStyle, const RenderStyle* rootElementStyle);

    void setWeight(FontWeight);
    void setStretch(FontStretch);
    void setFeatureSettings(PassRefPtr<FontFeatureSettings>);
    void setScript(const String& locale);
    void setStyle(FontStyle);
    void setVariant(FontVariant);
    void setVariantLigatures(const FontDescription::VariantLigatures&);
    void setTextRendering(TextRenderingMode);
    void setKerning(FontDescription::Kerning);
    void setFontSmoothing(FontSmoothingMode);

    // FIXME: These need to just vend a Font object eventually.
    void createFont(PassRefPtrWillBeRawPtr<FontSelector>, const RenderStyle* parentStyle, RenderStyle*);
    // FIXME: This is nearly static, should either made fully static or decomposed into
    // FontBuilder calls at the callsite.
    void createFontForDocument(PassRefPtrWillBeRawPtr<FontSelector>, RenderStyle*);

    bool fontSizeHasViewportUnits() { return m_fontSizehasViewportUnits; }

    // FIXME: These should not be necessary eventually.
    void setFontDirty(bool fontDirty) { m_fontDirty = fontDirty; }
    // FIXME: This is only used by an ASSERT in StyleResolver. Remove?
    bool fontDirty() const { return m_fontDirty; }

    static FontFeatureSettings* initialFeatureSettings() { return nullptr; }
    static FontDescription::GenericFamilyType initialGenericFamily() { return FontDescription::NoFamily; }
    static TextRenderingMode initialTextRendering() { return AutoTextRendering; }
    static FontVariant initialVariant() { return FontVariantNormal; }
    static FontDescription::VariantLigatures initialVariantLigatures() { return FontDescription::VariantLigatures(); }
    static FontStyle initialStyle() { return FontStyleNormal; }
    static FontDescription::Kerning initialKerning() { return FontDescription::AutoKerning; }
    static FontSmoothingMode initialFontSmoothing() { return AutoSmoothing; }
    static FontStretch initialStretch() { return FontStretchNormal; }
    static FontWeight initialWeight() { return FontWeightNormal; }

    friend class FontDescriptionChangeScope;

private:

    // FIXME: "size" arg should be first for consistency with other similar functions.
    void setSize(FontDescription&, float effectiveZoom, float size);
    void checkForOrientationChange(RenderStyle*);
    // This function fixes up the default font size if it detects that the current generic font family has changed. -dwh
    void checkForGenericFamilyChange(RenderStyle*, const RenderStyle* parentStyle);
    void updateComputedSize(RenderStyle*, const RenderStyle* parentStyle);

    float getComputedSizeFromSpecifiedSize(FontDescription&, float effectiveZoom, float specifiedSize);

    RawPtrWillBeMember<const Document> m_document;
    bool m_fontSizehasViewportUnits;
    // FIXME: This member is here on a short-term lease. The plan is to remove
    // any notion of RenderStyle from here, allowing FontBuilder to build Font objects
    // directly, rather than as a byproduct of calling RenderStyle::setFontDescription.
    // FontDescriptionChangeScope should be the only consumer of this member.
    // If you're using it, U R DOIN IT WRONG.
    RenderStyle* m_style;

    // Fontbuilder is responsbile for creating the Font()
    // object on RenderStyle from various other font-related
    // properties on RenderStyle. Whenever one of those
    // is changed, FontBuilder tracks the need to update
    // style->font() with this bool.
    bool m_fontDirty;

    friend class FontBuilderTest;
};

}

#endif
