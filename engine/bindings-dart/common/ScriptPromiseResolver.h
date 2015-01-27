// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef ScriptPromiseResolver_h
#define ScriptPromiseResolver_h

#include "bindings/common/AbstractScriptPromiseResolver.h"
#include "bindings/common/ScriptPromise.h"

namespace blink {

class ScriptPromiseResolver : public ActiveDOMObject, public RefCounted<ScriptPromiseResolver> {
    WTF_MAKE_NONCOPYABLE(ScriptPromiseResolver);
public:
    static PassRefPtr<ScriptPromiseResolver> create(ScriptState* scriptState)
    {
        RefPtr<ScriptPromiseResolver> resolver = adoptRef(new ScriptPromiseResolver(scriptState));
        resolver->suspendIfNeeded();
        return resolver.release();
    }

    virtual ~ScriptPromiseResolver() { }

    // Note that an empty ScriptPromise will be returned after resolve or
    // reject is called.
    ScriptPromise promise() { return ScriptPromise(m_impl->promise()); }

    void resolve() { return m_impl->resolve(); }
    void reject() { return m_impl->reject(); }

    template <typename T>
    void resolve(T value) { return m_impl->resolve(value); }
    template <typename T>
    void reject(T error) { return m_impl->reject(error); }

    // Once this function is called this resolver stays alive while the
    // promise is pending and the associated ExecutionContext isn't stopped.
    void keepAliveWhilePending() { return m_impl->keepAliveWhilePending(); }

    ScriptState* scriptState() { return m_impl->scriptState(); }
    ScriptState* scriptState() const { return m_impl->scriptState(); }

    // ActiveDOMObject implementation.
    void suspend() { return m_impl->suspend(); }
    void resume() { return m_impl->resume(); }
    void stop() { return m_impl->stop(); }

protected:
    // You need to call suspendIfNeeded after the construction because
    // this is an ActiveDOMObject.
    ScriptPromiseResolver(ScriptState* scriptState)
        : ActiveDOMObject(scriptState->executionContext())
        , m_impl(scriptState->createPromiseResolver(this)) { }

    OwnPtr<AbstractScriptPromiseResolver> m_impl;
};

} // namespace blink

#endif // #ifndef ScriptPromiseResolver_h
