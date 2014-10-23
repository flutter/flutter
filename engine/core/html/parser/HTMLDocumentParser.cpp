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
#include "core/dom/DocumentFragment.h"
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
#include "wtf/Functional.h"

namespace blink {

// This is a direct transcription of step 4 from:
// http://www.whatwg.org/specs/web-apps/current-work/multipage/the-end.html#fragment-case
static HTMLTokenizer::State tokenizerStateForContextElement(Element* contextElement, bool reportErrors, const HTMLParserOptions& options)
{
    if (!contextElement)
        return HTMLTokenizer::DataState;

    const QualifiedName& contextTag = contextElement->tagQName();

    if (contextTag == HTMLNames::styleTag)
        return HTMLTokenizer::RAWTEXTState;
    if (contextTag == HTMLNames::scriptTag)
        return HTMLTokenizer::ScriptDataState;
    return HTMLTokenizer::DataState;
}

HTMLDocumentParser::HTMLDocumentParser(HTMLDocument& document, bool reportErrors)
    : ScriptableDocumentParser(document)
    , m_options(&document)
    , m_token(m_options.useThreading ? nullptr : adoptPtr(new HTMLToken))
    , m_tokenizer(m_options.useThreading ? nullptr : HTMLTokenizer::create(m_options))
    , m_treeBuilder(HTMLTreeBuilder::create(this, &document, parserContentPolicy(), reportErrors, m_options))
    , m_parserScheduler(HTMLParserScheduler::create(this))
    , m_weakFactory(this)
    , m_isFragment(false)
    , m_endWasDelayed(false)
    , m_haveBackgroundParser(false)
    , m_pumpSessionNestingLevel(0)
{
    ASSERT(shouldUseThreading() || (m_token && m_tokenizer));
}

// FIXME: Member variables should be grouped into self-initializing structs to
// minimize code duplication between these constructors.
HTMLDocumentParser::HTMLDocumentParser(DocumentFragment* fragment, Element* contextElement, ParserContentPolicy parserContentPolicy)
    : ScriptableDocumentParser(fragment->document(), parserContentPolicy)
    , m_options(&fragment->document())
    , m_token(adoptPtr(new HTMLToken))
    , m_tokenizer(HTMLTokenizer::create(m_options))
    , m_treeBuilder(HTMLTreeBuilder::create(this, fragment, contextElement, this->parserContentPolicy(), m_options))
    , m_weakFactory(this)
    , m_isFragment(true)
    , m_endWasDelayed(false)
    , m_haveBackgroundParser(false)
    , m_pumpSessionNestingLevel(0)
{
    ASSERT(!shouldUseThreading());
    bool reportErrors = false; // For now document fragment parsing never reports errors.
    m_tokenizer->setState(tokenizerStateForContextElement(contextElement, reportErrors, m_options));
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

void HTMLDocumentParser::trace(Visitor* visitor)
{
    visitor->trace(m_treeBuilder);
    ScriptableDocumentParser::trace(visitor);
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
    RefPtrWillBeRawPtr<HTMLDocumentParser> protect(this);

    // NOTE: This pump should only ever emit buffered character tokens,
    // so ForceSynchronous vs. AllowYield should be meaningless.
    if (m_tokenizer) {
        ASSERT(!m_haveBackgroundParser);
        pumpTokenizerIfPossible(ForceSynchronous);
    }

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

bool HTMLDocumentParser::processingData() const
{
    return isScheduledForResume() || inPumpSession() || m_haveBackgroundParser;
}

void HTMLDocumentParser::pumpTokenizerIfPossible(SynchronousMode mode)
{
    if (isStopped())
        return;
    if (isWaitingForScripts())
        return;

    // Once a resume is scheduled, HTMLParserScheduler controls when we next pump.
    if (isScheduledForResume()) {
        ASSERT(mode == AllowYield);
        return;
    }

    pumpTokenizer(mode);
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
    RefPtrWillBeRawPtr<HTMLDocumentParser> protect(this);

    if (m_haveBackgroundParser) {
        pumpPendingSpeculations();
        return;
    }

    // We should never be here unless we can pump immediately.  Call pumpTokenizer()
    // directly so that ASSERTS will fire if we're wrong.
    pumpTokenizer(AllowYield);
    endIfDelayed();
}

void HTMLDocumentParser::runScriptsForPausedTreeBuilder()
{
    ASSERT(scriptingContentIsAllowed(parserContentPolicy()));
    if (m_isFragment)
        return;
    TextPosition scriptStartPosition = TextPosition::belowRangePosition();
    RefPtrWillBeRawPtr<Element> scriptToProcess = m_treeBuilder->takeScriptToProcess(scriptStartPosition);
    m_scriptRunner.runScript(toHTMLScriptElement(scriptToProcess.get()), scriptStartPosition);
}

bool HTMLDocumentParser::canTakeNextToken(SynchronousMode mode, PumpSession& session)
{
    if (isStopped())
        return false;

    ASSERT(!m_haveBackgroundParser || mode == ForceSynchronous);

    if (isWaitingForScripts()) {
        if (mode == AllowYield)
            session.didSeeScript = true;

        // If we don't run the script, we cannot allow the next token to be taken.
        if (session.needsYield)
            return false;

        // If we're paused waiting for a script, we try to execute scripts before continuing.
        runScriptsForPausedTreeBuilder();
        if (isStopped())
            return false;
        if (isWaitingForScripts())
            return false;
    }

    if (mode == AllowYield)
        m_parserScheduler->checkForYieldBeforeToken(session);

    return true;
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
    RefPtrWillBeRawPtr<HTMLDocumentParser> protect(this);

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
    ASSERT(shouldUseThreading());
    ASSERT(!m_tokenizer);
    ASSERT(!m_token);
    ASSERT(!m_lastChunkBeforeScript);

    ActiveParserSession session(contextForParsingSession());

    OwnPtr<ParsedChunk> chunk(popChunk);
    OwnPtr<CompactHTMLTokenStream> tokens = chunk->tokens.release();

    HTMLParserThread::taskRunner()->PostTask(FROM_HERE,
        base::Bind(&BackgroundHTMLParser::startedChunkWithCheckpoint, m_backgroundParser, chunk->inputCheckpoint));

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

        ASSERT(!m_tokenizer);
        ASSERT(!m_token);
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
    // If this assert fails, you need to call validateSpeculations to make sure
    // m_tokenizer and m_token don't have state that invalidates m_speculations.
    ASSERT(!m_tokenizer);
    ASSERT(!m_token);
    ASSERT(!m_lastChunkBeforeScript);
    ASSERT(!isWaitingForScripts());
    ASSERT(!isStopped());

    // FIXME: Pass in current input length.
    TRACE_EVENT_BEGIN1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "ParseHTML", "beginData", InspectorParseHtmlEvent::beginData(document(), lineNumber().zeroBasedInt()));
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline.stack"), "CallStack", "stack", InspectorCallStackEvent::currentCallStack());

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
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "UpdateCounters", "data", InspectorUpdateCountersEvent::data());
}

Document* HTMLDocumentParser::contextForParsingSession()
{
    // The parsing session should interact with the document only when parsing
    // non-fragments. Otherwise, we might delay the load event mistakenly.
    if (isParsingFragment())
        return 0;
    return document();
}

void HTMLDocumentParser::pumpTokenizer(SynchronousMode mode)
{
    ASSERT(!isStopped());
    ASSERT(!isScheduledForResume());
#if !ENABLE(OILPAN)
    // ASSERT that this object is both attached to the Document and protected.
    ASSERT(refCount() >= 2);
#endif
    ASSERT(m_tokenizer);
    ASSERT(m_token);
    ASSERT(!m_haveBackgroundParser || mode == ForceSynchronous);

    PumpSession session(m_pumpSessionNestingLevel, contextForParsingSession());

    TRACE_EVENT_BEGIN1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "ParseHTML", "beginData", InspectorParseHtmlEvent::beginData(document(), m_input.current().currentLine().zeroBasedInt()));
    TRACE_EVENT_INSTANT1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline.stack"), "CallStack", "stack", InspectorCallStackEvent::currentCallStack());

