// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/bind.h"
#include "base/message_loop/message_loop.h"
#include "sky/engine/core/loader/CanvasImageDecoder.h"
#include "sky/engine/core/painting/CanvasImage.h"
#include "sky/engine/platform/SharedBuffer.h"
#include "sky/engine/platform/image-decoders/ImageDecoder.h"

namespace blink {

PassRefPtr<CanvasImageDecoder> CanvasImageDecoder::create(
    PassOwnPtr<ImageDecoderCallback> callback) {
  return adoptRef(new CanvasImageDecoder(callback));
}

CanvasImageDecoder::CanvasImageDecoder(PassOwnPtr<ImageDecoderCallback> callback)
    : callback_(callback), weak_factory_(this) {
  CHECK(callback_);
  buffer_ = SharedBuffer::create();
}

CanvasImageDecoder::~CanvasImageDecoder() {
}

void CanvasImageDecoder::initWithConsumer(mojo::ScopedDataPipeConsumerHandle handle) {
  CHECK(!drainer_);
  if (!handle.is_valid()) {
    base::MessageLoop::current()->PostTask(
        FROM_HERE, base::Bind(&CanvasImageDecoder::RejectCallback,
                              weak_factory_.GetWeakPtr()));
    return;
  }

  drainer_ = adoptPtr(new mojo::common::DataPipeDrainer(this, handle.Pass()));
}

void CanvasImageDecoder::initWithList(const Uint8List& list) {
  CHECK(!drainer_);

  OnDataAvailable(list.data(), list.num_elements());
  base::MessageLoop::current()->PostTask(
      FROM_HERE, base::Bind(&CanvasImageDecoder::OnDataComplete,
                            weak_factory_.GetWeakPtr()));
}

void CanvasImageDecoder::OnDataAvailable(const void* data, size_t num_bytes) {
  buffer_->append(static_cast<const char*>(data), num_bytes);
}

void CanvasImageDecoder::OnDataComplete() {
  OwnPtr<ImageDecoder> decoder =
      ImageDecoder::create(*buffer_.get(), ImageSource::AlphaPremultiplied,
                           ImageSource::GammaAndColorProfileIgnored);
  // decoder can be null if the buffer we was empty and we couldn't even guess
  // what type of image to decode.
  if (!decoder) {
    callback_->handleEvent(nullptr);
    return;
  }
  decoder->setData(buffer_.get(), true);
  if (decoder->failed() || decoder->frameCount() == 0) {
    callback_->handleEvent(nullptr);
    return;
  }

  RefPtr<CanvasImage> resultImage = CanvasImage::create();
  ImageFrame* imageFrame = decoder->frameBufferAtIndex(0);
  RefPtr<SkImage> skImage = adoptRef(SkImage::NewFromBitmap(imageFrame->getSkBitmap()));
  resultImage->setImage(skImage.release());
  callback_->handleEvent(resultImage.get());
}

void CanvasImageDecoder::RejectCallback() {
  callback_->handleEvent(nullptr);
}

}  // namespace blink
