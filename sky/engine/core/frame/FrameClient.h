// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_FRAME_FRAMECLIENT_H_
#define SKY_ENGINE_CORE_FRAME_FRAMECLIENT_H_

namespace blink {

class Frame;

// FIXME(sky): remove
class FrameClient {
public:
    virtual ~FrameClient() { }
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_FRAME_FRAMECLIENT_H_
