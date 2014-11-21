/*
 * Copyright (C) 2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2008 Apple Inc. All rights reserved.
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
#include "sky/engine/core/css/parser/CSSParserValues.h"

#include "sky/engine/core/css/CSSFunctionValue.h"
#include "sky/engine/core/css/CSSSelectorList.h"
#include "sky/engine/core/html/parser/HTMLParserIdioms.h"

namespace blink {

using namespace WTF;

static void destroy(Vector<CSSParserValue, 4>& values)
{
    size_t numValues = values.size();
    for (size_t i = 0; i < numValues; i++) {
        if (values[i].unit == CSSParserValue::Function)
            delete values[i].function;
        else if (values[i].unit == CSSParserValue::ValueList)
            delete values[i].valueList;
    }
}

void CSSParserValueList::destroyAndClear()
{
    destroy(m_values);
    clearAndLeakValues();
}

CSSParserValueList::~CSSParserValueList()
{
    destroy(m_values);
}

void CSSParserValueList::addValue(const CSSParserValue& v)
{
    m_values.append(v);
}

void CSSParserValueList::insertValueAt(unsigned i, const CSSParserValue& v)
{
    m_values.insert(i, v);
}

void CSSParserValueList::stealValues(CSSParserValueList& valueList)
{
    for (unsigned i = 0; i < valueList.size(); ++i)
        m_values.append(*(valueList.valueAt(i)));
    valueList.clearAndLeakValues();
}

CSSParserSelector::CSSParserSelector()
    : m_selector(adoptPtr(new CSSSelector()))
{
}

CSSParserSelector::CSSParserSelector(const QualifiedName& tagQName)
    : m_selector(adoptPtr(new CSSSelector(tagQName)))
{
}

CSSParserSelector::~CSSParserSelector()
{
    if (!m_tagHistory)
        return;
    Vector<OwnPtr<CSSParserSelector>, 16> toDelete;
    OwnPtr<CSSParserSelector> selector = m_tagHistory.release();
    while (true) {
        OwnPtr<CSSParserSelector> next = selector->m_tagHistory.release();
        toDelete.append(selector.release());
        if (!next)
            break;
        selector = next.release();
    }
}

void CSSParserSelector::adoptSelectorVector(Vector<OwnPtr<CSSParserSelector> >& selectorVector)
{
    CSSSelectorList* selectorList = new CSSSelectorList();
    selectorList->adoptSelectorVector(selectorVector);
    m_selector->setSelectorList(adoptPtr(selectorList));
}

bool CSSParserSelector::isSimple() const
{
    if (m_selector->selectorList() || m_selector->matchesPseudoElement())
        return false;

    if (!m_tagHistory)
        return true;

    if (m_selector->match() == CSSSelector::Tag) {
        // We can't check against anyQName() here because namespace may not be nullAtom.
        // Example:
        //     @namespace "http://www.w3.org/2000/svg";
        //     svg:not(:root) { ...
        if (m_selector->tagQName().localName() == starAtom)
            return m_tagHistory->isSimple();
    }

    return false;
}

void CSSParserSelector::appendTagHistory(PassOwnPtr<CSSParserSelector> selector)
{
    CSSParserSelector* end = this;
    while (end->tagHistory())
        end = end->tagHistory();
    end->setTagHistory(selector);
}

void CSSParserSelector::prependTagSelector(const QualifiedName& tagQName, bool tagIsForNamespaceRule)
{
    OwnPtr<CSSParserSelector> second = adoptPtr(new CSSParserSelector);
    second->m_selector = m_selector.release();
    second->m_tagHistory = m_tagHistory.release();
    m_tagHistory = second.release();

    m_selector = adoptPtr(new CSSSelector(tagQName, tagIsForNamespaceRule));
}

bool CSSParserSelector::hasHostPseudoSelector() const
{
    for (CSSParserSelector* selector = const_cast<CSSParserSelector*>(this); selector; selector = selector->tagHistory()) {
        if (selector->pseudoType() == CSSSelector::PseudoHost)
            return true;
    }
    return false;
}

} // namespace blink
