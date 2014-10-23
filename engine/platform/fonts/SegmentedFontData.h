/*
 * Copyright (C) 2008, 2009 Apple Inc. All rights reserved.
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

#ifndef SegmentedFontData_h
#define SegmentedFontData_h

#include "platform/PlatformExport.h"
#include "platform/fonts/FontData.h"
#include "wtf/Vector.h"

namespace blink {

class SimpleFontData;

struct FontDataRange {
    FontDataRange(UChar32 from, UChar32 to, PassRefPtr<SimpleFontData> fontData)
        : m_from(from)
        , m_to(to)
        , m_fontData(fontData)
    {
    }

    UChar32 from() const { return m_from; }
    UChar32 to() const { return m_to; }
    bool isEntireRange() const { return !m_from && m_to >= 0x10ffff; }
    PassRefPtr<SimpleFontData> fontData() const { return m_fontData; }

private:
    UChar32 m_from;
    UChar32 m_to;
    RefPtr<SimpleFontData> m_fontData;
};

class PLATFORM_EXPORT SegmentedFontData : public FontData {
public:
    static PassRefPtr<SegmentedFontData> create() { return adoptRef(new SegmentedFontData); }

    virtual ~SegmentedFontData();

    void appendRange(const FontDataRange& range) { m_ranges.append(range); }
    unsigned numRanges() const { return m_ranges.size(); }
    const FontDataRange& rangeAt(unsigned i) const { return m_ranges[i]; }
    bool containsCharacter(UChar32) const;

#ifndef NDEBUG
    virtual String description() const OVERRIDE;
#endif

private:
    SegmentedFontData() { }

    virtual const SimpleFontData* fontDataForCharacter(UChar32) const OVERRIDE;

    virtual bool isCustomFont() const OVERRIDE;
    virtual bool isLoading() const OVERRIDE;
    virtual bool isLoadingFallback() const OVERRIDE;
    virtual bool isSegmented() const OVERRIDE;
    virtual bool shouldSkipDrawing() const OVERRIDE;

    Vector<FontDataRange, 1> m_ranges;
};

DEFINE_FONT_DATA_TYPE_CASTS(SegmentedFontData, true);

} // namespace blink

#endif // SegmentedFontData_h
