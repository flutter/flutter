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

#include "config.h"
#include "public/web/WebFontDescription.h"

#include "platform/fonts/FontDescription.h"

namespace blink {

WebFontDescription::WebFontDescription(const FontDescription& desc)
{
    family = desc.family().family();
    genericFamily = static_cast<GenericFamily>(desc.genericFamily());
    size = desc.specifiedSize();
    italic = desc.style() == FontStyleItalic;
    smallCaps = desc.variant() == FontVariantSmallCaps;
    weight = static_cast<Weight>(desc.weight());
    smoothing = static_cast<Smoothing>(desc.fontSmoothing());
    letterSpacing = desc.letterSpacing();
    wordSpacing = desc.wordSpacing();
}

WebFontDescription::operator FontDescription() const
{
    FontFamily fontFamily;
    fontFamily.setFamily(family);

    FontDescription desc;
    desc.setFamily(fontFamily);
    desc.setGenericFamily(static_cast<FontDescription::GenericFamilyType>(genericFamily));
    desc.setSpecifiedSize(size);
    desc.setComputedSize(size);
    desc.setStyle(italic ? FontStyleItalic : FontStyleNormal);
    desc.setVariant(smallCaps ? FontVariantSmallCaps : FontVariantNormal);
    desc.setWeight(static_cast<FontWeight>(weight));
    desc.setFontSmoothing(static_cast<FontSmoothingMode>(smoothing));
    desc.setLetterSpacing(letterSpacing);
    desc.setWordSpacing(wordSpacing);
    return desc;
}

} // namespace blink
