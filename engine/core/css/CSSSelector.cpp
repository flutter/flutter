/*
 * Copyright (C) 1999-2003 Lars Knoll (knoll@kde.org)
 *               1999 Waldo Bastian (bastian@kde.org)
 *               2001 Andreas Schlapbach (schlpbch@iam.unibe.ch)
 *               2001-2003 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2002, 2006, 2007, 2008, 2009, 2010 Apple Inc. All rights reserved.
 * Copyright (C) 2008 David Smith (catfish.man@gmail.com)
 * Copyright (C) 2010 Google Inc. All rights reserved.
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
#include "sky/engine/core/css/CSSSelector.h"

#include "gen/sky/platform/RuntimeEnabledFeatures.h"
#include "sky/engine/core/css/CSSOMUtils.h"
#include "sky/engine/core/css/CSSSelectorList.h"
#include "sky/engine/wtf/Assertions.h"
#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/StdLibExtras.h"
#include "sky/engine/wtf/text/StringBuilder.h"

#ifndef NDEBUG
#include <stdio.h>
#endif

namespace blink {

struct SameSizeAsCSSSelector {
    unsigned bitfields;
    void *pointers[1];
};

COMPILE_ASSERT(sizeof(CSSSelector) == sizeof(SameSizeAsCSSSelector), CSSSelectorShouldStaySmall);

void CSSSelector::createRareData()
{
    ASSERT(m_match != Tag);
    if (m_hasRareData)
        return;
    AtomicString value(m_data.m_value);
    if (m_data.m_value)
        m_data.m_value->deref();
    m_data.m_rareData = RareData::create(value).leakRef();
    m_hasRareData = true;
}

PseudoId CSSSelector::pseudoId(PseudoType type)
{
    switch (type) {
    case PseudoUnknown:
    case PseudoHover:
    case PseudoFocus:
    case PseudoActive:
    case PseudoLang:
    case PseudoUserAgentCustomElement:
    case PseudoHost:
        return NOPSEUDO;
    case PseudoNotParsed:
        ASSERT_NOT_REACHED();
        return NOPSEUDO;
    }

    ASSERT_NOT_REACHED();
    return NOPSEUDO;
}

// Could be made smaller and faster by replacing pointer with an
// offset into a string buffer and making the bit fields smaller but
// that could not be maintained by hand.
struct NameToPseudoStruct {
    const char* string;
    unsigned type:8;
};

// This table should be kept sorted.
const static NameToPseudoStruct pseudoTypeMap[] = {
{"active",                        CSSSelector::PseudoActive},
{"focus",                         CSSSelector::PseudoFocus},
{"host",                          CSSSelector::PseudoHost},
{"host(",                         CSSSelector::PseudoHost},
{"hover",                         CSSSelector::PseudoHover},
{"lang(",                         CSSSelector::PseudoLang},
};

class NameToPseudoCompare {
public:
    NameToPseudoCompare(const AtomicString& key) : m_key(key) { ASSERT(m_key.is8Bit()); }

    bool operator()(const NameToPseudoStruct& entry, const NameToPseudoStruct&)
    {
        ASSERT(entry.string);
        const char* key = reinterpret_cast<const char*>(m_key.characters8());
        // If strncmp returns 0, then either the keys are equal, or |m_key| sorts before |entry|.
        return strncmp(entry.string, key, m_key.length()) < 0;
    }

private:
    const AtomicString& m_key;
};

static CSSSelector::PseudoType nameToPseudoType(const AtomicString& name)
{
    if (name.isNull() || !name.is8Bit())
        return CSSSelector::PseudoUnknown;

    const NameToPseudoStruct* pseudoTypeMapEnd = pseudoTypeMap + WTF_ARRAY_LENGTH(pseudoTypeMap);
    NameToPseudoStruct dummyKey = { 0, CSSSelector::PseudoUnknown };
    const NameToPseudoStruct* match = std::lower_bound(pseudoTypeMap, pseudoTypeMapEnd, dummyKey, NameToPseudoCompare(name));
    if (match == pseudoTypeMapEnd || match->string != name.string())
        return CSSSelector::PseudoUnknown;

    return static_cast<CSSSelector::PseudoType>(match->type);
}

#ifndef NDEBUG
void CSSSelector::show(int indent) const
{
    printf("%*sselectorText(): %s\n", indent, "", selectorText().ascii().data());
    printf("%*sm_match: %d\n", indent, "", m_match);
    printf("%*sisCustomPseudoElement(): %d\n", indent, "", isCustomPseudoElement());
    if (m_match != Tag)
        printf("%*svalue(): %s\n", indent, "", value().ascii().data());
    printf("%*spseudoType(): %d\n", indent, "", pseudoType());
    if (m_match == Tag)
        printf("%*stagQName().localName: %s\n", indent, "", tagQName().localName().ascii().data());
    printf("%*sisAttributeSelector(): %d\n", indent, "", isAttributeSelector());
    if (isAttributeSelector())
        printf("%*sattribute(): %s\n", indent, "", attribute().localName().ascii().data());
    printf("%*sargument(): %s\n", indent, "", argument().ascii().data());
}

void CSSSelector::show() const
{
    printf("\n******* CSSSelector::show(\"%s\") *******\n", selectorText().ascii().data());
    show(2);
    printf("******* end *******\n");
}
#endif

CSSSelector::PseudoType CSSSelector::parsePseudoType(const AtomicString& name)
{
    return nameToPseudoType(name);
}

void CSSSelector::extractPseudoType() const
{
    if (m_match != PseudoClass && m_match != PseudoElement)
        return;

    m_pseudoType = parsePseudoType(value());

    bool element = false; // pseudo-element
    bool compat = false; // single colon compatbility mode

    switch (m_pseudoType) {
    case PseudoUserAgentCustomElement:
        element = true;
        break;
    case PseudoUnknown:
    case PseudoHover:
    case PseudoFocus:
    case PseudoActive:
    case PseudoLang:
    case PseudoNotParsed:
    case PseudoHost:
        break;
    }

    if (m_match == PseudoClass && element) {
        if (!compat)
            m_pseudoType = PseudoUnknown;
        else
            m_match = PseudoElement;
    } else if (m_match == PseudoElement && !element)
        m_pseudoType = PseudoUnknown;
}

bool CSSSelector::operator==(const CSSSelector& other) const
{
    const CSSSelector* sel1 = this;
    const CSSSelector* sel2 = &other;

    while (sel1 && sel2) {
        if (sel1->attribute() != sel2->attribute()
            || sel1->m_match != sel2->m_match
            || sel1->value() != sel2->value()
            || sel1->pseudoType() != sel2->pseudoType()
            || sel1->argument() != sel2->argument()) {
            return false;
        }
        if (sel1->m_match == Tag) {
            if (sel1->tagQName() != sel2->tagQName())
                return false;
        }
        sel1 = sel1->tagHistory();
        sel2 = sel2->tagHistory();
    }

    if (sel1 || sel2)
        return false;

    return true;
}

String CSSSelector::selectorText(const String& rightSide) const
{
    StringBuilder str;

    if (m_match == CSSSelector::Tag && !m_tagIsForNamespaceRule) {
        str.append(tagQName().localName());
    }

    const CSSSelector* cs = this;
    while (true) {
        if (cs->m_match == CSSSelector::Id) {
            str.append('#');
            serializeIdentifier(cs->value(), str);
        } else if (cs->m_match == CSSSelector::Class) {
            str.append('.');
            serializeIdentifier(cs->value(), str);
        } else if (cs->m_match == CSSSelector::PseudoClass) {
            str.append(':');
            str.append(cs->value());

            switch (cs->pseudoType()) {
            case PseudoLang:
                str.append(cs->argument());
                str.append(')');
                break;
            case PseudoHost: {
                if (cs->selectorList()) {
                    const CSSSelector* firstSubSelector = cs->selectorList()->first();
                    for (const CSSSelector* subSelector = firstSubSelector; subSelector; subSelector = CSSSelectorList::next(*subSelector)) {
                        if (subSelector != firstSubSelector)
                            str.append(',');
                        str.append(subSelector->selectorText());
                    }
                    str.append(')');
                }
                break;
            }
            default:
                break;
            }
        } else if (cs->m_match == CSSSelector::PseudoElement) {
            str.appendLiteral("::");
            str.append(cs->value());
        } else if (cs->isAttributeSelector()) {
            str.append('[');
            str.append(cs->attribute().localName());
            if (cs->m_match == CSSSelector::Exact)
                str.append('=');
            if (cs->m_match != CSSSelector::Set) {
                serializeString(cs->value(), str);
                if (cs->attributeMatchType() == CaseInsensitive)
                    str.appendLiteral(" i");
            }
            str.append(']');
        }
        if (!cs->tagHistory())
            break;
        cs = cs->tagHistory();
    }

    return str.toString() + rightSide;
}

void CSSSelector::setAttribute(const QualifiedName& value, AttributeMatchType matchType)
{
    createRareData();
    m_data.m_rareData->m_attribute = value;
    m_data.m_rareData->m_bits.m_attributeMatchType = matchType;
}

void CSSSelector::setArgument(const AtomicString& value)
{
    createRareData();
    m_data.m_rareData->m_argument = value;
}

void CSSSelector::setSelectorList(PassOwnPtr<CSSSelectorList> selectorList)
{
    createRareData();
    m_data.m_rareData->m_selectorList = selectorList;
}

static bool validateSubSelector(const CSSSelector* selector)
{
    switch (selector->match()) {
    case CSSSelector::Tag:
    case CSSSelector::Id:
    case CSSSelector::Class:
    case CSSSelector::Exact:
    case CSSSelector::Set:
        return true;
    case CSSSelector::PseudoElement:
    case CSSSelector::Unknown:
        return false;
    case CSSSelector::PseudoClass:
        break;
    }

    switch (selector->pseudoType()) {
    case CSSSelector::PseudoHost:
        return true;
    default:
        return false;
    }
}

bool CSSSelector::isCompound() const
{
    if (!validateSubSelector(this))
        return false;

    const CSSSelector* prevSubSelector = this;
    const CSSSelector* subSelector = tagHistory();

    while (subSelector) {
        if (!validateSubSelector(subSelector))
            return false;

        prevSubSelector = subSelector;
        subSelector = subSelector->tagHistory();
    }

    return true;
}

CSSSelector::RareData::RareData(const AtomicString& value)
    : m_value(value)
    , m_bits()
    , m_attribute(anyName)
    , m_argument(nullAtom)
{
}

CSSSelector::RareData::~RareData()
{
}

} // namespace blink
