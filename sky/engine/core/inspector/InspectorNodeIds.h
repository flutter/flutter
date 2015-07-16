// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_INSPECTOR_INSPECTORNODEIDS_H_
#define SKY_ENGINE_CORE_INSPECTOR_INSPECTORNODEIDS_H_

namespace blink {

class Node;

class InspectorNodeIds {
public:
    static int idForNode(Node*);
    static Node* nodeForId(int);
};

} // namespace blink


#endif  // SKY_ENGINE_CORE_INSPECTOR_INSPECTORNODEIDS_H_
