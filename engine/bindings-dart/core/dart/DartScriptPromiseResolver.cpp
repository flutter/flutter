// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "bindings/core/dart/DartScriptPromiseResolver.h"

#include "bindings/common/ScriptPromiseResolverIncludes.h"

namespace blink {

DartScriptPromiseResolver::DartScriptPromiseResolver(DartScriptState* scriptState, ScriptPromiseResolver* owner)
    : AbstractScriptPromiseResolver()
    , m_state(Pending)
    , m_scriptState(scriptState)
    , m_owner(owner)
    , m_mode(Default)
    , m_timer(this, &DartScriptPromiseResolver::onTimerFired)
    , m_completer()
#if ENABLE(ASSERT)
    , m_isPromiseCalled(false)
#endif
{
    Dart_Handle asyncLib = Dart_LookupLibrary(Dart_NewStringFromCString("dart:async"));
    Dart_Handle completerClass = Dart_GetType(asyncLib, Dart_NewStringFromCString("Completer"), 0, 0);
    Dart_Handle completer = Dart_New(completerClass, Dart_NewStringFromCString(""), 0, 0);
    m_completer = Dart_NewPersistentHandle(completer);

    if (executionContext()->activeDOMObjectsAreStopped())
        m_state = ResolvedOrRejected;
}

#define DEFINE_RESOLUTION_METHODS(type) \
void DartScriptPromiseResolver::resolve(type value) { resolveInternal(value); } \
void DartScriptPromiseResolver::reject(type error) { rejectInternal(error); }
PROMISE_RESOLUTION_TYPES_LIST(DEFINE_RESOLUTION_METHODS);
#undef DEFINE_RESOLUTION_METHODS

void DartScriptPromiseResolver::suspend()
{
    m_timer.stop();
}

void DartScriptPromiseResolver::resume()
{
    if (m_state == Resolving || m_state == Rejecting)
        m_timer.startOneShot(0, FROM_HERE);
}

void DartScriptPromiseResolver::stop()
{
    m_timer.stop();
    clear();
}

void DartScriptPromiseResolver::keepAliveWhilePending()
{
    if (m_state == ResolvedOrRejected || m_mode == KeepAliveWhilePending)
        return;

    // Keep |this| while the promise is Pending.
    // deref() will be called in clear().
    m_mode = KeepAliveWhilePending;
    m_owner->ref();
}

void DartScriptPromiseResolver::onTimerFired(Timer<DartScriptPromiseResolver>*)
{
    ASSERT(m_state == Resolving || m_state == Rejecting);
    DartIsolateScope scope(m_scriptState->isolate());
    DartApiScope apiScope;
    // FIXMEDART: Remove this.
    V8ScriptState::Scope v8Scope(m_scriptState->v8ScriptState());
    resolveOrRejectImmediately();
}

void DartScriptPromiseResolver::resolveOrRejectImmediately()
{
    ASSERT(!executionContext()->activeDOMObjectsAreStopped());
    ASSERT(!executionContext()->activeDOMObjectsAreSuspended());
    {
        if (m_state == Resolving) {
            Dart_Handle value = Dart_HandleFromPersistent(m_value);
            Dart_Invoke(m_completer, Dart_NewStringFromCString("complete"), 1, &value);
        } else {
            ASSERT(m_state == Rejecting);
            Dart_Handle error = Dart_HandleFromPersistent(m_value);
            Dart_Invoke(m_completer, Dart_NewStringFromCString("completeError"), 1, &error);
        }
    }
    clear();
}

void DartScriptPromiseResolver::clear()
{
    if (m_state == ResolvedOrRejected)
        return;
    ResolutionState state = m_state;
    m_state = ResolvedOrRejected;
    Dart_DeletePersistentHandle(m_completer);
    Dart_DeletePersistentHandle(m_value);

    if (m_mode == KeepAliveWhilePending) {
        // |ref| was called in |keepAliveWhilePending|.
        m_owner->deref();
    }
    // |this| may be deleted here, but it is safe to check |state| because
    // it doesn't depend on |this|. When |this| is deleted, |state| can't be
    // |Resolving| nor |Rejecting| and hence |this->deref()| can't be executed.
    if (state == Resolving || state == Rejecting) {
        // |ref| was called in |resolveOrReject|.
        m_owner->deref();
    }
}

} // namespace blink
