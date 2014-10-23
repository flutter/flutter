/*
    Copyright (C) 2005, 2006 Apple Inc. All rights reserved.

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public License
    along with this library; see the file COPYING.LIB.  If not, write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110-1301, USA.


    Some useful definitions needed for laying out elements
*/

#ifndef GapRects_h
#define GapRects_h

#include "platform/geometry/LayoutRect.h"

namespace blink {

    struct GapRects {
        const LayoutRect& left() const { return m_left; }
        const LayoutRect& center() const { return m_center; }
        const LayoutRect& right() const { return m_right; }

        void uniteLeft(const LayoutRect& r) { m_left.unite(r); }
        void uniteCenter(const LayoutRect& r) { m_center.unite(r); }
        void uniteRight(const LayoutRect& r) { m_right.unite(r); }
        void unite(const GapRects& o) { uniteLeft(o.left()); uniteCenter(o.center()); uniteRight(o.right()); }

        operator LayoutRect() const
        {
            LayoutRect result = m_left;
            result.unite(m_center);
            result.unite(m_right);
            return result;
        }

        bool operator==(const GapRects& other)
        {
            return m_left == other.left() && m_center == other.center() && m_right == other.right();
        }
        bool operator!=(const GapRects& other) { return !(*this == other); }

    private:
        LayoutRect m_left;
        LayoutRect m_center;
        LayoutRect m_right;
    };

} // namespace blink

#endif // GapRects_h
