/*
 * Copyright (C) 2011 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/rendering/RenderGrid.h"

#include "core/rendering/RenderLayer.h"
#include "core/rendering/RenderView.h"
#include "core/rendering/style/GridCoordinate.h"
#include "platform/LengthFunctions.h"

namespace blink {

static const int infinity = -1;

class GridTrack {
public:
    GridTrack()
        : m_usedBreadth(0)
        , m_maxBreadth(0)
    {
    }

    void growUsedBreadth(LayoutUnit growth)
    {
        ASSERT(growth >= 0);
        m_usedBreadth += growth;
    }
    LayoutUnit usedBreadth() const { return m_usedBreadth; }

    void growMaxBreadth(LayoutUnit growth)
    {
        if (m_maxBreadth == infinity)
            m_maxBreadth = m_usedBreadth + growth;
        else
            m_maxBreadth += growth;
    }
    LayoutUnit maxBreadthIfNotInfinite() const
    {
        return (m_maxBreadth == infinity) ? m_usedBreadth : m_maxBreadth;
    }

    LayoutUnit m_usedBreadth;
    LayoutUnit m_maxBreadth;
};

struct GridTrackForNormalization {
    GridTrackForNormalization(const GridTrack& track, double flex)
        : m_track(&track)
        , m_flex(flex)
        , m_normalizedFlexValue(track.m_usedBreadth / flex)
    {
    }

    // Required by std::sort.
    GridTrackForNormalization& operator=(const GridTrackForNormalization& o)
    {
        m_track = o.m_track;
        m_flex = o.m_flex;
        m_normalizedFlexValue = o.m_normalizedFlexValue;
        return *this;
    }

    const GridTrack* m_track;
    double m_flex;
    LayoutUnit m_normalizedFlexValue;
};

class RenderGrid::GridIterator {
    WTF_MAKE_NONCOPYABLE(GridIterator);
public:
    // |direction| is the direction that is fixed to |fixedTrackIndex| so e.g
    // GridIterator(m_grid, ForColumns, 1) will walk over the rows of the 2nd column.
    GridIterator(const GridRepresentation& grid, GridTrackSizingDirection direction, size_t fixedTrackIndex, size_t varyingTrackIndex = 0)
        : m_grid(grid)
        , m_direction(direction)
        , m_rowIndex((direction == ForColumns) ? varyingTrackIndex : fixedTrackIndex)
        , m_columnIndex((direction == ForColumns) ? fixedTrackIndex : varyingTrackIndex)
        , m_childIndex(0)
    {
        ASSERT(m_rowIndex < m_grid.size());
        ASSERT(m_columnIndex < m_grid[0].size());
    }

    RenderBox* nextGridItem()
    {
        ASSERT(!m_grid.isEmpty());

        size_t& varyingTrackIndex = (m_direction == ForColumns) ? m_rowIndex : m_columnIndex;
        const size_t endOfVaryingTrackIndex = (m_direction == ForColumns) ? m_grid.size() : m_grid[0].size();
        for (; varyingTrackIndex < endOfVaryingTrackIndex; ++varyingTrackIndex) {
            const GridCell& children = m_grid[m_rowIndex][m_columnIndex];
            if (m_childIndex < children.size())
                return children[m_childIndex++];

            m_childIndex = 0;
        }
        return 0;
    }

    bool checkEmptyCells(size_t rowSpan, size_t columnSpan) const
    {
        // Ignore cells outside current grid as we will grow it later if needed.
        size_t maxRows = std::min(m_rowIndex + rowSpan, m_grid.size());
        size_t maxColumns = std::min(m_columnIndex + columnSpan, m_grid[0].size());

        // This adds a O(N^2) behavior that shouldn't be a big deal as we expect spanning areas to be small.
        for (size_t row = m_rowIndex; row < maxRows; ++row) {
            for (size_t column = m_columnIndex; column < maxColumns; ++column) {
                const GridCell& children = m_grid[row][column];
                if (!children.isEmpty())
                    return false;
            }
        }

        return true;
    }

    PassOwnPtr<GridCoordinate> nextEmptyGridArea(size_t fixedTrackSpan, size_t varyingTrackSpan)
    {
        ASSERT(!m_grid.isEmpty());
        ASSERT(fixedTrackSpan >= 1 && varyingTrackSpan >= 1);

        size_t rowSpan = (m_direction == ForColumns) ? varyingTrackSpan : fixedTrackSpan;
        size_t columnSpan = (m_direction == ForColumns) ? fixedTrackSpan : varyingTrackSpan;

        size_t& varyingTrackIndex = (m_direction == ForColumns) ? m_rowIndex : m_columnIndex;
        const size_t endOfVaryingTrackIndex = (m_direction == ForColumns) ? m_grid.size() : m_grid[0].size();
        for (; varyingTrackIndex < endOfVaryingTrackIndex; ++varyingTrackIndex) {
            if (checkEmptyCells(rowSpan, columnSpan)) {
                OwnPtr<GridCoordinate> result = adoptPtr(new GridCoordinate(GridSpan(m_rowIndex, m_rowIndex + rowSpan - 1), GridSpan(m_columnIndex, m_columnIndex + columnSpan - 1)));
                // Advance the iterator to avoid an infinite loop where we would return the same grid area over and over.
                ++varyingTrackIndex;
                return result.release();
            }
        }
        return nullptr;
    }

private:
    const GridRepresentation& m_grid;
    GridTrackSizingDirection m_direction;
    size_t m_rowIndex;
    size_t m_columnIndex;
    size_t m_childIndex;
};

struct RenderGrid::GridSizingData {
    WTF_MAKE_NONCOPYABLE(GridSizingData);
public:
    GridSizingData(size_t gridColumnCount, size_t gridRowCount)
        : columnTracks(gridColumnCount)
        , rowTracks(gridRowCount)
    {
    }

    Vector<GridTrack> columnTracks;
    Vector<GridTrack> rowTracks;
    Vector<size_t> contentSizedTracksIndex;

    // Performance optimization: hold onto these Vectors until the end of Layout to avoid repeated malloc / free.
    Vector<LayoutUnit> distributeTrackVector;
    Vector<GridTrack*> filteredTracks;
};

RenderGrid::RenderGrid(Element* element)
    : RenderBlock(element)
    , m_gridIsDirty(true)
    , m_orderIterator(this)
{
    ASSERT(!childrenInline());
}

RenderGrid::~RenderGrid()
{
}

void RenderGrid::addChild(RenderObject* newChild, RenderObject* beforeChild)
{
    // If the new requested beforeChild is not one of our children is because it's wrapped by an anonymous container. If
    // we do not special case this situation we could end up calling addChild() twice for the newChild, one with the
    // initial beforeChild and another one with its parent.
    if (beforeChild && beforeChild->parent() != this) {
        ASSERT(beforeChild->parent()->isAnonymous());
        beforeChild = splitAnonymousBoxesAroundChild(beforeChild);
        dirtyGrid();
    }

    RenderBlock::addChild(newChild, beforeChild);

    if (gridIsDirty())
        return;

    if (!newChild->isBox()) {
        dirtyGrid();
        return;
    }

    // FIXME: Implement properly "stack" value in auto-placement algorithm.
    if (!style()->isGridAutoFlowAlgorithmStack()) {
        // The grid needs to be recomputed as it might contain auto-placed items that will change their position.
        dirtyGrid();
        return;
    }

    RenderBox* newChildBox = toRenderBox(newChild);
    OwnPtr<GridSpan> rowPositions = GridResolvedPosition::resolveGridPositionsFromStyle(*style(), *newChildBox, ForRows);
    OwnPtr<GridSpan> columnPositions = GridResolvedPosition::resolveGridPositionsFromStyle(*style(), *newChildBox, ForColumns);
    if (!rowPositions || !columnPositions) {
        // The new child requires the auto-placement algorithm to run so we need to recompute the grid fully.
        dirtyGrid();
        return;
    } else {
        insertItemIntoGrid(newChildBox, GridCoordinate(*rowPositions, *columnPositions));
        addChildToIndexesMap(newChildBox);
    }
}

void RenderGrid::addChildToIndexesMap(RenderBox* child)
{
    ASSERT(!m_gridItemsIndexesMap.contains(child));
    RenderBox* sibling = child->nextSiblingBox();
    bool lastSibling = !sibling;

    if (lastSibling)
        sibling = child->previousSiblingBox();

    size_t index = 0;
    if (sibling)
        index = lastSibling ? m_gridItemsIndexesMap.get(sibling) + 1 : m_gridItemsIndexesMap.get(sibling);

    if (sibling && !lastSibling) {
        for (; sibling; sibling = sibling->nextSiblingBox())
            m_gridItemsIndexesMap.set(sibling, m_gridItemsIndexesMap.get(sibling) + 1);
    }

    m_gridItemsIndexesMap.set(child, index);
}

void RenderGrid::removeChild(RenderObject* child)
{
    RenderBlock::removeChild(child);

    if (gridIsDirty())
        return;

    ASSERT(child->isBox());

    // FIXME: Implement properly "stack" value in auto-placement algorithm.
    if (!style()->isGridAutoFlowAlgorithmStack()) {
        // The grid needs to be recomputed as it might contain auto-placed items that will change their position.
        dirtyGrid();
        return;
    }

    const RenderBox* childBox = toRenderBox(child);
    GridCoordinate coordinate = m_gridItemCoordinate.take(childBox);

    for (GridSpan::iterator row = coordinate.rows.begin(); row != coordinate.rows.end(); ++row) {
        for (GridSpan::iterator column = coordinate.columns.begin(); column != coordinate.columns.end(); ++column) {
            GridCell& cell = m_grid[row.toInt()][column.toInt()];
            cell.remove(cell.find(childBox));
        }
    }

    m_gridItemsIndexesMap.remove(childBox);
}

void RenderGrid::styleDidChange(StyleDifference diff, const RenderStyle* oldStyle)
{
    RenderBlock::styleDidChange(diff, oldStyle);
    if (!oldStyle)
        return;

    // FIXME: The following checks could be narrowed down if we kept track of which type of grid items we have:
    // - explicit grid size changes impact negative explicitely positioned and auto-placed grid items.
    // - named grid lines only impact grid items with named grid lines.
    // - auto-flow changes only impacts auto-placed children.

    if (explicitGridDidResize(oldStyle)
        || namedGridLinesDefinitionDidChange(oldStyle)
        || oldStyle->gridAutoFlow() != style()->gridAutoFlow())
        dirtyGrid();
}

bool RenderGrid::explicitGridDidResize(const RenderStyle* oldStyle) const
{
    return oldStyle->gridTemplateColumns().size() != style()->gridTemplateColumns().size()
        || oldStyle->gridTemplateRows().size() != style()->gridTemplateRows().size();
}

bool RenderGrid::namedGridLinesDefinitionDidChange(const RenderStyle* oldStyle) const
{
    return oldStyle->namedGridRowLines() != style()->namedGridRowLines()
        || oldStyle->namedGridColumnLines() != style()->namedGridColumnLines();
}

void RenderGrid::layoutBlock(bool relayoutChildren)
{
    ASSERT(needsLayout());

    if (!relayoutChildren && simplifiedLayout())
        return;

    // FIXME: Much of this method is boiler plate that matches RenderBox::layoutBlock and Render*FlexibleBox::layoutBlock.
    // It would be nice to refactor some of the duplicate code.
    LayoutState state(*this, locationOffset());

    LayoutSize previousSize = size();

    setLogicalHeight(0);
    updateLogicalWidth();

    layoutGridItems();

    LayoutUnit oldClientAfterEdge = clientLogicalBottom();
    updateLogicalHeight();

    if (size() != previousSize)
        relayoutChildren = true;

    layoutPositionedObjects(relayoutChildren || isDocumentElement());

    computeOverflow(oldClientAfterEdge);

    updateLayerTransformAfterLayout();

    // Update our scroll information if we're overflow:auto/scroll/hidden now that we know if
    // we overflow or not.
    if (hasOverflowClip())
        layer()->scrollableArea()->updateAfterLayout();

    clearNeedsLayout();
}

void RenderGrid::computeIntrinsicLogicalWidths(LayoutUnit& minLogicalWidth, LayoutUnit& maxLogicalWidth) const
{
    const_cast<RenderGrid*>(this)->placeItemsOnGrid();

    GridSizingData sizingData(gridColumnCount(), gridRowCount());
    LayoutUnit availableLogicalSpace = 0;
    const_cast<RenderGrid*>(this)->computeUsedBreadthOfGridTracks(ForColumns, sizingData, availableLogicalSpace);

    for (size_t i = 0; i < sizingData.columnTracks.size(); ++i) {
        LayoutUnit minTrackBreadth = sizingData.columnTracks[i].m_usedBreadth;
        LayoutUnit maxTrackBreadth = sizingData.columnTracks[i].m_maxBreadth;
        maxTrackBreadth = std::max(maxTrackBreadth, minTrackBreadth);

        minLogicalWidth += minTrackBreadth;
        maxLogicalWidth += maxTrackBreadth;

        // FIXME: This should add in the scrollbarWidth (e.g. see RenderFlexibleBox).
    }
}

void RenderGrid::computePreferredLogicalWidths()
{
    ASSERT(preferredLogicalWidthsDirty());

    m_minPreferredLogicalWidth = 0;
    m_maxPreferredLogicalWidth = 0;

    // FIXME: We don't take our own logical width into account. Once we do, we need to make sure
    // we apply (and test the interaction with) min-width / max-width.

    computeIntrinsicLogicalWidths(m_minPreferredLogicalWidth, m_maxPreferredLogicalWidth);

    LayoutUnit borderAndPaddingInInlineDirection = borderAndPaddingLogicalWidth();
    m_minPreferredLogicalWidth += borderAndPaddingInInlineDirection;
    m_maxPreferredLogicalWidth += borderAndPaddingInInlineDirection;

    clearPreferredLogicalWidthsDirty();
}

void RenderGrid::computeUsedBreadthOfGridTracks(GridTrackSizingDirection direction, GridSizingData& sizingData)
{
    LayoutUnit availableLogicalSpace = (direction == ForColumns) ? availableLogicalWidth() : availableLogicalHeight(IncludeMarginBorderPadding);
    computeUsedBreadthOfGridTracks(direction, sizingData, availableLogicalSpace);
}

bool RenderGrid::gridElementIsShrinkToFit()
{
    return isFloatingOrOutOfFlowPositioned();
}

void RenderGrid::computeUsedBreadthOfGridTracks(GridTrackSizingDirection direction, GridSizingData& sizingData, LayoutUnit& availableLogicalSpace)
{
    Vector<GridTrack>& tracks = (direction == ForColumns) ? sizingData.columnTracks : sizingData.rowTracks;
    Vector<size_t> flexibleSizedTracksIndex;
    sizingData.contentSizedTracksIndex.shrink(0);

    // 1. Initialize per Grid track variables.
    for (size_t i = 0; i < tracks.size(); ++i) {
        GridTrack& track = tracks[i];
        const GridTrackSize& trackSize = gridTrackSize(direction, i);
        const GridLength& minTrackBreadth = trackSize.minTrackBreadth();
        const GridLength& maxTrackBreadth = trackSize.maxTrackBreadth();

        track.m_usedBreadth = computeUsedBreadthOfMinLength(direction, minTrackBreadth);
        track.m_maxBreadth = computeUsedBreadthOfMaxLength(direction, maxTrackBreadth, track.m_usedBreadth);

        if (track.m_maxBreadth != infinity)
            track.m_maxBreadth = std::max(track.m_maxBreadth, track.m_usedBreadth);

        if (trackSize.isContentSized())
            sizingData.contentSizedTracksIndex.append(i);
        if (trackSize.maxTrackBreadth().isFlex())
            flexibleSizedTracksIndex.append(i);
    }

    // 2. Resolve content-based TrackSizingFunctions.
    if (!sizingData.contentSizedTracksIndex.isEmpty())
        resolveContentBasedTrackSizingFunctions(direction, sizingData, availableLogicalSpace);

    for (size_t i = 0; i < tracks.size(); ++i) {
        ASSERT(tracks[i].m_maxBreadth != infinity);
        availableLogicalSpace -= tracks[i].m_usedBreadth;
    }

    const bool hasUndefinedRemainingSpace = (direction == ForRows) ? style()->logicalHeight().isAuto() : gridElementIsShrinkToFit();

    if (!hasUndefinedRemainingSpace && availableLogicalSpace <= 0)
        return;

    // 3. Grow all Grid tracks in GridTracks from their UsedBreadth up to their MaxBreadth value until
    // availableLogicalSpace (RemainingSpace in the specs) is exhausted.
    const size_t tracksSize = tracks.size();
    if (!hasUndefinedRemainingSpace) {
        Vector<GridTrack*> tracksForDistribution(tracksSize);
        for (size_t i = 0; i < tracksSize; ++i)
            tracksForDistribution[i] = tracks.data() + i;

        distributeSpaceToTracks(tracksForDistribution, 0, &GridTrack::usedBreadth, &GridTrack::growUsedBreadth, sizingData, availableLogicalSpace);
    } else {
        for (size_t i = 0; i < tracksSize; ++i)
            tracks[i].m_usedBreadth = tracks[i].m_maxBreadth;
    }

    if (flexibleSizedTracksIndex.isEmpty())
        return;

    // 4. Grow all Grid tracks having a fraction as the MaxTrackSizingFunction.
    double normalizedFractionBreadth = 0;
    if (!hasUndefinedRemainingSpace) {
        normalizedFractionBreadth = computeNormalizedFractionBreadth(tracks, GridSpan(0, tracks.size() - 1), direction, availableLogicalSpace);
    } else {
        for (size_t i = 0; i < flexibleSizedTracksIndex.size(); ++i) {
            const size_t trackIndex = flexibleSizedTracksIndex[i];
            const GridTrackSize& trackSize = gridTrackSize(direction, trackIndex);
            normalizedFractionBreadth = std::max(normalizedFractionBreadth, tracks[trackIndex].m_usedBreadth / trackSize.maxTrackBreadth().flex());
        }

        for (size_t i = 0; i < flexibleSizedTracksIndex.size(); ++i) {
            GridIterator iterator(m_grid, direction, flexibleSizedTracksIndex[i]);
            while (RenderBox* gridItem = iterator.nextGridItem()) {
                const GridCoordinate coordinate = cachedGridCoordinate(gridItem);
                const GridSpan span = (direction == ForColumns) ? coordinate.columns : coordinate.rows;

                // Do not include already processed items.
                if (i > 0 && span.resolvedInitialPosition.toInt() <= flexibleSizedTracksIndex[i - 1])
                    continue;

                double itemNormalizedFlexBreadth = computeNormalizedFractionBreadth(tracks, span, direction, maxContentForChild(gridItem, direction, sizingData.columnTracks));
                normalizedFractionBreadth = std::max(normalizedFractionBreadth, itemNormalizedFlexBreadth);
            }
        }
    }

    for (size_t i = 0; i < flexibleSizedTracksIndex.size(); ++i) {
        const size_t trackIndex = flexibleSizedTracksIndex[i];
        const GridTrackSize& trackSize = gridTrackSize(direction, trackIndex);

        tracks[trackIndex].m_usedBreadth = std::max<LayoutUnit>(tracks[trackIndex].m_usedBreadth, normalizedFractionBreadth * trackSize.maxTrackBreadth().flex());
    }
}

LayoutUnit RenderGrid::computeUsedBreadthOfMinLength(GridTrackSizingDirection direction, const GridLength& gridLength) const
{
    if (gridLength.isFlex())
        return 0;

    const Length& trackLength = gridLength.length();
    ASSERT(!trackLength.isAuto());
    if (trackLength.isSpecified())
        return computeUsedBreadthOfSpecifiedLength(direction, trackLength);

    ASSERT(trackLength.isMinContent() || trackLength.isMaxContent());
    return 0;
}

LayoutUnit RenderGrid::computeUsedBreadthOfMaxLength(GridTrackSizingDirection direction, const GridLength& gridLength, LayoutUnit usedBreadth) const
{
    if (gridLength.isFlex())
        return usedBreadth;

    const Length& trackLength = gridLength.length();
    ASSERT(!trackLength.isAuto());
    if (trackLength.isSpecified()) {
        LayoutUnit computedBreadth = computeUsedBreadthOfSpecifiedLength(direction, trackLength);
        ASSERT(computedBreadth != infinity);
        return computedBreadth;
    }

    ASSERT(trackLength.isMinContent() || trackLength.isMaxContent());
    return infinity;
}

LayoutUnit RenderGrid::computeUsedBreadthOfSpecifiedLength(GridTrackSizingDirection direction, const Length& trackLength) const
{
    ASSERT(trackLength.isSpecified());
    // FIXME: The -1 here should be replaced by whatever the intrinsic height of the grid is.
    return valueForLength(trackLength, direction == ForColumns ? logicalWidth() : computeContentLogicalHeight(style()->logicalHeight(), -1));
}

static bool sortByGridNormalizedFlexValue(const GridTrackForNormalization& track1, const GridTrackForNormalization& track2)
{
    return track1.m_normalizedFlexValue < track2.m_normalizedFlexValue;
}

double RenderGrid::computeNormalizedFractionBreadth(Vector<GridTrack>& tracks, const GridSpan& tracksSpan, GridTrackSizingDirection direction, LayoutUnit availableLogicalSpace) const
{
    // |availableLogicalSpace| already accounts for the used breadths so no need to remove it here.

    Vector<GridTrackForNormalization> tracksForNormalization;
    for (GridSpan::iterator resolvedPosition = tracksSpan.begin(); resolvedPosition != tracksSpan.end(); ++resolvedPosition) {
        const GridTrackSize& trackSize = gridTrackSize(direction, resolvedPosition.toInt());
        if (!trackSize.maxTrackBreadth().isFlex())
            continue;

        tracksForNormalization.append(GridTrackForNormalization(tracks[resolvedPosition.toInt()], trackSize.maxTrackBreadth().flex()));
    }

    // The function is not called if we don't have <flex> grid tracks
    ASSERT(!tracksForNormalization.isEmpty());

    std::sort(tracksForNormalization.begin(), tracksForNormalization.end(), sortByGridNormalizedFlexValue);

    // These values work together: as we walk over our grid tracks, we increase fractionValueBasedOnGridItemsRatio
    // to match a grid track's usedBreadth to <flex> ratio until the total fractions sized grid tracks wouldn't
    // fit into availableLogicalSpaceIgnoringFractionTracks.
    double accumulatedFractions = 0;
    LayoutUnit fractionValueBasedOnGridItemsRatio = 0;
    LayoutUnit availableLogicalSpaceIgnoringFractionTracks = availableLogicalSpace;

    for (size_t i = 0; i < tracksForNormalization.size(); ++i) {
        const GridTrackForNormalization& track = tracksForNormalization[i];
        if (track.m_normalizedFlexValue > fractionValueBasedOnGridItemsRatio) {
            // If the normalized flex value (we ordered |tracksForNormalization| by increasing normalized flex value)
            // will make us overflow our container, then stop. We have the previous step's ratio is the best fit.
            if (track.m_normalizedFlexValue * accumulatedFractions > availableLogicalSpaceIgnoringFractionTracks)
                break;

            fractionValueBasedOnGridItemsRatio = track.m_normalizedFlexValue;
        }

        accumulatedFractions += track.m_flex;
        // This item was processed so we re-add its used breadth to the available space to accurately count the remaining space.
        availableLogicalSpaceIgnoringFractionTracks += track.m_track->m_usedBreadth;
    }

    return availableLogicalSpaceIgnoringFractionTracks / accumulatedFractions;
}

const GridTrackSize& RenderGrid::gridTrackSize(GridTrackSizingDirection direction, size_t i) const
{
    const Vector<GridTrackSize>& trackStyles = (direction == ForColumns) ? style()->gridTemplateColumns() : style()->gridTemplateRows();
    if (i >= trackStyles.size())
        return (direction == ForColumns) ? style()->gridAutoColumns() : style()->gridAutoRows();

    const GridTrackSize& trackSize = trackStyles[i];
    // If the logical width/height of the grid container is indefinite, percentage values are treated as <auto>.
    if (trackSize.isPercentage()) {
        Length logicalSize = direction == ForColumns ? style()->logicalWidth() : style()->logicalHeight();
        if (logicalSize.isIntrinsicOrAuto()) {
            DEFINE_STATIC_LOCAL(GridTrackSize, autoTrackSize, (Length(Auto)));
            return autoTrackSize;
        }
    }

    return trackSize;
}

LayoutUnit RenderGrid::logicalHeightForChild(RenderBox* child, Vector<GridTrack>& columnTracks)
{
    SubtreeLayoutScope layoutScope(*child);
    LayoutUnit oldOverrideContainingBlockContentLogicalWidth = child->hasOverrideContainingBlockLogicalWidth() ? child->overrideContainingBlockContentLogicalWidth() : LayoutUnit();
    LayoutUnit overrideContainingBlockContentLogicalWidth = gridAreaBreadthForChild(child, ForColumns, columnTracks);
    if (child->style()->logicalHeight().isPercent() || oldOverrideContainingBlockContentLogicalWidth != overrideContainingBlockContentLogicalWidth)
        layoutScope.setNeedsLayout(child);

    child->setOverrideContainingBlockContentLogicalWidth(overrideContainingBlockContentLogicalWidth);
    // If |child| has a percentage logical height, we shouldn't let it override its intrinsic height, which is
    // what we are interested in here. Thus we need to set the override logical height to -1 (no possible resolution).
    child->setOverrideContainingBlockContentLogicalHeight(-1);
    child->layoutIfNeeded();
    return child->logicalHeight() + child->marginLogicalHeight();
}

LayoutUnit RenderGrid::minContentForChild(RenderBox* child, GridTrackSizingDirection direction, Vector<GridTrack>& columnTracks)
{
    bool hasOrthogonalWritingMode = child->isHorizontalWritingMode() != isHorizontalWritingMode();
    // FIXME: Properly support orthogonal writing mode.
    if (hasOrthogonalWritingMode)
        return 0;

    if (direction == ForColumns) {
        // FIXME: It's unclear if we should return the intrinsic width or the preferred width.
        // See http://lists.w3.org/Archives/Public/www-style/2013Jan/0245.html
        return child->minPreferredLogicalWidth() + marginIntrinsicLogicalWidthForChild(child);
    }

    return logicalHeightForChild(child, columnTracks);
}

LayoutUnit RenderGrid::maxContentForChild(RenderBox* child, GridTrackSizingDirection direction, Vector<GridTrack>& columnTracks)
{
    bool hasOrthogonalWritingMode = child->isHorizontalWritingMode() != isHorizontalWritingMode();
    // FIXME: Properly support orthogonal writing mode.
    if (hasOrthogonalWritingMode)
        return LayoutUnit();

    if (direction == ForColumns) {
        // FIXME: It's unclear if we should return the intrinsic width or the preferred width.
        // See http://lists.w3.org/Archives/Public/www-style/2013Jan/0245.html
        return child->maxPreferredLogicalWidth() + marginIntrinsicLogicalWidthForChild(child);
    }

    return logicalHeightForChild(child, columnTracks);
}

size_t RenderGrid::gridItemSpan(const RenderBox* child, GridTrackSizingDirection direction)
{
    GridCoordinate childCoordinate = cachedGridCoordinate(child);
    GridSpan childSpan = (direction == ForRows) ? childCoordinate.rows : childCoordinate.columns;

    return childSpan.resolvedFinalPosition.toInt() - childSpan.resolvedInitialPosition.toInt() + 1;
}

typedef std::pair<RenderBox*, size_t> GridItemWithSpan;

// This function sorts by span (.second in the pair) but also places pointers (.first in the pair) to the same object in
// consecutive positions so duplicates could be easily removed with std::unique() for example.
static bool gridItemWithSpanSorter(const GridItemWithSpan& item1, const GridItemWithSpan& item2)
{
    if (item1.second != item2.second)
        return item1.second < item2.second;

    return item1.first < item2.first;
}

static bool uniquePointerInPair(const GridItemWithSpan& item1, const GridItemWithSpan& item2)
{
    return item1.first == item2.first;
}

void RenderGrid::resolveContentBasedTrackSizingFunctions(GridTrackSizingDirection direction, GridSizingData& sizingData, LayoutUnit& availableLogicalSpace)
{
    // FIXME: Split the grid tracks into groups that doesn't overlap a <flex> grid track (crbug.com/235258).

    for (size_t i = 0; i < sizingData.contentSizedTracksIndex.size(); ++i) {
        size_t trackIndex = sizingData.contentSizedTracksIndex[i];
        GridIterator iterator(m_grid, direction, trackIndex);
        Vector<GridItemWithSpan> itemsSortedByIncreasingSpan;

        while (RenderBox* gridItem = iterator.nextGridItem())
            itemsSortedByIncreasingSpan.append(std::make_pair(gridItem, gridItemSpan(gridItem, direction)));
        std::stable_sort(itemsSortedByIncreasingSpan.begin(), itemsSortedByIncreasingSpan.end(), gridItemWithSpanSorter);
        Vector<GridItemWithSpan>::iterator end = std::unique(itemsSortedByIncreasingSpan.begin(), itemsSortedByIncreasingSpan.end(), uniquePointerInPair);

        for (Vector<GridItemWithSpan>::iterator it = itemsSortedByIncreasingSpan.begin(); it != end; ++it) {
            RenderBox* gridItem = it->first;
            resolveContentBasedTrackSizingFunctionsForItems(direction, sizingData, gridItem, &GridTrackSize::hasMinOrMaxContentMinTrackBreadth, &RenderGrid::minContentForChild, &GridTrack::usedBreadth, &GridTrack::growUsedBreadth);
            resolveContentBasedTrackSizingFunctionsForItems(direction, sizingData, gridItem, &GridTrackSize::hasMaxContentMinTrackBreadth, &RenderGrid::maxContentForChild, &GridTrack::usedBreadth, &GridTrack::growUsedBreadth);
            resolveContentBasedTrackSizingFunctionsForItems(direction, sizingData, gridItem, &GridTrackSize::hasMinOrMaxContentMaxTrackBreadth, &RenderGrid::minContentForChild, &GridTrack::maxBreadthIfNotInfinite, &GridTrack::growMaxBreadth);
            resolveContentBasedTrackSizingFunctionsForItems(direction, sizingData, gridItem, &GridTrackSize::hasMaxContentMaxTrackBreadth, &RenderGrid::maxContentForChild, &GridTrack::maxBreadthIfNotInfinite, &GridTrack::growMaxBreadth);
        }

        GridTrack& track = (direction == ForColumns) ? sizingData.columnTracks[trackIndex] : sizingData.rowTracks[trackIndex];
        if (track.m_maxBreadth == infinity)
            track.m_maxBreadth = track.m_usedBreadth;
    }
}

void RenderGrid::resolveContentBasedTrackSizingFunctionsForItems(GridTrackSizingDirection direction, GridSizingData& sizingData, RenderBox* gridItem, FilterFunction filterFunction, SizingFunction sizingFunction, AccumulatorGetter trackGetter, AccumulatorGrowFunction trackGrowthFunction)
{
    const GridCoordinate coordinate = cachedGridCoordinate(gridItem);
    const GridResolvedPosition initialTrackPosition = (direction == ForColumns) ? coordinate.columns.resolvedInitialPosition : coordinate.rows.resolvedInitialPosition;
    const GridResolvedPosition finalTrackPosition = (direction == ForColumns) ? coordinate.columns.resolvedFinalPosition : coordinate.rows.resolvedFinalPosition;

    sizingData.filteredTracks.shrink(0);
    for (GridResolvedPosition trackPosition = initialTrackPosition; trackPosition <= finalTrackPosition; ++trackPosition) {
        const GridTrackSize& trackSize = gridTrackSize(direction, trackPosition.toInt());
        if (!(trackSize.*filterFunction)())
            continue;

        GridTrack& track = (direction == ForColumns) ? sizingData.columnTracks[trackPosition.toInt()] : sizingData.rowTracks[trackPosition.toInt()];
        sizingData.filteredTracks.append(&track);
    }

    if (sizingData.filteredTracks.isEmpty())
        return;

    LayoutUnit additionalBreadthSpace = (this->*sizingFunction)(gridItem, direction, sizingData.columnTracks);
    for (GridResolvedPosition trackIndexForSpace = initialTrackPosition; trackIndexForSpace <= finalTrackPosition; ++trackIndexForSpace) {
        GridTrack& track = (direction == ForColumns) ? sizingData.columnTracks[trackIndexForSpace.toInt()] : sizingData.rowTracks[trackIndexForSpace.toInt()];
        additionalBreadthSpace -= (track.*trackGetter)();
    }

    // FIXME: We should pass different values for |tracksForGrowthAboveMaxBreadth|.

    // Specs mandate to floor additionalBreadthSpace (extra-space in specs) to 0. Instead we directly avoid the function
    // call in those cases as it will be a noop in terms of track sizing.
    if (additionalBreadthSpace > 0)
        distributeSpaceToTracks(sizingData.filteredTracks, &sizingData.filteredTracks, trackGetter, trackGrowthFunction, sizingData, additionalBreadthSpace);
}

static bool sortByGridTrackGrowthPotential(const GridTrack* track1, const GridTrack* track2)
{
    if (track1->m_maxBreadth == infinity)
        return track2->m_maxBreadth == infinity;

    if (track2->m_maxBreadth == infinity)
        return true;

    return (track1->m_maxBreadth - track1->m_usedBreadth) < (track2->m_maxBreadth - track2->m_usedBreadth);
}

void RenderGrid::distributeSpaceToTracks(Vector<GridTrack*>& tracks, Vector<GridTrack*>* tracksForGrowthAboveMaxBreadth, AccumulatorGetter trackGetter, AccumulatorGrowFunction trackGrowthFunction, GridSizingData& sizingData, LayoutUnit& availableLogicalSpace)
{
    ASSERT(availableLogicalSpace > 0);
    std::sort(tracks.begin(), tracks.end(), sortByGridTrackGrowthPotential);

    size_t tracksSize = tracks.size();
    sizingData.distributeTrackVector.resize(tracksSize);

    for (size_t i = 0; i < tracksSize; ++i) {
        GridTrack& track = *tracks[i];
        LayoutUnit availableLogicalSpaceShare = availableLogicalSpace / (tracksSize - i);
        LayoutUnit trackBreadth = (tracks[i]->*trackGetter)();
        LayoutUnit growthShare = track.m_maxBreadth == infinity ? availableLogicalSpaceShare : std::min(availableLogicalSpaceShare, track.m_maxBreadth - trackBreadth);
        ASSERT(growthShare != infinity);
        sizingData.distributeTrackVector[i] = trackBreadth;
        // We should never shrink any grid track or else we can't guarantee we abide by our min-sizing function.
        if (growthShare > 0) {
            sizingData.distributeTrackVector[i] += growthShare;
            availableLogicalSpace -= growthShare;
        }
    }

    if (availableLogicalSpace > 0 && tracksForGrowthAboveMaxBreadth) {
        tracksSize = tracksForGrowthAboveMaxBreadth->size();
        for (size_t i = 0; i < tracksSize; ++i) {
            LayoutUnit growthShare = availableLogicalSpace / (tracksSize - i);
            sizingData.distributeTrackVector[i] += growthShare;
            availableLogicalSpace -= growthShare;
        }
    }

    for (size_t i = 0; i < tracksSize; ++i) {
        LayoutUnit growth = sizingData.distributeTrackVector[i] - (tracks[i]->*trackGetter)();
        if (growth >= 0)
            (tracks[i]->*trackGrowthFunction)(growth);
    }
}

#if ENABLE(ASSERT)
bool RenderGrid::tracksAreWiderThanMinTrackBreadth(GridTrackSizingDirection direction, const Vector<GridTrack>& tracks)
{
    for (size_t i = 0; i < tracks.size(); ++i) {
        const GridTrackSize& trackSize = gridTrackSize(direction, i);
        const GridLength& minTrackBreadth = trackSize.minTrackBreadth();
        if (computeUsedBreadthOfMinLength(direction, minTrackBreadth) > tracks[i].m_usedBreadth)
            return false;
    }
    return true;
}
#endif

void RenderGrid::ensureGridSize(size_t maximumRowIndex, size_t maximumColumnIndex)
{
    const size_t oldRowSize = gridRowCount();
    if (maximumRowIndex >= oldRowSize) {
        m_grid.grow(maximumRowIndex + 1);
        for (size_t row = oldRowSize; row < gridRowCount(); ++row)
            m_grid[row].grow(gridColumnCount());
    }

    if (maximumColumnIndex >= gridColumnCount()) {
        for (size_t row = 0; row < gridRowCount(); ++row)
            m_grid[row].grow(maximumColumnIndex + 1);
    }
}

void RenderGrid::insertItemIntoGrid(RenderBox* child, const GridCoordinate& coordinate)
{
    ensureGridSize(coordinate.rows.resolvedFinalPosition.toInt(), coordinate.columns.resolvedFinalPosition.toInt());

    for (GridSpan::iterator row = coordinate.rows.begin(); row != coordinate.rows.end(); ++row) {
        for (GridSpan::iterator column = coordinate.columns.begin(); column != coordinate.columns.end(); ++column)
            m_grid[row.toInt()][column.toInt()].append(child);
    }

    RELEASE_ASSERT(!m_gridItemCoordinate.contains(child));
    m_gridItemCoordinate.set(child, coordinate);
}

void RenderGrid::placeItemsOnGrid()
{
    if (!gridIsDirty())
        return;

    ASSERT(m_gridItemCoordinate.isEmpty());

    populateExplicitGridAndOrderIterator();

    // We clear the dirty bit here as the grid sizes have been updated, this means
    // that we can safely call gridRowCount() / gridColumnCount().
    m_gridIsDirty = false;

    Vector<RenderBox*> autoMajorAxisAutoGridItems;
    Vector<RenderBox*> specifiedMajorAxisAutoGridItems;
    for (RenderBox* child = m_orderIterator.first(); child; child = m_orderIterator.next()) {
        // FIXME: We never re-resolve positions if the grid is grown during auto-placement which may lead auto / <integer>
        // positions to not match the author's intent. The specification is unclear on what should be done in this case.
        OwnPtr<GridSpan> rowPositions = GridResolvedPosition::resolveGridPositionsFromStyle(*style(), *child, ForRows);
        OwnPtr<GridSpan> columnPositions = GridResolvedPosition::resolveGridPositionsFromStyle(*style(), *child, ForColumns);
        if (!rowPositions || !columnPositions) {
            GridSpan* majorAxisPositions = (autoPlacementMajorAxisDirection() == ForColumns) ? columnPositions.get() : rowPositions.get();
            if (!majorAxisPositions)
                autoMajorAxisAutoGridItems.append(child);
            else
                specifiedMajorAxisAutoGridItems.append(child);
            continue;
        }
        insertItemIntoGrid(child, GridCoordinate(*rowPositions, *columnPositions));
    }

    ASSERT(gridRowCount() >= style()->gridTemplateRows().size());
    ASSERT(gridColumnCount() >= style()->gridTemplateColumns().size());

    // FIXME: Implement properly "stack" value in auto-placement algorithm.
    if (style()->isGridAutoFlowAlgorithmStack()) {
        // If we did collect some grid items, they won't be placed thus never laid out.
        ASSERT(!autoMajorAxisAutoGridItems.size());
        ASSERT(!specifiedMajorAxisAutoGridItems.size());
        return;
    }

    placeSpecifiedMajorAxisItemsOnGrid(specifiedMajorAxisAutoGridItems);
    placeAutoMajorAxisItemsOnGrid(autoMajorAxisAutoGridItems);

    m_grid.shrinkToFit();
}

void RenderGrid::populateExplicitGridAndOrderIterator()
{
    OrderIteratorPopulator populator(m_orderIterator);

    size_t maximumRowIndex = std::max<size_t>(1, GridResolvedPosition::explicitGridRowCount(*style()));
    size_t maximumColumnIndex = std::max<size_t>(1, GridResolvedPosition::explicitGridColumnCount(*style()));

    ASSERT(m_gridItemsIndexesMap.isEmpty());
    size_t childIndex = 0;
    for (RenderBox* child = firstChildBox(); child; child = child->nextSiblingBox()) {
        populator.collectChild(child);
        m_gridItemsIndexesMap.set(child, childIndex++);

        // This function bypasses the cache (cachedGridCoordinate()) as it is used to build it.
        OwnPtr<GridSpan> rowPositions = GridResolvedPosition::resolveGridPositionsFromStyle(*style(), *child, ForRows);
        OwnPtr<GridSpan> columnPositions = GridResolvedPosition::resolveGridPositionsFromStyle(*style(), *child, ForColumns);

        // |positions| is 0 if we need to run the auto-placement algorithm.
        if (rowPositions) {
            maximumRowIndex = std::max<size_t>(maximumRowIndex, rowPositions->resolvedFinalPosition.next().toInt());
        } else {
            // Grow the grid for items with a definite row span, getting the largest such span.
            GridSpan positions = GridResolvedPosition::resolveGridPositionsFromAutoPlacementPosition(*style(), *child, ForRows, GridResolvedPosition(0));
            maximumRowIndex = std::max<size_t>(maximumRowIndex, positions.resolvedFinalPosition.next().toInt());
        }

        if (columnPositions) {
            maximumColumnIndex = std::max<size_t>(maximumColumnIndex, columnPositions->resolvedFinalPosition.next().toInt());
        } else {
            // Grow the grid for items with a definite column span, getting the largest such span.
            GridSpan positions = GridResolvedPosition::resolveGridPositionsFromAutoPlacementPosition(*style(), *child, ForColumns, GridResolvedPosition(0));
            maximumColumnIndex = std::max<size_t>(maximumColumnIndex, positions.resolvedFinalPosition.next().toInt());
        }
    }

    m_grid.grow(maximumRowIndex);
    for (size_t i = 0; i < m_grid.size(); ++i)
        m_grid[i].grow(maximumColumnIndex);
}

PassOwnPtr<GridCoordinate> RenderGrid::createEmptyGridAreaAtSpecifiedPositionsOutsideGrid(const RenderBox* gridItem, GridTrackSizingDirection specifiedDirection, const GridSpan& specifiedPositions) const
{
    GridTrackSizingDirection crossDirection = specifiedDirection == ForColumns ? ForRows : ForColumns;
    const size_t endOfCrossDirection = crossDirection == ForColumns ? gridColumnCount() : gridRowCount();
    GridSpan crossDirectionPositions = GridResolvedPosition::resolveGridPositionsFromAutoPlacementPosition(*style(), *gridItem, crossDirection, GridResolvedPosition(endOfCrossDirection));
    return adoptPtr(new GridCoordinate(specifiedDirection == ForColumns ? crossDirectionPositions : specifiedPositions, specifiedDirection == ForColumns ? specifiedPositions : crossDirectionPositions));
}

void RenderGrid::placeSpecifiedMajorAxisItemsOnGrid(const Vector<RenderBox*>& autoGridItems)
{
    for (size_t i = 0; i < autoGridItems.size(); ++i) {
        OwnPtr<GridSpan> majorAxisPositions = GridResolvedPosition::resolveGridPositionsFromStyle(*style(), *autoGridItems[i], autoPlacementMajorAxisDirection());
        GridSpan minorAxisPositions = GridResolvedPosition::resolveGridPositionsFromAutoPlacementPosition(*style(), *autoGridItems[i], autoPlacementMinorAxisDirection(), GridResolvedPosition(0));

        GridIterator iterator(m_grid, autoPlacementMajorAxisDirection(), majorAxisPositions->resolvedInitialPosition.toInt());
        OwnPtr<GridCoordinate> emptyGridArea = iterator.nextEmptyGridArea(majorAxisPositions->integerSpan(), minorAxisPositions.integerSpan());
        if (!emptyGridArea)
            emptyGridArea = createEmptyGridAreaAtSpecifiedPositionsOutsideGrid(autoGridItems[i], autoPlacementMajorAxisDirection(), *majorAxisPositions);
        insertItemIntoGrid(autoGridItems[i], *emptyGridArea);
    }
}

void RenderGrid::placeAutoMajorAxisItemsOnGrid(const Vector<RenderBox*>& autoGridItems)
{
    std::pair<size_t, size_t> autoPlacementCursor = std::make_pair(0, 0);
    bool isGridAutoFlowDense = style()->isGridAutoFlowAlgorithmDense();

    for (size_t i = 0; i < autoGridItems.size(); ++i) {
        placeAutoMajorAxisItemOnGrid(autoGridItems[i], autoPlacementCursor);

        // If grid-auto-flow is dense, reset auto-placement cursor.
        if (isGridAutoFlowDense) {
            autoPlacementCursor.first = 0;
            autoPlacementCursor.second = 0;
        }
    }
}

void RenderGrid::placeAutoMajorAxisItemOnGrid(RenderBox* gridItem, std::pair<size_t, size_t>& autoPlacementCursor)
{
    OwnPtr<GridSpan> minorAxisPositions = GridResolvedPosition::resolveGridPositionsFromStyle(*style(), *gridItem, autoPlacementMinorAxisDirection());
    ASSERT(!GridResolvedPosition::resolveGridPositionsFromStyle(*style(), *gridItem, autoPlacementMajorAxisDirection()));
    GridSpan majorAxisPositions = GridResolvedPosition::resolveGridPositionsFromAutoPlacementPosition(*style(), *gridItem, autoPlacementMajorAxisDirection(), GridResolvedPosition(0));

    const size_t endOfMajorAxis = (autoPlacementMajorAxisDirection() == ForColumns) ? gridColumnCount() : gridRowCount();
    size_t majorAxisAutoPlacementCursor = autoPlacementMajorAxisDirection() == ForColumns ? autoPlacementCursor.second : autoPlacementCursor.first;
    size_t minorAxisAutoPlacementCursor = autoPlacementMajorAxisDirection() == ForColumns ? autoPlacementCursor.first : autoPlacementCursor.second;

    OwnPtr<GridCoordinate> emptyGridArea;
    if (minorAxisPositions) {
        // Move to the next track in major axis if initial position in minor axis is before auto-placement cursor.
        if (minorAxisPositions->resolvedInitialPosition.toInt() < minorAxisAutoPlacementCursor)
            majorAxisAutoPlacementCursor++;

        if (majorAxisAutoPlacementCursor < endOfMajorAxis) {
            GridIterator iterator(m_grid, autoPlacementMinorAxisDirection(), minorAxisPositions->resolvedInitialPosition.toInt(), majorAxisAutoPlacementCursor);
            emptyGridArea = iterator.nextEmptyGridArea(minorAxisPositions->integerSpan(), majorAxisPositions.integerSpan());
        }

        if (!emptyGridArea)
            emptyGridArea = createEmptyGridAreaAtSpecifiedPositionsOutsideGrid(gridItem, autoPlacementMinorAxisDirection(), *minorAxisPositions);
    } else {
        GridSpan minorAxisPositions = GridResolvedPosition::resolveGridPositionsFromAutoPlacementPosition(*style(), *gridItem, autoPlacementMinorAxisDirection(), GridResolvedPosition(0));

        for (size_t majorAxisIndex = majorAxisAutoPlacementCursor; majorAxisIndex < endOfMajorAxis; ++majorAxisIndex) {
            GridIterator iterator(m_grid, autoPlacementMajorAxisDirection(), majorAxisIndex, minorAxisAutoPlacementCursor);
            emptyGridArea = iterator.nextEmptyGridArea(majorAxisPositions.integerSpan(), minorAxisPositions.integerSpan());

            if (emptyGridArea) {
                // Check that it fits in the minor axis direction, as we shouldn't grow in that direction here (it was already managed in populateExplicitGridAndOrderIterator()).
                GridResolvedPosition minorAxisFinalPositionIndex = autoPlacementMinorAxisDirection() == ForColumns ? emptyGridArea->columns.resolvedFinalPosition : emptyGridArea->rows.resolvedFinalPosition;
                const size_t endOfMinorAxis = autoPlacementMinorAxisDirection() == ForColumns ? gridColumnCount() : gridRowCount();
                if (minorAxisFinalPositionIndex.toInt() < endOfMinorAxis)
                    break;

                // Discard empty grid area as it does not fit in the minor axis direction.
                // We don't need to create a new empty grid area yet as we might find a valid one in the next iteration.
                emptyGridArea = nullptr;
            }

            // As we're moving to the next track in the major axis we should reset the auto-placement cursor in the minor axis.
            minorAxisAutoPlacementCursor = 0;
        }

        if (!emptyGridArea)
            emptyGridArea = createEmptyGridAreaAtSpecifiedPositionsOutsideGrid(gridItem, autoPlacementMinorAxisDirection(), minorAxisPositions);
    }

    insertItemIntoGrid(gridItem, *emptyGridArea);
    // Move auto-placement cursor to the new position.
    autoPlacementCursor.first = emptyGridArea->rows.resolvedInitialPosition.toInt();
    autoPlacementCursor.second = emptyGridArea->columns.resolvedInitialPosition.toInt();
}

GridTrackSizingDirection RenderGrid::autoPlacementMajorAxisDirection() const
{
    return style()->isGridAutoFlowDirectionColumn() ? ForColumns : ForRows;
}

GridTrackSizingDirection RenderGrid::autoPlacementMinorAxisDirection() const
{
    return style()->isGridAutoFlowDirectionColumn() ? ForRows : ForColumns;
}

void RenderGrid::dirtyGrid()
{
    m_grid.resize(0);
    m_gridItemCoordinate.clear();
    m_gridIsDirty = true;
    m_gridItemsOverflowingGridArea.resize(0);
    m_gridItemsIndexesMap.clear();
}

void RenderGrid::layoutGridItems()
{
    placeItemsOnGrid();

    GridSizingData sizingData(gridColumnCount(), gridRowCount());
    computeUsedBreadthOfGridTracks(ForColumns, sizingData);
    ASSERT(tracksAreWiderThanMinTrackBreadth(ForColumns, sizingData.columnTracks));
    computeUsedBreadthOfGridTracks(ForRows, sizingData);
    ASSERT(tracksAreWiderThanMinTrackBreadth(ForRows, sizingData.rowTracks));

    populateGridPositions(sizingData);
    m_gridItemsOverflowingGridArea.resize(0);

    for (RenderBox* child = firstChildBox(); child; child = child->nextSiblingBox()) {
        // Because the grid area cannot be styled, we don't need to adjust
        // the grid breadth to account for 'box-sizing'.
        LayoutUnit oldOverrideContainingBlockContentLogicalWidth = child->hasOverrideContainingBlockLogicalWidth() ? child->overrideContainingBlockContentLogicalWidth() : LayoutUnit();
        LayoutUnit oldOverrideContainingBlockContentLogicalHeight = child->hasOverrideContainingBlockLogicalHeight() ? child->overrideContainingBlockContentLogicalHeight() : LayoutUnit();

        LayoutUnit overrideContainingBlockContentLogicalWidth = gridAreaBreadthForChild(child, ForColumns, sizingData.columnTracks);
        LayoutUnit overrideContainingBlockContentLogicalHeight = gridAreaBreadthForChild(child, ForRows, sizingData.rowTracks);

        SubtreeLayoutScope layoutScope(*child);
        if (oldOverrideContainingBlockContentLogicalWidth != overrideContainingBlockContentLogicalWidth || (oldOverrideContainingBlockContentLogicalHeight != overrideContainingBlockContentLogicalHeight && child->hasRelativeLogicalHeight()))
            layoutScope.setNeedsLayout(child);

        child->setOverrideContainingBlockContentLogicalWidth(overrideContainingBlockContentLogicalWidth);
        child->setOverrideContainingBlockContentLogicalHeight(overrideContainingBlockContentLogicalHeight);

        // FIXME: Grid items should stretch to fill their cells. Once we
        // implement grid-{column,row}-align, we can also shrink to fit. For
        // now, just size as if we were a regular child.
        child->layoutIfNeeded();

#if ENABLE(ASSERT)
        const GridCoordinate& coordinate = cachedGridCoordinate(child);
        ASSERT(coordinate.columns.resolvedInitialPosition.toInt() < sizingData.columnTracks.size());
        ASSERT(coordinate.rows.resolvedInitialPosition.toInt() < sizingData.rowTracks.size());
#endif
        child->setLogicalLocation(findChildLogicalPosition(child));

        // Keep track of children overflowing their grid area as we might need to paint them even if the grid-area is
        // not visible
        if (child->logicalHeight() > overrideContainingBlockContentLogicalHeight
            || child->logicalWidth() > overrideContainingBlockContentLogicalWidth)
            m_gridItemsOverflowingGridArea.append(child);
    }

    for (size_t i = 0; i < sizingData.rowTracks.size(); ++i)
        setLogicalHeight(logicalHeight() + sizingData.rowTracks[i].m_usedBreadth);

    // Min / max logical height is handled by the call to updateLogicalHeight in layoutBlock.

    setLogicalHeight(logicalHeight() + borderAndPaddingLogicalHeight());
}

GridCoordinate RenderGrid::cachedGridCoordinate(const RenderBox* gridItem) const
{
    ASSERT(m_gridItemCoordinate.contains(gridItem));
    return m_gridItemCoordinate.get(gridItem);
}

LayoutUnit RenderGrid::gridAreaBreadthForChild(const RenderBox* child, GridTrackSizingDirection direction, const Vector<GridTrack>& tracks) const
{
    const GridCoordinate& coordinate = cachedGridCoordinate(child);
    const GridSpan& span = (direction == ForColumns) ? coordinate.columns : coordinate.rows;
    LayoutUnit gridAreaBreadth = 0;
    for (GridSpan::iterator trackPosition = span.begin(); trackPosition != span.end(); ++trackPosition)
        gridAreaBreadth += tracks[trackPosition.toInt()].m_usedBreadth;
    return gridAreaBreadth;
}

void RenderGrid::populateGridPositions(const GridSizingData& sizingData)
{
    m_columnPositions.resize(sizingData.columnTracks.size() + 1);
    m_columnPositions[0] = borderAndPaddingStart();
    for (size_t i = 0; i < m_columnPositions.size() - 1; ++i)
        m_columnPositions[i + 1] = m_columnPositions[i] + sizingData.columnTracks[i].m_usedBreadth;

    m_rowPositions.resize(sizingData.rowTracks.size() + 1);
    m_rowPositions[0] = borderAndPaddingBefore();
    for (size_t i = 0; i < m_rowPositions.size() - 1; ++i)
        m_rowPositions[i + 1] = m_rowPositions[i] + sizingData.rowTracks[i].m_usedBreadth;
}

LayoutUnit RenderGrid::startOfColumnForChild(const RenderBox* child) const
{
    const GridCoordinate& coordinate = cachedGridCoordinate(child);
    LayoutUnit startOfColumn = m_columnPositions[coordinate.columns.resolvedInitialPosition.toInt()];
    // The grid items should be inside the grid container's border box, that's why they need to be shifted.
    // FIXME: This should account for the grid item's <overflow-position>.
    return startOfColumn + marginStartForChild(child);
}

LayoutUnit RenderGrid::endOfColumnForChild(const RenderBox* child) const
{
    const GridCoordinate& coordinate = cachedGridCoordinate(child);
    LayoutUnit startOfColumn = m_columnPositions[coordinate.columns.resolvedInitialPosition.toInt()];
    // The grid items should be inside the grid container's border box, that's why they need to be shifted.
    LayoutUnit columnPosition = startOfColumn + marginStartForChild(child);

    LayoutUnit endOfColumn = m_columnPositions[coordinate.columns.resolvedFinalPosition.next().toInt()];
    // FIXME: This should account for the grid item's <overflow-position>.
    return columnPosition + std::max<LayoutUnit>(0, endOfColumn - m_columnPositions[coordinate.columns.resolvedInitialPosition.toInt()] - child->logicalWidth());
}

LayoutUnit RenderGrid::columnPositionAlignedWithGridContainerStart(const RenderBox* child) const
{
    if (style()->isLeftToRightDirection())
        return startOfColumnForChild(child);

    return endOfColumnForChild(child);
}

LayoutUnit RenderGrid::columnPositionAlignedWithGridContainerEnd(const RenderBox* child) const
{
    if (!style()->isLeftToRightDirection())
        return startOfColumnForChild(child);

    return endOfColumnForChild(child);
}

LayoutUnit RenderGrid::centeredColumnPositionForChild(const RenderBox* child) const
{
    const GridCoordinate& coordinate = cachedGridCoordinate(child);
    LayoutUnit startOfColumn = m_columnPositions[coordinate.columns.resolvedInitialPosition.toInt()];
    LayoutUnit endOfColumn = m_columnPositions[coordinate.columns.resolvedFinalPosition.next().toInt()];
    LayoutUnit columnPosition = startOfColumn + marginStartForChild(child);
    // FIXME: This should account for the grid item's <overflow-position>.
    return columnPosition + std::max<LayoutUnit>(0, endOfColumn - startOfColumn - child->logicalWidth()) / 2;
}

static ItemPosition resolveJustification(const RenderStyle* parentStyle, const RenderStyle* childStyle)
{
    ItemPosition justify = childStyle->justifySelf();
    if (justify == ItemPositionAuto)
        justify = (parentStyle->justifyItems() == ItemPositionAuto) ? ItemPositionStretch : parentStyle->justifyItems();

    return justify;
}

LayoutUnit RenderGrid::columnPositionForChild(const RenderBox* child) const
{
    bool hasOrthogonalWritingMode = child->isHorizontalWritingMode() != isHorizontalWritingMode();

    switch (resolveJustification(style(), child->style())) {
    case ItemPositionSelfStart:
        // For orthogonal writing-modes, this computes to 'start'
        // FIXME: grid track sizing and positioning do not support orthogonal modes yet.
        if (hasOrthogonalWritingMode)
            return columnPositionAlignedWithGridContainerStart(child);

        // self-start is based on the child's direction. That's why we need to check against the grid container's direction.
        if (child->style()->direction() != style()->direction())
            return columnPositionAlignedWithGridContainerEnd(child);

        return columnPositionAlignedWithGridContainerStart(child);
    case ItemPositionSelfEnd:
        // For orthogonal writing-modes, this computes to 'start'
        // FIXME: grid track sizing and positioning do not support orthogonal modes yet.
        if (hasOrthogonalWritingMode)
            return columnPositionAlignedWithGridContainerEnd(child);

        // self-end is based on the child's direction. That's why we need to check against the grid container's direction.
        if (child->style()->direction() != style()->direction())
            return columnPositionAlignedWithGridContainerStart(child);

        return columnPositionAlignedWithGridContainerEnd(child);

    case ItemPositionFlexStart:
        // Only used in flex layout, for other layout, it's equivalent to 'start'.
        return columnPositionAlignedWithGridContainerStart(child);
    case ItemPositionFlexEnd:
        // Only used in flex layout, for other layout, it's equivalent to 'start'.
        return columnPositionAlignedWithGridContainerEnd(child);

    case ItemPositionLeft:
        // If the property's axis is not parallel with the inline axis, this is equivalent to ‘start’.
        if (!isHorizontalWritingMode())
            return columnPositionAlignedWithGridContainerStart(child);

        if (style()->isLeftToRightDirection())
            return columnPositionAlignedWithGridContainerStart(child);

        return columnPositionAlignedWithGridContainerEnd(child);
    case ItemPositionRight:
        // If the property's axis is not parallel with the inline axis, this is equivalent to ‘start’.
        if (!isHorizontalWritingMode())
            return columnPositionAlignedWithGridContainerStart(child);

        if (style()->isLeftToRightDirection())
            return columnPositionAlignedWithGridContainerEnd(child);

        return columnPositionAlignedWithGridContainerStart(child);

    case ItemPositionCenter:
        return centeredColumnPositionForChild(child);
    case ItemPositionStart:
        return columnPositionAlignedWithGridContainerStart(child);
    case ItemPositionEnd:
        return columnPositionAlignedWithGridContainerEnd(child);

    case ItemPositionAuto:
        break;
    case ItemPositionStretch:
    case ItemPositionBaseline:
    case ItemPositionLastBaseline:
        // FIXME: Implement the previous values. For now, we always start align the child.
        return startOfColumnForChild(child);
    }

    ASSERT_NOT_REACHED();
    return 0;
}

LayoutUnit RenderGrid::endOfRowForChild(const RenderBox* child) const
{
    const GridCoordinate& coordinate = cachedGridCoordinate(child);

    LayoutUnit startOfRow = m_rowPositions[coordinate.rows.resolvedInitialPosition.toInt()];
    // The grid items should be inside the grid container's border box, that's why they need to be shifted.
    LayoutUnit rowPosition = startOfRow + marginBeforeForChild(child);

    LayoutUnit endOfRow = m_rowPositions[coordinate.rows.resolvedFinalPosition.next().toInt()];
    // FIXME: This should account for the grid item's <overflow-position>.
    return rowPosition + std::max<LayoutUnit>(0, endOfRow - startOfRow - child->logicalHeight());
}

LayoutUnit RenderGrid::startOfRowForChild(const RenderBox* child) const
{
    const GridCoordinate& coordinate = cachedGridCoordinate(child);

    LayoutUnit startOfRow = m_rowPositions[coordinate.rows.resolvedInitialPosition.toInt()];
    // The grid items should be inside the grid container's border box, that's why they need to be shifted.
    // FIXME: This should account for the grid item's <overflow-position>.
    LayoutUnit rowPosition = startOfRow + marginBeforeForChild(child);

    return rowPosition;
}

LayoutUnit RenderGrid::centeredRowPositionForChild(const RenderBox* child) const
{
    const GridCoordinate& coordinate = cachedGridCoordinate(child);

    // The grid items should be inside the grid container's border box, that's why they need to be shifted.
    LayoutUnit startOfRow = m_rowPositions[coordinate.rows.resolvedInitialPosition.toInt()] + marginBeforeForChild(child);
    LayoutUnit endOfRow = m_rowPositions[coordinate.rows.resolvedFinalPosition.next().toInt()];

    // FIXME: This should account for the grid item's <overflow-position>.
    return startOfRow + std::max<LayoutUnit>(0, endOfRow - startOfRow - child->logicalHeight()) / 2;
}

// FIXME: We should move this logic to the StyleAdjuster or the StyleBuilder.
static ItemPosition resolveAlignment(const RenderStyle* parentStyle, const RenderStyle* childStyle)
{
    ItemPosition align = childStyle->alignSelf();
    // The auto keyword computes to the parent's align-items computed value, or to "stretch", if not set or "auto".
    if (align == ItemPositionAuto)
        align = (parentStyle->alignItems() == ItemPositionAuto) ? ItemPositionStretch : parentStyle->alignItems();
    return align;
}

LayoutUnit RenderGrid::rowPositionForChild(const RenderBox* child) const
{
    bool hasOrthogonalWritingMode = child->isHorizontalWritingMode() != isHorizontalWritingMode();
    ItemPosition alignSelf = resolveAlignment(style(), child->style());

    switch (alignSelf) {
    case ItemPositionSelfStart:
        // If orthogonal writing-modes, this computes to 'Start'.
        // FIXME: grid track sizing and positioning does not support orthogonal modes yet.
        if (hasOrthogonalWritingMode)
            return startOfRowForChild(child);

        // self-start is based on the child's block axis direction. That's why we need to check against the grid container's block flow.
        if (child->style()->writingMode() != style()->writingMode())
            return endOfRowForChild(child);

        return startOfRowForChild(child);
    case ItemPositionSelfEnd:
        // If orthogonal writing-modes, this computes to 'End'.
        // FIXME: grid track sizing and positioning does not support orthogonal modes yet.
        if (hasOrthogonalWritingMode)
            return endOfRowForChild(child);

        // self-end is based on the child's block axis direction. That's why we need to check against the grid container's block flow.
        if (child->style()->writingMode() != style()->writingMode())
            return startOfRowForChild(child);

        return endOfRowForChild(child);

    case ItemPositionLeft:
        // orthogonal modes make property and inline axes to be parallel, but in any case
        // this is always equivalent to 'Start'.
        //
        // self-align's axis is never parallel to the inline axis, except in orthogonal
        // writing-mode, so this is equivalent to 'Start’.
        return startOfRowForChild(child);

    case ItemPositionRight:
        // orthogonal modes make property and inline axes to be parallel.
        // FIXME: grid track sizing and positioning does not support orthogonal modes yet.
        if (hasOrthogonalWritingMode)
            return endOfRowForChild(child);

        // self-align's axis is never parallel to the inline axis, except in orthogonal
        // writing-mode, so this is equivalent to 'Start'.
        return startOfRowForChild(child);

    case ItemPositionCenter:
        return centeredRowPositionForChild(child);
        // Only used in flex layout, for other layout, it's equivalent to 'Start'.
    case ItemPositionFlexStart:
    case ItemPositionStart:
        return startOfRowForChild(child);
        // Only used in flex layout, for other layout, it's equivalent to 'End'.
    case ItemPositionFlexEnd:
    case ItemPositionEnd:
        return endOfRowForChild(child);
    case ItemPositionStretch:
        // FIXME: Implement the Stretch value. For now, we always start align the child.
        return startOfRowForChild(child);
    case ItemPositionBaseline:
    case ItemPositionLastBaseline:
        // FIXME: Implement the ItemPositionBaseline value. For now, we always start align the child.
        return startOfRowForChild(child);
    case ItemPositionAuto:
        break;
    }

    ASSERT_NOT_REACHED();
    return 0;
}

LayoutPoint RenderGrid::findChildLogicalPosition(const RenderBox* child) const
{
    return LayoutPoint(columnPositionForChild(child), rowPositionForChild(child));
}

static GridSpan dirtiedGridAreas(const Vector<LayoutUnit>& coordinates, LayoutUnit start, LayoutUnit end)
{
    // This function does a binary search over the coordinates.
    // This doesn't work with grid items overflowing their grid areas, but that is managed with m_gridItemsOverflowingGridArea.

    size_t startGridAreaIndex = std::upper_bound(coordinates.begin(), coordinates.end() - 1, start) - coordinates.begin();
    if (startGridAreaIndex > 0)
        --startGridAreaIndex;

    size_t endGridAreaIndex = std::upper_bound(coordinates.begin() + startGridAreaIndex, coordinates.end() - 1, end) - coordinates.begin();
    if (endGridAreaIndex > 0)
        --endGridAreaIndex;

    return GridSpan(startGridAreaIndex, endGridAreaIndex);
}

class GridItemsSorter {
public:
    bool operator()(const std::pair<RenderBox*, size_t>& firstChild, const std::pair<RenderBox*, size_t>& secondChild) const
    {
        if (firstChild.first->style()->order() != secondChild.first->style()->order())
            return firstChild.first->style()->order() < secondChild.first->style()->order();

        return firstChild.second < secondChild.second;
    }
};

void RenderGrid::paintChildren(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    ASSERT_WITH_SECURITY_IMPLICATION(!gridIsDirty());

    LayoutRect localPaintInvalidationRect = paintInfo.rect;
    localPaintInvalidationRect.moveBy(-paintOffset);

    GridSpan dirtiedColumns = dirtiedGridAreas(m_columnPositions, localPaintInvalidationRect.x(), localPaintInvalidationRect.maxX());
    GridSpan dirtiedRows = dirtiedGridAreas(m_rowPositions, localPaintInvalidationRect.y(), localPaintInvalidationRect.maxY());

    Vector<std::pair<RenderBox*, size_t> > gridItemsToBePainted;

    for (GridSpan::iterator row = dirtiedRows.begin(); row != dirtiedRows.end(); ++row) {
        for (GridSpan::iterator column = dirtiedColumns.begin(); column != dirtiedColumns.end(); ++column) {
            const Vector<RenderBox*, 1>& children = m_grid[row.toInt()][column.toInt()];
            for (size_t j = 0; j < children.size(); ++j)
                gridItemsToBePainted.append(std::make_pair(children[j], m_gridItemsIndexesMap.get(children[j])));
        }
    }

    for (Vector<RenderBox*>::const_iterator it = m_gridItemsOverflowingGridArea.begin(); it != m_gridItemsOverflowingGridArea.end(); ++it) {
        if ((*it)->frameRect().intersects(localPaintInvalidationRect))
            gridItemsToBePainted.append(std::make_pair(*it, m_gridItemsIndexesMap.get(*it)));
    }

    // Sort grid items following order-modified document order.
    // See http://www.w3.org/TR/css-flexbox/#order-modified-document-order
    std::stable_sort(gridItemsToBePainted.begin(), gridItemsToBePainted.end(), GridItemsSorter());

    RenderBox* previous = 0;
    for (Vector<std::pair<RenderBox*, size_t> >::const_iterator it = gridItemsToBePainted.begin(); it != gridItemsToBePainted.end(); ++it) {
        // We might have duplicates because of spanning children are included in all cells they span.
        // Skip them here to avoid painting items several times.
        RenderBox* current = (*it).first;
        if (current == previous)
            continue;

        paintChild(current, paintInfo, paintOffset);
        previous = current;
    }
}

const char* RenderGrid::renderName() const
{
    if (isFloating())
        return "RenderGrid (floating)";
    if (isOutOfFlowPositioned())
        return "RenderGrid (positioned)";
    if (isAnonymous())
        return "RenderGrid (generated)";
    if (isRelPositioned())
        return "RenderGrid (relative positioned)";
    return "RenderGrid";
}

} // namespace blink
