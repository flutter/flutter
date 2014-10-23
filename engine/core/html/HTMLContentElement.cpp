/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
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
#include "core/html/HTMLContentElement.h"

#include "core/HTMLNames.h"
#include "core/css/SelectorChecker.h"
#include "core/css/parser/BisonCSSParser.h"
#include "core/dom/QualifiedName.h"
#include "core/dom/shadow/ElementShadow.h"
#include "core/dom/shadow/ShadowRoot.h"
#include "platform/RuntimeEnabledFeatures.h"

namespace blink {

inline HTMLContentElement::HTMLContentElement(Document& document)
    : InsertionPoint(HTMLNames::contentTag, document)
    , m_shouldParseSelect(false)
    , m_isValidSelector(true)
{
    ScriptWrappable::init(this);
}

DEFINE_NODE_FACTORY(HTMLContentElement)

HTMLContentElement::~HTMLContentElement()
{
}

void HTMLContentElement::parseSelect()
{
    ASSERT(m_shouldParseSelect);

    BisonCSSParser parser(CSSParserContext(document(), 0));
    parser.parseSelector(m_select, m_selectorList);
    m_shouldParseSelect = false;
    m_isValidSelector = validateSelect();
    if (!m_isValidSelector) {
        CSSSelectorList emptyList;
        m_selectorList.adopt(emptyList);
    }
}

void HTMLContentElement::parseAttribute(const QualifiedName& name, const AtomicString& value)
{
    if (name == HTMLNames::selectAttr) {
        if (ShadowRoot* root = containingShadowRoot())
            root->owner()->willAffectSelector();
        m_shouldParseSelect = true;
        m_select = value;
    } else {
        InsertionPoint::parseAttribute(name, value);
    }
}

static inline bool includesDisallowedPseudoClass(const CSSSelector& selector)
{
    return selector.match() == CSSSelector::PseudoClass;
}

bool HTMLContentElement::validateSelect() const
{
    ASSERT(!m_shouldParseSelect);

    if (m_select.isNull() || m_select.isEmpty())
        return true;

    if (!m_selectorList.isValid())
        return false;

    // FIXME(sky): Should we allow pseudo classes in select?
    bool allowAnyPseudoClasses = false;

    for (const CSSSelector* selector = m_selectorList.first(); selector; selector = m_selectorList.next(*selector)) {
        if (!selector->isCompound())
            return false;
        if (allowAnyPseudoClasses)
            continue;
        for (const CSSSelector* subSelector = selector; subSelector; subSelector = subSelector->tagHistory()) {
            if (includesDisallowedPseudoClass(*subSelector))
                return false;
        }
    }
    return true;
}

static inline bool checkOneSelector(const CSSSelector& selector, const WillBeHeapVector<RawPtrWillBeMember<Node>, 32>& siblings, int nth)
{
    Element* element = toElement(siblings[nth]);
    SelectorChecker selectorChecker(element->document(), SelectorChecker::CollectingCSSRules);
    SelectorChecker::SelectorCheckingContext context(selector, element);
    return selectorChecker.match(context);
}

bool HTMLContentElement::matchSelector(const WillBeHeapVector<RawPtrWillBeMember<Node>, 32>& siblings, int nth) const
{
    for (const CSSSelector* selector = selectorList().first(); selector; selector = CSSSelectorList::next(*selector)) {
        if (checkOneSelector(*selector, siblings, nth))
            return true;
    }
    return false;
}

}
