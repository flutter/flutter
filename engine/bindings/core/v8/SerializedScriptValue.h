/*
 * Copyright (C) 2009, 2010 Google Inc. All rights reserved.
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

#ifndef SerializedScriptValue_h
#define SerializedScriptValue_h

#include "bindings/core/v8/ScriptValue.h"
#include "wtf/HashMap.h"
#include "wtf/ThreadSafeRefCounted.h"
#include <v8.h>

namespace WTF {

class ArrayBuffer;
class ArrayBufferContents;

}

namespace blink {

class ExceptionState;
class MessagePort;

typedef WillBeHeapVector<RefPtrWillBeMember<MessagePort>, 1> MessagePortArray;
typedef Vector<RefPtr<WTF::ArrayBuffer>, 1> ArrayBufferArray;

class SerializedScriptValue FINAL : public ThreadSafeRefCounted<SerializedScriptValue> {
public:
    // Increment this for each incompatible change to the wire format.
    // Version 2: Added StringUCharTag for UChar v8 strings.
    // Version 3: Switched to using uuids as blob data identifiers.
    // Version 4: Extended File serialization to be complete.
    // Version 5: Added CryptoKeyTag for Key objects.
    // Version 6: Added indexed serialization for File, Blob, and FileList.
    // Version 7: Extended File serialization with user visibility.
    static const uint32_t wireFormatVersion = 7;

    ~SerializedScriptValue();

    // If a serialization error occurs (e.g., cyclic input value) this
    // function returns an empty representation, schedules a V8 exception to
    // be thrown using v8::ThrowException(), and sets |didThrow|. In this case
    // the caller must not invoke any V8 operations until control returns to
    // V8. When serialization is successful, |didThrow| is false.
    static PassRefPtr<SerializedScriptValue> create(v8::Handle<v8::Value>, MessagePortArray*, ArrayBufferArray*, ExceptionState&, v8::Isolate*);
    static PassRefPtr<SerializedScriptValue> createFromWire(const String&);
    static PassRefPtr<SerializedScriptValue> createFromWireBytes(const Vector<uint8_t>&);
    static PassRefPtr<SerializedScriptValue> create(const String&);
    static PassRefPtr<SerializedScriptValue> create(const String&, v8::Isolate*);
    static PassRefPtr<SerializedScriptValue> create();
    static PassRefPtr<SerializedScriptValue> create(const ScriptValue&, ExceptionState&, v8::Isolate*);

    // Never throws exceptions.
    static PassRefPtr<SerializedScriptValue> createAndSwallowExceptions(v8::Handle<v8::Value>, v8::Isolate*);

    static PassRefPtr<SerializedScriptValue> nullValue();

    String toWireString() const { return m_data; }
    void toWireBytes(Vector<char>&) const;

    // Deserializes the value (in the current context). Returns a null value in
    // case of failure.
    v8::Handle<v8::Value> deserialize(MessagePortArray* = 0);
    v8::Handle<v8::Value> deserialize(v8::Isolate*, MessagePortArray* = 0);

    // Helper function which pulls the values out of a JS sequence and into a MessagePortArray.
    // Also validates the elements per sections 4.1.13 and 4.1.15 of the WebIDL spec and section 8.3.3
    // of the HTML5 spec and generates exceptions as appropriate.
    // Returns true if the array was filled, or false if the passed value was not of an appropriate type.
    static bool extractTransferables(v8::Local<v8::Value>, int, MessagePortArray&, ArrayBufferArray&, ExceptionState&, v8::Isolate*);

    // Informs the V8 about external memory allocated and owned by this object. Large values should contribute
    // to GC counters to eventually trigger a GC, otherwise flood of postMessage() can cause OOM.
    // Ok to invoke multiple times (only adds memory once).
    // The memory registration is revoked automatically in destructor.
    void registerMemoryAllocatedWithCurrentScriptContext();

private:
    enum StringDataMode {
        StringValue,
        WireData
    };
    typedef Vector<WTF::ArrayBufferContents, 1> ArrayBufferContentsArray;

    SerializedScriptValue();
    SerializedScriptValue(v8::Handle<v8::Value>, MessagePortArray*, ArrayBufferArray*, ExceptionState&, v8::Isolate*);
    explicit SerializedScriptValue(const String& wireData);

    static PassOwnPtr<ArrayBufferContentsArray> transferArrayBuffers(ArrayBufferArray&, ExceptionState&, v8::Isolate*);

    String m_data;
    OwnPtr<ArrayBufferContentsArray> m_arrayBufferContentsArray;
    intptr_t m_externallyAllocatedMemory;
};

} // namespace blink

#endif // SerializedScriptValue_h
