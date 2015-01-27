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
#include "bindings/common/ScriptValue.h"

#include "modules/indexeddb/IDBKey.h"
#include "modules/indexeddb/IDBKeyRange.h"
#include "platform/JSONValues.h"

namespace blink {

PassRefPtr<JSONValue> ScriptValue::toJSONValue(ScriptState* state) const
{
    return m_implScriptValue->toJSONValue(state);
}

ScriptPromise ScriptValue::toPromise() const
{
    return ScriptPromise(m_implScriptValue->toPromise());
}

ScriptPromise ScriptValue::toRejectedPromise() const
{
    return ScriptPromise(m_implScriptValue->toRejectedPromise());
}

IDBKey* ScriptValue::createIDBKeyFromKeyPath(const IDBKeyPath& keyPath) const
{
    return m_implScriptValue->createIDBKeyFromKeyPath(keyPath);
}

bool ScriptValue::canInjectIDBKey(const IDBKeyPath& keyPath) const
{
    return m_implScriptValue->canInjectIDBKey(keyPath);
}

IDBKey* ScriptValue::toIDBKey() const
{
    return m_implScriptValue->toIDBKey();
}

IDBKeyRange* ScriptValue::toIDBKeyRange() const
{
    return m_implScriptValue->toIDBKeyRange();
}

} // namespace blink
