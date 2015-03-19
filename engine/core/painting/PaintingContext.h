// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_PAINTINGCONTEXT_H_
#define SKY_ENGINE_CORE_PAINTING_PAINTINGCONTEXT_H_

#include "base/callback.h"
#include "sky/engine/core/painting/Paint.h"
#include "sky/engine/platform/graphics/DisplayList.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {

class PaintingContext : public RefCounted<PaintingContext>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    typedef base::Callback<void (RefPtr<PaintingContext>)> CommitCallback;

    ~PaintingContext() override;
    static PassRefPtr<PaintingContext> create(const FloatSize& size, const CommitCallback& commitCallback)
    {
        return adoptRef(new PaintingContext(size, commitCallback));
    }

    double height() const { return m_size.height(); }
    double width() const { return m_size.width(); }

    void drawCircle(double x, double y, double radius, Paint* paint);
    void commit();

    PassRefPtr<DisplayList> takeDisplayList()
    {
        ASSERT(!m_canvas);
        return m_displayList.release();
    }

private:
    PaintingContext(const FloatSize& size, const CommitCallback& commitCallback);

    FloatSize m_size;
    CommitCallback m_commitCallback;
    RefPtr<DisplayList> m_displayList;
    SkCanvas* m_canvas;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_PAINTINGCONTEXT_H_
