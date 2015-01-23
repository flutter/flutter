// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_FRAME_NEWEVENTHANDLER_H_
#define SKY_ENGINE_CORE_FRAME_NEWEVENTHANDLER_H_

#include <map>
#include "sky/engine/core/dom/Node.h"
#include "sky/engine/core/rendering/HitTestRequest.h"
#include "sky/engine/core/rendering/HitTestResult.h"
#include "sky/engine/wtf/HashMap.h"

namespace blink {

class LocalFrame;
class WebPointerEvent;

class NewEventHandler {
    WTF_MAKE_NONCOPYABLE(NewEventHandler);
public:
    explicit NewEventHandler(LocalFrame&);
    ~NewEventHandler();

    bool handlePointerEvent(const WebPointerEvent&);

private:
    bool handlePointerDownEvent(const WebPointerEvent&);
    bool handlePointerUpEvent(const WebPointerEvent&);
    bool handlePointerMoveEvent(const WebPointerEvent&);
    bool handlePointerCancelEvent(const WebPointerEvent&);

    bool dispatchPointerEvent(Node& target, const WebPointerEvent&);
    bool dispatchClickEvent(Node& capturingTarget, const WebPointerEvent&);

    Node* targetForHitTestResult(const HitTestResult& hitTestResult);
    HitTestResult performHitTest(const LayoutPoint&);
    void updateSelectionForPointerDown(const HitTestResult&, const WebPointerEvent&);

    typedef std::map<int, RefPtr<Node>> PointerTargetMap;

    LocalFrame& m_frame;
    PointerTargetMap m_targetForPointer;
};

}

#endif // SKY_ENGINE_CORE_FRAME_NEWEVENTHANDLER_H_
