 /*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 * Copyright (C) 2012 Intel Corporation. All rights reserved.
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
#include "platform/network/ParsedContentType.h"

#include "wtf/text/CString.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

class DummyParsedContentType {
public:
    void setContentType(const SubstringRange&) const { }
    void setContentTypeParameter(const SubstringRange&, const SubstringRange&) const { }
};

static void skipSpaces(const String& input, unsigned& startIndex)
{
    while (startIndex < input.length() && input[startIndex] == ' ')
        ++startIndex;
}

static SubstringRange parseParameterPart(const String& input, unsigned& startIndex)
{
    unsigned inputLength = input.length();
    unsigned tokenStart = startIndex;
    unsigned& tokenEnd = startIndex;

    if (tokenEnd >= inputLength)
        return SubstringRange();

    bool quoted = input[tokenStart] == '\"';
    bool escape = false;

    while (tokenEnd < inputLength) {
        UChar c = input[tokenEnd];
        if (quoted && tokenStart != tokenEnd && c == '\"' && !escape)
            return SubstringRange(tokenStart + 1, tokenEnd++ - tokenStart - 1);
        if (!quoted && (c == ';' || c == '='))
            return SubstringRange(tokenStart, tokenEnd - tokenStart);
        escape = !escape && c == '\\';
        ++tokenEnd;
    }

    if (quoted)
        return SubstringRange();
    return SubstringRange(tokenStart, tokenEnd - tokenStart);
}

static String substringForRange(const String& string, const SubstringRange& range)
{
    return string.substring(range.first, range.second);
}

// From http://tools.ietf.org/html/rfc2045#section-5.1:
//
// content := "Content-Type" ":" type "/" subtype
//            *(";" parameter)
//            ; Matching of media type and subtype
//            ; is ALWAYS case-insensitive.
//
// type := discrete-type / composite-type
//
// discrete-type := "text" / "image" / "audio" / "video" /
//                  "application" / extension-token
//
// composite-type := "message" / "multipart" / extension-token
//
// extension-token := ietf-token / x-token
//
// ietf-token := <An extension token defined by a
//                standards-track RFC and registered
//                with IANA.>
//
// x-token := <The two characters "X-" or "x-" followed, with
//             no intervening white space, by any token>
//
// subtype := extension-token / iana-token
//
// iana-token := <A publicly-defined extension token. Tokens
//                of this form must be registered with IANA
//                as specified in RFC 2048.>
//
// parameter := attribute "=" value
//
// attribute := token
//              ; Matching of attributes
//              ; is ALWAYS case-insensitive.
//
// value := token / quoted-string
//
// token := 1*<any (US-ASCII) CHAR except SPACE, CTLs,
//             or tspecials>
//
// tspecials :=  "(" / ")" / "<" / ">" / "@" /
//               "," / ";" / ":" / "\" / <">
//               "/" / "[" / "]" / "?" / "="
//               ; Must be in quoted-string,
//               ; to use within parameter values

template <class ReceiverType>
bool parseContentType(const String& contentType, ReceiverType& receiver)
{
    unsigned index = 0;
    unsigned contentTypeLength = contentType.length();
    skipSpaces(contentType, index);
    if (index >= contentTypeLength)  {
        WTF_LOG_ERROR("Invalid Content-Type string '%s'", contentType.ascii().data());
        return false;
    }

    // There should not be any quoted strings until we reach the parameters.
    size_t semiColonIndex = contentType.find(';', index);
    if (semiColonIndex == kNotFound) {
        receiver.setContentType(SubstringRange(index, contentTypeLength - index));
        return true;
    }

    receiver.setContentType(SubstringRange(index, semiColonIndex - index));
    index = semiColonIndex + 1;
    while (true) {
        skipSpaces(contentType, index);
        SubstringRange keyRange = parseParameterPart(contentType, index);
        if (!keyRange.second || index >= contentTypeLength) {
            WTF_LOG_ERROR("Invalid Content-Type parameter name. (at %i)", index);
            return false;
        }

        // Should we tolerate spaces here?
        if (contentType[index++] != '=' || index >= contentTypeLength) {
            WTF_LOG_ERROR("Invalid Content-Type malformed parameter (at %i).", index);
            return false;
        }

        // Should we tolerate spaces here?
        SubstringRange valueRange = parseParameterPart(contentType, index);

        if (!valueRange.second) {
            WTF_LOG_ERROR("Invalid Content-Type, invalid parameter value (at %i, for '%s').", index, substringForRange(contentType, keyRange).stripWhiteSpace().ascii().data());
            return false;
        }

        // Should we tolerate spaces here?
        if (index < contentTypeLength && contentType[index++] != ';') {
            WTF_LOG_ERROR("Invalid Content-Type, invalid character at the end of key/value parameter (at %i).", index);
            return false;
        }

        receiver.setContentTypeParameter(keyRange, valueRange);

        if (index >= contentTypeLength)
            return true;
    }

    return true;
}

bool isValidContentType(const String& contentType)
{
    if (contentType.contains('\r') || contentType.contains('\n'))
        return false;

    DummyParsedContentType parsedContentType = DummyParsedContentType();
    return parseContentType<DummyParsedContentType>(contentType, parsedContentType);
}

ParsedContentType::ParsedContentType(const String& contentType)
    : m_contentType(contentType.stripWhiteSpace())
{
    parseContentType<ParsedContentType>(m_contentType, *this);
}

String ParsedContentType::charset() const
{
    return parameterValueForName("charset");
}

String ParsedContentType::parameterValueForName(const String& name) const
{
    return m_parameters.get(name);
}

size_t ParsedContentType::parameterCount() const
{
    return m_parameters.size();
}

void ParsedContentType::setContentType(const SubstringRange& contentRange)
{
    m_mimeType = substringForRange(m_contentType, contentRange).stripWhiteSpace();
}

void ParsedContentType::setContentTypeParameter(const SubstringRange& key, const SubstringRange& value)
{
    m_parameters.set(substringForRange(m_contentType, key), substringForRange(m_contentType, value));
}

}
