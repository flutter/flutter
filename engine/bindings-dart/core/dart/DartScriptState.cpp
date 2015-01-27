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

#include "config.h"
#include "bindings/core/dart/DartScriptState.h"

#include "bindings/core/dart/DartScriptPromise.h"
#include "bindings/core/dart/DartScriptPromiseResolver.h"
#include "bindings/core/dart/DartUtilities.h"
#include "platform/SharedBuffer.h"
#include <dart_debugger_api.h>

namespace blink {

DartScriptState::DartScriptState(Dart_Isolate isolate, intptr_t libraryId, V8ScriptState* v8ScriptState)
{
    m_isolate = isolate;
    m_libraryId = libraryId;
    m_libraryUrl = DartUtilities::toString(Dart_GetLibraryURL(libraryId));
    m_v8ScriptState = v8ScriptState;
}

bool DartScriptState::contextIsEmpty() const
{
    if (m_v8ScriptState)
        return m_v8ScriptState->contextIsEmpty();
    return true;
}

PassRefPtr<AbstractScriptValue> DartScriptState::createNull()
{
    return DartScriptValue::create(this, Dart_Null());
}

PassRefPtr<AbstractScriptValue> DartScriptState::createUndefined()
{
    return DartScriptValue::create(this, Dart_Null());
}

PassRefPtr<AbstractScriptValue> DartScriptState::createBoolean(bool value)
{
    return DartScriptValue::create(this, value ? Dart_True() : Dart_False());
}

PassRefPtr<AbstractScriptPromise> DartScriptState::createEmptyPromise()
{
    return DartScriptPromise::create();
}

PassRefPtr<AbstractScriptPromise> DartScriptState::createRejectedPromise(PassRefPtrWillBeRawPtr<DOMException> domException)
{
    Dart_Handle dartException = DartDOMException::toDart(domException);
    return DartScriptPromise::create(this, DartUtilities::newSmashedPromise(dartException));
}

PassRefPtr<AbstractScriptPromise> DartScriptState::createPromiseRejectedWithTypeError(const String& message)
{
    Dart_Handle argumentError = DartUtilities::newArgumentError(message);
    return DartScriptPromise::create(this, DartUtilities::newSmashedPromise(argumentError));
}

PassOwnPtr<AbstractScriptPromiseResolver> DartScriptState::createPromiseResolver(ScriptPromiseResolver* owner)
{
    return DartScriptPromiseResolver::create(this, owner);
}

class DartScriptStateProtectingContext : public AbstractScriptStateProtectingContext {
public:
    DartScriptStateProtectingContext(DartScriptState* scriptState)
        : m_scriptState(scriptState)
    {
    }

    DartScriptState* get() const { return m_scriptState.get(); }
    void clear() { m_scriptState.clear(); }

private:
    RefPtr<DartScriptState> m_scriptState;
};

AbstractScriptStateProtectingContext* DartScriptState::createProtectingContext()
{
    return new DartScriptStateProtectingContext(this);
}

PassRefPtr<AbstractScriptValue> DartScriptState::idbAnyToScriptValue(IDBAny* any)
{
    // FIXMEDART: Implement without Dart<->V8 conversion.
    return v8ScriptState()->idbAnyToScriptValue(any);
}

PassRefPtr<AbstractScriptValue> DartScriptState::idbKeyToScriptValue(IDBKey* key)
{
    // FIXMEDART: Implement without Dart<->V8 conversion.
    return v8ScriptState()->idbKeyToScriptValue(key);
}

#ifndef NDEBUG
void DartScriptState::assertPrimaryKeyValidOrInjectable(PassRefPtr<SharedBuffer> buffer, const Vector<blink::WebBlobInfo>* blobInfo, IDBKey* key, const IDBKeyPath& keyPath)
{
    // FIXMEDART: Implement without Dart<->V8 conversion.
    return v8ScriptState()->assertPrimaryKeyValidOrInjectable(buffer, blobInfo, key, keyPath);
}
#endif

} // namespace blink
