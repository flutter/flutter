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

#ifndef HTMLConstructionSite_h
#define HTMLConstructionSite_h

#include "core/dom/Document.h"
#include "core/html/parser/HTMLElementStack.h"
#include "wtf/Noncopyable.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"
#include "wtf/Vector.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

struct HTMLConstructionSiteTask {
    ALLOW_ONLY_INLINE_ALLOCATION();
public:
    enum Operation {
        Insert,
        InsertText, // Handles possible merging of text nodes.
    };

    explicit HTMLConstructionSiteTask(Operation op)
        : operation(op)
        , selfClosing(false)
    {
    }

    void trace(Visitor* visitor)
    {
        visitor->trace(parent);
        visitor->trace(nextChild);
        visitor->trace(child);
    }

    Operation operation;
    RefPtr<ContainerNode> parent;
    RefPtr<Node> nextChild;
    RefPtr<Node> child;
    bool selfClosing;
};

} // namespace blink

WTF_ALLOW_MOVE_INIT_AND_COMPARE_WITH_MEM_FUNCTIONS(blink::HTMLConstructionSiteTask);

namespace blink {

// Note: These are intentionally ordered so that when we concatonate
// strings and whitespaces the resulting whitespace is ws = min(ws1, ws2).
enum WhitespaceMode {
    WhitespaceUnknown,
    NotAllWhitespace,
    AllWhitespace,
};

class AtomicHTMLToken;
class Document;
class Element;

class HTMLConstructionSite final {
    WTF_MAKE_NONCOPYABLE(HTMLConstructionSite);
    DISALLOW_ALLOCATION();
public:
    explicit HTMLConstructionSite(Document*);
    explicit HTMLConstructionSite(DocumentFragment*);
    ~HTMLConstructionSite();
    void trace(Visitor*);

    void detach();

    // executeQueuedTasks empties the queue but does not flush pending text.
    // NOTE: Possible reentrancy via JavaScript execution.
    void executeQueuedTasks();

    // flushPendingText turns pending text into queued Text insertions, but does not execute them.
    void flushPendingText();

    // Called before every token in HTMLTreeBuilder::processToken, thus inlined:
    void flush()
    {
        if (!hasPendingTasks())
            return;
        flushPendingText();
        executeQueuedTasks(); // NOTE: Possible reentrancy via JavaScript execution.
        ASSERT(!hasPendingTasks());
    }

    bool hasPendingTasks()
    {
        return !m_pendingText.isEmpty() || !m_taskQueue.isEmpty();
    }

    void processEndOfFile();
    void finishedParsing();

    void insertHTMLElement(AtomicHTMLToken*);
    void insertSelfClosingHTMLElement(AtomicHTMLToken*);
    void insertScriptElement(AtomicHTMLToken*);
    void insertTextNode(const String&, WhitespaceMode = WhitespaceUnknown);

    bool isEmpty() const { return !m_openElements.stackDepth(); }
    Element* currentElement() const { return m_openElements.top(); }
    ContainerNode* currentNode() const { return m_openElements.topNode(); }
    Document& ownerDocumentForCurrentNode();
    HTMLElementStack* openElements() const { return &m_openElements; }

private:
    // In the common case, this queue will have only one task because most
    // tokens produce only one DOM mutation.
    typedef Vector<HTMLConstructionSiteTask, 1> TaskQueue;

    void attachLater(ContainerNode* parent, PassRefPtr<Node> child, bool selfClosing = false);

    PassRefPtr<HTMLElement> createHTMLElement(AtomicHTMLToken*);
    PassRefPtr<Element> createElement(AtomicHTMLToken*, const AtomicString& namespaceURI);

    void queueTask(const HTMLConstructionSiteTask&);

    RawPtr<Document> m_document;

    // This is the root ContainerNode to which the parser attaches all newly
    // constructed nodes. It points to a DocumentFragment when parsing fragments
    // and a Document in all other cases.
    RawPtr<ContainerNode> m_attachmentRoot;

    mutable HTMLElementStack m_openElements;

    TaskQueue m_taskQueue;

    class PendingText {
        DISALLOW_ALLOCATION();
    public:
        PendingText()
            : whitespaceMode(WhitespaceUnknown)
        {
        }

        void append(PassRefPtr<ContainerNode> newParent, PassRefPtr<Node> newNextChild, const String& newString, WhitespaceMode newWhitespaceMode)
        {
            ASSERT(!parent || parent == newParent);
            parent = newParent;
            ASSERT(!nextChild || nextChild == newNextChild);
            nextChild = newNextChild;
            stringBuilder.append(newString);
            whitespaceMode = std::min(whitespaceMode, newWhitespaceMode);
        }

        void swap(PendingText& other)
        {
            std::swap(whitespaceMode, other.whitespaceMode);
            parent.swap(other.parent);
            nextChild.swap(other.nextChild);
            stringBuilder.swap(other.stringBuilder);
        }

        void discard()
        {
            PendingText discardedText;
            swap(discardedText);
        }

        bool isEmpty()
        {
            // When the stringbuilder is empty, the parent and whitespace should also be "empty".
            ASSERT(stringBuilder.isEmpty() == !parent);
            ASSERT(!stringBuilder.isEmpty() || !nextChild);
            ASSERT(!stringBuilder.isEmpty() || (whitespaceMode == WhitespaceUnknown));
            return stringBuilder.isEmpty();
        }

        void trace(Visitor*);

        RefPtr<ContainerNode> parent;
        RefPtr<Node> nextChild;
        StringBuilder stringBuilder;
        WhitespaceMode whitespaceMode;
    };

    PendingText m_pendingText;
};

} // namespace blink

#endif
