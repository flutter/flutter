/*
 * Copyright (C) 2010 Google, Inc. All Rights Reserved.
 * Copyright (C) 2011, 2014 Apple Inc. All rights reserved.
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
#include "core/html/parser/HTMLTreeBuilder.h"

#include "bindings/core/v8/ExceptionStatePlaceholder.h"
#include "core/HTMLNames.h"
#include "core/dom/DocumentFragment.h"
#include "core/html/HTMLDocument.h"
#include "core/html/HTMLTemplateElement.h"
#include "core/html/parser/AtomicHTMLToken.h"
#include "core/html/parser/HTMLDocumentParser.h"
#include "core/html/parser/HTMLParserIdioms.h"
#include "core/html/parser/HTMLStackItem.h"
#include "core/html/parser/HTMLToken.h"
#include "core/html/parser/HTMLTokenizer.h"

namespace blink {

static TextPosition uninitializedPositionValue1()
{
    return TextPosition(OrdinalNumber::fromOneBasedInt(-1), OrdinalNumber::first());
}

HTMLTreeBuilder::HTMLTreeBuilder(HTMLDocumentParser* parser, HTMLDocument* document, ParserContentPolicy parserContentPolicy, bool, const HTMLParserOptions& options)
    :
#if ENABLE(ASSERT)
      m_isAttached(true),
#endif
      m_tree(document, parserContentPolicy)
    , m_insertionMode(HTMLMode)
    , m_originalInsertionMode(HTMLMode)
    , m_parser(parser)
    , m_scriptToProcessStartPosition(uninitializedPositionValue1())
    , m_options(options)
{
    m_tree.openElements()->pushRootNode(HTMLStackItem::create(document, HTMLStackItem::ItemForContextElement));
}

// FIXME: Member variables should be grouped into self-initializing structs to
// minimize code duplication between these constructors.
HTMLTreeBuilder::HTMLTreeBuilder(HTMLDocumentParser* parser, DocumentFragment* fragment, Element* contextElement, ParserContentPolicy parserContentPolicy, const HTMLParserOptions& options)
    :
#if ENABLE(ASSERT)
     m_isAttached(true),
#endif
     m_fragmentContext(fragment, contextElement)
    , m_tree(fragment, parserContentPolicy)
    , m_insertionMode(HTMLMode)
    , m_originalInsertionMode(HTMLMode)
    , m_parser(parser)
    , m_scriptToProcessStartPosition(uninitializedPositionValue1())
    , m_options(options)
{
    ASSERT(isMainThread());
    ASSERT(contextElement);

    // Steps 4.2-4.6 of the HTML5 Fragment Case parsing algorithm:
    // http://www.whatwg.org/specs/web-apps/current-work/multipage/the-end.html#fragment-case
    // For efficiency, we skip step 4.2 ("Let root be a new html element with no attributes")
    // and instead use the DocumentFragment as a root node.
    m_tree.openElements()->pushRootNode(HTMLStackItem::create(fragment, HTMLStackItem::ItemForDocumentFragmentNode));
}

HTMLTreeBuilder::~HTMLTreeBuilder()
{
}

void HTMLTreeBuilder::trace(Visitor* visitor)
{
    visitor->trace(m_fragmentContext);
    visitor->trace(m_tree);
    visitor->trace(m_parser);
    visitor->trace(m_scriptToProcess);
}

void HTMLTreeBuilder::detach()
{
#if ENABLE(ASSERT)
    // This call makes little sense in fragment mode, but for consistency
    // DocumentParser expects detach() to always be called before it's destroyed.
    m_isAttached = false;
#endif
    // HTMLConstructionSite might be on the callstack when detach() is called
    // otherwise we'd just call m_tree.clear() here instead.
    m_tree.detach();
}

HTMLTreeBuilder::FragmentParsingContext::FragmentParsingContext()
    : m_fragment(nullptr)
{
}

HTMLTreeBuilder::FragmentParsingContext::FragmentParsingContext(DocumentFragment* fragment, Element* contextElement)
    : m_fragment(fragment)
{
    ASSERT(!fragment->hasChildren());
    m_contextElementStackItem = HTMLStackItem::create(contextElement, HTMLStackItem::ItemForContextElement);
}

HTMLTreeBuilder::FragmentParsingContext::~FragmentParsingContext()
{
}

void HTMLTreeBuilder::FragmentParsingContext::trace(Visitor* visitor)
{
    visitor->trace(m_fragment);
    visitor->trace(m_contextElementStackItem);
}

PassRefPtrWillBeRawPtr<Element> HTMLTreeBuilder::takeScriptToProcess(TextPosition& scriptStartPosition)
{
    ASSERT(m_scriptToProcess);
    ASSERT(!m_tree.hasPendingTasks());
    // Unpause ourselves, callers may pause us again when processing the script.
    // The HTML5 spec is written as though scripts are executed inside the tree
    // builder.  We pause the parser to exit the tree builder, and then resume
    // before running scripts.
    scriptStartPosition = m_scriptToProcessStartPosition;
    m_scriptToProcessStartPosition = uninitializedPositionValue1();
    return m_scriptToProcess.release();
}

void HTMLTreeBuilder::constructTree(AtomicHTMLToken* token)
{
    const HTMLToken::Type type = token->type();

    if (type == HTMLToken::Character) {
        processCharacter(token);
        return;
    }

    // Any non-character token needs to cause us to flush any pending text immediately.
    // NOTE: flush() can cause any queued tasks to execute, possibly re-entering the parser.
    m_tree.flush();

    if (type == HTMLToken::StartTag) {
        processStartTag(token);
    } else if (type == HTMLToken::EndTag) {
        processEndTag(token);
    } else if (type == HTMLToken::EndOfFile) {
        processEndOfFile(token);
    } else {
        // We ignore Comments.
        ASSERT(type == HTMLToken::Comment);
    }

    m_tree.executeQueuedTasks();
    // We might be detached now.
}

void HTMLTreeBuilder::processStartTag(AtomicHTMLToken* token)
{
    ASSERT(token->type() == HTMLToken::StartTag);
    const AtomicString& name = token->name();

    if (name == HTMLNames::styleTag) {
        processGenericRawTextStartTag(token);
    } else if (name == HTMLNames::scriptTag) {
        processScriptStartTag(token);
    } else if (token->selfClosing()) {
        m_tree.insertSelfClosingHTMLElement(token);
    } else {
        m_tree.insertHTMLElement(token);
    }
}

void HTMLTreeBuilder::processEndTag(AtomicHTMLToken* token)
{
    ASSERT(token->type() == HTMLToken::EndTag);

    const InsertionMode mode = insertionMode();
    if (mode == HTMLMode) {
        HTMLElementStack::ElementRecord* record = m_tree.openElements()->topRecord();
        while (record->next()) {
            RefPtrWillBeRawPtr<HTMLStackItem> item = record->stackItem();
            if (item->hasLocalName(token->name())) {
                m_tree.openElements()->popUntilPopped(item->element());
                ASSERT(m_tree.openElements()->topNode());
                return;
            }
            record = record->next();
        }
        return;
    }

    ASSERT(mode == TextMode);
    if (token->name() == HTMLNames::scriptTag) {
        // Pause ourselves so that parsing stops until the script can be processed by the caller.
        ASSERT(m_tree.currentStackItem()->hasLocalName(HTMLNames::scriptTag.localName()));
        if (scriptingContentIsAllowed(m_tree.parserContentPolicy()))
            m_scriptToProcess = m_tree.currentElement();
        m_tree.openElements()->pop();
        setInsertionMode(m_originalInsertionMode);

        if (m_parser->tokenizer()) {
            // We must set the tokenizer's state to
            // DataState explicitly if the tokenizer didn't have a chance to.
            ASSERT(m_parser->tokenizer()->state() == HTMLTokenizer::DataState || m_options.useThreading);
            m_parser->tokenizer()->setState(HTMLTokenizer::DataState);
        }
        return;
    }
    m_tree.openElements()->pop();
    setInsertionMode(m_originalInsertionMode);
}

void HTMLTreeBuilder::processCharacter(AtomicHTMLToken* token)
{
    ASSERT(token->type() == HTMLToken::Character);
    m_tree.insertTextNode(token->characters());
}

void HTMLTreeBuilder::processEndOfFile(AtomicHTMLToken* token)
{
    ASSERT(token->type() == HTMLToken::EndOfFile);
    m_tree.processEndOfFile();
}

void HTMLTreeBuilder::processGenericRawTextStartTag(AtomicHTMLToken* token)
{
    ASSERT(token->type() == HTMLToken::StartTag);
    m_tree.insertHTMLElement(token);
    if (m_parser->tokenizer())
        m_parser->tokenizer()->setState(HTMLTokenizer::RAWTEXTState);
    m_originalInsertionMode = m_insertionMode;
    setInsertionMode(TextMode);
}

void HTMLTreeBuilder::processScriptStartTag(AtomicHTMLToken* token)
{
    ASSERT(token->type() == HTMLToken::StartTag);
    m_tree.insertScriptElement(token);
    if (m_parser->tokenizer())
        m_parser->tokenizer()->setState(HTMLTokenizer::ScriptDataState);
    m_originalInsertionMode = m_insertionMode;
    TextPosition position = m_parser->textPosition();
    m_scriptToProcessStartPosition = position;
    setInsertionMode(TextMode);
}

void HTMLTreeBuilder::finished()
{
    if (isParsingFragment())
        return;
    ASSERT(m_isAttached);
    // Warning, this may detach the parser. Do not do anything else after this.
    m_tree.finishedParsing();
}

} // namespace blink
