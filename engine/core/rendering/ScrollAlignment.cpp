/*
 * Copyright (C) 2006, 2007, 2008 Apple Inc. All rights reserved.
 *
 * Portions are Copyright (C) 1998 Netscape Communications Corporation.
 *
 * Other contributors:
 *   Robert O'Callahan <roc+@cs.cmu.edu>
 *   David Baron <dbaron@fas.harvard.edu>
 *   Christian Biesinger <cbiesinger@web.de>
 *   Randall Jesup <rjesup@wgate.com>
 *   Roland Mainz <roland.mainz@informatik.med.uni-giessen.de>
 *   Josh Soref <timeless@mac.com>
 *   Boris Zbarsky <bzbarsky@mit.edu>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * Alternatively, the contents of this file may be used under the terms
 * of either the Mozilla Public License Version 1.1, found at
 * http://www.mozilla.org/MPL/ (the "MPL") or the GNU General Public
 * License Version 2.0, found at http://www.fsf.org/copyleft/gpl.html
 * (the "GPL"), in which case the provisions of the MPL or the GPL are
 * applicable instead of those above.  If you wish to allow use of your
 * version of this file only under the terms of one of those two
 * licenses (the MPL or the GPL) and not to allow others to use your
 * version of this file under the LGPL, indicate your decision by
 * deletingthe provisions above and replace them with the notice and
 * other provisions required by the MPL or the GPL, as the case may be.
 * If you do not delete the provisions above, a recipient may use your
 * version of this file under any of the LGPL, the MPL or the GPL.
 */

#include "config.h"
#include "core/rendering/ScrollAlignment.h"

#include "platform/geometry/LayoutRect.h"

namespace blink {

const ScrollAlignment ScrollAlignment::alignCenterIfNeeded = { ScrollAlignmentNoScroll, ScrollAlignmentCenter, ScrollAlignmentClosestEdge };
const ScrollAlignment ScrollAlignment::alignToEdgeIfNeeded = { ScrollAlignmentNoScroll, ScrollAlignmentClosestEdge, ScrollAlignmentClosestEdge };
const ScrollAlignment ScrollAlignment::alignCenterAlways = { ScrollAlignmentCenter, ScrollAlignmentCenter, ScrollAlignmentCenter };
const ScrollAlignment ScrollAlignment::alignTopAlways = { ScrollAlignmentTop, ScrollAlignmentTop, ScrollAlignmentTop };
const ScrollAlignment ScrollAlignment::alignBottomAlways = { ScrollAlignmentBottom, ScrollAlignmentBottom, ScrollAlignmentBottom };

#define MIN_INTERSECT_FOR_REVEAL 32

LayoutRect ScrollAlignment::getRectToExpose(const LayoutRect& visibleRect, const LayoutRect& exposeRect, const ScrollAlignment& alignX, const ScrollAlignment& alignY)
{
    // Determine the appropriate X behavior.
    ScrollAlignmentBehavior scrollX;
    LayoutRect exposeRectX(exposeRect.x(), visibleRect.y(), exposeRect.width(), visibleRect.height());
    LayoutUnit intersectWidth = intersection(visibleRect, exposeRectX).width();
    if (intersectWidth == exposeRect.width() || intersectWidth >= MIN_INTERSECT_FOR_REVEAL) {
        // If the rectangle is fully visible, use the specified visible behavior.
        // If the rectangle is partially visible, but over a certain threshold,
        // then treat it as fully visible to avoid unnecessary horizontal scrolling
        scrollX = getVisibleBehavior(alignX);
    } else if (intersectWidth == visibleRect.width()) {
        // If the rect is bigger than the visible area, don't bother trying to center. Other alignments will work.
        scrollX = getVisibleBehavior(alignX);
        if (scrollX == ScrollAlignmentCenter)
            scrollX = ScrollAlignmentNoScroll;
    } else if (intersectWidth > 0) {
        // If the rectangle is partially visible, but not above the minimum threshold, use the specified partial behavior
        scrollX = getPartialBehavior(alignX);
    } else {
        scrollX = getHiddenBehavior(alignX);
    }

    if (scrollX == ScrollAlignmentClosestEdge) {
        // Closest edge is the right in two cases:
        // (1) exposeRect to the right of and smaller than visibleRect
        // (2) exposeRect to the left of and larger than visibleRect
        if ((exposeRect.maxX() > visibleRect.maxX() && exposeRect.width() < visibleRect.width())
            || (exposeRect.maxX() < visibleRect.maxX() && exposeRect.width() > visibleRect.width())) {
            scrollX = ScrollAlignmentRight;
        }
    }

    // Given the X behavior, compute the X coordinate.
    LayoutUnit x;
    if (scrollX == ScrollAlignmentNoScroll)
        x = visibleRect.x();
    else if (scrollX == ScrollAlignmentRight)
        x = exposeRect.maxX() - visibleRect.width();
    else if (scrollX == ScrollAlignmentCenter)
        x = exposeRect.x() + (exposeRect.width() - visibleRect.width()) / 2;
    else
        x = exposeRect.x();

    // Determine the appropriate Y behavior.
    ScrollAlignmentBehavior scrollY;
    LayoutRect exposeRectY(visibleRect.x(), exposeRect.y(), visibleRect.width(), exposeRect.height());
    LayoutUnit intersectHeight = intersection(visibleRect, exposeRectY).height();
    if (intersectHeight == exposeRect.height()) {
        // If the rectangle is fully visible, use the specified visible behavior.
        scrollY = getVisibleBehavior(alignY);
    } else if (intersectHeight == visibleRect.height()) {
        // If the rect is bigger than the visible area, don't bother trying to center. Other alignments will work.
        scrollY = getVisibleBehavior(alignY);
        if (scrollY == ScrollAlignmentCenter)
            scrollY = ScrollAlignmentNoScroll;
    } else if (intersectHeight > 0) {
        // If the rectangle is partially visible, use the specified partial behavior
        scrollY = getPartialBehavior(alignY);
    } else {
        scrollY = getHiddenBehavior(alignY);
    }

    if (scrollY == ScrollAlignmentClosestEdge) {
        // Closest edge is the bottom in two cases:
        // (1) exposeRect below and smaller than visibleRect
        // (2) exposeRect above and larger than visibleRect
        if ((exposeRect.maxY() > visibleRect.maxY() && exposeRect.height() < visibleRect.height())
            || (exposeRect.maxY() < visibleRect.maxY() && exposeRect.height() > visibleRect.height())) {
            scrollY = ScrollAlignmentBottom;
        }
    }

    // Given the Y behavior, compute the Y coordinate.
    LayoutUnit y;
    if (scrollY == ScrollAlignmentNoScroll)
        y = visibleRect.y();
    else if (scrollY == ScrollAlignmentBottom)
        y = exposeRect.maxY() - visibleRect.height();
    else if (scrollY == ScrollAlignmentCenter)
        y = exposeRect.y() + (exposeRect.height() - visibleRect.height()) / 2;
    else
        y = exposeRect.y();

    return LayoutRect(LayoutPoint(x, y), visibleRect.size());
}

}; // namespace blink
