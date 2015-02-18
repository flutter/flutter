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

#include "sky/engine/config.h"
#include "sky/engine/core/html/parser/BackgroundHTMLParser.h"

#include "base/bind.h"
#include "base/single_thread_task_runner.h"
#include "sky/engine/core/html/parser/HTMLDocumentParser.h"
#include "sky/engine/core/html/parser/HTMLParserIdioms.h"
#include "sky/engine/core/html/parser/TextResourceDecoder.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/wtf/MainThread.h"
#include "sky/engine/wtf/text/TextPosition.h"

namespace blink {

// We limit our chucks to 1000 tokens, to make sure the main
// thread is never waiting on the parser thread for tokens.
// This was tuned in https://bugs.webkit.org/show_bug.cgi?id=110408.
static const size_t pendingTokenLimit = 1000;

#if ENABLE(ASSERT)

static void checkThatTokensAreSafeToSendToAnotherThread(const CompactHTMLTokenStream* tokens)
{
    for (size_t i = 0; i < tokens->size(); ++i)
        ASSERT(tokens->at(i).isSafeToSendToAnotherThread());
}

#endif

base::WeakPtr<BackgroundHTMLParser> BackgroundHTMLParser::create(PassOwnPtr<BackgroundHTMLParser::Configuration> config)
{
    // Caller must free by calling stop().
    BackgroundHTMLParser* parser = new BackgroundHTMLParser(config);
    return parser->m_weakFactory.GetWeakPtr();
}

BackgroundHTMLParser::BackgroundHTMLParser(PassOwnPtr<Configuration> config)
    : m_state(InitialState)
    , m_token(adoptPtr(new HTMLToken))
    , m_tokenizer(HTMLTokenizer::create())
    , m_parser(config->parser)
    , m_pendingTokens(adoptPtr(new CompactHTMLTokenStream))
    , m_decoder(TextResourceDecoder::create())
    , m_source(config->source.Pass())
    , m_weakFactory(this)
{
}

BackgroundHTMLParser::~BackgroundHTMLParser()
{
}

void BackgroundHTMLParser::start()
{
    m_drainer = adoptPtr(new mojo::common::DataPipeDrainer(this, m_source.Pass()));
}

void BackgroundHTMLParser::stop()
{
    delete this;
}

void BackgroundHTMLParser::OnDataAvailable(const void* data, size_t numberOfBytes)
{
    ASSERT(!m_input.isClosed());
    String input = m_decoder->decode(static_cast<const char*>(data), numberOfBytes);
    m_input.append(SegmentedString(input));
    pumpTokenizer();
}

void BackgroundHTMLParser::OnDataComplete()
{
    ASSERT(!m_input.isClosed());
    finish();
}

void BackgroundHTMLParser::finish()
{
    m_input.append(SegmentedString(m_decoder->flush()));
    markEndOfFile();
    pumpTokenizer();
}

void BackgroundHTMLParser::markEndOfFile()
{
    ASSERT(!m_input.isClosed());
    m_input.append(SegmentedString(String(&kEndOfFileMarker, 1)));
    m_input.close();
}

BackgroundHTMLParser::ContinueBehavior BackgroundHTMLParser::updateTokenizerState(const CompactHTMLToken& lastToken)
{
    if (lastToken.type() == HTMLToken::StartTag) {
        const String& tagName = lastToken.data();

        if (threadSafeMatch(tagName, HTMLNames::scriptTag) || threadSafeMatch(tagName, HTMLNames::styleTag))
            m_tokenizer->setState(HTMLTokenizer::RawDataState);

        if (threadSafeMatch(tagName, HTMLNames::importTag)) {
            m_state = DidSeeImportState;
            return ContinueParsing;
        }

        if (m_state == InitialState)
            return ContinueParsing;

        // If we hit a start tag which is not an <import> tag while in the
        // have-seen-import state, we need to send all but the last token.
        // This lets the main thread see all import tags in one chunk.
        // TODO(eseidel): We could replace this with a preloader and then
        // simply yield after every </import> regardless.
        m_state = InitialState;
        return SendTokensExceptingLast;
    }

    // We send all tokens at the end of every </script>
    if (lastToken.type() == HTMLToken::EndTag && threadSafeMatch(lastToken.data(), HTMLNames::scriptTag))
        return SendTokensIncludingLast;

    return ContinueParsing;
}

void BackgroundHTMLParser::pumpTokenizer()
{
    while (true) {
        if (!m_tokenizer->nextToken(m_input, *m_token)) {
            // We've reached the end of our current input.
            sendTokensToMainThread();
            break;
        }

        ContinueBehavior result;
        {
            CompactHTMLToken token(m_token.get(), TextPosition(m_input.currentLine(), m_input.currentColumn()));
            result = updateTokenizerState(token);
            if (result ==  SendTokensExceptingLast)
                sendTokensToMainThread();

            m_pendingTokens->append(token);
        }

        m_token->clear();

        if (result == SendTokensIncludingLast || m_pendingTokens->size() >= pendingTokenLimit)
            sendTokensToMainThread();
    }
}

void BackgroundHTMLParser::sendTokensToMainThread()
{
    if (m_pendingTokens->isEmpty())
        return;

#if ENABLE(ASSERT)
    checkThatTokensAreSafeToSendToAnotherThread(m_pendingTokens.get());
#endif

    OwnPtr<HTMLDocumentParser::ParsedChunk> chunk = adoptPtr(new HTMLDocumentParser::ParsedChunk);
    chunk->tokens = m_pendingTokens.release();
    Platform::current()->mainThreadTaskRunner()->PostTask(FROM_HERE,
        base::Bind(&HTMLDocumentParser::didReceiveParsedChunkFromBackgroundParser, m_parser, chunk.release()));

    m_pendingTokens = adoptPtr(new CompactHTMLTokenStream);
}

}
