/*
 * Copyright (C) 2007, 2008, 2010, 2011 Apple Inc. All rights reserved.
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
#include "core/css/CSSFontFaceSource.h"

#include "core/css/CSSFontFace.h"
#include "platform/fonts/FontCacheKey.h"
#include "platform/fonts/FontDescription.h"
#include "platform/fonts/FontFaceCreationParams.h"
#include "platform/fonts/SimpleFontData.h"

namespace blink {

CSSFontFaceSource::CSSFontFaceSource()
    : m_face(nullptr)
{
}

CSSFontFaceSource::~CSSFontFaceSource()
{
}

PassRefPtr<SimpleFontData> CSSFontFaceSource::getFontData(const FontDescription& fontDescription)
{
    // If the font hasn't loaded or an error occurred, then we've got nothing.
    if (!isValid())
        return nullptr;

    if (isLocal()) {
        // We're local. Just return a SimpleFontData from the normal cache.
        return createFontData(fontDescription);
    }

    // See if we have a mapping in our FontData cache.
    FontCacheKey key = fontDescription.cacheKey(FontFaceCreationParams());

    RefPtr<SimpleFontData>& fontData = m_fontDataTable.add(key.hash(), nullptr).storedValue->value;
    if (!fontData)
        fontData = createFontData(fontDescription);
    return fontData; // No release, because fontData is a reference to a RefPtr that is held in the m_fontDataTable.
}

void CSSFontFaceSource::trace(Visitor* visitor)
{
    visitor->trace(m_face);
}

}
