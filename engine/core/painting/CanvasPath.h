// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_PATH_H_
#define SKY_ENGINE_CORE_PAINTING_PATH_H_

#include "math.h"

#include "sky/engine/core/painting/Rect.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "third_party/skia/include/core/SkPath.h"

// Note: There's a very similar class in ../../platform/graphics/Path.h
// We should probably rationalise these two.
// (The existence of that class is why this is CanvasPath and not just Path.)

namespace blink {

class CanvasPath : public RefCounted<CanvasPath>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    ~CanvasPath() override;
    static PassRefPtr<CanvasPath> create()
    {
        return adoptRef(new CanvasPath);
    }

    void moveTo(float x, float y)
    {
        m_path.moveTo(x, y);
    }

    void lineTo(float x, float y)
    {
        m_path.lineTo(x, y);
    }

    void arcTo(const Rect& rect, float startAngle, float sweepAngle, bool forceMoveTo)
    {
        m_path.arcTo(rect.sk_rect, startAngle*180.0/M_PI, sweepAngle*180.0/M_PI, forceMoveTo);
    }

    void close()
    {
        m_path.close();
    }

    const SkPath& path() const { return m_path; }

private:
    CanvasPath();

    SkPath m_path;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_PATH_H_
