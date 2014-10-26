/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2010 Apple Inc. All rights reserved.
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
#include "core/html/HTMLMetaElement.h"

#include "core/HTMLNames.h"
#include "core/dom/Document.h"
#include "core/dom/ElementTraversal.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "core/inspector/ConsoleMessage.h"
#include "core/loader/FrameLoaderClient.h"
#include "platform/RuntimeEnabledFeatures.h"

namespace blink {

inline HTMLMetaElement::HTMLMetaElement(Document& document)
    : HTMLElement(HTMLNames::metaTag, document)
{
    ScriptWrappable::init(this);
}

DEFINE_NODE_FACTORY(HTMLMetaElement)

void HTMLMetaElement::parseAttribute(const QualifiedName& name, const AtomicString& value)
{
    if (name == HTMLNames::http_equivAttr || name == HTMLNames::contentAttr) {
        process();
        return;
    }

    if (name != HTMLNames::nameAttr)
        HTMLElement::parseAttribute(name, value);
}

Node::InsertionNotificationRequest HTMLMetaElement::insertedInto(ContainerNode* insertionPoint)
{
    HTMLElement::insertedInto(insertionPoint);
    return InsertionShouldCallDidNotifySubtreeInsertions;
}

void HTMLMetaElement::didNotifySubtreeInsertionsToDocument()
{
    process();
}

void HTMLMetaElement::process()
{
    if (!inDocument())
        return;

    // All below situations require a content attribute (which can be the empty string).
    const AtomicString& contentValue = getAttribute(HTMLNames::contentAttr);
    if (contentValue.isNull())
        return;

    const AtomicString& nameValue = getAttribute(HTMLNames::nameAttr);
    if (!nameValue.isEmpty() && equalIgnoringCase(nameValue, "referrer"))
        document().processReferrerPolicy(contentValue);

    // Get the document to process the tag, but only if we're actually part of DOM
    // tree (changing a meta tag while it's not in the tree shouldn't have any effect
    // on the document).

    const AtomicString& httpEquivValue = getAttribute(HTMLNames::http_equivAttr);
    if (!httpEquivValue.isEmpty())
        document().processHttpEquiv(httpEquivValue, contentValue, false);
}

const AtomicString& HTMLMetaElement::content() const
{
    return getAttribute(HTMLNames::contentAttr);
}

const AtomicString& HTMLMetaElement::httpEquiv() const
{
    return getAttribute(HTMLNames::http_equivAttr);
}

const AtomicString& HTMLMetaElement::name() const
{
    return getAttribute(HTMLNames::nameAttr);
}

}
