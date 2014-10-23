// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef ScriptPromisePropertyBase_h
#define ScriptPromisePropertyBase_h

#include "bindings/core/v8/ScopedPersistent.h"
#include "bindings/core/v8/ScriptPromise.h"
#include "bindings/core/v8/ScriptPromiseProperties.h"
#include "core/dom/ContextLifecycleObserver.h"
#include "wtf/OwnPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/Vector.h"
#include <v8.h>

namespace blink {

class DOMWrapperWorld;
class ExecutionContext;
class ScriptState;

class ScriptPromisePropertyBase : public GarbageCollectedFinalized<ScriptPromisePropertyBase>, public ContextLifecycleObserver {
public:
    virtual ~ScriptPromisePropertyBase();

    enum Name {
#define P(Name) Name,
        SCRIPT_PROMISE_PROPERTIES(P)
#undef P
    };

    enum State {
        Pending,
        Resolved,
        Rejected,
    };
    State state() const { return m_state; }

    ScriptPromise promise(DOMWrapperWorld&);

    virtual void trace(Visitor*) { }

protected:
    ScriptPromisePropertyBase(ExecutionContext*, Name);

    void resolveOrReject(State targetState);

    // ScriptPromiseProperty overrides these to wrap the holder,
    // rejected value and resolved value. The
    // ScriptPromisePropertyBase caller will enter the V8Context for
    // the property's execution context and the world it is
    // creating/settling promises in; the implementation should use
    // this context.
    virtual v8::Handle<v8::Object> holder(v8::Handle<v8::Object> creationContext, v8::Isolate*) = 0;
    virtual v8::Handle<v8::Value> resolvedValue(v8::Handle<v8::Object> creationContext, v8::Isolate*) = 0;
    virtual v8::Handle<v8::Value> rejectedValue(v8::Handle<v8::Object> creationContext, v8::Isolate*) = 0;

    void resetBase();

private:
    typedef Vector<OwnPtr<ScopedPersistent<v8::Object> > > WeakPersistentSet;

    void resolveOrRejectInternal(v8::Handle<v8::Promise::Resolver>);
    v8::Local<v8::Object> ensureHolderWrapper(ScriptState*);
    void clearWrappers();

    v8::Handle<v8::String> promiseName();
    v8::Handle<v8::String> resolverName();

    v8::Isolate* m_isolate;
    Name m_name;
    State m_state;

    WeakPersistentSet m_wrappers;
};

} // namespace blink

#endif // ScriptPromisePropertyBase_h
