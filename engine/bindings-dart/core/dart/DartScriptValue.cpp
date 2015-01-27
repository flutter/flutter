/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
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
#include "bindings/core/dart/DartScriptValue.h"

#include "bindings/core/dart/DartScriptPromise.h"
#include "bindings/core/dart/DartUtilities.h"
#include "bindings/core/dart/V8Converter.h"
#include "platform/JSONValues.h"
#include "platform/SharedBuffer.h"

namespace blink {

DartScriptValue::~DartScriptValue()
{
}

bool DartScriptValue::toString(String& result) const
{
    if (isEmpty())
        return false;

    DartIsolateScope(m_scriptState->isolate());
    DartApiScope apiScope;

    Dart_Handle exception = 0;
    DartStringAdapter string = DartUtilities::dartToString(Dart_ToString(dartValue()), exception);
    if (exception)
        return false;
    result = string;
    return true;
}

// FIXMEDART: Implement without conversion to v8.
PassRefPtr<JSONValue> DartScriptValue::toJSONValue(ScriptState* scriptState) const
{
    Dart_Handle exception = 0;
    v8::Handle<v8::Value> v8Value = V8Converter::toV8(dartValue(), exception);
    if (exception) {
        ASSERT_NOT_REACHED();
        return nullptr;
    }
    ScriptValue v8ScriptValue(m_scriptState->v8ScriptState(), v8Value);
    return v8ScriptValue.toJSONValue(scriptState);
}

PassRefPtr<AbstractScriptPromise> DartScriptValue::toPromise() const
{
    // Does Blink rely on the value not being wrapped if it is already a future?
    return DartScriptPromise::create(m_scriptState.get(), DartUtilities::newResolvedPromise(dartValue()));
}

PassRefPtr<AbstractScriptPromise> DartScriptValue::toRejectedPromise() const
{
    return DartScriptPromise::create(m_scriptState.get(), DartUtilities::newSmashedPromise(dartValue()));
}

IDBKey* DartScriptValue::createIDBKeyFromKeyPath(const IDBKeyPath& keyPath)
{
    // FIXMEDART: Implement without conversion to v8.
    Dart_Handle exception = 0;
    v8::Handle<v8::Value> v8Value = V8Converter::toV8(dartValue(), exception);
    if (exception) {
        ASSERT_NOT_REACHED();
        return nullptr;
    }
    return V8ScriptValue::create(m_scriptState->v8ScriptState(), v8Value)->createIDBKeyFromKeyPath(keyPath);
}

bool DartScriptValue::canInjectIDBKey(const IDBKeyPath& keyPath)
{
    // FIXMEDART: Implement without conversion to v8.
    Dart_Handle exception = 0;
    v8::Handle<v8::Value> v8Value = V8Converter::toV8(dartValue(), exception);
    if (exception) {
        ASSERT_NOT_REACHED();
        return false;
    }
    return V8ScriptValue::create(m_scriptState->v8ScriptState(), v8Value)->canInjectIDBKey(keyPath);
}

IDBKey* DartScriptValue::toIDBKey()
{
    // FIXMEDART: Implement without conversion to v8.
    Dart_Handle exception = 0;
    v8::Handle<v8::Value> v8Value = V8Converter::toV8(dartValue(), exception);
    if (exception) {
        ASSERT_NOT_REACHED();
        return nullptr;
    }
    return V8ScriptValue::create(m_scriptState->v8ScriptState(), v8Value)->toIDBKey();
}

IDBKeyRange* DartScriptValue::toIDBKeyRange()
{
    // FIXMEDART: Implement without conversion to v8.
    Dart_Handle exception = 0;
    v8::Handle<v8::Value> v8Value = V8Converter::toV8(dartValue(), exception);
    if (exception) {
        ASSERT_NOT_REACHED();
        return nullptr;
    }
    return V8ScriptValue::create(m_scriptState->v8ScriptState(), v8Value)->toIDBKeyRange();
}

} // namespace blink
