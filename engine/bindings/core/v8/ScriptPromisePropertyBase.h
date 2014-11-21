// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_BINDINGS_CORE_V8_SCRIPTPROMISEPROPERTYBASE_H_
#define SKY_ENGINE_BINDINGS_CORE_V8_SCRIPTPROMISEPROPERTYBASE_H_

#include "sky/engine/bindings/core/v8/ScopedPersistent.h"
#include "sky/engine/bindings/core/v8/ScriptPromise.h"
#include "sky/engine/bindings/core/v8/ScriptPromiseProperties.h"
#include "sky/engine/core/dom/ContextLifecycleObserver.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/Vector.h"
#include "v8/include/v8.h"

namespace blink {

class DOMWrapperWorld;
class ExecutionContext;
class ScriptState;

class ScriptPromisePropertyBase : public ContextLifecycleObserver {
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

#endif  // SKY_ENGINE_BINDINGS_CORE_V8_SCRIPTPROMISEPROPERTYBASE_H_
