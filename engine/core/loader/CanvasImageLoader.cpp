// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/loader/CanvasImageLoader.h"
#include "sky/engine/core/painting/CanvasImage.h"
#include "sky/engine/platform/image-decoders/ImageDecoder.h"
#include "sky/engine/platform/SharedBuffer.h"

namespace blink {

CanvasImageLoader::CanvasImageLoader(const String& src, PassOwnPtr<ImageLoaderCallback> callback)
  : callback_(callback) {
  // TODO(jackson): Figure out how to determine the proper base URL here
  KURL url = KURL(KURL(), src);
  fetcher_ = adoptPtr(new MojoFetcher(this, url));
}

CanvasImageLoader::~CanvasImageLoader() {
}

void CanvasImageLoader::OnReceivedResponse(mojo::URLResponsePtr response) {
  if (response->status_code != 200) {
    callback_->handleEvent(nullptr);
    return;
  }
  buffer_ = SharedBuffer::create();
  drainer_ =
      adoptPtr(new mojo::common::DataPipeDrainer(this, response->body.Pass()));
}

void CanvasImageLoader::OnDataAvailable(const void* data, size_t num_bytes) {
  buffer_->append(static_cast<const char*>(data), num_bytes);
}

void CanvasImageLoader::OnDataComplete() {
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