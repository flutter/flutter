// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/inspector/InspectorNodeIds.h"

#include "sky/engine/core/dom/WeakNodeMap.h"
#include "sky/engine/platform/heap/Handle.h"

namespace blink {

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

}
