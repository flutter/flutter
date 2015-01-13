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
#include "sky/engine/core/dom/StyleSheetCollection.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/platform/TraceEvent.h"

namespace blink {

inline HTMLStyleElement::HTMLStyleElement(Document& document)
    : HTMLElement(HTMLNames::styleTag, document)
{
}

HTMLStyleElement::~HTMLStyleElement()
{
    if (m_sheet)
        m_sheet->clearOwnerNode();
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
        document().styleResolverChanged();
    } else {
        HTMLElement::parseAttribute(name, value);
    }
}

void HTMLStyleElement::insertedInto(ContainerNode* insertionPoint)
{
    HTMLElement::insertedInto(insertionPoint);
    if (!inActiveDocument())
        return;
    treeScope().styleSheets().addStyleSheetCandidateNode(*this);
    process();
}

void HTMLStyleElement::removedFrom(ContainerNode* insertionPoint)
{
    HTMLElement::removedFrom(insertionPoint);

    if (!insertionPoint->inActiveDocument())
        return;

    TreeScope* containingScope = containingShadowRoot();
    TreeScope& scope = containingScope ? *containingScope : insertionPoint->treeScope();

    scope.styleSheets().removeStyleSheetCandidateNode(*this);

    RefPtr<CSSStyleSheet> removedSheet = m_sheet.get();

    if (m_sheet)
        clearSheet();
    if (removedSheet)
        document().styleResolverChanged();
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
    if (!inActiveDocument())
        return 0;

    if (isInShadowTree())
        return containingShadowRoot();

    return &document();
}

void HTMLStyleElement::clearSheet()
{
    ASSERT(m_sheet);
    m_sheet.release()->clearOwnerNode();
}

void HTMLStyleElement::process()
{
    if (!inActiveDocument())
        return;

    TRACE_EVENT0("blink", "StyleElement::process");

    if (m_sheet)
        clearSheet();

    RefPtr<MediaQuerySet> mediaQueries = MediaQuerySet::create(media());

    MediaQueryEvaluator screenEval("screen", true);
    if (screenEval.eval(mediaQueries.get())) {
        const String& text = textFromChildren();
        m_sheet = document().styleEngine()->createSheet(this, text);
        m_sheet->setMediaQueries(mediaQueries.release());
    }

    document().styleResolverChanged();
}

}
