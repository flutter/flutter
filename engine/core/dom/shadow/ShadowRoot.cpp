/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
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

#include "config.h"
#include "core/dom/shadow/ShadowRoot.h"

#include "bindings/core/v8/ExceptionState.h"
#include "core/css/StyleSheetList.h"
#include "core/css/resolver/StyleResolver.h"
#include "core/dom/ElementTraversal.h"
#include "core/dom/StyleEngine.h"
#include "core/dom/Text.h"
#include "core/dom/shadow/ElementShadow.h"
#include "core/dom/shadow/InsertionPoint.h"
#include "core/dom/shadow/ShadowRootRareData.h"
#include "core/editing/markup.h"
#include "core/html/HTMLShadowElement.h"
#include "public/platform/Platform.h"

namespace blink {

struct SameSizeAsShadowRoot : public DocumentFragment, public TreeScope, public DoublyLinkedListNode<ShadowRoot> {
    void* pointers[3];
    unsigned countersAndFlags[1];
};

COMPILE_ASSERT(sizeof(ShadowRoot) == sizeof(SameSizeAsShadowRoot), shadowroot_should_stay_small);

ShadowRoot::ShadowRoot(Document& document)
    : DocumentFragment(0, CreateShadowRoot)
    , TreeScope(*this, document)
    , m_prev(nullptr)
    , m_next(nullptr)
    , m_numberOfStyles(0)
    , m_registeredWithParentShadowRoot(false)
    , m_descendantInsertionPointsIsValid(false)
{
    ScriptWrappable::init(this);
}

ShadowRoot::~ShadowRoot()
{
#if !ENABLE(OILPAN)
    ASSERT(!m_prev);
    ASSERT(!m_next);

    if (m_shadowRootRareData && m_shadowRootRareData->styleSheets())
        m_shadowRootRareData->styleSheets()->detachFromDocument();

    document().styleEngine()->didRemoveShadowRoot(this);

    // We cannot let ContainerNode destructor call willBeDeletedFromDocument()
    // for this ShadowRoot instance because TreeScope destructor
    // clears Node::m_treeScope thus ContainerNode is no longer able
    // to access it Document reference after that.
    willBeDeletedFromDocument();

    // We must remove all of our children first before the TreeScope destructor
    // runs so we don't go through TreeScopeAdopter for each child with a
    // destructed tree scope in each descendant.
    removeDetachedChildren();

    // We must call clearRareData() here since a ShadowRoot class inherits TreeScope
    // as well as Node. See a comment on TreeScope.h for the reason.
    if (hasRareData())
        clearRareData();
#endif
}

#if !ENABLE(OILPAN)
void ShadowRoot::dispose()
{
    removeDetachedChildren();
}
#endif

PassRefPtrWillBeRawPtr<Node> ShadowRoot::cloneNode(bool, ExceptionState& exceptionState)
{
    exceptionState.throwDOMException(DataCloneError, "ShadowRoot nodes are not clonable.");
    return nullptr;
}

void ShadowRoot::recalcStyle(StyleRecalcChange change)
{
    // ShadowRoot doesn't support custom callbacks.
    ASSERT(!hasCustomStyleCallbacks());

    if (styleChangeType() >= SubtreeStyleChange)
        change = Force;

    // There's no style to update so just calling recalcStyle means we're updated.
    clearNeedsStyleRecalc();

    // FIXME: This doesn't handle :hover + div properly like Element::recalcStyle does.
    Text* lastTextNode = 0;
    for (Node* child = lastChild(); child; child = child->previousSibling()) {
        if (child->isTextNode()) {
            toText(child)->recalcTextStyle(change, lastTextNode);
            lastTextNode = toText(child);
        } else if (child->isElementNode()) {
            if (child->shouldCallRecalcStyle(change))
                toElement(child)->recalcStyle(change, lastTextNode);
            if (child->renderer())
                lastTextNode = 0;
        }
    }

    clearChildNeedsStyleRecalc();
}

Node::InsertionNotificationRequest ShadowRoot::insertedInto(ContainerNode* insertionPoint)
{
    DocumentFragment::insertedInto(insertionPoint);

    if (!insertionPoint->inDocument() || !isOldest())
        return InsertionDone;

    // FIXME: When parsing <video controls>, insertedInto() is called many times without invoking removedFrom.
    // For now, we check m_registeredWithParentShadowroot. We would like to ASSERT(!m_registeredShadowRoot) here.
    // https://bugs.webkit.org/show_bug.cig?id=101316
    if (m_registeredWithParentShadowRoot)
        return InsertionDone;

    if (ShadowRoot* root = host()->containingShadowRoot()) {
        root->addChildShadowRoot();
        m_registeredWithParentShadowRoot = true;
    }

    return InsertionDone;
}

void ShadowRoot::removedFrom(ContainerNode* insertionPoint)
{
    if (insertionPoint->inDocument() && m_registeredWithParentShadowRoot) {
        ShadowRoot* root = host()->containingShadowRoot();
        if (!root)
            root = insertionPoint->containingShadowRoot();
        if (root)
            root->removeChildShadowRoot();
        m_registeredWithParentShadowRoot = false;
    }

    DocumentFragment::removedFrom(insertionPoint);
}

void ShadowRoot::childrenChanged(const ChildrenChange& change)
{
    ContainerNode::childrenChanged(change);

    if (InsertionPoint* point = shadowInsertionPointOfYoungerShadowRoot()) {
        if (ShadowRoot* root = point->containingShadowRoot())
            root->owner()->setNeedsDistributionRecalc();
    }
}

void ShadowRoot::registerScopedHTMLStyleChild()
{
    ++m_numberOfStyles;
}

void ShadowRoot::unregisterScopedHTMLStyleChild()
{
    ASSERT(m_numberOfStyles > 0);
    --m_numberOfStyles;
}

ShadowRootRareData* ShadowRoot::ensureShadowRootRareData()
{
    if (m_shadowRootRareData)
        return m_shadowRootRareData.get();

    m_shadowRootRareData = adoptPtrWillBeNoop(new ShadowRootRareData);
    return m_shadowRootRareData.get();
}

bool ShadowRoot::containsShadowElements() const
{
    return m_shadowRootRareData ? m_shadowRootRareData->containsShadowElements() : 0;
}

bool ShadowRoot::containsContentElements() const
{
    return m_shadowRootRareData ? m_shadowRootRareData->containsContentElements() : 0;
}

bool ShadowRoot::containsShadowRoots() const
{
    return m_shadowRootRareData ? m_shadowRootRareData->containsShadowRoots() : 0;
}

unsigned ShadowRoot::descendantShadowElementCount() const
{
    return m_shadowRootRareData ? m_shadowRootRareData->descendantShadowElementCount() : 0;
}

HTMLShadowElement* ShadowRoot::shadowInsertionPointOfYoungerShadowRoot() const
{
    return m_shadowRootRareData ? m_shadowRootRareData->shadowInsertionPointOfYoungerShadowRoot() : 0;
}

void ShadowRoot::setShadowInsertionPointOfYoungerShadowRoot(PassRefPtrWillBeRawPtr<HTMLShadowElement> shadowInsertionPoint)
{
    if (!m_shadowRootRareData && !shadowInsertionPoint)
        return;
    ensureShadowRootRareData()->setShadowInsertionPointOfYoungerShadowRoot(shadowInsertionPoint);
}

void ShadowRoot::didAddInsertionPoint(InsertionPoint* insertionPoint)
{
    ensureShadowRootRareData()->didAddInsertionPoint(insertionPoint);
    invalidateDescendantInsertionPoints();
}

void ShadowRoot::didRemoveInsertionPoint(InsertionPoint* insertionPoint)
{
    m_shadowRootRareData->didRemoveInsertionPoint(insertionPoint);
    invalidateDescendantInsertionPoints();
}

void ShadowRoot::addChildShadowRoot()
{
    ensureShadowRootRareData()->didAddChildShadowRoot();
}

void ShadowRoot::removeChildShadowRoot()
{
    // FIXME: Why isn't this an ASSERT?
    if (!m_shadowRootRareData)
        return;
    m_shadowRootRareData->didRemoveChildShadowRoot();
}

unsigned ShadowRoot::childShadowRootCount() const
{
    return m_shadowRootRareData ? m_shadowRootRareData->childShadowRootCount() : 0;
}

void ShadowRoot::invalidateDescendantInsertionPoints()
{
    m_descendantInsertionPointsIsValid = false;
    m_shadowRootRareData->clearDescendantInsertionPoints();
}

const WillBeHeapVector<RefPtrWillBeMember<InsertionPoint> >& ShadowRoot::descendantInsertionPoints()
{
    DEFINE_STATIC_LOCAL(WillBePersistentHeapVector<RefPtrWillBeMember<InsertionPoint> >, emptyList, ());
    if (m_shadowRootRareData && m_descendantInsertionPointsIsValid)
        return m_shadowRootRareData->descendantInsertionPoints();

    m_descendantInsertionPointsIsValid = true;

    if (!containsInsertionPoints())
        return emptyList;

    WillBeHeapVector<RefPtrWillBeMember<InsertionPoint> > insertionPoints;
    for (InsertionPoint* insertionPoint = Traversal<InsertionPoint>::firstWithin(*this); insertionPoint; insertionPoint = Traversal<InsertionPoint>::next(*insertionPoint, this))
        insertionPoints.append(insertionPoint);

    ensureShadowRootRareData()->setDescendantInsertionPoints(insertionPoints);

    return m_shadowRootRareData->descendantInsertionPoints();
}

StyleSheetList* ShadowRoot::styleSheets()
{
    if (!ensureShadowRootRareData()->styleSheets())
        m_shadowRootRareData->setStyleSheets(StyleSheetList::create(this));

    return m_shadowRootRareData->styleSheets();
}

void ShadowRoot::trace(Visitor* visitor)
{
    visitor->trace(m_prev);
    visitor->trace(m_next);
    visitor->trace(m_shadowRootRareData);
    TreeScope::trace(visitor);
    DocumentFragment::trace(visitor);
}

}
