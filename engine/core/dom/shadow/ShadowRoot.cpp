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

#include "sky/engine/config.h"
#include "sky/engine/core/dom/shadow/ShadowRoot.h"

#include "sky/engine/bindings2/exception_state.h"
#include "sky/engine/core/css/resolver/StyleResolver.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/ElementTraversal.h"
#include "sky/engine/core/dom/StyleEngine.h"
#include "sky/engine/core/dom/Text.h"
#include "sky/engine/core/dom/shadow/ElementShadow.h"
#include "sky/engine/core/dom/shadow/InsertionPoint.h"
#include "sky/engine/public/platform/Platform.h"

namespace blink {

struct SameSizeAsShadowRoot : public DocumentFragment, public TreeScope {
    Vector<RefPtr<InsertionPoint>> vector;
    unsigned countersAndFlags[3];
};

COMPILE_ASSERT(sizeof(ShadowRoot) == sizeof(SameSizeAsShadowRoot), shadowroot_should_stay_small);

ShadowRoot::ShadowRoot(Document& document)
    : DocumentFragment(0, CreateShadowRoot)
    , TreeScope(*this, document)
    , m_descendantContentElementCount(0)
    , m_childShadowRootCount(0)
    , m_descendantInsertionPointsIsValid(false)
{
}

ShadowRoot::~ShadowRoot()
{
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
}

void ShadowRoot::dispose()
{
    invalidateDescendantInsertionPoints();
    removeDetachedChildren();
}

PassRefPtr<Node> ShadowRoot::cloneNode(bool, ExceptionState& exceptionState)
{
    exceptionState.ThrowDOMException(DataCloneError, "ShadowRoot nodes are not clonable.");
    return nullptr;
}

PassRefPtr<Node> ShadowRoot::cloneNode(ExceptionState& exceptionState)
{
    return cloneNode(exceptionState);
}

PassRefPtr<Node> ShadowRoot::cloneNode(bool deep)
{
    return nullptr;
}

void ShadowRoot::recalcStyle(StyleRecalcChange change)
{
    if (styleChangeType() >= SubtreeStyleChange)
        change = Force;

    // There's no style to update so just calling recalcStyle means we're updated.
    clearNeedsStyleRecalc();

    for (Node* child = lastChild(); child; child = child->previousSibling()) {
        if (child->isTextNode()) {
            toText(child)->recalcTextStyle(change);
        } else if (child->isElementNode()) {
            if (child->shouldCallRecalcStyle(change))
                toElement(child)->recalcStyle(change);
        }
    }

    clearChildNeedsStyleRecalc();
}

void ShadowRoot::insertedInto(ContainerNode* insertionPoint)
{
    DocumentFragment::insertedInto(insertionPoint);

    if (inActiveDocument())
        document().styleEngine()->addTreeScope(*this);

    if (ShadowRoot* root = host()->containingShadowRoot())
        root->addChildShadowRoot();
}

void ShadowRoot::removedFrom(ContainerNode* insertionPoint)
{
    ShadowRoot* root = host()->containingShadowRoot();
    if (!root)
        root = insertionPoint->containingShadowRoot();
    if (root)
        root->removeChildShadowRoot();

    if (inActiveDocument())
        document().styleEngine()->removeTreeScope(*this);

    DocumentFragment::removedFrom(insertionPoint);
}

void ShadowRoot::didAddInsertionPoint()
{
    ++m_descendantContentElementCount;
    invalidateDescendantInsertionPoints();
}

void ShadowRoot::didRemoveInsertionPoint()
{
    ASSERT(m_descendantContentElementCount);
    --m_descendantContentElementCount;
    invalidateDescendantInsertionPoints();
}

void ShadowRoot::addChildShadowRoot()
{
    ++m_childShadowRootCount;
}

void ShadowRoot::removeChildShadowRoot()
{
    ASSERT(m_childShadowRootCount);
    --m_childShadowRootCount;
}

void ShadowRoot::invalidateDescendantInsertionPoints()
{
    m_descendantInsertionPointsIsValid = false;
    m_descendantInsertionPoints.clear();
}

bool ShadowRoot::containsContentElements() const
{
    return m_descendantContentElementCount;
}

bool ShadowRoot::containsShadowRoots() const
{
    return m_childShadowRootCount;
}

const Vector<RefPtr<InsertionPoint> >& ShadowRoot::descendantInsertionPoints()
{
    DEFINE_STATIC_LOCAL(Vector<RefPtr<InsertionPoint> >, emptyList, ());
    if (m_descendantInsertionPointsIsValid)
        return m_descendantInsertionPoints;

    m_descendantInsertionPointsIsValid = true;

    if (!containsContentElements())
        return emptyList;

    Vector<RefPtr<InsertionPoint> > insertionPoints;
    for (InsertionPoint* insertionPoint = Traversal<InsertionPoint>::firstWithin(*this); insertionPoint; insertionPoint = Traversal<InsertionPoint>::next(*insertionPoint, this))
        insertionPoints.append(insertionPoint);

    m_descendantInsertionPoints.swap(insertionPoints);

    return m_descendantInsertionPoints;
}

}
