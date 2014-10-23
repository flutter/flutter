/*
 * Copyright (C) 2007, 2008, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#include "config.h"
#include "core/css/FontFaceCache.h"

#include "core/css/CSSFontSelector.h"
#include "core/css/CSSSegmentedFontFace.h"
#include "core/css/CSSValueList.h"
#include "core/css/FontFace.h"
#include "core/css/StyleRule.h"
#include "core/fetch/FontResource.h"
#include "core/fetch/ResourceFetcher.h"
#include "platform/FontFamilyNames.h"
#include "platform/fonts/FontDescription.h"
#include "wtf/text/AtomicString.h"

namespace blink {

FontFaceCache::FontFaceCache()
    : m_version(0)
{
}

void FontFaceCache::add(CSSFontSelector* cssFontSelector, const StyleRuleFontFace* fontFaceRule, PassRefPtrWillBeRawPtr<FontFace> prpFontFace)
{
    RefPtrWillBeRawPtr<FontFace> fontFace = prpFontFace;
    if (!m_styleRuleToFontFace.add(fontFaceRule, fontFace).isNewEntry)
        return;
    addFontFace(cssFontSelector, fontFace, true);
}

void FontFaceCache::addFontFace(CSSFontSelector* cssFontSelector, PassRefPtrWillBeRawPtr<FontFace> prpFontFace, bool cssConnected)
{
    RefPtrWillBeRawPtr<FontFace> fontFace = prpFontFace;

    FamilyToTraitsMap::AddResult traitsResult = m_fontFaces.add(fontFace->family(), nullptr);
    if (!traitsResult.storedValue->value)
        traitsResult.storedValue->value = adoptPtrWillBeNoop(new TraitsMap);

    TraitsMap::AddResult segmentedFontFaceResult = traitsResult.storedValue->value->add(fontFace->traits().bitfield(), nullptr);
    if (!segmentedFontFaceResult.storedValue->value)
        segmentedFontFaceResult.storedValue->value = CSSSegmentedFontFace::create(cssFontSelector, fontFace->traits());

    segmentedFontFaceResult.storedValue->value->addFontFace(fontFace, cssConnected);
    if (cssConnected)
        m_cssConnectedFontFaces.add(fontFace);

    ++m_version;
}

void FontFaceCache::remove(const StyleRuleFontFace* fontFaceRule)
{
    StyleRuleToFontFace::iterator it = m_styleRuleToFontFace.find(fontFaceRule);
    if (it != m_styleRuleToFontFace.end()) {
        removeFontFace(it->value.get(), true);
        m_styleRuleToFontFace.remove(it);
    }
}

void FontFaceCache::removeFontFace(FontFace* fontFace, bool cssConnected)
{
    FamilyToTraitsMap::iterator fontFacesIter = m_fontFaces.find(fontFace->family());
    if (fontFacesIter == m_fontFaces.end())
        return;
    TraitsMap* familyFontFaces = fontFacesIter->value.get();

    TraitsMap::iterator familyFontFacesIter = familyFontFaces->find(fontFace->traits().bitfield());
    if (familyFontFacesIter == familyFontFaces->end())
        return;
    RefPtrWillBeRawPtr<CSSSegmentedFontFace> segmentedFontFace = familyFontFacesIter->value;

    segmentedFontFace->removeFontFace(fontFace);
    if (segmentedFontFace->isEmpty()) {
        familyFontFaces->remove(familyFontFacesIter);
        if (familyFontFaces->isEmpty())
            m_fontFaces.remove(fontFacesIter);
    }
    m_fonts.clear();
    if (cssConnected)
        m_cssConnectedFontFaces.remove(fontFace);

    ++m_version;
}

void FontFaceCache::clearCSSConnected()
{
    for (StyleRuleToFontFace::iterator it = m_styleRuleToFontFace.begin(); it != m_styleRuleToFontFace.end(); ++it)
        removeFontFace(it->value.get(), true);
    m_styleRuleToFontFace.clear();
}

void FontFaceCache::clearAll()
{
    if (m_fontFaces.isEmpty())
        return;

    m_fontFaces.clear();
    m_fonts.clear();
    m_styleRuleToFontFace.clear();
    m_cssConnectedFontFaces.clear();
    ++m_version;
}

static inline bool compareFontFaces(CSSSegmentedFontFace* first, CSSSegmentedFontFace* second, FontTraits desiredTraits)
{
    const FontTraits& firstTraits = first->traits();
    const FontTraits& secondTraits = second->traits();

    bool firstHasDesiredVariant = firstTraits.variant() == desiredTraits.variant();
    bool secondHasDesiredVariant = secondTraits.variant() == desiredTraits.variant();

    if (firstHasDesiredVariant != secondHasDesiredVariant)
        return firstHasDesiredVariant;

    // We need to check font-variant css property for CSS2.1 compatibility.
    if (desiredTraits.variant() == FontVariantSmallCaps) {
        // Prefer a font that has indicated that it can only support small-caps to a font that claims to support
        // all variants. The specialized font is more likely to be true small-caps and not require synthesis.
        bool firstRequiresSmallCaps = firstTraits.variant() == FontVariantSmallCaps;
        bool secondRequiresSmallCaps = secondTraits.variant() == FontVariantSmallCaps;
        if (firstRequiresSmallCaps != secondRequiresSmallCaps)
            return firstRequiresSmallCaps;
    }

    bool firstHasDesiredStyle = firstTraits.style() == desiredTraits.style();
    bool secondHasDesiredStyle = secondTraits.style() == desiredTraits.style();

    if (firstHasDesiredStyle != secondHasDesiredStyle)
        return firstHasDesiredStyle;

    if (desiredTraits.style() == FontStyleItalic) {
        // Prefer a font that has indicated that it can only support italics to a font that claims to support
        // all styles. The specialized font is more likely to be the one the author wants used.
        bool firstRequiresItalics = firstTraits.style() == FontStyleItalic;
        bool secondRequiresItalics = secondTraits.style() == FontStyleItalic;
        if (firstRequiresItalics != secondRequiresItalics)
            return firstRequiresItalics;
    }
    if (secondTraits.weight() == desiredTraits.weight())
        return false;

    if (firstTraits.weight() == desiredTraits.weight())
        return true;

    // http://www.w3.org/TR/2011/WD-css3-fonts-20111004/#font-matching-algorithm says :
    //   - If the desired weight is less than 400, weights below the desired weight are checked in descending order followed by weights above the desired weight in ascending order until a match is found.
    //   - If the desired weight is greater than 500, weights above the desired weight are checked in ascending order followed by weights below the desired weight in descending order until a match is found.
    //   - If the desired weight is 400, 500 is checked first and then the rule for desired weights less than 400 is used.
    //   - If the desired weight is 500, 400 is checked first and then the rule for desired weights less than 400 is used.
    static const unsigned fallbackRuleSets = 9;
    static const unsigned rulesPerSet = 8;
    static const FontWeight weightFallbackRuleSets[fallbackRuleSets][rulesPerSet] = {
        { FontWeight200, FontWeight300, FontWeight400, FontWeight500, FontWeight600, FontWeight700, FontWeight800, FontWeight900 },
        { FontWeight100, FontWeight300, FontWeight400, FontWeight500, FontWeight600, FontWeight700, FontWeight800, FontWeight900 },
        { FontWeight200, FontWeight100, FontWeight400, FontWeight500, FontWeight600, FontWeight700, FontWeight800, FontWeight900 },
        { FontWeight500, FontWeight300, FontWeight200, FontWeight100, FontWeight600, FontWeight700, FontWeight800, FontWeight900 },
        { FontWeight400, FontWeight300, FontWeight200, FontWeight100, FontWeight600, FontWeight700, FontWeight800, FontWeight900 },
        { FontWeight700, FontWeight800, FontWeight900, FontWeight500, FontWeight400, FontWeight300, FontWeight200, FontWeight100 },
        { FontWeight800, FontWeight900, FontWeight600, FontWeight500, FontWeight400, FontWeight300, FontWeight200, FontWeight100 },
        { FontWeight900, FontWeight700, FontWeight600, FontWeight500, FontWeight400, FontWeight300, FontWeight200, FontWeight100 },
        { FontWeight800, FontWeight700, FontWeight600, FontWeight500, FontWeight400, FontWeight300, FontWeight200, FontWeight100 }
    };

    unsigned ruleSetIndex = static_cast<unsigned>(desiredTraits.weight());
    ASSERT(ruleSetIndex < fallbackRuleSets);
    const FontWeight* weightFallbackRule = weightFallbackRuleSets[ruleSetIndex];
    for (unsigned i = 0; i < rulesPerSet; ++i) {
        if (secondTraits.weight() == weightFallbackRule[i])
            return false;
        if (firstTraits.weight() == weightFallbackRule[i])
            return true;
    }

    return false;
}

CSSSegmentedFontFace* FontFaceCache::get(const FontDescription& fontDescription, const AtomicString& family)
{
    TraitsMap* familyFontFaces = m_fontFaces.get(family);
    if (!familyFontFaces || familyFontFaces->isEmpty())
        return 0;

    FamilyToTraitsMap::AddResult traitsResult = m_fonts.add(family, nullptr);
    if (!traitsResult.storedValue->value)
        traitsResult.storedValue->value = adoptPtrWillBeNoop(new TraitsMap);

    FontTraits traits = fontDescription.traits();
    TraitsMap::AddResult faceResult = traitsResult.storedValue->value->add(traits.bitfield(), nullptr);
    if (!faceResult.storedValue->value) {
        for (TraitsMap::const_iterator i = familyFontFaces->begin(); i != familyFontFaces->end(); ++i) {
            CSSSegmentedFontFace* candidate = i->value.get();
            FontTraits candidateTraits = candidate->traits();
            if (traits.style() == FontStyleNormal && candidateTraits.style() != FontStyleNormal)
                continue;
            if (traits.variant() == FontVariantNormal && candidateTraits.variant() != FontVariantNormal)
                continue;
            if (!faceResult.storedValue->value || compareFontFaces(candidate, faceResult.storedValue->value.get(), traits))
                faceResult.storedValue->value = candidate;
        }
    }
    return faceResult.storedValue->value.get();
}

void FontFaceCache::trace(Visitor* visitor)
{
#if ENABLE(OILPAN)
    visitor->trace(m_fontFaces);
    visitor->trace(m_fonts);
    visitor->trace(m_styleRuleToFontFace);
    visitor->trace(m_cssConnectedFontFaces);
#endif
}

}
