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

#ifndef V8CustomElementLifecycleCallbacks_h
#define V8CustomElementLifecycleCallbacks_h

#include "bindings/core/v8/ScopedPersistent.h"
#include "bindings/core/v8/ScriptState.h"
#include "core/dom/ContextLifecycleObserver.h"
#include "core/dom/custom/CustomElementLifecycleCallbacks.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/PassRefPtr.h"
#include <v8.h>

namespace blink {

class CustomElementLifecycleCallbacks;
class Element;
class ExecutionContext;
class V8PerContextData;

class V8CustomElementLifecycleCallbacks FINAL : public CustomElementLifecycleCallbacks, ContextLifecycleObserver {
public:
    static PassRefPtr<V8CustomElementLifecycleCallbacks> create(ScriptState*, v8::Handle<v8::Object> prototype, v8::Handle<v8::Function> created, v8::Handle<v8::Function> attached, v8::Handle<v8::Function> detached, v8::Handle<v8::Function> attributeChanged);

    virtual ~V8CustomElementLifecycleCallbacks();

    bool setBinding(CustomElementDefinition* owner, PassOwnPtr<CustomElementBinding>);

private:
    V8CustomElementLifecycleCallbacks(ScriptState*, v8::Handle<v8::Object> prototype, v8::Handle<v8::Function> created, v8::Handle<v8::Function> attached, v8::Handle<v8::Function> detached, v8::Handle<v8::Function> attributeChanged);

    virtual void created(Element*) OVERRIDE;
    virtual void attached(Element*) OVERRIDE;
    virtual void detached(Element*) OVERRIDE;
    virtual void attributeChanged(Element*, const AtomicString& name, const AtomicString& oldValue, const AtomicString& newValue) OVERRIDE;

    void call(const ScopedPersistent<v8::Function>& weakCallback, Element*);

    V8PerContextData* creationContextData();

    CustomElementDefinition* m_owner;
    RefPtr<ScriptState> m_scriptState;
    ScopedPersistent<v8::Object> m_prototype;
    ScopedPersistent<v8::Function> m_created;
    ScopedPersistent<v8::Function> m_attached;
    ScopedPersistent<v8::Function> m_detached;
    ScopedPersistent<v8::Function> m_attributeChanged;
};

}

#endif // V8CustomElementLifecycleCallbacks_h
