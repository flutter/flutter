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
#include "platform/fonts/opentype/OpenTypeSanitizer.h"

#include "platform/RuntimeEnabledFeatures.h"
#include "platform/SharedBuffer.h"
#include "opentype-sanitiser.h"
#include "ots-memory-stream.h"

namespace blink {

PassRefPtr<SharedBuffer> OpenTypeSanitizer::sanitize()
{
    if (!m_buffer)
        return nullptr;

    // This is the largest web font size which we'll try to transcode.
    static const size_t maxWebFontSize = 30 * 1024 * 1024; // 30 MB
    if (m_buffer->size() > maxWebFontSize)
        return nullptr;

    if (RuntimeEnabledFeatures::woff2Enabled())
        ots::EnableWOFF2();

    // A transcoded font is usually smaller than an original font.
    // However, it can be slightly bigger than the original one due to
    // name table replacement and/or padding for glyf table.
    //
    // With WOFF fonts, however, we'll be decompressing, so the result can be
    // much larger than the original.

    ots::ExpandingMemoryStream output(m_buffer->size(), maxWebFontSize);
    if (!ots::Process(&output, reinterpret_cast<const uint8_t*>(m_buffer->data()), m_buffer->size()))
        return nullptr;

    const size_t transcodeLen = output.Tell();
    return SharedBuffer::create(static_cast<unsigned char*>(output.get()), transcodeLen);
}

bool OpenTypeSanitizer::supportsFormat(const String& format)
{
    return equalIgnoringCase(format, "woff")
        || (RuntimeEnabledFeatures::woff2Enabled() && equalIgnoringCase(format, "woff2"));
}

} // namespace blink
