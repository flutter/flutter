// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/html/HTMLImportElement.h"

#include "core/dom/Document.h"
#include "core/html/imports/HTMLImportsController.h"
#include "core/html/imports/HTMLImportChild.h"

namespace blink {

HTMLImportElement::HTMLImportElement(Document& document)
    : HTMLElement(HTMLNames::importTag, document)
    , m_child(nullptr)
{
    ScriptWrappable::init(this);
}

PassRefPtr<HTMLImportElement> HTMLImportElement::create(Document& document)
{
    return adoptRef(new HTMLImportElement(document));
}

Node::InsertionNotificationRequest HTMLImportElement::insertedInto(ContainerNode* insertionPoint)
{
    HTMLElement::insertedInto(insertionPoint);
    if (!insertionPoint->inDocument() || isInShadowTree())
        return InsertionDone;

    if (shouldLoad())
        load();

    return InsertionDone;
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
}

void HTMLImportElement::importChildWasDestroyed(HTMLImportChild* child)
{
    ASSERT(m_child == child);
    m_child = nullptr;
}

bool HTMLImportElement::isSync() const
{
    return true;
}

Element* HTMLImportElement::link()
{
    return this;
}

}
