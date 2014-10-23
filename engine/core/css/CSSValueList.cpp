/*
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2010 Apple Inc. All rights reserved.
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
#include "core/css/CSSValueList.h"

#include "core/css/parser/CSSParserValues.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

CSSValueList::CSSValueList(ClassType classType, ValueListSeparator listSeparator)
    : CSSValue(classType)
{
    m_valueListSeparator = listSeparator;
}

CSSValueList::CSSValueList(ValueListSeparator listSeparator)
    : CSSValue(ValueListClass)
{
    m_valueListSeparator = listSeparator;
}

bool CSSValueList::removeAll(CSSValue* val)
{
    bool found = false;
    for (size_t index = 0; index < m_values.size(); index++) {
        RefPtrWillBeMember<CSSValue>& value = m_values.at(index);
        if (value && val && value->equals(*val)) {
            m_values.remove(index);
            found = true;
        }
    }

    return found;
}

bool CSSValueList::hasValue(CSSValue* val) const
{
    for (size_t index = 0; index < m_values.size(); index++) {
        const RefPtrWillBeMember<CSSValue>& value = m_values.at(index);
        if (value && val && value->equals(*val))
            return true;
    }
    return false;
}

PassRefPtrWillBeRawPtr<CSSValueList> CSSValueList::copy()
{
    RefPtrWillBeRawPtr<CSSValueList> newList = nullptr;
    switch (m_valueListSeparator) {
    case SpaceSeparator:
        newList = createSpaceSeparated();
        break;
    case CommaSeparator:
        newList = createCommaSeparated();
        break;
    case SlashSeparator:
        newList = createSlashSeparated();
        break;
    default:
        ASSERT_NOT_REACHED();
    }
    for (size_t index = 0; index < m_values.size(); index++)
        newList->append(m_values[index]);
    return newList.release();
}

String CSSValueList::customCSSText(CSSTextFormattingFlags formattingFlag) const
{
    StringBuilder result;
    String separator;
    switch (m_valueListSeparator) {
    case SpaceSeparator:
        separator = " ";
        break;
    case CommaSeparator:
        separator = ", ";
        break;
    case SlashSeparator:
        separator = " / ";
        break;
    default:
        ASSERT_NOT_REACHED();
    }

    unsigned size = m_values.size();
    for (unsigned i = 0; i < size; i++) {
        if (!result.isEmpty())
            result.append(separator);
        if (formattingFlag == AlwaysQuoteCSSString && m_values[i]->isPrimitiveValue())
            result.append(toCSSPrimitiveValue(m_values[i].get())->customCSSText(AlwaysQuoteCSSString));
        else
            result.append(m_values[i]->cssText());
    }

    return result.toString();
}

bool CSSValueList::equals(const CSSValueList& other) const
{
    return m_valueListSeparator == other.m_valueListSeparator && compareCSSValueVector(m_values, other.m_values);
}

bool CSSValueList::equals(const CSSValue& other) const
{
    if (m_values.size() != 1)
        return false;

    const RefPtrWillBeMember<CSSValue>& value = m_values[0];
    return value && value->equals(other);
}

bool CSSValueList::hasFailedOrCanceledSubresources() const
{
    for (unsigned i = 0; i < m_values.size(); ++i) {
        if (m_values[i]->hasFailedOrCanceledSubresources())
            return true;
    }
    return false;
}

CSSValueList::CSSValueList(const CSSValueList& cloneFrom)
    : CSSValue(cloneFrom.classType(), /* isCSSOMSafe */ true)
{
    m_valueListSeparator = cloneFrom.m_valueListSeparator;
    m_values.resize(cloneFrom.m_values.size());
    for (unsigned i = 0; i < m_values.size(); ++i)
        m_values[i] = cloneFrom.m_values[i]->cloneForCSSOM();
}

PassRefPtrWillBeRawPtr<CSSValueList> CSSValueList::cloneForCSSOM() const
{
    return adoptRefWillBeNoop(new CSSValueList(*this));
}

void CSSValueList::traceAfterDispatch(Visitor* visitor)
{
    visitor->trace(m_values);
    CSSValue::traceAfterDispatch(visitor);
}

} // namespace blink
