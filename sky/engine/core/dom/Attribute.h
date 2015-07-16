/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Peter Kelly (pmk@post.com)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2008, 2012 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_DOM_ATTRIBUTE_H_
#define SKY_ENGINE_CORE_DOM_ATTRIBUTE_H_

#include "sky/engine/core/dom/QualifiedName.h"

namespace blink {

// This has no counterpart in DOM.
// It is an internal representation of the node value of an Attr.
// The actual Attr with its value as a Text child is allocated only if needed.
class Attribute {
public:
    Attribute(const QualifiedName& name, const AtomicString& value)
        : m_name(name)
        , m_value(value)
    {
    }

    // NOTE: The references returned by these functions are only valid for as long
    // as the Attribute stays in place. For example, calling a function that mutates
    // an Element's internal attribute storage may invalidate them.
    const AtomicString& value() const { return m_value; }
    const AtomicString& localName() const { return m_name.localName(); }

    const QualifiedName& name() const { return m_name; }

    bool isEmpty() const { return m_value.isEmpty(); }
    bool matches(const QualifiedName&) const;

    void setValue(const AtomicString& value) { m_value = value; }

    // Note: This API is only for HTMLTreeBuilder.  It is not safe to change the
    // name of an attribute once parseAttribute has been called as DOM
    // elements may have placed the Attribute in a hash by name.
    void parserSetName(const QualifiedName& name) { m_name = name; }

private:
    QualifiedName m_name;
    AtomicString m_value;
};

inline bool Attribute::matches(const QualifiedName& qualifiedName) const
{
    return qualifiedName.localName() == localName();
}

} // namespace blink

#endif  // SKY_ENGINE_CORE_DOM_ATTRIBUTE_H_
