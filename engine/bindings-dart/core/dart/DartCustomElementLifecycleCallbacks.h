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

#ifndef DartCustomElementLifecycleCallbacks_h
#define DartCustomElementLifecycleCallbacks_h

#include "bindings/core/v8/DOMWrapperWorld.h"
#include "core/dom/custom/CustomElementLifecycleCallbacks.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/PassRefPtr.h"

#include <dart_api.h>

namespace blink {

class CustomElementDefinition;
class CustomElementLifecycleCallbacks;
class DartCustomElementBinding;
class DartScriptState;
class Element;
class ExecutionContext;

class DartCustomElementLifecycleCallbacks : public CustomElementLifecycleCallbacks {
public:
    static PassRefPtr<DartCustomElementLifecycleCallbacks> create(DartScriptState*);

    virtual ~DartCustomElementLifecycleCallbacks();

    bool setBinding(CustomElementDefinition* owner, PassOwnPtr<DartCustomElementBinding>);

private:
    DartCustomElementLifecycleCallbacks(DartScriptState*);

    virtual void created(Element*) OVERRIDE;
    virtual void attached(Element*) OVERRIDE;
    virtual void detached(Element*) OVERRIDE;
    virtual void attributeChanged(Element*, const AtomicString& name, const AtomicString& oldValue, const AtomicString& newValue) OVERRIDE;

    void call(const char* methodName, Element*);

    RefPtr<DartScriptState> m_scriptState;
    CustomElementDefinition* m_owner;
};

}

#endif // DartCustomElementLifecycleCallbacks_h
