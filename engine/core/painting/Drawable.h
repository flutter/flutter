// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_DRAWABLE_H_
#define SKY_ENGINE_CORE_PAINTING_DRAWABLE_H_

#include "sky/engine/core/painting/Picture.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "third_party/skia/include/core/SkDrawable.h"

namespace blink {

class Drawable : public RefCounted<Drawable>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<Drawable> create(PassRefPtr<SkDrawable> skDrawable);
    ~Drawable() override;

    PassRefPtr<Picture> newPictureSnapshot();
    SkDrawable* toSkia() const { return m_drawable.get(); }

private:
    explicit Drawable(PassRefPtr<SkDrawable> skDrawable);
    RefPtr<SkDrawable> m_drawable;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_DRAWABLE_H_
