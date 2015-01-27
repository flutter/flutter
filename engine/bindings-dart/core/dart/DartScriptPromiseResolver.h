// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef DartScriptPromiseResolver_h
#define DartScriptPromiseResolver_h

#include "bindings/common/ScriptPromiseResolver.h"
#include "bindings/common/ScriptState.h"
#include "bindings/core/dart/DartDOMException.h"
#include "bindings/core/dart/DartDOMWrapper.h"
#include "bindings/core/dart/DartScriptPromise.h"
#include "bindings/core/dart/DartUtilities.h"
#include "bindings/core/v8/V8ScriptState.h"
#include "core/dom/ActiveDOMObject.h"
#include "core/dom/ExecutionContext.h"
#include "platform/Timer.h"
#include "wtf/RefCounted.h"
#include <dart_api.h>

namespace blink {

class ScriptPromiseResolver;

class DartScriptPromiseResolver : public AbstractScriptPromiseResolver {
    WTF_MAKE_NONCOPYABLE(DartScriptPromiseResolver);

public:
    static PassOwnPtr<DartScriptPromiseResolver> create(DartScriptState* scriptState, ScriptPromiseResolver* owner)
    {
        return adoptPtr(new DartScriptPromiseResolver(scriptState, owner));
    }

    virtual ~DartScriptPromiseResolver()
    {
        // This assertion fails if:
        //  - promise() is called at least once and
        //  - this resolver is destructed before it is resolved, rejected or
        //    the associated ExecutionContext is stopped.
        ASSERT(m_state == ResolvedOrRejected || !m_isPromiseCalled);
    }

    ExecutionContext* executionContext() { return m_scriptState->executionContext(); }

#define DECLARE_RESOLUTION_METHODS(type) \
    void resolve(type); \
    void reject(type);
PROMISE_RESOLUTION_TYPES_LIST(DECLARE_RESOLUTION_METHODS);
#undef DECLARE_RESOLUTION_METHODS

    // Anything that can be passed to toV8Value can be passed to this function.
    template <typename T>
    void resolveInternal(T value)
    {
        resolveOrReject(value, Resolving);
    }

    // Anything that can be passed to toV8Value can be passed to this function.
    template <typename T>
    void rejectInternal(T value)
    {
        resolveOrReject(value, Rejecting);
    }

    void resolve() { resolve(V8UndefinedType()); }
    void reject() { reject(V8UndefinedType()); }

    ScriptState* scriptState() { return m_scriptState.get(); }

    // Note that an empty ScriptPromise will be returned after resolve or
    // reject is called.
    PassRefPtr<AbstractScriptPromise> promise()
    {
#if ENABLE(ASSERT)
        m_isPromiseCalled = true;
#endif
        ASSERT(m_completer);
        Dart_Handle future = Dart_GetField(m_completer, Dart_NewStringFromCString("future"));
        return DartScriptPromise::create(m_scriptState.get(), future);
    }

    ScriptState* scriptState() const { return m_scriptState.get(); }

    // ActiveDOMObject implementation.
    virtual void suspend();
    virtual void resume();
    virtual void stop();

    // Once this function is called this resolver stays alive while the
    // promise is pending and the associated ExecutionContext isn't stopped.
    void keepAliveWhilePending();

protected:
    // You need to call suspendIfNeeded after the construction because
    // this is an ActiveDOMObject.
    explicit DartScriptPromiseResolver(DartScriptState*, ScriptPromiseResolver*);

private:
    enum ResolutionState {
        Pending,
        Resolving,
        Rejecting,
        ResolvedOrRejected,
    };
    enum LifetimeMode {
        Default,
        KeepAliveWhilePending,
    };

    template <typename T>
    void resolveOrReject(T value, ResolutionState newState)
    {
        if (m_state != Pending || !executionContext() || executionContext()->activeDOMObjectsAreStopped())
            return;
        ASSERT(newState == Resolving || newState == Rejecting);
        m_state = newState;
        // Retain this object until it is actually resolved or rejected.
        // |deref| will be called in |clear|.
        m_owner->ref();

        DartIsolateScope scope(m_scriptState->isolate());
        DartApiScope apiScope;
        // FIXMEDART: Remove this.
        V8ScriptState::Scope v8Scope(m_scriptState->v8ScriptState());

        // FIXMEDART: Should be able to get DartDOMData from a DartScriptState instead of TLS.
        Dart_Handle v = DartValueTraits<T>::toDartValue(value, DartDOMData::current());
        m_value = Dart_NewPersistentHandle(v);
        if (!executionContext()->activeDOMObjectsAreSuspended())
            resolveOrRejectImmediately();
    }

    void resolveOrRejectImmediately();
    void onTimerFired(Timer<DartScriptPromiseResolver>*);
    void clear();

    ResolutionState m_state;
    const RefPtr<DartScriptState> m_scriptState;
    ScriptPromiseResolver* m_owner;
    LifetimeMode m_mode;
    Timer<DartScriptPromiseResolver> m_timer;

    Dart_PersistentHandle m_completer;
    Dart_PersistentHandle m_value;

#if ENABLE(ASSERT)
    // True if promise() is called.
    bool m_isPromiseCalled;
#endif
};

} // namespace blink

#endif // #ifndef DartScriptPromiseResolver_h
