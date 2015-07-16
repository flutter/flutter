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

#include "sky/engine/core/css/resolver/ElementResolveContext.h"

#include "sky/engine/core/dom/Node.h"
#include "sky/engine/core/dom/NodeRenderStyle.h"
#include "sky/engine/core/dom/NodeRenderingTraversal.h"

namespace blink {

ElementResolveContext::ElementResolveContext(const Document& document)
    : m_element(nullptr)
    , m_parentNode(nullptr)
    , m_distributedToInsertionPoint(false)
{
}

ElementResolveContext::ElementResolveContext(Element& element)
    : m_element(&element)
    , m_distributedToInsertionPoint(false)
{
    NodeRenderingTraversal::ParentDetails parentDetails;
    m_parentNode = NodeRenderingTraversal::parent(&element, &parentDetails);
    m_distributedToInsertionPoint = parentDetails.insertionPoint();
}

} // namespace blink
