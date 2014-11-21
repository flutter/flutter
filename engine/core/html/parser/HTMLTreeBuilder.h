/*
 * Copyright (C) 2010 Google, Inc. All Rights Reserved.
 * Copyright (C) 2011 Apple Inc. All rights reserved.
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

#ifndef HTMLTreeBuilder_h
#define HTMLTreeBuilder_h

#include "sky/engine/core/html/parser/HTMLConstructionSite.h"
#include "sky/engine/core/html/parser/HTMLElementStack.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/Noncopyable.h"
#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/engine/wtf/Vector.h"
#include "sky/engine/wtf/text/StringBuilder.h"
#include "sky/engine/wtf/text/TextPosition.h"

namespace blink {

class AtomicHTMLToken;
class Document;
class DocumentFragment;
class Element;
class LocalFrame;
class HTMLToken;
class HTMLDocument;
class Node;
class HTMLDocumentParser;

class HTMLTreeBuilder final {
    WTF_MAKE_NONCOPYABLE(HTMLTreeBuilder); WTF_MAKE_FAST_ALLOCATED;
public:
    static PassOwnPtr<HTMLTreeBuilder> create(HTMLDocumentParser* parser, HTMLDocument* document, bool reportErrors)
    {
        return adoptPtr(new HTMLTreeBuilder(parser, document, reportErrors));
    }
    ~HTMLTreeBuilder();

    const HTMLElementStack* openElements() const { return m_tree.openElements(); }

    bool isParsingFragment() const { return !!m_fragmentContext.fragment(); }

    void detach();

    void constructTree(AtomicHTMLToken*);

    bool hasParserBlockingScript() const { return !!m_scriptToProcess; }
    // Must be called to take the parser-blocking script before calling the parser again.
    PassRefPtr<Element> takeScriptToProcess(TextPosition& scriptStartPosition);

    // Done, close any open tags, etc.
    void finished();

    // Synchronously empty any queues, possibly creating more DOM nodes.
    void flush() { m_tree.flush(); }

private:
    class CharacterTokenBuffer;
    // Represents HTML5 "insertion mode"
    // http://www.whatwg.org/specs/web-apps/current-work/multipage/parsing.html#insertion-mode
    enum InsertionMode {
        HTMLMode,
        TextMode,
    };

    HTMLTreeBuilder(HTMLDocumentParser*, HTMLDocument*, bool reportErrors);

    void processStartTag(AtomicHTMLToken*);
    void processEndTag(AtomicHTMLToken*);
    void processCharacter(AtomicHTMLToken*);
    void processEndOfFile(AtomicHTMLToken*);

    void processGenericRawTextStartTag(AtomicHTMLToken*);
    void processScriptStartTag(AtomicHTMLToken*);

    InsertionMode insertionMode() const { return m_insertionMode; }
    void setInsertionMode(InsertionMode mode) { m_insertionMode = mode; }

    class FragmentParsingContext {
        WTF_MAKE_NONCOPYABLE(FragmentParsingContext);
        DISALLOW_ALLOCATION();
    public:
        FragmentParsingContext();
        FragmentParsingContext(DocumentFragment*, Element* contextElement);
        ~FragmentParsingContext();

        DocumentFragment* fragment() const { return m_fragment; }

    private:
        RawPtr<DocumentFragment> m_fragment;
    };

#if ENABLE(ASSERT)
    bool m_isAttached;
#endif
    FragmentParsingContext m_fragmentContext;
    HTMLConstructionSite m_tree;

    // http://www.whatwg.org/specs/web-apps/current-work/multipage/parsing.html#insertion-mode
    InsertionMode m_insertionMode;

    // http://www.whatwg.org/specs/web-apps/current-work/multipage/parsing.html#original-insertion-mode
    InsertionMode m_originalInsertionMode;

    // We access parser because HTML5 spec requires that we be able to change the state of the tokenizer
    // from within parser actions. We also need it to track the current position.
    RawPtr<HTMLDocumentParser> m_parser;

    RefPtr<Element> m_scriptToProcess; // <script> tag which needs processing before resuming the parser.
    TextPosition m_scriptToProcessStartPosition; // Starting line number of the script tag needing processing.
};

}

#endif
