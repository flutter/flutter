/*
 * Copyright (C) 2008, 2009 Google Inc. All rights reserved.
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

#ifndef ScriptValue_h
#define ScriptValue_h

#include "bindings/common/AbstractScriptValue.h"
// FIXMEDART: Move this file to bindings/core/dart.
#include "bindings/core/dart/DartScriptValue.h"
#include "bindings/core/v8/SharedPersistent.h"
#include "bindings/core/v8/V8ScriptValue.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"
#include "wtf/text/WTFString.h"
#include <v8.h>

namespace blink {

class JSONValue;
class ScriptPromise;
class ScriptState;
class V8ScriptState;

// Indirection to avoid re-writing the parts of Blink that pass ScriptValue by
// value.
// FIXME: Should change pass by value uses to pass by reference and use
// AbstractScriptValue directly.
class ScriptValue FINAL {
public:
    ScriptValue()
        : m_implScriptValue(V8ScriptValue::create())
    {
    }

    ScriptValue(V8ScriptState* scriptState, v8::Handle<v8::Value> value)
        : m_implScriptValue(V8ScriptValue::create(scriptState, value))
    {
    }

    ScriptValue(const ScriptValue& value)
        : m_implScriptValue(value.m_implScriptValue)
    {
    }

    ScriptValue(PassRefPtr<AbstractScriptValue> value)
        : m_implScriptValue(value)
    {
    }

    ScriptState* scriptState() const
    {
        return m_implScriptValue->scriptState();
    }

    v8::Isolate* isolate() const
    {
        ASSERT(m_implScriptValue->isV8());
        return static_cast<V8ScriptValue*>(m_implScriptValue.get())->isolate();
    }

    // FIXMEMULTIVM: Remove.
    v8::Handle<v8::Value> v8Value() const
    {
        if (m_implScriptValue->isV8()) {
            return static_cast<V8ScriptValue*>(m_implScriptValue.get())->v8Value();
        }
        if (m_implScriptValue->isDart()) {
            return static_cast<DartScriptValue*>(m_implScriptValue.get())->v8Value();
        }
        ASSERT_NOT_REACHED();
        return v8::Handle<v8::Value>();
    }

    v8::Handle<v8::Value> v8ValueUnsafe() const
    {
        ASSERT(m_implScriptValue->isV8());
        return static_cast<V8ScriptValue*>(m_implScriptValue.get())->v8ValueUnsafe();
    }

    ScriptValue& operator=(const ScriptValue& value)
    {
        if (this != &value) {
            m_implScriptValue = value.m_implScriptValue;
        }
        return *this;
    }

    bool operator==(const ScriptValue& value) const
    {
        return m_implScriptValue->equals(value.m_implScriptValue.get());
    }

    bool operator!=(const ScriptValue& value) const
    {
        return !operator==(value);
    }

    // This creates a new local Handle; Don't use this in performance-sensitive places.
    bool isFunction() const
    {
        return m_implScriptValue->isFunction();
    }

    // This creates a new local Handle; Don't use this in performance-sensitive places.
    bool isNull() const
    {
        return m_implScriptValue->isNull();
    }

    // This creates a new local Handle; Don't use this in performance-sensitive places.
    bool isUndefined() const
    {
        return m_implScriptValue->isUndefined();
    }

    // This creates a new local Handle; Don't use this in performance-sensitive places.
    bool isObject() const
    {
        return m_implScriptValue->isObject();
    }

    bool isEmpty() const
    {
        return m_implScriptValue->isEmpty();
    }

    void clear()
    {
        return m_implScriptValue->clear();
    }

    bool toString(String& result) const
    {
        return m_implScriptValue->toString(result);
    }

    PassRefPtr<JSONValue> toJSONValue(ScriptState*) const;
    ScriptPromise toPromise() const;
    ScriptPromise toRejectedPromise() const;

    // FIXMEDART: Do we need this? If so, move to multivm.
    AbstractScriptValue* scriptValue() const
    {
        return m_implScriptValue.get();
    }

    IDBKey* createIDBKeyFromKeyPath(const IDBKeyPath&) const;
    bool canInjectIDBKey(const IDBKeyPath&) const;
    IDBKey* toIDBKey() const;
    IDBKeyRange* toIDBKeyRange() const;

private:
    RefPtr<AbstractScriptValue> m_implScriptValue;
};

} // namespace blink

#endif // ScriptValue_h
