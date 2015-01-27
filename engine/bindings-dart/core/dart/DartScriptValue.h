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

#ifndef DartScriptValue_h
#define DartScriptValue_h

#include "bindings/common/AbstractScriptValue.h"
#include "bindings/core/dart/DartPersistentValue.h"
#include "bindings/core/dart/DartScriptState.h"
#include "bindings/core/dart/V8Converter.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"
#include "wtf/text/WTFString.h"
#include <dart_api.h>

namespace blink {

class JSONValue;
class ScriptState;

class DartScriptValue : public AbstractScriptValue {
    WTF_MAKE_NONCOPYABLE(DartScriptValue);
public:
    virtual ~DartScriptValue();

    static PassRefPtr<DartScriptValue> create(DartScriptState *scriptState, Dart_Handle value)
    {
        return adoptRef(new DartScriptValue(scriptState, value));
    }

    static PassRefPtr<DartScriptValue> create()
    {
        return adoptRef(new DartScriptValue());
    }

    ScriptState* scriptState() const
    {
        return m_scriptState.get();
    }

    bool isDart() const { return true; }

    Dart_Handle dartValue() const { return m_value.value(); }

    v8::Handle<v8::Value> v8Value() const
    {
        // FIXMEMULTIVM: Should not be converting v8 values. Major culprit is IDB.
        Dart_Handle exception = 0;
        v8::Handle<v8::Value> value = V8Converter::toV8(m_value.value(), exception);
        if (exception)
            return v8::Undefined(m_scriptState->v8ScriptState()->isolate());
        ASSERT(!value.IsEmpty());
        return value;
    }

    bool equals(AbstractScriptValue* other) const
    {
        if (!other->isDart())
            return false;

        DartScriptValue* dartOther = static_cast<DartScriptValue*>(other);
        if (isEmpty())
            return dartOther->isEmpty();
        if (dartOther->isEmpty())
            return false;
        return Dart_IdentityEquals(dartValue(), dartOther->dartValue());
    }

    bool isFunction() const
    {
        ASSERT(!isEmpty());
        return Dart_IsClosure(dartValue());
    }

    bool isNull() const
    {
        ASSERT(!isEmpty());
        return Dart_IsNull(dartValue());
    }

    bool isUndefined() const
    {
        ASSERT(!isEmpty());
        return false;
    }

    bool isObject() const
    {
        ASSERT(!isEmpty());
        return true;
    }

    bool isEmpty() const
    {
        return !dartValue();
    }

    void clear()
    {
        m_value.clear();
    }

    bool toString(String& result) const;

    PassRefPtr<JSONValue> toJSONValue(ScriptState*) const;

    PassRefPtr<AbstractScriptPromise> toPromise() const;
    PassRefPtr<AbstractScriptPromise> toRejectedPromise() const;

    IDBKey* createIDBKeyFromKeyPath(const IDBKeyPath&);
    bool canInjectIDBKey(const IDBKeyPath&);
    IDBKey* toIDBKey();
    IDBKeyRange* toIDBKeyRange();

private:
    RefPtr<DartScriptState> m_scriptState;
    DartPersistentValue m_value;

    explicit DartScriptValue()
        : m_scriptState(nullptr)
        , m_value(0)
    {
    }

    explicit DartScriptValue(DartScriptState* scriptState, Dart_Handle value)
        : m_scriptState(scriptState)
        , m_value(value)
    {
    }
};

} // namespace blink

#endif // DartScriptValue_h
