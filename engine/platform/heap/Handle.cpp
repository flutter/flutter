// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "platform/heap/Handle.h"

namespace blink {

bool WrapperPersistentRegion::removeIfNotLast(WrapperPersistentRegion** headPtr)
{
    ASSERT(!m_count);
    // We are the last region in the list if both the region's m_prev and
    // m_next are 0.
    if (!m_prev && !m_next)
        return false;
    if (m_prev) {
        m_prev->m_next = m_next;
    } else {
        ASSERT(*headPtr == this);
        *headPtr = m_next;
    }
    if (m_next)
        m_next->m_prev = m_prev;
    m_prev = 0;
    m_next = 0;
    return true;
}

void WrapperPersistentRegion::insertHead(WrapperPersistentRegion** headPtr, WrapperPersistentRegion* newHead)
{
    ASSERT(headPtr);
    WrapperPersistentRegion* oldHead = *headPtr;
    if (oldHead) {
        ASSERT(!oldHead->m_prev);
        oldHead->m_prev = newHead;
    }
    newHead->m_prev = 0;
    newHead->m_next = oldHead;
    *headPtr = newHead;
}

WrapperPersistentRegion* WrapperPersistentRegion::removeHead(WrapperPersistentRegion** headPtr)
{
    // We only call this if there is at least one element in the list.
    ASSERT(headPtr && *headPtr);
    WrapperPersistentRegion* oldHead = *headPtr;
    ASSERT(!oldHead->m_prev);
    *headPtr = oldHead->m_next;
    oldHead->m_next = 0;
    ASSERT(!(*headPtr) || (*headPtr)->m_prev == oldHead);
    if (*headPtr)
        (*headPtr)->m_prev = 0;
    return oldHead;
}

void* WrapperPersistentRegion::outOfLineAllocate(ThreadState* state, WrapperPersistentRegion* head)
{
    void* persistent = 0;
    // The caller has already tried allocating in the passed-in region, start
    // from the next.
    for (WrapperPersistentRegion* current = head->m_next; current; current = current->m_next) {
        persistent = current->allocate();
        if (persistent)
            return persistent;
    }
    ASSERT(!persistent);
    WrapperPersistentRegion* newRegion = state->takeWrapperPersistentRegion();
    persistent = newRegion->allocate();
    ASSERT(persistent);
    return persistent;
}

}
