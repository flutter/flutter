/*
 * Copyright (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
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
#include "core/rendering/style/ShadowData.h"

#include "platform/animation/AnimationUtilities.h"

namespace blink {

bool ShadowData::operator==(const ShadowData& o) const
{
    return m_location == o.m_location
        && m_blur == o.m_blur
        && m_spread == o.m_spread
        && m_style == o.m_style
        && m_color == o.m_color;
}

ShadowData ShadowData::blend(const ShadowData& from, double progress) const
{
    if (style() != from.style())
        return *this;

    return ShadowData(blink::blend(from.location(), location(), progress),
        clampTo(blink::blend(from.blur(), blur(), progress), 0.0f),
        blink::blend(from.spread(), spread(), progress),
        style(),
        blink::blend(from.color(), color(), progress));
}

} // namespace blink
