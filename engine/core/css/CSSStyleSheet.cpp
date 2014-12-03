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

#include "sky/engine/bindings/core/v8/ExceptionState.h"
#include "sky/engine/bindings/core/v8/V8Binding.h"
#include "sky/engine/bindings/core/v8/V8PerIsolateData.h"
#include "sky/engine/core/css/CSSRuleList.h"
#include "sky/engine/core/css/MediaList.h"
#include "sky/engine/core/css/StyleRule.h"
#include "sky/engine/core/css/StyleSheetContents.h"
#include "sky/engine/core/css/parser/BisonCSSParser.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/ExceptionCode.h"
#include "sky/engine/core/dom/Node.h"
#include "sky/engine/core/frame/UseCounter.h"
#include "sky/engine/core/html/HTMLStyleElement.h"
#include "sky/engine/wtf/text/StringBuilder.h"

namespace blink {

class StyleSheetCSSRuleList final : public CSSRuleList {
public:
    static PassOwnPtr<StyleSheetCSSRuleList> create(CSSStyleSheet* sheet)
    {
        return adoptPtr(new StyleSheetCSSRuleList(sheet));
    }

private:
    StyleSheetCSSRuleList(CSSStyleSheet* sheet) : m_styleSheet(sheet) { }

    virtual void ref() override { m_styleSheet->ref(); }
    virtual void deref() override { m_styleSheet->deref(); }

    virtual unsigned length() const override { return m_styleSheet->length(); }
    virtual CSSRule* item(unsigned index) const override { return m_styleSheet->item(index); }

    virtual CSSStyleSheet* styleSheet() const override { return m_styleSheet; }

    RawPtr<CSSStyleSheet> m_styleSheet;
};

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
    // With oilpan the parent style sheet pointer is strong and the sheet and
    // its RuleCSSOMWrappers die together and we don't need to clear them here.
    // Also with oilpan the StyleSheetContents client pointers are weak and
    // therefore do not need to be cleared here.
    // For style rules outside the document, .parentStyleSheet can become null even if the style rule
    // is still observable from JavaScript. This matches the behavior of .parentNode for nodes, but
    // it's not ideal because it makes the CSSOM's behavior depend on the timing of garbage collection.
    for (unsigned i = 0; i < m_childRuleCSSOMWrappers.size(); ++i) {
        if (m_childRuleCSSOMWrappers[i])
            m_childRuleCSSOMWrappers[i]->setParentStyleSheet(0);
    }

    if (m_mediaCSSOMWrapper)
        m_mediaCSSOMWrapper->clearParentStyleSheet();

    m_contents->unregisterClient(this);
}

void CSSStyleSheet::willMutateRules()
{
    // If we are the only client it is safe to mutate.
    if (m_contents->clientSize() <= 1 && !m_contents->isInMemoryCache()) {
        m_contents->clearRuleSet();
        if (Document* document = ownerDocument())
            m_contents->removeSheetFromCache(document);
        m_contents->setMutable();
        return;
    }
    // Only cacheable stylesheets should have multiple clients.
    ASSERT(m_contents->isCacheable());

    // Copy-on-write.
    m_contents->unregisterClient(this);
    m_contents = m_contents->copy();
    m_contents->registerClient(this);

    m_contents->setMutable();

    // Any existing CSSOM wrappers need to be connected to the copied child rules.
    reattachChildRuleCSSOMWrappers();
}

void CSSStyleSheet::didMutateRules()
{
    ASSERT(m_contents->isMutable());
    ASSERT(m_contents->clientSize() <= 1);

    didMutate(PartialRuleUpdate);
}

void CSSStyleSheet::didMutate(StyleSheetUpdateType updateType)
{
    Document* owner = ownerDocument();
    if (!owner)
        return;

    owner->modifiedStyleSheet(this);
}

void CSSStyleSheet::reattachChildRuleCSSOMWrappers()
{
    for (unsigned i = 0; i < m_childRuleCSSOMWrappers.size(); ++i) {
        if (!m_childRuleCSSOMWrappers[i])
            continue;
        m_childRuleCSSOMWrappers[i]->reattach(m_contents->ruleAt(i));
    }
}

void CSSStyleSheet::setMediaQueries(PassRefPtr<MediaQuerySet> mediaQueries)
{
    m_mediaQueries = mediaQueries;
    if (m_mediaCSSOMWrapper && m_mediaQueries)
        m_mediaCSSOMWrapper->reattach(m_mediaQueries.get());

    // Add warning message to inspector whenever dpi/dpcm values are used for "screen" media.
    reportMediaQueryWarningIfNeeded(ownerDocument(), m_mediaQueries.get());
}

unsigned CSSStyleSheet::length() const
{
    return m_contents->ruleCount();
}

