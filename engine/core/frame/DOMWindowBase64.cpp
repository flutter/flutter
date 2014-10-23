/*
 * Copyright (C) 2006, 2007, 2008, 2010 Apple Inc. All rights reserved.
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2013 Samsung Electronics. All rights reserved.
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
#include "core/frame/DOMWindowBase64.h"

#include "bindings/core/v8/ExceptionState.h"
#include "core/dom/ExceptionCode.h"
#include "core/html/parser/HTMLParserIdioms.h"
#include "wtf/text/Base64.h"

namespace blink {

String DOMWindowBase64::btoa(const String& stringToEncode, ExceptionState& exceptionState)
{
    if (stringToEncode.isNull())
        return String();

    if (!stringToEncode.containsOnlyLatin1()) {
        exceptionState.throwDOMException(InvalidCharacterError, "The string to be encoded contains characters outside of the Latin1 range.");
        return String();
    }

    return base64Encode(stringToEncode.latin1());
}

String DOMWindowBase64::atob(const String& encodedString, ExceptionState& exceptionState)
{
    if (encodedString.isNull())
        return String();

    if (!encodedString.containsOnlyLatin1()) {
        exceptionState.throwDOMException(InvalidCharacterError, "The string to be decoded contains characters outside of the Latin1 range.");
        return String();
    }
    Vector<char> out;
    if (!base64Decode(encodedString, out, isHTMLSpace<UChar>, Base64ValidatePadding)) {
        exceptionState.throwDOMException(InvalidCharacterError, "The string to be decoded is not correctly encoded.");
        return String();
    }

    return String(out.data(), out.size());
}

} // namespace blink
