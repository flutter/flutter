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

#include "config.h"
#include "core/inspector/AsyncCallStackTracker.h"

#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8RecursionScope.h"
#include "core/dom/ExecutionContext.h"
// #include "core/dom/ExecutionContextTask.h"
#include "core/events/Event.h"
#include "core/events/EventTarget.h"
#include "wtf/text/StringBuilder.h"
#include "wtf/text/StringHash.h"
#include "v8/include/v8.h"

namespace {

static const char setTimeoutName[] = "setTimeout";
static const char setIntervalName[] = "setInterval";
static const char requestAnimationFrameName[] = "requestAnimationFrame";
static const char enqueueMutationRecordName[] = "Mutation";

}

namespace blink {

void AsyncCallStackTracker::ExecutionContextData::contextDestroyed()
{
    ASSERT(executionContext());
    OwnPtr<ExecutionContextData> self = m_tracker->m_executionContextDataMap.take(executionContext());
    ASSERT_UNUSED(self, self == this);
    ContextLifecycleObserver::contextDestroyed();
}

int AsyncCallStackTracker::ExecutionContextData::circularSequentialID()
{
    ++m_circularSequentialID;
    if (m_circularSequentialID <= 0)
        m_circularSequentialID = 1;
    return m_circularSequentialID;
}

AsyncCallStackTracker::AsyncCallStack::AsyncCallStack(const String& description, const ScriptValue& callFrames)
    : m_description(description)
    , m_callFrames(callFrames)
{
}

AsyncCallStackTracker::AsyncCallStack::~AsyncCallStack()
{
}

AsyncCallStackTracker::AsyncCallStackTracker()
    : m_maxAsyncCallStackDepth(0)
    , m_nestedAsyncCallCount(0)
{
}

void AsyncCallStackTracker::setAsyncCallStackDepth(int depth)
{
    if (depth <= 0) {
        m_maxAsyncCallStackDepth = 0;
        clear();
    } else {
        m_maxAsyncCallStackDepth = depth;
    }
}

const AsyncCallStackTracker::AsyncCallChain* AsyncCallStackTracker::currentAsyncCallChain() const
{
    if (m_currentAsyncCallChain)
        ensureMaxAsyncCallChainDepth(m_currentAsyncCallChain.get(), m_maxAsyncCallStackDepth);
    return m_currentAsyncCallChain.get();
}

void AsyncCallStackTracker::didInstallTimer(ExecutionContext* context, int timerId, bool singleShot, const ScriptValue& callFrames)
{
    ASSERT(context);
    ASSERT(isEnabled());
    if (!validateCallFrames(callFrames))
        return;
    ASSERT(timerId > 0);
    ExecutionContextData* data = createContextDataIfNeeded(context);
    data->m_timerCallChains.set(timerId, createAsyncCallChain(singleShot ? setTimeoutName : setIntervalName, callFrames));
    if (!singleShot)
        data->m_intervalTimerIds.add(timerId);
}

void AsyncCallStackTracker::didRemoveTimer(ExecutionContext* context, int timerId)
{
    ASSERT(context);
    ASSERT(isEnabled());
    if (timerId <= 0)
        return;
    ExecutionContextData* data = m_executionContextDataMap.get(context);
    if (!data)
        return;
    data->m_intervalTimerIds.remove(timerId);
    data->m_timerCallChains.remove(timerId);
}

void AsyncCallStackTracker::willFireTimer(ExecutionContext* context, int timerId)
{
    ASSERT(context);
    ASSERT(isEnabled());
    ASSERT(timerId > 0);
    ASSERT(!m_currentAsyncCallChain);
    if (ExecutionContextData* data = m_executionContextDataMap.get(context)) {
        if (data->m_intervalTimerIds.contains(timerId))
            setCurrentAsyncCallChain(context, data->m_timerCallChains.get(timerId));
        else
            setCurrentAsyncCallChain(context, data->m_timerCallChains.take(timerId));
    } else {
        setCurrentAsyncCallChain(context, nullptr);
    }
}

void AsyncCallStackTracker::didRequestAnimationFrame(ExecutionContext* context, int callbackId, const ScriptValue& callFrames)
{
    ASSERT(context);
    ASSERT(isEnabled());
    if (!validateCallFrames(callFrames))
        return;
    ASSERT(callbackId > 0);
    ExecutionContextData* data = createContextDataIfNeeded(context);
    data->m_animationFrameCallChains.set(callbackId, createAsyncCallChain(requestAnimationFrameName, callFrames));
}

void AsyncCallStackTracker::didCancelAnimationFrame(ExecutionContext* context, int callbackId)
{
    ASSERT(context);
    ASSERT(isEnabled());
    if (callbackId <= 0)
        return;
    if (ExecutionContextData* data = m_executionContextDataMap.get(context))
        data->m_animationFrameCallChains.remove(callbackId);
}

void AsyncCallStackTracker::willFireAnimationFrame(ExecutionContext* context, int callbackId)
{
    ASSERT(context);
    ASSERT(isEnabled());
    ASSERT(callbackId > 0);
    ASSERT(!m_currentAsyncCallChain);
    if (ExecutionContextData* data = m_executionContextDataMap.get(context))
        setCurrentAsyncCallChain(context, data->m_animationFrameCallChains.take(callbackId));
    else
        setCurrentAsyncCallChain(context, nullptr);
}

void AsyncCallStackTracker::didEnqueueEvent(EventTarget* eventTarget, Event* event, const ScriptValue& callFrames)
{
    ASSERT(eventTarget->executionContext());
    ASSERT(isEnabled());
    if (!validateCallFrames(callFrames))
        return;
    ExecutionContextData* data = createContextDataIfNeeded(eventTarget->executionContext());
    data->m_eventCallChains.set(event, createAsyncCallChain(event->type(), callFrames));
}

void AsyncCallStackTracker::didRemoveEvent(EventTarget* eventTarget, Event* event)
{
    ASSERT(eventTarget->executionContext());
    ASSERT(isEnabled());
    if (ExecutionContextData* data = m_executionContextDataMap.get(eventTarget->executionContext()))
        data->m_eventCallChains.remove(event);
}

void AsyncCallStackTracker::willHandleEvent(EventTarget* eventTarget, Event* event, EventListener* listener, bool useCapture)
{
    ASSERT(eventTarget->executionContext());
    ASSERT(isEnabled());
    ExecutionContext* context = eventTarget->executionContext();
    if (ExecutionContextData* data = m_executionContextDataMap.get(context))
        setCurrentAsyncCallChain(context, data->m_eventCallChains.get(event));
    else
        setCurrentAsyncCallChain(context, nullptr);
}

void AsyncCallStackTracker::didEnqueueMutationRecord(ExecutionContext* context, MutationObserver* observer, const ScriptValue& callFrames)
{
    ASSERT(context);
    ASSERT(isEnabled());
    if (!validateCallFrames(callFrames))
        return;
    ExecutionContextData* data = createContextDataIfNeeded(context);
    data->m_mutationObserverCallChains.set(observer, createAsyncCallChain(enqueueMutationRecordName, callFrames));
}

bool AsyncCallStackTracker::hasEnqueuedMutationRecord(ExecutionContext* context, MutationObserver* observer)
{
    ASSERT(context);
    ASSERT(isEnabled());
    if (ExecutionContextData* data = m_executionContextDataMap.get(context))
        return data->m_mutationObserverCallChains.contains(observer);
    return false;
}

void AsyncCallStackTracker::didClearAllMutationRecords(ExecutionContext* context, MutationObserver* observer)
{
    ASSERT(context);
    ASSERT(isEnabled());
    if (ExecutionContextData* data = m_executionContextDataMap.get(context))
        data->m_mutationObserverCallChains.remove(observer);
}

void AsyncCallStackTracker::willDeliverMutationRecords(ExecutionContext* context, MutationObserver* observer)
{
    ASSERT(context);
    ASSERT(isEnabled());
    if (ExecutionContextData* data = m_executionContextDataMap.get(context))
        setCurrentAsyncCallChain(context, data->m_mutationObserverCallChains.take(observer));
    else
        setCurrentAsyncCallChain(context, nullptr);
}

// void AsyncCallStackTracker::didPostExecutionContextTask(ExecutionContext* context, ExecutionContextTask* task, const ScriptValue& callFrames)
// {
//     ASSERT(context);
//     ASSERT(isEnabled());
//     if (!validateCallFrames(callFrames))
//         return;
//     ExecutionContextData* data = createContextDataIfNeeded(context);
//     data->m_executionContextTaskCallChains.set(task, createAsyncCallChain(task->taskNameForInstrumentation(), callFrames));
// }

// void AsyncCallStackTracker::didKillAllExecutionContextTasks(ExecutionContext* context)
// {
//     ASSERT(context);
//     ASSERT(isEnabled());
//     if (ExecutionContextData* data = m_executionContextDataMap.get(context))
//         data->m_executionContextTaskCallChains.clear();
// }

// void AsyncCallStackTracker::willPerformExecutionContextTask(ExecutionContext* context, ExecutionContextTask* task)
// {
//     ASSERT(context);
//     ASSERT(isEnabled());
//     if (ExecutionContextData* data = m_executionContextDataMap.get(context))
//         setCurrentAsyncCallChain(context, data->m_executionContextTaskCallChains.take(task));
//     else
//         setCurrentAsyncCallChain(context, nullptr);
// }

static String makeV8AsyncTaskUniqueId(const String& eventName, int id)
{
    StringBuilder builder;
    builder.append(eventName);
    builder.appendNumber(id);
    return builder.toString();
}

void AsyncCallStackTracker::didEnqueueV8AsyncTask(ExecutionContext* context, const String& eventName, int id, const ScriptValue& callFrames)
{
    ASSERT(context);
    ASSERT(isEnabled());
    if (!validateCallFrames(callFrames))
        return;
    ExecutionContextData* data = createContextDataIfNeeded(context);
    data->m_v8AsyncTaskCallChains.set(makeV8AsyncTaskUniqueId(eventName, id), createAsyncCallChain(eventName, callFrames));
}

void AsyncCallStackTracker::willHandleV8AsyncTask(ExecutionContext* context, const String& eventName, int id)
{
    ASSERT(context);
    ASSERT(isEnabled());
    if (ExecutionContextData* data = m_executionContextDataMap.get(context))
        setCurrentAsyncCallChain(context, data->m_v8AsyncTaskCallChains.take(makeV8AsyncTaskUniqueId(eventName, id)));
    else
        setCurrentAsyncCallChain(context, nullptr);
}

int AsyncCallStackTracker::traceAsyncOperationStarting(ExecutionContext* context, const String& operationName, const ScriptValue& callFrames)
{
    ASSERT(context);
    ASSERT(isEnabled());
    if (!validateCallFrames(callFrames))
        return 0;
    ExecutionContextData* data = createContextDataIfNeeded(context);
    int id = data->circularSequentialID();
    while (data->m_asyncOperationCallChains.contains(id))
        id = data->circularSequentialID();
    data->m_asyncOperationCallChains.set(id, createAsyncCallChain(operationName, callFrames));
    return id;
}

void AsyncCallStackTracker::traceAsyncOperationCompleted(ExecutionContext* context, int operationId)
{
    ASSERT(context);
    ASSERT(isEnabled());
    if (operationId <= 0)
        return;
    if (ExecutionContextData* data = m_executionContextDataMap.get(context))
        data->m_asyncOperationCallChains.remove(operationId);
}

void AsyncCallStackTracker::traceAsyncCallbackStarting(ExecutionContext* context, int operationId)
{
    ASSERT(context);
    ASSERT(isEnabled());
    if (ExecutionContextData* data = m_executionContextDataMap.get(context))
        setCurrentAsyncCallChain(context, operationId > 0 ? data->m_asyncOperationCallChains.get(operationId) : nullptr);
    else
        setCurrentAsyncCallChain(context, nullptr);
}

void AsyncCallStackTracker::didFireAsyncCall()
{
    clearCurrentAsyncCallChain();
}

PassRefPtr<AsyncCallStackTracker::AsyncCallChain> AsyncCallStackTracker::createAsyncCallChain(const String& description, const ScriptValue& callFrames)
{
    if (callFrames.isEmpty()) {
        ASSERT(m_currentAsyncCallChain);
        return m_currentAsyncCallChain; // Propogate async call stack chain.
    }
    RefPtr<AsyncCallChain> chain = adoptRef(m_currentAsyncCallChain ? new AsyncCallStackTracker::AsyncCallChain(*m_currentAsyncCallChain) : new AsyncCallStackTracker::AsyncCallChain());
    ensureMaxAsyncCallChainDepth(chain.get(), m_maxAsyncCallStackDepth - 1);
    chain->m_callStacks.prepend(adoptRef(new AsyncCallStackTracker::AsyncCallStack(description, callFrames)));
    return chain.release();
}

void AsyncCallStackTracker::setCurrentAsyncCallChain(ExecutionContext* context, PassRefPtr<AsyncCallChain> chain)
{
    if (chain && !V8RecursionScope::recursionLevel(toIsolate(context))) {
        // Current AsyncCallChain corresponds to the bottommost JS call frame.
        m_currentAsyncCallChain = chain;
        m_nestedAsyncCallCount = 1;
    } else {
        if (m_currentAsyncCallChain)
            ++m_nestedAsyncCallCount;
    }
}

void AsyncCallStackTracker::clearCurrentAsyncCallChain()
{
    if (!m_nestedAsyncCallCount)
        return;
    --m_nestedAsyncCallCount;
    if (!m_nestedAsyncCallCount)
        m_currentAsyncCallChain.clear();
}

void AsyncCallStackTracker::ensureMaxAsyncCallChainDepth(AsyncCallChain* chain, unsigned maxDepth)
{
    while (chain->m_callStacks.size() > maxDepth)
        chain->m_callStacks.removeLast();
}

bool AsyncCallStackTracker::validateCallFrames(const ScriptValue& callFrames)
{
    return !callFrames.isEmpty() || m_currentAsyncCallChain;
}

AsyncCallStackTracker::ExecutionContextData* AsyncCallStackTracker::createContextDataIfNeeded(ExecutionContext* context)
{
    ExecutionContextData* data = m_executionContextDataMap.get(context);
    if (!data) {
        data = m_executionContextDataMap.set(context, adoptPtr(new AsyncCallStackTracker::ExecutionContextData(this, context)))
            .storedValue->value.get();
    }
    return data;
}

void AsyncCallStackTracker::clear()
{
    m_currentAsyncCallChain.clear();
    m_nestedAsyncCallCount = 0;
    m_executionContextDataMap.clear();
}

} // namespace blink