    while (canTakeNextToken(mode, session) && !session.needsYield) {
        if (!m_tokenizer->nextToken(m_input.current(), token()))
            break;

        constructTreeFromHTMLToken(token());
        ASSERT(token().isUninitialized());
    }

#if !ENABLE(OILPAN)
    // Ensure we haven't been totally deref'ed after pumping. Any caller of this
    // function should be holding a RefPtr to this to ensure we weren't deleted.
    ASSERT(refCount() >= 1);
#endif

    if (isStopped())
        return;

    // There should only be PendingText left since the tree-builder always flushes
    // the task queue before returning. In case that ever changes, crash.
    if (mode == ForceSynchronous)
        m_treeBuilder->flush();
    RELEASE_ASSERT(!isStopped());

    if (session.needsYield)
        m_parserScheduler->scheduleForResume();

    TRACE_EVENT_END1(TRACE_DISABLED_BY_DEFAULT("devtools.timeline"), "ParseHTML", "endLine", m_input.current().currentLine().zeroBasedInt());
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
    return m_input.hasInsertionPoint();
}

void HTMLDocumentParser::insert(const SegmentedString& source)
{
    if (isStopped())
        return;

    TRACE_EVENT1("blink", "HTMLDocumentParser::insert", "source_length", source.length());

    // pumpTokenizer can cause this parser to be detached from the Document,
    // but we need to ensure it isn't deleted yet.
    RefPtrWillBeRawPtr<HTMLDocumentParser> protect(this);

    if (!m_tokenizer) {
        ASSERT(!inPumpSession());
        ASSERT(m_haveBackgroundParser);
        m_token = adoptPtr(new HTMLToken);
        m_tokenizer = HTMLTokenizer::create(m_options);
    }

    SegmentedString excludedLineNumberSource(source);
    excludedLineNumberSource.setExcludeLineNumbers();
    m_input.insertAtCurrentInsertionPoint(excludedLineNumberSource);
    pumpTokenizerIfPossible(ForceSynchronous);

    endIfDelayed();
}

