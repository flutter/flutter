/*
 * Copyright (C) 2008 Apple Inc. All Rights Reserved.
 * Copyright (C) 2012 Google Inc. All Rights Reserved.
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
#include "core/dom/ExecutionContext.h"

#include "core/dom/ContextLifecycleNotifier.h"
#include "core/events/ErrorEvent.h"
#include "core/events/EventTarget.h"
#include "core/html/PublicURLManager.h"
#include "core/inspector/ScriptCallStack.h"
#include "wtf/MainThread.h"

namespace blink {

class ExecutionContext::PendingException : public NoBaseWillBeGarbageCollectedFinalized<ExecutionContext::PendingException> {
    WTF_MAKE_NONCOPYABLE(PendingException);
public:
    PendingException(const String& errorMessage, int lineNumber, int columnNumber, int scriptId, const String& sourceURL, PassRefPtrWillBeRawPtr<ScriptCallStack> callStack)
        : m_errorMessage(errorMessage)
        , m_lineNumber(lineNumber)
        , m_columnNumber(columnNumber)
        , m_scriptId(scriptId)
        , m_sourceURL(sourceURL)
        , m_callStack(callStack)
    {
    }
    void trace(Visitor* visitor)
    {
        visitor->trace(m_callStack);
    }
    String m_errorMessage;
    int m_lineNumber;
    int m_columnNumber;
    int m_scriptId;
    String m_sourceURL;
    RefPtrWillBeMember<ScriptCallStack> m_callStack;
};

ExecutionContext::ExecutionContext()
    : m_client(0)
    , m_circularSequentialID(0)
    , m_inDispatchErrorEvent(false)
    , m_activeDOMObjectsAreSuspended(false)
    , m_activeDOMObjectsAreStopped(false)
{
}

ExecutionContext::~ExecutionContext()
{
}

bool ExecutionContext::hasPendingActivity()
{
    return lifecycleNotifier().hasPendingActivity();
}

void ExecutionContext::stopActiveDOMObjects()
{
    m_activeDOMObjectsAreStopped = true;
    lifecycleNotifier().notifyStoppingActiveDOMObjects();
}

unsigned ExecutionContext::activeDOMObjectCount()
{
    return lifecycleNotifier().activeDOMObjects().size();
}

void ExecutionContext::suspendActiveDOMObjectIfNeeded(ActiveDOMObject* object)
{
    ASSERT(lifecycleNotifier().contains(object));
    // Ensure all ActiveDOMObjects are suspended also newly created ones.
    if (m_activeDOMObjectsAreSuspended)
        object->suspend();
}

bool ExecutionContext::shouldSanitizeScriptError(const String& sourceURL)
{
    return false;
}

void ExecutionContext::reportException(PassRefPtrWillBeRawPtr<ErrorEvent> event, int scriptId, PassRefPtrWillBeRawPtr<ScriptCallStack> callStack)
{
    RefPtrWillBeRawPtr<ErrorEvent> errorEvent = event;
    if (m_inDispatchErrorEvent) {
        if (!m_pendingExceptions)
            m_pendingExceptions = adoptPtrWillBeNoop(new WillBeHeapVector<OwnPtrWillBeMember<PendingException> >());
        m_pendingExceptions->append(adoptPtrWillBeNoop(new PendingException(errorEvent->messageForConsole(), errorEvent->lineno(), errorEvent->colno(), scriptId, errorEvent->filename(), callStack)));
        return;
    }

    // First report the original exception and only then all the nested ones.
    if (!dispatchErrorEvent(errorEvent) && m_client)
        m_client->logExceptionToConsole(errorEvent->messageForConsole(), scriptId, errorEvent->filename(), errorEvent->lineno(), errorEvent->colno(), callStack);

    if (!m_pendingExceptions)
        return;

    for (size_t i = 0; i < m_pendingExceptions->size(); i++) {
        PendingException* e = m_pendingExceptions->at(i).get();
        if (m_client)
            m_client->logExceptionToConsole(e->m_errorMessage, e->m_scriptId, e->m_sourceURL, e->m_lineNumber, e->m_columnNumber, e->m_callStack);
    }
    m_pendingExceptions.clear();
}

void ExecutionContext::addConsoleMessage(PassRefPtrWillBeRawPtr<ConsoleMessage> consoleMessage)
{
    if (!m_client)
        return;
    m_client->addMessage(consoleMessage);
}

bool ExecutionContext::dispatchErrorEvent(PassRefPtrWillBeRawPtr<ErrorEvent> event)
{
    if (!m_client)
        return false;
    EventTarget* target = m_client->errorEventTarget();
    if (!target)
        return false;

    RefPtrWillBeRawPtr<ErrorEvent> errorEvent = event;
    if (shouldSanitizeScriptError(errorEvent->filename()))
        errorEvent = ErrorEvent::createSanitizedError(errorEvent->world());

    ASSERT(!m_inDispatchErrorEvent);
    m_inDispatchErrorEvent = true;
    target->dispatchEvent(errorEvent);
    m_inDispatchErrorEvent = false;
    return errorEvent->defaultPrevented();
}

int ExecutionContext::circularSequentialID()
{
    ++m_circularSequentialID;
    if (m_circularSequentialID <= 0)
        m_circularSequentialID = 1;
    return m_circularSequentialID;
}

int ExecutionContext::installNewTimeout(PassOwnPtr<ScheduledAction> action, int timeout, bool singleShot)
{
    int timeoutID;
    while (true) {
        timeoutID = circularSequentialID();
        if (!m_timeouts.contains(timeoutID))
            break;
    }
    TimeoutMap::AddResult result = m_timeouts.add(timeoutID, DOMTimer::create(this, action, timeout, singleShot, timeoutID));
    ASSERT(result.isNewEntry);
    DOMTimer* timer = result.storedValue->value.get();

    timer->suspendIfNeeded();

    return timer->timeoutID();
}

void ExecutionContext::removeTimeoutByID(int timeoutID)
{
    if (timeoutID <= 0)
        return;
    m_timeouts.remove(timeoutID);
}

PublicURLManager& ExecutionContext::publicURLManager()
{
    if (!m_publicURLManager)
        m_publicURLManager = PublicURLManager::create(this);
    return *m_publicURLManager;
}

void ExecutionContext::didChangeTimerAlignmentInterval()
{
    for (TimeoutMap::iterator iter = m_timeouts.begin(); iter != m_timeouts.end(); ++iter)
        iter->value->didChangeAlignmentInterval();
}

const KURL& ExecutionContext::url() const
{
    if (!m_client) {
        DEFINE_STATIC_LOCAL(KURL, emptyURL, ());
        return emptyURL;
    }

    return virtualURL();
}

KURL ExecutionContext::completeURL(const String& url) const
{

    if (!m_client) {
        DEFINE_STATIC_LOCAL(KURL, emptyURL, ());
        return emptyURL;
    }

    return virtualCompleteURL(url);
}

LocalDOMWindow* ExecutionContext::executingWindow() const
{
    RELEASE_ASSERT(m_client);
    return m_client->executingWindow();
}

double ExecutionContext::timerAlignmentInterval() const
{
    if (!m_client)
        return DOMTimer::visiblePageAlignmentInterval();
    return m_client->timerAlignmentInterval();
}

PassOwnPtr<LifecycleNotifier<ExecutionContext> > ExecutionContext::createLifecycleNotifier()
{
    return ContextLifecycleNotifier::create(this);
}

ContextLifecycleNotifier& ExecutionContext::lifecycleNotifier()
{
    return static_cast<ContextLifecycleNotifier&>(LifecycleContext<ExecutionContext>::lifecycleNotifier());
}

bool ExecutionContext::isIteratingOverObservers() const
{
    return m_lifecycleNotifier && m_lifecycleNotifier->isIteratingOverObservers();
}

void ExecutionContext::trace(Visitor* visitor)
{
#if ENABLE(OILPAN)
    visitor->trace(m_pendingExceptions);
#endif
    WillBeHeapSupplementable<ExecutionContext>::trace(visitor);
    LifecycleContext<ExecutionContext>::trace(visitor);
}

} // namespace blink
