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

#ifndef CollapsedBorderValue_h
#define CollapsedBorderValue_h

#include "core/rendering/style/BorderValue.h"

namespace blink {

class CollapsedBorderValue {
public:
    CollapsedBorderValue()
        : m_color(0)
        , m_colorIsCurrentColor(true)
        , m_width(0)
        , m_style(BNONE)
        , m_precedence(BOFF)
        , m_transparent(false)
    {
    }

    CollapsedBorderValue(const BorderValue& border, const StyleColor& color, EBorderPrecedence precedence)
        : m_color(color.resolve(Color()))
        , m_colorIsCurrentColor(color.isCurrentColor())
        , m_width(border.nonZero() ? border.width() : 0)
        , m_style(border.style())
        , m_precedence(precedence)
        , m_transparent(border.isTransparent())
    {
    }

    unsigned width() const { return m_style > BHIDDEN ? m_width : 0; }
    EBorderStyle style() const { return static_cast<EBorderStyle>(m_style); }
    bool exists() const { return m_precedence != BOFF; }
    StyleColor color() const { return m_colorIsCurrentColor ? StyleColor::currentColor() : StyleColor(m_color); }
    bool isTransparent() const { return m_transparent; }
    EBorderPrecedence precedence() const { return static_cast<EBorderPrecedence>(m_precedence); }

    bool isSameIgnoringColor(const CollapsedBorderValue& o) const
    {
        return width() == o.width() && style() == o.style() && precedence() == o.precedence();
    }

private:
    Color m_color;
    unsigned m_colorIsCurrentColor : 1;
    unsigned m_width : 23;
    unsigned m_style : 4; // EBorderStyle
    unsigned m_precedence : 3; // EBorderPrecedence
    unsigned m_transparent : 1;
};

} // namespace blink

#endif // CollapsedBorderValue_h
