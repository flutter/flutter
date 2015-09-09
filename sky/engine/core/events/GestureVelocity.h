// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_EVENTS_GESTURE_VELOCITY_H_
#define SKY_ENGINE_CORE_EVENTS_GESTURE_VELOCITY_H_

#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {

class GestureVelocity final : public RefCounted<GestureVelocity>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<GestureVelocity> create(bool valid, float x, float y)
    {
        return adoptRef(new GestureVelocity(valid, x, y));
    }

    bool isValid() const { return m_is_valid; }
    float x() const { return m_x; }
    float y() const { return m_y; }

private:
    GestureVelocity(bool valid, float x, float y);

    bool m_is_valid;
    float m_x;
    float m_y;
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_EVENTS_GESTURE_VELOCITY_H_
