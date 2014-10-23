/*
 * (C) 1999-2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010 Apple Inc. All rights reserved.
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

#ifndef CSSValueList_h
#define CSSValueList_h

#include "core/css/CSSValue.h"
#include "wtf/PassRefPtr.h"
#include "wtf/Vector.h"

namespace blink {

class CSSValueList : public CSSValue {
public:
    static PassRefPtrWillBeRawPtr<CSSValueList> createCommaSeparated()
    {
        return adoptRefWillBeNoop(new CSSValueList(CommaSeparator));
    }
    static PassRefPtrWillBeRawPtr<CSSValueList> createSpaceSeparated()
    {
        return adoptRefWillBeNoop(new CSSValueList(SpaceSeparator));
    }
    static PassRefPtrWillBeRawPtr<CSSValueList> createSlashSeparated()
    {
        return adoptRefWillBeNoop(new CSSValueList(SlashSeparator));
    }

    size_t length() const { return m_values.size(); }
    CSSValue* item(size_t index) { return m_values[index].get(); }
    const CSSValue* item(size_t index) const { return m_values[index].get(); }
    CSSValue* itemWithBoundsCheck(size_t index) { return index < m_values.size() ? m_values[index].get() : 0; }

    void append(PassRefPtrWillBeRawPtr<CSSValue> value) { m_values.append(value); }
    void prepend(PassRefPtrWillBeRawPtr<CSSValue> value) { m_values.prepend(value); }
    bool removeAll(CSSValue*);
    bool hasValue(CSSValue*) const;
    PassRefPtrWillBeRawPtr<CSSValueList> copy();

    String customCSSText(CSSTextFormattingFlags = QuoteCSSStringIfNeeded) const;
    bool equals(const CSSValueList&) const;
    bool equals(const CSSValue&) const;

    bool hasFailedOrCanceledSubresources() const;

    PassRefPtrWillBeRawPtr<CSSValueList> cloneForCSSOM() const;

    void traceAfterDispatch(Visitor*);

protected:
    CSSValueList(ClassType, ValueListSeparator);
    CSSValueList(const CSSValueList& cloneFrom);

private:
    explicit CSSValueList(ValueListSeparator);

    WillBeHeapVector<RefPtrWillBeMember<CSSValue>, 4> m_values;
};

DEFINE_CSS_VALUE_TYPE_CASTS(CSSValueList, isValueList());

// Objects of this class are intended to be stack-allocated and scoped to a single function.
// Please take care not to pass these around as they do hold onto a raw pointer.
class CSSValueListInspector {
    STACK_ALLOCATED();
public:
    CSSValueListInspector(CSSValue* value) : m_list((value && value->isValueList()) ? toCSSValueList(value) : 0) { }
    CSSValue* item(size_t index) const { ASSERT_WITH_SECURITY_IMPLICATION(index < length()); return m_list->item(index); }
    CSSValue* first() const { return item(0); }
    CSSValue* second() const { return item(1); }
    size_t length() const { return m_list ? m_list->length() : 0; }
private:
    RawPtrWillBeMember<CSSValueList> m_list;
};

// Wrapper that can be used to iterate over any CSSValue. Non-list values and 0 behave as zero-length lists.
// Objects of this class are intended to be stack-allocated and scoped to a single function.
// Please take care not to pass these around as they do hold onto a raw pointer.
class CSSValueListIterator {
    STACK_ALLOCATED();
public:
    CSSValueListIterator(CSSValue* value) : m_inspector(value), m_position(0) { }
    bool hasMore() const { return m_position < m_inspector.length(); }
    CSSValue* value() const { return m_inspector.item(m_position); }
    bool isPrimitiveValue() const { return value()->isPrimitiveValue(); }
    void advance() { m_position++; ASSERT(m_position <= m_inspector.length());}
    size_t index() const { return m_position; }
private:
    CSSValueListInspector m_inspector;
    size_t m_position;
};

} // namespace blink

#endif // CSSValueList_h
