/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 2004-2005 Allan Sandfeld Jensen (kde@carewolf.com)
 * Copyright (C) 2006, 2007 Nicholas Shanks (webkit@nickshanks.com)
 * Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013 Apple Inc. All rights reserved.
 * Copyright (C) 2007 Alexey Proskuryakov <ap@webkit.org>
 * Copyright (C) 2007, 2008 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (c) 2011, Code Aurora Forum. All rights reserved.
 * Copyright (C) Research In Motion Limited 2011. All rights reserved.
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#include "config.h"
#include "core/css/FontSize.h"

#include "core/CSSValueKeywords.h"
#include "core/dom/Document.h"
#include "core/frame/Settings.h"

namespace blink {

float FontSize::getComputedSizeFromSpecifiedSize(const Document* document, bool isAbsoluteSize, float specifiedSize, ESmartMinimumForFontSize useSmartMinimumForFontSize)
{
    // Text with a 0px font size should not be visible and therefore needs to be
    // exempt from minimum font size rules. Acid3 relies on this for pixel-perfect
    // rendering. This is also compatible with other browsers that have minimum
    // font size settings (e.g. Firefox).
    if (fabsf(specifiedSize) < std::numeric_limits<float>::epsilon())
        return 0.0f;

    // We support two types of minimum font size. The first is a hard override that applies to
    // all fonts. This is "minSize." The second type of minimum font size is a "smart minimum"
    // that is applied only when the Web page can't know what size it really asked for, e.g.,
    // when it uses logical sizes like "small" or expresses the font-size as a percentage of
    // the user's default font setting.

    // With the smart minimum, we never want to get smaller than the minimum font size to keep fonts readable.
    // However we always allow the page to set an explicit pixel size that is smaller,
    // since sites will mis-render otherwise (e.g., http://www.gamespot.com with a 9px minimum).

    Settings* settings = document->settings();
    if (!settings)
        return 1.0f;

    int minSize = 0;
    int minLogicalSize = 0;

    // Apply the hard minimum first. We only apply the hard minimum if after zooming we're still too small.
    if (specifiedSize < minSize)
        specifiedSize = minSize;

    // Now apply the "smart minimum." This minimum is also only applied if we're still too small
    // after zooming. The font size must either be relative to the user default or the original size
    // must have been acceptable. In other words, we only apply the smart minimum whenever we're positive
    // doing so won't disrupt the layout.
    if (useSmartMinimumForFontSize && specifiedSize < minLogicalSize && (specifiedSize >= minLogicalSize || !isAbsoluteSize))
        specifiedSize = minLogicalSize;

    // Also clamp to a reasonable maximum to prevent insane font sizes from causing crashes on various
    // platforms (I'm looking at you, Windows.)
    return std::min(maximumAllowedFontSize, specifiedSize);
}

const int fontSizeTableMax = 16;
const int fontSizeTableMin = 9;
const int totalKeywords = 8;

// Strict mode table matches MacIE and Mozilla's settings exactly.
static const int strictFontSizeTable[fontSizeTableMax - fontSizeTableMin + 1][totalKeywords] =
{
    { 9,    9,     9,     9,    11,    14,    18,    27 },
    { 9,    9,     9,    10,    12,    15,    20,    30 },
    { 9,    9,    10,    11,    13,    17,    22,    33 },
    { 9,    9,    10,    12,    14,    18,    24,    36 },
    { 9,   10,    12,    13,    16,    20,    26,    39 }, // fixed font default (13)
    { 9,   10,    12,    14,    17,    21,    28,    42 },
    { 9,   10,    13,    15,    18,    23,    30,    45 },
    { 9,   10,    13,    16,    18,    24,    32,    48 } // proportional font default (16)
};
// HTML       1      2      3      4      5      6      7
// CSS  xxs   xs     s      m      l     xl     xxl
//                          |
//                      user pref

// For values outside the range of the table, we use Todd Fahrner's suggested scale
// factors for each keyword value.
static const float fontSizeFactors[totalKeywords] = { 0.60f, 0.75f, 0.89f, 1.0f, 1.2f, 1.5f, 2.0f, 3.0f };

static int inline rowFromMediumFontSizeInRange(const Settings* settings, FixedPitchFontType fixedPitchFontType, int& mediumSize)
{
    mediumSize = fixedPitchFontType == FixedPitchFont ? settings->defaultFixedFontSize() : settings->defaultFontSize();
    if (mediumSize >= fontSizeTableMin && mediumSize <= fontSizeTableMax)
        return mediumSize - fontSizeTableMin;
    return -1;
}

float FontSize::fontSizeForKeyword(const Document* document, CSSValueID keyword, FixedPitchFontType fixedPitchFontType)
{
    ASSERT(keyword >= CSSValueXxSmall && keyword <= CSSValueWebkitXxxLarge);
    const Settings* settings = document->settings();
    if (!settings)
        return 1.0f;

    int mediumSize = 0;
    int row = rowFromMediumFontSizeInRange(settings, fixedPitchFontType, mediumSize);
    if (row >= 0) {
        int col = (keyword - CSSValueXxSmall);
        return strictFontSizeTable[row][col];
    }

    // Value is outside the range of the table. Apply the scale factor instead.
    float minLogicalSize = 1;
    return std::max(fontSizeFactors[keyword - CSSValueXxSmall] * mediumSize, minLogicalSize);
}



template<typename T>
static int findNearestLegacyFontSize(int pixelFontSize, const T* table, int multiplier)
{
    // Ignore table[0] because xx-small does not correspond to any legacy font size.
    for (int i = 1; i < totalKeywords - 1; i++) {
        if (pixelFontSize * 2 < (table[i] + table[i + 1]) * multiplier)
            return i;
    }
    return totalKeywords - 1;
}

int FontSize::legacyFontSize(const Document* document, int pixelFontSize, FixedPitchFontType fixedPitchFontType)
{
    const Settings* settings = document->settings();
    if (!settings)
        return 1;

    int mediumSize = 0;
    int row = rowFromMediumFontSizeInRange(settings, fixedPitchFontType, mediumSize);
    if (row >= 0)
        return findNearestLegacyFontSize<int>(pixelFontSize, strictFontSizeTable[row], 1);

    return findNearestLegacyFontSize<float>(pixelFontSize, fontSizeFactors, mediumSize);
}

} // namespace blink
