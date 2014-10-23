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
#include "bindings/core/v8/ExceptionState.h"

#include "bindings/core/v8/ExceptionMessages.h"
#include "bindings/core/v8/V8ThrowException.h"
#include "core/dom/ExceptionCode.h"

namespace blink {

void ExceptionState::clearException()
{
    m_code = 0;
    m_exception.clear();
}

ScriptPromise ExceptionState::reject(ScriptState* scriptState)
{
    ScriptPromise promise = ScriptPromise::reject(scriptState, m_exception.newLocal(scriptState->isolate()));
    clearException();
    return promise;
}

void ExceptionState::throwDOMException(const ExceptionCode& ec, const String& message)
{
    ASSERT(ec);
    ASSERT(m_isolate);
    ASSERT(!m_creationContext.IsEmpty());

    // SecurityError is thrown via ::throwSecurityError, and _careful_ consideration must be given to the data exposed to JavaScript via the 'sanitizedMessage'.
    ASSERT(ec != SecurityError);

    m_code = ec;
    String processedMessage = addExceptionContext(message);
    m_message = processedMessage;
    setException(V8ThrowException::createDOMException(ec, processedMessage, m_creationContext, m_isolate));
}

void ExceptionState::throwSecurityError(const String& sanitizedMessage, const String& unsanitizedMessage)
{
    ASSERT(m_isolate);
    ASSERT(!m_creationContext.IsEmpty());
    m_code = SecurityError;
    String finalSanitized = addExceptionContext(sanitizedMessage);
    m_message = finalSanitized;
    String finalUnsanitized = addExceptionContext(unsanitizedMessage);

    setException(V8ThrowException::createDOMException(SecurityError, finalSanitized, finalUnsanitized, m_creationContext, m_isolate));
}

void ExceptionState::setException(v8::Handle<v8::Value> exception)
{
    // FIXME: Assert that exception is not empty?
    if (exception.IsEmpty()) {
        clearException();
        return;
    }

    m_exception.set(m_isolate, exception);
}

void ExceptionState::throwException()
{
    ASSERT(!m_exception.isEmpty());
    V8ThrowException::throwException(m_exception.newLocal(m_isolate), m_isolate);
}

void ExceptionState::throwTypeError(const String& message)
{
    ASSERT(m_isolate);
    m_code = V8TypeError;
    m_message = message;
    setException(V8ThrowException::createTypeError(addExceptionContext(message), m_isolate));
}

void ExceptionState::throwRangeError(const String& message)
{
    ASSERT(m_isolate);
    m_code = V8RangeError;
    m_message = message;
    setException(V8ThrowException::createRangeError(addExceptionContext(message), m_isolate));
}

void NonThrowableExceptionState::throwDOMException(const ExceptionCode& ec, const String& message)
{
    ASSERT_NOT_REACHED();
    m_code = ec;
    m_message = message;
}

void NonThrowableExceptionState::throwTypeError(const String& message)
{
    ASSERT_NOT_REACHED();
    m_code = V8TypeError;
    m_message = message;
}

void NonThrowableExceptionState::throwSecurityError(const String& sanitizedMessage, const String&)
{
    ASSERT_NOT_REACHED();
    m_code = SecurityError;
    m_message = sanitizedMessage;
}

void NonThrowableExceptionState::throwRangeError(const String& message)
{
    ASSERT_NOT_REACHED();
    m_code = V8RangeError;
    m_message = message;
}

void TrackExceptionState::throwDOMException(const ExceptionCode& ec, const String& message)
{
    m_code = ec;
    m_message = message;
}

void TrackExceptionState::throwTypeError(const String& message)
{
    m_code = V8TypeError;
    m_message = message;
}

void TrackExceptionState::throwSecurityError(const String& sanitizedMessage, const String&)
{
    m_code = SecurityError;
    m_message = sanitizedMessage;
}

void TrackExceptionState::throwRangeError(const String& message)
{
    m_code = V8RangeError;
    m_message = message;
}

String ExceptionState::addExceptionContext(const String& message) const
{
    if (message.isEmpty())
        return message;

    String processedMessage = message;
    if (propertyName() && interfaceName() && m_context != UnknownContext) {
        if (m_context == DeletionContext)
            processedMessage = ExceptionMessages::failedToDelete(propertyName(), interfaceName(), message);
        else if (m_context == ExecutionContext)
            processedMessage = ExceptionMessages::failedToExecute(propertyName(), interfaceName(), message);
        else if (m_context == GetterContext)
            processedMessage = ExceptionMessages::failedToGet(propertyName(), interfaceName(), message);
        else if (m_context == SetterContext)
            processedMessage = ExceptionMessages::failedToSet(propertyName(), interfaceName(), message);
    } else if (!propertyName() && interfaceName()) {
        if (m_context == ConstructionContext)
            processedMessage = ExceptionMessages::failedToConstruct(interfaceName(), message);
        else if (m_context == EnumerationContext)
            processedMessage = ExceptionMessages::failedToEnumerate(interfaceName(), message);
        else if (m_context == IndexedDeletionContext)
            processedMessage = ExceptionMessages::failedToDeleteIndexed(interfaceName(), message);
        else if (m_context == IndexedGetterContext)
            processedMessage = ExceptionMessages::failedToGetIndexed(interfaceName(), message);
        else if (m_context == IndexedSetterContext)
            processedMessage = ExceptionMessages::failedToSetIndexed(interfaceName(), message);
    }
    return processedMessage;
}

} // namespace blink
