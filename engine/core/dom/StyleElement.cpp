/*
 * Copyright (C) 2006, 2007 Rob Buis
 * Copyright (C) 2008 Apple, Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#include "config.h"
#include "core/dom/StyleElement.h"

#include "bindings/core/v8/ScriptController.h"
#include "core/css/MediaList.h"
#include "core/css/MediaQueryEvaluator.h"
#include "core/css/StyleSheetContents.h"
#include "core/dom/Document.h"
#include "core/dom/Element.h"
#include "core/dom/StyleEngine.h"
#include "core/frame/LocalFrame.h"
#include "core/html/HTMLStyleElement.h"
#include "core/html/parser/HTMLDocumentParser.h"
#include "platform/TraceEvent.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

static bool isCSS(Element* element, const AtomicString& type)
{
    return type.isEmpty() || (element->isHTMLElement() ? equalIgnoringCase(type, "text/css") : (type == "text/css"));
}

StyleElement::StyleElement(Document* document, bool createdByParser)
    : m_createdByParser(createdByParser)
    , m_loading(false)
    , m_registeredAsCandidate(false)
    , m_startPosition(TextPosition::belowRangePosition())
{
    if (createdByParser)
        m_startPosition = document->parserPosition();
}

StyleElement::~StyleElement()
{
#if !ENABLE(OILPAN)
    if (m_sheet)
        clearSheet();
#endif
}

void StyleElement::processStyleSheet(Document& document, Element* element)
{
    TRACE_EVENT0("blink", "StyleElement::processStyleSheet");
    ASSERT(element);
    ASSERT(element->inDocument());

    m_registeredAsCandidate = true;
    document.styleEngine()->addStyleSheetCandidateNode(element, m_createdByParser);
    if (m_createdByParser)
        return;

    process(element);
}

void StyleElement::removedFromDocument(Document& document, Element* element)
{
    removedFromDocument(document, element, 0, document);
}

void StyleElement::removedFromDocument(Document& document, Element* element, ContainerNode* scopingNode, TreeScope& treeScope)
{
    ASSERT(element);

    if (m_registeredAsCandidate) {
        document.styleEngine()->removeStyleSheetCandidateNode(element, scopingNode, treeScope);
        m_registeredAsCandidate = false;
    }

    RefPtr<StyleSheet> removedSheet = m_sheet.get();

    if (m_sheet)
        clearSheet(element);
    if (removedSheet)
        document.removedStyleSheet(removedSheet.get(), AnalyzedStyleUpdate);
}

void StyleElement::clearDocumentData(Document& document, Element* element)
{
    if (m_sheet)
        m_sheet->clearOwnerNode();

    if (element->inDocument()) {
        ContainerNode* scopingNode = isHTMLStyleElement(element) ? toHTMLStyleElement(element)->scopingNode() :  0;
        TreeScope& treeScope = scopingNode ? scopingNode->treeScope() : element->treeScope();
        document.styleEngine()->removeStyleSheetCandidateNode(element, scopingNode, treeScope);
    }
}

void StyleElement::childrenChanged(Element* element)
{
    ASSERT(element);
    if (m_createdByParser)
        return;

    process(element);
}

void StyleElement::finishParsingChildren(Element* element)
{
    ASSERT(element);
    process(element);
    m_createdByParser = false;
}

void StyleElement::process(Element* element)
{
    if (!element || !element->inDocument())
        return;
    createSheet(element, element->textFromChildren());
}

void StyleElement::clearSheet(Element* ownerElement)
{
    ASSERT(m_sheet);
    m_sheet.release()->clearOwnerNode();
}

void StyleElement::createSheet(Element* e, const String& text)
{
    ASSERT(e);
    ASSERT(e->inDocument());
    Document& document = e->document();
    if (m_sheet)
        clearSheet(e);

    // If type is empty or CSS, this is a CSS style sheet.
    const AtomicString& type = this->type();
    if (isCSS(e, type)) {
        RefPtr<MediaQuerySet> mediaQueries = MediaQuerySet::create(media());

        MediaQueryEvaluator screenEval("screen", true);
        MediaQueryEvaluator printEval("print", true);
        if (screenEval.eval(mediaQueries.get()) || printEval.eval(mediaQueries.get())) {
            m_loading = true;
            TextPosition startPosition = m_startPosition == TextPosition::belowRangePosition() ? TextPosition::minimumPosition() : m_startPosition;
            m_sheet = document.styleEngine()->createSheet(e, text, startPosition, m_createdByParser);
            m_sheet->setMediaQueries(mediaQueries.release());
            m_loading = false;
        }
    }


    document.styleResolverMayHaveChanged();
}

void StyleElement::trace(Visitor* visitor)
{
    visitor->trace(m_sheet);
}

}
