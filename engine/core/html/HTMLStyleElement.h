/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003, 2010 Apple Inc. ALl rights reserved.
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

#ifndef HTMLStyleElement_h
#define HTMLStyleElement_h

#include "core/dom/StyleElement.h"
#include "core/html/HTMLElement.h"

namespace blink {

class HTMLStyleElement;

template<typename T> class EventSender;
typedef EventSender<HTMLStyleElement> StyleEventSender;

class HTMLStyleElement final : public HTMLElement, private StyleElement {
    DEFINE_WRAPPERTYPEINFO();
    WILL_BE_USING_GARBAGE_COLLECTED_MIXIN(HTMLStyleElement);
public:
    static PassRefPtr<HTMLStyleElement> create(Document&, bool createdByParser);
    virtual ~HTMLStyleElement();

    ContainerNode* scopingNode();

    using StyleElement::sheet;

    virtual void trace(Visitor*) override;

private:
    HTMLStyleElement(Document&, bool createdByParser);

    // overload from HTMLElement
    virtual void parseAttribute(const QualifiedName&, const AtomicString&) override;
    virtual InsertionNotificationRequest insertedInto(ContainerNode*) override;
    virtual void didNotifySubtreeInsertionsToDocument() override;
    virtual void removedFrom(ContainerNode*) override;
    virtual void childrenChanged(const ChildrenChange&) override;

    virtual void finishParsingChildren() override;

    virtual const AtomicString& media() const override;
    virtual const AtomicString& type() const override;
};

} // namespace blink

#endif // HTMLStyleElement_h
