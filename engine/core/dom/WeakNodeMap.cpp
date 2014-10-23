// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/dom/WeakNodeMap.h"

#include "core/dom/Node.h"

namespace blink {

#if !ENABLE(OILPAN)
class NodeToWeakNodeMaps {
public:
    bool addedToMap(Node*, WeakNodeMap*);
    bool removedFromMap(Node*, WeakNodeMap*);
    void nodeDestroyed(Node*);

    static NodeToWeakNodeMaps& instance()
    {
        DEFINE_STATIC_LOCAL(NodeToWeakNodeMaps, self, ());
        return self;
    }

private:
    typedef Vector<WeakNodeMap*, 1> MapList;
    typedef HashMap<Node*, OwnPtr<MapList> > NodeToMapList;
    NodeToMapList m_nodeToMapList;
};

bool NodeToWeakNodeMaps::addedToMap(Node* node, WeakNodeMap* map)
{
    NodeToMapList::AddResult result = m_nodeToMapList.add(node, nullptr);
    if (result.isNewEntry)
        result.storedValue->value = adoptPtr(new MapList());
    result.storedValue->value->append(map);
    return result.isNewEntry;
}

bool NodeToWeakNodeMaps::removedFromMap(Node* node, WeakNodeMap* map)
{
    NodeToMapList::iterator it = m_nodeToMapList.find(node);
    ASSERT(it != m_nodeToMapList.end());
    MapList* mapList = it->value.get();
    size_t position = mapList->find(map);
    ASSERT(position != kNotFound);
    mapList->remove(position);
    if (mapList->size() == 0) {
        m_nodeToMapList.remove(it);
        return true;
    }
    return false;
}

void NodeToWeakNodeMaps::nodeDestroyed(Node* node)
{
    OwnPtr<NodeToWeakNodeMaps::MapList> maps = m_nodeToMapList.take(node);
    for (size_t i = 0; i < maps->size(); i++)
        (*maps)[i]->nodeDestroyed(node);
}

WeakNodeMap::~WeakNodeMap()
{
    NodeToWeakNodeMaps& allMaps = NodeToWeakNodeMaps::instance();
    for (NodeToValue::iterator it = m_nodeToValue.begin(); it != m_nodeToValue.end(); ++it) {
        Node* node = it->key;
        if (allMaps.removedFromMap(node, this))
            node->clearFlag(Node::HasWeakReferencesFlag);
    }
}

void WeakNodeMap::put(Node* node, int value)
{
    ASSERT(node && !m_nodeToValue.contains(node));
    m_nodeToValue.set(node, value);
    m_valueToNode.set(value, node);

    NodeToWeakNodeMaps& maps = NodeToWeakNodeMaps::instance();
    if (maps.addedToMap(node, this))
        node->setFlag(Node::HasWeakReferencesFlag);
}

int WeakNodeMap::value(Node* node)
{
    return m_nodeToValue.get(node);
}

Node* WeakNodeMap::node(int value)
{
    return m_valueToNode.get(value);
}

void WeakNodeMap::nodeDestroyed(Node* node)
{
    int value = m_nodeToValue.take(node);
    ASSERT(value);
    m_valueToNode.remove(value);
}

void WeakNodeMap::notifyNodeDestroyed(Node* node)
{
    NodeToWeakNodeMaps::instance().nodeDestroyed(node);
}
#endif

}
