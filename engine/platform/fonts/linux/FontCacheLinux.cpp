/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"

#include "platform/fonts/FontCache.h"

#include "public/platform/linux/WebFallbackFont.h"
#include "public/platform/linux/WebFontInfo.h"
#include "public/platform/linux/WebSandboxSupport.h"
#include "public/platform/Platform.h"
#include "wtf/text/CString.h"

namespace blink {

void FontCache::getFontForCharacter(UChar32 c, const char* preferredLocale, FontCache::PlatformFallbackFont* fallbackFont)
{
    WebFallbackFont webFallbackFont;
    if (Platform::current()->sandboxSupport())
        Platform::current()->sandboxSupport()->getFallbackFontForCharacter(c, preferredLocale, &webFallbackFont);
    else
        WebFontInfo::fallbackFontForChar(c, preferredLocale, &webFallbackFont);
    fallbackFont->name = String::fromUTF8(CString(webFallbackFont.name));
    fallbackFont->filename = webFallbackFont.filename;
    fallbackFont->fontconfigInterfaceId = webFallbackFont.fontconfigInterfaceId;
    fallbackFont->ttcIndex = webFallbackFont.ttcIndex;
    fallbackFont->isBold = webFallbackFont.isBold;
    fallbackFont->isItalic = webFallbackFont.isItalic;
}

} // namespace blink
