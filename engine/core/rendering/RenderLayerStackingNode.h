/*
 * Copyright (C) 2003, 2009, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2013 Intel Corporation. All rights reserved.
 *
 * Portions are Copyright (C) 1998 Netscape Communications Corporation.
 *
 * Other contributors:
 *   Robert O'Callahan <roc+@cs.cmu.edu>
 *   David Baron <dbaron@fas.harvard.edu>
 *   Christian Biesinger <cbiesinger@web.de>
 *   Randall Jesup <rjesup@wgate.com>
 *   Roland Mainz <roland.mainz@informatik.med.uni-giessen.de>
 *   Josh Soref <timeless@mac.com>
 *   Boris Zbarsky <bzbarsky@mit.edu>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * Alternatively, the contents of this file may be used under the terms
 * of either the Mozilla Public License Version 1.1, found at
 * http://www.mozilla.org/MPL/ (the "MPL") or the GNU General Public
 * License Version 2.0, found at http://www.fsf.org/copyleft/gpl.html
 * (the "GPL"), in which case the provisions of the MPL or the GPL are
 * applicable instead of those above.  If you wish to allow use of your
 * version of this file only under the terms of one of those two
 * licenses (the MPL or the GPL) and not to allow others to use your
 * version of this file under the LGPL, indicate your decision by
 * deletingthe provisions above and replace them with the notice and
 * other provisions required by the MPL or the GPL, as the case may be.
 * If you do not delete the provisions above, a recipient may use your
 * version of this file under any of the LGPL, the MPL or the GPL.
 */

#ifndef RenderLayerStackingNode_h
#define RenderLayerStackingNode_h

#include "core/rendering/RenderLayerModelObject.h"
#include "wtf/Noncopyable.h"
#include "wtf/OwnPtr.h"
#include "wtf/Vector.h"

namespace blink {

class RenderLayer;
class RenderLayerCompositor;
class RenderStyle;

class RenderLayerStackingNode {
    WTF_MAKE_NONCOPYABLE(RenderLayerStackingNode);
public:
    explicit RenderLayerStackingNode(RenderLayer*);
    ~RenderLayerStackingNode();

    int zIndex() const { return renderer()->style()->zIndex(); }

    // A stacking context is a layer that has a non-auto z-index.
    bool isStackingContext() const { return !renderer()->style()->hasAutoZIndex(); }

    // Update our normal and z-index lists.
    void updateLayerListsIfNeeded();

    bool zOrderListsDirty() const { return m_zOrderListsDirty; }
    void dirtyZOrderLists();
    void updateZOrderLists();
    void clearZOrderLists();
    void dirtyStackingContextZOrderLists();

    bool hasPositiveZOrderList() const { return posZOrderList() && posZOrderList()->size(); }
    bool hasNegativeZOrderList() const { return negZOrderList() && negZOrderList()->size(); }

    // FIXME: should check for dirtiness here?
    bool isNormalFlowOnly() const { return m_isNormalFlowOnly; }
    void updateIsNormalFlowOnly();
    bool normalFlowListDirty() const { return m_normalFlowListDirty; }
    void dirtyNormalFlowList();

    void updateStackingNodesAfterStyleChange(const RenderStyle* oldStyle);

    RenderLayerStackingNode* ancestorStackingContextNode() const;

    // Gets the enclosing stacking context for this node, possibly the node
    // itself, if it is a stacking context.
    RenderLayerStackingNode* enclosingStackingContextNode() { return isStackingContext() ? this : ancestorStackingContextNode(); }

    RenderLayer* layer() const { return m_layer; }

#if ENABLE(ASSERT)
    bool layerListMutationAllowed() const { return m_layerListMutationAllowed; }
    void setLayerListMutationAllowed(bool flag) { m_layerListMutationAllowed = flag; }
#endif

private:
    friend class RenderLayerStackingNodeIterator;
    friend class RenderLayerStackingNodeReverseIterator;
    friend class RenderTreeAsText;

