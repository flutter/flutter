/*
 * Copyright (C) 2007 Nicholas Shanks <contact@nickshanks.com>
 * Copyright (C) 2008 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 3.  Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/fonts/FontDescription.h"

#include "platform/RuntimeEnabledFeatures.h"
#include "wtf/text/AtomicStringHash.h"
#include "wtf/text/StringHash.h"

namespace blink {

struct SameSizeAsFontDescription {
    FontFamily familyList;
    RefPtr<FontFeatureSettings> m_featureSettings;
    String locale;
    float sizes[4];
    // FXIME: Make them fit into one word.
    uint32_t bitfields;
    uint32_t bitfields2 : 7;
};

COMPILE_ASSERT(sizeof(FontDescription) == sizeof(SameSizeAsFontDescription), FontDescription_should_stay_small);

TypesettingFeatures FontDescription::s_defaultTypesettingFeatures = 0;

bool FontDescription::s_useSubpixelTextPositioning = false;

FontWeight FontDescription::lighterWeight(FontWeight weight)
{
    switch (weight) {
        case FontWeight100:
        case FontWeight200:
        case FontWeight300:
        case FontWeight400:
        case FontWeight500:
            return FontWeight100;

        case FontWeight600:
        case FontWeight700:
            return FontWeight400;

        case FontWeight800:
        case FontWeight900:
            return FontWeight700;
    }
    ASSERT_NOT_REACHED();
    return FontWeightNormal;
}

FontWeight FontDescription::bolderWeight(FontWeight weight)
{
    switch (weight) {
        case FontWeight100:
        case FontWeight200:
        case FontWeight300:
            return FontWeight400;

        case FontWeight400:
        case FontWeight500:
            return FontWeight700;

        case FontWeight600:
        case FontWeight700:
        case FontWeight800:
        case FontWeight900:
            return FontWeight900;
    }
    ASSERT_NOT_REACHED();
    return FontWeightNormal;
}

FontTraits FontDescription::traits() const
{
    return FontTraits(style(), variant(), weight(), stretch());
}

FontDescription::VariantLigatures FontDescription::variantLigatures() const
{
    VariantLigatures ligatures;

    ligatures.common = commonLigaturesState();
    ligatures.discretionary = discretionaryLigaturesState();
    ligatures.historical = historicalLigaturesState();
    ligatures.contextual = contextualLigaturesState();

    return ligatures;
}

void FontDescription::setTraits(FontTraits traits)
{
    setStyle(traits.style());
    setVariant(traits.variant());
    setWeight(traits.weight());
    setStretch(traits.stretch());
}

void FontDescription::setVariantLigatures(const VariantLigatures& ligatures)
{
    m_commonLigaturesState = ligatures.common;
    m_discretionaryLigaturesState = ligatures.discretionary;
    m_historicalLigaturesState = ligatures.historical;
    m_contextualLigaturesState = ligatures.contextual;

    updateTypesettingFeatures();
}

float FontDescription::effectiveFontSize() const
{
    float size = (RuntimeEnabledFeatures::subpixelFontScalingEnabled())
        ? computedSize()
        : computedPixelSize();

    // Ensure that the effective precision matches the font-cache precision.
    // This guarantees that the same precision is used regardless of cache status.
    return floorf(size * FontCacheKey::precisionMultiplier()) / FontCacheKey::precisionMultiplier();
}

FontCacheKey FontDescription::cacheKey(const FontFaceCreationParams& creationParams, FontTraits desiredTraits) const
{
    FontTraits fontTraits = desiredTraits.bitfield() ? desiredTraits : traits();

    unsigned options =
        static_cast<unsigned>(m_syntheticItalic) << 7 | // bit 8
        static_cast<unsigned>(m_syntheticBold) << 6 | // bit 7
        static_cast<unsigned>(m_fontSmoothing) << 4 | // bits 5-6
        static_cast<unsigned>(m_textRendering) << 2 | // bits 3-4
        static_cast<unsigned>(m_orientation) << 1 | // bit 2
        static_cast<unsigned>(m_subpixelTextPosition); // bit 1

    return FontCacheKey(creationParams, effectiveFontSize(), options | fontTraits.bitfield() << 8);
}


void FontDescription::setDefaultTypesettingFeatures(TypesettingFeatures typesettingFeatures)
{
    s_defaultTypesettingFeatures = typesettingFeatures;
}

TypesettingFeatures FontDescription::defaultTypesettingFeatures()
{
    return s_defaultTypesettingFeatures;
}

void FontDescription::updateTypesettingFeatures() const
{
    m_typesettingFeatures = s_defaultTypesettingFeatures;

    switch (textRendering()) {
    case AutoTextRendering:
        break;
    case OptimizeSpeed:
        m_typesettingFeatures &= ~(blink::Kerning | Ligatures);
        break;
    case GeometricPrecision:
    case OptimizeLegibility:
        m_typesettingFeatures |= blink::Kerning | Ligatures;
        break;
    }

    switch (kerning()) {
    case FontDescription::NoneKerning:
        m_typesettingFeatures &= ~blink::Kerning;
        break;
    case FontDescription::NormalKerning:
        m_typesettingFeatures |= blink::Kerning;
        break;
    case FontDescription::AutoKerning:
        break;
    }

    // As per CSS (http://dev.w3.org/csswg/css-text-3/#letter-spacing-property),
    // When the effective letter-spacing between two characters is not zero (due to
    // either justification or non-zero computed letter-spacing), user agents should
    // not apply optional ligatures.
    if (m_letterSpacing == 0) {
        switch (commonLigaturesState()) {
        case FontDescription::DisabledLigaturesState:
            m_typesettingFeatures &= ~Ligatures;
            break;
        case FontDescription::EnabledLigaturesState:
            m_typesettingFeatures |= Ligatures;
            break;
        case FontDescription::NormalLigaturesState:
            break;
        }

        if (discretionaryLigaturesState() == FontDescription::EnabledLigaturesState
            || historicalLigaturesState() == FontDescription::EnabledLigaturesState
            || contextualLigaturesState() == FontDescription::EnabledLigaturesState) {
            m_typesettingFeatures |= blink::Ligatures;
        }
    }
}

} // namespace blink
