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

#include "config.h"
#include "core/html/parser/HTMLDocumentParser.h"

#include "base/bind.h"
#include "core/HTMLNames.h"
#include "core/css/MediaValuesCached.h"
#include "core/dom/Element.h"
#include "core/frame/LocalFrame.h"
#include "core/html/HTMLDocument.h"
#include "core/html/HTMLScriptElement.h"
#include "core/html/parser/AtomicHTMLToken.h"
#include "core/html/parser/BackgroundHTMLParser.h"
#include "core/html/parser/HTMLParserScheduler.h"
#include "core/html/parser/HTMLParserThread.h"
#include "core/html/parser/HTMLTreeBuilder.h"
#include "core/inspector/InspectorTraceEvents.h"
#include "platform/SharedBuffer.h"
#include "platform/TraceEvent.h"

namespace blink {

HTMLDocumentParser::HTMLDocumentParser(HTMLDocument& document, bool reportErrors)
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
#if ENABLE(OILPAN)
    if (m_haveBackgroundParser)
        stopBackgroundParser();
    // In Oilpan, HTMLDocumentParser can die together with Document, and
    // detach() is not called in this case.
#else
    ASSERT(!m_parserScheduler);
    ASSERT(!m_pumpSessionNestingLevel);
    ASSERT(!m_haveBackgroundParser);
    // FIXME: We should be able to ASSERT(m_speculations.isEmpty()),
    // but there are cases where that's not true currently. For example,
    // we we're told to stop parsing before we've consumed all the input.
#endif
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
    pumpPendingSpeculations();
}

void HTMLDocumentParser::runScriptsForPausedTreeBuilder()
{
    if (m_isFragment)
        return;
    TextPosition scriptStartPosition = TextPosition::belowRangePosition();
    RefPtr<Element> scriptToProcess = m_treeBuilder->takeScriptToProcess(scriptStartPosition);
    m_scriptRunner.runScript(toHTMLScriptElement(scriptToProcess.get()), scriptStartPosition);
}

void HTMLDocumentParser::didReceiveParsedChunkFromBackgroundParser(PassOwnPtr<ParsedChunk> chunk)
{
    TRACE_EVENT0("blink", "HTMLDocumentParser::didReceiveParsedChunkFromBackgroundParser");

    // alert(), runModalDialog, and the JavaScript Debugger all run nested event loops
    // which can cause this method to be re-entered. We detect re-entry using
    // hasActiveParser(), save the chunk as a speculation, and return.
    if (isWaitingForScripts() || !m_speculations.isEmpty() || document()->activeParserCount() > 0) {
        m_speculations.append(chunk);
        return;
    }

    // processParsedChunkFromBackgroundParser can cause this parser to be detached from the Document,
    // but we need to ensure it isn't deleted yet.
    RefPtr<HTMLDocumentParser> protect(this);

    ASSERT(m_speculations.isEmpty());
    m_speculations.append(chunk);
    pumpPendingSpeculations();
}

void HTMLDocumentParser::validateSpeculations(PassOwnPtr<ParsedChunk> chunk)
{
    ASSERT(chunk);
    if (isWaitingForScripts()) {
        // We're waiting on a network script, just save the chunk, we'll get
        // a second validateSpeculations call after the script completes.
        // This call should have been made immediately after runScriptsForPausedTreeBuilder
        // which may have started a network load and left us waiting.
        ASSERT(!m_lastChunkBeforeScript);
        m_lastChunkBeforeScript = chunk;
        return;
    }
}

