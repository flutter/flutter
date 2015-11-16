// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "services/sky/compositor/texture_layer.h"

#include "base/trace_event/trace_event.h"
#include "services/sky/compositor/layer_host.h"
#include "services/sky/compositor/rasterizer.h"
#include "sky/engine/wtf/RefPtr.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace sky {

TextureLayer::TextureLayer(LayerClient* client) : client_(client) {
}

TextureLayer::~TextureLayer() {
}

void TextureLayer::SetSize(const gfx::Size& size) {
  size_ = size;
}

void TextureLayer::Display() {
  TRACE_EVENT0("flutter", "Layer::Display");
  DCHECK(rasterizer_);
  RefPtr<SkPicture> picture = RecordPicture();
  texture_ = rasterizer_->Rasterize(picture.get());
}

PassRefPtr<SkPicture> TextureLayer::RecordPicture() {
  TRACE_EVENT0("flutter", "Layer::RecordPicture");

  SkRTreeFactory factory;
  SkPictureRecorder recorder;

  SkCanvas* canvas = recorder.beginRecording(
      size_.width(), size_.height(), &factory,
      SkPictureRecorder::kComputeSaveLayerInfo_RecordFlag);

  client_->PaintContents(canvas, gfx::Rect(size_));
  return adoptRef(recorder.endRecordingAsPicture());
}

bool TextureLayer::HaveTexture() const {
  return texture_;
}

scoped_ptr<mojo::GLTexture> TextureLayer::GetTexture() {
  return texture_.Pass();
}

}  // namespace sky
