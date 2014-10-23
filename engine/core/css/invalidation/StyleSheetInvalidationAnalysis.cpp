/*
 * Copyright (C) 2012 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/css/invalidation/StyleSheetInvalidationAnalysis.h"

#include "core/css/CSSSelectorList.h"
#include "core/css/StyleSheetContents.h"
#include "core/dom/ContainerNode.h"
#include "core/dom/Document.h"
#include "core/dom/ElementTraversal.h"
#include "core/dom/shadow/ShadowRoot.h"
#include "core/html/HTMLStyleElement.h"

namespace blink {

StyleSheetInvalidationAnalysis::StyleSheetInvalidationAnalysis(const WillBeHeapVector<RawPtrWillBeMember<StyleSheetContents> >& sheets)
    : m_dirtiesAllStyle(false)
{
    for (unsigned i = 0; i < sheets.size() && !m_dirtiesAllStyle; ++i)
        analyzeStyleSheet(sheets[i]);
}

static bool determineSelectorScopes(const CSSSelectorList& selectorList, HashSet<StringImpl*>& idScopes, HashSet<StringImpl*>& classScopes)
{
    for (const CSSSelector* selector = selectorList.first(); selector; selector = CSSSelectorList::next(*selector)) {
        const CSSSelector* scopeSelector = 0;
        // This picks the widest scope, not the narrowest, to minimize the number of found scopes.
        for (const CSSSelector* current = selector; current; current = current->tagHistory()) {
            // Prefer ids over classes.
            if (current->match() == CSSSelector::Id)
                scopeSelector = current;
            else if (current->match() == CSSSelector::Class && (!scopeSelector || scopeSelector->match() != CSSSelector::Id))
                scopeSelector = current;
        }
        if (!scopeSelector)
            return false;
        ASSERT(scopeSelector->match() == CSSSelector::Class || scopeSelector->match() == CSSSelector::Id);
        if (scopeSelector->match() == CSSSelector::Id)
            idScopes.add(scopeSelector->value().impl());
        else
            classScopes.add(scopeSelector->value().impl());
    }
    return true;
}

static Node* determineScopingNodeForStyleInShadow(HTMLStyleElement* ownerElement, StyleSheetContents* styleSheetContents)
{
    ASSERT(ownerElement && ownerElement->isInShadowTree());
    return ownerElement->containingShadowRoot()->shadowHost();
}

static bool ruleAdditionMightRequireDocumentStyleRecalc(StyleRuleBase* rule)
{
    // This funciton is conservative. We only return false when we know that
    // the added @rule can't require style recalcs.
    switch (rule->type()) {
    case StyleRule::Keyframes: // Keyframes never cause style invalidations and are handled during sheet insertion.
        return false;

    case StyleRule::Media: // If the media rule doesn't apply, we could avoid recalc.
    case StyleRule::FontFace: // If the fonts aren't in use, we could avoid recalc.
    case StyleRule::Supports: // If we evaluated the supports-clause we could avoid recalc.
    case StyleRule::Viewport: // If the viewport doesn't match, we could avoid recalcing.
    // FIXME: Unclear if any of the rest need to cause style recalc:
    case StyleRule::Filter:
        return true;

    // These should all be impossible to reach:
    case StyleRule::Unknown:
    case StyleRule::Keyframe:
    case StyleRule::Style:
        break;
    }
    ASSERT_NOT_REACHED();
    return true;
}

void StyleSheetInvalidationAnalysis::analyzeStyleSheet(StyleSheetContents* styleSheetContents)
{
    // See if all rules on the sheet are scoped to some specific ids or classes.
    // Then test if we actually have any of those in the tree at the moment.
    if (styleSheetContents->hasSingleOwnerNode()) {
        Node* ownerNode = styleSheetContents->singleOwnerNode();
        if (isHTMLStyleElement(ownerNode) && toHTMLStyleElement(*ownerNode).isInShadowTree()) {
            m_scopingNodes.append(determineScopingNodeForStyleInShadow(toHTMLStyleElement(ownerNode), styleSheetContents));
            return;
        }
    }

    const WillBeHeapVector<RefPtrWillBeMember<StyleRuleBase> >& rules = styleSheetContents->childRules();
    for (unsigned i = 0; i < rules.size(); i++) {
        StyleRuleBase* rule = rules[i].get();
        if (!rule->isStyleRule()) {
            if (ruleAdditionMightRequireDocumentStyleRecalc(rule)) {
                m_dirtiesAllStyle = true;
                return;
            }
            continue;
        }
        StyleRule* styleRule = toStyleRule(rule);
        if (!determineSelectorScopes(styleRule->selectorList(), m_idScopes, m_classScopes)) {
            m_dirtiesAllStyle = true;
            return;
        }
    }
}

static bool elementMatchesSelectorScopes(const Element* element, const HashSet<StringImpl*>& idScopes, const HashSet<StringImpl*>& classScopes)
{
    if (!idScopes.isEmpty() && element->hasID() && idScopes.contains(element->idForStyleResolution().impl()))
        return true;
    if (classScopes.isEmpty() || !element->hasClass())
        return false;
    const SpaceSplitString& classNames = element->classNames();
    for (unsigned i = 0; i < classNames.size(); ++i) {
        if (classScopes.contains(classNames[i].impl()))
            return true;
    }
    return false;
}

void StyleSheetInvalidationAnalysis::invalidateStyle(Document& document)
{
    ASSERT(!m_dirtiesAllStyle);

    if (!m_scopingNodes.isEmpty()) {
        for (unsigned i = 0; i < m_scopingNodes.size(); ++i)
            m_scopingNodes.at(i)->setNeedsStyleRecalc(SubtreeStyleChange);
    }

    if (m_idScopes.isEmpty() && m_classScopes.isEmpty())
        return;
    Element* element = ElementTraversal::firstWithin(document);
    while (element) {
        if (elementMatchesSelectorScopes(element, m_idScopes, m_classScopes)) {
            element->setNeedsStyleRecalc(SubtreeStyleChange);
            // The whole subtree is now invalidated, we can skip to the next sibling.
            element = ElementTraversal::nextSkippingChildren(*element);
            continue;
        }
        element = ElementTraversal::next(*element);
    }
}

}
