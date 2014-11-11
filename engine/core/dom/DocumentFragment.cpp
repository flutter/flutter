/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2009 Apple Inc. All rights reserved.
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
#include "core/dom/DocumentFragment.h"

#include "core/dom/Document.h"
#include "core/html/parser/HTMLDocumentParser.h"

namespace blink {

DocumentFragment::DocumentFragment(Document* document, ConstructionType constructionType)
    : ContainerNode(document, constructionType)
{
}

PassRefPtr<DocumentFragment> DocumentFragment::create(Document& document)
{
    return adoptRef(new DocumentFragment(&document, Node::CreateDocumentFragment));
}

String DocumentFragment::nodeName() const
{
    return "#document-fragment";
}

Node::NodeType DocumentFragment::nodeType() const
{
    return DOCUMENT_FRAGMENT_NODE;
}

bool DocumentFragment::childTypeAllowed(NodeType type) const
{
    switch (type) {
        case ELEMENT_NODE:
        case TEXT_NODE:
            return true;
        default:
            return false;
    }
}

PassRefPtr<Node> DocumentFragment::cloneNode(bool deep)
{
    RefPtr<DocumentFragment> clone = create(document());
    if (deep)
        cloneChildNodes(clone.get());
    return clone.release();
}

} // namespace blink
