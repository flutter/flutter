/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2004-2007, 2009, 2014 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_HTML_HTMLELEMENT_H_
#define SKY_ENGINE_CORE_HTML_HTMLELEMENT_H_

#include "sky/engine/core/dom/Element.h"

namespace blink {

class HTMLElement : public Element {
    DEFINE_WRAPPERTYPEINFO();
public:
    DECLARE_ELEMENT_FACTORY_WITH_TAGNAME(HTMLElement);

protected:
    HTMLElement(const QualifiedName& tagName, Document&, ConstructionType);

private:
    bool isHTMLElement() const = delete; // This will catch anyone doing an unnecessary check.
    bool isStyledElement() const = delete; // This will catch anyone doing an unnecessary check.
};

DEFINE_ELEMENT_TYPE_CASTS(HTMLElement, isHTMLElement());

template <typename T> bool isElementOfType(const HTMLElement&);
template <> inline bool isElementOfType<const HTMLElement>(const HTMLElement&) { return true; }

inline HTMLElement::HTMLElement(const QualifiedName& tagName, Document& document, ConstructionType type = CreateHTMLElement)
    : Element(tagName, &document, type)
{
    ASSERT(!tagName.localName().isNull());
}

// This requires isHTML*Element(const Element&) and isHTML*Element(const HTMLElement&).
// When the input element is an HTMLElement, we don't need to check the namespace URI, just the local name.
#define DEFINE_HTMLELEMENT_TYPE_CASTS_WITH_FUNCTION(thisType) \
    inline bool is##thisType(const thisType* element); \
    inline bool is##thisType(const thisType& element); \
    inline bool is##thisType(const Node& node) { return node.isElementNode() ? is##thisType(toElement(node)) : false; } \
    inline bool is##thisType(const Node* node) { return node && is##thisType(*node); } \
    inline bool is##thisType(const Element* element) { return element && is##thisType(*element); } \
    template<typename T> inline bool is##thisType(const PassRefPtr<T>& node) { return is##thisType(node.get()); } \
    template<typename T> inline bool is##thisType(const RefPtr<T>& node) { return is##thisType(node.get()); } \
    template <> inline bool isElementOfType<const thisType>(const HTMLElement& element) { return is##thisType(element); } \
    DEFINE_ELEMENT_TYPE_CASTS_WITH_FUNCTION(thisType)

} // namespace blink

#include "gen/sky/core/HTMLElementTypeHelpers.h"

#endif  // SKY_ENGINE_CORE_HTML_HTMLELEMENT_H_
