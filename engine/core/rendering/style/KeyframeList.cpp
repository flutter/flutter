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
#include "core/rendering/style/KeyframeList.h"

#include "core/animation/Animation.h"
#include "core/css/StylePropertySet.h"
#include "core/rendering/RenderObject.h"

namespace blink {

KeyframeList::~KeyframeList()
{
    clear();
}

void KeyframeList::clear()
{
    m_keyframes.clear();
    m_properties.clear();
}

void KeyframeList::insert(const KeyframeValue& keyframe)
{
    if (keyframe.key() < 0 || keyframe.key() > 1)
        return;

    bool inserted = false;
    bool replaced = false;
    for (size_t i = 0; i < m_keyframes.size(); ++i) {
        if (m_keyframes[i].key() == keyframe.key()) {
            m_keyframes[i] = keyframe;
            replaced = true;
            break;
        }

        if (m_keyframes[i].key() > keyframe.key()) {
            // insert before
            m_keyframes.insert(i, keyframe);
            inserted = true;
            break;
        }
    }

    if (!replaced && !inserted)
        m_keyframes.append(keyframe);

    if (replaced) {
        // We have to rebuild the properties list from scratch.
        m_properties.clear();
        for (Vector<KeyframeValue>::const_iterator it = m_keyframes.begin(); it != m_keyframes.end(); ++it) {
            const KeyframeValue& currKeyframe = *it;
            for (HashSet<CSSPropertyID>::const_iterator it = currKeyframe.properties().begin(); it != currKeyframe.properties().end(); ++it)
                m_properties.add(*it);
        }
    } else {
        for (HashSet<CSSPropertyID>::const_iterator it = keyframe.properties().begin(); it != keyframe.properties().end(); ++it)
            m_properties.add(*it);
    }
}

} // namespace blink
