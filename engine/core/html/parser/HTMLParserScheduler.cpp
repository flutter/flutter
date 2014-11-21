/*
 * Copyright (C) 2010 Google, Inc. All Rights Reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "sky/engine/config.h"
#include "sky/engine/core/html/parser/HTMLParserScheduler.h"

#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/html/parser/HTMLDocumentParser.h"

namespace blink {

// parserChunkSize is used to define how many tokens the parser will
// process before checking against parserTimeLimit and possibly yielding.
// This is a performance optimization to prevent checking after every token.
const int HTMLParserScheduler::parserChunkSize = 4096;

// parserTimeLimit is the seconds the parser will run in one write() call
// before yielding. Inline <script> execution can cause it to exceed the limit.
const double HTMLParserScheduler::parserTimeLimit = 0.2;

ActiveParserSession::ActiveParserSession(Document* document)
    : m_document(document)
{
    if (!m_document)
        return;
    m_document->incrementActiveParserCount();
}

ActiveParserSession::~ActiveParserSession()
{
    if (!m_document)
        return;
    m_document->decrementActiveParserCount();
}

PumpSession::PumpSession(unsigned& nestingLevel, Document* document)
    : NestingLevelIncrementer(nestingLevel)
    , ActiveParserSession(document)
    // Setting processedTokens to INT_MAX causes us to check for yields
    // after any token during any parse where yielding is allowed.
    // At that time we'll initialize startTime.
    , processedTokens(INT_MAX)
    , startTime(0)
    , needsYield(false)
    , didSeeScript(false)
{
}

PumpSession::~PumpSession()
{
}

HTMLParserScheduler::HTMLParserScheduler(HTMLDocumentParser* parser)
    : m_parser(parser)
    , m_continueNextChunkTimer(this, &HTMLParserScheduler::continueNextChunkTimerFired)
{
}

HTMLParserScheduler::~HTMLParserScheduler()
{
    m_continueNextChunkTimer.stop();
}

void HTMLParserScheduler::continueNextChunkTimerFired(Timer<HTMLParserScheduler>* timer)
{
    ASSERT_UNUSED(timer, timer == &m_continueNextChunkTimer);
    m_parser->resumeParsingAfterYield();
}

void HTMLParserScheduler::scheduleForResume()
{
    m_continueNextChunkTimer.startOneShot(0, FROM_HERE);
}

}
