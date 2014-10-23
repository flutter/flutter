// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FrameClient_h
#define FrameClient_h

namespace blink {

class Frame;

// FIXME(sky): remove
class FrameClient {
public:
    virtual ~FrameClient() { }
};

} // namespace blink

#endif // FrameClient_h
