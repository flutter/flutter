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

#include "config.h"
#include "bindings/core/dart/DartEventListener.h"

#include "bindings/core/dart/DartController.h"
#include "bindings/core/dart/DartDOMData.h"
#include "bindings/core/dart/DartEvent.h"
#include "bindings/core/dart/DartUtilities.h"
#include "core/dom/ExecutionContext.h"
#include "core/events/BeforeUnloadEvent.h"

namespace blink {

DartEventListener::DartEventListener()
    : EventListener(static_cast<EventListener::Type>(DartEventListenerType))
    , m_isolate(0)
    , m_listener(0)
{
}

DartEventListener::~DartEventListener()
{
    ASSERT(!m_listener);
}

DartEventListener* DartEventListener::createOrFetch(Dart_Handle closure)
{
    ASSERT(Dart_IsClosure(closure));
    void* peer;
    Dart_Handle ALLOW_UNUSED result = Dart_GetPeer(closure, &peer);
    ASSERT(!Dart_IsError(result));
    DartEventListener* existingListener = static_cast<DartEventListener*>(peer);
    if (existingListener)
        return existingListener;

    RefPtr<DartEventListener> listener = adoptRef(new DartEventListener());
    DartEventListener* listenerObj = listener.get();
    intptr_t peerSize = sizeof(*listenerObj);
    listener->m_isolate = Dart_CurrentIsolate();
    listener->m_listener = Dart_NewPrologueWeakPersistentHandle(closure, listenerObj, peerSize, &weakCallback);
    result = Dart_SetPeer(closure, listenerObj);
    ASSERT(!Dart_IsError(result));
    listener->ref();
    return listenerObj;
}

void DartEventListener::weakCallback(void* isolateCallbackData, Dart_WeakPersistentHandle handle, void* peer)
{
    DartEventListener* listener = static_cast<DartEventListener*>(peer);
    listener->m_listener = 0;
    listener->deref();
}

void DartEventListener::handleEvent(ExecutionContext* context, Event* event)
{
    if (!m_listener)
        return;

    // Don't reenter Dart if execution was terminated in this instance of Dart.
    // FIXME: we probably need isDartExecutionForbidden.
    if (context->isJSExecutionForbidden())
        return;

    ASSERT(event);

    DartIsolateScope scope(m_isolate);
    DartApiScope apiScope;

    // The callback function on XMLHttpRequest can clear the event listener and destroys 'this' object. Keep a local reference to it.
    // See issue 889829.
    RefPtr<DartEventListener> protect(this);
    // Keep a strong handle to the listener.
    Dart_Handle listener = Dart_HandleFromWeakPersistent(m_listener);

    // Get the Dart wrapper for the event object.
    Dart_Handle dartEvent = DartEvent::toDart(event);
    ASSERT(dartEvent);

    // FIXME: consider if DateExtension manipulations are necessary and if yes (most probably),
    // factor out common logic. For example by introducing EventProcessScope RAII to manage DateExtension.
    Dart_Handle result = callListenerFunction(context, listener, dartEvent);
    if (Dart_IsError(result)) {
        DartUtilities::reportProblem(context, result);
        return;
    }

    if (Dart_IsString(result)) {
        if (event->isBeforeUnloadEvent())
            toBeforeUnloadEvent(event)->setReturnValue(DartUtilities::toString(result));
    }
}

EventListener* DartEventListener::toNative(Dart_Handle handle, Dart_Handle& exception)
{
    if (Dart_IsNull(handle)) {
        exception = Dart_NewStringFromCString("Null passed where Dart closure is expected");
        return 0;
    }

    if (!Dart_IsClosure(handle)) {
        exception = Dart_NewStringFromCString("Not a Dart closure passed");
        return 0;
    }

    return createOrFetch(handle);
}

Dart_Handle DartEventListener::callListenerFunction(ExecutionContext* context, Dart_Handle listener, Dart_Handle dartEvent)
{
    ASSERT(listener);

    DartController* dartController = DartController::retrieve(context);
    if (!dartController)
        return Dart_NewApiError("Internal error: failed to fetch Dart controller");

    Dart_Handle parameters[1] = { dartEvent };
    return dartController->callFunction(listener, 1, parameters);
}

}
