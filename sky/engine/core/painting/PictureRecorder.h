// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_PICTURERECORDER_H_
#define SKY_ENGINE_CORE_PAINTING_PICTURERECORDER_H_

#include "base/memory/ref_counted.h"
#include "flutter/tonic/dart_wrappable.h"
#include "sky/engine/core/painting/Rect.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace blink {
class Canvas;
class DartLibraryNatives;
class Picture;

class PictureRecorder : public base::RefCountedThreadSafe<PictureRecorder>,
                        public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static scoped_refptr<PictureRecorder> create() { return new PictureRecorder(); }

    ~PictureRecorder();

    SkCanvas* beginRecording(SkRect bounds);
    scoped_refptr<Picture> endRecording();
    bool isRecording();

    void set_canvas(scoped_refptr<Canvas> canvas);

    static void RegisterNatives(DartLibraryNatives* natives);

private:
    PictureRecorder();

    SkRTreeFactory m_rtreeFactory;
    SkPictureRecorder m_pictureRecorder;
    scoped_refptr<Canvas> m_canvas;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_PICTURERECORDER_H_
