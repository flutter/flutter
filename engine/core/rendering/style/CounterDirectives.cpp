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
#include "core/rendering/style/CounterDirectives.h"
#include "wtf/PassOwnPtr.h"

namespace blink {

bool operator==(const CounterDirectives& a, const CounterDirectives& b)
{
    return a.isIncrement() == b.isIncrement()
      && a.incrementValue() == b.incrementValue()
      && a.isReset() == b.isReset()
      && a.resetValue() == b.resetValue();
}

PassOwnPtr<CounterDirectiveMap> clone(const CounterDirectiveMap& counterDirectives)
{
    OwnPtr<CounterDirectiveMap> result = adoptPtr(new CounterDirectiveMap);
    *result = counterDirectives;
    return result.release();
}

} // namespace blink
