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

#include "config.h"
#include "core/html/parser/HTMLConstructionSite.h"

#include "core/HTMLElementFactory.h"
#include "core/dom/DocumentFragment.h"
#include "core/dom/Element.h"
#include "core/dom/Text.h"
#include "core/frame/LocalFrame.h"
#include "core/html/HTMLScriptElement.h"
#include "core/html/HTMLTemplateElement.h"
#include "core/html/parser/AtomicHTMLToken.h"
#include "core/html/parser/HTMLParserIdioms.h"
#include "core/html/parser/HTMLToken.h"
#include "core/loader/FrameLoaderClient.h"
#include "platform/NotImplemented.h"
#include "platform/text/TextBreakIterator.h"
#include <limits>

namespace blink {

static const unsigned maximumHTMLParserDOMTreeDepth = 512;

static inline void setAttributes(Element* element, AtomicHTMLToken* token)
{
    element->stripScriptingAttributes(token->attributes());
    element->parserSetAttributes(token->attributes());
}

static bool shouldUseLengthLimit(const ContainerNode& node)
{
    return !isHTMLScriptElement(node)
        && !isHTMLStyleElement(node);
}

static unsigned textLengthLimitForContainer(const ContainerNode& node)
{
    return shouldUseLengthLimit(node) ? Text::defaultLengthLimit : std::numeric_limits<unsigned>::max();
}

static inline bool isAllWhitespace(const String& string)
{
    return string.isAllSpecialCharacters<isHTMLSpace<UChar> >();
}

static inline void insert(HTMLConstructionSiteTask& task)
{
    if (isHTMLTemplateElement(*task.parent))
        task.parent = toHTMLTemplateElement(task.parent.get())->content();

    if (ContainerNode* parent = task.child->parentNode())
        parent->parserRemoveChild(*task.child);

    if (task.nextChild)
        task.parent->parserInsertBefore(task.child.get(), *task.nextChild);
    else
        task.parent->parserAppendChild(task.child.get());
}

static inline void executeInsertTask(HTMLConstructionSiteTask& task)
{
    ASSERT(task.operation == HTMLConstructionSiteTask::Insert);

    insert(task);

    if (task.child->isElementNode()) {
        Element& child = toElement(*task.child);
        child.beginParsingChildren();
        if (task.selfClosing)
            child.finishParsingChildren();
    }
}

static inline void executeInsertTextTask(HTMLConstructionSiteTask& task)
{
    ASSERT(task.operation == HTMLConstructionSiteTask::InsertText);
    ASSERT(task.child->isTextNode());

    // Merge text nodes into previous ones if possible:
    // http://www.whatwg.org/specs/web-apps/current-work/multipage/tree-construction.html#insert-a-character
    Text* newText = toText(task.child.get());
    Node* previousChild = task.nextChild ? task.nextChild->previousSibling() : task.parent->lastChild();
    if (previousChild && previousChild->isTextNode()) {
        Text* previousText = toText(previousChild);
        unsigned lengthLimit = textLengthLimitForContainer(*task.parent);
        if (previousText->length() + newText->length() < lengthLimit) {
            previousText->parserAppendData(newText->data());
            return;
        }
    }

    insert(task);
}

static inline void executeTask(HTMLConstructionSiteTask& task)
{
    if (task.operation == HTMLConstructionSiteTask::Insert)
        return executeInsertTask(task);

    ASSERT(task.operation == HTMLConstructionSiteTask::InsertText);
    return executeInsertTextTask(task);
}

// This is only needed for TextDocuments where we might have text nodes
// approaching the default length limit (~64k) and we don't want to
// break a text node in the middle of a combining character.
static unsigned findBreakIndexBetween(const StringBuilder& string, unsigned currentPosition, unsigned proposedBreakIndex)
{
    ASSERT(currentPosition < proposedBreakIndex);
    ASSERT(proposedBreakIndex <= string.length());
    // The end of the string is always a valid break.
    if (proposedBreakIndex == string.length())
        return proposedBreakIndex;

    // Latin-1 does not have breakable boundaries. If we ever moved to a differnet 8-bit encoding this could be wrong.
    if (string.is8Bit())
        return proposedBreakIndex;

    const UChar* breakSearchCharacters = string.characters16() + currentPosition;
    // We need at least two characters look-ahead to account for UTF-16 surrogates, but can't search off the end of the buffer!
    unsigned breakSearchLength = std::min(proposedBreakIndex - currentPosition + 2, string.length() - currentPosition);
    NonSharedCharacterBreakIterator it(breakSearchCharacters, breakSearchLength);

    if (it.isBreak(proposedBreakIndex - currentPosition))
        return proposedBreakIndex;

    int adjustedBreakIndexInSubstring = it.preceding(proposedBreakIndex - currentPosition);
    if (adjustedBreakIndexInSubstring > 0)
        return currentPosition + adjustedBreakIndexInSubstring;
    // We failed to find a breakable point, let the caller figure out what to do.
    return 0;
}

static String atomizeIfAllWhitespace(const String& string, WhitespaceMode whitespaceMode)
{
    // Strings composed entirely of whitespace are likely to be repeated.
    // Turn them into AtomicString so we share a single string for each.
    if (whitespaceMode == AllWhitespace || (whitespaceMode == WhitespaceUnknown && isAllWhitespace(string)))
        return AtomicString(string).string();
    return string;
}

void HTMLConstructionSite::flushPendingText()
{
    if (m_pendingText.isEmpty())
        return;

    PendingText pendingText;
    // Hold onto the current pending text on the stack so that queueTask doesn't recurse infinitely.
    m_pendingText.swap(pendingText);
    ASSERT(m_pendingText.isEmpty());

    // Splitting text nodes into smaller chunks contradicts HTML5 spec, but is necessary
    // for performance, see: https://bugs.webkit.org/show_bug.cgi?id=55898
    unsigned lengthLimit = textLengthLimitForContainer(*pendingText.parent);

    unsigned currentPosition = 0;
    const StringBuilder& string = pendingText.stringBuilder;
    while (currentPosition < string.length()) {
        unsigned proposedBreakIndex = std::min(currentPosition + lengthLimit, string.length());
        unsigned breakIndex = findBreakIndexBetween(string, currentPosition, proposedBreakIndex);
        ASSERT(breakIndex <= string.length());
        String substring = string.substring(currentPosition, breakIndex - currentPosition);
        substring = atomizeIfAllWhitespace(substring, pendingText.whitespaceMode);

        HTMLConstructionSiteTask task(HTMLConstructionSiteTask::InsertText);
        task.parent = pendingText.parent;
        task.nextChild = pendingText.nextChild;
        task.child = Text::create(task.parent->document(), substring);
        queueTask(task);

        ASSERT(breakIndex > currentPosition);
        ASSERT(breakIndex - currentPosition == substring.length());
        ASSERT(toText(task.child.get())->length() == substring.length());
        currentPosition = breakIndex;
    }
}

void HTMLConstructionSite::queueTask(const HTMLConstructionSiteTask& task)
{
    flushPendingText();
    ASSERT(m_pendingText.isEmpty());
    m_taskQueue.append(task);
}

void HTMLConstructionSite::attachLater(ContainerNode* parent, PassRefPtr<Node> prpChild, bool selfClosing)
{
    HTMLConstructionSiteTask task(HTMLConstructionSiteTask::Insert);
    task.parent = parent;
    task.child = prpChild;
    task.selfClosing = selfClosing;

    // Add as a sibling of the parent if we have reached the maximum depth allowed.
    if (m_openElements.stackDepth() > maximumHTMLParserDOMTreeDepth && task.parent->parentNode())
        task.parent = task.parent->parentNode();

    ASSERT(task.parent);
    queueTask(task);
}

void HTMLConstructionSite::executeQueuedTasks()
{
    // This has no affect on pendingText, and we may have pendingText
    // remaining after executing all other queued tasks.
    const size_t size = m_taskQueue.size();
    if (!size)
        return;

    // Copy the task queue into a local variable in case executeTask
    // re-enters the parser.
    TaskQueue queue;
    queue.swap(m_taskQueue);

    for (size_t i = 0; i < size; ++i)
        executeTask(queue[i]);

    // We might be detached now.
}

HTMLConstructionSite::HTMLConstructionSite(Document* document)
    : m_document(document)
    , m_attachmentRoot(document)
{
}

HTMLConstructionSite::HTMLConstructionSite(DocumentFragment* fragment)
    : m_document(&fragment->document())
    , m_attachmentRoot(fragment)
{
}

HTMLConstructionSite::~HTMLConstructionSite()
{
    // Depending on why we're being destroyed it might be OK
    // to forget queued tasks, but currently we don't expect to.
    ASSERT(m_taskQueue.isEmpty());
    // Currently we assume that text will never be the last token in the
    // document and that we'll always queue some additional task to cause it to flush.
    ASSERT(m_pendingText.isEmpty());
}

void HTMLConstructionSite::trace(Visitor* visitor)
{
    visitor->trace(m_document);
    visitor->trace(m_attachmentRoot);
    visitor->trace(m_taskQueue);
    visitor->trace(m_pendingText);
}

void HTMLConstructionSite::detach()
{
    // FIXME: We'd like to ASSERT here that we're canceling and not just discarding
    // text that really should have made it into the DOM earlier, but there
    // doesn't seem to be a nice way to do that.
    m_pendingText.discard();
    m_document = nullptr;
    m_attachmentRoot = nullptr;
}

void HTMLConstructionSite::processEndOfFile()
{
    flush();
    openElements()->popAll();
}

void HTMLConstructionSite::finishedParsing()
{
    // We shouldn't have any queued tasks but we might have pending text which we need to promote to tasks and execute.
    ASSERT(m_taskQueue.isEmpty());
    flush();
    m_document->finishedParsing();
}

void HTMLConstructionSite::insertHTMLElement(AtomicHTMLToken* token)
{
    RefPtr<HTMLElement> element = createHTMLElement(token);
    attachLater(currentNode(), element);
    m_openElements.push(element.release());
}

void HTMLConstructionSite::insertSelfClosingHTMLElement(AtomicHTMLToken* token)
{
    ASSERT(token->type() == HTMLToken::StartTag);
    // Normally HTMLElementStack is responsible for calling finishParsingChildren,
    // but self-closing elements are never in the element stack so the stack
    // doesn't get a chance to tell them that we're done parsing their children.
    attachLater(currentNode(), createHTMLElement(token), true);
    // FIXME: Do we want to acknowledge the token's self-closing flag?
    // http://www.whatwg.org/specs/web-apps/current-work/multipage/tokenization.html#acknowledge-self-closing-flag
}

void HTMLConstructionSite::insertScriptElement(AtomicHTMLToken* token)
{
    RefPtr<HTMLScriptElement> element = HTMLScriptElement::create(ownerDocumentForCurrentNode());
    setAttributes(element.get(), token);
    attachLater(currentNode(), element);
    m_openElements.push(element.release());
}

void HTMLConstructionSite::insertTextNode(const String& string, WhitespaceMode whitespaceMode)
{
    HTMLConstructionSiteTask dummyTask(HTMLConstructionSiteTask::Insert);
    dummyTask.parent = currentNode();

    // FIXME: This probably doesn't need to be done both here and in insert(Task).
    if (isHTMLTemplateElement(*dummyTask.parent))
        dummyTask.parent = toHTMLTemplateElement(dummyTask.parent.get())->content();

    // Unclear when parent != case occurs. Somehow we insert text into two separate nodes while processing the same Token.
    // The nextChild != dummy.nextChild case occurs whenever foster parenting happened and we hit a new text node "<table>a</table>b"
    // In either case we have to flush the pending text into the task queue before making more.
    if (!m_pendingText.isEmpty() && (m_pendingText.parent != dummyTask.parent ||  m_pendingText.nextChild != dummyTask.nextChild))
        flushPendingText();
    m_pendingText.append(dummyTask.parent, dummyTask.nextChild, string, whitespaceMode);
}

PassRefPtr<Element> HTMLConstructionSite::createElement(AtomicHTMLToken* token, const AtomicString& namespaceURI)
{
    QualifiedName tagName(token->name());
    RefPtr<Element> element = ownerDocumentForCurrentNode().createElement(tagName, true);
    setAttributes(element.get(), token);
    return element.release();
}

inline Document& HTMLConstructionSite::ownerDocumentForCurrentNode()
{
    if (isHTMLTemplateElement(*currentNode()))
        return toHTMLTemplateElement(currentElement())->content()->document();
    return currentNode()->document();
}

PassRefPtr<HTMLElement> HTMLConstructionSite::createHTMLElement(AtomicHTMLToken* token)
{
    Document& document = ownerDocumentForCurrentNode();
    RefPtr<HTMLElement> element = HTMLElementFactory::createHTMLElement(token->name(), document, true);
    setAttributes(element.get(), token);
    return element.release();
}

void HTMLConstructionSite::PendingText::trace(Visitor* visitor)
{
    visitor->trace(parent);
    visitor->trace(nextChild);
}

}
