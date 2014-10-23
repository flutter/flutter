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
#include "bindings/core/v8/V8MutationObserver.h"

#include "bindings/core/v8/ExceptionMessages.h"
#include "bindings/core/v8/ExceptionState.h"
#include "bindings/core/v8/V8Binding.h"
#include "bindings/core/v8/V8DOMWrapper.h"
#include "bindings/core/v8/V8GCController.h"
#include "bindings/core/v8/V8MutationCallback.h"
#include "core/dom/MutationObserver.h"
#include "core/dom/Node.h"

namespace blink {

void V8MutationObserver::constructorCustom(const v8::FunctionCallbackInfo<v8::Value>& info)
{
    ExceptionState exceptionState(ExceptionState::ConstructionContext, "MutationObserver", info.Holder(), info.GetIsolate());
    if (info.Length() < 1) {
        exceptionState.throwTypeError(ExceptionMessages::notEnoughArguments(1, info.Length()));
        exceptionState.throwIfNeeded();
        return;
    }

    v8::Local<v8::Value> arg = info[0];
    if (!arg->IsFunction()) {
        exceptionState.throwTypeError("Callback argument must be a function");
        exceptionState.throwIfNeeded();
        return;
    }

    v8::Handle<v8::Object> wrapper = info.Holder();

    OwnPtr<MutationCallback> callback = V8MutationCallback::create(v8::Handle<v8::Function>::Cast(arg), wrapper, ScriptState::current(info.GetIsolate()));
    RefPtrWillBeRawPtr<MutationObserver> observer = MutationObserver::create(callback.release());

    V8DOMWrapper::associateObjectWithWrapper<V8MutationObserver>(observer.release(), &wrapperTypeInfo, wrapper, info.GetIsolate());
    info.GetReturnValue().Set(wrapper);
}

void V8MutationObserver::visitDOMWrapper(ScriptWrappableBase* internalPointer, const v8::Persistent<v8::Object>& wrapper, v8::Isolate* isolate)
{
    MutationObserver* observer = fromInternalPointer(internalPointer);
    WillBeHeapHashSet<RawPtrWillBeMember<Node> > observedNodes = observer->getObservedNodes();
    for (WillBeHeapHashSet<RawPtrWillBeMember<Node> >::iterator it = observedNodes.begin(); it != observedNodes.end(); ++it) {
        v8::UniqueId id(reinterpret_cast<intptr_t>(V8GCController::opaqueRootForGC(*it, isolate)));
        isolate->SetReferenceFromGroup(id, wrapper);
    }
}

} // namespace blink
