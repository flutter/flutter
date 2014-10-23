/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Graham Dennis (graham.dennis@gmail.com)
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
 *
 */

#ifndef BorderValue_h
#define BorderValue_h

#include "core/css/StyleColor.h"
#include "core/rendering/style/RenderStyleConstants.h"
#include "platform/graphics/Color.h"

namespace blink {

class BorderValue {
friend class RenderStyle;
public:
    BorderValue()
        : m_color(0)
        , m_colorIsCurrentColor(true)
        , m_width(3)
        , m_style(BNONE)
        , m_isAuto(AUTO_OFF)
    {
    }

    bool nonZero(bool checkStyle = true) const
    {
        return width() && (!checkStyle || m_style != BNONE);
    }

    bool isTransparent() const
    {
        return !m_colorIsCurrentColor && !m_color.alpha();
    }

    bool isVisible(bool checkStyle = true) const
    {
        return nonZero(checkStyle) && !isTransparent() && (!checkStyle || m_style != BHIDDEN);
    }

    bool operator==(const BorderValue& o) const
    {
        return m_width == o.m_width && m_style == o.m_style && m_color == o.m_color && m_colorIsCurrentColor == o.m_colorIsCurrentColor;
    }

    // The default width is 3px, but if the style is none we compute a value of 0 (in RenderStyle itself)
    bool visuallyEqual(const BorderValue& o) const
    {
        if (m_style == BNONE && o.m_style == BNONE)
            return true;
        if (m_style == BHIDDEN && o.m_style == BHIDDEN)
            return true;
        return *this == o;
    }

    bool operator!=(const BorderValue& o) const
    {
        return !(*this == o);
    }

    void setColor(const StyleColor& color)
    {
        m_color = color.resolve(Color());
        m_colorIsCurrentColor = color.isCurrentColor();
    }

    StyleColor color() const { return m_colorIsCurrentColor ? StyleColor::currentColor() : StyleColor(m_color); }

    unsigned width() const { return m_width; }

    EBorderStyle style() const { return static_cast<EBorderStyle>(m_style); }
    void setStyle(EBorderStyle style) { m_style = style; }

protected:
    Color m_color;
    unsigned m_colorIsCurrentColor : 1;

    unsigned m_width : 26;
    unsigned m_style : 4; // EBorderStyle

    // This is only used by OutlineValue but moved here to keep the bits packed.
    unsigned m_isAuto : 1; // OutlineIsAuto
};

} // namespace blink

#endif // BorderValue_h
