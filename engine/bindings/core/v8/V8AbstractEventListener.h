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

#ifndef V8AbstractEventListener_h
#define V8AbstractEventListener_h

#include "bindings/core/v8/DOMWrapperWorld.h"
#include "bindings/core/v8/ScopedPersistent.h"
#include "core/events/EventListener.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"
#include <v8.h>

namespace blink {

class Event;

// There are two kinds of event listeners: HTML or non-HMTL. onload,
// onfocus, etc (attributes) are always HTML event handler type; Event
// listeners added by Window.addEventListener or
// EventTargetNode::addEventListener are non-HTML type.
//
// Why does this matter?
// WebKit does not allow duplicated HTML event handlers of the same type,
// but ALLOWs duplicated non-HTML event handlers.
class V8AbstractEventListener : public EventListener {
public:
    virtual ~V8AbstractEventListener();

    static const V8AbstractEventListener* cast(const EventListener* listener)
    {
        return listener->type() == JSEventListenerType
            ? static_cast<const V8AbstractEventListener*>(listener)
            : 0;
    }

    static V8AbstractEventListener* cast(EventListener* listener)
    {
        return const_cast<V8AbstractEventListener*>(cast(const_cast<const EventListener*>(listener)));
    }

    // Implementation of EventListener interface.

    virtual bool operator==(const EventListener& other) OVERRIDE { return this == &other; }

    virtual void handleEvent(ExecutionContext*, Event*) OVERRIDE;

    virtual bool isLazy() const { return false; }

    // Returns the listener object, either a function or an object.
    v8::Local<v8::Object> getListenerObject(ExecutionContext* context)
    {
        // prepareListenerObject can potentially deref this event listener
        // as it may attempt to compile a function (lazy event listener), get an error
        // and invoke onerror callback which can execute arbitrary JS code.
        // Protect this event listener to keep it alive.
        RefPtr<V8AbstractEventListener> guard(this);
        prepareListenerObject(context);
        return m_listener.newLocal(m_isolate);
    }

    v8::Local<v8::Object> getExistingListenerObject()
    {
        return m_listener.newLocal(m_isolate);
    }

    // Provides access to the underlying handle for GC. Returned
    // value is a weak handle and so not guaranteed to stay alive.
    v8::Persistent<v8::Object>& existingListenerObjectPersistentHandle()
    {
        return m_listener.getUnsafe();
    }

    bool hasExistingListenerObject()
    {
        return !m_listener.isEmpty();
    }

    void clearListenerObject()
    {
        m_listener.clear();
    }

    virtual bool belongsToTheCurrentWorld() const OVERRIDE FINAL;
    v8::Isolate* isolate() const { return m_isolate; }
    virtual DOMWrapperWorld& world() const { return scriptState()->world(); }
    ScriptState* scriptState() const
    {
        ASSERT(m_scriptState);
        return m_scriptState.get();
    }
    void setScriptState(ScriptState* scriptState) { m_scriptState = scriptState; }

protected:
    V8AbstractEventListener(bool isAttribute, ScriptState*);
    V8AbstractEventListener(bool isAttribute, v8::Isolate*);

    virtual void prepareListenerObject(ExecutionContext*) { }

    void setListenerObject(v8::Handle<v8::Object>);

    void invokeEventHandler(Event*, v8::Local<v8::Value> jsEvent);

    // Get the receiver object to use for event listener call.
    v8::Local<v8::Object> getReceiverObject(Event*);

private:
    // Implementation of EventListener function.
    virtual bool virtualisAttribute() const OVERRIDE { return m_isAttribute; }

    virtual v8::Local<v8::Value> callListenerFunction(v8::Handle<v8::Value> jsevent, Event*) = 0;

    virtual bool shouldPreventDefault(v8::Local<v8::Value> returnValue);

    static void setWeakCallback(const v8::WeakCallbackData<v8::Object, V8AbstractEventListener>&);

    ScopedPersistent<v8::Object> m_listener;

    // Indicates if this is an HTML type listener.
    bool m_isAttribute;

    // For V8LazyEventListener, m_scriptState can be 0 until V8LazyEventListener is actually used.
    // m_scriptState is set lazily because V8LazyEventListener doesn't know the associated frame
    // until the listener is actually used.
    RefPtr<ScriptState> m_scriptState;
    v8::Isolate* m_isolate;
};

} // namespace blink

#endif // V8AbstractEventListener_h
