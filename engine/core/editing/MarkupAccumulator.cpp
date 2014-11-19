/*
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2009, 2010 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/editing/MarkupAccumulator.h"

#include "gen/sky/core/HTMLNames.h"
#include "core/dom/Document.h"
#include "core/dom/DocumentFragment.h"
#include "core/dom/Text.h"
#include "core/editing/Editor.h"
#include "core/html/HTMLElement.h"
#include "core/html/HTMLTemplateElement.h"
#include "platform/weborigin/KURL.h"
#include "wtf/unicode/CharacterNames.h"

namespace blink {

struct EntityDescription {
    UChar entity;
    const CString& reference;
    EntityMask mask;
};

template <typename CharType>
static inline void appendCharactersReplacingEntitiesInternal(StringBuilder& result, CharType* text, unsigned length, const EntityDescription entityMaps[], unsigned entityMapsCount, EntityMask entityMask)
{
    unsigned positionAfterLastEntity = 0;
    for (unsigned i = 0; i < length; ++i) {
        for (unsigned entityIndex = 0; entityIndex < entityMapsCount; ++entityIndex) {
            if (text[i] == entityMaps[entityIndex].entity && entityMaps[entityIndex].mask & entityMask) {
                result.append(text + positionAfterLastEntity, i - positionAfterLastEntity);
                const CString& replacement = entityMaps[entityIndex].reference;
                result.append(replacement.data(), replacement.length());
                positionAfterLastEntity = i + 1;
                break;
            }
        }
    }
    result.append(text + positionAfterLastEntity, length - positionAfterLastEntity);
}

void MarkupAccumulator::appendCharactersReplacingEntities(StringBuilder& result, const String& source, unsigned offset, unsigned length, EntityMask entityMask)
{
    DEFINE_STATIC_LOCAL(const CString, ampReference, ("&amp;"));
    DEFINE_STATIC_LOCAL(const CString, ltReference, ("&lt;"));
    DEFINE_STATIC_LOCAL(const CString, gtReference, ("&gt;"));
    DEFINE_STATIC_LOCAL(const CString, quotReference, ("&quot;"));
    DEFINE_STATIC_LOCAL(const CString, nbspReference, ("&nbsp;"));

    static const EntityDescription entityMaps[] = {
        { '&', ampReference, EntityAmp },
        { '<', ltReference, EntityLt },
        { '>', gtReference, EntityGt },
        { '"', quotReference, EntityQuot },
        { noBreakSpace, nbspReference, EntityNbsp },
    };

    if (!(offset + length))
        return;

    ASSERT(offset + length <= source.length());
    if (source.is8Bit())
        appendCharactersReplacingEntitiesInternal(result, source.characters8() + offset, length, entityMaps, WTF_ARRAY_LENGTH(entityMaps), entityMask);
    else
        appendCharactersReplacingEntitiesInternal(result, source.characters16() + offset, length, entityMaps, WTF_ARRAY_LENGTH(entityMaps), entityMask);
}

MarkupAccumulator::MarkupAccumulator(Vector<RawPtr<Node> >* nodes, EAbsoluteURLs resolveUrlsMethod, const Range* range)
    : m_nodes(nodes)
    , m_range(range)
    , m_resolveURLsMethod(resolveUrlsMethod)
{
}

MarkupAccumulator::~MarkupAccumulator()
{
}

String MarkupAccumulator::serializeNodes(Node& targetNode, EChildrenOnly childrenOnly, Vector<QualifiedName>* tagNamesToSkip)
{
    Namespaces* namespaces = 0;
    Namespaces namespaceHash;
    serializeNodesWithNamespaces(targetNode, childrenOnly, namespaces, tagNamesToSkip);
    return m_markup.toString();
}

void MarkupAccumulator::serializeNodesWithNamespaces(Node& targetNode, EChildrenOnly childrenOnly, const Namespaces* namespaces, Vector<QualifiedName>* tagNamesToSkip)
{
    if (tagNamesToSkip && targetNode.isElementNode()) {
        for (size_t i = 0; i < tagNamesToSkip->size(); ++i) {
            if (toElement(targetNode).hasTagName(tagNamesToSkip->at(i)))
                return;
        }
    }

    Namespaces namespaceHash;
    if (namespaces)
        namespaceHash = *namespaces;

    if (!childrenOnly)
        appendStartTag(targetNode, &namespaceHash);

    Node* current = isHTMLTemplateElement(targetNode) ? toHTMLTemplateElement(targetNode).content()->firstChild() : targetNode.firstChild();
    for ( ; current; current = current->nextSibling())
        serializeNodesWithNamespaces(*current, IncludeNode, &namespaceHash, tagNamesToSkip);

    if (!childrenOnly && targetNode.isElementNode())
        appendEndTag(toElement(targetNode));
}

String MarkupAccumulator::resolveURLIfNeeded(const Element& element, const String& urlString) const
{
    switch (m_resolveURLsMethod) {
    case ResolveAllURLs:
        return element.document().completeURL(urlString).string();

    case ResolveNonLocalURLs:
        if (!element.document().url().isLocalFile())
            return element.document().completeURL(urlString).string();
        break;

    case DoNotResolveURLs:
        break;
    }
    return urlString;
}

void MarkupAccumulator::appendString(const String& string)
{
    m_markup.append(string);
}

void MarkupAccumulator::appendStartTag(Node& node, Namespaces* namespaces)
{
    appendStartMarkup(m_markup, node, namespaces);
    if (m_nodes)
        m_nodes->append(&node);
}

void MarkupAccumulator::appendEndTag(const Element& element)
{
    appendEndMarkup(m_markup, element);
}

size_t MarkupAccumulator::totalLength(const Vector<String>& strings)
{
    size_t length = 0;
    for (size_t i = 0; i < strings.size(); ++i)
        length += strings[i].length();
    return length;
}

void MarkupAccumulator::concatenateMarkup(StringBuilder& result)
{
    result.append(m_markup);
}

void MarkupAccumulator::appendAttributeValue(StringBuilder& result, const String& attribute, bool documentIsHTML)
{
    appendCharactersReplacingEntities(result, attribute, 0, attribute.length(),
        documentIsHTML ? EntityMaskInHTMLAttributeValue : EntityMaskInAttributeValue);
}

void MarkupAccumulator::appendCustomAttributes(StringBuilder&, const Element&, Namespaces*)
{
}

void MarkupAccumulator::appendQuotedURLAttributeValue(StringBuilder& result, const Element& element, const Attribute& attribute)
{
    ASSERT(element.isURLAttribute(attribute));
    const String resolvedURLString = resolveURLIfNeeded(element, attribute.value());
    UChar quoteChar = '"';
    String strippedURLString = resolvedURLString.stripWhiteSpace();
    if (protocolIsJavaScript(strippedURLString)) {
        // minimal escaping for javascript urls
        if (strippedURLString.contains('"')) {
            if (strippedURLString.contains('\''))
                strippedURLString.replaceWithLiteral('"', "&quot;");
            else
                quoteChar = '\'';
        }
        result.append(quoteChar);
        result.append(strippedURLString);
        result.append(quoteChar);
        return;
    }

    // FIXME: This does not fully match other browsers. Firefox percent-escapes non-ASCII characters for innerHTML.
    result.append(quoteChar);
    appendAttributeValue(result, resolvedURLString, false);
    result.append(quoteChar);
}

EntityMask MarkupAccumulator::entityMaskForText(const Text& text) const
{
    const QualifiedName* parentName = 0;
    if (text.parentElement())
        parentName = &(text.parentElement())->tagQName();

    if (parentName && (*parentName == HTMLNames::scriptTag || *parentName == HTMLNames::styleTag))
        return EntityMaskInCDATA;
    return EntityMaskInHTMLPCDATA;
}

void MarkupAccumulator::appendText(StringBuilder& result, Text& text)
{
    const String& str = text.data();
    unsigned length = str.length();
    unsigned start = 0;

    if (m_range) {
        if (text == m_range->endContainer())
            length = m_range->endOffset();
        if (text == m_range->startContainer()) {
            start = m_range->startOffset();
            length -= start;
        }
    }
    appendCharactersReplacingEntities(result, str, start, length, entityMaskForText(text));
}

void MarkupAccumulator::appendElement(StringBuilder& result, Element& element, Namespaces* namespaces)
{
    appendOpenTag(result, element, namespaces);

    AttributeCollection attributes = element.attributes();
    AttributeCollection::iterator end = attributes.end();
    for (AttributeCollection::iterator it = attributes.begin(); it != end; ++it)
        appendAttribute(result, element, *it, namespaces);

    // Give an opportunity to subclasses to add their own attributes.
    appendCustomAttributes(result, element, namespaces);

    appendCloseTag(result, element);
}

void MarkupAccumulator::appendOpenTag(StringBuilder& result, const Element& element, Namespaces* namespaces)
{
    result.append('<');
    result.append(element.tagQName().localName());
}

void MarkupAccumulator::appendCloseTag(StringBuilder& result, const Element& element)
{
    result.append('>');
}

void MarkupAccumulator::appendAttribute(StringBuilder& result, const Element& element, const Attribute& attribute, Namespaces* namespaces)
{
    QualifiedName prefixedName = attribute.name();
    result.append(' ');
    result.append(attribute.name().localName());
    result.append('=');

    if (element.isURLAttribute(attribute)) {
        appendQuotedURLAttributeValue(result, element, attribute);
    } else {
        result.append('"');
        bool documentIsHTML = true;
        appendAttributeValue(result, attribute.value(), documentIsHTML);
        result.append('"');
    }
}

void MarkupAccumulator::appendStartMarkup(StringBuilder& result, Node& node, Namespaces* namespaces)
{
    switch (node.nodeType()) {
    case Node::TEXT_NODE:
        appendText(result, toText(node));
        break;
    case Node::DOCUMENT_NODE:
        break;
    case Node::DOCUMENT_FRAGMENT_NODE:
        // Not implemented.
        break;
    case Node::ELEMENT_NODE:
        appendElement(result, toElement(node), namespaces);
        break;
    }
}

void MarkupAccumulator::appendEndMarkup(StringBuilder& result, const Element& element)
{
    result.appendLiteral("</");
    result.append(element.tagQName().localName());
    result.append('>');
}

}
