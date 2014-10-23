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
#include "core/rendering/style/StyleBackgroundData.h"

#include "core/rendering/style/RenderStyle.h"
#include "core/rendering/style/RenderStyleConstants.h"

namespace blink {

StyleBackgroundData::StyleBackgroundData()
    : m_background(BackgroundFillLayer, true)
    , m_color(RenderStyle::initialBackgroundColor())
{
}

StyleBackgroundData::StyleBackgroundData(const StyleBackgroundData& o)
    : RefCounted<StyleBackgroundData>()
    , m_background(o.m_background)
    , m_color(o.m_color)
    , m_outline(o.m_outline)
{
}

bool StyleBackgroundData::operator==(const StyleBackgroundData& o) const
{
    return m_background == o.m_background && m_color == o.m_color && m_outline == o.m_outline;
}

bool StyleBackgroundData::visuallyEqual(const StyleBackgroundData& o) const
{
    return m_background == o.m_background && m_color == o.m_color && m_outline.visuallyEqual(o.m_outline);
}

} // namespace blink
