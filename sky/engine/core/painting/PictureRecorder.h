// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_PICTURERECORDER_H_
#define SKY_ENGINE_CORE_PAINTING_PICTURERECORDER_H_

#include "sky/engine/core/painting/Rect.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/ThreadSafeRefCounted.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace blink {
class Canvas;
class DartLibraryNatives;
class Picture;

class PictureRecorder : public ThreadSafeRefCounted<PictureRecorder>,
                        public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<PictureRecorder> create()
    {
        return adoptRef(new PictureRecorder());
    }

    ~PictureRecorder();

    SkCanvas* beginRecording(SkRect bounds);
    PassRefPtr<Picture> endRecording();
    bool isRecording();

    void set_canvas(PassRefPtr<Canvas> canvas);

    static void RegisterNatives(DartLibraryNatives* natives);

private:
    PictureRecorder();

    SkRTreeFactory m_rtreeFactory;
    SkPictureRecorder m_pictureRecorder;
    RefPtr<Canvas> m_canvas;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_PICTURERECORDER_H_
