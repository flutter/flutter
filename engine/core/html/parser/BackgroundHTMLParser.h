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

#ifndef SKY_ENGINE_CORE_HTML_PARSER_BACKGROUNDHTMLPARSER_H_
#define SKY_ENGINE_CORE_HTML_PARSER_BACKGROUNDHTMLPARSER_H_

#include "base/memory/weak_ptr.h"
#include "mojo/common/data_pipe_drainer.h"
#include "mojo/public/cpp/system/core.h"
#include "sky/engine/core/html/parser/CompactHTMLToken.h"
#include "sky/engine/core/html/parser/HTMLTokenizer.h"
#include "sky/engine/core/html/parser/TextResourceDecoder.h"
#include "sky/engine/platform/text/SegmentedString.h"
#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/WeakPtr.h"

namespace blink {

class HTMLDocumentParser;
class SharedBuffer;

class BackgroundHTMLParser : public mojo::common::DataPipeDrainer::Client {
    WTF_MAKE_FAST_ALLOCATED;
public:
    struct Configuration {
        mojo::ScopedDataPipeConsumerHandle source;
        base::WeakPtr<HTMLDocumentParser> parser;
    };

    static base::WeakPtr<BackgroundHTMLParser> create(PassOwnPtr<Configuration>);

    void start();
    void stop();

private:
    explicit BackgroundHTMLParser(PassOwnPtr<Configuration>);
    ~BackgroundHTMLParser();

    // DataPipeDrainer::Client:
    void OnDataAvailable(const void* data, size_t numberOfBytes) override;
    void OnDataComplete() override;

    void finish();
    void markEndOfFile();
    void pumpTokenizer();
    void sendTokensToMainThread();
    bool updateTokenizerState(const CompactHTMLToken& token);

    enum State {
        InitialState,
        DidSeeImportState,
    };

    State m_state;
    SegmentedString m_input;
    OwnPtr<HTMLToken> m_token;
    OwnPtr<HTMLTokenizer> m_tokenizer;
    base::WeakPtr<HTMLDocumentParser> m_parser;

    OwnPtr<CompactHTMLTokenStream> m_pendingTokens;
    OwnPtr<TextResourceDecoder> m_decoder;

    mojo::ScopedDataPipeConsumerHandle m_source;
    OwnPtr<mojo::common::DataPipeDrainer> m_drainer;

    base::WeakPtrFactory<BackgroundHTMLParser> m_weakFactory;
};

}

#endif  // SKY_ENGINE_CORE_HTML_PARSER_BACKGROUNDHTMLPARSER_H_
