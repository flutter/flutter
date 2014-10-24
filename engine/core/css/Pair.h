/*
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2005, 2006 Apple Computer, Inc.
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
 */

#ifndef Pair_h
#define Pair_h

#include "core/css/CSSPrimitiveValue.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

// A primitive value representing a pair.  This is useful for properties like border-radius, background-size/position,
// and border-spacing (all of which are space-separated sets of two values).  At the moment we are only using it for
// border-radius and background-size, but (FIXME) border-spacing and background-position could be converted over to use
// it (eliminating some extra -webkit- internal properties).
class Pair final : public RefCountedWillBeGarbageCollected<Pair> {
public:
    enum IdenticalValuesPolicy { DropIdenticalValues, KeepIdenticalValues };

    static PassRefPtrWillBeRawPtr<Pair> create(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> first, PassRefPtrWillBeRawPtr<CSSPrimitiveValue> second,
        IdenticalValuesPolicy identicalValuesPolicy)
    {
        return adoptRefWillBeNoop(new Pair(first, second, identicalValuesPolicy));
    }

    CSSPrimitiveValue* first() const { return m_first.get(); }
    CSSPrimitiveValue* second() const { return m_second.get(); }
    IdenticalValuesPolicy identicalValuesPolicy() const { return m_identicalValuesPolicy; }

    void setFirst(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> first) { m_first = first; }
    void setSecond(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> second) { m_second = second; }
    void setIdenticalValuesPolicy(IdenticalValuesPolicy identicalValuesPolicy) { m_identicalValuesPolicy = identicalValuesPolicy; }

    String cssText() const
    {
        return generateCSSString(first()->cssText(), second()->cssText(), m_identicalValuesPolicy);
    }

    bool equals(const Pair& other) const
    {
        return compareCSSValuePtr(m_first, other.m_first)
            && compareCSSValuePtr(m_second, other.m_second)
            && m_identicalValuesPolicy == other.m_identicalValuesPolicy;
    }

    void trace(Visitor*);

private:
    Pair()
        : m_first(nullptr)
        , m_second(nullptr)
        , m_identicalValuesPolicy(DropIdenticalValues) { }

    Pair(PassRefPtrWillBeRawPtr<CSSPrimitiveValue> first, PassRefPtrWillBeRawPtr<CSSPrimitiveValue> second, IdenticalValuesPolicy identicalValuesPolicy)
        : m_first(first)
        , m_second(second)
        , m_identicalValuesPolicy(identicalValuesPolicy) { }

    static String generateCSSString(const String& first, const String& second, IdenticalValuesPolicy identicalValuesPolicy)
    {
        if (identicalValuesPolicy == DropIdenticalValues && first == second)
            return first;
        return first + ' ' + second;
    }

    RefPtrWillBeMember<CSSPrimitiveValue> m_first;
    RefPtrWillBeMember<CSSPrimitiveValue> m_second;
    IdenticalValuesPolicy m_identicalValuesPolicy;
};

} // namespace

#endif
