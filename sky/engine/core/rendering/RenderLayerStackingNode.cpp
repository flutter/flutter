/*
 * Copyright (C) 2006, 2007, 2008, 2009, 2010, 2011, 2012 Apple Inc.
 * All rights reserved.
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA
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

#include "flutter/sky/engine/core/rendering/RenderLayerStackingNode.h"

#include "flutter/sky/engine/core/rendering/RenderLayer.h"
#include "flutter/sky/engine/core/rendering/RenderView.h"
#include "flutter/sky/engine/public/platform/Platform.h"

namespace blink {

// FIXME: This should not require RenderLayer. There is currently a cycle where
// in order to determine if we shoulBeNormalFlowOnly() we have to ask the render
// layer about some of its state.
RenderLayerStackingNode::RenderLayerStackingNode(RenderLayer* layer)
    : m_layer(layer),
      m_normalFlowListDirty(true)
#if ENABLE(ASSERT)
      ,
      m_layerListMutationAllowed(true),
      m_stackingParent(0)
#endif
{
  m_isNormalFlowOnly = shouldBeNormalFlowOnly();

  // Non-stacking contexts should have empty z-order lists. As this is already
  // the case, there is no need to dirty / recompute these lists.
  m_zOrderListsDirty = isStackingContext();
}

RenderLayerStackingNode::~RenderLayerStackingNode() {
#if ENABLE(ASSERT)
  if (!renderer()->documentBeingDestroyed()) {
    ASSERT(!isInStackingParentZOrderLists());
    ASSERT(!isInStackingParentNormalFlowList());

    updateStackingParentForZOrderLists(0);
    updateStackingParentForNormalFlowList(0);
  }
#endif
}

// Helper for the sorting of layers by z-index.
static inline bool compareZIndex(RenderLayerStackingNode* first,
                                 RenderLayerStackingNode* second) {
  return first->zIndex() < second->zIndex();
}

void RenderLayerStackingNode::dirtyZOrderLists() {
  ASSERT(m_layerListMutationAllowed);
  ASSERT(isStackingContext());

#if ENABLE(ASSERT)
  updateStackingParentForZOrderLists(0);
#endif

  if (m_zOrderList)
    m_zOrderList->clear();
  m_zOrderListsDirty = true;
}

void RenderLayerStackingNode::dirtyStackingContextZOrderLists() {
  if (RenderLayerStackingNode* stackingNode = ancestorStackingContextNode())
    stackingNode->dirtyZOrderLists();
}

void RenderLayerStackingNode::dirtyNormalFlowList() {
  ASSERT(m_layerListMutationAllowed);

#if ENABLE(ASSERT)
  updateStackingParentForNormalFlowList(0);
#endif

  if (m_normalFlowList)
    m_normalFlowList->clear();
  m_normalFlowListDirty = true;
}

void RenderLayerStackingNode::rebuildZOrderLists() {
  ASSERT(m_layerListMutationAllowed);
  ASSERT(isDirtyStackingContext());

  for (RenderLayer* child = layer()->firstChild(); child;
       child = child->nextSibling())
    child->stackingNode()->collectLayers(m_zOrderList);

  if (m_zOrderList)
    std::stable_sort(m_zOrderList->begin(), m_zOrderList->end(), compareZIndex);

#if ENABLE(ASSERT)
  updateStackingParentForZOrderLists(this);
#endif

  m_zOrderListsDirty = false;
}

void RenderLayerStackingNode::updateNormalFlowList() {
  if (!m_normalFlowListDirty)
    return;

  ASSERT(m_layerListMutationAllowed);

  for (RenderLayer* child = layer()->firstChild(); child;
       child = child->nextSibling()) {
    if (child->stackingNode()->isNormalFlowOnly()) {
      if (!m_normalFlowList)
        m_normalFlowList = adoptPtr(new Vector<RenderLayerStackingNode*>);
      m_normalFlowList->append(child->stackingNode());
    }
  }

#if ENABLE(ASSERT)
  updateStackingParentForNormalFlowList(this);
#endif

  m_normalFlowListDirty = false;
}

void RenderLayerStackingNode::collectLayers(
    OwnPtr<Vector<RenderLayerStackingNode*>>& buffer) {
  if (!isNormalFlowOnly()) {
    if (!buffer)
      buffer = adoptPtr(new Vector<RenderLayerStackingNode*>);
    buffer->append(this);
  }

  if (!isStackingContext()) {
    for (RenderLayer* child = layer()->firstChild(); child;
         child = child->nextSibling())
      child->stackingNode()->collectLayers(buffer);
  }
}

#if ENABLE(ASSERT)
bool RenderLayerStackingNode::isInStackingParentZOrderLists() const {
  if (!m_stackingParent || m_stackingParent->zOrderListsDirty())
    return false;

  if (m_stackingParent->zOrderList() &&
      m_stackingParent->zOrderList()->find(this) != kNotFound)
    return true;

  return false;
}

bool RenderLayerStackingNode::isInStackingParentNormalFlowList() const {
  if (!m_stackingParent || m_stackingParent->normalFlowListDirty())
    return false;

  return (m_stackingParent->normalFlowList() &&
          m_stackingParent->normalFlowList()->find(this) != kNotFound);
}

void RenderLayerStackingNode::updateStackingParentForZOrderLists(
    RenderLayerStackingNode* stackingParent) {
  if (m_zOrderList) {
    for (size_t i = 0; i < m_zOrderList->size(); ++i)
      m_zOrderList->at(i)->setStackingParent(stackingParent);
  }
}

void RenderLayerStackingNode::updateStackingParentForNormalFlowList(
    RenderLayerStackingNode* stackingParent) {
  if (m_normalFlowList) {
    for (size_t i = 0; i < m_normalFlowList->size(); ++i)
      m_normalFlowList->at(i)->setStackingParent(stackingParent);
  }
}
#endif

void RenderLayerStackingNode::updateLayerListsIfNeeded() {
  updateZOrderLists();
  updateNormalFlowList();
}

void RenderLayerStackingNode::updateStackingNodesAfterStyleChange(
    const RenderStyle* oldStyle) {
  bool wasStackingContext = oldStyle ? !oldStyle->hasAutoZIndex() : false;
  unsigned oldZIndex = oldStyle ? oldStyle->zIndex() : 0;

  bool isStackingContext = this->isStackingContext();
  if (isStackingContext == wasStackingContext && oldZIndex == zIndex())
    return;

  dirtyStackingContextZOrderLists();

  if (isStackingContext)
    dirtyZOrderLists();
  else
    clearZOrderLists();
}

// FIXME: Rename shouldBeNormalFlowOnly to something more accurate now that CSS
// 2.1 defines the term "normal flow".
bool RenderLayerStackingNode::shouldBeNormalFlowOnly() const {
  return !isStackingContext() && !renderer()->isPositioned();
}

void RenderLayerStackingNode::updateIsNormalFlowOnly() {
  bool isNormalFlowOnly = shouldBeNormalFlowOnly();
  if (isNormalFlowOnly == this->isNormalFlowOnly())
    return;

  m_isNormalFlowOnly = isNormalFlowOnly;
  if (RenderLayer* p = layer()->parent())
    p->stackingNode()->dirtyNormalFlowList();
  dirtyStackingContextZOrderLists();
}

RenderLayerStackingNode* RenderLayerStackingNode::ancestorStackingContextNode()
    const {
  for (RenderLayer* ancestor = layer()->parent(); ancestor;
       ancestor = ancestor->parent()) {
    RenderLayerStackingNode* stackingNode = ancestor->stackingNode();
    if (stackingNode->isStackingContext())
      return stackingNode;
  }
  return 0;
}

RenderBox* RenderLayerStackingNode::renderer() const {
  return m_layer->renderer();
}

}  // namespace blink
