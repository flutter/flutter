// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_PAINTINGTASKS_H_
#define SKY_ENGINE_CORE_PAINTING_PAINTINGTASKS_H_

#include "sky/engine/wtf/PassOwnPtr.h"
#include "sky/engine/wtf/PassRefPtr.h"

namespace blink {
class DisplayList;
class Element;
class Node;
class PaintingCallback;

class PaintingTasks {
public:
    static void enqueueRequest(PassRefPtr<Element>, PassOwnPtr<PaintingCallback>);
    static void enqueueCommit(PassRefPtr<Node>, PassRefPtr<DisplayList>);

    static bool serviceRequests();
    static void drainCommits();

private:
    PaintingTasks() = delete;
    ~PaintingTasks() = delete;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_PAINTINGTASKS_H_
