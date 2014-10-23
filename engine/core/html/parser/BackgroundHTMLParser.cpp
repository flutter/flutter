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

#include "config.h"
#include "core/html/parser/BackgroundHTMLParser.h"

#include "core/html/parser/HTMLDocumentParser.h"
#include "core/html/parser/TextResourceDecoder.h"
#include "wtf/MainThread.h"
#include "wtf/text/TextPosition.h"

namespace blink {

// On a network with high latency and high bandwidth, using a device
// with a fast CPU, we could end up speculatively tokenizing
// the whole document, well ahead of when the main-thread actually needs it.
// This is a waste of memory (and potentially time if the speculation fails).
// So we limit our outstanding tokens arbitrarily to 10,000.
// Our maximal memory spent speculating will be approximately:
// (outstandingTokenLimit + pendingTokenLimit) * sizeof(CompactToken)
// We use a separate low and high water mark to avoid constantly topping
// off the main thread's token buffer.
// At time of writing, this is (10000 + 1000) * 28 bytes = ~308kb of memory.
// These numbers have not been tuned.
static const size_t outstandingTokenLimit = 10000;

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
    : m_token(adoptPtr(new HTMLToken))
    , m_tokenizer(HTMLTokenizer::create(config->options))
    , m_treeBuilderSimulator(config->options)
    , m_options(config->options)
    , m_parser(config->parser)
    , m_pendingTokens(adoptPtr(new CompactHTMLTokenStream))
    , m_decoder(TextResourceDecoder::create())
    , m_weakFactory(this)
{
}

BackgroundHTMLParser::~BackgroundHTMLParser()
{
}

void BackgroundHTMLParser::appendRawBytesFromParserThread(const char* data, int dataLength)
{
    updateDocument(m_decoder->decode(data, dataLength));
}

void BackgroundHTMLParser::appendRawBytesFromMainThread(PassOwnPtr<Vector<char> > buffer)
{
    updateDocument(m_decoder->decode(buffer->data(), buffer->size()));
}

void BackgroundHTMLParser::appendDecodedBytes(const String& input)
{
    ASSERT(!m_input.current().isClosed());
    m_input.append(input);
    pumpTokenizer();
}

void BackgroundHTMLParser::flush()
{
    updateDocument(m_decoder->flush());
}

void BackgroundHTMLParser::updateDocument(const String& decodedData)
{
    if (decodedData.isEmpty())
        return;

    appendDecodedBytes(decodedData);
}

void BackgroundHTMLParser::startedChunkWithCheckpoint(HTMLInputCheckpoint inputCheckpoint)
{
    // Note, we should not have to worry about the index being invalid
    // as messages from the main thread will be processed in FIFO order.
    m_input.invalidateCheckpointsBefore(inputCheckpoint);
    pumpTokenizer();
}

void BackgroundHTMLParser::finish()
{
    markEndOfFile();
    pumpTokenizer();
}

void BackgroundHTMLParser::stop()
{
    delete this;
}

void BackgroundHTMLParser::markEndOfFile()
{
    ASSERT(!m_input.current().isClosed());
    m_input.append(String(&kEndOfFileMarker, 1));
    m_input.close();
}

void BackgroundHTMLParser::pumpTokenizer()
{
    // No need to start speculating until the main thread has almost caught up.
    if (m_input.totalCheckpointTokenCount() > outstandingTokenLimit)
        return;

    while (true) {
        if (!m_tokenizer->nextToken(m_input.current(), *m_token)) {
            // We've reached the end of our current input.
            sendTokensToMainThread();
            break;
        }

        {
            CompactHTMLToken token(m_token.get(), TextPosition(m_input.current().currentLine(), m_input.current().currentColumn()));
            m_pendingTokens->append(token);
        }

        m_token->clear();

        if (!m_treeBuilderSimulator.simulate(m_pendingTokens->last(), m_tokenizer.get()) || m_pendingTokens->size() >= pendingTokenLimit) {
            sendTokensToMainThread();
            // If we're far ahead of the main thread, yield for a bit to avoid consuming too much memory.
            if (m_input.totalCheckpointTokenCount() > outstandingTokenLimit)
                break;
        }
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
    chunk->tokenizerState = m_tokenizer->state();
    chunk->inputCheckpoint = m_input.createCheckpoint(m_pendingTokens->size());
    chunk->tokens = m_pendingTokens.release();
    callOnMainThread(bind(&HTMLDocumentParser::didReceiveParsedChunkFromBackgroundParser, m_parser, chunk.release()));

    m_pendingTokens = adoptPtr(new CompactHTMLTokenStream);
}

}
