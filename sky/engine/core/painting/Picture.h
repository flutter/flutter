// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_PICTURE_H_
#define SKY_ENGINE_CORE_PAINTING_PICTURE_H_

#include "base/memory/ref_counted.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "third_party/skia/include/core/SkPicture.h"

namespace blink {
class Canvas;
class DartLibraryNatives;

class Picture : public base::RefCountedThreadSafe<Picture>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    ~Picture() override;
    static scoped_refptr<Picture> create(sk_sp<SkPicture> skPicture);

    sk_sp<SkPicture> toSkia() const { return m_picture; }

    void dispose();

    static void RegisterNatives(DartLibraryNatives* natives);

private:
    explicit Picture(sk_sp<SkPicture> skPicture);

    sk_sp<SkPicture> m_picture;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_PICTURE_H_
