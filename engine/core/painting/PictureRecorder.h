// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_PICTURERECORDER_H_
#define SKY_ENGINE_CORE_PAINTING_PICTURERECORDER_H_

#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace blink {

class Canvas;
class Drawable;
class Picture;

class PictureRecorder : public RefCounted<PictureRecorder>,
                        public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<PictureRecorder> create()
    {
        return adoptRef(new PictureRecorder());
    }

    ~PictureRecorder();

    // PassRefPtr<Canvas> beginRecording(double width, double height);
    SkCanvas* beginRecording(double width, double height);
    PassRefPtr<Picture> endRecording();
    PassRefPtr<Drawable> endRecordingAsDrawable();
    bool isRecording();

    void set_canvas(PassRefPtr<Canvas> canvas);

private:
	PictureRecorder();

	OwnPtr<SkPictureRecorder> m_pictureRecorder;
	RefPtr<Canvas> m_canvas;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_PICTURERECORDER_H_
