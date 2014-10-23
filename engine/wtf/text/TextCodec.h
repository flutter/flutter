/*
 * Copyright (C) 2004, 2006 Apple Computer, Inc.  All rights reserved.
 * Copyright (C) 2006 Alexey Proskuryakov <ap@nypop.com>
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

#ifndef TextCodec_h
#define TextCodec_h

#include "wtf/Forward.h"
#include "wtf/Noncopyable.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/text/WTFString.h"
#include "wtf/unicode/Unicode.h"

namespace WTF {

class TextEncoding;

// Specifies what will happen when a character is encountered that is
// not encodable in the character set.
enum UnencodableHandling {
    // Substitutes the replacement character "?".
    QuestionMarksForUnencodables,

    // Encodes the character as an XML entity. For example, U+06DE
    // would be "&#1758;" (0x6DE = 1758 in octal).
    EntitiesForUnencodables,

    // Encodes the character as en entity as above, but escaped
    // non-alphanumeric characters. This is used in URLs.
    // For example, U+6DE would be "%26%231758%3B".
    URLEncodedEntitiesForUnencodables
};

typedef char UnencodableReplacementArray[32];

enum FlushBehavior {
    // More bytes are coming, don't flush the codec.
    DoNotFlush = 0,

    // A fetch has hit EOF. Some codecs handle fetches differently, for compat reasons.
    FetchEOF,

    // Do a full flush of the codec.
    DataEOF
};

COMPILE_ASSERT(!DoNotFlush, DoNotFlush_is_falsy);
COMPILE_ASSERT(FetchEOF, FetchEOF_is_truthy);
COMPILE_ASSERT(DataEOF, DataEOF_is_truthy);


class TextCodec {
    WTF_MAKE_NONCOPYABLE(TextCodec); WTF_MAKE_FAST_ALLOCATED;
public:
    TextCodec() { }
    virtual ~TextCodec();

    String decode(const char* str, size_t length, FlushBehavior flush = DoNotFlush)
    {
        bool ignored;
        return decode(str, length, flush, false, ignored);
    }

    virtual String decode(const char*, size_t length, FlushBehavior, bool stopOnError, bool& sawError) = 0;
    virtual CString encode(const UChar*, size_t length, UnencodableHandling) = 0;
    virtual CString encode(const LChar*, size_t length, UnencodableHandling) = 0;

    // Fills a null-terminated string representation of the given
    // unencodable character into the given replacement buffer.
    // The length of the string (not including the null) will be returned.
    static int getUnencodableReplacement(unsigned codePoint, UnencodableHandling, UnencodableReplacementArray);
};

typedef void (*EncodingNameRegistrar)(const char* alias, const char* name);

typedef PassOwnPtr<TextCodec> (*NewTextCodecFunction)(const TextEncoding&, const void* additionalData);
typedef void (*TextCodecRegistrar)(const char* name, NewTextCodecFunction, const void* additionalData);

} // namespace WTF

using WTF::TextCodec;

#endif // TextCodec_h
