// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/inspector/InspectorNodeIds.h"

#if ENABLE(OILPAN)
#include "core/dom/Node.h"
#else
#include "core/dom/WeakNodeMap.h"
#endif
#include "platform/heap/Handle.h"

namespace blink {

#if ENABLE(OILPAN)
typedef HeapHashMap<WeakMember<Node>, int> NodeToIdMap;
typedef HeapHashMap<int, WeakMember<Node> > IdToNodeMap;

static NodeToIdMap& nodeToIdMap()
{
    DEFINE_STATIC_LOCAL(Persistent<NodeToIdMap>, nodeToIdMap, (new NodeToIdMap()));
    return *nodeToIdMap;
}

static IdToNodeMap& idToNodeMap()
{
    DEFINE_STATIC_LOCAL(Persistent<IdToNodeMap>, idToNodeMap, (new IdToNodeMap()));
    return *idToNodeMap;
}

int InspectorNodeIds::idForNode(Node* node)
{
    static int s_nextNodeId = 1;
    NodeToIdMap::iterator it = nodeToIdMap().find(node);
    if (it != nodeToIdMap().end())
        return it->value;
    int id = s_nextNodeId++;
    nodeToIdMap().set(node, id);
    ASSERT(idToNodeMap().find(id) == idToNodeMap().end());
    idToNodeMap().set(id, node);
    return id;
}

Node* InspectorNodeIds::nodeForId(int id)
{
    return idToNodeMap().get(id);
}
#else
static WeakNodeMap& nodeIds()
{
    DEFINE_STATIC_LOCAL(WeakNodeMap, self, ());
    return self;
}

int InspectorNodeIds::idForNode(Node* node)
{
    static int s_nextNodeId = 1;
    WeakNodeMap& ids = nodeIds();
    int result = ids.value(node);
    if (!result) {
        result = s_nextNodeId++;
        ids.put(node, result);
    }
    return result;
}

Node* InspectorNodeIds::nodeForId(int id)
{
    return nodeIds().node(id);
}
#endif

}
