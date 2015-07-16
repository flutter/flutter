// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_LAYOUTCALLBACK_H_
#define SKY_ENGINE_CORE_PAINTING_LAYOUTCALLBACK_H_

namespace blink {

class LayoutCallback {
public:
    virtual ~LayoutCallback() {}
    virtual void handleEvent() = 0;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_LAYOUTCALLBACK_H_
