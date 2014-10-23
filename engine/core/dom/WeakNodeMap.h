// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef WeakNodeMap_h
#define WeakNodeMap_h

#include "wtf/HashMap.h"

namespace blink {

// Oilpan supports weak maps, so we no longer need WeakNodeMap.
#if !ENABLE(OILPAN)
class Node;
class NodeToWeakNodeMaps;

class WeakNodeMap {
public:
    ~WeakNodeMap();

    void put(Node*, int value);
    int value(Node*);
    Node* node(int value);

private:
    // FIXME: This should not be friends with Node, we should expose a proper API and not
    // let the map directly set flags.
    friend class Node;
    static void notifyNodeDestroyed(Node*);

    friend class NodeToWeakNodeMaps;
    void nodeDestroyed(Node*);

    typedef HashMap<Node*, int> NodeToValue;
    NodeToValue m_nodeToValue;
    typedef HashMap<int, Node*> ValueToNode;
    ValueToNode m_valueToNode;
};
#endif

}

#endif
