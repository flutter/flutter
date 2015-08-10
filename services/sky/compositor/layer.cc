// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "services/sky/compositor/layer.h"

#include "base/trace_event/trace_event.h"
#include "services/sky/compositor/layer_host.h"
#include "services/sky/compositor/picture_serializer.h"
#include "services/sky/compositor/rasterizer.h"
#include "sky/engine/wtf/RefPtr.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace sky {

Layer::Layer(LayerClient* client) : client_(client) {
}

Layer::~Layer() {
}

void Layer::SetSize(const gfx::Size& size) {
  size_ = size;
}

void Layer::Display() {
  TRACE_EVENT0("sky", "Layer::Display");
  DCHECK(rasterizer_);
  RefPtr<SkPicture> picture = RecordPicture();

#if 0
  SerializePicture(
      "/data/data/org.chromium.mojo.shell/cache/layer0.skp", picture.get());
#endif

  texture_ = rasterizer_->Rasterize(picture.get());
}

PassRefPtr<SkPicture> Layer::RecordPicture() {
  TRACE_EVENT0("sky", "Layer::RecordPicture");

  SkRTreeFactory factory;
  SkPictureRecorder recorder;

  SkCanvas* canvas = recorder.beginRecording(
      size_.width(), size_.height(), &factory,
      SkPictureRecorder::kComputeSaveLayerInfo_RecordFlag);

  client_->PaintContents(canvas, gfx::Rect(size_));
  return adoptRef(recorder.endRecordingAsPicture());
}

scoped_ptr<mojo::GLTexture> Layer::GetTexture() {
  return texture_.Pass();
}

}  // namespace sky
