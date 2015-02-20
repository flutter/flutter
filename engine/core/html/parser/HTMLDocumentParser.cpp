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
#include "sky/engine/core/html/parser/HTMLDocumentParser.h"

#include "base/bind.h"
#include "gen/sky/core/HTMLNames.h"
#include "sky/engine/core/css/MediaValuesCached.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/html/HTMLScriptElement.h"
#include "sky/engine/core/html/parser/AtomicHTMLToken.h"
#include "sky/engine/core/html/parser/BackgroundHTMLParser.h"
#include "sky/engine/core/html/parser/HTMLParserScheduler.h"
#include "sky/engine/core/html/parser/HTMLParserThread.h"
#include "sky/engine/core/html/parser/HTMLTreeBuilder.h"
#include "sky/engine/platform/SharedBuffer.h"
#include "sky/engine/platform/TraceEvent.h"

namespace blink {

HTMLDocumentParser::HTMLDocumentParser(Document& document, bool reportErrors)
    : DocumentParser(&document)
    , m_treeBuilder(HTMLTreeBuilder::create(this, &document, reportErrors))
    , m_parserScheduler(HTMLParserScheduler::create(this))
    , m_weakFactory(this)
    , m_isFragment(false)
    , m_endWasDelayed(false)
    , m_haveBackgroundParser(false)
    , m_pumpSessionNestingLevel(0)
{
}

HTMLDocumentParser::~HTMLDocumentParser()
{
    ASSERT(!m_parserScheduler);
    ASSERT(!m_pumpSessionNestingLevel);
    ASSERT(!m_haveBackgroundParser);
    // FIXME: We should be able to ASSERT(m_pendingChunks.isEmpty()),
    // but there are cases where that's not true currently. For example,
    // we we're told to stop parsing before we've consumed all the input.
}

void HTMLDocumentParser::parse(mojo::ScopedDataPipeConsumerHandle source,
                               const base::Closure& completionCallback)
{
    ASSERT(!isStopped());
    ASSERT(!m_haveBackgroundParser);
    m_haveBackgroundParser = true;

    m_completionCallback = completionCallback;

    OwnPtr<BackgroundHTMLParser::Configuration> config = adoptPtr(new BackgroundHTMLParser::Configuration);
    config->source = source.Pass();
    config->parser = m_weakFactory.GetWeakPtr();

    m_backgroundParser = BackgroundHTMLParser::create(config.release());
    HTMLParserThread::taskRunner()->PostTask(FROM_HERE,
        base::Bind(&BackgroundHTMLParser::start, m_backgroundParser));
}

void HTMLDocumentParser::detach()
{
    if (m_haveBackgroundParser)
        stopBackgroundParser();
    DocumentParser::detach();
    m_treeBuilder->detach();
    // FIXME: It seems wrong that we would have a preload scanner here.
    // Yet during fast/dom/HTMLScriptElement/script-load-events.html we do.
    m_parserScheduler.clear(); // Deleting the scheduler will clear any timers.
}

void HTMLDocumentParser::stopParsing()
{
    DocumentParser::stopParsing();
    m_parserScheduler.clear(); // Deleting the scheduler will clear any timers.
    if (m_haveBackgroundParser)
        stopBackgroundParser();
}

// This kicks off "Once the user agent stops parsing" as described by:
// http://www.whatwg.org/specs/web-apps/current-work/multipage/the-end.html#the-end
void HTMLDocumentParser::prepareToStopParsing()
{
    // FIXME: It may not be correct to disable this for the background parser.
    // That means hasInsertionPoint() may not be correct in some cases.
    ASSERT(!hasInsertionPoint() || m_haveBackgroundParser);

    // pumpTokenizer can cause this parser to be detached from the Document,
    // but we need to ensure it isn't deleted yet.
    RefPtr<HTMLDocumentParser> protect(this);

    if (isStopped())
        return;

    DocumentParser::prepareToStopParsing();

    // We will not have a scriptRunner when parsing a DocumentFragment.
    if (!m_isFragment)
        document()->setReadyState(Document::Interactive);

    // Setting the ready state above can fire mutation event and detach us
    // from underneath. In that case, just bail out.
    if (isDetached())
        return;

    ASSERT(isStopping());
    ASSERT(!hasInsertionPoint() || m_haveBackgroundParser);
    end();
}

bool HTMLDocumentParser::isParsingFragment() const
{
    return m_treeBuilder->isParsingFragment();
}

bool HTMLDocumentParser::isScheduledForResume() const
{
    return m_parserScheduler && m_parserScheduler->isScheduledForResume();
}

// Used by HTMLParserScheduler
void HTMLDocumentParser::resumeParsingAfterYield()
{
    // pumpTokenizer can cause this parser to be detached from the Document,
    // but we need to ensure it isn't deleted yet.
    RefPtr<HTMLDocumentParser> protect(this);

    ASSERT(m_haveBackgroundParser);
    pumpPendingChunks();
}

void HTMLDocumentParser::runScriptsForPausedTreeBuilder()
{
    if (m_isFragment)
        return;
    TextPosition scriptStartPosition = TextPosition::belowRangePosition();
    RefPtr<Element> scriptToProcess = m_treeBuilder->takeScriptToProcess(scriptStartPosition);

    // Sending the script to dart may find additional 'import' declarations
    // which need to load before the script can execute.  HTMLScriptRunner
    // always calls scriptExecutionCompleted regardless of success/failure.
    m_scriptRunner = HTMLScriptRunner::createForScript(
        toHTMLScriptElement(scriptToProcess.get()), scriptStartPosition, this);
    m_scriptRunner->start();
}

void HTMLDocumentParser::didReceiveParsedChunkFromBackgroundParser(PassOwnPtr<ParsedChunk> chunk)
{
    TRACE_EVENT0("blink", "HTMLDocumentParser::didReceiveParsedChunkFromBackgroundParser");
    // Sky should not need nested parsers.
    ASSERT(document()->activeParserCount() == 0);

    if (isWaitingForScripts() || !m_pendingChunks.isEmpty() ||
        document()->activeParserCount() > 0) {
        m_pendingChunks.append(chunk);
        return;
    }

    // processParsedChunkFromBackgroundParser can cause this parser to be detached from the Document,
    // but we need to ensure it isn't deleted yet.
    RefPtr<HTMLDocumentParser> protect(this);

    ASSERT(m_pendingChunks.isEmpty());
    m_pendingChunks.append(chunk);
    pumpPendingChunks();
}

void HTMLDocumentParser::processParsedChunkFromBackgroundParser(PassOwnPtr<ParsedChunk> popChunk)
{
    // TODO(eseidel): Include the token count in the trace event.
    TRACE_EVENT0("blink", "HTMLDocumentParser::processParsedChunkFromBackgroundParser");

    ASSERT_WITH_SECURITY_IMPLICATION(!document()->activeParserCount());
    ASSERT(!isParsingFragment());
    ASSERT(!isWaitingForScripts());
    ASSERT(!isStopped());

    // ASSERT that this object is both attached to the Document and protected.
    ASSERT(refCount() >= 2);

    ActiveParserSession session(contextForParsingSession());

    OwnPtr<ParsedChunk> chunk(popChunk);
    OwnPtr<CompactHTMLTokenStream> tokens = chunk->tokens.release();

    Vector<CompactHTMLToken>::const_iterator it;
    for (it = tokens->begin(); it != tokens->end(); ++it) {
      // A chunk can issue import loads causing us to be isWaitingForScripts
      // but we don't stop processing in that case.
      ASSERT(!m_treeBuilder->hasParserBlockingScript());
      ASSERT(!m_scriptRunner);

        m_textPosition = it->textPosition();

        constructTreeFromCompactHTMLToken(*it);

        if (isStopped())
            break;

        if (m_treeBuilder->hasParserBlockingScript()) {
            ++it; // Make it == end() during non-stopped termination.
            ASSERT(it == tokens->end());  // The </script> is assumed to be the
                                          // last token of this bunch.
            runScriptsForPausedTreeBuilder();
            break;
        }

        if (it->type() == HTMLToken::EndOfFile) {
            ++it; // Make it == end() during non-stopped termination.
            ASSERT(it == tokens->end());  // The EOF is assumed to be the
                                          // last token of this bunch.
            ASSERT(m_pendingChunks.isEmpty()); // There should never be any chunks after the EOF.
            prepareToStopParsing();
            break;
        }
    }

    // Either we aborted due to stopping or we processed all tokens.
    ASSERT(isStopped() || it == tokens->end());

    // Make sure any pending text nodes are emitted before returning.
    if (!isStopped())
        m_treeBuilder->flush();
}

void HTMLDocumentParser::pumpPendingChunks()
{
    // FIXME: Share this constant with the parser scheduler.
    const double parserTimeLimit = 0.500;

    // ASSERT that this object is both attached to the Document and protected.
    ASSERT(refCount() >= 2);
    ASSERT(!isWaitingForScripts());
    ASSERT(!isStopped());

    double startTime = currentTime();

    while (!m_pendingChunks.isEmpty()) {
        processParsedChunkFromBackgroundParser(m_pendingChunks.takeFirst());

        // Always check isStopped first as m_document may be null.
        if (isStopped() || isWaitingForScripts())
            break;

        if (currentTime() - startTime > parserTimeLimit && !m_pendingChunks.isEmpty()) {
            m_parserScheduler->scheduleForResume();
            break;
        }
    }
}

Document* HTMLDocumentParser::contextForParsingSession()
{
    // The parsing session should interact with the document only when parsing
    // non-fragments. Otherwise, we might delay the load event mistakenly.
    if (isParsingFragment())
        return 0;
    return document();
}

void HTMLDocumentParser::constructTreeFromHTMLToken(HTMLToken& rawToken)
{
    AtomicHTMLToken token(rawToken);

    // We clear the rawToken in case constructTreeFromAtomicToken
    // synchronously re-enters the parser. We don't clear the token immedately
    // for Character tokens because the AtomicHTMLToken avoids copying the
    // characters by keeping a pointer to the underlying buffer in the
    // HTMLToken. Fortunately, Character tokens can't cause us to re-enter
    // the parser.
    //
    // FIXME: Stop clearing the rawToken once we start running the parser off
    // the main thread or once we stop allowing synchronous JavaScript
    // execution from parseAttribute.
    if (rawToken.type() != HTMLToken::Character)
        rawToken.clear();

    m_treeBuilder->constructTree(&token);

    if (!rawToken.isUninitialized()) {
        ASSERT(rawToken.type() == HTMLToken::Character);
        rawToken.clear();
    }
}

void HTMLDocumentParser::constructTreeFromCompactHTMLToken(const CompactHTMLToken& compactToken)
{
    AtomicHTMLToken token(compactToken);
    m_treeBuilder->constructTree(&token);
}

bool HTMLDocumentParser::hasInsertionPoint()
{
    return false;
}

void HTMLDocumentParser::stopBackgroundParser()
{
    ASSERT(m_haveBackgroundParser);
    m_haveBackgroundParser = false;

    HTMLParserThread::taskRunner()->PostTask(FROM_HERE,
        base::Bind(&BackgroundHTMLParser::stop, m_backgroundParser));
    m_weakFactory.InvalidateWeakPtrs();
}

void HTMLDocumentParser::end()
{
    ASSERT(!isDetached());
    ASSERT(!isScheduledForResume());

    if (m_haveBackgroundParser)
        stopBackgroundParser();

    // Notice that we copy the compleition callback into a local variable
    // because we might be deleted after we call ffinish() below.
    base::Closure completionCallback = m_completionCallback;

    // Informs the the rest of WebCore that parsing is really finished (and deletes this).
    m_treeBuilder->finished();

    completionCallback.Run();
}

void HTMLDocumentParser::attemptToEnd()
{
    if (shouldDelayEnd()) {
        m_endWasDelayed = true;
        return;
    }
    prepareToStopParsing();
}

void HTMLDocumentParser::endIfDelayed()
{
    // If we've already been detached, don't bother ending.
    if (isDetached())
        return;

    if (!m_endWasDelayed || shouldDelayEnd())
        return;

    m_endWasDelayed = false;
    prepareToStopParsing();
}

bool HTMLDocumentParser::isExecutingScript() const
{
    // TODO(eseidel): Callers may need updates now that scripts can be async.
    return m_scriptRunner && m_scriptRunner->isExecutingScript();
}

OrdinalNumber HTMLDocumentParser::lineNumber() const
{
    ASSERT(m_haveBackgroundParser);
    return m_textPosition.m_line;
}

TextPosition HTMLDocumentParser::textPosition() const
{
    ASSERT(m_haveBackgroundParser);
    return m_textPosition;
}

bool HTMLDocumentParser::isWaitingForScripts() const
{
  return m_treeBuilder->hasParserBlockingScript() || m_scriptRunner ||
         !document()->haveImportsLoaded();
}

void HTMLDocumentParser::resumeAfterWaitingForImports()
{
    RefPtr<HTMLDocumentParser> protect(this);
    ASSERT(!isWaitingForScripts());
    if (m_pendingChunks.isEmpty())
        return;
    ASSERT(m_haveBackgroundParser);
    pumpPendingChunks();
}

// HTMLScriptRunner has finished executing a script.
// Just call resumeAfterWaitingForImports since it happens to do what we need.
void HTMLDocumentParser::scriptExecutionCompleted() {
  ASSERT(m_scriptRunner);
  m_scriptRunner.clear();
  // To avoid re-entering the parser for synchronous scripts, we use a postTask.
  base::MessageLoop::current()->PostTask(
      FROM_HERE, base::Bind(&HTMLDocumentParser::resumeAfterWaitingForImports,
                            m_weakFactory.GetWeakPtr()));
}
}
