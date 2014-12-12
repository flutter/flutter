/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2010 Apple Inc. All rights reserved.
 *           (C) 2007 Rob Buis (buis@kde.org)
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

#include "sky/engine/config.h"
#include "sky/engine/core/html/HTMLStyleElement.h"

#include "gen/sky/core/HTMLNames.h"
#include "sky/engine/core/css/MediaList.h"
#include "sky/engine/core/css/MediaQueryEvaluator.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/StyleEngine.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/platform/TraceEvent.h"

namespace blink {

inline HTMLStyleElement::HTMLStyleElement(Document& document)
    : HTMLElement(HTMLNames::styleTag, document)
    , m_loading(false)
    , m_registeredAsCandidate(false)
{
}

HTMLStyleElement::~HTMLStyleElement()
{
    clearDocumentData();
    if (m_sheet)
        clearSheet();
}

PassRefPtr<HTMLStyleElement> HTMLStyleElement::create(Document& document)
{
    return adoptRef(new HTMLStyleElement(document));
}

void HTMLStyleElement::parseAttribute(const QualifiedName& name, const AtomicString& value)
{
    if (name == HTMLNames::mediaAttr && inDocument() && document().isActive() && m_sheet) {
        m_sheet->setMediaQueries(MediaQuerySet::create(value));
        document().modifiedStyleSheet(m_sheet.get());
    } else {
        HTMLElement::parseAttribute(name, value);
    }
}

void HTMLStyleElement::insertedInto(ContainerNode* insertionPoint)
{
    HTMLElement::insertedInto(insertionPoint);

    if (!inDocument())
        return;

    processStyleSheet();

    if (ShadowRoot* scope = containingShadowRoot())
        scope->registerScopedHTMLStyleChild();
}

void HTMLStyleElement::removedFrom(ContainerNode* insertionPoint)
{
    HTMLElement::removedFrom(insertionPoint);

    if (!insertionPoint->inDocument())
        return;

    ShadowRoot* scopingNode = containingShadowRoot();
    if (!scopingNode)
        scopingNode = insertionPoint->containingShadowRoot();

    if (scopingNode)
        scopingNode->unregisterScopedHTMLStyleChild();

    TreeScope* containingScope = containingShadowRoot();
    TreeScope& scope = containingScope ? *containingScope : insertionPoint->treeScope();

    if (m_registeredAsCandidate) {
        document().styleEngine()->removeStyleSheetCandidateNode(this, scopingNode, scope);
        m_registeredAsCandidate = false;
    }

    RefPtr<CSSStyleSheet> removedSheet = m_sheet.get();

    if (m_sheet)
        clearSheet();
    if (removedSheet)
        document().removedStyleSheet(removedSheet.get());
}

void HTMLStyleElement::childrenChanged(const ChildrenChange& change)
{
    HTMLElement::childrenChanged(change);
    process();
}

const AtomicString& HTMLStyleElement::media() const
{
    return getAttribute(HTMLNames::mediaAttr);
}

ContainerNode* HTMLStyleElement::scopingNode()
{
    if (!inDocument())
        return 0;

    if (isInShadowTree())
        return containingShadowRoot();

    return &document();
}

void HTMLStyleElement::process()
{
    if (!inDocument())
        return;
    createSheet();
}

void HTMLStyleElement::clearSheet()
{
    ASSERT(m_sheet);
    m_sheet.release()->clearOwnerNode();
}

void HTMLStyleElement::createSheet()
{
    ASSERT(inDocument());

    if (m_sheet)
        clearSheet();

    RefPtr<MediaQuerySet> mediaQueries = MediaQuerySet::create(media());

    MediaQueryEvaluator screenEval("screen", true);
    MediaQueryEvaluator printEval("print", true);
    if (screenEval.eval(mediaQueries.get()) || printEval.eval(mediaQueries.get())) {
        m_loading = true;
        const String& text = textFromChildren();
        m_sheet = document().styleEngine()->createSheet(this, text);
        m_sheet->setMediaQueries(mediaQueries.release());
        m_loading = false;
    }

    document().styleResolverChanged();
}

void HTMLStyleElement::clearDocumentData()
{
    if (m_sheet)
        m_sheet->clearOwnerNode();

    if (inDocument()) {
        ContainerNode* scopingNode = this->scopingNode();
        TreeScope& scope = scopingNode ? scopingNode->treeScope() : treeScope();
        document().styleEngine()->removeStyleSheetCandidateNode(this, scopingNode, scope);
    }
}

void HTMLStyleElement::processStyleSheet()
{
    TRACE_EVENT0("blink", "StyleElement::processStyleSheet");

    ASSERT(inDocument());

    m_registeredAsCandidate = true;
    document().styleEngine()->addStyleSheetCandidateNode(this, false);
    process();
}

}
