/*
 * Copyright (C) 2006, 2007 Rob Buis
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

#ifndef StyleElement_h
#define StyleElement_h

#include "core/css/CSSStyleSheet.h"
#include "wtf/text/TextPosition.h"

namespace blink {

class ContainerNode;
class Document;
class Element;
class TreeScope;

class StyleElement {
public:
    StyleElement(Document*, bool createdByParser);
    virtual ~StyleElement();
    virtual void trace(Visitor*);

protected:
    virtual const AtomicString& type() const = 0;
    virtual const AtomicString& media() const = 0;

    CSSStyleSheet* sheet() const { return m_sheet.get(); }

    void processStyleSheet(Document&, Element*);
    void removedFromDocument(Document&, Element*);
    void removedFromDocument(Document&, Element*, ContainerNode* scopingNode, TreeScope&);
    void clearDocumentData(Document&, Element*);
    void childrenChanged(Element*);
    void finishParsingChildren(Element*);

    RefPtr<CSSStyleSheet> m_sheet;

private:
    void createSheet(Element*, const String& text = String());
    void process(Element*);
    void clearSheet(Element* ownerElement = 0);

    bool m_createdByParser : 1;
    bool m_loading : 1;
    bool m_registeredAsCandidate : 1;
    TextPosition m_startPosition;
};

}

#endif
