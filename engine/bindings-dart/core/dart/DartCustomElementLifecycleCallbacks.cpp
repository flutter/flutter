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
#include "bindings/core/dart/DartCustomElementLifecycleCallbacks.h"

#include "bindings/core/dart/DartCustomElementWrapper.h"
#include "bindings/core/dart/DartDOMData.h"
#include "bindings/core/dart/DartDOMWrapper.h"
#include "bindings/core/dart/DartHTMLElement.h"
#include "bindings/core/dart/DartScriptState.h"
#include "bindings/core/dart/DartUtilities.h"
#include "bindings/core/v8/V8Binding.h"
#include "core/dom/Element.h"
#include "core/dom/ExecutionContext.h"
#include "wtf/PassOwnPtr.h"


namespace blink {

PassRefPtr<DartCustomElementLifecycleCallbacks> DartCustomElementLifecycleCallbacks::create(DartScriptState* scriptState)
{
    return adoptRef(new DartCustomElementLifecycleCallbacks(scriptState));
}

static CustomElementLifecycleCallbacks::CallbackType flagSet()
{
    int flags = CustomElementLifecycleCallbacks::Created | CustomElementLifecycleCallbacks::Attached | CustomElementLifecycleCallbacks::Detached | CustomElementLifecycleCallbacks::AttributeChanged;

    return CustomElementLifecycleCallbacks::CallbackType(flags);
}

DartCustomElementLifecycleCallbacks::DartCustomElementLifecycleCallbacks(DartScriptState* scriptState)
    : CustomElementLifecycleCallbacks(flagSet())
    , m_scriptState(scriptState)
    , m_owner(0)
{
}

DartCustomElementLifecycleCallbacks::~DartCustomElementLifecycleCallbacks()
{
    if (!m_owner || !Dart_CurrentIsolate())
        return;

    DartDOMData::current()->clearCustomElementBinding(m_owner);
}


bool DartCustomElementLifecycleCallbacks::setBinding(CustomElementDefinition* owner, PassOwnPtr<DartCustomElementBinding> binding)
{
    ASSERT(!m_owner);
    m_owner = owner;

    DartDOMData::current()->addCustomElementBinding(owner, binding);
    return true;
}

void DartCustomElementLifecycleCallbacks::created(Element* element)
{
    DartIsolateScope isolateScope(m_scriptState->isolate());
    DartApiScope dartApiScope;

    element->setCustomElementState(Element::Upgraded);

    DartCustomElementWrapper<HTMLElement>::upgradeDartWrapper(reinterpret_cast<HTMLElement*>(element), 0);
}

void DartCustomElementLifecycleCallbacks::attached(Element* element)
{
    // TODO(blois): cache this method name to avoid re-creating handles.
    call("attached", element);
}

void DartCustomElementLifecycleCallbacks::detached(Element* element)
{
    // TODO(blois): cache this method name to avoid re-creating handles.
    call("detached", element);
}

void DartCustomElementLifecycleCallbacks::attributeChanged(Element* element, const AtomicString& name, const AtomicString& oldValue, const AtomicString& newValue)
{
    DartIsolateScope isolateScope(m_scriptState->isolate());
    DartApiScope dartApiScope;

    DartDOMData* domData = DartDOMData::current();

    Dart_WeakPersistentHandle wrapper = DartDOMWrapper::lookupWrapper<DartHTMLElement>(domData, reinterpret_cast<HTMLElement*>(element));
    if (!wrapper) {
        return;
    }
    Dart_Handle receiver = Dart_HandleFromWeakPersistent(wrapper);

    Dart_Handle args[3] = {
        DartUtilities::stringToDartString(name),
        oldValue.isNull() ? Dart_Null() : DartUtilities::stringToDartString(oldValue),
        newValue.isNull() ? Dart_Null() : DartUtilities::stringToDartString(newValue)
    };

    // TODO(blois): cache this method name to avoid re-creating handles.
    Dart_Handle result = Dart_Invoke(receiver, Dart_NewStringFromCString("attributeChanged"), 3, args);
    if (Dart_IsError(result)) {
        DartUtilities::reportProblem(DartUtilities::scriptExecutionContext(), result);
    }
}

void DartCustomElementLifecycleCallbacks::call(const char* methodName, Element* element)
{
    DartIsolateScope isolateScope(m_scriptState->isolate());
    DartApiScope dartApiScope;

    DartDOMData* domData = DartDOMData::current();

    Dart_WeakPersistentHandle wrapper = DartDOMWrapper::lookupWrapper<DartHTMLElement>(domData, reinterpret_cast<HTMLElement*>(element));
    if (!wrapper) {
        return;
    }
    Dart_Handle receiver = Dart_HandleFromWeakPersistent(wrapper);
    Dart_Handle result = Dart_Invoke(receiver, Dart_NewStringFromCString(methodName), 0, 0);
    if (Dart_IsError(result)) {
        DartUtilities::reportProblem(DartUtilities::scriptExecutionContext(), result);
    }
}

} // namespace blink
