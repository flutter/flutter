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

#ifndef SKY_ENGINE_CORE_HTML_HTMLSTYLEELEMENT_H_
#define SKY_ENGINE_CORE_HTML_HTMLSTYLEELEMENT_H_

#include "sky/engine/core/css/CSSStyleSheet.h"
#include "sky/engine/core/html/HTMLElement.h"
#include "sky/engine/wtf/text/TextPosition.h" 

namespace blink {

class ContainerNode;
class Document;

class HTMLStyleElement final : public HTMLElement {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<HTMLStyleElement> create(Document&);
    virtual ~HTMLStyleElement();

    ContainerNode* scopingNode();

    CSSStyleSheet* sheet() const { return m_sheet.get(); }

    const AtomicString& media() const;
    const AtomicString& type() const;

private:
    HTMLStyleElement(Document&);

    void createSheet();
    void process();
    void clearSheet();

    void processStyleSheet();
    void clearDocumentData();

    // overload from HTMLElement
    virtual void parseAttribute(const QualifiedName&, const AtomicString&) override;
    virtual void insertedInto(ContainerNode*) override;
    virtual void removedFrom(ContainerNode*) override;
    virtual void childrenChanged(const ChildrenChange&) override;

    RefPtr<CSSStyleSheet> m_sheet;

    bool m_loading : 1;
    bool m_registeredAsCandidate : 1;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_HTML_HTMLSTYLEELEMENT_H_
