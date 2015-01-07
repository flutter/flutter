/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Peter Kelly (pmk@post.com)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003-2011, 2013, 2014 Apple Inc. All rights reserved.
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

#ifndef SKY_ENGINE_CORE_DOM_ELEMENT_H_
#define SKY_ENGINE_CORE_DOM_ELEMENT_H_

#include "gen/sky/core/CSSPropertyNames.h"
#include "gen/sky/core/HTMLNames.h"
#include "sky/engine/core/css/CSSPrimitiveValue.h"
#include "sky/engine/core/dom/Attribute.h"
#include "sky/engine/core/dom/ContainerNode.h"
#include "sky/engine/core/dom/ElementData.h"
#include "sky/engine/core/dom/SpaceSplitString.h"
#include "sky/engine/core/page/FocusType.h"
#include "sky/engine/platform/heap/Handle.h"

namespace blink {

class ActiveAnimations;
class Attr;
class Attribute;
class CSSStyleDeclaration;
class ClientRect;
class ClientRectList;
class CustomElementDefinition;
class DOMTokenList;
class Document;
class ElementRareData;
class ElementShadow;
class ExceptionState;
class Image;
class InputMethodContext;
class IntSize;
class MutableStylePropertySet;
class PropertySetCSSStyleDeclaration;
class PseudoElement;
class ShadowRoot;
class StylePropertySet;

enum SpellcheckAttributeState {
    SpellcheckAttributeTrue,
    SpellcheckAttributeFalse,
    SpellcheckAttributeDefault
};

enum ElementFlags {
    TabIndexWasSetExplicitly = 1 << 0,

    NumberOfElementFlags = 2, // Required size of bitfield used to store the flags.
};

class Element : public ContainerNode {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<Element> create(const QualifiedName&, Document*);
    virtual ~Element();

    bool hasAttribute(const QualifiedName&) const;
    const AtomicString& getAttribute(const QualifiedName&) const;
    Vector<RefPtr<Attr>> getAttributes();
    bool hasAttributes() const;
    bool hasAttribute(const AtomicString& name) const;
    const AtomicString& getAttribute(const AtomicString& name) const;
    void setAttribute(const AtomicString& name, const AtomicString& value, ExceptionState&);
    void removeAttribute(const AtomicString& name);
    void removeAttribute(const QualifiedName&);

    // Passing nullAtom as the second parameter removes the attribute when calling either of these set methods.
    void setAttribute(const QualifiedName&, const AtomicString& value);
    void setSynchronizedLazyAttribute(const QualifiedName&, const AtomicString& value);

    // Typed getters and setters for language bindings.
    int getIntegralAttribute(const QualifiedName& attributeName) const;
    void setIntegralAttribute(const QualifiedName& attributeName, int value);
    unsigned getUnsignedIntegralAttribute(const QualifiedName& attributeName) const;
    void setUnsignedIntegralAttribute(const QualifiedName& attributeName, unsigned value);
    double getFloatingPointAttribute(const QualifiedName& attributeName, double fallbackValue = std::numeric_limits<double>::quiet_NaN()) const;
    void setFloatingPointAttribute(const QualifiedName& attributeName, double value);

    const AtomicString& getIdAttribute() const;
    void setIdAttribute(const AtomicString&);

    const AtomicString& getClassAttribute() const;

    // Call this to get the value of the id attribute for style resolution purposes.
    // The value will already be lowercased if the document is in compatibility mode,
    // so this function is not suitable for non-style uses.
    const AtomicString& idForStyleResolution() const;

    // This getter takes care of synchronizing all attributes before returning the
    // AttributeCollection. If the Element has no attributes, an empty AttributeCollection
    // will be returned. This is not a trivial getter and its return value should be cached
    // for performance.
    AttributeCollection attributes() const;
    // This variant will not update the potentially invalid attributes. To be used when not interested
    // in style attribute or one of the SVG animation attributes.
    AttributeCollection attributesWithoutUpdate() const;

    int offsetLeft();
    int offsetTop();
    int offsetWidth();
    int offsetHeight();

    Element* offsetParent();
    int clientLeft();
    int clientTop();
    int clientWidth();
    int clientHeight();
    int scrollLeft();
    int scrollTop();
    void setScrollLeft(int);
    void setScrollLeft(const Dictionary& scrollOptionsHorizontal, ExceptionState&);
    void setScrollTop(int);
    void setScrollTop(const Dictionary& scrollOptionsVertical, ExceptionState&);
    int scrollWidth();
    int scrollHeight();

