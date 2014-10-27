/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Peter Kelly (pmk@post.com)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2009, 2010, 2012 Apple Inc. All rights reserved.
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
#include "core/dom/Attr.h"

#include "bindings/core/v8/ExceptionState.h"
#include "bindings/core/v8/ExceptionStatePlaceholder.h"
#include "core/dom/Document.h"
#include "core/dom/Element.h"
#include "core/dom/Text.h"
#include "core/events/ScopedEventQueue.h"
#include "core/frame/UseCounter.h"
#include "wtf/text/AtomicString.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

Attr::Attr(Element& element, const QualifiedName& name)
    : Node(&element.document(), Node::CreateOther)
    , m_element(&element)
    , m_name(name)
{
    ScriptWrappable::init(this);
}

PassRefPtr<Attr> Attr::create(Element& element, const QualifiedName& name)
{
    RefPtr<Attr> attr = adoptRef(new Attr(element, name));
    return attr.release();
}

Attr::~Attr()
{
}

void Attr::setValue(const AtomicString& value)
{
    if (!m_element)
        return;
    m_element->setAttribute(m_name, value);
}

const AtomicString& Attr::value() const
{
    if (m_element)
        return m_element->getAttribute(m_name);
    return nullAtom;
}

void Attr::detachFromElement()
{
    m_element = nullptr;
}

void Attr::trace(Visitor* visitor)
{
    visitor->trace(m_element);
    Node::trace(visitor);
}

}
