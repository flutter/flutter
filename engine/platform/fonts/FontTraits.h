/*
 * Copyright (C) 2008 Apple Inc. All Rights Reserved.
 * Copyright (C) 2014 Google Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef FontTraits_h
#define FontTraits_h

#include "wtf/Assertions.h"

namespace blink {

enum FontWeight {
    FontWeight100,
    FontWeight200,
    FontWeight300,
    FontWeight400,
    FontWeight500,
    FontWeight600,
    FontWeight700,
    FontWeight800,
    FontWeight900,
    FontWeightNormal = FontWeight400,
    FontWeightBold = FontWeight700
};

// Numeric values matching OS/2 & Windows Metrics usWidthClass table.
// https://www.microsoft.com/typography/otspec/os2.htm
enum FontStretch {
    FontStretchUltraCondensed = 1,
    FontStretchExtraCondensed = 2,
    FontStretchCondensed = 3,
    FontStretchSemiCondensed = 4,
    FontStretchNormal = 5,
    FontStretchSemiExpanded = 6,
    FontStretchExpanded = 7,
    FontStretchExtraExpanded = 8,
    FontStretchUltraExpanded = 9
};

enum FontStyle {
    FontStyleNormal = 0,
    FontStyleItalic = 1
};

enum FontVariant {
    FontVariantNormal = 0,
    FontVariantSmallCaps = 1
};

typedef unsigned FontTraitsBitfield;

struct FontTraits {
    FontTraits(FontStyle style, FontVariant variant, FontWeight weight, FontStretch stretch)
    {
        m_traits.m_style = style;
        m_traits.m_variant = variant;
        m_traits.m_weight = weight;
        m_traits.m_stretch = stretch;
        m_traits.m_filler = 0;
        ASSERT(!(m_bitfield >> 10));
    }
    FontTraits(FontTraitsBitfield bitfield)
        : m_bitfield(bitfield)
    {
        ASSERT(!m_traits.m_filler);
        ASSERT(!(m_bitfield >> 10));
    }
    FontStyle style() const { return static_cast<FontStyle>(m_traits.m_style); }
    FontVariant variant() const { return static_cast<FontVariant>(m_traits.m_variant); }
    FontWeight weight() const { return static_cast<FontWeight>(m_traits.m_weight); }
    FontStretch stretch() const { return static_cast<FontStretch>(m_traits.m_stretch); }
    FontTraitsBitfield bitfield() const { return m_bitfield; }

    union {
        struct {
            unsigned m_style : 1;
            unsigned m_variant : 1;
            unsigned m_weight : 4;
            unsigned m_stretch : 4;
            unsigned m_filler : 22;
        } m_traits;
        FontTraitsBitfield m_bitfield;
    };
};

} // namespace blink
#endif // FontTraits_h
