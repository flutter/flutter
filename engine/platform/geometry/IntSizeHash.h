/*
 * Copyright (C) 2006, 2008 Apple Inc. All rights reserved.
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
#ifndef IntSizeHash_h
#define IntSizeHash_h

#include "platform/geometry/IntSize.h"
#include "wtf/HashMap.h"
#include "wtf/HashSet.h"

namespace WTF {

template<> struct IntHash<blink::IntSize> {
    static unsigned hash(const blink::IntSize& key) { return pairIntHash(key.width(), key.height()); }
    static bool equal(const blink::IntSize& a, const blink::IntSize& b) { return a == b; }
    static const bool safeToCompareToEmptyOrDeleted = true;
};

template<> struct DefaultHash<blink::IntSize> {
    typedef IntHash<blink::IntSize> Hash;
};

template<> struct HashTraits<blink::IntSize> : GenericHashTraits<blink::IntSize> {
    static const bool emptyValueIsZero = true;
    static const bool needsDestruction = false;
    static void constructDeletedValue(blink::IntSize& slot, bool) { new (NotNull, &slot) blink::IntSize(-1, -1); }
    static bool isDeletedValue(const blink::IntSize& value) { return value.width() == -1 && value.height() == -1; }
};

} // namespace WTF

#endif
