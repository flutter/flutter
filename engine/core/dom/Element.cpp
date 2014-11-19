/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Peter Kelly (pmk@post.com)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 *           (C) 2007 David Smith (catfish.man@gmail.com)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2012, 2013 Apple Inc. All rights reserved.
 *           (C) 2007 Eric Seidel (eric@webkit.org)
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

#include "config.h"
#include "core/dom/Element.h"

#include "bindings/core/v8/Dictionary.h"
#include "bindings/core/v8/ExceptionMessages.h"
#include "bindings/core/v8/ExceptionState.h"
#include "core/CSSValueKeywords.h"
#include "core/HTMLNames.h"
#include "core/animation/AnimationTimeline.h"
#include "core/animation/css/CSSAnimations.h"
#include "core/css/CSSImageValue.h"
#include "core/css/CSSStyleSheet.h"
#include "core/css/CSSValuePool.h"
#include "core/css/PropertySetCSSStyleDeclaration.h"
#include "core/css/StylePropertySet.h"
#include "core/css/parser/BisonCSSParser.h"
#include "core/css/resolver/StyleResolver.h"
#include "core/dom/Attr.h"
#include "core/dom/ClientRect.h"
#include "core/dom/ClientRectList.h"
#include "core/dom/ElementDataCache.h"
#include "core/dom/ElementRareData.h"
#include "core/dom/ElementTraversal.h"
#include "core/dom/ExceptionCode.h"
#include "core/dom/MutationObserverInterestGroup.h"
#include "core/dom/MutationRecord.h"
#include "core/dom/NodeRenderStyle.h"
#include "core/dom/RenderTreeBuilder.h"
#include "core/dom/SelectorQuery.h"
#include "core/dom/StyleEngine.h"
#include "core/dom/Text.h"
#include "core/dom/custom/CustomElement.h"
#include "core/dom/custom/CustomElementRegistrationContext.h"
#include "core/dom/shadow/InsertionPoint.h"
#include "core/dom/shadow/ShadowRoot.h"
#include "core/editing/FrameSelection.h"
#include "core/editing/TextIterator.h"
#include "core/editing/htmlediting.h"
#include "core/editing/markup.h"
#include "core/events/EventDispatcher.h"
#include "core/events/FocusEvent.h"
#include "core/frame/FrameView.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "core/frame/UseCounter.h"
#include "core/html/ClassList.h"
#include "core/html/HTMLCanvasElement.h"
#include "core/html/HTMLDocument.h"
#include "core/html/HTMLElement.h"
#include "core/html/HTMLTemplateElement.h"
#include "core/html/parser/HTMLDocumentParser.h"
#include "core/html/parser/HTMLParserIdioms.h"
#include "core/page/Chrome.h"
#include "core/page/ChromeClient.h"
#include "core/page/FocusController.h"
#include "core/page/Page.h"
#include "core/rendering/RenderLayer.h"
#include "core/rendering/RenderView.h"
#include "core/rendering/compositing/RenderLayerCompositor.h"
#include "platform/EventDispatchForbiddenScope.h"
#include "platform/RuntimeEnabledFeatures.h"
#include "platform/UserGestureIndicator.h"
#include "platform/scroll/ScrollableArea.h"
#include "wtf/BitVector.h"
#include "wtf/HashFunctions.h"
#include "wtf/text/CString.h"
#include "wtf/text/StringBuilder.h"
#include "wtf/text/TextPosition.h"

