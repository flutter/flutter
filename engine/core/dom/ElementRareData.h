/*
 * Copyright (C) 2008, 2009, 2010 Apple Inc. All rights reserved.
 * Copyright (C) 2008 David Smith <catfish.man@gmail.com>
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

#ifndef ElementRareData_h
#define ElementRareData_h

#include "core/animation/ActiveAnimations.h"
#include "core/dom/Attr.h"
#include "core/dom/NamedNodeMap.h"
#include "core/dom/NodeRareData.h"
#include "core/dom/custom/CustomElementDefinition.h"
#include "core/dom/shadow/ElementShadow.h"
#include "core/html/ClassList.h"
#include "core/html/ime/InputMethodContext.h"
#include "core/rendering/style/StyleInheritedData.h"
#include "platform/heap/Handle.h"
#include "wtf/OwnPtr.h"

namespace blink {

class HTMLElement;

class ElementRareData : public NodeRareData {
public:
    static ElementRareData* create(RenderObject* renderer)
    {
        return new ElementRareData(renderer);
    }

    ~ElementRareData();

    short tabIndex() const { return m_tabindex; }

    void setTabIndexExplicitly(short index)
    {
        m_tabindex = index;
        setElementFlag(TabIndexWasSetExplicitly, true);
    }

    void clearTabIndexExplicitly()
    {
        m_tabindex = 0;
        clearElementFlag(TabIndexWasSetExplicitly);
    }

    CSSStyleDeclaration& ensureInlineCSSStyleDeclaration(Element* ownerElement);

    void clearShadow() { m_shadow = nullptr; }
    ElementShadow* shadow() const { return m_shadow.get(); }
    ElementShadow& ensureShadow()
    {
        if (!m_shadow)
            m_shadow = ElementShadow::create();
        return *m_shadow;
    }

    NamedNodeMap* attributeMap() const { return m_attributeMap.get(); }
    void setAttributeMap(PassOwnPtrWillBeRawPtr<NamedNodeMap> attributeMap) { m_attributeMap = attributeMap; }

    RenderStyle* computedStyle() const { return m_computedStyle.get(); }
    void setComputedStyle(PassRefPtr<RenderStyle> computedStyle) { m_computedStyle = computedStyle; }
    void clearComputedStyle() { m_computedStyle = nullptr; }

    ClassList* classList() const { return m_classList.get(); }
    void setClassList(PassOwnPtrWillBeRawPtr<ClassList> classList) { m_classList = classList; }

    LayoutSize minimumSizeForResizing() const { return m_minimumSizeForResizing; }
    void setMinimumSizeForResizing(LayoutSize size) { m_minimumSizeForResizing = size; }

    IntSize savedLayerScrollOffset() const { return m_savedLayerScrollOffset; }
    void setSavedLayerScrollOffset(IntSize size) { m_savedLayerScrollOffset = size; }

    ActiveAnimations* activeAnimations() { return m_activeAnimations.get(); }
    void setActiveAnimations(PassOwnPtrWillBeRawPtr<ActiveAnimations> activeAnimations)
    {
        m_activeAnimations = activeAnimations;
    }

    bool hasInputMethodContext() const { return m_inputMethodContext; }
    InputMethodContext& ensureInputMethodContext(HTMLElement* element)
    {
        if (!m_inputMethodContext)
            m_inputMethodContext = InputMethodContext::create(element);
        return *m_inputMethodContext;
    }

    void setCustomElementDefinition(PassRefPtr<CustomElementDefinition> definition) { m_customElementDefinition = definition; }
    CustomElementDefinition* customElementDefinition() const { return m_customElementDefinition.get(); }

    WillBeHeapVector<RefPtrWillBeMember<Attr> >& ensureAttrNodeList();
    WillBeHeapVector<RefPtrWillBeMember<Attr> >* attrNodeList() { return m_attrNodeList.get(); }
    void removeAttrNodeList() { m_attrNodeList.clear(); }

    void traceAfterDispatch(Visitor*);

private:
    short m_tabindex;

    LayoutSize m_minimumSizeForResizing;
    IntSize m_savedLayerScrollOffset;

    OwnPtrWillBeMember<ClassList> m_classList;
    OwnPtrWillBeMember<ElementShadow> m_shadow;
    OwnPtrWillBeMember<NamedNodeMap> m_attributeMap;
    OwnPtrWillBeMember<WillBeHeapVector<RefPtrWillBeMember<Attr> > > m_attrNodeList;
    OwnPtrWillBeMember<InputMethodContext> m_inputMethodContext;
    OwnPtrWillBeMember<ActiveAnimations> m_activeAnimations;
    OwnPtrWillBeMember<InlineCSSStyleDeclaration> m_cssomWrapper;

    RefPtr<RenderStyle> m_computedStyle;
    RefPtr<CustomElementDefinition> m_customElementDefinition;

    explicit ElementRareData(RenderObject*);
};

inline IntSize defaultMinimumSizeForResizing()
{
    return IntSize(LayoutUnit::max(), LayoutUnit::max());
}

inline ElementRareData::ElementRareData(RenderObject* renderer)
    : NodeRareData(renderer)
    , m_tabindex(0)
    , m_minimumSizeForResizing(defaultMinimumSizeForResizing())
{
    m_isElementRareData = true;
}

inline ElementRareData::~ElementRareData()
{
#if !ENABLE(OILPAN)
    ASSERT(!m_shadow);
#endif
}

} // namespace

#endif // ElementRareData_h
