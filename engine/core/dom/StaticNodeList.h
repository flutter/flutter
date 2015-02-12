/*
 * Copyright (C) 2007, 2008 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 3.  Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_CORE_DOM_STATICNODELIST_H_
#define SKY_ENGINE_CORE_DOM_STATICNODELIST_H_

#include "sky/engine/core/dom/NodeList.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefPtr.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {

class Element;
class Node;

template <typename NodeType>
class StaticNodeTypeList final : public NodeList {
public:
    static PassRefPtr<StaticNodeTypeList> adopt(Vector<RefPtr<NodeType> >& nodes);

    static PassRefPtr<StaticNodeTypeList> createEmpty()
    {
        return adoptRef(new StaticNodeTypeList);
    }

    virtual ~StaticNodeTypeList();

    virtual unsigned length() const override;
    virtual NodeType* item(unsigned index) const override;

private:
    ptrdiff_t AllocationSize()
    {
        return m_nodes.capacity() * sizeof(RefPtr<NodeType>);
    }

    Vector<RefPtr<NodeType> > m_nodes;
};

typedef StaticNodeTypeList<Node> StaticNodeList;
typedef StaticNodeTypeList<Element> StaticElementList;

template <typename NodeType>
PassRefPtr<StaticNodeTypeList<NodeType> > StaticNodeTypeList<NodeType>::adopt(Vector<RefPtr<NodeType> >& nodes)
{
    RefPtr<StaticNodeTypeList<NodeType> > nodeList = adoptRef(new StaticNodeTypeList<NodeType>);
    nodeList->m_nodes.swap(nodes);
    return nodeList.release();
}

template <typename NodeType>
StaticNodeTypeList<NodeType>::~StaticNodeTypeList()
{
}

template <typename NodeType>
unsigned StaticNodeTypeList<NodeType>::length() const
{
    return m_nodes.size();
}

template <typename NodeType>
NodeType* StaticNodeTypeList<NodeType>::item(unsigned index) const
{
    if (index < m_nodes.size())
        return m_nodes[index].get();
    return 0;
}

} // namespace blink

#endif  // SKY_ENGINE_CORE_DOM_STATICNODELIST_H_
