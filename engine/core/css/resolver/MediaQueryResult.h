/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#ifndef MediaQueryResult_h
#define MediaQueryResult_h

#include "core/css/MediaQueryExp.h"
#include "wtf/Noncopyable.h"
#include "wtf/RefCounted.h"

namespace blink {

class MediaQueryResult : public RefCountedWillBeGarbageCollectedFinalized<MediaQueryResult> {
    WTF_MAKE_NONCOPYABLE(MediaQueryResult); WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
public:
    MediaQueryResult(const MediaQueryExp& expr, bool result)
#if ENABLE(OILPAN)
        : m_expression(&expr)
#else
        : m_expression(expr)
#endif
        , m_result(result)
    {
    }

    void trace(Visitor* visitor) { visitor->trace(m_expression); }

    const MediaQueryExp* expression() const
    {
#if ENABLE(OILPAN)
        return m_expression;
#else
        return &m_expression;
#endif
    }

    bool result() const { return m_result; }

private:
#if ENABLE(OILPAN)
    Member<const MediaQueryExp> m_expression;
#else
    MediaQueryExp m_expression;
#endif
    bool m_result;
};

}

#endif