void HTMLDocumentParser::processParsedChunkFromBackgroundParser(PassOwnPtr<ParsedChunk> popChunk)
{
    TRACE_EVENT0("blink", "HTMLDocumentParser::processParsedChunkFromBackgroundParser");

    ASSERT_WITH_SECURITY_IMPLICATION(!document()->activeParserCount());
    ASSERT(!isParsingFragment());
    ASSERT(!isWaitingForScripts());
    ASSERT(!isStopped());
#if !ENABLE(OILPAN)
    // ASSERT that this object is both attached to the Document and protected.
    ASSERT(refCount() >= 2);
#endif
    ASSERT(!m_lastChunkBeforeScript);

    ActiveParserSession session(contextForParsingSession());

    OwnPtr<ParsedChunk> chunk(popChunk);
    OwnPtr<CompactHTMLTokenStream> tokens = chunk->tokens.release();

    for (Vector<CompactHTMLToken>::const_iterator it = tokens->begin(); it != tokens->end(); ++it) {
        ASSERT(!isWaitingForScripts());

        m_textPosition = it->textPosition();

        constructTreeFromCompactHTMLToken(*it);

        if (isStopped())
            break;

        if (isWaitingForScripts()) {
            ASSERT(it + 1 == tokens->end()); // The </script> is assumed to be the last token of this bunch.
            runScriptsForPausedTreeBuilder();
            validateSpeculations(chunk.release());
            break;
        }

        if (it->type() == HTMLToken::EndOfFile) {
            ASSERT(it + 1 == tokens->end()); // The EOF is assumed to be the last token of this bunch.
            ASSERT(m_speculations.isEmpty()); // There should never be any chunks after the EOF.
            prepareToStopParsing();
            break;
        }
    }

    // Make sure any pending text nodes are emitted before returning.
    if (!isStopped())
        m_treeBuilder->flush();
}

void HTMLDocumentParser::pumpPendingSpeculations()
{
    // FIXME: Share this constant with the parser scheduler.
    const double parserTimeLimit = 0.500;

#if !ENABLE(OILPAN)
    // ASSERT that this object is both attached to the Document and protected.
    ASSERT(refCount() >= 2);
#endif
    ASSERT(!m_lastChunkBeforeScript);
    ASSERT(!isWaitingForScripts());
    ASSERT(!isStopped());

    // FIXME: Pass in current input length.
    TRACE_EVENT_BEGIN1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "ParseHTML", "beginData", InspectorParseHtmlEvent::beginData(document(), lineNumber().zeroBasedInt()));
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline.stack"), "CallStack", TRACE_EVENT_SCOPE_PROCESS, "stack", InspectorCallStackEvent::currentCallStack());

    double startTime = currentTime();

    while (!m_speculations.isEmpty()) {
        processParsedChunkFromBackgroundParser(m_speculations.takeFirst());

        // Always check isStopped first as m_document may be null.
        if (isStopped() || isWaitingForScripts())
            break;

        if (currentTime() - startTime > parserTimeLimit && !m_speculations.isEmpty()) {
            m_parserScheduler->scheduleForResume();
            break;
        }
    }

    TRACE_EVENT_END1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "ParseHTML", "endLine", lineNumber().zeroBasedInt());
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "UpdateCounters", TRACE_EVENT_SCOPE_PROCESS, "data", InspectorUpdateCountersEvent::data());
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

void HTMLDocumentParser::startBackgroundParser()
{
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
    return m_scriptRunner.isExecutingScript();
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
    return m_treeBuilder->hasParserBlockingScript() || m_scriptRunner.hasPendingScripts();
}

void HTMLDocumentParser::resumeParsingAfterScriptExecution()
{
    ASSERT(!isExecutingScript());
    ASSERT(!isWaitingForScripts());
    ASSERT(m_haveBackgroundParser);

    validateSpeculations(m_lastChunkBeforeScript.release());
    ASSERT(!m_lastChunkBeforeScript);
    // processParsedChunkFromBackgroundParser can cause this parser to be detached from the Document,
    // but we need to ensure it isn't deleted yet.
    RefPtr<HTMLDocumentParser> protect(this);
    pumpPendingSpeculations();
}

void HTMLDocumentParser::executeScriptsWaitingForResources()
{
    if (!m_scriptRunner.hasPendingScripts())
        return;
    RefPtr<HTMLDocumentParser> protect(this);
    m_scriptRunner.executePendingScripts();
    if (!isWaitingForScripts())
        resumeParsingAfterScriptExecution();
}

}
