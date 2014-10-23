/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2006, 2007, 2008 Apple Inc.  All right reserved.
 * Copyright (C) 2011 Google, Inc.  All rights reserved.
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

#ifndef BidiRunList_h
#define BidiRunList_h

#include "wtf/Assertions.h"
#include "wtf/Noncopyable.h"

namespace blink {

template <class Run>
class BidiRunList {
    WTF_MAKE_NONCOPYABLE(BidiRunList);
public:
    BidiRunList()
        : m_firstRun(0)
        , m_lastRun(0)
        , m_logicallyLastRun(0)
        , m_runCount(0)
    {
    }

    // FIXME: Once BidiResolver no longer owns the BidiRunList,
    // then ~BidiRunList should call deleteRuns() automatically.

    Run* firstRun() const { return m_firstRun; }
    Run* lastRun() const { return m_lastRun; }
    Run* logicallyLastRun() const { return m_logicallyLastRun; }
    unsigned runCount() const { return m_runCount; }

    void addRun(Run*);
    void prependRun(Run*);

    void moveRunToEnd(Run*);
    void moveRunToBeginning(Run*);

    void deleteRuns();
    void reverseRuns(unsigned start, unsigned end);
    void reorderRunsFromLevels();

    void setLogicallyLastRun(Run* run) { m_logicallyLastRun = run; }

    void replaceRunWithRuns(Run* toReplace, BidiRunList<Run>& newRuns);

private:
    void clearWithoutDestroyingRuns();

    Run* m_firstRun;
    Run* m_lastRun;
    Run* m_logicallyLastRun;
    unsigned m_runCount;
};

template <class Run>
inline void BidiRunList<Run>::addRun(Run* run)
{
    if (!m_firstRun)
        m_firstRun = run;
    else
        m_lastRun->m_next = run;
    m_lastRun = run;
    m_runCount++;
}

template <class Run>
inline void BidiRunList<Run>::prependRun(Run* run)
{
    ASSERT(!run->m_next);

    if (!m_lastRun)
        m_lastRun = run;
    else
        run->m_next = m_firstRun;
    m_firstRun = run;
    m_runCount++;
}

template <class Run>
inline void BidiRunList<Run>::moveRunToEnd(Run* run)
{
    ASSERT(m_firstRun);
    ASSERT(m_lastRun);
    ASSERT(run->m_next);

    Run* current = 0;
    Run* next = m_firstRun;
    while (next != run) {
        current = next;
        next = current->next();
    }

    if (!current)
        m_firstRun = run->next();
    else
        current->m_next = run->m_next;

    run->m_next = 0;
    m_lastRun->m_next = run;
    m_lastRun = run;
}

template <class Run>
inline void BidiRunList<Run>::moveRunToBeginning(Run* run)
{
    ASSERT(m_firstRun);
    ASSERT(m_lastRun);
    ASSERT(run != m_firstRun);

    Run* current = m_firstRun;
    Run* next = current->next();
    while (next != run) {
        current = next;
        next = current->next();
    }

    current->m_next = run->m_next;
    if (run == m_lastRun)
        m_lastRun = current;

    run->m_next = m_firstRun;
    m_firstRun = run;
}

template <class Run>
void BidiRunList<Run>::replaceRunWithRuns(Run* toReplace, BidiRunList<Run>& newRuns)
{
    ASSERT(newRuns.runCount());
    ASSERT(m_firstRun);
    ASSERT(toReplace);

    if (m_firstRun == toReplace) {
        m_firstRun = newRuns.firstRun();
    } else {
        // Find the run just before "toReplace" in the list of runs.
        Run* previousRun = m_firstRun;
        while (previousRun->next() != toReplace)
            previousRun = previousRun->next();
        ASSERT(previousRun);
        previousRun->setNext(newRuns.firstRun());
    }

    newRuns.lastRun()->setNext(toReplace->next());

    // Fix up any of other pointers which may now be stale.
    if (m_lastRun == toReplace)
        m_lastRun = newRuns.lastRun();
    if (m_logicallyLastRun == toReplace)
        m_logicallyLastRun = newRuns.logicallyLastRun();
    m_runCount += newRuns.runCount() - 1; // We added the new runs and removed toReplace.

    delete toReplace;
    newRuns.clearWithoutDestroyingRuns();
}

template <class Run>
void BidiRunList<Run>::clearWithoutDestroyingRuns()
{
    m_firstRun = 0;
    m_lastRun = 0;
    m_logicallyLastRun = 0;
    m_runCount = 0;
}

template <class Run>
void BidiRunList<Run>::deleteRuns()
{
    if (!m_firstRun)
        return;

    Run* curr = m_firstRun;
    while (curr) {
        Run* s = curr->next();
        delete curr;
        curr = s;
    }

    clearWithoutDestroyingRuns();
}

template <class Run>
void BidiRunList<Run>::reverseRuns(unsigned start, unsigned end)
{
    ASSERT(m_runCount);
    if (start >= end)
        return;

    ASSERT(end < m_runCount);

    // Get the item before the start of the runs to reverse and put it in
    // |beforeStart|. |curr| should point to the first run to reverse.
    Run* curr = m_firstRun;
    Run* beforeStart = 0;
    unsigned i = 0;
    while (i < start) {
        i++;
        beforeStart = curr;
        curr = curr->next();
    }

    Run* startRun = curr;
    while (i < end) {
        i++;
        curr = curr->next();
    }
    Run* endRun = curr;
    Run* afterEnd = curr->next();

    i = start;
    curr = startRun;
    Run* newNext = afterEnd;
    while (i <= end) {
        // Do the reversal.
        Run* next = curr->next();
        curr->m_next = newNext;
        newNext = curr;
        curr = next;
        i++;
    }

    // Now hook up beforeStart and afterEnd to the startRun and endRun.
    if (beforeStart)
        beforeStart->m_next = endRun;
    else
        m_firstRun = endRun;

    startRun->m_next = afterEnd;
    if (!afterEnd)
        m_lastRun = startRun;
}

} // namespace blink

#endif // BidiRunList
