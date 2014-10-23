/*
 * Copyright (C) 2008 Apple Inc. All Rights Reserved.
 * Copyright (C) 2013 Google Inc. All Rights Reserved.
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
 *
 */

#include "config.h"
#include "core/dom/ContextLifecycleNotifier.h"

#include "core/dom/ExecutionContext.h"
#include "wtf/TemporaryChange.h"

namespace blink {

ContextLifecycleNotifier::ContextLifecycleNotifier(ExecutionContext* context)
    : LifecycleNotifier<ExecutionContext>(context)
{
}

ContextLifecycleNotifier::~ContextLifecycleNotifier()
{
}

void ContextLifecycleNotifier::addObserver(ContextLifecycleNotifier::Observer* observer)
{
    LifecycleNotifier<ExecutionContext>::addObserver(observer);

    RELEASE_ASSERT(m_iterating != IteratingOverContextObservers);
    if (observer->observerType() == Observer::ActiveDOMObjectType) {
        RELEASE_ASSERT(m_iterating != IteratingOverActiveDOMObjects);
        m_activeDOMObjects.add(static_cast<ActiveDOMObject*>(observer));
    }
}

void ContextLifecycleNotifier::removeObserver(ContextLifecycleNotifier::Observer* observer)
{
    LifecycleNotifier<ExecutionContext>::removeObserver(observer);

    RELEASE_ASSERT(m_iterating != IteratingOverContextObservers);
    if (observer->observerType() == Observer::ActiveDOMObjectType) {
        m_activeDOMObjects.remove(static_cast<ActiveDOMObject*>(observer));
    }
}

void ContextLifecycleNotifier::notifyResumingActiveDOMObjects()
{
    TemporaryChange<IterationType> scope(this->m_iterating, IteratingOverActiveDOMObjects);
    Vector<ActiveDOMObject*> snapshotOfActiveDOMObjects;
    copyToVector(m_activeDOMObjects, snapshotOfActiveDOMObjects);
    for (Vector<ActiveDOMObject*>::iterator iter = snapshotOfActiveDOMObjects.begin(); iter != snapshotOfActiveDOMObjects.end(); iter++) {
        // FIXME: Oilpan: At the moment, it's possible that the ActiveDOMObject is destructed
        // during the iteration. Once we move ActiveDOMObject to the heap and
        // make m_activeDOMObjects a HeapHashSet<WeakMember<ActiveDOMObject>>,
        // it's no longer possible that ActiveDOMObject is destructed during the iteration,
        // so we can remove the hack (i.e., we can just iterate m_activeDOMObjects without
        // taking a snapshot). For more details, see https://codereview.chromium.org/247253002/.
        if (m_activeDOMObjects.contains(*iter)) {
            ASSERT((*iter)->executionContext() == context());
            ASSERT((*iter)->suspendIfNeededCalled());
            (*iter)->resume();
        }
    }
}

void ContextLifecycleNotifier::notifySuspendingActiveDOMObjects()
{
    TemporaryChange<IterationType> scope(this->m_iterating, IteratingOverActiveDOMObjects);
    Vector<ActiveDOMObject*> snapshotOfActiveDOMObjects;
    copyToVector(m_activeDOMObjects, snapshotOfActiveDOMObjects);
    for (Vector<ActiveDOMObject*>::iterator iter = snapshotOfActiveDOMObjects.begin(); iter != snapshotOfActiveDOMObjects.end(); iter++) {
        // It's possible that the ActiveDOMObject is already destructed.
        // See a FIXME above.
        if (m_activeDOMObjects.contains(*iter)) {
            ASSERT((*iter)->executionContext() == context());
            ASSERT((*iter)->suspendIfNeededCalled());
            (*iter)->suspend();
        }
    }
}

void ContextLifecycleNotifier::notifyStoppingActiveDOMObjects()
{
    TemporaryChange<IterationType> scope(this->m_iterating, IteratingOverActiveDOMObjects);
    Vector<ActiveDOMObject*> snapshotOfActiveDOMObjects;
    copyToVector(m_activeDOMObjects, snapshotOfActiveDOMObjects);
    for (Vector<ActiveDOMObject*>::iterator iter = snapshotOfActiveDOMObjects.begin(); iter != snapshotOfActiveDOMObjects.end(); iter++) {
        // It's possible that the ActiveDOMObject is already destructed.
        // See a FIXME above.
        if (m_activeDOMObjects.contains(*iter)) {
            ASSERT((*iter)->executionContext() == context());
            ASSERT((*iter)->suspendIfNeededCalled());
            (*iter)->stop();
        }
    }
}

bool ContextLifecycleNotifier::hasPendingActivity() const
{
    for (ActiveDOMObjectSet::const_iterator iter = m_activeDOMObjects.begin(); iter != m_activeDOMObjects.end(); ++iter) {
        if ((*iter)->hasPendingActivity())
            return true;
    }
    return false;
}

} // namespace blink
