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

#ifndef ExceptionStatePlaceholder_h
#define ExceptionStatePlaceholder_h

#include "bindings/core/v8/ExceptionState.h"
#include "wtf/Assertions.h"
#include "wtf/text/WTFString.h"
#include <v8.h>

namespace blink {

class ExceptionState;

typedef int ExceptionCode;

class IgnorableExceptionState FINAL : public ExceptionState {
public:
    IgnorableExceptionState(): ExceptionState(ExceptionState::UnknownContext, 0, 0, v8::Handle<v8::Object>(), 0) { }
    ExceptionState& returnThis() { return *this; }
    virtual void throwDOMException(const ExceptionCode&, const String& message = String()) OVERRIDE { }
    virtual void throwTypeError(const String& message = String()) OVERRIDE { }
    virtual void throwSecurityError(const String& sanitizedMessage, const String& unsanitizedMessage = String()) OVERRIDE { }
};

#define IGNORE_EXCEPTION (::blink::IgnorableExceptionState().returnThis())

#if ENABLE(ASSERT)

class NoExceptionStateAssertionChecker FINAL : public ExceptionState {
public:
    NoExceptionStateAssertionChecker(const char* file, int line);
    ExceptionState& returnThis() { return *this; }
    virtual void throwDOMException(const ExceptionCode&, const String& message = String()) OVERRIDE;
    virtual void throwTypeError(const String& message = String()) OVERRIDE;
    virtual void throwSecurityError(const String& sanitizedMessage, const String& unsanitizedMessage = String()) OVERRIDE;

private:
    const char* m_file;
    int m_line;
};

#define ASSERT_NO_EXCEPTION (::blink::NoExceptionStateAssertionChecker(__FILE__, __LINE__).returnThis())

#else

#define ASSERT_NO_EXCEPTION (::blink::IgnorableExceptionState().returnThis())

#endif

} // namespace blink

#endif // ExceptionStatePlaceholder_h
