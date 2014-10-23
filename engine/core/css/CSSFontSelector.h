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

#ifndef CSSFontSelector_h
#define CSSFontSelector_h

#include "core/css/FontFaceCache.h"
#include "core/css/FontLoader.h"
#include "platform/fonts/FontSelector.h"
#include "platform/fonts/GenericFontFamilySettings.h"
#include "platform/heap/Handle.h"
#include "wtf/Forward.h"
#include "wtf/HashMap.h"
#include "wtf/HashSet.h"

namespace blink {

class CSSFontFace;
class CSSFontFaceRule;
class CSSFontSelectorClient;
class CSSSegmentedFontFace;
class Document;
class FontDescription;
class StyleRuleFontFace;

class CSSFontSelector FINAL : public FontSelector {
public:
    static PassRefPtrWillBeRawPtr<CSSFontSelector> create(Document* document)
    {
        return adoptRefWillBeNoop(new CSSFontSelector(document));
    }
    virtual ~CSSFontSelector();

    virtual unsigned version() const OVERRIDE { return m_fontFaceCache.version(); }

    virtual PassRefPtr<FontData> getFontData(const FontDescription&, const AtomicString&) OVERRIDE;
    virtual void willUseFontData(const FontDescription&, const AtomicString& family, UChar32) OVERRIDE;
    bool isPlatformFontAvailable(const FontDescription&, const AtomicString& family);

#if !ENABLE(OILPAN)
    void clearDocument();
#endif

    void fontFaceInvalidated();

    // FontCacheClient implementation
    virtual void fontCacheInvalidated() OVERRIDE;

    void registerForInvalidationCallbacks(CSSFontSelectorClient*);
#if !ENABLE(OILPAN)
    void unregisterForInvalidationCallbacks(CSSFontSelectorClient*);
#endif

    Document* document() const { return m_document; }
    FontFaceCache* fontFaceCache() { return &m_fontFaceCache; }
    FontLoader* fontLoader() { return m_fontLoader.get(); }

    const GenericFontFamilySettings& genericFontFamilySettings() const { return m_genericFontFamilySettings; }
    void updateGenericFontFamilySettings(Document&);

    virtual void trace(Visitor*);

private:
    explicit CSSFontSelector(Document*);

    void dispatchInvalidationCallbacks();

    // FIXME: Oilpan: Ideally this should just be a traced Member but that will
    // currently leak because RenderStyle and its data are not on the heap.
    // See crbug.com/383860 for details.
    RawPtrWillBeWeakMember<Document> m_document;
    // FIXME: Move to Document or StyleEngine.
    FontFaceCache m_fontFaceCache;
    WillBeHeapHashSet<RawPtrWillBeWeakMember<CSSFontSelectorClient> > m_clients;

    RefPtrWillBeMember<FontLoader> m_fontLoader;
    GenericFontFamilySettings m_genericFontFamilySettings;
};

} // namespace blink

#endif // CSSFontSelector_h
