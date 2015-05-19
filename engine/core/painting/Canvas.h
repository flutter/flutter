// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_CANVAS_H_
#define SKY_ENGINE_CORE_PAINTING_CANVAS_H_

#include "sky/engine/core/painting/Paint.h"
#include "sky/engine/core/painting/Picture.h"
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
    float width() const { return m_size.width(); }
    float height() const { return m_size.height(); }

    void save();
    void saveLayer(const Vector<float>& bounds, const Paint* paint);
    void restore();

    void translate(float dx, float dy);
    void scale(float sx, float sy);
    void rotateDegrees(float degrees);
    void skew(float sx, float sy);
    void concat(const Vector<float>& matrix);

    void clipRect(const Vector<float>& rect);

    void drawPicture(Picture* picture);
    void drawPaint(const Paint* paint);
    void drawRect(const Vector<float>& rect, const Paint* paint);
    void drawOval(const Vector<float>& rect, const Paint* paint);
    void drawCircle(float x, float y, float radius, const Paint* paint);

    SkCanvas* skCanvas() { return m_canvas; }

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
