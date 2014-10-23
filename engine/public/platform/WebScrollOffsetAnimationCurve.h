// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef WebScrollOffsetAnimationCurve_h
#define WebScrollOffsetAnimationCurve_h

#include "WebCompositorAnimationCurve.h"
#include "WebFloatPoint.h"

namespace blink {

class WebScrollOffsetAnimationCurve : public WebCompositorAnimationCurve {
public:
    virtual ~WebScrollOffsetAnimationCurve() { }

    virtual void setInitialValue(WebFloatPoint) = 0;
    virtual WebFloatPoint getValue(double time) const = 0;
    virtual double duration() const = 0;
};

} // namespace blink

#endif // WebScrollOffsetAnimationCurve_h
