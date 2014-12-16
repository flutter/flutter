/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_CSS_RESOLVER_ELEMENTRESOLVECONTEXT_H_
#define SKY_ENGINE_CORE_CSS_RESOLVER_ELEMENTRESOLVECONTEXT_H_

#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/rendering/style/RenderStyleConstants.h"

namespace blink {

class ContainerNode;
class Document;
class Element;
class RenderStyle;

// ElementResolveContext is immutable and serves as an input to the style resolve process.
class ElementResolveContext {
    STACK_ALLOCATED();
public:
    explicit ElementResolveContext(const Document&);

    explicit ElementResolveContext(Element&);

    Element* element() const { return m_element; }
    const ContainerNode* parentNode() const { return m_parentNode; }
    bool distributedToInsertionPoint() const { return m_distributedToInsertionPoint; }

private:
    RawPtr<Element> m_element;
    RawPtr<ContainerNode> m_parentNode;
    bool m_distributedToInsertionPoint;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_CSS_RESOLVER_ELEMENTRESOLVECONTEXT_H_
