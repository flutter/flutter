/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
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

#ifndef StyleResolverState_h
#define StyleResolverState_h

#include "gen/sky/core/CSSPropertyNames.h"

#include "sky/engine/core/css/CSSToLengthConversionData.h"
#include "sky/engine/core/css/resolver/CSSToStyleMap.h"
#include "sky/engine/core/css/resolver/ElementResolveContext.h"
#include "sky/engine/core/css/resolver/ElementStyleResources.h"
#include "sky/engine/core/css/resolver/FontBuilder.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/rendering/style/RenderStyle.h"
#include "sky/engine/core/rendering/style/StyleInheritedData.h"

namespace blink {

class CSSAnimationUpdate;
class FontDescription;
class StyleRule;

class StyleResolverState {
    STACK_ALLOCATED();
    WTF_MAKE_NONCOPYABLE(StyleResolverState);
public:
    StyleResolverState(Document&, Element*, RenderStyle* parentStyle = 0);
    ~StyleResolverState();

    // In FontFaceSet and CanvasRenderingContext2D, we don't have an element to grab the document from.
    // This is why we have to store the document separately.
    Document& document() const { return *m_document; }
    // These are all just pass-through methods to ElementResolveContext.
    Element* element() const { return m_elementContext.element(); }
    const ContainerNode* parentNode() const { return m_elementContext.parentNode(); }
    const RenderStyle* rootElementStyle() const { return m_elementContext.rootElementStyle(); }

    bool distributedToInsertionPoint() const { return m_elementContext.distributedToInsertionPoint(); }

    const ElementResolveContext& elementContext() const { return m_elementContext; }

    void setStyle(PassRefPtr<RenderStyle> style) { m_style = style; m_cssToLengthConversionData.setStyle(m_style.get()); }
    const RenderStyle* style() const { return m_style.get(); }
    RenderStyle* style() { return m_style.get(); }
    PassRefPtr<RenderStyle> takeStyle() { return m_style.release(); }

    const CSSToLengthConversionData& cssToLengthConversionData() const { return m_cssToLengthConversionData; }

    void setAnimationUpdate(PassOwnPtr<CSSAnimationUpdate>);
    const CSSAnimationUpdate* animationUpdate() { return m_animationUpdate.get(); }
    PassOwnPtr<CSSAnimationUpdate> takeAnimationUpdate();

    void setParentStyle(PassRefPtr<RenderStyle> parentStyle) { m_parentStyle = parentStyle; }
    const RenderStyle* parentStyle() const { return m_parentStyle.get(); }
    RenderStyle* parentStyle() { return m_parentStyle.get(); }

    // Holds all attribute names found while applying "content" properties that contain an "attr()" value.
    Vector<AtomicString>& contentAttrValues() { return m_contentAttrValues; }

    void setLineHeightValue(CSSValue* value) { m_lineHeightValue = value; }
    CSSValue* lineHeightValue() { return m_lineHeightValue; }

    ElementStyleResources& elementStyleResources() { return m_elementStyleResources; }
    const CSSToStyleMap& styleMap() const { return m_styleMap; }
    CSSToStyleMap& styleMap() { return m_styleMap; }

    // FIXME: Once styleImage can be made to not take a StyleResolverState
    // this convenience function should be removed. As-is, without this, call
    // sites are extremely verbose.
    PassRefPtr<StyleImage> styleImage(CSSPropertyID propertyId, CSSValue* value)
    {
        return m_elementStyleResources.styleImage(document(), document().textLinkColors(), style()->color(), propertyId, value);
    }

    FontBuilder& fontBuilder() { return m_fontBuilder; }
    // FIXME: These exist as a primitive way to track mutations to font-related properties
    // on a RenderStyle. As designed, these are very error-prone, as some callers
    // set these directly on the RenderStyle w/o telling us. Presumably we'll
    // want to design a better wrapper around RenderStyle for tracking these mutations
    // and separate it from StyleResolverState.
    const FontDescription& parentFontDescription() { return m_parentStyle->fontDescription(); }
    void setTextOrientation(TextOrientation textOrientation) { m_fontBuilder.didChangeFontParameters(m_style->setTextOrientation(textOrientation)); }

private:
    ElementResolveContext m_elementContext;
    RawPtr<Document> m_document;

    // m_style is the primary output for each element's style resolve.
    RefPtr<RenderStyle> m_style;

    CSSToLengthConversionData m_cssToLengthConversionData;

    // m_parentStyle is not always just element->parentNode()->style()
    // so we keep it separate from m_elementContext.
    RefPtr<RenderStyle> m_parentStyle;

    OwnPtr<CSSAnimationUpdate> m_animationUpdate;

    RawPtr<CSSValue> m_lineHeightValue;

    FontBuilder m_fontBuilder;

    ElementStyleResources m_elementStyleResources;
    // CSSToStyleMap is a pure-logic class and only contains
    // a back-pointer to this object.
    CSSToStyleMap m_styleMap;
    Vector<AtomicString> m_contentAttrValues;
};

} // namespace blink

#endif // StyleResolverState_h
