/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Peter Kelly (pmk@post.com)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
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
 *
 */

#ifndef Attr_h
#define Attr_h

#include "core/dom/Node.h"
#include "core/dom/QualifiedName.h"

namespace blink {

class Attr FINAL : public Node {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtrWillBeRawPtr<Attr> create(Element&, const QualifiedName&);
    virtual ~Attr();

    String name() const { return m_name.localName(); }
    Element* ownerElement() const { return m_element; }

    const AtomicString& value() const;
    void setValue(const AtomicString&);

    void detachFromElement();

    // FIXME(sky): Remove this.
    virtual const AtomicString& localName() const OVERRIDE { return m_name.localName(); }

    virtual void trace(Visitor*) OVERRIDE;

private:
    Attr(Element&, const QualifiedName&);

    bool isElementNode() const WTF_DELETED_FUNCTION; // This will catch anyone doing an unnecessary check.

    virtual String nodeName() const OVERRIDE { return name(); }
    virtual NodeType nodeType() const OVERRIDE { return ATTRIBUTE_NODE; }

    virtual PassRefPtrWillBeRawPtr<Node> cloneNode(bool deep = true) OVERRIDE { return nullptr; }

    virtual bool isAttributeNode() const OVERRIDE { return true; }

    RawPtrWillBeMember<Element> m_element;
    QualifiedName m_name;
};

DEFINE_NODE_TYPE_CASTS(Attr, isAttributeNode());

} // namespace blink

#endif // Attr_h
