/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2008, 2009 Apple Inc. All rights reserved.
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
 *
 */

#ifndef CharacterData_h
#define CharacterData_h

#include "core/dom/Node.h"
#include "wtf/text/WTFString.h"

namespace blink {

class ExceptionState;

class CharacterData : public Node {
    DEFINE_WRAPPERTYPEINFO();
public:
    void atomize();
    const String& data() const { return m_data; }
    void setData(const String&);
    unsigned length() const { return m_data.length(); }
    String substringData(unsigned offset, unsigned count, ExceptionState&);
    void appendData(const String&);
    void replaceData(unsigned offset, unsigned count, const String&, ExceptionState&);

    enum RecalcStyleBehavior { DoNotRecalcStyle, DeprecatedRecalcStyleImmediatlelyForEditing };
    void insertData(unsigned offset, const String&, ExceptionState&, RecalcStyleBehavior = DoNotRecalcStyle);
    void deleteData(unsigned offset, unsigned count, ExceptionState&, RecalcStyleBehavior = DoNotRecalcStyle);

    bool containsOnlyWhitespace() const;

    StringImpl* dataImpl() { return m_data.impl(); }

    void parserAppendData(const String&);

protected:
    CharacterData(TreeScope& treeScope, const String& text, ConstructionType type)
        : Node(&treeScope, type)
        , m_data(!text.isNull() ? text : emptyString())
    {
        ASSERT(type == CreateOther || type == CreateText || type == CreateEditingText);
        ScriptWrappable::init(this);
    }

    void setDataWithoutUpdate(const String& data)
    {
        ASSERT(!data.isNull());
        m_data = data;
    }
    void didModifyData(const String& oldValue);

    String m_data;

private:
    virtual String nodeValue() const OVERRIDE FINAL;
    virtual void setNodeValue(const String&) OVERRIDE FINAL;
    virtual bool isCharacterDataNode() const OVERRIDE FINAL { return true; }
    virtual int maxCharacterOffset() const OVERRIDE FINAL;
    virtual bool offsetInCharacters() const OVERRIDE FINAL;
    void setDataAndUpdate(const String&, unsigned offsetOfReplacedData, unsigned oldLength, unsigned newLength, RecalcStyleBehavior = DoNotRecalcStyle);

    bool isContainerNode() const WTF_DELETED_FUNCTION; // This will catch anyone doing an unnecessary check.
    bool isElementNode() const WTF_DELETED_FUNCTION; // This will catch anyone doing an unnecessary check.
};

DEFINE_NODE_TYPE_CASTS(CharacterData, isCharacterDataNode());

} // namespace blink

#endif // CharacterData_h
