/*
 * Copyright (c) 2006, 2007, 2008, Google Inc. All rights reserved.
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
#include "platform/fonts/FontPlatformData.h"

#include "SkEndian.h"
#include "SkTypeface.h"
#include "platform/fonts/FontCache.h"

namespace blink {

#if !OS(MACOSX)
unsigned FontPlatformData::hash() const
{
    unsigned h = SkTypeface::UniqueID(m_typeface.get());
    h ^= 0x01010101 * ((static_cast<int>(m_orientation) << 2) | (static_cast<int>(m_syntheticBold) << 1) | static_cast<int>(m_syntheticItalic));

    // This memcpy is to avoid a reinterpret_cast that breaks strict-aliasing
    // rules. Memcpy is generally optimized enough so that performance doesn't
    // matter here.
    uint32_t textSizeBytes;
    memcpy(&textSizeBytes, &m_textSize, sizeof(uint32_t));
    h ^= textSizeBytes;

    return h;
}

bool FontPlatformData::fontContainsCharacter(UChar32 character)
{
    SkPaint paint;
    setupPaint(&paint);
    paint.setTextEncoding(SkPaint::kUTF32_TextEncoding);

    uint16_t glyph;
    paint.textToGlyphs(&character, sizeof(character), &glyph);
    return glyph;
}

#endif

#if ENABLE(OPENTYPE_VERTICAL)
PassRefPtr<OpenTypeVerticalData> FontPlatformData::verticalData() const
{
    return FontCache::fontCache()->getVerticalData(typeface()->uniqueID(), *this);
}

PassRefPtr<SharedBuffer> FontPlatformData::openTypeTable(uint32_t table) const
{
    RefPtr<SharedBuffer> buffer;

    SkFontTableTag tag = SkEndianSwap32(table);
    const size_t tableSize = m_typeface->getTableSize(tag);
    if (tableSize) {
        Vector<char> tableBuffer(tableSize);
        m_typeface->getTableData(tag, 0, tableSize, &tableBuffer[0]);
        buffer = SharedBuffer::adoptVector(tableBuffer);
    }
    return buffer.release();
}
#endif

} // namespace blink
