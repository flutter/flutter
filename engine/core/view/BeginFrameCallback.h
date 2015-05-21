// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_VIEW_BEGINFRAMECALLBACK_H_
#define SKY_ENGINE_CORE_VIEW_BEGINFRAMECALLBACK_H_

namespace blink {

class BeginFrameCallback {
public:
    virtual ~BeginFrameCallback() { }
    virtual bool handleEvent(double highResTime) = 0;
};

}

#endif  // SKY_ENGINE_CORE_VIEW_BEGINFRAMECALLBACK_H_
