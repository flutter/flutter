/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef GridCoordinate_h
#define GridCoordinate_h

#include "core/rendering/style/GridResolvedPosition.h"
#include "wtf/HashMap.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/text/WTFString.h"

namespace blink {

// A span in a single direction (either rows or columns). Note that |resolvedInitialPosition|
// and |resolvedFinalPosition| are grid areas' indexes, NOT grid lines'. Iterating over the
// span should include both |resolvedInitialPosition| and |resolvedFinalPosition| to be correct.
struct GridSpan {
    static PassOwnPtr<GridSpan> create(const GridResolvedPosition& resolvedInitialPosition, const GridResolvedPosition& resolvedFinalPosition)
    {
        return adoptPtr(new GridSpan(resolvedInitialPosition, resolvedFinalPosition));
    }

    static PassOwnPtr<GridSpan> createWithSpanAgainstOpposite(const GridResolvedPosition& resolvedOppositePosition, const GridPosition& position, GridPositionSide side)
    {
        // 'span 1' is contained inside a single grid track regardless of the direction.
        // That's why the CSS span value is one more than the offset we apply.
        size_t positionOffset = position.spanPosition() - 1;
        if (side == ColumnStartSide || side == RowStartSide) {
            GridResolvedPosition initialResolvedPosition = GridResolvedPosition(std::max<int>(0, resolvedOppositePosition.toInt() - positionOffset));
            return GridSpan::create(initialResolvedPosition, resolvedOppositePosition);
        }

        return GridSpan::create(resolvedOppositePosition, GridResolvedPosition(resolvedOppositePosition.toInt() + positionOffset));
    }

    static PassOwnPtr<GridSpan> createWithNamedSpanAgainstOpposite(const GridResolvedPosition& resolvedOppositePosition, const GridPosition& position, GridPositionSide side, const Vector<size_t>& gridLines)
    {
        if (side == RowStartSide || side == ColumnStartSide)
            return createWithInitialNamedSpanAgainstOpposite(resolvedOppositePosition, position, gridLines);

        return createWithFinalNamedSpanAgainstOpposite(resolvedOppositePosition, position, gridLines);
    }

    static PassOwnPtr<GridSpan> createWithInitialNamedSpanAgainstOpposite(const GridResolvedPosition& resolvedOppositePosition, const GridPosition& position, const Vector<size_t>& gridLines)
    {
        // The grid line inequality needs to be strict (which doesn't match the after / end case) because |resolvedOppositePosition|
        // is already converted to an index in our grid representation (ie one was removed from the grid line to account for the side).
        size_t firstLineBeforeOppositePositionIndex = 0;
        const size_t* firstLineBeforeOppositePosition = std::lower_bound(gridLines.begin(), gridLines.end(), resolvedOppositePosition.toInt());
        if (firstLineBeforeOppositePosition != gridLines.end()) {
            if (*firstLineBeforeOppositePosition > resolvedOppositePosition.toInt() && firstLineBeforeOppositePosition != gridLines.begin())
                --firstLineBeforeOppositePosition;

            firstLineBeforeOppositePositionIndex = firstLineBeforeOppositePosition - gridLines.begin();
        }

        size_t gridLineIndex = std::max<int>(0, firstLineBeforeOppositePositionIndex - position.spanPosition() + 1);
        GridResolvedPosition resolvedGridLinePosition = GridResolvedPosition(gridLines[gridLineIndex]);
        if (resolvedGridLinePosition > resolvedOppositePosition)
            resolvedGridLinePosition = resolvedOppositePosition;
        return GridSpan::create(resolvedGridLinePosition, resolvedOppositePosition);
    }

    static PassOwnPtr<GridSpan> createWithFinalNamedSpanAgainstOpposite(const GridResolvedPosition& resolvedOppositePosition, const GridPosition& position, const Vector<size_t>& gridLines)
    {
        size_t firstLineAfterOppositePositionIndex = gridLines.size() - 1;
        const size_t* firstLineAfterOppositePosition = std::upper_bound(gridLines.begin(), gridLines.end(), resolvedOppositePosition.toInt());
        if (firstLineAfterOppositePosition != gridLines.end())
            firstLineAfterOppositePositionIndex = firstLineAfterOppositePosition - gridLines.begin();

        size_t gridLineIndex = std::min(gridLines.size() - 1, firstLineAfterOppositePositionIndex + position.spanPosition() - 1);
        GridResolvedPosition resolvedGridLinePosition = GridResolvedPosition::adjustGridPositionForAfterEndSide(gridLines[gridLineIndex]);
        if (resolvedGridLinePosition < resolvedOppositePosition)
            resolvedGridLinePosition = resolvedOppositePosition;
        return GridSpan::create(resolvedOppositePosition, resolvedGridLinePosition);
    }

    GridSpan(const GridResolvedPosition& resolvedInitialPosition, const GridResolvedPosition& resolvedFinalPosition)
        : resolvedInitialPosition(resolvedInitialPosition)
        , resolvedFinalPosition(resolvedFinalPosition)
    {
        ASSERT(resolvedInitialPosition <= resolvedFinalPosition);
    }

    bool operator==(const GridSpan& o) const
    {
        return resolvedInitialPosition == o.resolvedInitialPosition && resolvedFinalPosition == o.resolvedFinalPosition;
    }

    size_t integerSpan() const
    {
        return resolvedFinalPosition.toInt() - resolvedInitialPosition.toInt() + 1;
    }

    GridResolvedPosition resolvedInitialPosition;
    GridResolvedPosition resolvedFinalPosition;

    typedef GridResolvedPosition iterator;

    iterator begin() const
    {
        return resolvedInitialPosition;
    }

    iterator end() const
    {
        return resolvedFinalPosition.next();
    }
};

// This represents a grid area that spans in both rows' and columns' direction.
struct GridCoordinate {
    // HashMap requires a default constuctor.
    GridCoordinate()
        : columns(0, 0)
        , rows(0, 0)
    {
    }

    GridCoordinate(const GridSpan& r, const GridSpan& c)
        : columns(c)
        , rows(r)
    {
    }

    bool operator==(const GridCoordinate& o) const
    {
        return columns == o.columns && rows == o.rows;
    }

    bool operator!=(const GridCoordinate& o) const
    {
        return !(*this == o);
    }

    GridResolvedPosition positionForSide(GridPositionSide side) const
    {
        switch (side) {
        case ColumnStartSide:
            return columns.resolvedInitialPosition;
        case ColumnEndSide:
            return columns.resolvedFinalPosition;
        case RowStartSide:
            return rows.resolvedInitialPosition;
        case RowEndSide:
            return rows.resolvedFinalPosition;
        }
        ASSERT_NOT_REACHED();
        return 0;
    }

    GridSpan columns;
    GridSpan rows;
};

typedef HashMap<String, GridCoordinate> NamedGridAreaMap;

} // namespace blink

#endif // GridCoordinate_h