    PassRefPtr<ClientRectList> getClientRects();
    PassRefPtr<ClientRect> getBoundingClientRect();

    virtual void didMoveToNewDocument(Document&) override;

    CSSStyleDeclaration* style();

    const QualifiedName& tagQName() const { return m_tagName; }
    String tagName() const { return nodeName(); }

    bool hasTagName(const QualifiedName& tagName) const { return m_tagName == tagName; }
    bool hasTagName(const HTMLQualifiedName& name) const { return hasLocalName(name.localName()); }

    // A fast function for checking the local name against another atomic string.
    bool hasLocalName(const AtomicString& other) const { return m_tagName.localName() == other; }

    virtual const AtomicString& localName() const override final { return m_tagName.localName(); }

    virtual String nodeName() const override;

    PassRefPtr<Element> cloneElementWithChildren();
    PassRefPtr<Element> cloneElementWithoutChildren();

    void setBooleanAttribute(const QualifiedName& name, bool);

    void invalidateStyleAttribute();

    bool affectedByAttributeSelector(const AtomicString& attributeName) const;
    bool affectedByClassSelector(const AtomicString& classValue) const;
    bool affectedByIdSelector(const AtomicString& idValue) const;

    const StylePropertySet* inlineStyle() const { return elementData() ? elementData()->m_inlineStyle.get() : 0; }

    bool setInlineStyleProperty(CSSPropertyID, CSSValueID identifier, bool important = false);
    bool setInlineStyleProperty(CSSPropertyID, double value, CSSPrimitiveValue::UnitType, bool important = false);
    bool setInlineStyleProperty(CSSPropertyID, const String& value, bool important = false);
    bool removeInlineStyleProperty(CSSPropertyID);
    void removeAllInlineStyleProperties();

    void synchronizeStyleAttributeInternal() const;

    enum AttributeModificationReason {
        ModifiedDirectly,
        ModifiedByCloning
    };

    virtual void parseAttribute(const QualifiedName&, const AtomicString&);

    // Only called by the parser immediately after element construction.
    void parserSetAttributes(const Vector<Attribute>&);

    bool sharesSameElementData(const Element& other) const { return elementData() == other.elementData(); }

    // Clones attributes only.
    void cloneAttributesFromElement(const Element&);

    // Clones all attribute-derived data, including subclass specifics (through copyNonAttributeProperties.)
    void cloneDataFromElement(const Element&);

    bool hasEquivalentAttributes(const Element* other) const;

    void attach(const AttachContext& = AttachContext()) final;
    void detach(const AttachContext& = AttachContext()) final;

    virtual RenderObject* createRenderer(RenderStyle*);
    void recalcStyle(StyleRecalcChange, Text* nextTextSibling = 0);
    void setAnimationStyleChange(bool);
    void setNeedsAnimationStyleRecalc();

    bool supportsStyleSharing() const;

    ElementShadow* shadow() const;
    ElementShadow& ensureShadow();
    PassRefPtr<ShadowRoot> ensureShadowRoot(ExceptionState&);
    ShadowRoot* shadowRoot() const;

    bool hasAuthorShadowRoot() const { return shadowRoot(); }

    RenderStyle* computedStyle(PseudoId = NOPSEUDO);

    bool isUpgradedCustomElement() { return customElementState() == Upgraded; }
    bool isUnresolvedCustomElement() { return customElementState() == WaitingForUpgrade; }

    AtomicString computeInheritedLanguage() const;

    virtual bool isURLAttribute(const Attribute&) const { return false; }

    virtual bool isLiveLink() const { return false; }
    KURL hrefURL() const;

    KURL getURLAttribute(const QualifiedName&) const;
    KURL getNonEmptyURLAttribute(const QualifiedName&) const;

    virtual const AtomicString imageSourceURL() const;

    void focus(bool restorePreviousSelection = true, FocusType = FocusTypeNone);
    void updateFocusAppearance(bool restorePreviousSelection);
    void blur();
    // Whether this element can receive focus at all. Most elements are not
    // focusable but some elements, such as form controls and links, are. Unlike
    // rendererIsFocusable(), this method may be called when layout is not up to
    // date, so it must not use the renderer to determine focusability.
    virtual bool supportsFocus() const;
    // Whether the node can actually be focused.
    bool isFocusable() const;
    bool isKeyboardFocusable() const;
    bool isMouseFocusable() const;
    virtual void willCallDefaultEventHandler(const Event&) override final;
    void dispatchFocusEvent(Element* oldFocusedElement, FocusType);
    void dispatchBlurEvent(Element* newFocusedElement);
    void dispatchFocusInEvent(const AtomicString& eventType, Element* oldFocusedElement);
    void dispatchFocusOutEvent(const AtomicString& eventType, Element* newFocusedElement);

