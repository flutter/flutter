/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
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

#include "sky/engine/core/dom/MutationObserver.h"

#include <algorithm>
#include "base/bind.h"
#include "sky/engine/bindings/exception_state.h"
#include "sky/engine/core/dom/ExceptionCode.h"
#include "sky/engine/core/dom/ExecutionContext.h"
#include "sky/engine/core/dom/Microtask.h"
#include "sky/engine/core/dom/MutationCallback.h"
#include "sky/engine/core/dom/MutationObserverRegistration.h"
#include "sky/engine/core/dom/MutationRecord.h"
#include "sky/engine/core/dom/Node.h"
#include "sky/engine/wtf/MainThread.h"

namespace blink {

static unsigned s_observerPriority = 0;

struct MutationObserver::ObserverLessThan {
    bool operator()(const RefPtr<MutationObserver>& lhs, const RefPtr<MutationObserver>& rhs)
    {
        return lhs->m_priority < rhs->m_priority;
    }
};

PassRefPtr<MutationObserver> MutationObserver::create(PassOwnPtr<MutationCallback> callback)
{
    ASSERT(isMainThread());
    return adoptRef(new MutationObserver(callback));
}

MutationObserver::MutationObserver(PassOwnPtr<MutationCallback> callback)
    : m_callback(callback)
    , m_priority(s_observerPriority++)
{
}

MutationObserver::~MutationObserver()
{
#if !ENABLE(OILPAN)
    ASSERT(m_registrations.isEmpty());
#endif
}

void MutationObserver::observe(Node* node, ExceptionState& exceptionState)
{
    if (!node) {
        exceptionState.ThrowDOMException(NotFoundError, "The provided node was null.");
        return;
    }

    // FIXME(Dictionary): Provide way to specify these.
    MutationObserverOptions options = 0;
    HashSet<AtomicString> attributeFilter;
    node->registerMutationObserver(*this, options, attributeFilter);
}

MutationRecordVector MutationObserver::takeRecords()
{
    MutationRecordVector records;
    records.swap(m_records);
    return records;
}

void MutationObserver::disconnect()
{
    m_records.clear();
    MutationObserverRegistrationSet registrations(m_registrations);
    for (MutationObserverRegistrationSet::iterator iter = registrations.begin(); iter != registrations.end(); ++iter)
        (*iter)->unregister();
    ASSERT(m_registrations.isEmpty());
}

void MutationObserver::observationStarted(MutationObserverRegistration* registration)
{
    ASSERT(!m_registrations.contains(registration));
    m_registrations.add(registration);
}

void MutationObserver::observationEnded(MutationObserverRegistration* registration)
{
    ASSERT(m_registrations.contains(registration));
    m_registrations.remove(registration);
}

static MutationObserverSet& activeMutationObservers()
{
    DEFINE_STATIC_LOCAL(OwnPtr<MutationObserverSet>, activeObservers, (adoptPtr(new MutationObserverSet())));
    return *activeObservers;
}

static MutationObserverSet& suspendedMutationObservers()
{
    DEFINE_STATIC_LOCAL(OwnPtr<MutationObserverSet>, suspendedObservers, (adoptPtr(new MutationObserverSet())));
    return *suspendedObservers;
}

static void activateObserver(PassRefPtr<MutationObserver> observer)
{
    if (activeMutationObservers().isEmpty())
        Microtask::enqueueMicrotask(base::Bind(&MutationObserver::deliverMutations));

    activeMutationObservers().add(observer);
}

void MutationObserver::enqueueMutationRecord(PassRefPtr<MutationRecord> mutation)
{
    ASSERT(isMainThread());
    m_records.append(mutation);
    activateObserver(this);
}

void MutationObserver::setHasTransientRegistration()
{
    ASSERT(isMainThread());
    activateObserver(this);
}

HashSet<RawPtr<Node> > MutationObserver::getObservedNodes() const
{
    HashSet<RawPtr<Node> > observedNodes;
    for (MutationObserverRegistrationSet::const_iterator iter = m_registrations.begin(); iter != m_registrations.end(); ++iter)
        (*iter)->addRegistrationNodesToSet(observedNodes);
    return observedNodes;
}

bool MutationObserver::canDeliver()
{
    return !m_callback->executionContext()->activeDOMObjectsAreSuspended();
}

void MutationObserver::deliver()
{
    ASSERT(canDeliver());

    // Calling clearTransientRegistrations() can modify m_registrations, so it's necessary
    // to make a copy of the transient registrations before operating on them.
    Vector<RawPtr<MutationObserverRegistration>, 1> transientRegistrations;
    for (MutationObserverRegistrationSet::iterator iter = m_registrations.begin(); iter != m_registrations.end(); ++iter) {
        if ((*iter)->hasTransientRegistrations())
            transientRegistrations.append(*iter);
    }
    for (size_t i = 0; i < transientRegistrations.size(); ++i)
        transientRegistrations[i]->clearTransientRegistrations();

    if (m_records.isEmpty())
        return;

    MutationRecordVector records;
    records.swap(m_records);

    m_callback->call(records, this);
}

void MutationObserver::resumeSuspendedObservers()
{
    ASSERT(isMainThread());
    if (suspendedMutationObservers().isEmpty())
        return;

    MutationObserverVector suspended;
    copyToVector(suspendedMutationObservers(), suspended);
    for (size_t i = 0; i < suspended.size(); ++i) {
        if (suspended[i]->canDeliver()) {
            suspendedMutationObservers().remove(suspended[i]);
            activateObserver(suspended[i]);
        }
    }
}

void MutationObserver::deliverMutations()
{
    ASSERT(isMainThread());
    MutationObserverVector observers;
    copyToVector(activeMutationObservers(), observers);
    activeMutationObservers().clear();
    std::sort(observers.begin(), observers.end(), ObserverLessThan());
    for (size_t i = 0; i < observers.size(); ++i) {
        if (observers[i]->canDeliver())
            observers[i]->deliver();
        else
            suspendedMutationObservers().add(observers[i]);
    }
}

} // namespace blink
