// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/PictureRecorder.h"

#include "sky/engine/core/painting/Picture.h"

namespace blink {

PassRefPtr<PictureRecorder> PictureRecorder::create(double width, double height)
{
    return adoptRef(new PictureRecorder(FloatSize(width, height)));
}

PictureRecorder::PictureRecorder(const FloatSize& size)
    : Canvas(size)
{
}

PictureRecorder::~PictureRecorder()
{
}

PassRefPtr<Picture> PictureRecorder::endRecording()
{
    if (!isRecording())
        return nullptr;
    return Picture::create(finishRecording());
}

} // namespace blink
