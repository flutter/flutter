/*
 * Copyright (C) 2005, 2006, 2009 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_DOM_QUALIFIEDNAME_H_
#define SKY_ENGINE_CORE_DOM_QUALIFIEDNAME_H_

#include "sky/engine/wtf/text/AtomicString.h"

namespace blink {

class QualifiedName {
    WTF_MAKE_FAST_ALLOCATED;
public:
    explicit QualifiedName(const AtomicString& localName)
        : m_localName(localName)
    { }
    ~QualifiedName() { }

    QualifiedName(const QualifiedName& other)
        : m_localName(other.m_localName)
    { }
    const QualifiedName& operator=(const QualifiedName& other) { m_localName = other.m_localName; return *this; }

    bool operator==(const QualifiedName& other) const { return m_localName == other.m_localName; }
    bool operator!=(const QualifiedName& other) const { return !(*this == other); }

    const AtomicString& localName() const { return m_localName; }

    static void init();
    static void createStatic(void* targetAddress, StringImpl* name);

private:
    AtomicString m_localName;
};

extern const QualifiedName& anyName;
extern const QualifiedName& nullName;

inline bool operator==(const AtomicString& a, const QualifiedName& q) { return a == q.localName(); }
inline bool operator!=(const AtomicString& a, const QualifiedName& q) { return a != q.localName(); }
inline bool operator==(const QualifiedName& q, const AtomicString& a) { return a == q.localName(); }
inline bool operator!=(const QualifiedName& q, const AtomicString& a) { return a != q.localName(); }

} // namespace blink

#endif  // SKY_ENGINE_CORE_DOM_QUALIFIEDNAME_H_
