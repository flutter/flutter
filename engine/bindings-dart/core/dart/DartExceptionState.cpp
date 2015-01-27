// Copyright (c) 2014, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include "config.h"
#include "bindings/core/dart/DartExceptionState.h"

#include "bindings/core/dart/DartDOMException.h"
#include "bindings/core/dart/DartUtilities.h"
#include "wtf/text/WTFString.h"

#include <stdio.h>

namespace blink {

void DartExceptionState::throwDOMException(const ExceptionCode& ec, const String& message)
{
    setException(ec, message);
}

void DartExceptionState::throwSecurityError(const String& sanitizedMessage, const String& unsanitizedMessage)
{
    // SecurityError is thrown via ::throwSecurityError, and _careful_ consideration must be given to the data exposed to JavaScript via the 'sanitizedMessage'.
    setException(SecurityError, sanitizedMessage);
}

void DartExceptionState::rethrowV8Exception(v8::Handle<v8::Value> value)
{
    const char* msg = "A Javascript exception occurred";
    ASSERT(!m_exception);
    m_exception = Dart_NewPersistentHandle(Dart_NewStringFromCString(msg));
    setMessage(msg);
    setHadException(true);
}

void DartExceptionState::setException(const ExceptionCode& ec, const String& msg)
{
    setCode(ec);
    setHadException(true);
    String excp = DOMException::getErrorMessage(ec) + " " + msg;
    RefPtr<DOMException> domException = DOMException::create(ec, excp);
    ASSERT(!m_exception);
    m_exception = Dart_NewPersistentHandle(DartDOMException::toDart(domException));
    setMessage(msg);
}

void DartExceptionState::clearException()
{
    setCode(0);
    setHadException(false);
    if (m_exception) {
        Dart_DeletePersistentHandle(m_exception);
        m_exception = 0;
    }
}

void DartExceptionState::throwException()
{
    // FIXMEMULTIVM: The control flow here does not match V8's. Dart_ThrowException immediately
    // transfers control, which may skip running C++ destructors on the stack and ref-counting
    // leaks. Should move throwIfNeeded from ExceptionState to V8ExceptionState and remove this.
    ASSERT_NOT_REACHED();

    ASSERT(code());
    ASSERT(hadException());
    ASSERT(m_exception);
    DartDOMData* domData = DartDOMData::current();
    Dart_SetPersistentHandle(domData->currentException(), m_exception);
    Dart_DeletePersistentHandle(m_exception);
    m_exception = 0;
    Dart_ThrowException(domData->currentException());
    ASSERT_NOT_REACHED();
}

Dart_Handle DartExceptionState::toDart(Dart_NativeArguments args, bool autoDartScope)
{
    ASSERT(hadException());
    ASSERT(m_exception);

    if (autoDartScope) {
        Dart_Handle localException = Dart_HandleFromPersistent(m_exception);
        Dart_DeletePersistentHandle(m_exception);
        m_exception = 0;
        return localException;
    }
    DartDOMData* domData = static_cast<DartDOMData*>(Dart_GetNativeIsolateData(args));
    Dart_SetPersistentHandle(domData->currentException(), m_exception);
    Dart_DeletePersistentHandle(m_exception);
    m_exception = 0;
    return domData->currentException();
}

void DartExceptionState::throwTypeError(const String& message)
{
    throwDartCoreError("ArgumentError", message, V8TypeError);
}

void DartExceptionState::throwRangeError(const String& message)
{
    throwDartCoreError("RangeError", message, V8RangeError);
}

void DartExceptionState::throwDartCoreError(const String& className, const String& message, const ExceptionCode& ec)
{
    setCode(ec);
    setHadException(true);
    setMessage(message);

    Dart_Handle error = DartUtilities::toDartCoreException(className, message);

    ASSERT(!m_exception);
    m_exception = Dart_NewPersistentHandle(error);
}

ScriptPromise DartExceptionState::reject(ScriptState* state)
{
    // FIXMEDART: implement.
    DART_UNIMPLEMENTED();
    return ScriptPromise::empty(state);
}


} // namespace blink