    String title() const;

    bool matches(const String& selectors, ExceptionState&);

    DOMTokenList& classList();

    virtual bool canContainRangeEndPoint() const override { return true; }

    void setCustomElementDefinition(PassRefPtr<CustomElementDefinition>);
    CustomElementDefinition* customElementDefinition() const;

    bool isSpellCheckingEnabled() const;

    // FIXME: public for RenderTreeBuilder, we shouldn't expose this though.
    PassRefPtr<RenderStyle> styleForRenderer();

    bool hasID() const;
    bool hasClass() const;
    const SpaceSplitString& classNames() const;

    IntSize savedLayerScrollOffset() const;
    void setSavedLayerScrollOffset(const IntSize&);

    ActiveAnimations* activeAnimations() const;
    ActiveAnimations& ensureActiveAnimations();
    bool hasActiveAnimations() const;

    InputMethodContext& inputMethodContext();
    bool hasInputMethodContext() const;

    void synchronizeAttribute(const AtomicString& localName) const;

    MutableStylePropertySet& ensureMutableInlineStyle();
    void clearMutableInlineStyleIfEmpty();

    void setTabIndex(int);
    virtual short tabIndex() const override;

    String contentEditable() const;
    void setContentEditable(const String&, ExceptionState&);

    bool spellcheck() const;
    void setSpellcheck(bool);

    const AtomicString& dir();
    void setDir(const AtomicString&);

    void click();

    String textFromChildren();

protected:
    Element(const QualifiedName& tagName, Document*, ConstructionType);

    const ElementData* elementData() const { return m_elementData.get(); }
    UniqueElementData& ensureUniqueElementData();

    virtual void insertedInto(ContainerNode*) override;
    virtual void removedFrom(ContainerNode*) override;
    virtual void childrenChanged(const ChildrenChange&) override;

    void clearTabIndexExplicitlyIfNeeded();
    void setTabIndexExplicitly(short);
    // Subclasses may override this method to affect focusability. Unlike
    // supportsFocus, this method must be called on an up-to-date layout, so it
    // may use the renderer to reason about focusability. This method cannot be
    // moved to RenderObject because some focusable nodes don't have renderers,
    // e.g., HTMLOptionElement.
    virtual bool rendererIsFocusable() const;

    // These methods are overridden by subclasses whose default focus appearance should not remain hidden on mouse focus.
    virtual bool wasFocusedByMouse() const { return false; }
    virtual void setWasFocusedByMouse(bool) { }

    // classAttributeChanged() exists to share code between
    // parseAttribute (called via setAttribute()) and
    // svgAttributeChanged (called when element.className.baseValue is set)
    void classAttributeChanged(const AtomicString& newClassString);

private:
    void attributeChanged(const QualifiedName&, const AtomicString&, AttributeModificationReason = ModifiedDirectly);

    bool classChangeNeedsStyleRecalc(const SpaceSplitString& oldClasses, const SpaceSplitString& newClasses);

    bool hasElementFlag(ElementFlags mask) const { return hasRareData() && hasElementFlagInternal(mask); }
    void setElementFlag(ElementFlags, bool value = true);
    void clearElementFlag(ElementFlags);
    bool hasElementFlagInternal(ElementFlags) const;

    bool isElementNode() const = delete; // This will catch anyone doing an unnecessary check.
    bool isDocumentFragment() const = delete; // This will catch anyone doing an unnecessary check.
    bool isDocumentNode() const = delete; // This will catch anyone doing an unnecessary check.

    void styleAttributeChanged(const AtomicString& newStyleString);

    void inlineStyleChanged();
    PropertySetCSSStyleDeclaration* inlineStyleCSSOMWrapper();
    void setInlineStyleFromString(const AtomicString&);

    StyleRecalcChange recalcOwnStyle(StyleRecalcChange);
    void recalcChildStyle(StyleRecalcChange);

    enum SynchronizationOfLazyAttribute { NotInSynchronizationOfLazyAttribute = 0, InSynchronizationOfLazyAttribute };

