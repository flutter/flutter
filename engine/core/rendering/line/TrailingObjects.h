/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All right reserved.
 * Copyright (C) 2010 Google Inc. All rights reserved.
 * Copyright (C) 2014 Adobe Systems Inc.
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

#ifndef TrailingObjects_h
#define TrailingObjects_h

#include "wtf/Vector.h"

namespace blink {

class InlineIterator;
class RenderObject;
class RenderText;

struct BidiRun;

template <class Iterator, class Run> class BidiResolver;
template <class Iterator> class MidpointState;
typedef BidiResolver<InlineIterator, BidiRun> InlineBidiResolver;
typedef MidpointState<InlineIterator> LineMidpointState;

// This class allows us to ensure lineboxes are created in the right place on the line when
// an out-of-flow positioned object or an empty inline is encountered between a trailing space
// and subsequent spaces and we want to ignore (i.e. collapse) surplus whitespace. So for example:
//   <div>X <span></span> Y</div>
// or
//   <div>X <div style="position: absolute"></div> Y</div>
// In both of the above snippets the inline and the positioned object occur after a trailing space
// and before a space that will cause our line breaking algorithm to start ignoring spaces. When it
// does that we want to ensure that the inline/positioned object gets a linebox and that it is part
// of the collapsed whitespace. So to achieve this we use appendObjectIfNeeded() to keep track of
// objects encountered after a trailing whitespace and updateMidpointsForTrailingObjects() to put
// them in the right place when we start ignoring surplus whitespace.

class TrailingObjects {
public:
    TrailingObjects()
        : m_whitespace(0)
    {
    }

    void setTrailingWhitespace(RenderText* whitespace)
    {
        ASSERT(whitespace);
        m_whitespace = whitespace;
    }

    void clear()
    {
        m_whitespace = 0;
        // Using resize(0) rather than clear() here saves 2% on
        // PerformanceTests/Layout/line-layout.html because we avoid freeing and
        // re-allocating the underlying buffer repeatedly.
        m_objects.resize(0);
    }

    void appendObjectIfNeeded(RenderObject* object)
    {
        if (m_whitespace)
            m_objects.append(object);
    }

    enum CollapseFirstSpaceOrNot { DoNotCollapseFirstSpace, CollapseFirstSpace };

    void updateMidpointsForTrailingObjects(LineMidpointState&, const InlineIterator& lBreak, CollapseFirstSpaceOrNot);

private:
    RenderText* m_whitespace;
    Vector<RenderObject*, 4> m_objects;
};

}

#endif // TrailingObjects_h
