/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
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

#ifndef Text_h
#define Text_h

#include "core/dom/CharacterData.h"

namespace blink {

class ExceptionState;
class RenderText;

class Text : public CharacterData {
    DEFINE_WRAPPERTYPEINFO();
public:
    static const unsigned defaultLengthLimit = 1 << 16;

    static PassRefPtr<Text> create(Document&, const String&);
    static PassRefPtr<Text> createEditingText(Document&, const String&);

    RenderText* renderer() const;

    // mergeNextSiblingNodesIfPossible() merges next sibling nodes if possible
    // then returns a node not merged.
    PassRefPtr<Node> mergeNextSiblingNodesIfPossible();
    PassRefPtr<Text> splitText(unsigned offset, ExceptionState&);

    // DOM Level 3: http://www.w3.org/TR/DOM-Level-3-Core/core.html#ID-1312295772

    String wholeText() const;
    PassRefPtr<Text> replaceWholeText(const String&);

    void recalcTextStyle(StyleRecalcChange, Text* nextTextSibling);
    bool textRendererIsNeeded(const RenderStyle&, const RenderObject& parent);
    RenderText* createTextRenderer(RenderStyle*);
    void updateTextRenderer(unsigned offsetOfReplacedData, unsigned lengthOfReplacedData, RecalcStyleBehavior = DoNotRecalcStyle);

    virtual void attach(const AttachContext& = AttachContext()) override final;

    virtual bool canContainRangeEndPoint() const override final { return true; }
    virtual NodeType nodeType() const override;

protected:
    Text(TreeScope& treeScope, const String& data, ConstructionType type)
        : CharacterData(treeScope, data, type)
    {
        ScriptWrappable::init(this);
    }

private:
    virtual String nodeName() const override;
    virtual PassRefPtr<Node> cloneNode(bool deep = true) override final;

    bool isTextNode() const = delete; // This will catch anyone doing an unnecessary check.

    bool needsWhitespaceRenderer();

    virtual PassRefPtr<Text> cloneWithData(const String&);

#ifndef NDEBUG
    virtual void formatForDebugger(char* buffer, unsigned length) const override;
#endif
};

DEFINE_NODE_TYPE_CASTS(Text, isTextNode());

} // namespace blink

#endif // Text_h