    void willModifyAttribute(const QualifiedName&, const AtomicString& oldValue, const AtomicString& newValue);

    void synchronizeAllAttributes() const;

    void updateId(const AtomicString& oldId, const AtomicString& newId);
    void updateId(TreeScope&, const AtomicString& oldId, const AtomicString& newId);

    virtual NodeType nodeType() const override final;

    void setAttributeInternal(size_t index, const QualifiedName&, const AtomicString& value, SynchronizationOfLazyAttribute);
    void appendAttributeInternal(const QualifiedName&, const AtomicString& value, SynchronizationOfLazyAttribute);
    void removeAttributeInternal(size_t index, SynchronizationOfLazyAttribute);
    void attributeChangedFromParserOrByCloning(const QualifiedName&, const AtomicString&, AttributeModificationReason);

#ifndef NDEBUG
    virtual void formatForDebugger(char* buffer, unsigned length) const override;
#endif

    virtual RenderStyle* virtualComputedStyle(PseudoId pseudoElementSpecifier = NOPSEUDO) override { return computedStyle(pseudoElementSpecifier); }

    // cloneNode is private so that non-virtual cloneElementWithChildren and cloneElementWithoutChildren
    // are used instead.
    virtual PassRefPtr<Node> cloneNode(bool deep) override;
    virtual PassRefPtr<Element> cloneElementWithoutAttributesAndChildren();

    QualifiedName m_tagName;

    SpellcheckAttributeState spellcheckAttributeState() const;

    void createUniqueElementData();

    bool shouldInvalidateDistributionWhenAttributeChanged(ElementShadow*, const QualifiedName&, const AtomicString&);

    ElementRareData* elementRareData() const;
    ElementRareData& ensureElementRareData();

