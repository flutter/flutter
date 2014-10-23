/*
 * Copyright (C) 2006, 2007, 2008, 2009 Google Inc. All rights reserved.
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
#include "bindings/core/v8/V8AbstractEventListener.h"

#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8Event.h"
#include "bindings/core/v8/V8EventListenerList.h"
#include "bindings/core/v8/V8EventTarget.h"
#include "bindings/core/v8/V8HiddenValue.h"
#include "core/dom/Document.h"
#include "core/events/BeforeUnloadEvent.h"
#include "core/events/Event.h"
#include "core/inspector/InspectorCounters.h"

namespace blink {

V8AbstractEventListener::V8AbstractEventListener(bool isAttribute, ScriptState* scriptState)
    : EventListener(JSEventListenerType)
    , m_isAttribute(isAttribute)
    , m_scriptState(scriptState)
    , m_isolate(scriptState->isolate())
{
    if (isMainThread())
        InspectorCounters::incrementCounter(InspectorCounters::JSEventListenerCounter);
}

V8AbstractEventListener::V8AbstractEventListener(bool isAttribute, v8::Isolate* isolate)
    : EventListener(JSEventListenerType)
    , m_isAttribute(isAttribute)
    , m_scriptState(nullptr)
    , m_isolate(isolate)
{
    if (isMainThread())
        InspectorCounters::incrementCounter(InspectorCounters::JSEventListenerCounter);
}

V8AbstractEventListener::~V8AbstractEventListener()
{
    if (!m_listener.isEmpty()) {
        v8::HandleScope scope(m_isolate);
        V8EventListenerList::clearWrapper(m_listener.newLocal(isolate()), m_isAttribute, isolate());
    }
    if (isMainThread())
        InspectorCounters::decrementCounter(InspectorCounters::JSEventListenerCounter);
}

void V8AbstractEventListener::handleEvent(ExecutionContext*, Event* event)
{
    if (scriptState()->contextIsEmpty())
        return;
    if (!scriptState()->executionContext())
        return;

    ASSERT(event);

    // The callback function on XMLHttpRequest can clear the event listener and destroys 'this' object. Keep a local reference to it.
    // See issue 889829.
    RefPtr<V8AbstractEventListener> protect(this);

    ScriptState::Scope scope(scriptState());

    // Get the V8 wrapper for the event object.
    v8::Handle<v8::Value> jsEvent = toV8(event, scriptState()->context()->Global(), isolate());
    if (jsEvent.IsEmpty())
        return;
    invokeEventHandler(event, v8::Local<v8::Value>::New(isolate(), jsEvent));
}

void V8AbstractEventListener::setListenerObject(v8::Handle<v8::Object> listener)
{
    m_listener.set(isolate(), listener);
    m_listener.setWeak(this, &setWeakCallback);
}

void V8AbstractEventListener::invokeEventHandler(Event* event, v8::Local<v8::Value> jsEvent)
{
    // If jsEvent is empty, attempt to set it as a hidden value would crash v8.
    if (jsEvent.IsEmpty())
        return;

    ASSERT(!scriptState()->contextIsEmpty());
    v8::Local<v8::Value> returnValue;
    {
        // Catch exceptions thrown in the event handler so they do not propagate to javascript code that caused the event to fire.
        v8::TryCatch tryCatch;
        tryCatch.SetVerbose(true);

        // Save the old 'event' property so we can restore it later.
        v8::Local<v8::Value> savedEvent = V8HiddenValue::getHiddenValue(isolate(), scriptState()->context()->Global(), V8HiddenValue::event(isolate()));
        tryCatch.Reset();

        // Make the event available in the global object, so LocalDOMWindow can expose it.
        V8HiddenValue::setHiddenValue(isolate(), scriptState()->context()->Global(), V8HiddenValue::event(isolate()), jsEvent);
        tryCatch.Reset();

        returnValue = callListenerFunction(jsEvent, event);
        if (tryCatch.HasCaught())
            event->target()->uncaughtExceptionInEventHandler();

        if (!tryCatch.CanContinue()) // Result of TerminateExecution().
            return;
        tryCatch.Reset();

        // Restore the old event. This must be done for all exit paths through this method.
        if (savedEvent.IsEmpty())
            V8HiddenValue::setHiddenValue(isolate(), scriptState()->context()->Global(), V8HiddenValue::event(isolate()), v8::Undefined(isolate()));
        else
            V8HiddenValue::setHiddenValue(isolate(), scriptState()->context()->Global(), V8HiddenValue::event(isolate()), savedEvent);
        tryCatch.Reset();
    }

    if (returnValue.IsEmpty())
        return;

    if (m_isAttribute && !returnValue->IsNull() && !returnValue->IsUndefined() && event->isBeforeUnloadEvent()) {
        TOSTRING_VOID(V8StringResource<>, stringReturnValue, returnValue);
        toBeforeUnloadEvent(event)->setReturnValue(stringReturnValue);
    }

    if (m_isAttribute && shouldPreventDefault(returnValue))
        event->preventDefault();
}

bool V8AbstractEventListener::shouldPreventDefault(v8::Local<v8::Value> returnValue)
{
    // Prevent default action if the return value is false in accord with the spec
    // http://www.w3.org/TR/html5/webappapis.html#event-handler-attributes
    return returnValue->IsBoolean() && !returnValue->BooleanValue();
}

v8::Local<v8::Object> V8AbstractEventListener::getReceiverObject(Event* event)
{
    v8::Local<v8::Object> listener = m_listener.newLocal(isolate());
    if (!m_listener.isEmpty() && !listener->IsFunction())
        return listener;

    EventTarget* target = event->currentTarget();
    v8::Handle<v8::Value> value = toV8(target, scriptState()->context()->Global(), isolate());
    if (value.IsEmpty())
        return v8::Local<v8::Object>();
    return v8::Local<v8::Object>::New(isolate(), v8::Handle<v8::Object>::Cast(value));
}

bool V8AbstractEventListener::belongsToTheCurrentWorld() const
{
    return isolate()->InContext() && &world() == &DOMWrapperWorld::current(isolate());
}

void V8AbstractEventListener::setWeakCallback(const v8::WeakCallbackData<v8::Object, V8AbstractEventListener> &data)
{
    data.GetParameter()->m_listener.clear();
}

} // namespace blink
