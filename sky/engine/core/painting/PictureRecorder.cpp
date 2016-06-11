// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/painting/PictureRecorder.h"

#include "flutter/tonic/dart_args.h"
#include "flutter/tonic/dart_binding_macros.h"
#include "flutter/tonic/dart_converter.h"
#include "flutter/tonic/dart_library_natives.h"
#include "sky/engine/core/painting/Canvas.h"
#include "sky/engine/core/painting/Picture.h"

namespace blink {

static void PictureRecorder_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&PictureRecorder::create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, PictureRecorder);

#define FOR_EACH_BINDING(V) \
  V(PictureRecorder, isRecording) \
  V(PictureRecorder, endRecording)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void PictureRecorder::RegisterNatives(DartLibraryNatives* natives) {
  natives->Register({
    { "PictureRecorder_constructor", PictureRecorder_constructor, 1, true },
FOR_EACH_BINDING(DART_REGISTER_NATIVE)
  });
}

PictureRecorder::PictureRecorder()
{
}

PictureRecorder::~PictureRecorder()
{
}

bool PictureRecorder::isRecording() {
    return m_canvas && m_canvas->isRecording();
}

SkCanvas* PictureRecorder::beginRecording(SkRect bounds)
{
    return m_pictureRecorder.beginRecording(bounds,
        &m_rtreeFactory, SkPictureRecorder::kComputeSaveLayerInfo_RecordFlag);
}

scoped_refptr<Picture> PictureRecorder::endRecording()
{
    if (!isRecording())
        return nullptr;
    scoped_refptr<Picture> picture = Picture::create(
        m_pictureRecorder.finishRecordingAsPicture());
    m_canvas->clearSkCanvas();
    m_canvas->ClearDartWrapper();
    m_canvas = nullptr;
    ClearDartWrapper();
    return std::move(picture);
}

void PictureRecorder::set_canvas(scoped_refptr<Canvas> canvas)
{
    m_canvas = std::move(canvas);
}

} // namespace blink
