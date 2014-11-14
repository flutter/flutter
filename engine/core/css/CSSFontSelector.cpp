/*
 * Copyright (C) 2007, 2008, 2011 Apple Inc. All rights reserved.
 *           (C) 2007, 2008 Nikolas Zimmermann <zimmermann@kde.org>
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
#include "core/css/CSSFontSelector.h"

#include "core/css/CSSFontSelectorClient.h"
#include "core/css/CSSSegmentedFontFace.h"
#include "core/css/CSSValueList.h"
#include "core/css/FontFaceSet.h"
#include "core/css/resolver/StyleResolver.h"
#include "core/dom/Document.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "platform/RuntimeEnabledFeatures.h"
#include "platform/fonts/FontCache.h"
#include "platform/fonts/SimpleFontData.h"
#include "wtf/text/AtomicString.h"

namespace blink {

CSSFontSelector::CSSFontSelector(Document* document)
    : m_document(document)
    , m_fontLoader(FontLoader::create(this, document->fetcher()))
    , m_genericFontFamilySettings(document->frame()->settings()->genericFontFamilySettings())
{
    // FIXME: An old comment used to say there was no need to hold a reference to m_document
    // because "we are guaranteed to be destroyed before the document". But there does not
    // seem to be any such guarantee.

    ASSERT(m_document);
    ASSERT(m_document->frame());
    FontCache::fontCache()->addClient(this);
    FontFaceSet::from(*document)->addFontFacesToFontFaceCache(&m_fontFaceCache, this);
}

CSSFontSelector::~CSSFontSelector()
{
#if !ENABLE(OILPAN)
    clearDocument();
    FontCache::fontCache()->removeClient(this);
#endif
}

void CSSFontSelector::registerForInvalidationCallbacks(CSSFontSelectorClient* client)
{
    m_clients.add(client);
}

#if !ENABLE(OILPAN)
void CSSFontSelector::unregisterForInvalidationCallbacks(CSSFontSelectorClient* client)
{
    m_clients.remove(client);
}
#endif

void CSSFontSelector::dispatchInvalidationCallbacks()
{
    Vector<RawPtr<CSSFontSelectorClient> > clients;
    copyToVector(m_clients, clients);
    for (size_t i = 0; i < clients.size(); ++i)
        clients[i]->fontsNeedUpdate(this);
}

void CSSFontSelector::fontFaceInvalidated()
{
    dispatchInvalidationCallbacks();
}

void CSSFontSelector::fontCacheInvalidated()
{
    dispatchInvalidationCallbacks();
}

static AtomicString familyNameFromSettings(const GenericFontFamilySettings& settings, const FontDescription& fontDescription, const AtomicString& genericFamilyName)
{
#if OS(ANDROID)
    if (fontDescription.genericFamily() == FontDescription::StandardFamily)
        return FontCache::getGenericFamilyNameForScript(FontFamilyNames::webkit_standard, fontDescription);

    if (genericFamilyName.startsWith("-webkit-"))
        return FontCache::getGenericFamilyNameForScript(genericFamilyName, fontDescription);
#else
    UScriptCode script = fontDescription.script();

    if (fontDescription.genericFamily() == FontDescription::StandardFamily)
        return settings.standard(script);
    if (genericFamilyName == FontFamilyNames::webkit_serif)
        return settings.serif(script);
    if (genericFamilyName == FontFamilyNames::webkit_sans_serif)
        return settings.sansSerif(script);
    if (genericFamilyName == FontFamilyNames::webkit_cursive)
        return settings.cursive(script);
    if (genericFamilyName == FontFamilyNames::webkit_fantasy)
        return settings.fantasy(script);
    if (genericFamilyName == FontFamilyNames::webkit_monospace)
        return settings.fixed(script);
    if (genericFamilyName == FontFamilyNames::webkit_pictograph)
        return settings.pictograph(script);
    if (genericFamilyName == FontFamilyNames::webkit_standard)
        return settings.standard(script);
#endif
    return emptyAtom;
}

PassRefPtr<FontData> CSSFontSelector::getFontData(const FontDescription& fontDescription, const AtomicString& familyName)
{
    if (CSSSegmentedFontFace* face = m_fontFaceCache.get(fontDescription, familyName))
        return face->getFontData(fontDescription);

    // Try to return the correct font based off our settings, in case we were handed the generic font family name.
    AtomicString settingsFamilyName = familyNameFromSettings(m_genericFontFamilySettings, fontDescription, familyName);
    if (settingsFamilyName.isEmpty())
        return nullptr;

    return FontCache::fontCache()->getFontData(fontDescription, settingsFamilyName);
}

void CSSFontSelector::willUseFontData(const FontDescription& fontDescription, const AtomicString& family, UChar32 character)
{
    CSSSegmentedFontFace* face = m_fontFaceCache.get(fontDescription, family);
    if (face)
        face->willUseFontData(fontDescription, character);
}

bool CSSFontSelector::isPlatformFontAvailable(const FontDescription& fontDescription, const AtomicString& passedFamily)
{
    AtomicString family = familyNameFromSettings(m_genericFontFamilySettings, fontDescription, passedFamily);
    if (family.isEmpty())
        family = passedFamily;
    return FontCache::fontCache()->isPlatformFontAvailable(fontDescription, family);
}

#if !ENABLE(OILPAN)
void CSSFontSelector::clearDocument()
{
    m_fontLoader->clearResourceFetcherAndFontSelector();
    m_document = nullptr;
    m_fontFaceCache.clearAll();
}
#endif

void CSSFontSelector::updateGenericFontFamilySettings(Document& document)
{
    if (!document.settings())
        return;
    m_genericFontFamilySettings = document.settings()->genericFontFamilySettings();
    // Need to increment FontFaceCache version to update RenderStyles.
    m_fontFaceCache.incrementVersion();
}

}
