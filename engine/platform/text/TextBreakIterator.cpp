/*
 * (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2007-2009 Torch Mobile, Inc.
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

#include "config.h"
#include "platform/text/TextBreakIterator.h"

namespace blink {

unsigned numGraphemeClusters(const String& string)
{
    unsigned stringLength = string.length();

    if (!stringLength)
        return 0;

    // The only Latin-1 Extended Grapheme Cluster is CR LF
    if (string.is8Bit() && !string.contains('\r'))
        return stringLength;

    NonSharedCharacterBreakIterator it(string);
    if (!it)
        return stringLength;

    unsigned num = 0;
    while (it.next() != TextBreakDone)
        ++num;
    return num;
}

unsigned numCharactersInGraphemeClusters(const String& string, unsigned numGraphemeClusters)
{
    unsigned stringLength = string.length();

    if (!stringLength)
        return 0;

    // The only Latin-1 Extended Grapheme Cluster is CR LF
    if (string.is8Bit() && !string.contains('\r'))
        return std::min(stringLength, numGraphemeClusters);

    NonSharedCharacterBreakIterator it(string);
    if (!it)
        return std::min(stringLength, numGraphemeClusters);

    for (unsigned i = 0; i < numGraphemeClusters; ++i) {
        if (it.next() == TextBreakDone)
            return stringLength;
    }
    return it.current();
}

} // namespace blink
