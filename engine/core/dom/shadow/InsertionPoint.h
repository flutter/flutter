/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#ifndef InsertionPoint_h
#define InsertionPoint_h

#include "core/css/CSSSelectorList.h"
#include "core/dom/shadow/ContentDistribution.h"
#include "core/dom/shadow/ShadowRoot.h"
#include "core/html/HTMLElement.h"

namespace blink {

class InsertionPoint : public HTMLElement {
public:
    virtual ~InsertionPoint();

    bool hasDistribution() const { return !m_distribution.isEmpty(); }
    void setDistribution(ContentDistribution&);
    void clearDistribution() { m_distribution.clear(); }
    bool isActive() const;
    bool canBeActive() const;

    bool isShadowInsertionPoint() const;
    bool isContentInsertionPoint() const;

    PassRefPtrWillBeRawPtr<StaticNodeList> getDistributedNodes();

    virtual bool canAffectSelector() const { return false; }

    virtual void attach(const AttachContext& = AttachContext()) OVERRIDE;
    virtual void detach(const AttachContext& = AttachContext()) OVERRIDE;

    bool shouldUseFallbackElements() const;

    size_t size() const { return m_distribution.size(); }
    Node* at(size_t index)  const { return m_distribution.at(index).get(); }
    Node* first() const { return m_distribution.isEmpty() ? 0 : m_distribution.first().get(); }
    Node* last() const { return m_distribution.isEmpty() ? 0 : m_distribution.last().get(); }
    Node* nextTo(const Node* node) const { return m_distribution.nextTo(node); }
    Node* previousTo(const Node* node) const { return m_distribution.previousTo(node); }

    virtual void trace(Visitor*) OVERRIDE;

protected:
    InsertionPoint(const QualifiedName&, Document&);
    virtual bool rendererIsNeeded(const RenderStyle&) OVERRIDE;
    virtual void childrenChanged(const ChildrenChange&) OVERRIDE;
    virtual InsertionNotificationRequest insertedInto(ContainerNode*) OVERRIDE;
    virtual void removedFrom(ContainerNode*) OVERRIDE;
    virtual void willRecalcStyle(StyleRecalcChange) OVERRIDE;

private:
    bool isInsertionPoint() const WTF_DELETED_FUNCTION; // This will catch anyone doing an unnecessary check.

    ContentDistribution m_distribution;
    bool m_registeredWithShadowRoot;
};

typedef WillBeHeapVector<RefPtrWillBeMember<InsertionPoint> > DestinationInsertionPoints;

DEFINE_ELEMENT_TYPE_CASTS(InsertionPoint, isInsertionPoint());

inline bool isActiveInsertionPoint(const Node& node)
{
    return node.isInsertionPoint() && toInsertionPoint(node).isActive();
}

inline bool isActiveShadowInsertionPoint(const Node& node)
{
    return node.isInsertionPoint() && toInsertionPoint(node).isShadowInsertionPoint();
}

inline ElementShadow* shadowWhereNodeCanBeDistributed(const Node& node)
{
    Node* parent = node.parentNode();
    if (!parent)
        return 0;
    if (parent->isShadowRoot() && !toShadowRoot(parent)->isYoungest())
        return node.shadowHost()->shadow();
    if (isActiveInsertionPoint(*parent))
        return node.shadowHost()->shadow();
    if (parent->isElementNode())
        return toElement(parent)->shadow();
    return 0;
}

const InsertionPoint* resolveReprojection(const Node*);

void collectDestinationInsertionPoints(const Node&, WillBeHeapVector<RawPtrWillBeMember<InsertionPoint>, 8>& results);

} // namespace blink

#endif // InsertionPoint_h
