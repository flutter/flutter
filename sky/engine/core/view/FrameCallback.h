// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_VIEW_FRAMECALLBACK_H_
#define SKY_ENGINE_CORE_VIEW_FRAMECALLBACK_H_

namespace blink {

class FrameCallback {
public:
    virtual ~FrameCallback() { }
    virtual bool handleEvent(double highResTime) = 0;
};

}

#endif  // SKY_ENGINE_CORE_VIEW_FRAMECALLBACK_H_
