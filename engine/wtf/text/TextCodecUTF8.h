/*
 * Copyright (C) 2011 Apple Inc. All rights reserved.
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

#ifndef TextCodecUTF8_h
#define TextCodecUTF8_h

#include "wtf/text/TextCodec.h"

namespace WTF {

class TextCodecUTF8 : public TextCodec {
public:
    static void registerEncodingNames(EncodingNameRegistrar);
    static void registerCodecs(TextCodecRegistrar);

protected:
    TextCodecUTF8() : m_partialSequenceSize(0) { }

private:
    static PassOwnPtr<TextCodec> create(const TextEncoding&, const void*);

    virtual String decode(const char*, size_t length, FlushBehavior, bool stopOnError, bool& sawError) override;
    virtual CString encode(const UChar*, size_t length, UnencodableHandling) override;
    virtual CString encode(const LChar*, size_t length, UnencodableHandling) override;

    template<typename CharType>
    CString encodeCommon(const CharType* characters, size_t length);

    template <typename CharType>
    bool handlePartialSequence(CharType*& destination, const uint8_t*& source, const uint8_t* end, bool flush, bool stopOnError, bool& sawError);
    void handleError(UChar*& destination, bool stopOnError, bool& sawError);
    void consumePartialSequenceByte();

    int m_partialSequenceSize;
    uint8_t m_partialSequence[U8_MAX_LENGTH];

};

} // namespace WTF

#endif // TextCodecUTF8_h