CSSRule* CSSStyleSheet::item(unsigned index)
{
    unsigned ruleCount = length();
    if (index >= ruleCount)
        return 0;

    if (m_childRuleCSSOMWrappers.isEmpty())
        m_childRuleCSSOMWrappers.grow(ruleCount);
    ASSERT(m_childRuleCSSOMWrappers.size() == ruleCount);

    RefPtr<CSSRule>& cssRule = m_childRuleCSSOMWrappers[index];
    if (!cssRule)
        cssRule = m_contents->ruleAt(index)->createCSSOMWrapper(this);
    return cssRule.get();
}

void CSSStyleSheet::clearOwnerNode()
{
    didMutate(EntireStyleSheetUpdate);
    if (m_ownerNode)
        m_contents->unregisterClient(this);
    m_ownerNode = nullptr;
}

PassRefPtr<CSSRuleList> CSSStyleSheet::rules()
{
    // IE behavior.
    RefPtr<StaticCSSRuleList> nonCharsetRules(StaticCSSRuleList::create());
    unsigned ruleCount = length();
    for (unsigned i = 0; i < ruleCount; ++i) {
        CSSRule* rule = item(i);
        nonCharsetRules->rules().append(rule);
    }
    return nonCharsetRules.release();
}

unsigned CSSStyleSheet::insertRule(const String& ruleString, unsigned index, ExceptionState& exceptionState)
{
    ASSERT(m_childRuleCSSOMWrappers.isEmpty() || m_childRuleCSSOMWrappers.size() == m_contents->ruleCount());

    if (index > length()) {
        exceptionState.throwDOMException(IndexSizeError, "The index provided (" + String::number(index) + ") is larger than the maximum index (" + String::number(length()) + ").");
        return 0;
    }
    CSSParserContext context(m_contents->parserContext(), UseCounter::getFrom(this));
    BisonCSSParser p(context);
    RefPtr<StyleRuleBase> rule = p.parseRule(m_contents.get(), ruleString);

    if (!rule) {
        exceptionState.throwDOMException(SyntaxError, "Failed to parse the rule '" + ruleString + "'.");
        return 0;
    }
    RuleMutationScope mutationScope(this);

    bool success = m_contents->wrapperInsertRule(rule, index);
    if (!success) {
        exceptionState.throwDOMException(HierarchyRequestError, "Failed to insert the rule.");
        return 0;
    }
    if (!m_childRuleCSSOMWrappers.isEmpty())
        m_childRuleCSSOMWrappers.insert(index, RefPtr<CSSRule>(nullptr));

    return index;
}

unsigned CSSStyleSheet::insertRule(const String& rule, ExceptionState& exceptionState)
{
    UseCounter::countDeprecation(callingExecutionContext(V8PerIsolateData::mainThreadIsolate()), UseCounter::CSSStyleSheetInsertRuleOptionalArg);
    return insertRule(rule, 0, exceptionState);
}

void CSSStyleSheet::deleteRule(unsigned index, ExceptionState& exceptionState)
{
    ASSERT(m_childRuleCSSOMWrappers.isEmpty() || m_childRuleCSSOMWrappers.size() == m_contents->ruleCount());

    if (index >= length()) {
        exceptionState.throwDOMException(IndexSizeError, "The index provided (" + String::number(index) + ") is larger than the maximum index (" + String::number(length() - 1) + ").");
        return;
    }
    RuleMutationScope mutationScope(this);

    m_contents->wrapperDeleteRule(index);

    if (!m_childRuleCSSOMWrappers.isEmpty()) {
        if (m_childRuleCSSOMWrappers[index])
            m_childRuleCSSOMWrappers[index]->setParentStyleSheet(0);
        m_childRuleCSSOMWrappers.remove(index);
    }
}

int CSSStyleSheet::addRule(const String& selector, const String& style, int index, ExceptionState& exceptionState)
{
    StringBuilder text;
    text.append(selector);
    text.appendLiteral(" { ");
    text.append(style);
    if (!style.isEmpty())
        text.append(' ');
    text.append('}');
    insertRule(text.toString(), index, exceptionState);

    // As per Microsoft documentation, always return -1.
    return -1;
}

int CSSStyleSheet::addRule(const String& selector, const String& style, ExceptionState& exceptionState)
{
    return addRule(selector, style, length(), exceptionState);
}


PassRefPtr<CSSRuleList> CSSStyleSheet::cssRules()
{
    if (!m_ruleListCSSOMWrapper)
        m_ruleListCSSOMWrapper = StyleSheetCSSRuleList::create(this);
    return m_ruleListCSSOMWrapper.get();
}

KURL CSSStyleSheet::baseURL() const
{
    return m_contents->baseURL();
}

MediaList* CSSStyleSheet::media() const
{
    if (!m_mediaQueries)
        return 0;

    if (!m_mediaCSSOMWrapper)
        m_mediaCSSOMWrapper = MediaList::create(m_mediaQueries.get(), const_cast<CSSStyleSheet*>(this));
    return m_mediaCSSOMWrapper.get();
}

Document* CSSStyleSheet::ownerDocument() const
{
    return ownerNode() ? &ownerNode()->document() : 0;
}

void CSSStyleSheet::clearChildRuleCSSOMWrappers()
{
    m_childRuleCSSOMWrappers.clear();
}

} // namespace blink
