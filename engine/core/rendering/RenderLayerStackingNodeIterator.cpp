/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#include "config.h"
#include "core/rendering/RenderLayerStackingNodeIterator.h"

#include "core/rendering/RenderLayer.h"
#include "core/rendering/RenderLayerStackingNode.h"

namespace blink {

RenderLayerStackingNode* RenderLayerStackingNodeIterator::next()
{
    if (m_remainingChildren & NegativeZOrderChildren) {
        Vector<RenderLayerStackingNode*>* negZOrderList = m_root.negZOrderList();
        if (negZOrderList && m_index < negZOrderList->size())
            return negZOrderList->at(m_index++);

        m_index = 0;
        m_remainingChildren &= ~NegativeZOrderChildren;
    }

    if (m_remainingChildren & NormalFlowChildren) {
        Vector<RenderLayerStackingNode*>* normalFlowList = m_root.normalFlowList();
        if (normalFlowList && m_index < normalFlowList->size())
            return normalFlowList->at(m_index++);

        m_index = 0;
        m_remainingChildren &= ~NormalFlowChildren;
    }

    if (m_remainingChildren & PositiveZOrderChildren) {
        Vector<RenderLayerStackingNode*>* posZOrderList = m_root.posZOrderList();
        if (posZOrderList && m_index < posZOrderList->size())
            return posZOrderList->at(m_index++);

        m_index = 0;
        m_remainingChildren &= ~PositiveZOrderChildren;
    }

    return 0;
}

RenderLayerStackingNode* RenderLayerStackingNodeReverseIterator::next()
{
    if (m_remainingChildren & NegativeZOrderChildren) {
        Vector<RenderLayerStackingNode*>* negZOrderList = m_root.negZOrderList();
        if (negZOrderList && m_index >= 0)
            return negZOrderList->at(m_index--);

        m_remainingChildren &= ~NegativeZOrderChildren;
        setIndexToLastItem();
    }

    if (m_remainingChildren & NormalFlowChildren) {
        Vector<RenderLayerStackingNode*>* normalFlowList = m_root.normalFlowList();
        if (normalFlowList && m_index >= 0)
            return normalFlowList->at(m_index--);

        m_remainingChildren &= ~NormalFlowChildren;
        setIndexToLastItem();
    }

    if (m_remainingChildren & PositiveZOrderChildren) {
        Vector<RenderLayerStackingNode*>* posZOrderList = m_root.posZOrderList();
        if (posZOrderList && m_index >= 0)
            return posZOrderList->at(m_index--);

        m_remainingChildren &= ~PositiveZOrderChildren;
        setIndexToLastItem();
    }

    return 0;
}

void RenderLayerStackingNodeReverseIterator::setIndexToLastItem()
{
    if (m_remainingChildren & NegativeZOrderChildren) {
        Vector<RenderLayerStackingNode*>* negZOrderList = m_root.negZOrderList();
        if (negZOrderList) {
            m_index  = negZOrderList->size() - 1;
            return;
        }

        m_remainingChildren &= ~NegativeZOrderChildren;
    }

    if (m_remainingChildren & NormalFlowChildren) {
        Vector<RenderLayerStackingNode*>* normalFlowList = m_root.normalFlowList();
        if (normalFlowList) {
            m_index = normalFlowList->size() - 1;
            return;
        }

        m_remainingChildren &= ~NormalFlowChildren;
    }

    if (m_remainingChildren & PositiveZOrderChildren) {
        Vector<RenderLayerStackingNode*>* posZOrderList = m_root.posZOrderList();
        if (posZOrderList) {
            m_index = posZOrderList->size() - 1;
            return;
        }

        m_remainingChildren &= ~PositiveZOrderChildren;
    }

    // No more list to visit.
    ASSERT(!m_remainingChildren);
    m_index = -1;
}

} // namespace blink
