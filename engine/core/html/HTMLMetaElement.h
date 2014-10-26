/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
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
 *
 */

#ifndef HTMLMetaElement_h
#define HTMLMetaElement_h

#include "core/html/HTMLElement.h"

namespace blink {

class HTMLMetaElement final : public HTMLElement {
    DEFINE_WRAPPERTYPEINFO();
public:
    DECLARE_NODE_FACTORY(HTMLMetaElement);

    const AtomicString& content() const;
    const AtomicString& httpEquiv() const;
    const AtomicString& name() const;

private:
    explicit HTMLMetaElement(Document&);

    virtual void parseAttribute(const QualifiedName&, const AtomicString&) override;
    virtual InsertionNotificationRequest insertedInto(ContainerNode*) override;
    virtual void didNotifySubtreeInsertionsToDocument() override;

    void process();
};

} // namespace blink

#endif // HTMLMetaElement_h
