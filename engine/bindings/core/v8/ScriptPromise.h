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

#ifndef ScriptPromise_h
#define ScriptPromise_h

#include "bindings/core/v8/ScriptFunction.h"
#include "bindings/core/v8/ScriptValue.h"
#include "bindings/core/v8/V8ThrowException.h"
#include "core/dom/ExceptionCode.h"
#include "platform/heap/Handle.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/PassRefPtr.h"
#include "wtf/text/WTFString.h"
#include <v8.h>

namespace blink {

class DOMException;
class ExceptionState;

// ScriptPromise is the class for representing Promise values in C++ world.
// ScriptPromise holds a Promise.
// So holding a ScriptPromise as a member variable in DOM object causes
// memory leaks since it has a reference from C++ to V8.
//
class ScriptPromise FINAL {
public:
    // Constructs an empty promise.
    ScriptPromise() { }

    // Constructs a ScriptPromise from |promise|.
    // If |promise| is not a Promise object, throws a v8 TypeError.
    ScriptPromise(ScriptState*, v8::Handle<v8::Value> promise);

    ScriptPromise then(v8::Handle<v8::Function> onFulfilled, v8::Handle<v8::Function> onRejected = v8::Handle<v8::Function>());

    bool isObject() const
    {
        return m_promise.isObject();
    }

    bool isNull() const
    {
        return m_promise.isNull();
    }

    bool isUndefinedOrNull() const
    {
        return m_promise.isUndefined() || m_promise.isNull();
    }

    v8::Handle<v8::Value> v8Value() const
    {
        return m_promise.v8Value();
    }

    v8::Isolate* isolate() const
    {
        return m_promise.isolate();
    }

    bool isEmpty() const
    {
        return m_promise.isEmpty();
    }

    void clear()
    {
        m_promise.clear();
    }

    bool operator==(const ScriptPromise& value) const
    {
        return m_promise == value.m_promise;
    }

    bool operator!=(const ScriptPromise& value) const
    {
        return !operator==(value);
    }

    // Constructs and returns a ScriptPromise from |value|.
    // if |value| is not a Promise object, returns a Promise object
    // resolved with |value|.
    // Returns |value| itself if it is a Promise.
    static ScriptPromise cast(ScriptState*, const ScriptValue& /*value*/);
    static ScriptPromise cast(ScriptState*, v8::Handle<v8::Value> /*value*/);

    static ScriptPromise reject(ScriptState*, const ScriptValue&);
    static ScriptPromise reject(ScriptState*, v8::Handle<v8::Value>);

    static ScriptPromise rejectWithDOMException(ScriptState*, PassRefPtrWillBeRawPtr<DOMException>);

    static v8::Local<v8::Promise> rejectRaw(v8::Isolate*, v8::Handle<v8::Value>);

    // This is a utility class intended to be used internally.
    // ScriptPromiseResolver is for general purpose.
    class InternalResolver FINAL {
    public:
        explicit InternalResolver(ScriptState*);
        v8::Local<v8::Promise> v8Promise() const;
        ScriptPromise promise() const;
        void resolve(v8::Local<v8::Value>);
        void reject(v8::Local<v8::Value>);
        void clear() { m_resolver.clear(); }

    private:
        ScriptValue m_resolver;
    };

private:
    RefPtr<ScriptState> m_scriptState;
    ScriptValue m_promise;
};

} // namespace blink


#endif // ScriptPromise_h
