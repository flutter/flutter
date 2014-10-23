/*
 * Copyright (c) 2010 Google Inc. All rights reserved.
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
#include "core/inspector/ScriptArguments.h"

#include "bindings/core/v8/ScriptValue.h"
#include "bindings/core/v8/V8Binding.h"
#include "wtf/text/StringBuilder.h"
#include <v8.h>

namespace blink {

namespace {

static const unsigned maxArrayItemsLimit = 10000;
static const unsigned maxStackDepthLimit = 32;

class V8ValueStringBuilder {
public:
    static String toString(v8::Handle<v8::Value> value, v8::Isolate* isolate)
    {
        V8ValueStringBuilder builder(isolate);
        if (!builder.append(value))
            return String();
        return builder.toString();
    }

private:
    enum {
        IgnoreNull = 1 << 0,
        IgnoreUndefined = 1 << 1,
    };

    V8ValueStringBuilder(v8::Isolate* isolate)
        : m_arrayLimit(maxArrayItemsLimit)
        , m_isolate(isolate)
    {
    }

    bool append(v8::Handle<v8::Value> value, unsigned ignoreOptions = 0)
    {
        if (value.IsEmpty())
            return true;
        if ((ignoreOptions & IgnoreNull) && value->IsNull())
            return true;
        if ((ignoreOptions & IgnoreUndefined) && value->IsUndefined())
            return true;
        if (value->IsString())
            return append(v8::Handle<v8::String>::Cast(value));
        if (value->IsStringObject())
            return append(v8::Handle<v8::StringObject>::Cast(value)->ValueOf());
        if (value->IsSymbol())
            return append(v8::Handle<v8::Symbol>::Cast(value));
        if (value->IsSymbolObject())
            return append(v8::Handle<v8::SymbolObject>::Cast(value)->ValueOf());
        if (value->IsNumberObject()) {
            m_builder.appendNumber(v8::Handle<v8::NumberObject>::Cast(value)->ValueOf());
            return true;
        }
        if (value->IsBooleanObject()) {
            m_builder.append(v8::Handle<v8::BooleanObject>::Cast(value)->ValueOf() ? "true" : "false");
            return true;
        }
        if (value->IsArray())
            return append(v8::Handle<v8::Array>::Cast(value));
        if (toDOMWindow(value, m_isolate)) {
            m_builder.append("[object Window]");
            return true;
        }
        if (value->IsObject()
            && !value->IsDate()
            && !value->IsFunction()
            && !value->IsNativeError()
            && !value->IsRegExp())
            return append(v8::Handle<v8::Object>::Cast(value)->ObjectProtoToString());
        return append(value->ToString());
    }

    bool append(v8::Handle<v8::Array> array)
    {
        if (m_visitedArrays.contains(array))
            return true;
        uint32_t length = array->Length();
        if (length > m_arrayLimit)
            return false;
        if (m_visitedArrays.size() > maxStackDepthLimit)
            return false;

        bool result = true;
        m_arrayLimit -= length;
        m_visitedArrays.append(array);
        for (uint32_t i = 0; i < length; ++i) {
            if (i)
                m_builder.append(',');
            if (!append(array->Get(i), IgnoreNull | IgnoreUndefined)) {
                result = false;
                break;
            }
        }
        m_visitedArrays.removeLast();
        return result;
    }

    bool append(v8::Handle<v8::Symbol> symbol)
    {
        m_builder.appendLiteral("Symbol(");
        bool result = append(symbol->Name(), IgnoreUndefined);
        m_builder.append(')');
        return result;
    }

    bool append(v8::Handle<v8::String> string)
    {
        if (m_tryCatch.HasCaught())
            return false;
        if (!string.IsEmpty())
            m_builder.append(toCoreString(string));
        return true;
    }

    String toString()
    {
        if (m_tryCatch.HasCaught())
            return String();
        return m_builder.toString();
    }

    uint32_t m_arrayLimit;
    v8::Isolate* m_isolate;
    StringBuilder m_builder;
    Vector<v8::Handle<v8::Array> > m_visitedArrays;
    v8::TryCatch m_tryCatch;
};

} // namespace

DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(ScriptArguments)

PassRefPtrWillBeRawPtr<ScriptArguments> ScriptArguments::create(ScriptState* scriptState, Vector<ScriptValue>& arguments)
{
    return adoptRefWillBeNoop(new ScriptArguments(scriptState, arguments));
}

ScriptArguments::ScriptArguments(ScriptState* scriptState, Vector<ScriptValue>& arguments)
    : m_scriptState(scriptState)
{
    m_arguments.swap(arguments);
}

const ScriptValue &ScriptArguments::argumentAt(size_t index) const
{
    ASSERT(m_arguments.size() > index);
    return m_arguments[index];
}

bool ScriptArguments::getFirstArgumentAsString(String& result, bool checkForNullOrUndefined)
{
    if (!argumentCount())
        return false;

    const ScriptValue& value = argumentAt(0);
    ScriptState::Scope scope(m_scriptState.get());
    if (checkForNullOrUndefined && (value.isNull() || value.isUndefined()))
        return false;

    result = V8ValueStringBuilder::toString(value.v8Value(), value.isolate());
    return true;
}

} // namespace blink
