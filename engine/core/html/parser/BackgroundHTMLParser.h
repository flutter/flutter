/*
 * Copyright (C) 2013 Google, Inc. All Rights Reserved.
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
 * THIS SOFTWARE IS PROVIDED BY GOOGLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL GOOGLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef BackgroundHTMLParser_h
#define BackgroundHTMLParser_h

#include "base/memory/weak_ptr.h"
#include "core/html/parser/CompactHTMLToken.h"
#include "core/html/parser/HTMLParserOptions.h"
#include "core/html/parser/HTMLTokenizer.h"
#include "core/html/parser/TextResourceDecoder.h"
#include "platform/text/SegmentedString.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/WeakPtr.h"

namespace blink {

class HTMLDocumentParser;
class SharedBuffer;

class BackgroundHTMLParser {
    WTF_MAKE_FAST_ALLOCATED;
public:
    struct Configuration {
        HTMLParserOptions options;
        WeakPtr<HTMLDocumentParser> parser;
    };

    static base::WeakPtr<BackgroundHTMLParser> create(PassOwnPtr<Configuration>);

    struct Checkpoint {
        WeakPtr<HTMLDocumentParser> parser;
        OwnPtr<HTMLToken> token;
        OwnPtr<HTMLTokenizer> tokenizer;
        String unparsedInput;
    };

    void appendRawBytesFromParserThread(const char* data, int dataLength);

    void appendRawBytesFromMainThread(PassOwnPtr<Vector<char> >);
    void flush();
    void resumeFrom(PassOwnPtr<Checkpoint>);
    void finish();
    void stop();

private:
    explicit BackgroundHTMLParser(PassOwnPtr<Configuration>);
    ~BackgroundHTMLParser();

    void appendDecodedBytes(const String&);
    void markEndOfFile();
    void pumpTokenizer();
    void sendTokensToMainThread();
    void updateDocument(const String& decodedData);
    bool updateTokenizerState(const CompactHTMLToken& token);

    SegmentedString m_input;
    OwnPtr<HTMLToken> m_token;
    OwnPtr<HTMLTokenizer> m_tokenizer;
    HTMLParserOptions m_options;
    WeakPtr<HTMLDocumentParser> m_parser;

    OwnPtr<CompactHTMLTokenStream> m_pendingTokens;
    OwnPtr<TextResourceDecoder> m_decoder;

    base::WeakPtrFactory<BackgroundHTMLParser> m_weakFactory;
};

}

#endif
