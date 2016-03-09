// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_PICTURE_H_
#define SKY_ENGINE_CORE_PAINTING_PICTURE_H_

#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "third_party/skia/include/core/SkPicture.h"

namespace blink {
class Canvas;
class DartLibraryNatives;

class Picture : public RefCounted<Picture>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    ~Picture() override;
    static PassRefPtr<Picture> create(PassRefPtr<SkPicture> skPicture);

    SkPicture* toSkia() const { return m_picture.get(); }

    void dispose();

    static void RegisterNatives(DartLibraryNatives* natives);

private:
    explicit Picture(PassRefPtr<SkPicture> skPicture);

    RefPtr<SkPicture> m_picture;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_PICTURE_H_
