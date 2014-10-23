/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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
#include "public/platform/linux/WebFontInfo.h"

#include "public/platform/linux/WebFallbackFont.h"
#include "wtf/HashMap.h"
#include "wtf/Noncopyable.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/Vector.h"
#include "wtf/text/AtomicString.h"
#include "wtf/text/AtomicStringHash.h"
#include <fontconfig/fontconfig.h>
#include <string.h>
#include <unicode/utf16.h>

namespace blink {

class CachedFont {
public:
    // Note: We pass the charset explicitly as callers
    // should not create CachedFont entries without knowing
    // that the FcPattern contains a valid charset.
    CachedFont(FcPattern* pattern, FcCharSet* charSet)
        : m_supportedCharacters(charSet)
    {
        ASSERT(pattern);
        ASSERT(charSet);
        m_fallbackFont.name = fontName(pattern);
        m_fallbackFont.filename = fontFilename(pattern);
        m_fallbackFont.ttcIndex = fontTtcIndex(pattern);
        m_fallbackFont.isBold = fontIsBold(pattern);
        m_fallbackFont.isItalic = fontIsItalic(pattern);
    }
    const WebFallbackFont& fallbackFont() const { return m_fallbackFont; }
    bool hasGlyphForCharacter(WebUChar32 c)
    {
        return m_supportedCharacters && FcCharSetHasChar(m_supportedCharacters, c);
    }

private:
    static WebCString fontName(FcPattern* pattern)
    {
        FcChar8* familyName = nullptr;
        if (FcPatternGetString(pattern, FC_FAMILY, 0, &familyName) != FcResultMatch)
            return WebCString();

        // FCChar8 is unsigned char, so we cast to char for WebCString.
        const char* charFamily = reinterpret_cast<char*>(familyName);
        return WebCString(charFamily, strlen(charFamily));
    }

    static WebCString fontFilename(FcPattern* pattern)
    {
        FcChar8* cFilename = nullptr;
        if (FcPatternGetString(pattern, FC_FILE, 0, &cFilename) != FcResultMatch)
            return WebCString();
        const char* fontFilename = reinterpret_cast<char*>(cFilename);
        return WebCString(fontFilename, strlen(fontFilename));
    }

    static int fontTtcIndex(FcPattern* pattern)
    {
        int ttcIndex = -1;
        if (FcPatternGetInteger(pattern, FC_INDEX, 0, &ttcIndex) != FcResultMatch || ttcIndex < 0)
            return 0;
        return ttcIndex;
    }

    static bool fontIsBold(FcPattern* pattern)
    {
        int weight = 0;
        if (FcPatternGetInteger(pattern, FC_WEIGHT, 0, &weight) != FcResultMatch)
            return false;
        return weight >= FC_WEIGHT_BOLD;
    }

    static bool fontIsItalic(FcPattern* pattern)
    {
        int slant = 0;
        if (FcPatternGetInteger(pattern, FC_SLANT, 0, &slant) != FcResultMatch)
            return false;
        return slant != FC_SLANT_ROMAN;
    }

    WebFallbackFont m_fallbackFont;
    // m_supportedCharaters is owned by the parent
    // FcFontSet and should never be freed.
    FcCharSet* m_supportedCharacters;
};


class CachedFontSet {
    WTF_MAKE_NONCOPYABLE(CachedFontSet);
public:
    // CachedFontSet takes ownership of the passed FcFontSet.
    static PassOwnPtr<CachedFontSet> createForLocale(const char* locale)
    {
        FcFontSet* fontSet = createFcFontSetForLocale(locale);
        return adoptPtr(new CachedFontSet(fontSet));
    }

    ~CachedFontSet()
    {
        m_fallbackList.clear();
        FcFontSetDestroy(m_fontSet);
    }

