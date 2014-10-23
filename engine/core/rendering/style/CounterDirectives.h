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

#ifndef CounterDirectives_h
#define CounterDirectives_h

#include "wtf/HashMap.h"
#include "wtf/MathExtras.h"
#include "wtf/RefPtr.h"
#include "wtf/text/AtomicString.h"
#include "wtf/text/AtomicStringHash.h"

namespace blink {

class CounterDirectives {
public:
    CounterDirectives()
        : m_isResetSet(false)
        , m_isIncrementSet(false)
        , m_resetValue(0)
        , m_incrementValue(0)
    {
    }

    // FIXME: The code duplication here could possibly be replaced by using two
    // maps, or by using a container that held two generic Directive objects.

    bool isReset() const { return m_isResetSet; }
    int resetValue() const { return m_resetValue; }
    void setResetValue(int value)
    {
        m_resetValue = value;
        m_isResetSet = true;
    }
    void clearReset()
    {
        m_resetValue = 0;
        m_isResetSet = false;
    }
    void inheritReset(CounterDirectives& parent)
    {
        m_resetValue = parent.m_resetValue;
        m_isResetSet = parent.m_isResetSet;
    }

    bool isIncrement() const { return m_isIncrementSet; }
    int incrementValue() const { return m_incrementValue; }
    void addIncrementValue(int value)
    {
        m_incrementValue = clampToInteger((double)m_incrementValue + value);
        m_isIncrementSet = true;
    }
    void clearIncrement()
    {
        m_incrementValue = 0;
        m_isIncrementSet = false;
    }
    void inheritIncrement(CounterDirectives& parent)
    {
        m_incrementValue = parent.m_incrementValue;
        m_isIncrementSet = parent.m_isIncrementSet;
    }

    bool isDefined() const { return isReset() || isIncrement(); }

    int combinedValue() const
    {
        ASSERT(m_isResetSet || !m_resetValue);
        ASSERT(m_isIncrementSet || !m_incrementValue);
        // FIXME: Shouldn't allow overflow here.
        return m_resetValue + m_incrementValue;
    }

private:
    bool m_isResetSet;
    bool m_isIncrementSet;
    int m_resetValue;
    int m_incrementValue;
};

bool operator==(const CounterDirectives&, const CounterDirectives&);
inline bool operator!=(const CounterDirectives& a, const CounterDirectives& b) { return !(a == b); }

typedef HashMap<AtomicString, CounterDirectives> CounterDirectiveMap;

PassOwnPtr<CounterDirectiveMap> clone(const CounterDirectiveMap&);

} // namespace blink

#endif // CounterDirectives_h
