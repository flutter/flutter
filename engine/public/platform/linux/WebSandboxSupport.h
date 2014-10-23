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

#ifndef WebSandboxSupport_h
#define WebSandboxSupport_h

#include "../WebCommon.h"
#include "../WebString.h"
#include "WebFallbackFont.h"

namespace blink {

struct WebFontRenderStyle;

// Put methods here that are required due to sandbox restrictions.
// These are currently only implemented only on Linux:
// https://code.google.com/p/chromium/wiki/LinuxSandboxIPC
class WebSandboxSupport {
public:
    // Get information to instantiate a font which contains glyphs for the given Unicode code-point.
    //   character: a UTF-32 codepoint
    //   preferredLocale: preferred locale identifier for the |characters|
    //                    (e.g. "en", "ja", "zh-CN")
    //
    // Returns a WebFallbackFont instance with the font name and filename.
    // The instance has empty font name if the request cannot be satisfied.
    virtual void getFallbackFontForCharacter(WebUChar32, const char* preferredLocale, WebFallbackFont*) = 0;

    // Fill out the given WebFontRenderStyle with the user's preferences for
    // rendering the given font at the given size (in pixels).
    //   family: i.e. "Times New Roman"
    //   sizeAndStyle:
    //      3322222222221111111111
    //      10987654321098765432109876543210
    //     +--------------------------------+
    //     |..............Size............IB|
    //     +--------------------------------+
    //     I: italic flag
    //     B: bold flag
    // TODO(derat): Use separate parameters for the size and the style.
    virtual void getRenderStyleForStrike(const char* family, int sizeAndStyle, WebFontRenderStyle*) = 0;
};

} // namespace blink

#endif