    WebFallbackFont fallbackFontForChar(WebUChar32 c)
    {
        Vector<CachedFont>::iterator itr = m_fallbackList.begin();
        for (; itr != m_fallbackList.end(); itr++) {
            if (itr->hasGlyphForCharacter(c))
                return itr->fallbackFont();
        }
        // The previous code just returned garbage if the user didn't
        // have the necessary fonts, this seems better than garbage.
        // Current callers happen to ignore any values with an empty family string.
        return WebFallbackFont();
    }

private:
    static FcFontSet* createFcFontSetForLocale(const char* locale)
    {
        FcPattern* pattern = FcPatternCreate();

        if (locale) {
            // FcChar* is unsigned char* so we have to cast.
            FcPatternAddString(pattern, FC_LANG, reinterpret_cast<const FcChar8*>(locale));
        }

        FcValue fcvalue;
        fcvalue.type = FcTypeBool;
        fcvalue.u.b = FcTrue;
        FcPatternAdd(pattern, FC_SCALABLE, fcvalue, FcFalse);

        FcConfigSubstitute(0, pattern, FcMatchPattern);
        FcDefaultSubstitute(pattern);

        if (!locale)
            FcPatternDel(pattern, FC_LANG);

        // The result parameter returns if any fonts were found.
        // We already handle 0 fonts correctly, so we ignore the param.
        FcResult result;
        FcFontSet* fontSet = FcFontSort(0, pattern, 0, 0, &result);
        FcPatternDestroy(pattern);

        // The caller will take ownership of this FcFontSet.
        return fontSet;
    }

    CachedFontSet(FcFontSet* fontSet)
        : m_fontSet(fontSet)
    {
        fillFallbackList();
    }

    void fillFallbackList()
    {
        ASSERT(m_fallbackList.isEmpty());
        if (!m_fontSet)
            return;

        for (int i = 0; i < m_fontSet->nfont; ++i) {
            FcPattern* pattern = m_fontSet->fonts[i];

            // Ignore any bitmap fonts users may still have installed from last century.
            FcBool isScalable;
            if (FcPatternGetBool(pattern, FC_SCALABLE, 0, &isScalable) != FcResultMatch || !isScalable)
                continue;

            // Ignore any fonts FontConfig knows about, but that we don't have permission to read.
            FcChar8* cFilename;
            if (FcPatternGetString(pattern, FC_FILE, 0, &cFilename) != FcResultMatch)
                continue;
            if (access(reinterpret_cast<char*>(cFilename), R_OK))
                continue;

            // Make sure this font can tell us what characters it has glyphs for.
            FcCharSet* charSet;
            if (FcPatternGetCharSet(pattern, FC_CHARSET, 0, &charSet) != FcResultMatch)
                continue;

            m_fallbackList.append(CachedFont(pattern, charSet));
        }
    }

    FcFontSet* m_fontSet; // Owned by this object.
    // CachedFont has a FcCharset* which points into the FcFontSet.
    // If the FcFontSet is ever destroyed, the fallbackList
    // must be cleared first.
    Vector<CachedFont> m_fallbackList;
};

class FontSetCache {
public:
    static FontSetCache& shared()
    {
        DEFINE_STATIC_LOCAL(FontSetCache, cache, ());
        return cache;
    }

    WebFallbackFont fallbackFontForCharInLocale(WebUChar32 c, const char* locale)
    {
        DEFINE_STATIC_LOCAL(AtomicString, kNoLocale, ("NO_LOCALE_SPECIFIED"));
        AtomicString localeKey;
        if (locale && strlen(locale)) {
            localeKey = AtomicString(locale);
        } else {
            // String hash computation the m_setsByLocale map needs
            // a non-empty string.
            localeKey = kNoLocale;
        }

        LocaleToCachedFont::iterator itr = m_setsByLocale.find(localeKey);
        if (itr == m_setsByLocale.end()) {
            OwnPtr<CachedFontSet> newEntry = CachedFontSet::createForLocale(strlen(locale) ? locale : 0);
            return m_setsByLocale.add(localeKey, newEntry.release()).storedValue->value->fallbackFontForChar(c);
        }
        return itr.get()->value->fallbackFontForChar(c);
    }
    // FIXME: We may wish to add a way to prune the cache at a later time.

private:
    // FIXME: This shouldn't need to be AtomicString, but
    // currently HashTraits<const char*> isn't smart enough
    // to hash the string (only does pointer compares).
    typedef HashMap<AtomicString, OwnPtr<CachedFontSet> > LocaleToCachedFont;
    LocaleToCachedFont m_setsByLocale;
};

void WebFontInfo::fallbackFontForChar(WebUChar32 c, const char* locale, WebFallbackFont* fallbackFont)
{
    *fallbackFont = FontSetCache::shared().fallbackFontForCharInLocale(c, locale);
}

} // namespace blink