    RefPtr<ElementData> m_elementData;
};

DEFINE_NODE_TYPE_CASTS(Element, isElementNode());
template <typename T> bool isElementOfType(const Node&);
template <> inline bool isElementOfType<const Element>(const Node& node) { return node.isElementNode(); }
template <typename T> inline bool isElementOfType(const Element& element) { return isElementOfType<T>(static_cast<const Node&>(element)); }
template <> inline bool isElementOfType<const Element>(const Element&) { return true; }

// Type casting.
template<typename T> inline T& toElement(Node& node)
{
    ASSERT_WITH_SECURITY_IMPLICATION(isElementOfType<const T>(node));
    return static_cast<T&>(node);
}
template<typename T> inline T* toElement(Node* node)
{
    ASSERT_WITH_SECURITY_IMPLICATION(!node || isElementOfType<const T>(*node));
    return static_cast<T*>(node);
}
template<typename T> inline const T& toElement(const Node& node)
{
    ASSERT_WITH_SECURITY_IMPLICATION(isElementOfType<const T>(node));
    return static_cast<const T&>(node);
}
template<typename T> inline const T* toElement(const Node* node)
{
    ASSERT_WITH_SECURITY_IMPLICATION(!node || isElementOfType<const T>(*node));
    return static_cast<const T*>(node);
}
template<typename T, typename U> inline T* toElement(const RefPtr<U>& node) { return toElement<T>(node.get()); }

inline Element* Node::parentElement() const
{
    ContainerNode* parent = parentNode();
    return parent && parent->isElementNode() ? toElement(parent) : 0;
}

inline void Element::synchronizeAttribute(const AtomicString& localName) const
{
    if (!elementData())
        return;
    if (localName == HTMLNames::styleAttr && elementData()->m_styleAttributeIsDirty) {
        ASSERT(isStyledElement());
        synchronizeStyleAttributeInternal();
    }
}

inline bool Element::hasAttribute(const QualifiedName& name) const
{
    return hasAttribute(name.localName());
}

inline bool Element::hasAttribute(const AtomicString& name) const
{
    synchronizeAttribute(name);
    return elementData() && elementData()->attributes().findIndex(name) != kNotFound;
}

inline const AtomicString& Element::getAttribute(const QualifiedName& name) const
{
    return getAttribute(name.localName());
}

inline const AtomicString& Element::getAttribute(const AtomicString& name) const
{
    if (!elementData())
        return nullAtom;
    synchronizeAttribute(name);
    if (const Attribute* attribute = elementData()->attributes().find(name))
        return attribute->value();
    return nullAtom;
}

inline AttributeCollection Element::attributes() const
{
    if (!elementData())
        return AttributeCollection();
    synchronizeAllAttributes();
    return elementData()->attributes();
}

inline AttributeCollection Element::attributesWithoutUpdate() const
{
    if (!elementData())
        return AttributeCollection();
    return elementData()->attributes();
}

inline bool Element::hasAttributes() const
{
    return !attributes().isEmpty();
}

inline const AtomicString& Element::idForStyleResolution() const
{
    ASSERT(hasID());
    return elementData()->idForStyleResolution();
}

inline const AtomicString& Element::getIdAttribute() const
{
    return hasID() ? getAttribute(HTMLNames::idAttr) : nullAtom;
}

inline const AtomicString& Element::getClassAttribute() const
{
    if (!hasClass())
        return nullAtom;
    return getAttribute(HTMLNames::classAttr);
}

inline void Element::setIdAttribute(const AtomicString& value)
{
    setAttribute(HTMLNames::idAttr, value);
}

inline const SpaceSplitString& Element::classNames() const
{
    ASSERT(hasClass());
    ASSERT(elementData());
    return elementData()->classNames();
}

inline bool Element::hasID() const
{
    return elementData() && elementData()->hasID();
}

inline bool Element::hasClass() const
{
    return elementData() && elementData()->hasClass();
}

inline UniqueElementData& Element::ensureUniqueElementData()
{
    if (!elementData() || !elementData()->isUnique())
        createUniqueElementData();
    return toUniqueElementData(*m_elementData);
}

inline void Node::insertedInto(ContainerNode* insertionPoint)
{
    ASSERT(insertionPoint->inDocument() || isContainerNode());
    if (insertionPoint->inDocument())
        setFlag(InDocumentFlag);
    if (parentOrShadowHostNode()->isInShadowTree())
        setFlag(IsInShadowTreeFlag);
    if (childNeedsDistributionRecalc() && !insertionPoint->childNeedsDistributionRecalc())
        insertionPoint->markAncestorsWithChildNeedsDistributionRecalc();
}

inline void Node::removedFrom(ContainerNode* insertionPoint)
{
    ASSERT(insertionPoint->inDocument() || isContainerNode());
    if (insertionPoint->inDocument())
        clearFlag(InDocumentFlag);
    if (isInShadowTree() && !treeScope().rootNode().isShadowRoot())
        clearFlag(IsInShadowTreeFlag);
}

inline ShadowRoot* Node::shadowRoot() const
{
    if (!isElementNode())
        return 0;
    return toElement(this)->shadowRoot();
}

inline bool Node::hasTagName(const HTMLQualifiedName& name) const
{
    return isHTMLElement() && toElement(*this).hasTagName(name);
}

inline void Element::invalidateStyleAttribute()
{
    ASSERT(elementData());
    elementData()->m_styleAttributeIsDirty = true;
}

inline bool isShadowHost(const Node* node)
{
    return node && node->isElementNode() && toElement(node)->shadow();
}

inline bool isShadowHost(const Element* element)
{
    return element && element->shadow();
}

inline bool isAtShadowBoundary(const Element* element)
{
    if (!element)
        return false;
    ContainerNode* parentNode = element->parentNode();
    return parentNode && parentNode->isShadowRoot();
}

// These macros do the same as their NODE equivalents but additionally provide a template specialization
// for isElementOfType<>() so that the Traversal<> API works for these Element types.
#define DEFINE_ELEMENT_TYPE_CASTS(thisType, predicate) \
    template <> inline bool isElementOfType<const thisType>(const Node& node) { return node.predicate; } \
    DEFINE_NODE_TYPE_CASTS(thisType, predicate)

#define DEFINE_ELEMENT_TYPE_CASTS_WITH_FUNCTION(thisType) \
    template <> inline bool isElementOfType<const thisType>(const Node& node) { return is##thisType(node); } \
    DEFINE_NODE_TYPE_CASTS_WITH_FUNCTION(thisType)

#define DECLARE_ELEMENT_FACTORY_WITH_TAGNAME(T) \
    static PassRefPtr<T> create(const QualifiedName&, Document&)
#define DEFINE_ELEMENT_FACTORY_WITH_TAGNAME(T) \
    PassRefPtr<T> T::create(const QualifiedName& tagName, Document& document) \
    { \
        return adoptRef(new T(tagName, document)); \
    }

} // namespace

#endif  // SKY_ENGINE_CORE_DOM_ELEMENT_H_