void HTMLDocumentParser::startBackgroundParser()
{
    ASSERT(!isStopped());
    ASSERT(shouldUseThreading());
    ASSERT(!m_haveBackgroundParser);
    m_haveBackgroundParser = true;

    OwnPtr<BackgroundHTMLParser::Configuration> config = adoptPtr(new BackgroundHTMLParser::Configuration);
    config->options = m_options;
    config->parser = m_weakFactory.createWeakPtr();

    m_backgroundParser = BackgroundHTMLParser::create(config.release());
}

void HTMLDocumentParser::stopBackgroundParser()
{
    ASSERT(shouldUseThreading());
    ASSERT(m_haveBackgroundParser);
    m_haveBackgroundParser = false;

    HTMLParserThread::taskRunner()->PostTask(FROM_HERE,
        base::Bind(&BackgroundHTMLParser::stop, m_backgroundParser));
    m_weakFactory.revokeAll();
}

void HTMLDocumentParser::append(PassRefPtr<StringImpl> inputSource)
{
    if (isStopped())
        return;

    // We should never reach this point if we're using a parser thread,
    // as appendBytes() will directly ship the data to the thread.
    ASSERT(!shouldUseThreading());

    // pumpTokenizer can cause this parser to be detached from the Document,
    // but we need to ensure it isn't deleted yet.
    RefPtrWillBeRawPtr<HTMLDocumentParser> protect(this);
    TRACE_EVENT1("net", "HTMLDocumentParser::append", "size", inputSource->length());
    String source(inputSource);

    m_input.appendToEnd(source);

    if (inPumpSession()) {
        // We've gotten data off the network in a nested write.
        // We don't want to consume any more of the input stream now.  Do
        // not worry.  We'll consume this data in a less-nested write().
        return;
    }

    pumpTokenizerIfPossible(AllowYield);

    endIfDelayed();
}

void HTMLDocumentParser::end()
{
    ASSERT(!isDetached());
    ASSERT(!isScheduledForResume());

    if (m_haveBackgroundParser)
        stopBackgroundParser();

    // Informs the the rest of WebCore that parsing is really finished (and deletes this).
    m_treeBuilder->finished();
}

