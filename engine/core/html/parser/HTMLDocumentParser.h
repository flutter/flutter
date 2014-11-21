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

#ifndef SKY_ENGINE_CORE_HTML_PARSER_HTMLDOCUMENTPARSER_H_
#define SKY_ENGINE_CORE_HTML_PARSER_HTMLDOCUMENTPARSER_H_

#include "base/callback.h"
#include "base/memory/weak_ptr.h"
#include "sky/engine/core/dom/DocumentParser.h"
#include "sky/engine/core/fetch/ResourceClient.h"
#include "sky/engine/core/frame/UseCounter.h"
#include "sky/engine/core/html/parser/CompactHTMLToken.h"
#include "sky/engine/core/html/parser/HTMLInputStream.h"
#include "sky/engine/core/html/parser/HTMLScriptRunner.h"
#include "sky/engine/core/html/parser/HTMLToken.h"
#include "sky/engine/core/html/parser/HTMLTokenizer.h"
#include "sky/engine/core/html/parser/TextResourceDecoder.h"
#include "sky/engine/platform/text/SegmentedString.h"
#include "sky/engine/wtf/Deque.h"
#include "sky/engine/wtf/OwnPtr.h"
#include "sky/engine/wtf/WeakPtr.h"
#include "sky/engine/wtf/text/TextPosition.h"

namespace blink {

class BackgroundHTMLParser;
class CompactHTMLToken;
class Document;
class Element;
class HTMLDocument;
class HTMLParserScheduler;
class HTMLTreeBuilder;
class ScriptController;
class ScriptSourceCode;

class PumpSession;

class HTMLDocumentParser :  public DocumentParser {
    WTF_MAKE_FAST_ALLOCATED;
public:
    static PassRefPtr<HTMLDocumentParser> create(HTMLDocument& document, bool reportErrors)
    {
        return adoptRef(new HTMLDocumentParser(document, reportErrors));
    }
    virtual ~HTMLDocumentParser();

    void parse(mojo::ScopedDataPipeConsumerHandle,
               const base::Closure& completionCallback) override;

    // Exposed for HTMLParserScheduler
    void resumeParsingAfterYield();

    TextPosition textPosition() const;
    OrdinalNumber lineNumber() const;

    struct ParsedChunk {
        OwnPtr<CompactHTMLTokenStream> tokens;
    };
    void didReceiveParsedChunkFromBackgroundParser(PassOwnPtr<ParsedChunk>);

    // From DocumentParser:
    void detach() override final;
    void prepareToStopParsing() override final;
    void stopParsing() override final;
    bool isWaitingForScripts() const override final;
    bool isExecutingScript() const override final;
    void executeScriptsWaitingForResources() override final;

    UseCounter* useCounter() { return UseCounter::getFrom(contextForParsingSession()); }

private:
    HTMLDocumentParser(HTMLDocument&, bool reportErrors);

    HTMLTreeBuilder* treeBuilder() const { return m_treeBuilder.get(); }

    bool hasInsertionPoint();

    void startBackgroundParser();
    void stopBackgroundParser();
    void validateSpeculations(PassOwnPtr<ParsedChunk> lastChunk);
    void processParsedChunkFromBackgroundParser(PassOwnPtr<ParsedChunk>);
    void pumpPendingSpeculations();

    Document* contextForParsingSession();

    void constructTreeFromHTMLToken(HTMLToken&);
    void constructTreeFromCompactHTMLToken(const CompactHTMLToken&);

    void runScriptsForPausedTreeBuilder();
    void resumeParsingAfterScriptExecution();

    void attemptToEnd();
    void endIfDelayed();
    void end();

    bool isParsingFragment() const;
    bool isScheduledForResume() const;
    bool inPumpSession() const { return m_pumpSessionNestingLevel > 0; }
    bool shouldDelayEnd() const { return inPumpSession() || isWaitingForScripts() || isScheduledForResume() || isExecutingScript(); }

    OwnPtr<HTMLTreeBuilder> m_treeBuilder;
    OwnPtr<HTMLParserScheduler> m_parserScheduler;
    TextPosition m_textPosition;

    HTMLScriptRunner m_scriptRunner;

    OwnPtr<ParsedChunk> m_lastChunkBeforeScript;
    Deque<OwnPtr<ParsedChunk> > m_speculations;
    base::WeakPtrFactory<HTMLDocumentParser> m_weakFactory;
    base::WeakPtr<BackgroundHTMLParser> m_backgroundParser;

    base::Closure m_completionCallback;

    bool m_isFragment;
    bool m_endWasDelayed;
    bool m_haveBackgroundParser;
    unsigned m_pumpSessionNestingLevel;
};

}

#endif  // SKY_ENGINE_CORE_HTML_PARSER_HTMLDOCUMENTPARSER_H_
