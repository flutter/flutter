/*
 * Copyright (C) 2007, 2008, 2011 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_CSS_CSSFONTSELECTOR_H_
#define SKY_ENGINE_CORE_CSS_CSSFONTSELECTOR_H_

#include "sky/engine/core/css/FontFaceCache.h"
#include "sky/engine/core/css/FontLoader.h"
#include "sky/engine/platform/fonts/FontSelector.h"
#include "sky/engine/platform/fonts/GenericFontFamilySettings.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/HashSet.h"

namespace blink {

class CSSFontFace;
class CSSFontFaceRule;
class CSSFontSelectorClient;
class CSSSegmentedFontFace;
class Document;
class FontDescription;
class StyleRuleFontFace;

class CSSFontSelector final : public FontSelector {
public:
    static PassRefPtr<CSSFontSelector> create(Document* document)
    {
        return adoptRef(new CSSFontSelector(document));
    }
    virtual ~CSSFontSelector();

    virtual unsigned version() const override { return m_fontFaceCache.version(); }

    virtual PassRefPtr<FontData> getFontData(const FontDescription&, const AtomicString&) override;
    virtual void willUseFontData(const FontDescription&, const AtomicString& family, UChar32) override;
    bool isPlatformFontAvailable(const FontDescription&, const AtomicString& family);

    void clearDocument();

    void fontFaceInvalidated();

    // FontCacheClient implementation
    virtual void fontCacheInvalidated() override;

    void registerForInvalidationCallbacks(CSSFontSelectorClient*);
    void unregisterForInvalidationCallbacks(CSSFontSelectorClient*);

    Document* document() const { return m_document; }
    FontFaceCache* fontFaceCache() { return &m_fontFaceCache; }
    FontLoader* fontLoader() { return m_fontLoader.get(); }

    const GenericFontFamilySettings& genericFontFamilySettings() const { return m_genericFontFamilySettings; }
    void updateGenericFontFamilySettings(Document&);

private:
    explicit CSSFontSelector(Document*);

    void dispatchInvalidationCallbacks();

    // FIXME: Oilpan: Ideally this should just be a traced Member but that will
    // currently leak because RenderStyle and its data are not on the heap.
    // See crbug.com/383860 for details.
    RawPtr<Document> m_document;
    // FIXME: Move to Document or StyleEngine.
    FontFaceCache m_fontFaceCache;
    HashSet<RawPtr<CSSFontSelectorClient> > m_clients;

    RefPtr<FontLoader> m_fontLoader;
    GenericFontFamilySettings m_genericFontFamilySettings;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_CSSFONTSELECTOR_H_