void HTMLDocumentParser::attemptToEnd()
{
    // finish() indicates we will not receive any more data. If we are waiting on
    // an external script to load, we can't finish parsing quite yet.

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

void HTMLDocumentParser::finish()
{
    // FIXME: We should ASSERT(!m_parserStopped) here, since it does not
    // makes sense to call any methods on DocumentParser once it's been stopped.
    // However, FrameLoader::stop calls DocumentParser::finish unconditionally.

    // flush may ending up executing arbitrary script, and possibly detach the parser.
    RefPtrWillBeRawPtr<HTMLDocumentParser> protect(this);
    flush();
    if (isDetached())
        return;

    // Empty documents never got an append() call, and thus have never started
    // a background parser. In those cases, we ignore shouldUseThreading()
    // and fall through to the non-threading case.
    if (m_haveBackgroundParser) {
        if (!m_input.haveSeenEndOfFile())
            m_input.closeWithoutMarkingEndOfFile();
        HTMLParserThread::taskRunner()->PostTask(FROM_HERE,
                base::Bind(&BackgroundHTMLParser::finish, m_backgroundParser));
        return;
    }

    if (!m_tokenizer) {
        ASSERT(!m_token);
        // We're finishing before receiving any data. Rather than booting up
        // the background parser just to spin it down, we finish parsing
        // synchronously.
        m_token = adoptPtr(new HTMLToken);
        m_tokenizer = HTMLTokenizer::create(m_options);
    }

    // We're not going to get any more data off the network, so we tell the
    // input stream we've reached the end of file. finish() can be called more
    // than once, if the first time does not call end().
    if (!m_input.haveSeenEndOfFile())
        m_input.markEndOfFile();

    attemptToEnd();
}

bool HTMLDocumentParser::isExecutingScript() const
{
    return m_scriptRunner.isExecutingScript();
}

OrdinalNumber HTMLDocumentParser::lineNumber() const
{
    if (m_haveBackgroundParser)
        return m_textPosition.m_line;

    return m_input.current().currentLine();
}

TextPosition HTMLDocumentParser::textPosition() const
{
    if (m_haveBackgroundParser)
        return m_textPosition;

    const SegmentedString& currentString = m_input.current();
    OrdinalNumber line = currentString.currentLine();
    OrdinalNumber column = currentString.currentColumn();

    return TextPosition(line, column);
}

bool HTMLDocumentParser::isWaitingForScripts() const
{
    return m_treeBuilder->hasParserBlockingScript() || m_scriptRunner.hasPendingScripts();
}

void HTMLDocumentParser::resumeParsingAfterScriptExecution()
{
    ASSERT(!isExecutingScript());
    ASSERT(!isWaitingForScripts());

    if (m_haveBackgroundParser) {
        validateSpeculations(m_lastChunkBeforeScript.release());
        ASSERT(!m_lastChunkBeforeScript);
        // processParsedChunkFromBackgroundParser can cause this parser to be detached from the Document,
        // but we need to ensure it isn't deleted yet.
        RefPtrWillBeRawPtr<HTMLDocumentParser> protect(this);
        pumpPendingSpeculations();
        return;
    }

    pumpTokenizerIfPossible(AllowYield);
    endIfDelayed();
}

void HTMLDocumentParser::executeScriptsWaitingForResources()
{
    if (!m_scriptRunner.hasPendingScripts())
        return;
    RefPtrWillBeRawPtr<HTMLDocumentParser> protect(this);
    m_scriptRunner.executePendingScripts();
    if (!isWaitingForScripts())
        resumeParsingAfterScriptExecution();
}

void HTMLDocumentParser::parseDocumentFragment(const String& source, DocumentFragment* fragment, Element* contextElement, ParserContentPolicy parserContentPolicy)
{
    RefPtrWillBeRawPtr<HTMLDocumentParser> parser = HTMLDocumentParser::create(fragment, contextElement, parserContentPolicy);
    parser->insert(source); // Use insert() so that the parser will not yield.
    parser->finish();
    ASSERT(!parser->processingData()); // Make sure we're done. <rdar://problem/3963151>
    parser->detach(); // Allows ~DocumentParser to assert it was detached before destruction.
}

void HTMLDocumentParser::appendBytes(const char* data, size_t length)
{
    if (!length || isStopped())
        return;

    if (shouldUseThreading()) {
        if (!m_haveBackgroundParser)
            startBackgroundParser();

        OwnPtr<Vector<char> > buffer = adoptPtr(new Vector<char>(length));
        memcpy(buffer->data(), data, length);
        TRACE_EVENT1("net", "HTMLDocumentParser::appendBytes", "size", (unsigned)length);

        HTMLParserThread::taskRunner()->PostTask(FROM_HERE,
            base::Bind(&BackgroundHTMLParser::appendRawBytesFromMainThread, m_backgroundParser, buffer.release()));
        return;
    }

    DecodedDataDocumentParser::appendBytes(data, length);
}

void HTMLDocumentParser::flush()
{
    // If we've got no decoder, we never received any data.
    if (isDetached())
        return;

    if (m_haveBackgroundParser) {
        HTMLParserThread::taskRunner()->PostTask(FROM_HERE,
            base::Bind(&BackgroundHTMLParser::flush, m_backgroundParser));
    } else {
        DecodedDataDocumentParser::flush();
    }
}

}
