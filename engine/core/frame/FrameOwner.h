// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_FRAME_FRAMEOWNER_H_
#define SKY_ENGINE_CORE_FRAME_FRAMEOWNER_H_

namespace blink {

class FrameOwner {
public:
    virtual ~FrameOwner() { }

    virtual bool isLocal() const = 0;

    virtual void dispatchLoad() = 0;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_FRAME_FRAMEOWNER_H_
