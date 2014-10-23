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

#ifndef KeyframeList_h
#define KeyframeList_h

#include "core/CSSPropertyNames.h"
#include "core/rendering/style/StyleInheritedData.h"
#include "wtf/HashSet.h"
#include "wtf/RefPtr.h"
#include "wtf/Vector.h"
#include "wtf/text/AtomicString.h"

namespace blink {

class RenderObject;
class RenderStyle;

class KeyframeValue {
public:
    KeyframeValue(double key, PassRefPtr<RenderStyle> style)
        : m_key(key)
        , m_style(style)
    {
    }

    void addProperty(CSSPropertyID prop) { m_properties.add(prop); }
    bool containsProperty(CSSPropertyID prop) const { return m_properties.contains(prop); }
    const HashSet<CSSPropertyID>& properties() const { return m_properties; }

    double key() const { return m_key; }
    void setKey(double key) { m_key = key; }

    const RenderStyle* style() const { return m_style.get(); }
    void setStyle(PassRefPtr<RenderStyle> style) { m_style = style; }

private:
    double m_key;
    HashSet<CSSPropertyID> m_properties; // The properties specified in this keyframe.
    RefPtr<RenderStyle> m_style;
};

class KeyframeList {
public:
    KeyframeList(RenderObject&, const AtomicString& animationName)
        : m_animationName(animationName)
    {
        insert(KeyframeValue(0, nullptr));
        insert(KeyframeValue(1, nullptr));
    }
    ~KeyframeList();

    const AtomicString& animationName() const { return m_animationName; }

    void insert(const KeyframeValue& keyframe);

    void addProperty(CSSPropertyID prop) { m_properties.add(prop); }
    bool containsProperty(CSSPropertyID prop) const { return m_properties.contains(prop); }
    HashSet<CSSPropertyID>::const_iterator beginProperties() const { return m_properties.begin(); }
    HashSet<CSSPropertyID>::const_iterator endProperties() const { return m_properties.end(); }

    void clear();
    bool isEmpty() const { return m_keyframes.isEmpty(); }
    size_t size() const { return m_keyframes.size(); }
    const KeyframeValue& operator[](size_t index) const { return m_keyframes[index]; }

private:
    AtomicString m_animationName;
    Vector<KeyframeValue> m_keyframes; // Kept sorted by key.
    HashSet<CSSPropertyID> m_properties; // The properties being animated.
};

} // namespace blink

#endif // KeyframeList_h
