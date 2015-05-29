// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/loader/NewImageLoader.h"
#include "sky/engine/platform/image-decoders/ImageDecoder.h"
#include "sky/engine/platform/SharedBuffer.h"

namespace blink {

NewImageLoader::NewImageLoader(NewImageLoaderClient* client) : client_(client) {
}

NewImageLoader::~NewImageLoader() {
}

void NewImageLoader::Load(const KURL& src) {
  fetcher_ = adoptPtr(new MojoFetcher(this, src));
}

void NewImageLoader::OnReceivedResponse(mojo::URLResponsePtr response) {
  if (response->status_code != 200) {
    client_->OnLoadFinished(SkBitmap());
    return;
  }
  buffer_ = SharedBuffer::create();
  drainer_ =
      adoptPtr(new mojo::common::DataPipeDrainer(this, response->body.Pass()));
}

void NewImageLoader::OnDataAvailable(const void* data, size_t num_bytes) {
  buffer_->append(static_cast<const char*>(data), num_bytes);
}

void NewImageLoader::OnDataComplete() {
  SkBitmap bitmap;
  OwnPtr<ImageDecoder> decoder =
      ImageDecoder::create(*buffer_.get(), ImageSource::AlphaPremultiplied,
                           ImageSource::GammaAndColorProfileIgnored);
  decoder->setData(buffer_.get(), true);

  if (decoder->failed()) {
    client_->OnLoadFinished(bitmap);
  } else {
    if (decoder->frameCount() > 0) {
      bitmap = decoder->frameBufferAtIndex(0)->getSkBitmap();
    }
    client_->OnLoadFinished(bitmap);
  }
}

}  // namespace blink