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

#ifndef HTMLDocumentParser_h
#define HTMLDocumentParser_h

#include "base/memory/weak_ptr.h"
#include "core/dom/DecodedDataDocumentParser.h"
#include "core/fetch/ResourceClient.h"
#include "core/frame/UseCounter.h"
#include "core/html/parser/CompactHTMLToken.h"
#include "core/html/parser/HTMLInputStream.h"
#include "core/html/parser/HTMLParserOptions.h"
#include "core/html/parser/HTMLScriptRunner.h"
#include "core/html/parser/HTMLToken.h"
#include "core/html/parser/HTMLTokenizer.h"
#include "core/html/parser/TextResourceDecoder.h"
#include "platform/text/SegmentedString.h"
#include "wtf/Deque.h"
#include "wtf/OwnPtr.h"
#include "wtf/WeakPtr.h"
#include "wtf/text/TextPosition.h"

namespace blink {

class BackgroundHTMLParser;
class CompactHTMLToken;
class Document;
class DocumentFragment;
class Element;
class HTMLDocument;
class HTMLParserScheduler;
class HTMLTreeBuilder;
class ScriptController;
class ScriptSourceCode;

class PumpSession;

class HTMLDocumentParser :  public DecodedDataDocumentParser {
    WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
    WILL_BE_USING_GARBAGE_COLLECTED_MIXIN(HTMLDocumentParser);
public:
    static PassRefPtrWillBeRawPtr<HTMLDocumentParser> create(HTMLDocument& document, bool reportErrors)
    {
        return adoptRefWillBeNoop(new HTMLDocumentParser(document, reportErrors));
    }
    virtual ~HTMLDocumentParser();
    virtual void trace(Visitor*) OVERRIDE;

    // Exposed for HTMLParserScheduler
    void resumeParsingAfterYield();

    static void parseDocumentFragment(const String&, DocumentFragment*, Element* contextElement);

    HTMLTokenizer* tokenizer() const { return m_tokenizer.get(); }

    TextPosition textPosition() const;
    OrdinalNumber lineNumber() const;

    struct ParsedChunk {
        OwnPtr<CompactHTMLTokenStream> tokens;
    };
    void didReceiveParsedChunkFromBackgroundParser(PassOwnPtr<ParsedChunk>);

    virtual void appendBytes(const char* bytes, size_t length) OVERRIDE;
    virtual void flush() OVERRIDE FINAL;

    bool isWaitingForScripts() const;
    bool isExecutingScript() const;
    void executeScriptsWaitingForResources();

    UseCounter* useCounter() { return UseCounter::getFrom(contextForParsingSession()); }

protected:
    virtual void insert(const SegmentedString&) OVERRIDE FINAL;
    virtual void append(PassRefPtr<StringImpl>) OVERRIDE;
    virtual void finish() OVERRIDE FINAL;

    HTMLDocumentParser(HTMLDocument&, bool reportErrors);
    HTMLDocumentParser(DocumentFragment*, Element* contextElement);

    HTMLTreeBuilder* treeBuilder() const { return m_treeBuilder.get(); }

private:
    static PassRefPtrWillBeRawPtr<HTMLDocumentParser> create(DocumentFragment* fragment, Element* contextElement)
    {
        return adoptRefWillBeNoop(new HTMLDocumentParser(fragment, contextElement));
    }

    virtual HTMLDocumentParser* asHTMLDocumentParser() OVERRIDE FINAL { return this; }

    // DocumentParser
    virtual void detach() OVERRIDE FINAL;
    virtual bool hasInsertionPoint() OVERRIDE FINAL;
    virtual bool processingData() const OVERRIDE FINAL;
    virtual void prepareToStopParsing() OVERRIDE FINAL;
    virtual void stopParsing() OVERRIDE FINAL;

    void startBackgroundParser();
    void stopBackgroundParser();
    void validateSpeculations(PassOwnPtr<ParsedChunk> lastChunk);
    void processParsedChunkFromBackgroundParser(PassOwnPtr<ParsedChunk>);
    void pumpPendingSpeculations();

    Document* contextForParsingSession();

    enum SynchronousMode {
        AllowYield,
        ForceSynchronous,
    };
    bool canTakeNextToken(SynchronousMode, PumpSession&);
    void pumpTokenizer(SynchronousMode);
    void pumpTokenizerIfPossible(SynchronousMode);
    void constructTreeFromHTMLToken(HTMLToken&);
    void constructTreeFromCompactHTMLToken(const CompactHTMLToken&);

    void runScriptsForPausedTreeBuilder();
    void resumeParsingAfterScriptExecution();

    void attemptToEnd();
    void endIfDelayed();
    void end();

    bool shouldUseThreading() const { return m_options.useThreading; }

    bool isParsingFragment() const;
    bool isScheduledForResume() const;
    bool inPumpSession() const { return m_pumpSessionNestingLevel > 0; }
    bool shouldDelayEnd() const { return inPumpSession() || isWaitingForScripts() || isScheduledForResume() || isExecutingScript(); }

    HTMLToken& token() { return *m_token; }

    HTMLParserOptions m_options;
    HTMLInputStream m_input;

    OwnPtr<HTMLToken> m_token;
    OwnPtr<HTMLTokenizer> m_tokenizer;
    OwnPtrWillBeMember<HTMLTreeBuilder> m_treeBuilder;
    OwnPtr<HTMLParserScheduler> m_parserScheduler;
    TextPosition m_textPosition;

    HTMLScriptRunner m_scriptRunner;

    // FIXME: m_lastChunkBeforeScript, m_tokenizer, m_token, and m_input should be combined into a single state object
    // so they can be set and cleared together and passed between threads together.
    OwnPtr<ParsedChunk> m_lastChunkBeforeScript;
    Deque<OwnPtr<ParsedChunk> > m_speculations;
    WeakPtrFactory<HTMLDocumentParser> m_weakFactory;
    base::WeakPtr<BackgroundHTMLParser> m_backgroundParser;

    bool m_isFragment;
    bool m_endWasDelayed;
    bool m_haveBackgroundParser;
    unsigned m_pumpSessionNestingLevel;
};

}

#endif
