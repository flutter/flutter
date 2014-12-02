/*
 * Copyright (C) 2008 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_CSS_CSSSEGMENTEDFONTFACE_H_
#define SKY_ENGINE_CORE_CSS_CSSSEGMENTEDFONTFACE_H_

#include "sky/engine/platform/fonts/FontTraits.h"
#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/ListHashSet.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/Vector.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

class CSSFontFace;
class CSSFontSelector;
class FontData;
class FontDescription;
class FontFace;
class SegmentedFontData;

class CSSSegmentedFontFace final : public RefCounted<CSSSegmentedFontFace> {
public:
    static PassRefPtr<CSSSegmentedFontFace> create(CSSFontSelector* selector, FontTraits traits)
    {
        return adoptRef(new CSSSegmentedFontFace(selector, traits));
    }
    ~CSSSegmentedFontFace();

    CSSFontSelector* fontSelector() const { return m_fontSelector; }
    FontTraits traits() const { return m_traits; }

    void fontLoaded(CSSFontFace*);
    void fontLoadWaitLimitExceeded(CSSFontFace*);

    void addFontFace(PassRefPtr<FontFace>, bool cssConnected);
    void removeFontFace(PassRefPtr<FontFace>);
    bool isEmpty() const { return m_fontFaces.isEmpty(); }

    PassRefPtr<FontData> getFontData(const FontDescription&);

    bool checkFont(const String&) const;
    void match(const String&, Vector<RefPtr<FontFace> >&) const;
    void willUseFontData(const FontDescription&, UChar32);

private:
    CSSSegmentedFontFace(CSSFontSelector*, FontTraits);

    void pruneTable();
    bool isValid() const;
    bool isLoading() const;
    bool isLoaded() const;

    typedef ListHashSet<RefPtr<FontFace> > FontFaceList;

    RawPtr<CSSFontSelector> m_fontSelector;
    FontTraits m_traits;
    HashMap<unsigned, RefPtr<SegmentedFontData> > m_fontDataTable;
    // All non-CSS-connected FontFaces are stored after the CSS-connected ones.
    FontFaceList m_fontFaces;
    FontFaceList::iterator m_firstNonCssConnectedFace;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_CSSSEGMENTEDFONTFACE_H_
