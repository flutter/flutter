/*
 * Copyright (C) 2007, 2009, 2010 Apple Inc.  All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
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
#include "core/html/TimeRanges.h"

#include "bindings/core/v8/ExceptionMessages.h"
#include "bindings/core/v8/ExceptionState.h"
#include "bindings/core/v8/ExceptionStatePlaceholder.h"
#include "core/dom/ExceptionCode.h"
#include <math.h>

using namespace blink;

TimeRanges::TimeRanges(double start, double end)
{
    ScriptWrappable::init(this);
    add(start, end);
}

PassRefPtrWillBeRawPtr<TimeRanges> TimeRanges::create(const blink::WebTimeRanges& webRanges)
{
    RefPtrWillBeRawPtr<TimeRanges> ranges = TimeRanges::create();

    unsigned size = webRanges.size();
    for (unsigned i = 0; i < size; ++i)
        ranges->add(webRanges[i].start, webRanges[i].end);

    return ranges.release();
}

PassRefPtrWillBeRawPtr<TimeRanges> TimeRanges::copy() const
{
    RefPtrWillBeRawPtr<TimeRanges> newSession = TimeRanges::create();

    unsigned size = m_ranges.size();
    for (unsigned i = 0; i < size; i++)
        newSession->add(m_ranges[i].m_start, m_ranges[i].m_end);

    return newSession.release();
}

void TimeRanges::invert()
{
    RefPtrWillBeRawPtr<TimeRanges> inverted = TimeRanges::create();
    double posInf = std::numeric_limits<double>::infinity();
    double negInf = -std::numeric_limits<double>::infinity();

    if (!m_ranges.size())
        inverted->add(negInf, posInf);
    else {
        double start = m_ranges.first().m_start;
        if (start != negInf)
            inverted->add(negInf, start);

        for (size_t index = 0; index + 1 < m_ranges.size(); ++index)
            inverted->add(m_ranges[index].m_end, m_ranges[index + 1].m_start);

        double end = m_ranges.last().m_end;
        if (end != posInf)
            inverted->add(end, posInf);
    }

    m_ranges.swap(inverted->m_ranges);
}

void TimeRanges::intersectWith(const TimeRanges* other)
{
    ASSERT(other);

    if (other == this)
        return;

    RefPtrWillBeRawPtr<TimeRanges> invertedOther = other->copy();
    invertedOther->invert();

    invert();
    unionWith(invertedOther.get());
    invert();
}

void TimeRanges::unionWith(const TimeRanges* other)
{
    ASSERT(other);
    RefPtrWillBeRawPtr<TimeRanges> unioned = copy();
    for (size_t index = 0; index < other->m_ranges.size(); ++index) {
        const Range& range = other->m_ranges[index];
        unioned->add(range.m_start, range.m_end);
    }

    m_ranges.swap(unioned->m_ranges);
}

double TimeRanges::start(unsigned index, ExceptionState& exceptionState) const
{
    if (index >= length()) {
        exceptionState.throwDOMException(IndexSizeError, ExceptionMessages::indexExceedsMaximumBound("index", index, length()));
        return 0;
    }
    return m_ranges[index].m_start;
}

double TimeRanges::end(unsigned index, ExceptionState& exceptionState) const
{
    if (index >= length()) {
        exceptionState.throwDOMException(IndexSizeError, ExceptionMessages::indexExceedsMaximumBound("index", index, length()));
        return 0;
    }
    return m_ranges[index].m_end;
}

void TimeRanges::add(double start, double end)
{
    ASSERT(start <= end);
    unsigned overlappingArcIndex;
    Range addedRange(start, end);

    // For each present range check if we need to:
    // - merge with the added range, in case we are overlapping or contiguous
    // - Need to insert in place, we we are completely, not overlapping and not contiguous
    // in between two ranges.
    //
    // TODO: Given that we assume that ranges are correctly ordered, this could be optimized.

    for (overlappingArcIndex = 0; overlappingArcIndex < m_ranges.size(); overlappingArcIndex++) {
        if (addedRange.isOverlappingRange(m_ranges[overlappingArcIndex])
         || addedRange.isContiguousWithRange(m_ranges[overlappingArcIndex])) {
            // We need to merge the addedRange and that range.
            addedRange = addedRange.unionWithOverlappingOrContiguousRange(m_ranges[overlappingArcIndex]);
            m_ranges.remove(overlappingArcIndex);
            overlappingArcIndex--;
        } else {
            // Check the case for which there is no more to do
            if (!overlappingArcIndex) {
                if (addedRange.isBeforeRange(m_ranges[0])) {
                    // First index, and we are completely before that range (and not contiguous, nor overlapping).
                    // We just need to be inserted here.
                    break;
                }
            } else {
                if (m_ranges[overlappingArcIndex - 1].isBeforeRange(addedRange)
                 && addedRange.isBeforeRange(m_ranges[overlappingArcIndex])) {
                    // We are exactly after the current previous range, and before the current range, while
                    // not overlapping with none of them. Insert here.
                    break;
                }
            }
        }
    }

    // Now that we are sure we don't overlap with any range, just add it.
    m_ranges.insert(overlappingArcIndex, addedRange);
}

bool TimeRanges::contain(double time) const
{
    for (unsigned n = 0; n < length(); n++) {
        if (time >= start(n, IGNORE_EXCEPTION) && time <= end(n, IGNORE_EXCEPTION))
            return true;
    }
    return false;
}

double TimeRanges::nearest(double time) const
{
    double closest = 0;
    unsigned count = length();
    for (unsigned ndx = 0; ndx < count; ndx++) {
        double startTime = start(ndx, IGNORE_EXCEPTION);
        double endTime = end(ndx, IGNORE_EXCEPTION);
        if (time >= startTime && time <= endTime)
            return time;
        if (fabs(startTime - time) < closest)
            closest = fabs(startTime - time);
        else if (fabs(endTime - time) < closest)
            closest = fabs(endTime - time);
    }
    return closest;
}

void TimeRanges::trace(Visitor* visitor)
{
    visitor->trace(m_ranges);
}
