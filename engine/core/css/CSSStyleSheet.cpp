/*
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2006, 2007, 2012 Apple Inc. All rights reserved.
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

#include "sky/engine/config.h"
#include "sky/engine/core/css/CSSStyleSheet.h"

#include "sky/engine/core/css/MediaList.h"
#include "sky/engine/core/css/StyleSheetContents.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Node.h"
#include "sky/engine/core/html/HTMLStyleElement.h"

namespace blink {

#if ENABLE(ASSERT)
static bool isAcceptableCSSStyleSheetParent(Node* parentNode)
{
    // Only these nodes can be parents of StyleSheets, and they need to call
    // clearOwnerNode() when moved out of document.
    // Destruction of the style sheet counts as being "moved out of the
    // document", but only in the non-oilpan version of blink. I.e. don't call
    // clearOwnerNode() in the owner's destructor in oilpan.
    return !parentNode
        || parentNode->isDocumentNode()
        || isHTMLStyleElement(*parentNode);
}
#endif

PassRefPtr<CSSStyleSheet> CSSStyleSheet::createInline(PassRefPtr<StyleSheetContents> sheet, Node* ownerNode, const TextPosition& startPosition)
{
    ASSERT(sheet);
    return adoptRef(new CSSStyleSheet(sheet, ownerNode, true, startPosition));
}

PassRefPtr<CSSStyleSheet> CSSStyleSheet::createInline(Node* ownerNode, const KURL& baseURL, const TextPosition& startPosition)
{
    CSSParserContext parserContext(ownerNode->document(), 0, baseURL);
    RefPtr<StyleSheetContents> sheet = StyleSheetContents::create(baseURL.string(), parserContext);
    return adoptRef(new CSSStyleSheet(sheet.release(), ownerNode, true, startPosition));
}

CSSStyleSheet::CSSStyleSheet(PassRefPtr<StyleSheetContents> contents)
    : m_contents(contents)
    , m_isInlineStylesheet(false)
    , m_ownerNode(nullptr)
    , m_startPosition(TextPosition::minimumPosition())
{
    m_contents->registerClient(this);
}

CSSStyleSheet::CSSStyleSheet(PassRefPtr<StyleSheetContents> contents, Node* ownerNode, bool isInlineStylesheet, const TextPosition& startPosition)
    : m_contents(contents)
    , m_isInlineStylesheet(isInlineStylesheet)
    , m_ownerNode(ownerNode)
    , m_startPosition(startPosition)
{
    ASSERT(isAcceptableCSSStyleSheetParent(ownerNode));
    m_contents->registerClient(this);
}

CSSStyleSheet::~CSSStyleSheet()
{
    m_contents->unregisterClient(this);
}

void CSSStyleSheet::setMediaQueries(PassRefPtr<MediaQuerySet> mediaQueries)
{
    m_mediaQueries = mediaQueries;

    // Add warning message to inspector whenever dpi/dpcm values are used for "screen" media.
    reportMediaQueryWarningIfNeeded(ownerDocument(), m_mediaQueries.get());
}

unsigned CSSStyleSheet::length() const
{
    return m_contents->ruleCount();
}

void CSSStyleSheet::clearOwnerNode()
{
    if (Document* owner = ownerDocument())
        owner->modifiedStyleSheet(this);
    if (m_ownerNode)
        m_contents->unregisterClient(this);
    m_ownerNode = nullptr;
}

KURL CSSStyleSheet::baseURL() const
{
    return m_contents->baseURL();
}

Document* CSSStyleSheet::ownerDocument() const
{
    return ownerNode() ? &ownerNode()->document() : 0;
}

} // namespace blink
