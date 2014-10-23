/*
 * Copyright (C) 2006, 2008 Apple Inc.  All rights reserved.
 * Copyright (C) 2008 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (C) 2009 Google Inc.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/ContentType.h"

namespace blink {

ContentType::ContentType(const String& contentType)
    : m_type(contentType)
{
}

String ContentType::parameter(const String& parameterName) const
{
    String parameterValue;
    String strippedType = m_type.stripWhiteSpace();

    // a MIME type can have one or more "param=value" after a semi-colon, and separated from each other by semi-colons
    size_t semi = strippedType.find(';');
    if (semi != kNotFound) {
        size_t start = strippedType.find(parameterName, semi + 1, false);
        if (start != kNotFound) {
            start = strippedType.find('=', start + parameterName.length());
            if (start != kNotFound) {
                size_t quote = strippedType.find('\"', start + 1);
                size_t end = strippedType.find('\"', start + 2);
                if (quote != kNotFound && end != kNotFound) {
                    start = quote;
                } else {
                    end = strippedType.find(';', start + 1);
                    if (end == kNotFound)
                        end = strippedType.length();
                }
                parameterValue = strippedType.substring(start + 1, end - (start + 1)).stripWhiteSpace();
            }
        }
    }

    return parameterValue;
}

String ContentType::type() const
{
    String strippedType = m_type.stripWhiteSpace();

    // "type" can have parameters after a semi-colon, strip them
    size_t semi = strippedType.find(';');
    if (semi != kNotFound)
        strippedType = strippedType.left(semi).stripWhiteSpace();

    return strippedType;
}

Vector<String> ContentType::codecs() const
{
    String codecsParameter = parameter("codecs");

    if (codecsParameter.isEmpty())
        return Vector<String>();

    Vector<String> codecs;
    codecsParameter.split(',', codecs);
    for (size_t i = 0; i < codecs.size(); ++i)
        codecs[i] = codecs[i].simplifyWhiteSpace();

    return codecs;
}

} // namespace blink
