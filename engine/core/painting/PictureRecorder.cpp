// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/Canvas.h"
#include "sky/engine/core/painting/Drawable.h"
#include "sky/engine/core/painting/Picture.h"
#include "sky/engine/core/painting/PictureRecorder.h"

namespace blink {

PictureRecorder::PictureRecorder()
    : m_pictureRecorder(adoptPtr(new SkPictureRecorder()))
{
}

PictureRecorder::~PictureRecorder()
{
}

bool PictureRecorder::isRecording() {
    return m_canvas && m_canvas->isRecording();
}

SkCanvas* PictureRecorder::beginRecording(double width, double height)
{
    return m_pictureRecorder->beginRecording(width, height);
}

PassRefPtr<Picture> PictureRecorder::endRecording()
{
    if (!isRecording())
        return nullptr;
    RefPtr<Picture> picture = Picture::create(
        adoptRef(m_pictureRecorder->endRecording()));
    m_canvas->clearSkCanvas();
    m_canvas = nullptr;
    return picture.release();
}

PassRefPtr<Drawable> PictureRecorder::endRecordingAsDrawable()
{
    if (!isRecording())
        return nullptr;
    RefPtr<Drawable> drawable = Drawable::create(
        adoptRef(m_pictureRecorder->endRecordingAsDrawable()));
    m_canvas->clearSkCanvas();
    m_canvas = nullptr;
    return drawable.release();
}

void PictureRecorder::set_canvas(PassRefPtr<Canvas> canvas) { m_canvas = canvas; }

} // namespace blink
