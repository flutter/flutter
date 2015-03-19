// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_PAINTINGCONTEXT_H_
#define SKY_ENGINE_CORE_PAINTING_PAINTINGCONTEXT_H_

#include "sky/engine/core/painting/Paint.h"
#include "sky/engine/platform/graphics/DisplayList.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {

class PaintingContext : public RefCounted<PaintingContext>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    ~PaintingContext() override;
    PassRefPtr<PaintingContext> create(const FloatRect& bounds) { return adoptRef(new PaintingContext(bounds)); }

    double height() const { return m_displayList->bounds().height(); }
    double width() const { return m_displayList->bounds().width(); }

    void drawCircle(double x, double y, double radius, Paint* paint);
    void commit();

private:
    PaintingContext(const FloatRect& bounds);

    RefPtr<DisplayList> m_displayList;
    SkCanvas* m_canvas;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_PAINTINGCONTEXT_H_
