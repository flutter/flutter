// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/bind.h"
#include "base/trace_event/trace_event.h"
#include "base/message_loop/message_loop.h"
#include "sky/engine/core/painting/CanvasImageDecoder.h"
#include "sky/engine/core/painting/CanvasImage.h"
#include "sky/engine/platform/SharedBuffer.h"
#include "sky/engine/platform/image-decoders/ImageDecoder.h"
#include "sky/engine/platform/mojo/data_pipe.h"

namespace blink {

PassRefPtr<CanvasImageDecoder> CanvasImageDecoder::create(
    PassOwnPtr<ImageDecoderCallback> callback) {
  return adoptRef(new CanvasImageDecoder(callback));
}

CanvasImageDecoder::CanvasImageDecoder(PassOwnPtr<ImageDecoderCallback> callback)
    : callback_(callback), weak_factory_(this) {
  CHECK(callback_);
}

CanvasImageDecoder::~CanvasImageDecoder() {
}

void CanvasImageDecoder::initWithConsumer(mojo::ScopedDataPipeConsumerHandle handle) {
  if (!handle.is_valid()) {
    base::MessageLoop::current()->PostTask(
        FROM_HERE, base::Bind(&CanvasImageDecoder::RejectCallback,
                              weak_factory_.GetWeakPtr()));
    return;
  }

  DrainDataPipeInBackground(handle.Pass(),
      base::Bind(&CanvasImageDecoder::Decode, weak_factory_.GetWeakPtr()));
}

void CanvasImageDecoder::initWithList(const Uint8List& list) {
  RefPtr<SharedBuffer> buffer = SharedBuffer::create();
  buffer->append(reinterpret_cast<const char*>(list.data()),
                 list.num_elements());
  base::MessageLoop::current()->PostTask(
      FROM_HERE, base::Bind(&CanvasImageDecoder::Decode,
                            weak_factory_.GetWeakPtr(), buffer.release()));
}

void CanvasImageDecoder::Decode(PassRefPtr<SharedBuffer> buffer) {
  TRACE_EVENT0("blink", "CanvasImageDecoder::Decode");

  // Destroy the callback after this function completes.  The Dart closure
  // associated with the callback may hold a reference to the ImageDecoder,
  // resulting in a circular reference.
  CHECK(callback_);
  OwnPtr<ImageDecoderCallback> callback(callback_.release());

  OwnPtr<ImageDecoder> decoder =
      ImageDecoder::create(*buffer.get(), ImageSource::AlphaPremultiplied,
                           ImageSource::GammaAndColorProfileIgnored);
  // decoder can be null if the buffer we was empty and we couldn't even guess
  // what type of image to decode.
  if (!decoder) {
    callback->handleEvent(nullptr);
    return;
  }
  decoder->setData(buffer.get(), true);
  if (decoder->failed() || decoder->frameCount() == 0) {
    callback->handleEvent(nullptr);
    return;
  }

  RefPtr<CanvasImage> resultImage = CanvasImage::create();
  ImageFrame* imageFrame = decoder->frameBufferAtIndex(0);
  RefPtr<SkImage> skImage = adoptRef(SkImage::NewFromBitmap(imageFrame->getSkBitmap()));
  resultImage->setImage(skImage.release());
  callback->handleEvent(resultImage.get());
}

void CanvasImageDecoder::RejectCallback() {
  CHECK(callback_);
  OwnPtr<ImageDecoderCallback> callback(callback_.release());
  callback->handleEvent(nullptr);
}

}  // namespace blink
