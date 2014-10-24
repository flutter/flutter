/*
 * Copyright (C) 2007, 2008 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 3.  Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef DOMException_h
#define DOMException_h

#include "bindings/core/v8/ScriptWrappable.h"
#include "platform/heap/Handle.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/text/WTFString.h"

namespace blink {

typedef int ExceptionCode;

class DOMException final : public RefCountedWillBeGarbageCollectedFinalized<DOMException>, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtrWillBeRawPtr<DOMException> create(ExceptionCode, const String& sanitizedMessage = String(), const String& unsanitizedMessage = String());

    unsigned short code() const { return m_code; }
    String name() const { return m_name; }

    // This is the message that's exposed to JavaScript: never return unsanitized data.
    String message() const { return m_sanitizedMessage; }
    String toString() const;

    // This is the message that's exposed to the console: if an unsanitized message is present, we prefer it.
    String messageForConsole() const { return !m_unsanitizedMessage.isEmpty() ? m_unsanitizedMessage : m_sanitizedMessage; }
    String toStringForConsole() const;

    static String getErrorName(ExceptionCode);
    static String getErrorMessage(ExceptionCode);

    void trace(Visitor*) { }

private:
    DOMException(unsigned short m_code, const String& name, const String& sanitizedMessage, const String& unsanitizedMessage);

    unsigned short m_code;
    String m_name;
    String m_sanitizedMessage;
    String m_unsanitizedMessage;
};

} // namespace blink

#endif // DOMException_h
