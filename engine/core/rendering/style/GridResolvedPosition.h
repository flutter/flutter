// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GridResolvedPosition_h
#define GridResolvedPosition_h

#include "core/rendering/style/GridPosition.h"

namespace blink {

struct GridSpan;
class RenderBox;
class RenderStyle;

enum GridPositionSide {
    ColumnStartSide,
    ColumnEndSide,
    RowStartSide,
    RowEndSide
};

enum GridTrackSizingDirection {
    ForColumns,
    ForRows
};

// This class represents an index into one of the dimensions of the grid array.
// Wraps a size_t integer just for the purpose of knowing what we manipulate in the grid code.
class GridResolvedPosition {
public:
    static GridResolvedPosition adjustGridPositionForAfterEndSide(size_t resolvedPosition)
    {
        return resolvedPosition ? GridResolvedPosition(resolvedPosition - 1) : GridResolvedPosition(0);
    }

    static GridResolvedPosition adjustGridPositionForSide(size_t resolvedPosition, GridPositionSide side)
    {
        // An item finishing on the N-th line belongs to the N-1-th cell.
        if (side == ColumnEndSide || side == RowEndSide)
            return adjustGridPositionForAfterEndSide(resolvedPosition);

        return GridResolvedPosition(resolvedPosition);
    }

    static void initialAndFinalPositionsFromStyle(const RenderStyle&, const RenderBox&, GridTrackSizingDirection, GridPosition &initialPosition, GridPosition &finalPosition);
    static GridSpan resolveGridPositionsFromAutoPlacementPosition(const RenderStyle&, const RenderBox&, GridTrackSizingDirection, const GridResolvedPosition&);
    static PassOwnPtr<GridSpan> resolveGridPositionsFromStyle(const RenderStyle&, const RenderBox&, GridTrackSizingDirection);
    static GridResolvedPosition resolveNamedGridLinePositionFromStyle(const RenderStyle&, const GridPosition&, GridPositionSide);
    static GridResolvedPosition resolveGridPositionFromStyle(const RenderStyle&, const GridPosition&, GridPositionSide);
    static PassOwnPtr<GridSpan> resolveGridPositionAgainstOppositePosition(const RenderStyle&, const GridResolvedPosition& resolvedOppositePosition, const GridPosition&, GridPositionSide);
    static PassOwnPtr<GridSpan> resolveNamedGridLinePositionAgainstOppositePosition(const RenderStyle&, const GridResolvedPosition& resolvedOppositePosition, const GridPosition&, GridPositionSide);

    GridResolvedPosition(size_t position)
        : m_integerPosition(position)
    {
    }

    GridResolvedPosition(const GridPosition& position, GridPositionSide side)
    {
        ASSERT(position.integerPosition());
        size_t integerPosition = position.integerPosition() - 1;

        m_integerPosition = adjustGridPositionForSide(integerPosition, side).toInt();
    }

    GridResolvedPosition& operator++()
    {
        m_integerPosition++;
        return *this;
    }

    bool operator==(const GridResolvedPosition& other) const
    {
        return m_integerPosition == other.m_integerPosition;
    }

    bool operator!=(const GridResolvedPosition& other) const
    {
        return m_integerPosition != other.m_integerPosition;
    }

    bool operator<(const GridResolvedPosition& other) const
    {
        return m_integerPosition < other.m_integerPosition;
    }

    bool operator>(const GridResolvedPosition& other) const
    {
        return m_integerPosition > other.m_integerPosition;
    }

    bool operator<=(const GridResolvedPosition& other) const
    {
        return m_integerPosition <= other.m_integerPosition;
    }

    bool operator>=(const GridResolvedPosition& other) const
    {
        return m_integerPosition >= other.m_integerPosition;
    }

    size_t toInt() const
    {
        return m_integerPosition;
    }

    GridResolvedPosition next() const
    {
        return GridResolvedPosition(m_integerPosition + 1);
    }

    static size_t explicitGridColumnCount(const RenderStyle&);
    static size_t explicitGridRowCount(const RenderStyle&);

private:

    static size_t explicitGridSizeForSide(const RenderStyle&, GridPositionSide);

    size_t m_integerPosition;
};

} // namespace blink

#endif // GridResolvedPosition_h
