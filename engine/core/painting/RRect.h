// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_RRECT_H_
#define SKY_ENGINE_CORE_PAINTING_RRECT_H_

#include "sky/engine/core/painting/Rect.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "third_party/skia/include/core/SkRRect.h"

namespace blink {

class RRect : public RefCounted<RRect>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    ~RRect() override;
    static PassRefPtr<RRect> create()
    {
        return adoptRef(new RRect);
    }

    void setRectXY(const Rect& rect, float xRad, float yRad);

    const SkRRect& rrect() const { return m_rrect; }
    void setRRect(const SkRRect& rrect) { m_rrect = rrect; }

private:
    RRect();

    SkRRect m_rrect;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_RRECT_H_
