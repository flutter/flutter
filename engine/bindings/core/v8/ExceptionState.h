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

#ifndef ExceptionState_h
#define ExceptionState_h

#include "bindings/core/v8/ScopedPersistent.h"
#include "bindings/core/v8/ScriptPromise.h"
#include "bindings/core/v8/V8ThrowException.h"
#include "wtf/Noncopyable.h"
#include "wtf/text/WTFString.h"
#include <v8.h>

namespace blink {

typedef int ExceptionCode;
class ScriptState;

class ExceptionState {
    WTF_MAKE_NONCOPYABLE(ExceptionState);
public:
    enum Context {
        ConstructionContext,
        ExecutionContext,
        DeletionContext,
        GetterContext,
        SetterContext,
        EnumerationContext,
        QueryContext,
        IndexedGetterContext,
        IndexedSetterContext,
        IndexedDeletionContext,
        UnknownContext, // FIXME: Remove this once we've flipped over to the new API.
    };

    ExceptionState(Context context, const char* propertyName, const char* interfaceName, const v8::Handle<v8::Object>& creationContext, v8::Isolate* isolate)
        : m_code(0)
        , m_context(context)
        , m_propertyName(propertyName)
        , m_interfaceName(interfaceName)
        , m_creationContext(creationContext)
        , m_isolate(isolate) { }

    ExceptionState(Context context, const char* interfaceName, const v8::Handle<v8::Object>& creationContext, v8::Isolate* isolate)
        : m_code(0)
        , m_context(context)
        , m_propertyName(0)
        , m_interfaceName(interfaceName)
        , m_creationContext(creationContext)
        , m_isolate(isolate) { ASSERT(m_context == ConstructionContext || m_context == EnumerationContext || m_context == IndexedSetterContext || m_context == IndexedGetterContext || m_context == IndexedDeletionContext); }

    virtual void throwDOMException(const ExceptionCode&, const String& message);
    virtual void throwTypeError(const String& message);
    virtual void throwSecurityError(const String& sanitizedMessage, const String& unsanitizedMessage = String());
    virtual void throwRangeError(const String& message);

    bool hadException() const { return !m_exception.isEmpty() || m_code; }
    void clearException();

    ExceptionCode code() const { return m_code; }
    const String& message() const { return m_message; }

    bool throwIfNeeded()
    {
        if (!hadException())
            return false;
        throwException();
        return true;
    }

    // This method clears out the exception which |this| has.
    ScriptPromise reject(ScriptState*);

    Context context() const { return m_context; }
    const char* propertyName() const { return m_propertyName; }
    const char* interfaceName() const { return m_interfaceName; }

    void rethrowV8Exception(v8::Handle<v8::Value> value)
    {
        setException(value);
    }

protected:
    ExceptionCode m_code;
    Context m_context;
    String m_message;
    const char* m_propertyName;
    const char* m_interfaceName;

private:
    void setException(v8::Handle<v8::Value>);
    void throwException();

    String addExceptionContext(const String&) const;

    ScopedPersistent<v8::Value> m_exception;
    v8::Handle<v8::Object> m_creationContext;
    v8::Isolate* m_isolate;
};

// Used if exceptions can/should not be directly thrown.
class NonThrowableExceptionState final : public ExceptionState {
public:
    NonThrowableExceptionState(): ExceptionState(ExceptionState::UnknownContext, 0, 0, v8::Handle<v8::Object>(), v8::Isolate::GetCurrent()) { }
    virtual void throwDOMException(const ExceptionCode&, const String& message) override;
    virtual void throwTypeError(const String& message = String()) override;
    virtual void throwSecurityError(const String& sanitizedMessage, const String& unsanitizedMessage = String()) override;
    virtual void throwRangeError(const String& message) override;
};

// Used if any exceptions thrown are ignorable.
class TrackExceptionState final : public ExceptionState {
public:
    TrackExceptionState(): ExceptionState(ExceptionState::UnknownContext, 0, 0, v8::Handle<v8::Object>(), v8::Isolate::GetCurrent()) { }
    virtual void throwDOMException(const ExceptionCode&, const String& message) override;
    virtual void throwTypeError(const String& message = String()) override;
    virtual void throwSecurityError(const String& sanitizedMessage, const String& unsanitizedMessage = String()) override;
    virtual void throwRangeError(const String& message) override;
};

} // namespace blink

#endif // ExceptionState_h