namespace blink {

PassRefPtr<Element> Element::create(const QualifiedName& tagName, Document* document)
{
    return adoptRef(new Element(tagName, document, CreateElement));
}

Element::Element(const QualifiedName& tagName, Document* document, ConstructionType type)
    : ContainerNode(document, type)
    , m_tagName(tagName)
{
}

Element::~Element()
{
    ASSERT(needsAttach());

#if !ENABLE(OILPAN)
    if (hasRareData())
        elementRareData()->clearShadow();

    if (isCustomElement())
        CustomElement::wasDestroyed(this);
#endif
}

inline ElementRareData* Element::elementRareData() const
{
    ASSERT(hasRareData());
    return static_cast<ElementRareData*>(rareData());
}

inline ElementRareData& Element::ensureElementRareData()
{
    return static_cast<ElementRareData&>(ensureRareData());
}

bool Element::hasElementFlagInternal(ElementFlags mask) const
{
    return elementRareData()->hasElementFlag(mask);
}

void Element::setElementFlag(ElementFlags mask, bool value)
{
    if (!hasRareData() && !value)
        return;
    ensureElementRareData().setElementFlag(mask, value);
}

void Element::clearElementFlag(ElementFlags mask)
{
    if (!hasRareData())
        return;
    elementRareData()->clearElementFlag(mask);
}

void Element::clearTabIndexExplicitlyIfNeeded()
{
    if (hasRareData())
        elementRareData()->clearTabIndexExplicitly();
}

void Element::setTabIndexExplicitly(short tabIndex)
{
    ensureElementRareData().setTabIndexExplicitly(tabIndex);
}

void Element::setTabIndex(int value)
{
    setIntegralAttribute(HTMLNames::tabindexAttr, value);
}

short Element::tabIndex() const
{
    return hasRareData() ? elementRareData()->tabIndex() : 0;
}

bool Element::rendererIsFocusable() const
{
    // FIXME: These asserts should be in Node::isFocusable, but there are some
    // callsites like Document::setFocusedElement that would currently fail on
    // them. See crbug.com/251163
    if (!renderer()) {
        // Elements in canvas fallback content are not rendered, but they are allowed to be
        // focusable as long as their canvas is displayed and visible.
        if (const HTMLCanvasElement* canvas = Traversal<HTMLCanvasElement>::firstAncestorOrSelf(*this))
            return canvas->renderer();
        // We can't just use needsStyleRecalc() because if the node is in a
        // display:none tree it might say it needs style recalc but the whole
        // document is actually up to date.
        ASSERT(!document().childNeedsStyleRecalc());
    }

    // FIXME: Even if we are not visible, we might have a child that is visible.
    // Hyatt wants to fix that some day with a "has visible content" flag or the like.
    if (!renderer())
        return false;

    return true;
}

PassRefPtr<Node> Element::cloneNode(bool deep)
{
    return deep ? cloneElementWithChildren() : cloneElementWithoutChildren();
}

PassRefPtr<Element> Element::cloneElementWithChildren()
{
    RefPtr<Element> clone = cloneElementWithoutChildren();
    cloneChildNodes(clone.get());
    return clone.release();
}

PassRefPtr<Element> Element::cloneElementWithoutChildren()
{
    RefPtr<Element> clone = cloneElementWithoutAttributesAndChildren();
    // This will catch HTML elements in the wrong namespace that are not correctly copied.
    // This is a sanity check as HTML overloads some of the DOM methods.
    ASSERT(isHTMLElement() == clone->isHTMLElement());

    clone->cloneDataFromElement(*this);
    return clone.release();
}

PassRefPtr<Element> Element::cloneElementWithoutAttributesAndChildren()
{
    return document().createElement(tagQName(), false);
}

void Element::removeAttribute(const QualifiedName& name)
{
    if (!elementData())
        return;

    size_t index = elementData()->attributes().findIndex(name);
    if (index == kNotFound)
        return;

    removeAttributeInternal(index, NotInSynchronizationOfLazyAttribute);
}

void Element::setBooleanAttribute(const QualifiedName& name, bool value)
{
    if (value)
        setAttribute(name, emptyAtom);
    else
        removeAttribute(name);
}

ActiveAnimations* Element::activeAnimations() const
{
    if (hasRareData())
        return elementRareData()->activeAnimations();
    return 0;
}

ActiveAnimations& Element::ensureActiveAnimations()
{
    ElementRareData& rareData = ensureElementRareData();
    if (!rareData.activeAnimations())
        rareData.setActiveAnimations(adoptPtr(new ActiveAnimations()));
    return *rareData.activeAnimations();
}

bool Element::hasActiveAnimations() const
{
    if (!hasRareData())
        return false;

    ActiveAnimations* activeAnimations = elementRareData()->activeAnimations();
    return activeAnimations && !activeAnimations->isEmpty();
}

Node::NodeType Element::nodeType() const
{
    return ELEMENT_NODE;
}

void Element::synchronizeAllAttributes() const
{
    synchronizeAttribute(HTMLNames::styleAttr.localName());
}

void Element::scrollIntoView(bool alignToTop)
{
    document().updateLayoutIgnorePendingStylesheets();

    if (!renderer())
        return;

    LayoutRect bounds = boundingBox();
    // Align to the top / bottom and to the closest edge.
    if (alignToTop)
        renderer()->scrollRectToVisible(bounds, ScrollAlignment::alignToEdgeIfNeeded, ScrollAlignment::alignTopAlways);
    else
        renderer()->scrollRectToVisible(bounds, ScrollAlignment::alignToEdgeIfNeeded, ScrollAlignment::alignBottomAlways);
}

void Element::scrollIntoViewIfNeeded(bool centerIfNeeded)
{
    document().updateLayoutIgnorePendingStylesheets();

    if (!renderer())
        return;

    LayoutRect bounds = boundingBox();
    if (centerIfNeeded)
        renderer()->scrollRectToVisible(bounds, ScrollAlignment::alignCenterIfNeeded, ScrollAlignment::alignCenterIfNeeded);
    else
        renderer()->scrollRectToVisible(bounds, ScrollAlignment::alignToEdgeIfNeeded, ScrollAlignment::alignToEdgeIfNeeded);
}

int Element::offsetLeft()
{
    document().updateLayoutIgnorePendingStylesheets();
    if (RenderBoxModelObject* renderer = renderBoxModelObject())
        return renderer->offsetLeft();
    return 0;
}

int Element::offsetTop()
{
    document().updateLayoutIgnorePendingStylesheets();
    if (RenderBoxModelObject* renderer = renderBoxModelObject())
        return renderer->pixelSnappedOffsetTop();
    return 0;
}

int Element::offsetWidth()
{
    document().updateLayoutIgnorePendingStylesheets();
    if (RenderBoxModelObject* renderer = renderBoxModelObject())
        return renderer->pixelSnappedOffsetWidth();
    return 0;
}

int Element::offsetHeight()
{
    document().updateLayoutIgnorePendingStylesheets();
    if (RenderBoxModelObject* renderer = renderBoxModelObject())
        return renderer->pixelSnappedOffsetHeight();
    return 0;
}

Element* Element::offsetParent()
{
    document().updateLayoutIgnorePendingStylesheets();
    if (RenderObject* renderer = this->renderer())
        return renderer->offsetParent();
    return 0;
}

int Element::clientLeft()
{
    document().updateLayoutIgnorePendingStylesheets();

    if (RenderBox* renderer = renderBox())
        return roundToInt(renderer->clientLeft());
    return 0;
}

int Element::clientTop()
{
    document().updateLayoutIgnorePendingStylesheets();

    if (RenderBox* renderer = renderBox())
        return roundToInt(renderer->clientTop());
    return 0;
}

int Element::clientWidth()
{
    document().updateLayoutIgnorePendingStylesheets();

    // FIXME(sky): Can we just use getBoundingClientRect() instead?
    if (document().documentElement() == this) {
        if (FrameView* view = document().view())
            return view->layoutSize().width();
    }

    if (RenderBox* renderer = renderBox())
        return renderer->pixelSnappedClientWidth();
    return 0;
}

int Element::clientHeight()
{
    document().updateLayoutIgnorePendingStylesheets();

    // FIXME(sky): Can we just use getBoundingClientRect() instead?
    if (document().documentElement() == this) {
        if (FrameView* view = document().view())
            return view->layoutSize().height();
    }

    if (RenderBox* renderer = renderBox())
        return renderer->pixelSnappedClientHeight();
    return 0;
}

int Element::scrollLeft()
{
    document().updateLayoutIgnorePendingStylesheets();

    if (document().documentElement() != this) {
        if (RenderBox* rend = renderBox())
            return rend->scrollLeft();
    }

    return 0;
}

int Element::scrollTop()
{
    document().updateLayoutIgnorePendingStylesheets();

    if (document().documentElement() != this) {
        if (RenderBox* rend = renderBox())
            return rend->scrollTop();
    }

    return 0;
}

void Element::setScrollLeft(int newLeft)
{
    document().updateLayoutIgnorePendingStylesheets();

    if (document().documentElement() != this) {
        if (RenderBox* rend = renderBox())
            rend->setScrollLeft(newLeft);
    }
}

void Element::setScrollLeft(const Dictionary& scrollOptionsHorizontal, ExceptionState& exceptionState)
{
    String scrollBehaviorString;
    ScrollBehavior scrollBehavior = ScrollBehaviorAuto;
    if (DictionaryHelper::get(scrollOptionsHorizontal, "behavior", scrollBehaviorString)) {
        if (!ScrollableArea::scrollBehaviorFromString(scrollBehaviorString, scrollBehavior)) {
            exceptionState.throwTypeError("The ScrollBehavior provided is invalid.");
            return;
        }
    }

    int position;
    if (!DictionaryHelper::get(scrollOptionsHorizontal, "x", position)) {
        exceptionState.throwTypeError("ScrollOptionsHorizontal must include an 'x' member.");
        return;
    }

    // FIXME: Use scrollBehavior to decide whether to scroll smoothly or instantly.
    setScrollLeft(position);
}

void Element::setScrollTop(int newTop)
{
    document().updateLayoutIgnorePendingStylesheets();

    if (document().documentElement() != this) {
        if (RenderBox* rend = renderBox())
            rend->setScrollTop(newTop);
    }
}

void Element::setScrollTop(const Dictionary& scrollOptionsVertical, ExceptionState& exceptionState)
{
    String scrollBehaviorString;
    ScrollBehavior scrollBehavior = ScrollBehaviorAuto;
    if (DictionaryHelper::get(scrollOptionsVertical, "behavior", scrollBehaviorString)) {
        if (!ScrollableArea::scrollBehaviorFromString(scrollBehaviorString, scrollBehavior)) {
            exceptionState.throwTypeError("The ScrollBehavior provided is invalid.");
            return;
        }
    }

    int position;
    if (!DictionaryHelper::get(scrollOptionsVertical, "y", position)) {
        exceptionState.throwTypeError("ScrollOptionsVertical must include a 'y' member.");
        return;
    }

    // FIXME: Use scrollBehavior to decide whether to scroll smoothly or instantly.
    setScrollTop(position);
}

int Element::scrollWidth()
{
    document().updateLayoutIgnorePendingStylesheets();
    if (RenderBox* rend = renderBox())
        return rend->scrollWidth().toDouble();
    return 0;
}

int Element::scrollHeight()
{
    document().updateLayoutIgnorePendingStylesheets();
    if (RenderBox* rend = renderBox())
        return rend->scrollHeight().toDouble();
    return 0;
}

PassRefPtr<ClientRectList> Element::getClientRects()
{
    document().updateLayoutIgnorePendingStylesheets();

    RenderBoxModelObject* renderBoxModelObject = this->renderBoxModelObject();
    if (!renderBoxModelObject)
        return ClientRectList::create();

    // FIXME: Handle SVG elements.
    // FIXME: Handle table/inline-table with a caption.

    Vector<FloatQuad> quads;
    renderBoxModelObject->absoluteQuads(quads);
    document().adjustFloatQuadsForScroll(quads);
    return ClientRectList::create(quads);
}

PassRefPtr<ClientRect> Element::getBoundingClientRect()
{
    document().updateLayoutIgnorePendingStylesheets();

    Vector<FloatQuad> quads;
    // Get the bounding rectangle from the box model.
    if (renderBoxModelObject())
        renderBoxModelObject()->absoluteQuads(quads);

    if (quads.isEmpty())
        return ClientRect::create();

    FloatRect result = quads[0].boundingBox();
    for (size_t i = 1; i < quads.size(); ++i)
        result.unite(quads[i].boundingBox());

    document().adjustFloatRectForScroll(result);
    return ClientRect::create(result);
}

void Element::setAttribute(const AtomicString& localName, const AtomicString& value, ExceptionState& exceptionState)
{
    if (!Document::isValidName(localName)) {
        exceptionState.throwDOMException(InvalidCharacterError, "'" + localName + "' is not a valid attribute name.");
        return;
    }

    synchronizeAttribute(localName);

    if (!elementData()) {
        setAttributeInternal(kNotFound, QualifiedName(localName), value, NotInSynchronizationOfLazyAttribute);
        return;
    }

    AttributeCollection attributes = elementData()->attributes();
    size_t index = attributes.findIndex(localName);
    const QualifiedName& qName = index != kNotFound ? attributes[index].name() : QualifiedName(localName);
    setAttributeInternal(index, qName, value, NotInSynchronizationOfLazyAttribute);
}

void Element::setAttribute(const QualifiedName& name, const AtomicString& value)
{
    synchronizeAttribute(name.localName());
    size_t index = elementData() ? elementData()->attributes().findIndex(name) : kNotFound;
    setAttributeInternal(index, name, value, NotInSynchronizationOfLazyAttribute);
}

void Element::setSynchronizedLazyAttribute(const QualifiedName& name, const AtomicString& value)
{
    size_t index = elementData() ? elementData()->attributes().findIndex(name) : kNotFound;
    setAttributeInternal(index, name, value, InSynchronizationOfLazyAttribute);
}

ALWAYS_INLINE void Element::setAttributeInternal(size_t index, const QualifiedName& name, const AtomicString& newValue, SynchronizationOfLazyAttribute inSynchronizationOfLazyAttribute)
{
    if (newValue.isNull()) {
        if (index != kNotFound)
            removeAttributeInternal(index, inSynchronizationOfLazyAttribute);
        return;
    }

    if (index == kNotFound) {
        appendAttributeInternal(name, newValue, inSynchronizationOfLazyAttribute);
        return;
    }

    const Attribute& existingAttribute = elementData()->attributes().at(index);
    QualifiedName existingAttributeName = existingAttribute.name();

    if (!inSynchronizationOfLazyAttribute)
        willModifyAttribute(existingAttributeName, existingAttribute.value(), newValue);

    if (newValue != existingAttribute.value())
        ensureUniqueElementData().attributes().at(index).setValue(newValue);

    if (!inSynchronizationOfLazyAttribute)
        attributeChanged(existingAttributeName, newValue);
}

void Element::attributeChanged(const QualifiedName& name, const AtomicString& newValue, AttributeModificationReason reason)
{
    if (ElementShadow* parentElementShadow = shadowWhereNodeCanBeDistributed(*this)) {
        if (shouldInvalidateDistributionWhenAttributeChanged(parentElementShadow, name, newValue))
            parentElementShadow->setNeedsDistributionRecalc();
    }

    parseAttribute(name, newValue);

    StyleResolver* styleResolver = document().styleResolver();
    bool testShouldInvalidateStyle = inActiveDocument() && styleResolver && styleChangeType() < SubtreeStyleChange;

    if (isStyledElement() && name == HTMLNames::styleAttr) {
        styleAttributeChanged(newValue);
    }

    if (name == HTMLNames::idAttr) {
        AtomicString oldId = elementData()->idForStyleResolution();
        AtomicString newId = newValue;
        if (newId != oldId) {
            elementData()->setIdForStyleResolution(newId);
            if (testShouldInvalidateStyle)
                styleResolver->ensureUpdatedRuleFeatureSet().scheduleStyleInvalidationForIdChange(oldId, newId, *this);
        }
    } else if (name == HTMLNames::classAttr) {
        classAttributeChanged(newValue);
    }

    // If there is currently no StyleResolver, we can't be sure that this attribute change won't affect style.
    if (!styleResolver)
        setNeedsStyleRecalc(SubtreeStyleChange);
}

inline void Element::attributeChangedFromParserOrByCloning(const QualifiedName& name, const AtomicString& newValue, AttributeModificationReason reason)
{
    if (name == HTMLNames::isAttr)
        CustomElementRegistrationContext::setTypeExtension(this, newValue);
    attributeChanged(name, newValue, reason);
}

template <typename CharacterType>
static inline bool classStringHasClassName(const CharacterType* characters, unsigned length)
{
    ASSERT(length > 0);

    unsigned i = 0;
    do {
        if (isNotHTMLSpace<CharacterType>(characters[i]))
            break;
        ++i;
    } while (i < length);

    return i < length;
}

static inline bool classStringHasClassName(const AtomicString& newClassString)
{
    unsigned length = newClassString.length();

    if (!length)
        return false;

    if (newClassString.is8Bit())
        return classStringHasClassName(newClassString.characters8(), length);
    return classStringHasClassName(newClassString.characters16(), length);
}

void Element::classAttributeChanged(const AtomicString& newClassString)
{
    StyleResolver* styleResolver = document().styleResolver();
    bool testShouldInvalidateStyle = inActiveDocument() && styleResolver && styleChangeType() < SubtreeStyleChange;

    ASSERT(elementData());
    if (classStringHasClassName(newClassString)) {
        const SpaceSplitString oldClasses = elementData()->classNames();
        elementData()->setClass(newClassString, false);
        const SpaceSplitString& newClasses = elementData()->classNames();
        if (testShouldInvalidateStyle)
            styleResolver->ensureUpdatedRuleFeatureSet().scheduleStyleInvalidationForClassChange(oldClasses, newClasses, *this);
    } else {
        const SpaceSplitString& oldClasses = elementData()->classNames();
        if (testShouldInvalidateStyle)
            styleResolver->ensureUpdatedRuleFeatureSet().scheduleStyleInvalidationForClassChange(oldClasses, *this);
        elementData()->clearClass();
    }
}

bool Element::shouldInvalidateDistributionWhenAttributeChanged(ElementShadow* elementShadow, const QualifiedName& name, const AtomicString& newValue)
{
    ASSERT(elementShadow);
    const SelectRuleFeatureSet& featureSet = elementShadow->ensureSelectFeatureSet();

    if (name == HTMLNames::idAttr) {
        AtomicString oldId = elementData()->idForStyleResolution();
        AtomicString newId = newValue;
        if (newId != oldId) {
            if (!oldId.isEmpty() && featureSet.hasSelectorForId(oldId))
                return true;
            if (!newId.isEmpty() && featureSet.hasSelectorForId(newId))
                return true;
        }
    }

    if (name == HTMLNames::classAttr) {
        const AtomicString& newClassString = newValue;
        if (classStringHasClassName(newClassString)) {
            const SpaceSplitString& oldClasses = elementData()->classNames();
            const SpaceSplitString newClasses(newClassString, false);
            if (featureSet.checkSelectorsForClassChange(oldClasses, newClasses))
                return true;
        } else {
            const SpaceSplitString& oldClasses = elementData()->classNames();
            if (featureSet.checkSelectorsForClassChange(oldClasses))
                return true;
        }
    }

    return featureSet.hasSelectorForAttribute(name.localName());
}

void Element::parserSetAttributes(const Vector<Attribute>& attributeVector)
{
    ASSERT(!inDocument());
    ASSERT(!parentNode());
    ASSERT(!m_elementData);

    if (attributeVector.isEmpty())
        return;

    if (document().elementDataCache())
        m_elementData = document().elementDataCache()->cachedShareableElementDataWithAttributes(attributeVector);
    else
        m_elementData = ShareableElementData::createWithAttributes(attributeVector);

    // Use attributeVector instead of m_elementData because attributeChanged might modify m_elementData.
    for (unsigned i = 0; i < attributeVector.size(); ++i)
        attributeChangedFromParserOrByCloning(attributeVector[i].name(), attributeVector[i].value(), ModifiedDirectly);
}

bool Element::hasEquivalentAttributes(const Element* other) const
{
    synchronizeAllAttributes();
    other->synchronizeAllAttributes();
    if (elementData() == other->elementData())
        return true;
    if (elementData())
        return elementData()->isEquivalent(other->elementData());
    if (other->elementData())
        return other->elementData()->isEquivalent(elementData());
    return true;
}

String Element::nodeName() const
{
    return m_tagName.localName();
}

const AtomicString Element::imageSourceURL() const
{
    return getAttribute(HTMLNames::srcAttr);
}

RenderObject* Element::createRenderer(RenderStyle* style)
{
    return RenderObject::createObject(this, style);
}

Node::InsertionNotificationRequest Element::insertedInto(ContainerNode* insertionPoint)
{
    // need to do superclass processing first so inDocument() is true
    // by the time we reach updateId
    ContainerNode::insertedInto(insertionPoint);

    if (!insertionPoint->isInTreeScope())
        return InsertionDone;

    if (isUpgradedCustomElement() && inDocument())
        CustomElement::didAttach(this, document());

    TreeScope& scope = insertionPoint->treeScope();
    if (scope != treeScope())
        return InsertionDone;

    const AtomicString& idValue = getIdAttribute();
    if (!idValue.isNull())
        updateId(scope, nullAtom, idValue);

    return InsertionDone;
}

void Element::removedFrom(ContainerNode* insertionPoint)
{
    bool wasInDocument = insertionPoint->inDocument();

    setSavedLayerScrollOffset(IntSize());

    if (insertionPoint->isInTreeScope() && treeScope() == document()) {
        const AtomicString& idValue = getIdAttribute();
        if (!idValue.isNull())
            updateId(insertionPoint->treeScope(), idValue, nullAtom);
    }

    ContainerNode::removedFrom(insertionPoint);
    if (wasInDocument) {
        if (isUpgradedCustomElement())
            CustomElement::didDetach(this, insertionPoint->document());
    }
}

void Element::attach(const AttachContext& context)
{
    ASSERT(document().inStyleRecalc());

    // We've already been through detach when doing an attach, but we might
    // need to clear any state that's been added since then.
    if (hasRareData() && styleChangeType() == NeedsReattachStyleChange) {
        ElementRareData* data = elementRareData();
        data->clearComputedStyle();
    }

    RenderTreeBuilder(this, context.resolvedStyle).createRendererForElementIfNeeded();

    if (hasRareData() && !renderer()) {
        if (ActiveAnimations* activeAnimations = elementRareData()->activeAnimations()) {
            activeAnimations->cssAnimations().cancel();
            activeAnimations->setAnimationStyleChange(false);
        }
    }

    // When a shadow root exists, it does the work of attaching the children.
    if (ElementShadow* shadow = this->shadow())
        shadow->attach(context);

    ContainerNode::attach(context);
}

void Element::detach(const AttachContext& context)
{
    if (hasRareData()) {
        ElementRareData* data = elementRareData();

        // attach() will perform the below steps for us when inside recalcStyle.
        if (!document().inStyleRecalc()) {
            data->clearComputedStyle();
        }

        if (ActiveAnimations* activeAnimations = data->activeAnimations()) {
            if (context.performingReattach) {
                // FIXME: We call detach from within style recalc, so compositingState is not up to date.
                // https://code.google.com/p/chromium/issues/detail?id=339847
                DisableCompositingQueryAsserts disabler;

                // FIXME: restart compositor animations rather than pull back to the main thread
                activeAnimations->cancelAnimationOnCompositor();
            } else {
                activeAnimations->cssAnimations().cancel();
                activeAnimations->setAnimationStyleChange(false);
            }
        }

        if (ElementShadow* shadow = data->shadow())
            shadow->detach(context);
    }
    ContainerNode::detach(context);
}

PassRefPtr<RenderStyle> Element::styleForRenderer()
{
    ASSERT(document().inStyleRecalc());

    // FIXME: Instead of clearing updates that may have been added from calls to styleForElement
    // outside recalcStyle, we should just never set them if we're not inside recalcStyle.
    if (ActiveAnimations* activeAnimations = this->activeAnimations())
        activeAnimations->cssAnimations().setPendingUpdate(nullptr);

    RefPtr<RenderStyle> style = document().ensureStyleResolver().styleForElement(this);
    ASSERT(style);

    // styleForElement() might add active animations so we need to get it again.
    if (ActiveAnimations* activeAnimations = this->activeAnimations()) {
        activeAnimations->cssAnimations().maybeApplyPendingUpdate(this);
        activeAnimations->updateAnimationFlags(*style);
    }

    if (style->hasTransform()) {
        if (const StylePropertySet* inlineStyle = this->inlineStyle())
            style->setHasInlineTransform(inlineStyle->hasProperty(CSSPropertyTransform) || inlineStyle->hasProperty(CSSPropertyWebkitTransform));
    }

    document().didRecalculateStyleForElement();
    return style.release();
}

void Element::recalcStyle(StyleRecalcChange change, Text* nextTextSibling)
{
    ASSERT(document().inStyleRecalc());
    ASSERT(!parentOrShadowHostNode()->needsStyleRecalc());

    if (isInsertionPoint())
        toInsertionPoint(this)->willRecalcStyle(change);

    if (change >= Inherit || needsStyleRecalc()) {
        if (hasRareData()) {
            ElementRareData* data = elementRareData();
            data->clearComputedStyle();

            if (change >= Inherit) {
                if (ActiveAnimations* activeAnimations = data->activeAnimations())
                    activeAnimations->setAnimationStyleChange(false);
            }
        }
        if (parentRenderStyle())
            change = recalcOwnStyle(change);
        clearNeedsStyleRecalc();
    }

    // If we reattached we don't need to recalc the style of our descendants anymore.
    if ((change >= Inherit && change < Reattach) || childNeedsStyleRecalc()) {
        recalcChildStyle(change);
        clearChildNeedsStyleRecalc();
    }

    if (change == Reattach)
        reattachWhitespaceSiblings(nextTextSibling);
}

StyleRecalcChange Element::recalcOwnStyle(StyleRecalcChange change)
{
    ASSERT(document().inStyleRecalc());
    ASSERT(!parentOrShadowHostNode()->needsStyleRecalc());
    ASSERT(change >= Inherit || needsStyleRecalc());
    ASSERT(parentRenderStyle());

    RefPtr<RenderStyle> oldStyle = renderStyle();
    RefPtr<RenderStyle> newStyle = styleForRenderer();
    StyleRecalcChange localChange = RenderStyle::stylePropagationDiff(oldStyle.get(), newStyle.get());

    ASSERT(newStyle);

    if (localChange == Reattach) {
        AttachContext reattachContext;
        reattachContext.resolvedStyle = newStyle.get();
        bool rendererWillChange = needsAttach() || renderer();
        reattach(reattachContext);
        if (rendererWillChange || renderer())
            return Reattach;
        return ReattachNoRenderer;
    }

    ASSERT(oldStyle);

    if (RenderObject* renderer = this->renderer()) {
        if (localChange != NoChange) {
            renderer->setStyle(newStyle.get());
        } else {
            // Although no change occurred, we use the new style so that the cousin style sharing code won't get
            // fooled into believing this style is the same.
            // FIXME: We may be able to remove this hack, see discussion in
            // https://codereview.chromium.org/30453002/
            renderer->setStyleInternal(newStyle.get());
        }
    }

    if (styleChangeType() >= SubtreeStyleChange)
        return Force;

    if (change > Inherit || localChange > Inherit)
        return max(localChange, change);

    return localChange;
}

void Element::recalcChildStyle(StyleRecalcChange change)
{
    ASSERT(document().inStyleRecalc());
    ASSERT(change >= Inherit || childNeedsStyleRecalc());
    ASSERT(!needsStyleRecalc());

    if (change > Inherit || childNeedsStyleRecalc()) {
        for (ShadowRoot* root = youngestShadowRoot(); root; root = root->olderShadowRoot()) {
            if (root->shouldCallRecalcStyle(change))
                root->recalcStyle(change);
        }

        // This loop is deliberately backwards because we use insertBefore in the rendering tree, and want to avoid
        // a potentially n^2 loop to find the insertion point while resolving style. Having us start from the last
        // child and work our way back means in the common case, we'll find the insertion point in O(1) time.
        // See crbug.com/288225
        StyleResolver& styleResolver = document().ensureStyleResolver();
        Text* lastTextNode = 0;
        for (Node* child = lastChild(); child; child = child->previousSibling()) {
            if (child->isTextNode()) {
                toText(child)->recalcTextStyle(change, lastTextNode);
                lastTextNode = toText(child);
            } else if (child->isElementNode()) {
                Element* element = toElement(child);
                if (element->shouldCallRecalcStyle(change))
                    element->recalcStyle(change, lastTextNode);
                else if (element->supportsStyleSharing())
                    styleResolver.addToStyleSharingList(*element);
                if (element->renderer())
                    lastTextNode = 0;
            }
        }
    }
}

ElementShadow* Element::shadow() const
{
    return hasRareData() ? elementRareData()->shadow() : 0;
}

ElementShadow& Element::ensureShadow()
{
    return ensureElementRareData().ensureShadow();
}

void Element::setAnimationStyleChange(bool animationStyleChange)
{
    if (animationStyleChange && document().inStyleRecalc())
        return;
    if (ActiveAnimations* activeAnimations = elementRareData()->activeAnimations())
        activeAnimations->setAnimationStyleChange(animationStyleChange);
}

void Element::setNeedsAnimationStyleRecalc()
{
    if (styleChangeType() != NoStyleChange)
        return;

    setNeedsStyleRecalc(LocalStyleChange);
    setAnimationStyleChange(true);
}

void Element::setNeedsCompositingUpdate()
{
    if (!document().isActive())
        return;
    RenderBoxModelObject* renderer = renderBoxModelObject();
    if (!renderer)
        return;
    if (!renderer->hasLayer())
        return;
    renderer->layer()->setNeedsCompositingInputsUpdate();
}

void Element::setCustomElementDefinition(PassRefPtr<CustomElementDefinition> definition)
{
    if (!hasRareData() && !definition)
        return;
    ASSERT(!customElementDefinition());
    ensureElementRareData().setCustomElementDefinition(definition);
}

CustomElementDefinition* Element::customElementDefinition() const
{
    if (hasRareData())
        return elementRareData()->customElementDefinition();
    return 0;
}

PassRefPtr<ShadowRoot> Element::createShadowRoot(ExceptionState& exceptionState)
{
    return PassRefPtr<ShadowRoot>(ensureShadow().addShadowRoot(*this));
}

ShadowRoot* Element::shadowRoot() const
{
    ElementShadow* elementShadow = shadow();
    if (!elementShadow)
        return 0;
    return elementShadow->youngestShadowRoot();
}

void Element::childrenChanged(const ChildrenChange& change)
{
    ContainerNode::childrenChanged(change);

    if (ElementShadow* shadow = this->shadow())
        shadow->setNeedsDistributionRecalc();
}

#ifndef NDEBUG
void Element::formatForDebugger(char* buffer, unsigned length) const
{
    StringBuilder result;
    String s;

    result.append(nodeName());

    s = getIdAttribute();
    if (s.length() > 0) {
        if (result.length() > 0)
            result.appendLiteral("; ");
        result.appendLiteral("id=");
        result.append(s);
    }

    s = getAttribute(HTMLNames::classAttr);
    if (s.length() > 0) {
        if (result.length() > 0)
            result.appendLiteral("; ");
        result.appendLiteral("class=");
        result.append(s);
    }

    strncpy(buffer, result.toString().utf8().data(), length - 1);
}
#endif

void Element::parseAttribute(const QualifiedName& name, const AtomicString& value)
{
    if (name == HTMLNames::tabindexAttr) {
        int tabindex = 0;
        if (value.isEmpty()) {
            clearTabIndexExplicitlyIfNeeded();
            if (treeScope().adjustedFocusedElement() == this) {
                // We might want to call blur(), but it's dangerous to dispatch
                // events here.
                document().setNeedsFocusedElementCheck();
            }
        } else if (parseHTMLInteger(value, tabindex)) {
            // Clamp tabindex to the range of 'short' to match Firefox's behavior.
            setTabIndexExplicitly(max(static_cast<int>(std::numeric_limits<short>::min()), std::min(tabindex, static_cast<int>(std::numeric_limits<short>::max()))));
        }
    }
}

void Element::removeAttributeInternal(size_t index, SynchronizationOfLazyAttribute inSynchronizationOfLazyAttribute)
{
    MutableAttributeCollection attributes = ensureUniqueElementData().attributes();
    ASSERT_WITH_SECURITY_IMPLICATION(index < attributes.size());

    QualifiedName name = attributes[index].name();
    AtomicString valueBeingRemoved = attributes[index].value();

    if (!inSynchronizationOfLazyAttribute) {
        if (!valueBeingRemoved.isNull())
            willModifyAttribute(name, valueBeingRemoved, nullAtom);
    }

    attributes.remove(index);

    if (!inSynchronizationOfLazyAttribute)
        attributeChanged(name, nullAtom);
}

void Element::appendAttributeInternal(const QualifiedName& name, const AtomicString& value, SynchronizationOfLazyAttribute inSynchronizationOfLazyAttribute)
{
    if (!inSynchronizationOfLazyAttribute)
        willModifyAttribute(name, nullAtom, value);
    ensureUniqueElementData().attributes().append(name, value);
    if (!inSynchronizationOfLazyAttribute)
        attributeChanged(name, value);
}

void Element::removeAttribute(const AtomicString& localName)
{
    if (!elementData())
        return;

    size_t index = elementData()->attributes().findIndex(localName);
    if (index == kNotFound) {
        if (UNLIKELY(localName == HTMLNames::styleAttr) && elementData()->m_styleAttributeIsDirty && isStyledElement())
            removeAllInlineStyleProperties();
        return;
    }

    removeAttributeInternal(index, NotInSynchronizationOfLazyAttribute);
}

Vector<RefPtr<Attr>> Element::getAttributes()
{
    if (!elementData())
        return Vector<RefPtr<Attr>>();
    synchronizeAllAttributes();
    Vector<RefPtr<Attr>> attributes;
    for (const Attribute& attribute : elementData()->attributes())
        attributes.append(Attr::create(attribute.name(), attribute.value()));
    return attributes;
}

void Element::focus(bool restorePreviousSelection, FocusType type)
{
    if (!inDocument())
        return;

    if (document().focusedElement() == this)
        return;

    if (!document().isActive())
        return;

    document().updateLayoutIgnorePendingStylesheets();
    if (!isFocusable())
        return;

    RefPtr<Node> protect(this);
    if (!document().page()->focusController().setFocusedElement(this, document().frame(), type))
        return;

    // Setting the focused node above might have invalidated the layout due to scripts.
    document().updateLayoutIgnorePendingStylesheets();
    if (!isFocusable())
        return;
    updateFocusAppearance(restorePreviousSelection);

    if (UserGestureIndicator::processedUserGestureSinceLoad()) {
        // Bring up the keyboard in the context of anything triggered by a user
        // gesture. Since tracking that across arbitrary boundaries (eg.
        // animations) is difficult, for now we match IE's heuristic and bring
        // up the keyboard if there's been any gesture since load.
        document().page()->chrome().client().showImeIfNeeded();
    }
}

void Element::updateFocusAppearance(bool /*restorePreviousSelection*/)
{
    if (isRootEditableElement()) {
        // Taking the ownership since setSelection() may release the last reference to |frame|.
        RefPtr<LocalFrame> frame(document().frame());
        if (!frame)
            return;

        // When focusing an editable element in an iframe, don't reset the selection if it already contains a selection.
        if (this == frame->selection().rootEditableElement())
            return;

        // FIXME: We should restore the previous selection if there is one.
        VisibleSelection newSelection = VisibleSelection(firstPositionInOrBeforeNode(this), DOWNSTREAM);
        // Passing DoNotSetFocus as this function is called after FocusController::setFocusedElement()
        // and we don't want to change the focus to a new Element.
        frame->selection().setSelection(newSelection,  FrameSelection::CloseTyping | FrameSelection::ClearTypingStyle | FrameSelection::DoNotSetFocus);
        frame->selection().revealSelection();
    } else if (renderer())
        renderer()->scrollRectToVisible(boundingBox());
}

void Element::blur()
{
    if (treeScope().adjustedFocusedElement() == this) {
        Document& doc = document();
        if (doc.page())
            doc.page()->focusController().setFocusedElement(0, doc.frame());
        else
            doc.setFocusedElement(nullptr);
    }
}

bool Element::supportsFocus() const
{
    // FIXME: supportsFocus() can be called when layout is not up to date.
    // Logic that deals with the renderer should be moved to rendererIsFocusable().
    // But supportsFocus must return true when the element is editable, or else
    // it won't be focusable. Furthermore, supportsFocus cannot just return true
    // always or else tabIndex() will change for all HTML elements.
    return hasElementFlag(TabIndexWasSetExplicitly) || (hasEditableStyle() && parentNode() && !parentNode()->hasEditableStyle());
}

bool Element::isFocusable() const
{
    return inDocument() && supportsFocus() && !isInert() && rendererIsFocusable();
}

bool Element::isKeyboardFocusable() const
{
    return isFocusable() && tabIndex() >= 0;
}

bool Element::isMouseFocusable() const
{
    return isFocusable();
}

void Element::willCallDefaultEventHandler(const Event& event)
{
    if (!wasFocusedByMouse())
        return;
    if (!event.isKeyboardEvent() || event.type() != EventTypeNames::keydown)
        return;
    setWasFocusedByMouse(false);
    if (renderer())
        renderer()->setShouldDoFullPaintInvalidation(true);
}

void Element::dispatchFocusEvent(Element* oldFocusedElement, FocusType type)
{
    if (type != FocusTypePage)
        setWasFocusedByMouse(type == FocusTypeMouse);

    RefPtr<FocusEvent> event = FocusEvent::create(EventTypeNames::focus, false, false, document().domWindow(), 0, oldFocusedElement);
    EventDispatcher::dispatchEvent(this, FocusEventDispatchMediator::create(event.release()));
}

void Element::dispatchBlurEvent(Element* newFocusedElement)
{
    RefPtr<FocusEvent> event = FocusEvent::create(EventTypeNames::blur, false, false, document().domWindow(), 0, newFocusedElement);
    EventDispatcher::dispatchEvent(this, BlurEventDispatchMediator::create(event.release()));
}

void Element::dispatchFocusInEvent(const AtomicString& eventType, Element* oldFocusedElement)
{
    ASSERT(!EventDispatchForbiddenScope::isEventDispatchForbidden());
    ASSERT(eventType == EventTypeNames::focusin || eventType == EventTypeNames::DOMFocusIn);
    dispatchScopedEventDispatchMediator(FocusInEventDispatchMediator::create(FocusEvent::create(eventType, true, false, document().domWindow(), 0, oldFocusedElement)));
}

void Element::dispatchFocusOutEvent(const AtomicString& eventType, Element* newFocusedElement)
{
    ASSERT(!EventDispatchForbiddenScope::isEventDispatchForbidden());
    ASSERT(eventType == EventTypeNames::focusout || eventType == EventTypeNames::DOMFocusOut);
    dispatchScopedEventDispatchMediator(FocusOutEventDispatchMediator::create(FocusEvent::create(eventType, true, false, document().domWindow(), 0, newFocusedElement)));
}

String Element::textFromChildren()
{
    Text* firstTextNode = 0;
    bool foundMultipleTextNodes = false;
    unsigned totalLength = 0;

    for (Node* child = firstChild(); child; child = child->nextSibling()) {
        if (!child->isTextNode())
            continue;
        Text* text = toText(child);
        if (!firstTextNode)
            firstTextNode = text;
        else
            foundMultipleTextNodes = true;
        unsigned length = text->data().length();
        if (length > std::numeric_limits<unsigned>::max() - totalLength)
            return emptyString();
        totalLength += length;
    }

    if (!firstTextNode)
        return emptyString();

    if (firstTextNode && !foundMultipleTextNodes) {
        firstTextNode->atomize();
        return firstTextNode->data();
    }

    StringBuilder content;
    content.reserveCapacity(totalLength);
    for (Node* child = firstTextNode; child; child = child->nextSibling()) {
        if (!child->isTextNode())
            continue;
        content.append(toText(child)->data());
    }

    ASSERT(content.length() == totalLength);
    return content.toString();
}

// FIXME(sky): Remove pseudoElementSpecifier.
RenderStyle* Element::computedStyle(PseudoId pseudoElementSpecifier)
{
    // FIXME: Find and use the renderer from the pseudo element instead of the actual element so that the 'length'
    // properties, which are only known by the renderer because it did the layout, will be correct and so that the
    // values returned for the ":selection" pseudo-element will be correct.
    if (RenderStyle* usedStyle = renderStyle())
        return usedStyle;

    if (!inActiveDocument())
        // FIXME: Try to do better than this. Ensure that styleForElement() works for elements that are not in the
        // document tree and figure out when to destroy the computed style for such elements.
        return 0;

    ElementRareData& rareData = ensureElementRareData();
    if (!rareData.computedStyle())
        rareData.setComputedStyle(document().styleForElementIgnoringPendingStylesheets(this));
    return rareData.computedStyle();
}

AtomicString Element::computeInheritedLanguage() const
{
    const Node* n = this;
    AtomicString value;
    // The language property is inherited, so we iterate over the parents to find the first language.
    do {
        if (n->isElementNode()) {
            if (const ElementData* elementData = toElement(n)->elementData()) {
                AttributeCollection attributes = elementData->attributes();
                if (const Attribute* attribute = attributes.find(HTMLNames::langAttr))
                    value = attribute->value();
            }
        } else if (n->isDocumentNode()) {
            // checking the MIME content-language
            value = toDocument(n)->contentLanguage();
        }

        n = n->parentNode();
    } while (n && value.isNull());

    return value;
}

bool Element::matches(const String& selectors, ExceptionState& exceptionState)
{
    SelectorQuery* selectorQuery = document().selectorQueryCache().add(AtomicString(selectors), document(), exceptionState);
    if (!selectorQuery)
        return false;
    return selectorQuery->matches(*this);
}

DOMTokenList& Element::classList()
{
    ElementRareData& rareData = ensureElementRareData();
    if (!rareData.classList())
        rareData.setClassList(ClassList::create(this));
    return *rareData.classList();
}

KURL Element::hrefURL() const
{
    // FIXME: These all have href() or url(), but no common super class. Why doesn't
    // <link> implement URLUtils?
    if (isHTMLAnchorElement(*this))
        return getURLAttribute(HTMLNames::hrefAttr);
    return KURL();
}

KURL Element::getURLAttribute(const QualifiedName& name) const
{
#if ENABLE(ASSERT)
    if (elementData()) {
        if (const Attribute* attribute = attributes().find(name))
            ASSERT(isURLAttribute(*attribute));
    }
#endif
    return document().completeURL(stripLeadingAndTrailingHTMLSpaces(getAttribute(name)));
}

KURL Element::getNonEmptyURLAttribute(const QualifiedName& name) const
{
#if ENABLE(ASSERT)
    if (elementData()) {
        if (const Attribute* attribute = attributes().find(name))
            ASSERT(isURLAttribute(*attribute));
    }
#endif
    String value = stripLeadingAndTrailingHTMLSpaces(getAttribute(name));
    if (value.isEmpty())
        return KURL();
    return document().completeURL(value);
}

int Element::getIntegralAttribute(const QualifiedName& attributeName) const
{
    return getAttribute(attributeName).string().toInt();
}

void Element::setIntegralAttribute(const QualifiedName& attributeName, int value)
{
    setAttribute(attributeName, AtomicString::number(value));
}

unsigned Element::getUnsignedIntegralAttribute(const QualifiedName& attributeName) const
{
    return getAttribute(attributeName).string().toUInt();
}

void Element::setUnsignedIntegralAttribute(const QualifiedName& attributeName, unsigned value)
{
    // Range restrictions are enforced for unsigned IDL attributes that
    // reflect content attributes,
    //   http://www.whatwg.org/specs/web-apps/current-work/multipage/common-dom-interfaces.html#reflecting-content-attributes-in-idl-attributes
    if (value > 0x7fffffffu)
        value = 0;
    setAttribute(attributeName, AtomicString::number(value));
}

double Element::getFloatingPointAttribute(const QualifiedName& attributeName, double fallbackValue) const
{
    return parseToDoubleForNumberType(getAttribute(attributeName), fallbackValue);
}

void Element::setFloatingPointAttribute(const QualifiedName& attributeName, double value)
{
    setAttribute(attributeName, AtomicString::number(value));
}

SpellcheckAttributeState Element::spellcheckAttributeState() const
{
    const AtomicString& value = getAttribute(HTMLNames::spellcheckAttr);
    if (value == nullAtom)
        return SpellcheckAttributeDefault;
    if (equalIgnoringCase(value, "true") || equalIgnoringCase(value, ""))
        return SpellcheckAttributeTrue;
    if (equalIgnoringCase(value, "false"))
        return SpellcheckAttributeFalse;

    return SpellcheckAttributeDefault;
}

bool Element::isSpellCheckingEnabled() const
{
    for (const Element* element = this; element; element = element->parentOrShadowHostElement()) {
        switch (element->spellcheckAttributeState()) {
        case SpellcheckAttributeTrue:
            return true;
        case SpellcheckAttributeFalse:
            return false;
        case SpellcheckAttributeDefault:
            break;
        }
    }

    return true;
}

inline void Element::updateId(const AtomicString& oldId, const AtomicString& newId)
{
    if (!isInTreeScope())
        return;

    if (oldId == newId)
        return;

    updateId(treeScope(), oldId, newId);
}

inline void Element::updateId(TreeScope& scope, const AtomicString& oldId, const AtomicString& newId)
{
    ASSERT(isInTreeScope());
    ASSERT(oldId != newId);

    if (!oldId.isEmpty())
        scope.removeElementById(oldId, this);
    if (!newId.isEmpty())
        scope.addElementById(newId, this);
}

void Element::willModifyAttribute(const QualifiedName& name, const AtomicString& oldValue, const AtomicString& newValue)
{
    if (name == HTMLNames::idAttr) {
        updateId(oldValue, newValue);
    }

    if (oldValue != newValue) {
        if (inActiveDocument() && document().styleResolver() && styleChangeType() < SubtreeStyleChange)
            document().ensureStyleResolver().ensureUpdatedRuleFeatureSet().scheduleStyleInvalidationForAttributeChange(name, *this);

        if (isUpgradedCustomElement())
            CustomElement::attributeDidChange(this, name.localName(), oldValue, newValue);
    }

    if (OwnPtr<MutationObserverInterestGroup> recipients = MutationObserverInterestGroup::createForAttributesMutation(*this, name))
        recipients->enqueueMutationRecord(MutationRecord::createAttributes(this, name, oldValue));
}

static bool needsURLResolutionForInlineStyle(const Element& element, const Document& oldDocument, const Document& newDocument)
{
    if (oldDocument == newDocument)
        return false;
    if (oldDocument.baseURL() == newDocument.baseURL())
        return false;
    const StylePropertySet* style = element.inlineStyle();
    if (!style)
        return false;
    for (unsigned i = 0; i < style->propertyCount(); ++i) {
        // FIXME: Should handle all URL-based properties: CSSImageSetValue, CSSCursorImageValue, etc.
        if (style->propertyAt(i).value()->isImageValue())
            return true;
    }
    return false;
}

static void reResolveURLsInInlineStyle(const Document& document, MutableStylePropertySet& style)
{
    for (unsigned i = 0; i < style.propertyCount(); ++i) {
        StylePropertySet::PropertyReference property = style.propertyAt(i);
        // FIXME: Should handle all URL-based properties: CSSImageSetValue, CSSCursorImageValue, etc.
        if (property.value()->isImageValue())
            toCSSImageValue(property.value())->reResolveURL(document);
    }
}

void Element::didMoveToNewDocument(Document& oldDocument)
{
    Node::didMoveToNewDocument(oldDocument);

    if (needsURLResolutionForInlineStyle(*this, oldDocument, document()))
        reResolveURLsInInlineStyle(document(), ensureMutableInlineStyle());
}

IntSize Element::savedLayerScrollOffset() const
{
    return hasRareData() ? elementRareData()->savedLayerScrollOffset() : IntSize();
}

void Element::setSavedLayerScrollOffset(const IntSize& size)
{
    if (size.isZero() && !hasRareData())
        return;
    ensureElementRareData().setSavedLayerScrollOffset(size);
}

void Element::cloneAttributesFromElement(const Element& other)
{
    other.synchronizeAllAttributes();
    if (!other.m_elementData) {
        m_elementData.clear();
        return;
    }

    const AtomicString& oldID = getIdAttribute();
    const AtomicString& newID = other.getIdAttribute();

    if (!oldID.isNull() || !newID.isNull())
        updateId(oldID, newID);

    // If 'other' has a mutable ElementData, convert it to an immutable one so we can share it between both elements.
    // We can only do this if there are no presentation attributes and sharing the data won't result in different case sensitivity of class or id.
    if (other.m_elementData->isUnique())
        const_cast<Element&>(other).m_elementData = toUniqueElementData(other.m_elementData)->makeShareableCopy();

    if (!other.m_elementData->isUnique() && !needsURLResolutionForInlineStyle(other, other.document(), document()))
        m_elementData = other.m_elementData;
    else
        m_elementData = other.m_elementData->makeUniqueCopy();

    AttributeCollection attributes = m_elementData->attributes();
    AttributeCollection::iterator end = attributes.end();
    for (AttributeCollection::iterator it = attributes.begin(); it != end; ++it)
        attributeChangedFromParserOrByCloning(it->name(), it->value(), ModifiedByCloning);
}

void Element::cloneDataFromElement(const Element& other)
{
    // FIXME(sky): Merge these.
    cloneAttributesFromElement(other);
}

void Element::createUniqueElementData()
{
    if (!m_elementData)
        m_elementData = UniqueElementData::create();
    else {
        ASSERT(!m_elementData->isUnique());
        m_elementData = toShareableElementData(m_elementData)->makeUniqueCopy();
    }
}

InputMethodContext& Element::inputMethodContext()
{
    return ensureElementRareData().ensureInputMethodContext(toHTMLElement(this));
}

bool Element::hasInputMethodContext() const
{
    return hasRareData() && elementRareData()->hasInputMethodContext();
}

void Element::synchronizeStyleAttributeInternal() const
{
    ASSERT(isStyledElement());
    ASSERT(elementData());
    ASSERT(elementData()->m_styleAttributeIsDirty);
    elementData()->m_styleAttributeIsDirty = false;
    const StylePropertySet* inlineStyle = this->inlineStyle();
    const_cast<Element*>(this)->setSynchronizedLazyAttribute(HTMLNames::styleAttr,
        inlineStyle ? AtomicString(inlineStyle->asText()) : nullAtom);
}

CSSStyleDeclaration* Element::style()
{
    if (!isStyledElement())
        return 0;
    return &ensureElementRareData().ensureInlineCSSStyleDeclaration(this);
}

MutableStylePropertySet& Element::ensureMutableInlineStyle()
{
    ASSERT(isStyledElement());
    RefPtr<StylePropertySet>& inlineStyle = ensureUniqueElementData().m_inlineStyle;
    if (!inlineStyle) {
        inlineStyle = MutableStylePropertySet::create(HTMLStandardMode);
    } else if (!inlineStyle->isMutable()) {
        inlineStyle = inlineStyle->mutableCopy();
    }
    return *toMutableStylePropertySet(inlineStyle);
}

void Element::clearMutableInlineStyleIfEmpty()
{
    if (ensureMutableInlineStyle().isEmpty()) {
        ensureUniqueElementData().m_inlineStyle.clear();
    }
}

inline void Element::setInlineStyleFromString(const AtomicString& newStyleString)
{
    ASSERT(isStyledElement());
    RefPtr<StylePropertySet>& inlineStyle = elementData()->m_inlineStyle;

    // Avoid redundant work if we're using shared attribute data with already parsed inline style.
    if (inlineStyle && !elementData()->isUnique())
        return;

    // We reconstruct the property set instead of mutating if there is no CSSOM wrapper.
    // This makes wrapperless property sets immutable and so cacheable.
    if (inlineStyle && !inlineStyle->isMutable())
        inlineStyle.clear();

    if (!inlineStyle) {
        inlineStyle = BisonCSSParser::parseInlineStyleDeclaration(newStyleString, this);
    } else {
        ASSERT(inlineStyle->isMutable());
        static_cast<MutableStylePropertySet*>(inlineStyle.get())->parseDeclaration(newStyleString, document().elementSheet().contents());
    }
}

void Element::styleAttributeChanged(const AtomicString& newStyleString)
{
    ASSERT(isStyledElement());

    if (newStyleString.isNull()) {
        ensureUniqueElementData().m_inlineStyle.clear();
    } else {
        setInlineStyleFromString(newStyleString);
    }

    elementData()->m_styleAttributeIsDirty = false;

    setNeedsStyleRecalc(LocalStyleChange);
}

void Element::inlineStyleChanged()
{
    ASSERT(isStyledElement());
    setNeedsStyleRecalc(LocalStyleChange);
    ASSERT(elementData());
    elementData()->m_styleAttributeIsDirty = true;
}

bool Element::setInlineStyleProperty(CSSPropertyID propertyID, CSSValueID identifier, bool important)
{
    ASSERT(isStyledElement());
    ensureMutableInlineStyle().setProperty(propertyID, cssValuePool().createIdentifierValue(identifier), important);
    inlineStyleChanged();
    return true;
}

bool Element::setInlineStyleProperty(CSSPropertyID propertyID, double value, CSSPrimitiveValue::UnitType unit, bool important)
{
    ASSERT(isStyledElement());
    ensureMutableInlineStyle().setProperty(propertyID, cssValuePool().createValue(value, unit), important);
    inlineStyleChanged();
    return true;
}

bool Element::setInlineStyleProperty(CSSPropertyID propertyID, const String& value, bool important)
{
    ASSERT(isStyledElement());
    bool changes = ensureMutableInlineStyle().setProperty(propertyID, value, important, document().elementSheet().contents());
    if (changes)
        inlineStyleChanged();
    return changes;
}

bool Element::removeInlineStyleProperty(CSSPropertyID propertyID)
{
    ASSERT(isStyledElement());
    if (!inlineStyle())
        return false;
    bool changes = ensureMutableInlineStyle().removeProperty(propertyID);
    if (changes)
        inlineStyleChanged();
    return changes;
}

void Element::removeAllInlineStyleProperties()
{
    ASSERT(isStyledElement());
    if (!inlineStyle())
        return;
    ensureMutableInlineStyle().clear();
    inlineStyleChanged();
}

bool Element::supportsStyleSharing() const
{
    if (!isStyledElement() || !parentOrShadowHostElement())
        return false;
    // If the element has inline style it is probably unique.
    if (inlineStyle())
        return false;
    // Ids stop style sharing if they show up in the stylesheets.
    if (hasID() && document().ensureStyleResolver().hasRulesForId(idForStyleResolution()))
        return false;
    // :active and :hover elements always make a chain towards the document node
    // and no siblings or cousins will have the same state. There's also only one
    // :focus element per scope so we don't need to attempt to share.
    if (isUserActionElement())
        return false;
    if (hasActiveAnimations())
        return false;
    // Turn off style sharing for elements that can gain layers for reasons outside of the style system.
    // See comments in RenderObject::setStyle().
    // FIXME: Why does gaining a layer from outside the style system require disabling sharing?
    if (isHTMLCanvasElement(*this))
        return false;
    return true;
}

} // namespace blink
