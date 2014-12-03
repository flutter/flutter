/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
 * Copyright (C) 2013 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
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

#ifndef SKY_ENGINE_CORE_EDITING_EDITINGSTYLE_H_
#define SKY_ENGINE_CORE_EDITING_EDITINGSTYLE_H_

#include "gen/sky/core/CSSPropertyNames.h"
#include "gen/sky/core/CSSValueKeywords.h"
#include "sky/engine/core/editing/WritingDirection.h"
#include "sky/engine/platform/fonts/FixedPitchFontType.h"
#include "sky/engine/platform/heap/Handle.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/RefCounted.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/engine/wtf/TriState.h"
#include "sky/engine/wtf/Vector.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink {

class CSSStyleDeclaration;
class CSSComputedStyleDeclaration;
class CSSPrimitiveValue;
class CSSValue;
class ContainerNode;
class Document;
class Element;
class HTMLElement;
class MutableStylePropertySet;
class Node;
class Position;
class QualifiedName;
class RenderStyle;
class StylePropertySet;
class VisibleSelection;

class EditingStyle final : public RefCounted<EditingStyle> {
public:

    enum PropertiesToInclude { AllProperties, OnlyEditingInheritableProperties, EditingPropertiesInEffect };
    static float NoFontDelta;

    static PassRefPtr<EditingStyle> create()
    {
        return adoptRef(new EditingStyle());
    }

    static PassRefPtr<EditingStyle> create(ContainerNode* node, PropertiesToInclude propertiesToInclude = OnlyEditingInheritableProperties)
    {
        return adoptRef(new EditingStyle(node, propertiesToInclude));
    }

    static PassRefPtr<EditingStyle> create(const Position& position, PropertiesToInclude propertiesToInclude = OnlyEditingInheritableProperties)
    {
        return adoptRef(new EditingStyle(position, propertiesToInclude));
    }

    static PassRefPtr<EditingStyle> create(const StylePropertySet* style)
    {
        return adoptRef(new EditingStyle(style));
    }

    static PassRefPtr<EditingStyle> create(CSSPropertyID propertyID, const String& value)
    {
        return adoptRef(new EditingStyle(propertyID, value));
    }

    ~EditingStyle();

    MutableStylePropertySet* style() { return m_mutableStyle.get(); }

    bool isEmpty() const;

    void clear();
    PassRefPtr<EditingStyle> copy() const;

    void removeBlockProperties();

    static bool elementIsStyledSpanOrHTMLEquivalent(const HTMLElement*);

    void mergeTypingStyle(Document*);

private:
    EditingStyle();
    EditingStyle(ContainerNode*, PropertiesToInclude);
    EditingStyle(const Position&, PropertiesToInclude);
    explicit EditingStyle(const StylePropertySet*);
    EditingStyle(CSSPropertyID, const String& value);
    void init(Node*, PropertiesToInclude);
    void removeTextFillAndStrokeColorsIfNeeded(RenderStyle*);
    void setProperty(CSSPropertyID, const String& value, bool important = false);
    void replaceFontSizeByKeywordIfPossible(RenderStyle*, CSSComputedStyleDeclaration*);
    void extractFontSizeDelta();

    enum CSSPropertyOverrideMode { OverrideValues, DoNotOverrideValues };
    void mergeStyle(const StylePropertySet*, CSSPropertyOverrideMode);

    RefPtr<MutableStylePropertySet> m_mutableStyle;
    FixedPitchFontType m_fixedPitchFontType;
    float m_fontSizeDelta;

    friend class HTMLElementEquivalent;
    friend class HTMLAttributeEquivalent;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_EDITING_EDITINGSTYLE_H_
