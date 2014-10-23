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

#ifndef FontData_h
#define FontData_h

#include "platform/PlatformExport.h"
#include "wtf/FastAllocBase.h"
#include "wtf/Forward.h"
#include "wtf/Noncopyable.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/unicode/Unicode.h"

namespace blink {

class SimpleFontData;

class PLATFORM_EXPORT FontData : public RefCounted<FontData> {
    WTF_MAKE_NONCOPYABLE(FontData); WTF_MAKE_FAST_ALLOCATED;
public:
    FontData()
        : m_maxGlyphPageTreeLevel(0)
    {
    }

    virtual ~FontData();

    virtual const SimpleFontData* fontDataForCharacter(UChar32) const = 0;
    virtual bool isCustomFont() const = 0;
    virtual bool isLoading() const = 0;
    // Returns whether this is a temporary font data for a custom font which is not yet loaded.
    virtual bool isLoadingFallback() const = 0;
    virtual bool isSegmented() const = 0;
    virtual bool shouldSkipDrawing() const = 0;

    void setMaxGlyphPageTreeLevel(unsigned level) const { m_maxGlyphPageTreeLevel = level; }
    unsigned maxGlyphPageTreeLevel() const { return m_maxGlyphPageTreeLevel; }

#ifndef NDEBUG
    virtual String description() const = 0;
#endif

private:
    mutable unsigned m_maxGlyphPageTreeLevel;
};

#define DEFINE_FONT_DATA_TYPE_CASTS(thisType, predicate) \
    template<typename T> inline thisType* to##thisType(const RefPtr<T>& fontData) { return to##thisType(fontData.get()); } \
    DEFINE_TYPE_CASTS(thisType, FontData, fontData, fontData->isSegmented() == predicate, fontData.isSegmented() == predicate)

} // namespace blink

#endif // FontData_h
