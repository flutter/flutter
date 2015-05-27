// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_PAINT_H_
#define SKY_ENGINE_CORE_PAINTING_PAINT_H_

#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "third_party/skia/include/core/SkPaint.h"

namespace blink {

class DrawLooper;

class Paint : public RefCounted<Paint>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    ~Paint() override;
    static PassRefPtr<Paint> create()
    {
        return adoptRef(new Paint);
    }

    bool isAntiAlias() const { return m_paint.isAntiAlias(); }
    void setIsAntiAlias(bool value) { m_paint.setAntiAlias(value); }

    unsigned color() const { return m_paint.getColor(); }
    void setColor(unsigned color) { m_paint.setColor(color); }

    void setARGB(unsigned a, unsigned r, unsigned g, unsigned b)
    {
        m_paint.setARGB(a, r, g, b);
    }
    void setDrawLooper(DrawLooper* looper);

    const SkPaint& paint() const { return m_paint; }
    void setPaint(const SkPaint& paint) { m_paint = paint; }

private:
    Paint();

    SkPaint m_paint;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_PAINT_H_
