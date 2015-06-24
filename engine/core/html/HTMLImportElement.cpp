// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/html/HTMLImportElement.h"

#include "gen/sky/core/EventTypeNames.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/events/Event.h"
#include "sky/engine/core/fetch/FetchRequest.h"
#include "sky/engine/core/html/imports/HTMLImportChild.h"
#include "sky/engine/core/html/imports/HTMLImportsController.h"

namespace blink {

HTMLImportElement::HTMLImportElement(Document& document)
    : HTMLElement(HTMLNames::importTag, document)
    , m_child(nullptr)
{
}

HTMLImportElement::~HTMLImportElement()
{
    if (m_child) {
        m_child->clearClient();
        m_child = nullptr;
    }
}

PassRefPtr<HTMLImportElement> HTMLImportElement::create(Document& document)
{
    return adoptRef(new HTMLImportElement(document));
}

void HTMLImportElement::insertedInto(ContainerNode* insertionPoint)
{
    HTMLElement::insertedInto(insertionPoint);
    if (!insertionPoint->inDocument() || isInShadowTree())
        return;

    if (shouldLoad())
        load();
}

bool HTMLImportElement::shouldLoad() const
{
    return document().frame() || document().importsController();
}

void HTMLImportElement::load()
{
    if (m_child || !hasAttribute(HTMLNames::srcAttr))
        return;
    KURL url = document().completeURL(getAttribute(HTMLNames::srcAttr));
    m_child = document().ensureImportsController().load(document().import(), this, FetchRequest(ResourceRequest(url)));

    if (m_child)
        m_child->ownerInserted();
}

void HTMLImportElement::didFinish()
{
    dispatchEvent(Event::create(EventTypeNames::load));
}

void HTMLImportElement::importChildWasDestroyed(HTMLImportChild* child)
{
    ASSERT(m_child == child);
    m_child = nullptr;
}

bool HTMLImportElement::isSync() const
{
    return !hasAttribute(HTMLNames::asyncAttr);
}

Element* HTMLImportElement::link()
{
    return this;
}

}
