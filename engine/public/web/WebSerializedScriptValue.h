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

#ifndef WebSerializedScriptValue_h
#define WebSerializedScriptValue_h

#include "../platform/WebCommon.h"
#include "../platform/WebPrivatePtr.h"

namespace v8 {
class Value;
template <class T> class Handle;
}

namespace blink {

class SerializedScriptValue;
class WebString;

// FIXME: Should this class be in platform?
class WebSerializedScriptValue {
public:
    ~WebSerializedScriptValue() { reset(); }

    WebSerializedScriptValue() { }
    WebSerializedScriptValue(const WebSerializedScriptValue& d) { assign(d); }
    WebSerializedScriptValue& operator=(const WebSerializedScriptValue& d)
    {
        assign(d);
        return *this;
    }

    BLINK_EXPORT static WebSerializedScriptValue fromString(const WebString&);

    BLINK_EXPORT static WebSerializedScriptValue serialize(v8::Handle<v8::Value>);

    // Create a WebSerializedScriptValue that represents a serialization error.
    BLINK_EXPORT static WebSerializedScriptValue createInvalid();

    BLINK_EXPORT void reset();
    BLINK_EXPORT void assign(const WebSerializedScriptValue&);

    bool isNull() const { return m_private.isNull(); }

    // Returns a string representation of the WebSerializedScriptValue.
    BLINK_EXPORT WebString toString() const;

    // Convert the serialized value to a parsed v8 value.
    BLINK_EXPORT v8::Handle<v8::Value> deserialize();

#if BLINK_IMPLEMENTATION
    WebSerializedScriptValue(const WTF::PassRefPtr<SerializedScriptValue>&);
    WebSerializedScriptValue& operator=(const WTF::PassRefPtr<SerializedScriptValue>&);
    operator WTF::PassRefPtr<SerializedScriptValue>() const;
#endif

private:
    WebPrivatePtr<SerializedScriptValue> m_private;
};

} // namespace blink

#endif
