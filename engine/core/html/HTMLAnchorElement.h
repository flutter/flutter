/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Simon Hausmann <hausmann@kde.org>
 * Copyright (C) 2007, 2008, 2009, 2010 Apple Inc. All rights reserved.
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

#ifndef HTMLAnchorElement_h
#define HTMLAnchorElement_h

#include "core/HTMLNames.h"
#include "core/dom/DOMURLUtils.h"
#include "core/dom/Document.h"
#include "core/html/HTMLElement.h"

namespace blink {

class HTMLAnchorElement : public HTMLElement {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtrWillBeRawPtr<HTMLAnchorElement> create(Document&);

    virtual ~HTMLAnchorElement();

    KURL href() const;
    void setHref(const AtomicString&);

    virtual bool isLiveLink() const override final;

private:
    explicit HTMLAnchorElement(Document&);

    virtual bool supportsFocus() const override final;
    virtual void defaultEventHandler(Event*) override final;
    virtual bool willRespondToMouseClickEvents() override final;
    virtual bool isURLAttribute(const Attribute&) const override final;
    virtual bool hasLegalLinkAttribute(const QualifiedName&) const override final;
    virtual bool canStartSelection() const override final;
    virtual bool isInteractiveContent() const override final;

    void handleClick(Event*);
};

} // namespace blink

#endif // HTMLAnchorElement_h
