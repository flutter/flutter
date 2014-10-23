/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2006, 2007, 2009, 2010 Apple Inc. All right reserved.
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

#ifndef BidiContext_h
#define BidiContext_h

#include "platform/PlatformExport.h"
#include "wtf/Assertions.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/RefPtr.h"
#include "wtf/unicode/Unicode.h"

namespace blink {

enum BidiEmbeddingSource {
    FromStyleOrDOM,
    FromUnicode
};

// Used to keep track of explicit embeddings.
class PLATFORM_EXPORT BidiContext : public RefCounted<BidiContext> {
public:
    static PassRefPtr<BidiContext> create(unsigned char level, WTF::Unicode::Direction, bool override = false, BidiEmbeddingSource = FromStyleOrDOM, BidiContext* parent = 0);

    BidiContext* parent() const { return m_parent.get(); }
    unsigned char level() const { return m_level; }
    WTF::Unicode::Direction dir() const { return static_cast<WTF::Unicode::Direction>(m_direction); }
    bool override() const { return m_override; }
    BidiEmbeddingSource source() const { return static_cast<BidiEmbeddingSource>(m_source); }

    PassRefPtr<BidiContext> copyStackRemovingUnicodeEmbeddingContexts();

    // http://www.unicode.org/reports/tr9/#Modifications
    // 6.3 raised the limit from 61 to 125.
    // http://unicode.org/reports/tr9/#BD2
    static const unsigned char kMaxLevel = 125;

private:
    BidiContext(unsigned char level, WTF::Unicode::Direction direction, bool override, BidiEmbeddingSource source, BidiContext* parent)
        : m_level(level)
        , m_direction(direction)
        , m_override(override)
        , m_source(source)
        , m_parent(parent)
    {
        ASSERT(level <= kMaxLevel);
    }

    static PassRefPtr<BidiContext> createUncached(unsigned char level, WTF::Unicode::Direction, bool override, BidiEmbeddingSource, BidiContext* parent);

    unsigned m_level : 7; // The maximium bidi level is 125: http://unicode.org/reports/tr9/#Explicit_Levels_and_Directions
    unsigned m_direction : 5; // Direction
    unsigned m_override : 1;
    unsigned m_source : 1; // BidiEmbeddingSource
    RefPtr<BidiContext> m_parent;
};

inline unsigned char nextGreaterOddLevel(unsigned char level)
{
    return (level + 1) | 1;
}

inline unsigned char nextGreaterEvenLevel(unsigned char level)
{
    return (level + 2) & ~1;
}

PLATFORM_EXPORT bool operator==(const BidiContext&, const BidiContext&);

} // namespace blink

#endif // BidiContext_h
