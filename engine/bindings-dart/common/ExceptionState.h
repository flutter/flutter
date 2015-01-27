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

#ifndef ExceptionState_h
#define ExceptionState_h

#include "bindings/common/ScriptPromise.h"
#include "core/dom/ExceptionCode.h"
#include "wtf/Noncopyable.h"
#include "wtf/text/WTFString.h"
#include <v8.h>

namespace blink {

typedef int ExceptionCode;
class ScriptState;

class ExceptionState {
public:
    virtual void throwDOMException(const ExceptionCode&, const String& message) = 0;
    virtual void throwTypeError(const String& message) = 0;
    virtual void throwSecurityError(const String& sanitizedMessage, const String& unsanitizedMessage = String()) = 0;
    virtual void throwRangeError(const String& message) = 0;

    // FIXME: Remove use in SerializedScriptValue.
    virtual void rethrowV8Exception(v8::Handle<v8::Value> value) = 0;

    virtual void throwException() = 0;
    virtual void clearException() = 0;

    virtual ScriptPromise reject(ScriptState*) = 0;

    bool throwIfNeeded()
    {
        if (hadException()) {
            throwException();
            return true;
        }
        return false;
    }

    ExceptionCode code() const { return m_code; }
    const String& message() const { return m_message; }
    bool hadException() const { return m_hadException || m_code; }

    virtual bool isV8ExceptionState() const { return false; }

protected:
    ExceptionState() : m_code(0), m_hadException(false) { }
    void setMessage(const String& message) { m_message = message; }
    void setCode(ExceptionCode code) { m_code = code; }
    void setHadException(bool exception) { m_hadException = exception; }

private:
    ExceptionCode m_code;
    String m_message;
    bool m_hadException;
};

// Used if exceptions can/should not be directly thrown.
class NonThrowableExceptionState FINAL : public ExceptionState {
public:
    NonThrowableExceptionState() : ExceptionState() { }
    virtual void throwDOMException(const ExceptionCode& ec, const String& message) OVERRIDE {
        ASSERT_NOT_REACHED();
        setCode(ec);
        setMessage(message);
        setHadException(true);
    }
    virtual void throwTypeError(const String& message = String()) OVERRIDE {
        ASSERT_NOT_REACHED();
        setCode(V8TypeError);
        setMessage(message);
        setHadException(true);
    }
    virtual void throwSecurityError(const String& sanitizedMessage, const String& unsanitizedMessage = String()) OVERRIDE{
        ASSERT_NOT_REACHED();
        setCode(SecurityError);
        setMessage(sanitizedMessage);
        setHadException(true);
    }
    virtual void throwRangeError(const String& message = String()) OVERRIDE {
        ASSERT_NOT_REACHED();
        setCode(V8RangeError);
        setMessage(message);
        setHadException(true);
    }
    virtual void rethrowV8Exception(v8::Handle<v8::Value> value) OVERRIDE {
        ASSERT_NOT_REACHED();
        setHadException(true);
    }
    virtual void throwException() OVERRIDE FINAL {
        ASSERT_NOT_REACHED();
    }
    virtual void clearException() OVERRIDE FINAL {
        ASSERT_NOT_REACHED();
        setCode(0);
        setHadException(false);
    }
    virtual ScriptPromise reject(ScriptState* state) OVERRIDE FINAL {
        ASSERT_NOT_REACHED();
        return ScriptPromise::empty(state);
    }
};

// Used if any exceptions thrown are ignorable.
class TrackExceptionState FINAL : public ExceptionState {
public:
    TrackExceptionState() : ExceptionState() { }
    virtual void throwDOMException(const ExceptionCode& ec, const String& message) OVERRIDE {
        setCode(ec);
        setMessage(message);
        setHadException(true);
    }
    virtual void throwTypeError(const String& message = String()) OVERRIDE {
        setCode(V8TypeError);
        setMessage(message);
        setHadException(true);
    }
    virtual void throwSecurityError(const String& sanitizedMessage, const String& unsanitizedMessage = String()) OVERRIDE {
        setCode(SecurityError);
        setMessage(sanitizedMessage);
        setHadException(true);
    }
    virtual void throwRangeError(const String& message = String()) OVERRIDE {
        setCode(V8RangeError);
        setMessage(message);
        setHadException(true);
    }
    virtual void rethrowV8Exception(v8::Handle<v8::Value> value) OVERRIDE {
        setHadException(true);
    }
    virtual void throwException() OVERRIDE FINAL {
        ASSERT_NOT_REACHED();
    }
    virtual void clearException() OVERRIDE FINAL {
        setCode(0);
        setHadException(false);
    }
    virtual ScriptPromise reject(ScriptState* state) OVERRIDE FINAL {
        ASSERT_NOT_REACHED();
        return ScriptPromise::empty(state);
    }
};

} // namespace blink

#endif // ExceptionState_h
