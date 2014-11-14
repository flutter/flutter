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

#ifndef EditingStyle_h
#define EditingStyle_h

#include "core/CSSPropertyNames.h"
#include "core/CSSValueKeywords.h"
#include "core/editing/WritingDirection.h"
#include "platform/fonts/FixedPitchFontType.h"
#include "platform/heap/Handle.h"
#include "wtf/Forward.h"
#include "wtf/RefCounted.h"
#include "wtf/RefPtr.h"
#include "wtf/TriState.h"
#include "wtf/Vector.h"
#include "wtf/text/WTFString.h"

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
    enum ShouldPreserveWritingDirection { PreserveWritingDirection, DoNotPreserveWritingDirection };
    enum ShouldExtractMatchingStyle { ExtractMatchingStyle, DoNotExtractMatchingStyle };
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
    bool textDirection(WritingDirection&) const;
    bool isEmpty() const;
    void overrideWithStyle(const StylePropertySet*);
    void clear();
    PassRefPtr<EditingStyle> copy() const;
    PassRefPtr<EditingStyle> extractAndRemoveBlockProperties();
    PassRefPtr<EditingStyle> extractAndRemoveTextDirection();
    void removeBlockProperties();
    void removeStyleAddedByElement(Element*);
    void removeStyleConflictingWithStyleOfElement(Element*);
    void collapseTextDecorationProperties();
    enum ShouldIgnoreTextOnlyProperties { IgnoreTextOnlyProperties, DoNotIgnoreTextOnlyProperties };
    TriState triStateOfStyle(EditingStyle*) const;
    TriState triStateOfStyle(const VisibleSelection&) const;
    bool conflictsWithInlineStyleOfElement(HTMLElement* element) const { return conflictsWithInlineStyleOfElement(element, 0, 0); }
    bool conflictsWithInlineStyleOfElement(HTMLElement* element, EditingStyle* extractedStyle, Vector<CSSPropertyID>& conflictingProperties) const
    {
        return conflictsWithInlineStyleOfElement(element, extractedStyle, &conflictingProperties);
    }
    bool conflictsWithImplicitStyleOfElement(HTMLElement*, EditingStyle* extractedStyle = 0, ShouldExtractMatchingStyle = DoNotExtractMatchingStyle) const;
    bool conflictsWithImplicitStyleOfAttributes(HTMLElement*) const;
    bool extractConflictingImplicitStyleOfAttributes(HTMLElement*, ShouldPreserveWritingDirection, EditingStyle* extractedStyle,
            Vector<QualifiedName>& conflictingAttributes, ShouldExtractMatchingStyle) const;
    bool styleIsPresentInComputedStyleOfNode(Node*) const;

    static bool elementIsStyledSpanOrHTMLEquivalent(const HTMLElement*);

    void mergeTypingStyle(Document*);
    enum CSSPropertyOverrideMode { OverrideValues, DoNotOverrideValues };
    void mergeInlineStyleOfElement(HTMLElement*, CSSPropertyOverrideMode, PropertiesToInclude = AllProperties);
    static PassRefPtr<EditingStyle> wrappingStyleForSerialization(ContainerNode* context, bool shouldAnnotate);
    void mergeStyleFromRules(Element*);
    void mergeStyleFromRulesForSerialization(Element*);
    void removeStyleFromRulesAndContext(Element*, ContainerNode* context);
    void removePropertiesInElementDefaultStyle(Element*);
    void addAbsolutePositioningFromElement(const Element&);
    void forceInline();
    int legacyFontSize(Document*) const;

    float fontSizeDelta() const { return m_fontSizeDelta; }
    bool hasFontSizeDelta() const { return m_fontSizeDelta != NoFontDelta; }

    static PassRefPtr<EditingStyle> styleAtSelectionStart(const VisibleSelection&, bool shouldUseBackgroundColorInEffect = false);
    static WritingDirection textDirectionForSelection(const VisibleSelection&, EditingStyle* typingStyle, bool& hasNestedOrMultipleEmbeddings);

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
    TriState triStateOfStyle(CSSStyleDeclaration* styleToCompare, ShouldIgnoreTextOnlyProperties) const;
    bool conflictsWithInlineStyleOfElement(HTMLElement*, EditingStyle* extractedStyle, Vector<CSSPropertyID>* conflictingProperties) const;
    void mergeInlineAndImplicitStyleOfElement(Element*, CSSPropertyOverrideMode, PropertiesToInclude);
    void mergeStyle(const StylePropertySet*, CSSPropertyOverrideMode);

    RefPtr<MutableStylePropertySet> m_mutableStyle;
    FixedPitchFontType m_fixedPitchFontType;
    float m_fontSizeDelta;

    friend class HTMLElementEquivalent;
    friend class HTMLAttributeEquivalent;
};

class StyleChange {
public:
    StyleChange()
        : m_applyBold(false)
        , m_applyItalic(false)
        , m_applyUnderline(false)
        , m_applyLineThrough(false)
        , m_applySubscript(false)
        , m_applySuperscript(false)
    { }

    StyleChange(EditingStyle*, const Position&);

    String cssStyle() const { return m_cssStyle; }
    bool applyBold() const { return m_applyBold; }
    bool applyItalic() const { return m_applyItalic; }
    bool applyUnderline() const { return m_applyUnderline; }
    bool applyLineThrough() const { return m_applyLineThrough; }
    bool applySubscript() const { return m_applySubscript; }
    bool applySuperscript() const { return m_applySuperscript; }
    bool applyFontColor() const { return m_applyFontColor.length() > 0; }
    bool applyFontFace() const { return m_applyFontFace.length() > 0; }
    bool applyFontSize() const { return m_applyFontSize.length() > 0; }

    String fontColor() { return m_applyFontColor; }
    String fontFace() { return m_applyFontFace; }
    String fontSize() { return m_applyFontSize; }

    bool operator==(const StyleChange& other)
    {
        return m_cssStyle == other.m_cssStyle
            && m_applyBold == other.m_applyBold
            && m_applyItalic == other.m_applyItalic
            && m_applyUnderline == other.m_applyUnderline
            && m_applyLineThrough == other.m_applyLineThrough
            && m_applySubscript == other.m_applySubscript
            && m_applySuperscript == other.m_applySuperscript
            && m_applyFontColor == other.m_applyFontColor
            && m_applyFontFace == other.m_applyFontFace
            && m_applyFontSize == other.m_applyFontSize;
    }
    bool operator!=(const StyleChange& other)
    {
        return !(*this == other);
    }
private:
    void extractTextStyles(Document*, MutableStylePropertySet*, FixedPitchFontType);

    String m_cssStyle;
    bool m_applyBold;
    bool m_applyItalic;
    bool m_applyUnderline;
    bool m_applyLineThrough;
    bool m_applySubscript;
    bool m_applySuperscript;
    String m_applyFontColor;
    String m_applyFontFace;
    String m_applyFontSize;
};

// FIXME: Remove these functions or make them non-global to discourage using CSSStyleDeclaration directly.
CSSValueID getIdentifierValue(CSSStyleDeclaration*, CSSPropertyID);
CSSValueID getIdentifierValue(StylePropertySet*, CSSPropertyID);

} // namespace blink

#endif // EditingStyle_h
