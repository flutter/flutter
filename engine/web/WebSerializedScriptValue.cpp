/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
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
#include "public/web/WebSerializedScriptValue.h"

#include "bindings/core/v8/ExceptionState.h"
#include "bindings/core/v8/SerializedScriptValue.h"
#include "public/platform/WebString.h"

namespace blink {

WebSerializedScriptValue WebSerializedScriptValue::fromString(const WebString& s)
{
    return SerializedScriptValue::createFromWire(s);
}

WebSerializedScriptValue WebSerializedScriptValue::serialize(v8::Handle<v8::Value> value)
{
    TrackExceptionState exceptionState;
    WebSerializedScriptValue serializedValue = SerializedScriptValue::create(value, 0, 0, exceptionState, v8::Isolate::GetCurrent());
    if (exceptionState.hadException())
        return createInvalid();
    return serializedValue;
}

WebSerializedScriptValue WebSerializedScriptValue::createInvalid()
{
    return SerializedScriptValue::create();
}

void WebSerializedScriptValue::reset()
{
    m_private.reset();
}

void WebSerializedScriptValue::assign(const WebSerializedScriptValue& other)
{
    m_private = other.m_private;
}

WebString WebSerializedScriptValue::toString() const
{
    return m_private->toWireString();
}

v8::Handle<v8::Value> WebSerializedScriptValue::deserialize()
{
    return m_private->deserialize();
}

WebSerializedScriptValue::WebSerializedScriptValue(const PassRefPtr<SerializedScriptValue>& value)
    : m_private(value)
{
}

WebSerializedScriptValue& WebSerializedScriptValue::operator=(const PassRefPtr<SerializedScriptValue>& value)
{
    m_private = value;
    return *this;
}

WebSerializedScriptValue::operator PassRefPtr<SerializedScriptValue>() const
{
    return m_private.get();
}

} // namespace blink
