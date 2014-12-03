/*
 * Copyright (C) 2007, 2008, 2009 Apple Computer, Inc.
 * Copyright (C) 2010, 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
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

#include "sky/engine/config.h"
#include "sky/engine/core/editing/EditingStyle.h"

#include "gen/sky/core/HTMLNames.h"
#include "sky/engine/bindings/core/v8/ExceptionStatePlaceholder.h"
#include "sky/engine/core/css/CSSComputedStyleDeclaration.h"
#include "sky/engine/core/css/CSSPropertyMetadata.h"
#include "sky/engine/core/css/CSSValueList.h"
#include "sky/engine/core/css/CSSValuePool.h"
#include "sky/engine/core/css/FontSize.h"
#include "sky/engine/core/css/StylePropertySet.h"
#include "sky/engine/core/css/StyleRule.h"
#include "sky/engine/core/css/parser/BisonCSSParser.h"
#include "sky/engine/core/css/resolver/StyleResolver.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/dom/Node.h"
#include "sky/engine/core/dom/NodeTraversal.h"
#include "sky/engine/core/dom/Position.h"
#include "sky/engine/core/dom/QualifiedName.h"
#include "sky/engine/core/editing/Editor.h"
#include "sky/engine/core/editing/FrameSelection.h"
#include "sky/engine/core/editing/HTMLInterchange.h"
#include "sky/engine/core/editing/htmlediting.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/rendering/RenderBox.h"
#include "sky/engine/core/rendering/RenderObject.h"
#include "sky/engine/core/rendering/style/RenderStyle.h"

namespace blink {

static const CSSPropertyID& textDecorationPropertyForEditing()
{
    static const CSSPropertyID property = RuntimeEnabledFeatures::css3TextDecorationsEnabled() ? CSSPropertyTextDecorationLine : CSSPropertyTextDecoration;
    return property;
}

// Editing style properties must be preserved during editing operation.
// e.g. when a user inserts a new paragraph, all properties listed here must be copied to the new paragraph.
// NOTE: Use either allEditingProperties() or inheritableEditingProperties() to
// respect runtime enabling of properties.
static const CSSPropertyID staticEditingProperties[] = {
    CSSPropertyBackgroundColor,
    CSSPropertyColor,
    CSSPropertyFontFamily,
    CSSPropertyFontSize,
    CSSPropertyFontStyle,
    CSSPropertyFontVariant,
    CSSPropertyFontWeight,
    CSSPropertyLetterSpacing,
    CSSPropertyLineHeight,
    CSSPropertyOrphans,
    CSSPropertyTextAlign,
    // FIXME: CSSPropertyTextDecoration needs to be removed when CSS3 Text
    // Decoration feature is no longer experimental.
    CSSPropertyTextDecoration,
    CSSPropertyTextDecorationLine,
    CSSPropertyTextIndent,
    CSSPropertyWhiteSpace,
    CSSPropertyWidows,
    CSSPropertyWordSpacing,
    CSSPropertyWebkitTextDecorationsInEffect,
    CSSPropertyWebkitTextFillColor,
    CSSPropertyWebkitTextStrokeColor,
    CSSPropertyWebkitTextStrokeWidth,
};

enum EditingPropertiesType { OnlyInheritableEditingProperties, AllEditingProperties };

static const Vector<CSSPropertyID>& allEditingProperties()
{
    DEFINE_STATIC_LOCAL(Vector<CSSPropertyID>, properties, ());
    if (properties.isEmpty()) {
        CSSPropertyMetadata::filterEnabledCSSPropertiesIntoVector(staticEditingProperties, WTF_ARRAY_LENGTH(staticEditingProperties), properties);
        if (RuntimeEnabledFeatures::css3TextDecorationsEnabled())
            properties.remove(properties.find(CSSPropertyTextDecoration));
    }
    return properties;
}

static const Vector<CSSPropertyID>& inheritableEditingProperties()
{
    DEFINE_STATIC_LOCAL(Vector<CSSPropertyID>, properties, ());
    if (properties.isEmpty()) {
        CSSPropertyMetadata::filterEnabledCSSPropertiesIntoVector(staticEditingProperties, WTF_ARRAY_LENGTH(staticEditingProperties), properties);
        for (size_t index = 0; index < properties.size();) {
            if (!CSSPropertyMetadata::isInheritedProperty(properties[index])) {
                properties.remove(index);
                continue;
            }
            ++index;
        }
    }
    return properties;
}

template <class StyleDeclarationType>
static PassRefPtr<MutableStylePropertySet> copyEditingProperties(StyleDeclarationType* style, EditingPropertiesType type = OnlyInheritableEditingProperties)
{
    if (type == AllEditingProperties)
        return style->copyPropertiesInSet(allEditingProperties());
    return style->copyPropertiesInSet(inheritableEditingProperties());
}

static inline bool isEditingProperty(int id)
{
    return allEditingProperties().contains(static_cast<CSSPropertyID>(id));
}

static PassRefPtr<MutableStylePropertySet> editingStyleFromComputedStyle(PassRefPtr<CSSComputedStyleDeclaration> style, EditingPropertiesType type = OnlyInheritableEditingProperties)
{
    if (!style)
        return MutableStylePropertySet::create();
    return copyEditingProperties(style.get(), type);
}

enum LegacyFontSizeMode { AlwaysUseLegacyFontSize, UseLegacyFontSizeOnlyIfPixelValuesMatch };

static bool isTransparentColorValue(CSSValue*);
static bool hasTransparentBackgroundColor(CSSStyleDeclaration*);

static PassRefPtr<CSSValue> backgroundColorInEffect(Node*);

class HTMLElementEquivalent {
    WTF_MAKE_FAST_ALLOCATED;
    DECLARE_EMPTY_VIRTUAL_DESTRUCTOR_WILL_BE_REMOVED(HTMLElementEquivalent);
public:
    static PassOwnPtr<HTMLElementEquivalent> create(CSSPropertyID propertyID, CSSValueID primitiveValue, const HTMLQualifiedName& tagName)
    {
        return adoptPtr(new HTMLElementEquivalent(propertyID, primitiveValue, tagName));
    }

    virtual bool matches(const Element* element) const { return !m_tagName || element->hasTagName(*m_tagName); }
    virtual bool hasAttribute() const { return false; }
    virtual bool propertyExistsInStyle(const StylePropertySet* style) const { return style->getPropertyCSSValue(m_propertyID); }
    virtual bool valueIsPresentInStyle(HTMLElement*, StylePropertySet*) const;
    virtual void addToStyle(Element*, EditingStyle*) const;

protected:
    HTMLElementEquivalent(CSSPropertyID);
    HTMLElementEquivalent(CSSPropertyID, const HTMLQualifiedName& tagName);
    HTMLElementEquivalent(CSSPropertyID, CSSValueID primitiveValue, const HTMLQualifiedName& tagName);
    const CSSPropertyID m_propertyID;
    const RefPtr<CSSPrimitiveValue> m_primitiveValue;
    const HTMLQualifiedName* m_tagName; // We can store a pointer because HTML tag names are const global.
};

DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(HTMLElementEquivalent);

HTMLElementEquivalent::HTMLElementEquivalent(CSSPropertyID id)
    : m_propertyID(id)
    , m_tagName(0)
{
}

HTMLElementEquivalent::HTMLElementEquivalent(CSSPropertyID id, const HTMLQualifiedName& tagName)
    : m_propertyID(id)
    , m_tagName(&tagName)
{
}

HTMLElementEquivalent::HTMLElementEquivalent(CSSPropertyID id, CSSValueID primitiveValue, const HTMLQualifiedName& tagName)
    : m_propertyID(id)
    , m_primitiveValue(CSSPrimitiveValue::createIdentifier(primitiveValue))
    , m_tagName(&tagName)
{
    ASSERT(primitiveValue != CSSValueInvalid);
}

bool HTMLElementEquivalent::valueIsPresentInStyle(HTMLElement* element, StylePropertySet* style) const
{
    RefPtr<CSSValue> value = style->getPropertyCSSValue(m_propertyID);
    return matches(element) && value && value->isPrimitiveValue() && toCSSPrimitiveValue(value.get())->getValueID() == m_primitiveValue->getValueID();
}

void HTMLElementEquivalent::addToStyle(Element*, EditingStyle* style) const
{
    style->setProperty(m_propertyID, m_primitiveValue->cssText());
}

class HTMLTextDecorationEquivalent final : public HTMLElementEquivalent {
public:
    static PassOwnPtr<HTMLElementEquivalent> create(CSSValueID primitiveValue, const HTMLQualifiedName& tagName)
    {
        return adoptPtr(new HTMLTextDecorationEquivalent(primitiveValue, tagName));
    }
    virtual bool propertyExistsInStyle(const StylePropertySet*) const override;
    virtual bool valueIsPresentInStyle(HTMLElement*, StylePropertySet*) const override;

private:
    HTMLTextDecorationEquivalent(CSSValueID primitiveValue, const HTMLQualifiedName& tagName);
};

HTMLTextDecorationEquivalent::HTMLTextDecorationEquivalent(CSSValueID primitiveValue, const HTMLQualifiedName& tagName)
    : HTMLElementEquivalent(textDecorationPropertyForEditing(), primitiveValue, tagName)
    // m_propertyID is used in HTMLElementEquivalent::addToStyle
{
}

bool HTMLTextDecorationEquivalent::propertyExistsInStyle(const StylePropertySet* style) const
{
    return style->getPropertyCSSValue(CSSPropertyWebkitTextDecorationsInEffect)
        || style->getPropertyCSSValue(textDecorationPropertyForEditing());
}

bool HTMLTextDecorationEquivalent::valueIsPresentInStyle(HTMLElement* element, StylePropertySet* style) const
{
    RefPtr<CSSValue> styleValue = style->getPropertyCSSValue(CSSPropertyWebkitTextDecorationsInEffect);
    if (!styleValue)
        styleValue = style->getPropertyCSSValue(textDecorationPropertyForEditing());
    return matches(element) && styleValue && styleValue->isValueList() && toCSSValueList(styleValue.get())->hasValue(m_primitiveValue.get());
}

class HTMLAttributeEquivalent : public HTMLElementEquivalent {
public:
    static PassOwnPtr<HTMLAttributeEquivalent> create(CSSPropertyID propertyID, const HTMLQualifiedName& tagName, const QualifiedName& attrName)
    {
        return adoptPtr(new HTMLAttributeEquivalent(propertyID, tagName, attrName));
    }
    static PassOwnPtr<HTMLAttributeEquivalent> create(CSSPropertyID propertyID, const QualifiedName& attrName)
    {
        return adoptPtr(new HTMLAttributeEquivalent(propertyID, attrName));
    }

    virtual bool matches(const Element* element) const override { return HTMLElementEquivalent::matches(element) && element->hasAttribute(m_attrName); }
    virtual bool hasAttribute() const override { return true; }
    virtual bool valueIsPresentInStyle(HTMLElement*, StylePropertySet*) const override;
    virtual void addToStyle(Element*, EditingStyle*) const override;
    virtual PassRefPtr<CSSValue> attributeValueAsCSSValue(Element*) const;
    inline const QualifiedName& attributeName() const { return m_attrName; }

protected:
    HTMLAttributeEquivalent(CSSPropertyID, const HTMLQualifiedName& tagName, const QualifiedName& attrName);
    HTMLAttributeEquivalent(CSSPropertyID, const QualifiedName& attrName);
    const QualifiedName& m_attrName; // We can store a reference because HTML attribute names are const global.
};

HTMLAttributeEquivalent::HTMLAttributeEquivalent(CSSPropertyID id, const HTMLQualifiedName& tagName, const QualifiedName& attrName)
    : HTMLElementEquivalent(id, tagName)
    , m_attrName(attrName)
{
}

HTMLAttributeEquivalent::HTMLAttributeEquivalent(CSSPropertyID id, const QualifiedName& attrName)
    : HTMLElementEquivalent(id)
    , m_attrName(attrName)
{
}

bool HTMLAttributeEquivalent::valueIsPresentInStyle(HTMLElement* element, StylePropertySet* style) const
{
    RefPtr<CSSValue> value = attributeValueAsCSSValue(element);
    RefPtr<CSSValue> styleValue = style->getPropertyCSSValue(m_propertyID);

    return compareCSSValuePtr(value, styleValue);
}

void HTMLAttributeEquivalent::addToStyle(Element* element, EditingStyle* style) const
{
    if (RefPtr<CSSValue> value = attributeValueAsCSSValue(element))
        style->setProperty(m_propertyID, value->cssText());
}

PassRefPtr<CSSValue> HTMLAttributeEquivalent::attributeValueAsCSSValue(Element* element) const
{
    ASSERT(element);
    const AtomicString& value = element->getAttribute(m_attrName);
    if (value.isNull())
        return nullptr;

    RefPtr<MutableStylePropertySet> dummyStyle = nullptr;
    dummyStyle = MutableStylePropertySet::create();
    dummyStyle->setProperty(m_propertyID, value);
    return dummyStyle->getPropertyCSSValue(m_propertyID);
}

float EditingStyle::NoFontDelta = 0.0f;

EditingStyle::EditingStyle()
    : m_fixedPitchFontType(NonFixedPitchFont)
    , m_fontSizeDelta(NoFontDelta)
{
}

EditingStyle::EditingStyle(ContainerNode* node, PropertiesToInclude propertiesToInclude)
    : m_fixedPitchFontType(NonFixedPitchFont)
    , m_fontSizeDelta(NoFontDelta)
{
    init(node, propertiesToInclude);
}

EditingStyle::EditingStyle(const Position& position, PropertiesToInclude propertiesToInclude)
    : m_fixedPitchFontType(NonFixedPitchFont)
    , m_fontSizeDelta(NoFontDelta)
{
    init(position.deprecatedNode(), propertiesToInclude);
}

EditingStyle::EditingStyle(const StylePropertySet* style)
    : m_mutableStyle(style ? style->mutableCopy() : nullptr)
    , m_fixedPitchFontType(NonFixedPitchFont)
    , m_fontSizeDelta(NoFontDelta)
{
    extractFontSizeDelta();
}

EditingStyle::EditingStyle(CSSPropertyID propertyID, const String& value)
    : m_mutableStyle(nullptr)
    , m_fixedPitchFontType(NonFixedPitchFont)
    , m_fontSizeDelta(NoFontDelta)
{
    setProperty(propertyID, value);
}

EditingStyle::~EditingStyle()
{
}

void EditingStyle::init(Node* node, PropertiesToInclude propertiesToInclude)
{
    RefPtr<CSSComputedStyleDeclaration> computedStyleAtPosition = CSSComputedStyleDeclaration::create(node);
    m_mutableStyle = propertiesToInclude == AllProperties && computedStyleAtPosition ? computedStyleAtPosition->copyProperties() : editingStyleFromComputedStyle(computedStyleAtPosition);

    if (propertiesToInclude == EditingPropertiesInEffect) {
        if (RefPtr<CSSValue> value = backgroundColorInEffect(node))
            m_mutableStyle->setProperty(CSSPropertyBackgroundColor, value->cssText());
        if (RefPtr<CSSValue> value = computedStyleAtPosition->getPropertyCSSValue(CSSPropertyWebkitTextDecorationsInEffect))
            m_mutableStyle->setProperty(CSSPropertyTextDecoration, value->cssText());
    }

    if (node && node->computedStyle()) {
        RenderStyle* renderStyle = node->computedStyle();
        removeTextFillAndStrokeColorsIfNeeded(renderStyle);
        replaceFontSizeByKeywordIfPossible(renderStyle, computedStyleAtPosition.get());
    }

    m_fixedPitchFontType = computedStyleAtPosition->fixedPitchFontType();
    extractFontSizeDelta();
}

void EditingStyle::removeTextFillAndStrokeColorsIfNeeded(RenderStyle* renderStyle)
{
    // If a node's text fill color is currentColor, then its children use
    // their font-color as their text fill color (they don't
    // inherit it).  Likewise for stroke color.
    if (renderStyle->textFillColor().isCurrentColor())
        m_mutableStyle->removeProperty(CSSPropertyWebkitTextFillColor);
    if (renderStyle->textStrokeColor().isCurrentColor())
        m_mutableStyle->removeProperty(CSSPropertyWebkitTextStrokeColor);
}

void EditingStyle::setProperty(CSSPropertyID propertyID, const String& value, bool important)
{
    if (!m_mutableStyle)
        m_mutableStyle = MutableStylePropertySet::create();

    m_mutableStyle->setProperty(propertyID, value, important);
}

void EditingStyle::replaceFontSizeByKeywordIfPossible(RenderStyle* renderStyle, CSSComputedStyleDeclaration* computedStyle)
{
    ASSERT(renderStyle);
    if (renderStyle->fontDescription().keywordSize())
        m_mutableStyle->setProperty(CSSPropertyFontSize, computedStyle->getFontSizeCSSValuePreferringKeyword()->cssText());
}

void EditingStyle::extractFontSizeDelta()
{
    if (!m_mutableStyle)
        return;

    if (m_mutableStyle->getPropertyCSSValue(CSSPropertyFontSize)) {
        // Explicit font size overrides any delta.
        m_mutableStyle->removeProperty(CSSPropertyWebkitFontSizeDelta);
        return;
    }

    // Get the adjustment amount out of the style.
    RefPtr<CSSValue> value = m_mutableStyle->getPropertyCSSValue(CSSPropertyWebkitFontSizeDelta);
    if (!value || !value->isPrimitiveValue())
        return;

    CSSPrimitiveValue* primitiveValue = toCSSPrimitiveValue(value.get());

    // Only PX handled now. If we handle more types in the future, perhaps
    // a switch statement here would be more appropriate.
    if (!primitiveValue->isPx())
        return;

    m_fontSizeDelta = primitiveValue->getFloatValue();
    m_mutableStyle->removeProperty(CSSPropertyWebkitFontSizeDelta);
}

bool EditingStyle::isEmpty() const
{
    return (!m_mutableStyle || m_mutableStyle->isEmpty()) && m_fontSizeDelta == NoFontDelta;
}

void EditingStyle::clear()
{
    m_mutableStyle.clear();
    m_fixedPitchFontType = NonFixedPitchFont;
    m_fontSizeDelta = NoFontDelta;
}

PassRefPtr<EditingStyle> EditingStyle::copy() const
{
    RefPtr<EditingStyle> copy = EditingStyle::create();
    if (m_mutableStyle)
        copy->m_mutableStyle = m_mutableStyle->mutableCopy();
    copy->m_fixedPitchFontType = m_fixedPitchFontType;
    copy->m_fontSizeDelta = m_fontSizeDelta;
    return copy;
}

void EditingStyle::removeBlockProperties()
{
    if (!m_mutableStyle)
        return;

    m_mutableStyle->removeBlockProperties();
}

static const Vector<OwnPtr<HTMLElementEquivalent> >& htmlElementEquivalents()
{
    DEFINE_STATIC_LOCAL(Vector<OwnPtr<HTMLElementEquivalent> >, HTMLElementEquivalents, ());
    return HTMLElementEquivalents;
}

static const Vector<OwnPtr<HTMLAttributeEquivalent> >& htmlAttributeEquivalents()
{
    DEFINE_STATIC_LOCAL(Vector<OwnPtr<HTMLAttributeEquivalent> >, HTMLAttributeEquivalents, ());
    return HTMLAttributeEquivalents;
}

bool EditingStyle::elementIsStyledSpanOrHTMLEquivalent(const HTMLElement* element)
{
    ASSERT(element);
    bool elementIsSpanOrElementEquivalent = false;
    const Vector<OwnPtr<HTMLElementEquivalent> >& HTMLElementEquivalents = htmlElementEquivalents();
    size_t i;
    for (i = 0; i < HTMLElementEquivalents.size(); ++i) {
        if (HTMLElementEquivalents[i]->matches(element)) {
            elementIsSpanOrElementEquivalent = true;
            break;
        }
    }

    AttributeCollection attributes = element->attributes();
    if (attributes.isEmpty())
        return elementIsSpanOrElementEquivalent; // span, b, etc... without any attributes

    unsigned matchedAttributes = 0;
    const Vector<OwnPtr<HTMLAttributeEquivalent> >& HTMLAttributeEquivalents = htmlAttributeEquivalents();
    for (size_t i = 0; i < HTMLAttributeEquivalents.size(); ++i) {
        if (HTMLAttributeEquivalents[i]->matches(element) && HTMLAttributeEquivalents[i]->attributeName() != HTMLNames::dirAttr)
            matchedAttributes++;
    }

    if (!elementIsSpanOrElementEquivalent && !matchedAttributes)
        return false; // element is not a span, a html element equivalent, or font element.

    if (element->getAttribute(HTMLNames::classAttr) == AppleStyleSpanClass)
        matchedAttributes++;

    if (element->hasAttribute(HTMLNames::styleAttr)) {
        if (const StylePropertySet* style = element->inlineStyle()) {
            unsigned propertyCount = style->propertyCount();
            for (unsigned i = 0; i < propertyCount; ++i) {
                if (!isEditingProperty(style->propertyAt(i).id()))
                    return false;
            }
        }
        matchedAttributes++;
    }

    // font with color attribute, span with style attribute, etc...
    ASSERT(matchedAttributes <= attributes.size());
    return matchedAttributes >= attributes.size();
}

void EditingStyle::mergeTypingStyle(Document* document)
{
    ASSERT(document);

    RefPtr<EditingStyle> typingStyle = document->frame()->selection().typingStyle();
    if (!typingStyle || typingStyle == this)
        return;

    mergeStyle(typingStyle->style(), OverrideValues);
}

static void mergeTextDecorationValues(CSSValueList* mergedValue, const CSSValueList* valueToMerge)
{
    DEFINE_STATIC_REF_WILL_BE_PERSISTENT(CSSPrimitiveValue, underline, (CSSPrimitiveValue::createIdentifier(CSSValueUnderline)));
    DEFINE_STATIC_REF_WILL_BE_PERSISTENT(CSSPrimitiveValue, lineThrough, (CSSPrimitiveValue::createIdentifier(CSSValueLineThrough)));
    if (valueToMerge->hasValue(underline) && !mergedValue->hasValue(underline))
        mergedValue->append(underline);

    if (valueToMerge->hasValue(lineThrough) && !mergedValue->hasValue(lineThrough))
        mergedValue->append(lineThrough);
}

void EditingStyle::mergeStyle(const StylePropertySet* style, CSSPropertyOverrideMode mode)
{
    if (!style)
        return;

    if (!m_mutableStyle) {
        m_mutableStyle = style->mutableCopy();
        return;
    }

    unsigned propertyCount = style->propertyCount();
    for (unsigned i = 0; i < propertyCount; ++i) {
        StylePropertySet::PropertyReference property = style->propertyAt(i);
        RefPtr<CSSValue> value = m_mutableStyle->getPropertyCSSValue(property.id());

        // text decorations never override values
        if ((property.id() == textDecorationPropertyForEditing() || property.id() == CSSPropertyWebkitTextDecorationsInEffect) && property.value()->isValueList() && value) {
            if (value->isValueList()) {
                mergeTextDecorationValues(toCSSValueList(value.get()), toCSSValueList(property.value()));
                continue;
            }
            value = nullptr; // text-decoration: none is equivalent to not having the property
        }

        if (mode == OverrideValues || (mode == DoNotOverrideValues && !value))
            m_mutableStyle->setProperty(property.id(), property.value()->cssText(), property.isImportant());
    }
}

bool isTransparentColorValue(CSSValue* cssValue)
{
    if (!cssValue)
        return true;
    if (!cssValue->isPrimitiveValue())
        return false;
    CSSPrimitiveValue* value = toCSSPrimitiveValue(cssValue);
    if (value->isRGBColor())
        return !alphaChannel(value->getRGBA32Value());
    return false;
}

bool hasTransparentBackgroundColor(CSSStyleDeclaration* style)
{
    RefPtr<CSSValue> cssValue = style->getPropertyCSSValueInternal(CSSPropertyBackgroundColor);
    return isTransparentColorValue(cssValue.get());
}

PassRefPtr<CSSValue> backgroundColorInEffect(Node* node)
{
    for (Node* ancestor = node; ancestor; ancestor = ancestor->parentNode()) {
        RefPtr<CSSComputedStyleDeclaration> ancestorStyle = CSSComputedStyleDeclaration::create(ancestor);
        if (!hasTransparentBackgroundColor(ancestorStyle.get()))
            return ancestorStyle->getPropertyCSSValue(CSSPropertyBackgroundColor);
    }
    return nullptr;
}

}
