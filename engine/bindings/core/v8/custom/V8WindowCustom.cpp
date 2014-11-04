/*
 * Copyright (C) 2009, 2011 Google Inc. All rights reserved.
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
#include "bindings/core/v8/V8Window.h"

#include "bindings/core/v8/BindingSecurity.h"
#include "bindings/core/v8/ExceptionMessages.h"
#include "bindings/core/v8/ExceptionState.h"
#include "bindings/core/v8/ScheduledAction.h"
#include "bindings/core/v8/ScriptController.h"
#include "bindings/core/v8/ScriptSourceCode.h"
#include "bindings/core/v8/SerializedScriptValue.h"
#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8EventListener.h"
#include "bindings/core/v8/V8EventListenerList.h"
#include "bindings/core/v8/V8GCForContextDispose.h"
#include "bindings/core/v8/V8HiddenValue.h"
#include "bindings/core/v8/V8Node.h"
#include "core/dom/ExceptionCode.h"
#include "core/dom/Element.h"
#include "core/dom/Node.h"
#include "core/frame/DOMTimer.h"
#include "core/frame/DOMWindowTimers.h"
#include "core/frame/FrameView.h"
#include "core/frame/LocalDOMWindow.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "core/html/HTMLDocument.h"
#include "core/inspector/ScriptCallStack.h"
#include "platform/PlatformScreen.h"
#include "wtf/ArrayBuffer.h"
#include "wtf/Assertions.h"
#include "wtf/OwnPtr.h"

namespace blink {

// FIXME: There is a lot of duplication with SetTimeoutOrInterval() in V8WorkerGlobalScopeCustom.cpp.
// We should refactor this.
static void windowSetTimeoutImpl(const v8::FunctionCallbackInfo<v8::Value>& info, bool singleShot, ExceptionState& exceptionState)
{
    int argumentCount = info.Length();

    if (argumentCount < 1)
        return;

    LocalDOMWindow* impl = V8Window::toNative(info.Holder());
    if (!impl->frame() || !impl->document()) {
        exceptionState.throwDOMException(InvalidAccessError, "No script context is available in which to execute the script.");
        return;
    }
    ScriptState* scriptState = ScriptState::current(info.GetIsolate());
    v8::Handle<v8::Value> function = info[0];
    String functionString;
    if (!function->IsFunction()) {
        if (function->IsString()) {
            functionString = toCoreString(function.As<v8::String>());
        } else {
            v8::Handle<v8::String> v8String = function->ToString();

            // Bail out if string conversion failed.
            if (v8String.IsEmpty())
                return;

            functionString = toCoreString(v8String);
        }

        // Don't allow setting timeouts to run empty functions!
        // (Bug 1009597)
        if (!functionString.length())
            return;
    }

    if (!BindingSecurity::shouldAllowAccessToFrame(info.GetIsolate(), impl->frame(), exceptionState))
        return;

    OwnPtr<ScheduledAction> action;
    if (function->IsFunction()) {
        int paramCount = argumentCount >= 2 ? argumentCount - 2 : 0;
        OwnPtr<v8::Local<v8::Value>[]> params;
        if (paramCount > 0) {
            params = adoptArrayPtr(new v8::Local<v8::Value>[paramCount]);
            for (int i = 0; i < paramCount; i++) {
                // parameters must be globalized
                params[i] = info[i+2];
            }
        }

        // params is passed to action, and released in action's destructor
        ASSERT(impl->frame());
        action = adoptPtr(new ScheduledAction(scriptState, v8::Handle<v8::Function>::Cast(function), paramCount, params.get(), info.GetIsolate()));
    } else {
        ASSERT(impl->frame());
        action = adoptPtr(new ScheduledAction(scriptState, functionString, KURL(), info.GetIsolate()));
    }

    int32_t timeout = argumentCount >= 2 ? info[1]->Int32Value() : 0;
    int timerId;
    if (singleShot)
        timerId = DOMWindowTimers::setTimeout(*impl, action.release(), timeout);
    else
        timerId = DOMWindowTimers::setInterval(*impl, action.release(), timeout);

    // Try to do the idle notification before the timeout expires to get better
    // use of any idle time. Aim for the middle of the interval for simplicity.
    if (timeout >= 0) {
        double maximumFireInterval = static_cast<double>(timeout) / 1000 / 2;
        V8GCForContextDispose::instanceTemplate().notifyIdleSooner(maximumFireInterval);
    }

    v8SetReturnValue(info, timerId);
}

void V8Window::eventAttributeGetterCustom(const v8::PropertyCallbackInfo<v8::Value>& info)
{
    LocalFrame* frame = V8Window::toNative(info.Holder())->frame();
    ExceptionState exceptionState(ExceptionState::GetterContext, "event", "Window", info.Holder(), info.GetIsolate());
    if (!BindingSecurity::shouldAllowAccessToFrame(info.GetIsolate(), frame, exceptionState)) {
        exceptionState.throwIfNeeded();
        return;
    }

    ASSERT(frame);
    // This is a fast path to retrieve info.Holder()->CreationContext().
    v8::Local<v8::Context> context = toV8Context(frame, DOMWrapperWorld::current(info.GetIsolate()));
    if (context.IsEmpty())
        return;

    v8::Handle<v8::Value> jsEvent = V8HiddenValue::getHiddenValue(info.GetIsolate(), context->Global(), V8HiddenValue::event(info.GetIsolate()));
    if (jsEvent.IsEmpty())
        return;
    v8SetReturnValue(info, jsEvent);
}

void V8Window::eventAttributeSetterCustom(v8::Local<v8::Value> value, const v8::PropertyCallbackInfo<void>& info)
{
    LocalFrame* frame = V8Window::toNative(info.Holder())->frame();
    ExceptionState exceptionState(ExceptionState::SetterContext, "event", "Window", info.Holder(), info.GetIsolate());
    if (!BindingSecurity::shouldAllowAccessToFrame(info.GetIsolate(), frame, exceptionState)) {
        exceptionState.throwIfNeeded();
        return;
    }

    ASSERT(frame);
    // This is a fast path to retrieve info.Holder()->CreationContext().
    v8::Local<v8::Context> context = toV8Context(frame, DOMWrapperWorld::current(info.GetIsolate()));
    if (context.IsEmpty())
        return;

    V8HiddenValue::setHiddenValue(info.GetIsolate(), context->Global(), V8HiddenValue::event(info.GetIsolate()), value);
}

// FIXME(fqian): returning string is cheating, and we should
// fix this by calling toString function on the receiver.
// However, V8 implements toString in JavaScript, which requires
// switching context of receiver. I consider it is dangerous.
void V8Window::toStringMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    v8::Handle<v8::Object> domWrapper = V8Window::findInstanceInPrototypeChain(info.This(), info.GetIsolate());
    if (domWrapper.IsEmpty()) {
        v8SetReturnValue(info, info.This()->ObjectProtoToString());
        return;
    }
    v8SetReturnValue(info, domWrapper->ObjectProtoToString());
}

void V8Window::namedPropertyGetterCustom(v8::Local<v8::String> name, const v8::PropertyCallbackInfo<v8::Value>& info)
{
}

void V8Window::setTimeoutMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "setTimeout", "Window", info.Holder(), info.GetIsolate());
    windowSetTimeoutImpl(info, true, exceptionState);
    exceptionState.throwIfNeeded();
}


void V8Window::setIntervalMethodCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ExecutionContext, "setInterval", "Window", info.Holder(), info.GetIsolate());
    windowSetTimeoutImpl(info, false, exceptionState);
    exceptionState.throwIfNeeded();
}

bool V8Window::namedSecurityCheckCustom(v8::Local<v8::Object> host, v8::Local<v8::Value> key, v8::AccessType type, v8::Local<v8::Value>)
{
    v8::Isolate* isolate = v8::Isolate::GetCurrent();
    v8::Handle<v8::Object> window = V8Window::findInstanceInPrototypeChain(host, isolate);
    if (window.IsEmpty())
        return false; // the frame is gone.

    LocalDOMWindow* targetWindow = V8Window::toNative(window);

    ASSERT(targetWindow);

    LocalFrame* target = targetWindow->frame();
    if (!target)
        return false;

    return BindingSecurity::shouldAllowAccessToFrame(isolate, target, DoNotReportSecurityError);
}

bool V8Window::indexedSecurityCheckCustom(v8::Local<v8::Object> host, uint32_t index, v8::AccessType type, v8::Local<v8::Value>)
{
    v8::Isolate* isolate = v8::Isolate::GetCurrent();
    v8::Handle<v8::Object> window = V8Window::findInstanceInPrototypeChain(host, isolate);
    if (window.IsEmpty())
        return false;

    LocalDOMWindow* targetWindow = V8Window::toNative(window);

    ASSERT(targetWindow);

    LocalFrame* target = targetWindow->frame();
    if (!target)
        return false;

    return BindingSecurity::shouldAllowAccessToFrame(isolate, target, DoNotReportSecurityError);
}

v8::Handle<v8::Value> toV8(LocalDOMWindow* window, v8::Handle<v8::Object> creationContext, v8::Isolate* isolate)
{
    // Notice that we explicitly ignore creationContext because the LocalDOMWindow is its own creationContext.

    if (!window)
        return v8::Null(isolate);
    // Initializes environment of a frame, and return the global object
    // of the frame.
    LocalFrame* frame = window->frame();
    if (!frame)
        return v8Undefined();

    v8::Handle<v8::Context> context = toV8Context(frame, DOMWrapperWorld::current(isolate));
    if (context.IsEmpty())
        return v8Undefined();

    v8::Handle<v8::Object> global = context->Global();
    ASSERT(!global.IsEmpty());
    return global;
}

} // namespace blink
