// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef ScriptPromise_h
#define ScriptPromise_h

#include "bindings/common/AbstractScriptPromise.h"
#include "core/dom/DOMException.h"

namespace blink {

class ScriptPromise FINAL {
public:
    explicit ScriptPromise(PassRefPtr<AbstractScriptPromise> impl)
        : m_promise(impl) { }

    static ScriptPromise empty(ScriptState* state)
    {
        return ScriptPromise(state->createEmptyPromise());
    }

    static ScriptPromise rejectWithDOMException(ScriptState* state, PassRefPtrWillBeRawPtr<DOMException> exception)
    {
        return ScriptPromise(state->createRejectedPromise(exception));
    }

    static ScriptPromise rejectWithTypeError(ScriptState* state, const String& message)
    {
        return ScriptPromise(state->createPromiseRejectedWithTypeError(message));
    }

    ScriptPromise& operator=(PassRefPtr<AbstractScriptPromise> impl)
    {
        ASSERT(m_promise == nullptr);
        m_promise = impl;
        return *this;
    }

    bool operator==(const ScriptPromise& other) const
    {
        return m_promise->equals(other.m_promise);
    }

    bool operator!=(const ScriptPromise& other) const
    {
        return !operator==(other);
    }

    ScriptPromise then(PassOwnPtr<ScriptFunction> onFulfilled, PassOwnPtr<ScriptFunction> onRejected = PassOwnPtr<ScriptFunction>()) { return ScriptPromise(m_promise->then(onFulfilled, onRejected)); }

    bool isObject() const { return m_promise->isObject(); }
    bool isNull() const { return m_promise->isNull(); }
    bool isUndefinedOrNull() const { return m_promise->isUndefinedOrNull(); }
    bool isEmpty() const { return m_promise->isEmpty(); }
    void clear() { m_promise->clear(); }

    // FIXMEMULTIVM: Remove.
    v8::Handle<v8::Value> v8Value() const { return m_promise->v8Value(); }
    v8::Isolate* isolate() const { return m_promise->isolate(); }

    PassRefPtr<AbstractScriptPromise> scriptPromise() const { return m_promise; }

private:
    RefPtr<AbstractScriptPromise> m_promise;
};

} // namespace blink

#endif // ScriptPromise_h
