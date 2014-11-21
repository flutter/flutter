/*
 * Copyright (C) 2006 Alexey Proskuryakov (ap@webkit.org)
 * Copyright (C) 2009 Google Inc. All rights reserved.
 * Copyright (C) 2011 Apple Inc. All Rights Reserved.
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

#ifndef HTTPParsers_h
#define HTTPParsers_h

#include "sky/engine/platform/PlatformExport.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

typedef enum {
    ContentDispositionNone,
    ContentDispositionInline,
    ContentDispositionAttachment,
    ContentDispositionOther
} ContentDispositionType;

enum ContentTypeOptionsDisposition {
    ContentTypeOptionsNone,
    ContentTypeOptionsNosniff
};

// Be sure to update the behavior of XSSAuditor::combineXSSProtectionHeaderAndCSP whenever you change this enum's content or ordering.
enum ReflectedXSSDisposition {
    ReflectedXSSUnset = 0,
    AllowReflectedXSS,
    ReflectedXSSInvalid,
    FilterReflectedXSS,
    BlockReflectedXSS
};

struct CacheControlHeader {
    bool parsed : 1;
    bool containsNoCache : 1;
    bool containsNoStore : 1;
    bool containsMustRevalidate : 1;
    double maxAge;

    CacheControlHeader()
        : parsed(false)
        , containsNoCache(false)
        , containsNoStore(false)
        , containsMustRevalidate(false)
        , maxAge(0.0)
    {
    }
};

PLATFORM_EXPORT ContentDispositionType contentDispositionType(const String&);
PLATFORM_EXPORT bool isValidHTTPHeaderValue(const String&);
PLATFORM_EXPORT bool isValidHTTPToken(const String&);
PLATFORM_EXPORT double parseDate(const String&);
PLATFORM_EXPORT String filenameFromHTTPContentDisposition(const String&);
PLATFORM_EXPORT AtomicString extractMIMETypeFromMediaType(const AtomicString&);
PLATFORM_EXPORT String extractCharsetFromMediaType(const String&);
PLATFORM_EXPORT void findCharsetInMediaType(const String& mediaType, unsigned& charsetPos, unsigned& charsetLen, unsigned start = 0);
PLATFORM_EXPORT ReflectedXSSDisposition parseXSSProtectionHeader(const String& header, String& failureReason, unsigned& failurePosition, String& reportURL);
PLATFORM_EXPORT String extractReasonPhraseFromHTTPStatusLine(const String&);
PLATFORM_EXPORT CacheControlHeader parseCacheControlDirectives(const AtomicString& cacheControlHeader, const AtomicString& pragmaHeader);

// -1 could be set to one of the return parameters to indicate the value is not specified.
PLATFORM_EXPORT bool parseRange(const String&, long long& rangeOffset, long long& rangeEnd, long long& rangeSuffixLength);

PLATFORM_EXPORT ContentTypeOptionsDisposition parseContentTypeOptionsHeader(const String& header);

// Parsing Complete HTTP Messages.
enum HTTPVersion { Unknown, HTTP_1_0, HTTP_1_1 };
PLATFORM_EXPORT size_t parseHTTPRequestLine(const char* data, size_t length, String& failureReason, String& method, String& url, HTTPVersion&);
PLATFORM_EXPORT size_t parseHTTPHeader(const char* data, size_t length, String& failureReason, AtomicString& nameStr, AtomicString& valueStr);
PLATFORM_EXPORT size_t parseHTTPRequestBody(const char* data, size_t length, Vector<unsigned char>& body);

}

#endif