    Vector<RenderLayerStackingNode*>* posZOrderList() const
    {
        ASSERT(!m_zOrderListsDirty);
        ASSERT(isStackingContext() || !m_posZOrderList);
        return m_posZOrderList.get();
    }

    Vector<RenderLayerStackingNode*>* normalFlowList() const
    {
        ASSERT(!m_normalFlowListDirty);
        return m_normalFlowList.get();
    }

    Vector<RenderLayerStackingNode*>* negZOrderList() const
    {
        ASSERT(!m_zOrderListsDirty);
        ASSERT(isStackingContext() || !m_negZOrderList);
        return m_negZOrderList.get();
    }

    void rebuildZOrderLists();
    void collectLayers(OwnPtr<Vector<RenderLayerStackingNode*> >& posZOrderList, OwnPtr<Vector<RenderLayerStackingNode*> >& negZOrderList);

#if ENABLE(ASSERT)
    bool isInStackingParentZOrderLists() const;
    bool isInStackingParentNormalFlowList() const;
    void updateStackingParentForZOrderLists(RenderLayerStackingNode* stackingParent);
    void updateStackingParentForNormalFlowList(RenderLayerStackingNode* stackingParent);
    void setStackingParent(RenderLayerStackingNode* stackingParent) { m_stackingParent = stackingParent; }
#endif

    bool shouldBeNormalFlowOnly() const;

    void updateNormalFlowList();

    bool isDirtyStackingContext() const { return m_zOrderListsDirty && isStackingContext(); }

    RenderLayerCompositor* compositor() const;
    // FIXME: Investigate changing this to Renderbox.
    RenderLayerModelObject* renderer() const;

    RenderLayer* m_layer;

    // m_posZOrderList holds a sorted list of all the descendant nodes within
    // that have z-indices of 0 or greater (auto will count as 0).
    // m_negZOrderList holds descendants within our stacking context with
    // negative z-indices.
    OwnPtr<Vector<RenderLayerStackingNode*> > m_posZOrderList;
    OwnPtr<Vector<RenderLayerStackingNode*> > m_negZOrderList;

    // This list contains child nodes that cannot create stacking contexts.
    OwnPtr<Vector<RenderLayerStackingNode*> > m_normalFlowList;

    unsigned m_zOrderListsDirty : 1;
    unsigned m_normalFlowListDirty: 1;
    unsigned m_isNormalFlowOnly : 1;

#if ENABLE(ASSERT)
    unsigned m_layerListMutationAllowed : 1;
    RenderLayerStackingNode* m_stackingParent;
#endif
};

inline void RenderLayerStackingNode::clearZOrderLists()
{
    ASSERT(!isStackingContext());

#if ENABLE(ASSERT)
    updateStackingParentForZOrderLists(0);
#endif

    m_posZOrderList.clear();
    m_negZOrderList.clear();
}

inline void RenderLayerStackingNode::updateZOrderLists()
{
    if (!m_zOrderListsDirty)
        return;

    if (!isStackingContext()) {
        clearZOrderLists();
        m_zOrderListsDirty = false;
        return;
    }

    rebuildZOrderLists();
}

#if ENABLE(ASSERT)
class LayerListMutationDetector {
public:
    explicit LayerListMutationDetector(RenderLayerStackingNode* stackingNode)
        : m_stackingNode(stackingNode)
        , m_previousMutationAllowedState(stackingNode->layerListMutationAllowed())
    {
        m_stackingNode->setLayerListMutationAllowed(false);
    }

    ~LayerListMutationDetector()
    {
        m_stackingNode->setLayerListMutationAllowed(m_previousMutationAllowedState);
    }

private:
    RenderLayerStackingNode* m_stackingNode;
    bool m_previousMutationAllowedState;
};
#endif

} // namespace blink

#endif // RenderLayerStackingNode_h
