/*
 * Copyright (C) 2003 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2008, 2009, 2010 Apple Inc. All rights reserved.
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

#ifndef CSSParserValues_h
#define CSSParserValues_h

#include "core/css/CSSPrimitiveValue.h"
#include "core/css/CSSSelector.h"
#include "core/css/CSSValueList.h"
#include "gen/sky/core/CSSValueKeywords.h"
#include "wtf/text/AtomicString.h"
#include "wtf/text/WTFString.h"

namespace blink {

class CSSValue;
class QualifiedName;

struct CSSParserString {
    void init(const LChar* characters, unsigned length)
    {
        m_data.characters8 = characters;
        m_length = length;
        m_is8Bit = true;
    }

    void init(const UChar* characters, unsigned length)
    {
        m_data.characters16 = characters;
        m_length = length;
        m_is8Bit = false;
    }

    void init(const String& string)
    {
        init(string, 0, string.length());
    }

    void init(const String& string, unsigned startOffset, unsigned length)
    {
        m_length = length;
        if (!m_length) {
            m_data.characters8 = 0;
            m_is8Bit = true;
            return;
        }
        if (string.is8Bit()) {
            m_data.characters8 = const_cast<LChar*>(string.characters8()) + startOffset;
            m_is8Bit = true;
        } else {
            m_data.characters16 = const_cast<UChar*>(string.characters16()) + startOffset;
            m_is8Bit = false;
        }
    }

    void clear()
    {
        m_data.characters8 = 0;
        m_length = 0;
        m_is8Bit = true;
    }

    bool is8Bit() const { return m_is8Bit; }
    const LChar* characters8() const { ASSERT(is8Bit()); return m_data.characters8; }
    const UChar* characters16() const { ASSERT(!is8Bit()); return m_data.characters16; }
    template <typename CharacterType>
    const CharacterType* characters() const;

    unsigned length() const { return m_length; }
    void setLength(unsigned length) { m_length = length; }

    UChar operator[](unsigned i) const
    {
        ASSERT_WITH_SECURITY_IMPLICATION(i < m_length);
        if (is8Bit())
            return m_data.characters8[i];
        return m_data.characters16[i];
    }

    bool equalIgnoringCase(const char* str) const
    {
        bool match = is8Bit() ? WTF::equalIgnoringCase(str, characters8(), length()) : WTF::equalIgnoringCase(str, characters16(), length());
        if (!match)
            return false;
        ASSERT(strlen(str) >= length());
        return str[length()] == '\0';
    }

    template <size_t strLength>
    bool startsWithIgnoringCase(const char (&str)[strLength]) const
    {
        return startsWithIgnoringCase(str, strLength - 1);
    }

    bool startsWithIgnoringCase(const char* str, size_t strLength) const
    {
        if (length() < strLength)
            return false;
        return is8Bit() ? WTF::equalIgnoringCase(str, characters8(), strLength) : WTF::equalIgnoringCase(str, characters16(), strLength);
    }

    operator String() const { return is8Bit() ? String(m_data.characters8, m_length) : StringImpl::create8BitIfPossible(m_data.characters16, m_length); }
    operator AtomicString() const { return is8Bit() ? AtomicString(m_data.characters8, m_length) : AtomicString(m_data.characters16, m_length); }

    bool isFunction() const { return length() > 0 && (*this)[length() - 1] == '('; }

    union {
        const LChar* characters8;
        const UChar* characters16;
    } m_data;
    unsigned m_length;
    bool m_is8Bit;
};

template <>
inline const LChar* CSSParserString::characters<LChar>() const { return characters8(); }

template <>
inline const UChar* CSSParserString::characters<UChar>() const { return characters16(); }

struct CSSParserFunction;
class CSSParserValueList;

struct CSSParserValue {
    CSSValueID id;
    bool isInt;
    union {
        double fValue;
        int iValue;
        CSSParserString string;
        CSSParserFunction* function;
        CSSParserValueList* valueList;
    };
    enum {
        Operator  = 0x100000,
        Function  = 0x100001,
        ValueList = 0x100002,
    };
    int unit;

    inline void setFromNumber(double value, int unit = CSSPrimitiveValue::CSS_NUMBER);
    inline void setFromFunction(CSSParserFunction*);
    inline void setFromValueList(PassOwnPtr<CSSParserValueList>);
};

class CSSParserValueList {
    WTF_MAKE_FAST_ALLOCATED;
public:
    CSSParserValueList()
        : m_current(0)
    {
    }
    ~CSSParserValueList();

    void addValue(const CSSParserValue&);
    void insertValueAt(unsigned, const CSSParserValue&);
    void stealValues(CSSParserValueList&);

    unsigned size() const { return m_values.size(); }
    unsigned currentIndex() { return m_current; }
    CSSParserValue* current() { return m_current < m_values.size() ? &m_values[m_current] : 0; }
    CSSParserValue* next() { ++m_current; return current(); }
    CSSParserValue* previous()
    {
        if (!m_current)
            return 0;
        --m_current;
        return current();
    }
    void setCurrentIndex(unsigned index)
    {
        ASSERT(index < m_values.size());
        if (index < m_values.size())
            m_current = index;
    }

    CSSParserValue* valueAt(unsigned i) { return i < m_values.size() ? &m_values[i] : 0; }

    void clearAndLeakValues() { m_values.clear(); m_current = 0;}
    void destroyAndClear();

private:
    unsigned m_current;
    Vector<CSSParserValue, 4> m_values;
};

struct CSSParserFunction {
    WTF_MAKE_FAST_ALLOCATED;
public:
    CSSParserString name;
    OwnPtr<CSSParserValueList> args;
};

class CSSParserSelector {
    WTF_MAKE_NONCOPYABLE(CSSParserSelector); WTF_MAKE_FAST_ALLOCATED;
public:
    CSSParserSelector();
    explicit CSSParserSelector(const QualifiedName&);
    ~CSSParserSelector();

    PassOwnPtr<CSSSelector> releaseSelector() { return m_selector.release(); }

    void setValue(const AtomicString& value) { m_selector->setValue(value); }
    void setAttribute(const QualifiedName& value, CSSSelector::AttributeMatchType matchType) { m_selector->setAttribute(value, matchType); }
    void setArgument(const AtomicString& value) { m_selector->setArgument(value); }
    void setMatch(CSSSelector::Match value) { m_selector->setMatch(value); }

    void adoptSelectorVector(Vector<OwnPtr<CSSParserSelector> >& selectorVector);

    bool hasHostPseudoSelector() const;

    CSSSelector::PseudoType pseudoType() const { return m_selector->pseudoType(); }
    bool isCustomPseudoElement() const { return m_selector->isCustomPseudoElement(); }

    bool isSimple() const;

    CSSParserSelector* tagHistory() const { return m_tagHistory.get(); }
    void setTagHistory(PassOwnPtr<CSSParserSelector> selector) { m_tagHistory = selector; }
    void clearTagHistory() { m_tagHistory.clear(); }
    void appendTagHistory(PassOwnPtr<CSSParserSelector>);
    void prependTagSelector(const QualifiedName&, bool tagIsForNamespaceRule = false);

private:
    OwnPtr<CSSSelector> m_selector;
    OwnPtr<CSSParserSelector> m_tagHistory;
};

inline void CSSParserValue::setFromNumber(double value, int unit)
{
    id = CSSValueInvalid;
    isInt = false;
    if (std::isfinite(value))
        fValue = value;
    else
        fValue = 0;
    this->unit = unit;
}

inline void CSSParserValue::setFromFunction(CSSParserFunction* function)
{
    id = CSSValueInvalid;
    this->function = function;
    unit = Function;
    isInt = false;
}

inline void CSSParserValue::setFromValueList(PassOwnPtr<CSSParserValueList> valueList)
{
    id = CSSValueInvalid;
    this->valueList = valueList.leakPtr();
    unit = ValueList;
    isInt = false;
}

}

#endif
