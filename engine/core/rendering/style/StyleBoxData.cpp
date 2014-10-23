/*
 * Copyright (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
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

#include "config.h"
#include "core/rendering/style/StyleBoxData.h"

#include "core/rendering/style/RenderStyle.h"

namespace blink {

struct SameSizeAsStyleBoxData : public RefCounted<SameSizeAsStyleBoxData> {
    Length length[7];
    int m_zIndex;
    uint32_t bitfields;
};

COMPILE_ASSERT(sizeof(StyleBoxData) == sizeof(SameSizeAsStyleBoxData), StyleBoxData_should_not_grow);

StyleBoxData::StyleBoxData()
    : m_minWidth(RenderStyle::initialMinSize())
    , m_maxWidth(RenderStyle::initialMaxSize())
    , m_minHeight(RenderStyle::initialMinSize())
    , m_maxHeight(RenderStyle::initialMaxSize())
    , m_zIndex(0)
    , m_hasAutoZIndex(true)
    , m_boxSizing(CONTENT_BOX)
    , m_boxDecorationBreak(DSLICE)
{
}

StyleBoxData::StyleBoxData(const StyleBoxData& o)
    : RefCounted<StyleBoxData>()
    , m_width(o.m_width)
    , m_height(o.m_height)
    , m_minWidth(o.m_minWidth)
    , m_maxWidth(o.m_maxWidth)
    , m_minHeight(o.m_minHeight)
    , m_maxHeight(o.m_maxHeight)
    , m_verticalAlign(o.m_verticalAlign)
    , m_zIndex(o.m_zIndex)
    , m_hasAutoZIndex(o.m_hasAutoZIndex)
    , m_boxSizing(o.m_boxSizing)
    , m_boxDecorationBreak(o.m_boxDecorationBreak)
{
}

bool StyleBoxData::operator==(const StyleBoxData& o) const
{
    return m_width == o.m_width
           && m_height == o.m_height
           && m_minWidth == o.m_minWidth
           && m_maxWidth == o.m_maxWidth
           && m_minHeight == o.m_minHeight
           && m_maxHeight == o.m_maxHeight
           && m_verticalAlign == o.m_verticalAlign
           && m_zIndex == o.m_zIndex
           && m_hasAutoZIndex == o.m_hasAutoZIndex
           && m_boxSizing == o.m_boxSizing
           && m_boxDecorationBreak == o.m_boxDecorationBreak
            ;
}

} // namespace blink
