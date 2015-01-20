// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/layer.h"

#include "base/debug/trace_event.h"
#include "sky/compositor/layer_host.h"
#include "sky/compositor/rasterizer.h"
#include "third_party/skia/include/core/SkCanvas.h"
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
  auto picture = RecordPicture();
  texture_ = rasterizer_->Rasterize(picture.get());
}

skia::RefPtr<SkPicture> Layer::RecordPicture() {
  TRACE_EVENT0("sky", "Layer::RecordPicture");

  SkRTreeFactory factory;
  SkPictureRecorder recorder;

  auto canvas = skia::SharePtr(recorder.beginRecording(
      size_.width(), size_.height(), &factory,
      SkPictureRecorder::kComputeSaveLayerInfo_RecordFlag));

  client_->PaintContents(canvas.get(), gfx::Rect(size_));
  return skia::AdoptRef(recorder.endRecordingAsPicture());
}

scoped_ptr<mojo::GLTexture> Layer::GetTexture() {
  return texture_.Pass();
}

}  // namespace sky
