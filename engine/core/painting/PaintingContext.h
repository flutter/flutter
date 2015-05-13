// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_PAINTINGCONTEXT_H_
#define SKY_ENGINE_CORE_PAINTING_PAINTINGCONTEXT_H_

#include "sky/engine/core/painting/Canvas.h"
#include "sky/engine/wtf/Vector.h"

namespace blink {
class Element;

class PaintingContext : public Canvas {
    DEFINE_WRAPPERTYPEINFO();
public:
    ~PaintingContext() override;
    static PassRefPtr<PaintingContext> create(PassRefPtr<Element> element, const FloatSize& size);

    void commit();

private:
    PaintingContext(PassRefPtr<Element> element, const FloatSize& size);

    RefPtr<Element> m_element;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_PAINTINGCONTEXT_H_
