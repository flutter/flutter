// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/loader/CanvasImageDecoder.h"
#include "sky/engine/core/painting/CanvasImage.h"
#include "sky/engine/core/script/dom_dart_state.h"
#include "sky/engine/platform/SharedBuffer.h"
#include "sky/engine/platform/image-decoders/ImageDecoder.h"

namespace blink {

PassRefPtr<CanvasImageDecoder> CanvasImageDecoder::create(
  mojo::ScopedDataPipeConsumerHandle handle,
  PassOwnPtr<ImageDecoderCallback> callback)
{
  return adoptRef(new CanvasImageDecoder(handle.Pass(), callback));
}

CanvasImageDecoder::CanvasImageDecoder(mojo::ScopedDataPipeConsumerHandle handle, PassOwnPtr<ImageDecoderCallback> callback)
  : callback_(callback) {
  buffer_ = SharedBuffer::create();
  drainer_ = adoptPtr(new mojo::common::DataPipeDrainer(this, handle.Pass()));
}

CanvasImageDecoder::~CanvasImageDecoder() {
}

void CanvasImageDecoder::OnDataAvailable(const void* data, size_t num_bytes) {
  buffer_->append(static_cast<const char*>(data), num_bytes);
}

void CanvasImageDecoder::OnDataComplete() {
  OwnPtr<ImageDecoder> decoder =
      ImageDecoder::create(*buffer_.get(), ImageSource::AlphaPremultiplied,
                           ImageSource::GammaAndColorProfileIgnored);
  decoder->setData(buffer_.get(), true);
  if (!decoder->failed() && decoder->frameCount() > 0) {
    RefPtr<CanvasImage> resultImage = CanvasImage::create();
    resultImage->setBitmap(decoder->frameBufferAtIndex(0)->getSkBitmap());
    callback_->handleEvent(resultImage.get());
  } else {
    callback_->handleEvent(nullptr);
  }
}

}  // namespace blink