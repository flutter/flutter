// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef ScriptState_h
#define ScriptState_h

#include "bindings/core/v8/ScopedPersistent.h"
#include "bindings/core/v8/V8PerContextData.h"
#include "wtf/RefCounted.h"
#include <v8.h>

namespace blink {

class LocalDOMWindow;
class DOMWrapperWorld;
class ExecutionContext;
class LocalFrame;
class ScriptValue;

// ScriptState is created when v8::Context is created.
// ScriptState is destroyed when v8::Context is garbage-collected and
// all V8 proxy objects that have references to the ScriptState are destructed.
class ScriptState : public RefCounted<ScriptState> {
    WTF_MAKE_NONCOPYABLE(ScriptState);
public:
    class Scope {
    public:
        // You need to make sure that scriptState->context() is not empty before creating a Scope.
        explicit Scope(ScriptState* scriptState)
            : m_handleScope(scriptState->isolate())
            , m_context(scriptState->context())
        {
            ASSERT(!m_context.IsEmpty());
            m_context->Enter();
        }

        ~Scope()
        {
            m_context->Exit();
        }

    private:
        v8::HandleScope m_handleScope;
        v8::Handle<v8::Context> m_context;
    };

    static PassRefPtr<ScriptState> create(v8::Handle<v8::Context>, PassRefPtr<DOMWrapperWorld>);
    virtual ~ScriptState();

    static ScriptState* current(v8::Isolate* isolate)
    {
        return from(isolate->GetCurrentContext());
    }

    static ScriptState* from(v8::Handle<v8::Context> context)
    {
        ASSERT(!context.IsEmpty());
        ScriptState* scriptState = static_cast<ScriptState*>(context->GetAlignedPointerFromEmbedderData(v8ContextPerContextDataIndex));
        // ScriptState::from() must not be called for a context that does not have
        // valid embedder data in the embedder field.
        RELEASE_ASSERT_WITH_SECURITY_IMPLICATION(scriptState);
        RELEASE_ASSERT_WITH_SECURITY_IMPLICATION(scriptState->context() == context);
        return scriptState;
    }

    static ScriptState* forMainWorld(LocalFrame*);

    v8::Isolate* isolate() const { return m_isolate; }
    DOMWrapperWorld& world() const { return *m_world; }
    LocalDOMWindow* domWindow() const;
    virtual ExecutionContext* executionContext() const;
    virtual void setExecutionContext(ExecutionContext*);

    // This can return an empty handle if the v8::Context is gone.
    v8::Handle<v8::Context> context() const { return m_context.newLocal(m_isolate); }
    bool contextIsEmpty() const { return m_context.isEmpty(); }
    void clearContext() { return m_context.clear(); }

    V8PerContextData* perContextData() const { return m_perContextData.get(); }
    void disposePerContextData() { m_perContextData = nullptr; }

    bool evalEnabled() const;
    void setEvalEnabled(bool);
    ScriptValue getFromGlobalObject(const char* name);

protected:
    ScriptState(v8::Handle<v8::Context>, PassRefPtr<DOMWrapperWorld>);

private:
    v8::Isolate* m_isolate;
    // This persistent handle is weak.
    ScopedPersistent<v8::Context> m_context;

    // This RefPtr doesn't cause a cycle because all persistent handles that DOMWrapperWorld holds are weak.
    RefPtr<DOMWrapperWorld> m_world;

    // This OwnPtr causes a cycle:
    // V8PerContextData --(Persistent)--> v8::Context --(RefPtr)--> ScriptState --(OwnPtr)--> V8PerContextData
    // So you must explicitly clear the OwnPtr by calling disposePerContextData()
    // once you no longer need V8PerContextData. Otherwise, the v8::Context will leak.
    OwnPtr<V8PerContextData> m_perContextData;
};

class ScriptStateForTesting : public ScriptState {
public:
    static PassRefPtr<ScriptStateForTesting> create(v8::Handle<v8::Context>, PassRefPtr<DOMWrapperWorld>);

    virtual ExecutionContext* executionContext() const OVERRIDE;
    virtual void setExecutionContext(ExecutionContext*) OVERRIDE;

private:
    ScriptStateForTesting(v8::Handle<v8::Context>, PassRefPtr<DOMWrapperWorld>);

    ExecutionContext* m_executionContext;
};

// ScriptStateProtectingContext keeps the context associated with the ScriptState alive.
// You need to call clear() once you no longer need the context. Otherwise, the context will leak.
class ScriptStateProtectingContext {
    WTF_MAKE_NONCOPYABLE(ScriptStateProtectingContext);
public:
    ScriptStateProtectingContext(ScriptState* scriptState)
        : m_scriptState(scriptState)
    {
        if (m_scriptState)
            m_context.set(m_scriptState->isolate(), m_scriptState->context());
    }

    ScriptState* operator->() const { return m_scriptState.get(); }
    ScriptState* get() const { return m_scriptState.get(); }
    void clear()
    {
        m_scriptState = nullptr;
        m_context.clear();
    }

private:
    RefPtr<ScriptState> m_scriptState;
    ScopedPersistent<v8::Context> m_context;
};

}

#endif // ScriptState_h
