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

#include "sky/engine/platform/fonts/opentype/OpenTypeSanitizer.h"

#include "ots-memory-stream.h"
#include "sky/engine/platform/SharedBuffer.h"

#include <stdarg.h>

namespace blink {

PassRefPtr<SharedBuffer> OpenTypeSanitizer::sanitize()
{
    if (!m_buffer) {
        setErrorString("Empty Buffer");
        return nullptr;
    }

    // This is the largest web font size which we'll try to transcode.
    static const size_t maxWebFontSize = 30 * 1024 * 1024; // 30 MB
    if (m_buffer->size() > maxWebFontSize) {
        setErrorString("Web font size more than 30MB");
        return nullptr;
    }

    // A transcoded font is usually smaller than an original font.
    // However, it can be slightly bigger than the original one due to
    // name table replacement and/or padding for glyf table.
    //
    // With WOFF fonts, however, we'll be decompressing, so the result can be
    // much larger than the original.

    ots::ExpandingMemoryStream output(m_buffer->size(), maxWebFontSize);
    BlinkOTSContext otsContext;

    if (!otsContext.Process(&output, reinterpret_cast<const uint8_t*>(m_buffer->data()), m_buffer->size())) {
        setErrorString(otsContext.getErrorString());
        return nullptr;
    }

    const size_t transcodeLen = output.Tell();
    return SharedBuffer::create(static_cast<unsigned char*>(output.get()), transcodeLen);
}

bool OpenTypeSanitizer::supportsFormat(const String& format)
{
    return equalIgnoringCase(format, "woff") || equalIgnoringCase(format, "woff2");
}

void BlinkOTSContext::Message(int level, const char *format, ...)
{
    va_list args;
    va_start(args, format);

#if COMPILER(MSVC)
    int result = _vscprintf(format, args);
#else
    char ch;
    int result = vsnprintf(&ch, 1, format, args);
#endif
    va_end(args);

    if (result <= 0) {
        m_errorString = String("OTS Error");
    } else {
        Vector<char, 256> buffer;
        unsigned len = result;
        buffer.grow(len + 1);

        va_start(args, format);
        vsnprintf(buffer.data(), buffer.size(), format, args);
        va_end(args);
        m_errorString = StringImpl::create(reinterpret_cast<const LChar*>(buffer.data()), len);
    }
}

ots::TableAction BlinkOTSContext::GetTableAction(uint32_t tag)
{
#define TABLE_TAG(c1, c2, c3, c4) ((uint32_t)((((uint8_t)(c1)) << 24) | (((uint8_t)(c2)) << 16) | (((uint8_t)(c3)) << 8) | ((uint8_t)(c4))))

    const uint32_t cbdtTag = TABLE_TAG('C', 'B', 'D', 'T');
    const uint32_t cblcTag = TABLE_TAG('C', 'B', 'L', 'C');
    const uint32_t colrTag = TABLE_TAG('C', 'O', 'L', 'R');
    const uint32_t cpalTag = TABLE_TAG('C', 'P', 'A', 'L');

    switch (tag) {
    // Google Color Emoji Tables
    case cbdtTag:
    case cblcTag:
    // Windows Color Emoji Tables
    case colrTag:
    case cpalTag:
        return ots::TABLE_ACTION_PASSTHRU;
    default:
        return ots::TABLE_ACTION_DEFAULT;
    }
#undef TABLE_TAG
}

} // namespace blink
