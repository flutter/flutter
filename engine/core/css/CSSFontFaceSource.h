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

#ifndef CSSFontFaceSource_h
#define CSSFontFaceSource_h

#include "platform/heap/Handle.h"
#include "wtf/HashMap.h"

namespace blink {

class FontResource;
class CSSFontFace;
class FontDescription;
class SimpleFontData;

class CSSFontFaceSource : public NoBaseWillBeGarbageCollectedFinalized<CSSFontFaceSource> {
public:
    virtual ~CSSFontFaceSource();

    virtual bool isLocal() const { return false; }
    virtual bool isLoading() const { return false; }
    virtual bool isLoaded() const { return true; }
    virtual bool isValid() const { return true; }

    virtual FontResource* resource() { return 0; }
    void setFontFace(CSSFontFace* face) { m_face = face; }

    PassRefPtr<SimpleFontData> getFontData(const FontDescription&);

    virtual bool isLocalFontAvailable(const FontDescription&) { return false; }
    virtual void beginLoadIfNeeded() { }

    // For UMA reporting
    virtual bool hadBlankText() { return false; }

    virtual void trace(Visitor*);

protected:
    CSSFontFaceSource();
    virtual PassRefPtr<SimpleFontData> createFontData(const FontDescription&) = 0;

    typedef HashMap<unsigned, RefPtr<SimpleFontData> > FontDataTable; // The hash key is composed of size synthetic styles.

    RawPtrWillBeMember<CSSFontFace> m_face; // Our owning font face.
    FontDataTable m_fontDataTable;
};

}

#endif
