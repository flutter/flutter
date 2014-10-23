/*
 * Copyright (C) 2008 Apple Inc. All Rights Reserved.
 * Copyright (C) 2002, 2003 The Karbon Developers
 * Copyright (C) 2006, 2007 Rob Buis <buis@kde.org>
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

#ifndef ParserUtilities_h
#define ParserUtilities_h

#include "wtf/text/WTFString.h"

namespace blink {

template<typename CharType>
inline bool skipString(const CharType*& ptr, const CharType* end, const CharType* name, int length)
{
    if (end - ptr < length)
        return false;
    if (memcmp(name, ptr, sizeof(CharType) * length))
        return false;
    ptr += length;
    return true;
}

inline bool skipString(const UChar*& ptr, const UChar* end, const LChar* name, int length)
{
    if (end - ptr < length)
        return false;
    for (int i = 0; i < length; ++i) {
        if (ptr[i] != name[i])
            return false;
    }
    ptr += length;
    return true;
}

template<typename CharType>
inline bool skipString(const CharType*& ptr, const CharType* end, const char* str)
{
    int length = strlen(str);
    if (end - ptr < length)
        return false;
    for (int i = 0; i < length; ++i) {
        if (ptr[i] != str[i])
            return false;
    }
    ptr += length;
    return true;
}

} // namespace blink

#endif // ParserUtilities_h
