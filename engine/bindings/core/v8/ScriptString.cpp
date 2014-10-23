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
#include "bindings/core/v8/ScriptString.h"

#include "bindings/core/v8/V8Binding.h"

namespace blink {

ScriptString::ScriptString()
    : m_isolate(0)
{
}

ScriptString::ScriptString(v8::Isolate* isolate, v8::Handle<v8::String> string)
    : m_isolate(isolate)
    , m_string(SharedPersistent<v8::String>::create(string, m_isolate))
{
}

ScriptString& ScriptString::operator=(const ScriptString& string)
{
    if (this != &string) {
        m_isolate = string.m_isolate;
        m_string = string.m_string;
    }
    return *this;
}

v8::Handle<v8::String> ScriptString::v8Value()
{
    if (isEmpty())
        return v8::Handle<v8::String>();
    return m_string->newLocal(isolate());
}

ScriptString ScriptString::concatenateWith(const String& string)
{
    v8::Isolate* nonNullIsolate = isolate();
    v8::HandleScope handleScope(nonNullIsolate);
    v8::Handle<v8::String> targetString = v8String(nonNullIsolate, string);
    if (isEmpty())
        return ScriptString(nonNullIsolate, targetString);
    return ScriptString(nonNullIsolate, v8::String::Concat(v8Value(), targetString));
}

String ScriptString::flattenToString()
{
    if (isEmpty())
        return String();
    v8::HandleScope handleScope(isolate());
    return v8StringToWebCoreString<String>(v8Value(), Externalize);
}

} // namespace blink
