// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_CANVAS_H_
#define SKY_ENGINE_CORE_PAINTING_CANVAS_H_

#include "sky/engine/core/painting/Paint.h"
#include "sky/engine/platform/graphics/DisplayList.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {
class Element;

class Canvas : public RefCounted<Canvas>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    Canvas(const FloatSize& size);
    ~Canvas() override;

    // Width/Height define a culling rect which Skia may use for optimizing
    // out draw calls issued outside the rect.
    double width() const { return m_size.width(); }
    double height() const { return m_size.height(); }

    void drawCircle(double x, double y, double radius, Paint* paint);

protected:
    PassRefPtr<DisplayList> finishRecording();

    bool isRecording() const { return m_canvas; }

private:
    FloatSize m_size;
    RefPtr<DisplayList> m_displayList;
    SkCanvas* m_canvas;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_CANVAS_H_
