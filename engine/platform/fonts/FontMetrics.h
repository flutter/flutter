/*
 * Copyright (C) Research In Motion Limited 2010-2011. All rights reserved.
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

#ifndef FontMetrics_h
#define FontMetrics_h

#include "platform/fonts/FontBaseline.h"
#include "wtf/MathExtras.h"

namespace blink {

const unsigned gDefaultUnitsPerEm = 1000;

class FontMetrics {
public:
    FontMetrics()
        : m_unitsPerEm(gDefaultUnitsPerEm)
        , m_ascent(0)
        , m_descent(0)
        , m_lineGap(0)
        , m_lineSpacing(0)
        , m_xHeight(0)
        , m_zeroWidth(0)
        , m_underlinethickness(0)
        , m_underlinePosition(0)
        , m_hasXHeight(false)
        , m_hasZeroWidth(false)
    {
    }

    unsigned unitsPerEm() const { return m_unitsPerEm; }
    void setUnitsPerEm(unsigned unitsPerEm) { m_unitsPerEm = unitsPerEm; }

    float floatAscent(FontBaseline baselineType = AlphabeticBaseline) const
    {
        if (baselineType == AlphabeticBaseline)
            return m_ascent;
        return floatHeight() / 2;
    }

    void setAscent(float ascent) { m_ascent = ascent; }

    float floatDescent(FontBaseline baselineType = AlphabeticBaseline) const
    {
        if (baselineType == AlphabeticBaseline)
            return m_descent;
        return floatHeight() / 2;
    }

    void setDescent(float descent) { m_descent = descent; }

    float floatHeight(FontBaseline baselineType = AlphabeticBaseline) const
    {
        return floatAscent(baselineType) + floatDescent(baselineType);
    }

    float floatLineGap() const { return m_lineGap; }
    void setLineGap(float lineGap) { m_lineGap = lineGap; }

    float floatLineSpacing() const { return m_lineSpacing; }
    void setLineSpacing(float lineSpacing) { m_lineSpacing = lineSpacing; }

    float xHeight() const { return m_xHeight; }
    void setXHeight(float xHeight)
    {
        m_xHeight = xHeight;
        m_hasXHeight = true;
    }

    bool hasXHeight() const { return m_hasXHeight && m_xHeight > 0; }
    void setHasXHeight(bool hasXHeight) { m_hasXHeight = hasXHeight; }

    // Integer variants of certain metrics, used for HTML rendering.
    int ascent(FontBaseline baselineType = AlphabeticBaseline) const
    {
        if (baselineType == AlphabeticBaseline)
            return lroundf(m_ascent);
        return height() - height() / 2;
    }

    int descent(FontBaseline baselineType = AlphabeticBaseline) const
    {
        if (baselineType == AlphabeticBaseline)
            return lroundf(m_descent);
        return height() / 2;
    }

    int height(FontBaseline baselineType = AlphabeticBaseline) const
    {
        return ascent(baselineType) + descent(baselineType);
    }

    int lineGap() const { return lroundf(m_lineGap); }
    int lineSpacing() const { return lroundf(m_lineSpacing); }

    bool hasIdenticalAscentDescentAndLineGap(const FontMetrics& other) const
    {
        return ascent() == other.ascent() && descent() == other.descent() && lineGap() == other.lineGap();
    }

    float zeroWidth() const { return m_zeroWidth; }
    void setZeroWidth(float zeroWidth)
    {
        m_zeroWidth = zeroWidth;
        m_hasZeroWidth = true;
    }

    bool hasZeroWidth() const { return m_hasZeroWidth; }
    void setHasZeroWidth(bool hasZeroWidth) { m_hasZeroWidth = hasZeroWidth; }

    float underlineThickness() const { return m_underlinethickness; }
    void setUnderlineThickness(float underlineThickness) { m_underlinethickness = underlineThickness; }

    float underlinePosition() const { return m_underlinePosition; }
    void setUnderlinePosition(float underlinePosition) { m_underlinePosition = underlinePosition; }

private:
    friend class SimpleFontData;

    void reset()
    {
        m_unitsPerEm = gDefaultUnitsPerEm;
        m_ascent = 0;
        m_descent = 0;
        m_lineGap = 0;
        m_lineSpacing = 0;
        m_xHeight = 0;
        m_hasXHeight = false;
        m_underlinethickness = 0;
        m_underlinePosition = 0;
    }

    unsigned m_unitsPerEm;
    float m_ascent;
    float m_descent;
    float m_lineGap;
    float m_lineSpacing;
    float m_xHeight;
    float m_zeroWidth;
    float m_underlinethickness;
    float m_underlinePosition;
    bool m_hasXHeight;
    bool m_hasZeroWidth;
};

inline float scaleEmToUnits(float x, unsigned unitsPerEm)
{
    return unitsPerEm ? x / unitsPerEm : x;
}

} // namespace blink

#endif // FontMetrics_h
