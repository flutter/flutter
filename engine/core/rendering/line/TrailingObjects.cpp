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

#include "config.h"
#include "core/rendering/line/TrailingObjects.h"

#include "core/rendering/InlineIterator.h"

namespace blink {

void TrailingObjects::updateMidpointsForTrailingObjects(LineMidpointState& lineMidpointState, const InlineIterator& lBreak, CollapseFirstSpaceOrNot collapseFirstSpace)
{
    if (!m_whitespace)
        return;

    // This object is either going to be part of the last midpoint, or it is going to be the actual endpoint.
    // In both cases we just decrease our pos by 1 level to exclude the space, allowing it to - in effect - collapse into the newline.
    if (lineMidpointState.numMidpoints() % 2) {
        // Find the trailing space object's midpoint.
        int trailingSpaceMidpoint = lineMidpointState.numMidpoints() - 1;
        for ( ; trailingSpaceMidpoint > 0 && lineMidpointState.midpoints()[trailingSpaceMidpoint].object() != m_whitespace; --trailingSpaceMidpoint) { }
        ASSERT(trailingSpaceMidpoint >= 0);
        if (collapseFirstSpace == CollapseFirstSpace)
            lineMidpointState.midpoints()[trailingSpaceMidpoint].setOffset(lineMidpointState.midpoints()[trailingSpaceMidpoint].offset() -1);

        // Now make sure every single trailingPositionedBox following the trailingSpaceMidpoint properly stops and starts
        // ignoring spaces.
        size_t currentMidpoint = trailingSpaceMidpoint + 1;
        for (size_t i = 0; i < m_objects.size(); ++i) {
            if (currentMidpoint >= lineMidpointState.numMidpoints()) {
                // We don't have a midpoint for this box yet.
                lineMidpointState.ensureLineBoxInsideIgnoredSpaces(m_objects[i]);
            } else {
                ASSERT(lineMidpointState.midpoints()[currentMidpoint].object() == m_objects[i]);
                ASSERT(lineMidpointState.midpoints()[currentMidpoint + 1].object() == m_objects[i]);
            }
            currentMidpoint += 2;
        }
    } else if (!lBreak.object()) {
        ASSERT(collapseFirstSpace == CollapseFirstSpace);
        // Add a new end midpoint that stops right at the very end.
        unsigned length = m_whitespace->textLength();
        unsigned pos = length >= 2 ? length - 2 : UINT_MAX;
        InlineIterator endMid(0, m_whitespace, pos);
        lineMidpointState.startIgnoringSpaces(endMid);
        for (size_t i = 0; i < m_objects.size(); ++i) {
            lineMidpointState.ensureLineBoxInsideIgnoredSpaces(m_objects[i]);
        }
    }
}

}
