/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
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

#ifndef WebFontDescription_h
#define WebFontDescription_h

#include "../platform/WebString.h"

namespace blink {

class FontDescription;

struct WebFontDescription {
    enum GenericFamily {
        GenericFamilyNone,
        GenericFamilyStandard,
        GenericFamilySerif,
        GenericFamilySansSerif,
        GenericFamilyMonospace,
        GenericFamilyCursive,
        GenericFamilyFantasy
    };

    enum Smoothing {
        SmoothingAuto,
        SmoothingNone,
        SmoothingGrayscale,
        SmoothingSubpixel
    };

    enum Weight {
        Weight100,
        Weight200,
        Weight300,
        Weight400,
        Weight500,
        Weight600,
        Weight700,
        Weight800,
        Weight900,
        WeightNormal = Weight400,
        WeightBold = Weight700
    };

    WebFontDescription()
        : genericFamily(GenericFamilyNone)
        , size(0)
        , italic(false)
        , smallCaps(false)
        , weight(WeightNormal)
        , smoothing(SmoothingAuto)
        , letterSpacing(0)
        , wordSpacing(0)
    {
    }

    WebString family;
    GenericFamily genericFamily;
    float size;
    bool italic;
    bool smallCaps;
    Weight weight;
    Smoothing smoothing;

    short letterSpacing;
    short wordSpacing;

#if BLINK_IMPLEMENTATION
    WebFontDescription(const FontDescription&);
    operator FontDescription() const;
#endif
};

} // namespace blink

#endif
