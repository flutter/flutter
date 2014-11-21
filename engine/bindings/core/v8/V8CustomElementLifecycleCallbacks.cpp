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

#include "sky/engine/config.h"
#include "sky/engine/bindings/core/v8/V8CustomElementLifecycleCallbacks.h"

#include "bindings/core/v8/V8Element.h"
#include "sky/engine/bindings/core/v8/CustomElementBinding.h"
#include "sky/engine/bindings/core/v8/DOMDataStore.h"
#include "sky/engine/bindings/core/v8/ScriptController.h"
#include "sky/engine/bindings/core/v8/V8Binding.h"
#include "sky/engine/bindings/core/v8/V8HiddenValue.h"
#include "sky/engine/bindings/core/v8/V8PerContextData.h"
#include "sky/engine/core/dom/ExecutionContext.h"
#include "sky/engine/wtf/PassOwnPtr.h"

namespace blink {

#define CALLBACK_LIST(V)                    \
    V(created, CreatedCallback)             \
    V(attached, AttachedCallback)           \
    V(detached, DetachedCallback)           \
    V(attributeChanged, AttributeChangedCallback)

PassRefPtr<V8CustomElementLifecycleCallbacks> V8CustomElementLifecycleCallbacks::create(ScriptState* scriptState, v8::Handle<v8::Object> prototype, v8::Handle<v8::Function> created, v8::Handle<v8::Function> attached, v8::Handle<v8::Function> detached, v8::Handle<v8::Function> attributeChanged)
{
    v8::Isolate* isolate = scriptState->isolate();
    // A given object can only be used as a Custom Element prototype
    // once; see customElementIsInterfacePrototypeObject
#define SET_HIDDEN_VALUE(Value, Name) \
    ASSERT(V8HiddenValue::getHiddenValue(isolate, prototype, V8HiddenValue::customElement##Name(isolate)).IsEmpty()); \
    if (!Value.IsEmpty()) \
        V8HiddenValue::setHiddenValue(isolate, prototype, V8HiddenValue::customElement##Name(isolate), Value);

    CALLBACK_LIST(SET_HIDDEN_VALUE)
#undef SET_HIDDEN_VALUE

    return adoptRef(new V8CustomElementLifecycleCallbacks(scriptState, prototype, created, attached, detached, attributeChanged));
}

static CustomElementLifecycleCallbacks::CallbackType flagSet(v8::Handle<v8::Function> attached, v8::Handle<v8::Function> detached, v8::Handle<v8::Function> attributeChanged)
{
    // V8 Custom Elements always run created to swizzle prototypes.
    int flags = CustomElementLifecycleCallbacks::CreatedCallback;

    if (!attached.IsEmpty())
        flags |= CustomElementLifecycleCallbacks::AttachedCallback;

    if (!detached.IsEmpty())
        flags |= CustomElementLifecycleCallbacks::DetachedCallback;

    if (!attributeChanged.IsEmpty())
        flags |= CustomElementLifecycleCallbacks::AttributeChangedCallback;

    return CustomElementLifecycleCallbacks::CallbackType(flags);
}

template <typename T>
static void weakCallback(const v8::WeakCallbackData<T, ScopedPersistent<T> >& data)
{
    data.GetParameter()->clear();
}

V8CustomElementLifecycleCallbacks::V8CustomElementLifecycleCallbacks(ScriptState* scriptState, v8::Handle<v8::Object> prototype, v8::Handle<v8::Function> created, v8::Handle<v8::Function> attached, v8::Handle<v8::Function> detached, v8::Handle<v8::Function> attributeChanged)
    : CustomElementLifecycleCallbacks(flagSet(attached, detached, attributeChanged))
    , ContextLifecycleObserver(scriptState->executionContext())
    , m_owner(0)
    , m_scriptState(scriptState)
    , m_prototype(scriptState->isolate(), prototype)
    , m_created(scriptState->isolate(), created)
    , m_attached(scriptState->isolate(), attached)
    , m_detached(scriptState->isolate(), detached)
    , m_attributeChanged(scriptState->isolate(), attributeChanged)
{
    m_prototype.setWeak(&m_prototype, weakCallback<v8::Object>);

#define MAKE_WEAK(Var, _) \
    if (!m_##Var.isEmpty()) \
        m_##Var.setWeak(&m_##Var, weakCallback<v8::Function>);

    CALLBACK_LIST(MAKE_WEAK)
#undef MAKE_WEAK
}

V8PerContextData* V8CustomElementLifecycleCallbacks::creationContextData()
{
    if (!executionContext())
        return 0;

    v8::Handle<v8::Context> context = m_scriptState->context();
    if (context.IsEmpty())
        return 0;

    return V8PerContextData::from(context);
}

V8CustomElementLifecycleCallbacks::~V8CustomElementLifecycleCallbacks()
{
    if (!m_owner)
        return;

    v8::HandleScope handleScope(m_scriptState->isolate());
    if (V8PerContextData* perContextData = creationContextData())
        perContextData->clearCustomElementBinding(m_owner);
}

bool V8CustomElementLifecycleCallbacks::setBinding(CustomElementDefinition* owner, PassOwnPtr<CustomElementBinding> binding)
{
    ASSERT(!m_owner);

    V8PerContextData* perContextData = creationContextData();
    if (!perContextData)
        return false;

    m_owner = owner;

    // Bindings retrieve the prototype when needed from per-context data.
    perContextData->addCustomElementBinding(owner, binding);

    return true;
}

void V8CustomElementLifecycleCallbacks::created(Element* element)
{
    // FIXME: callbacks while paused should be queued up for execution to
    // continue then be delivered in order rather than delivered immediately.
    // Bug 329665 tracks similar behavior for other synchronous events.
    if (!executionContext() || executionContext()->activeDOMObjectsAreStopped())
        return;

    element->setCustomElementState(Element::Upgraded);

    if (m_scriptState->contextIsEmpty())
        return;
    ScriptState::Scope scope(m_scriptState.get());
    v8::Isolate* isolate = m_scriptState->isolate();
    v8::Handle<v8::Context> context = m_scriptState->context();
    v8::Handle<v8::Object> receiver = m_scriptState->world().domDataStore().get<V8Element>(element, isolate);
    if (!receiver.IsEmpty()) {
        // Swizzle the prototype of the existing wrapper. We don't need to
        // worry about non-existent wrappers; they will get the right
        // prototype when wrapped.
        v8::Handle<v8::Object> prototype = m_prototype.newLocal(isolate);
        if (prototype.IsEmpty())
            return;
        receiver->SetPrototype(prototype);
    }

    v8::Handle<v8::Function> callback = m_created.newLocal(isolate);
    if (callback.IsEmpty())
        return;

    if (receiver.IsEmpty())
        receiver = toV8(element, context->Global(), isolate).As<v8::Object>();

    ASSERT(!receiver.IsEmpty());

    v8::TryCatch exceptionCatcher;
    exceptionCatcher.SetVerbose(true);
    ScriptController::callFunction(executionContext(), callback, receiver, 0, 0, isolate);
}

void V8CustomElementLifecycleCallbacks::attached(Element* element)
{
    call(m_attached, element);
}

void V8CustomElementLifecycleCallbacks::detached(Element* element)
{
    call(m_detached, element);
}

void V8CustomElementLifecycleCallbacks::attributeChanged(Element* element, const AtomicString& name, const AtomicString& oldValue, const AtomicString& newValue)
{
    // FIXME: callbacks while paused should be queued up for execution to
    // continue then be delivered in order rather than delivered immediately.
    // Bug 329665 tracks similar behavior for other synchronous events.
    if (!executionContext() || executionContext()->activeDOMObjectsAreStopped())
        return;

    if (m_scriptState->contextIsEmpty())
        return;
    ScriptState::Scope scope(m_scriptState.get());
    v8::Isolate* isolate = m_scriptState->isolate();
    v8::Handle<v8::Context> context = m_scriptState->context();
    v8::Handle<v8::Object> receiver = toV8(element, context->Global(), isolate).As<v8::Object>();
    ASSERT(!receiver.IsEmpty());

    v8::Handle<v8::Function> callback = m_attributeChanged.newLocal(isolate);
    if (callback.IsEmpty())
        return;

    v8::Handle<v8::Value> argv[] = {
        v8String(isolate, name),
        oldValue.isNull() ? v8::Handle<v8::Value>(v8::Null(isolate)) : v8::Handle<v8::Value>(v8String(isolate, oldValue)),
        newValue.isNull() ? v8::Handle<v8::Value>(v8::Null(isolate)) : v8::Handle<v8::Value>(v8String(isolate, newValue))
    };

    v8::TryCatch exceptionCatcher;
    exceptionCatcher.SetVerbose(true);
    ScriptController::callFunction(executionContext(), callback, receiver, WTF_ARRAY_LENGTH(argv), argv, isolate);
}

void V8CustomElementLifecycleCallbacks::call(const ScopedPersistent<v8::Function>& weakCallback, Element* element)
{
    // FIXME: callbacks while paused should be queued up for execution to
    // continue then be delivered in order rather than delivered immediately.
    // Bug 329665 tracks similar behavior for other synchronous events.
    if (!executionContext() || executionContext()->activeDOMObjectsAreStopped())
        return;

    if (m_scriptState->contextIsEmpty())
        return;
    ScriptState::Scope scope(m_scriptState.get());
    v8::Isolate* isolate = m_scriptState->isolate();
    v8::Handle<v8::Context> context = m_scriptState->context();
    v8::Handle<v8::Function> callback = weakCallback.newLocal(isolate);
    if (callback.IsEmpty())
        return;

    v8::Handle<v8::Object> receiver = toV8(element, context->Global(), isolate).As<v8::Object>();
    ASSERT(!receiver.IsEmpty());

    v8::TryCatch exceptionCatcher;
    exceptionCatcher.SetVerbose(true);
    ScriptController::callFunction(executionContext(), callback, receiver, 0, 0, isolate);
}

} // namespace blink
