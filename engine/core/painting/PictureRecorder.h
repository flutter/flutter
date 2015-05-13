// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_PICTURERECORDER_H_
#define SKY_ENGINE_CORE_PAINTING_PICTURERECORDER_H_

#include "sky/engine/core/painting/Canvas.h"

namespace blink {

class Picture;

class PictureRecorder : public Canvas {
    DEFINE_WRAPPERTYPEINFO();
public:
    ~PictureRecorder() override;
    static PassRefPtr<PictureRecorder> create(double width, double height);

    PassRefPtr<Picture> endRecording();

private:
    PictureRecorder(const FloatSize& size);
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_PICTURERECORDER_H_
