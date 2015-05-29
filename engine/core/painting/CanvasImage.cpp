// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/painting/CanvasImage.h"

namespace blink {

CanvasImage::CanvasImage() : imageLoader_(adoptPtr(new NewImageLoader(this))) {
}

CanvasImage::~CanvasImage() {
}

int CanvasImage::width() const {
  return bitmap_.width();
}

int CanvasImage::height() const {
  return bitmap_.height();
}

void CanvasImage::setSrc(const String& url) {
  // TODO(jackson): Figure out how to determine the proper base URL here
  KURL newSrcURL = KURL(KURL(), url);
  if (srcURL_ != newSrcURL) {
    srcURL_ = newSrcURL;
    imageLoader_->Load(srcURL_);
  }
}

void CanvasImage::OnLoadFinished(const SkBitmap& result) {
  // TODO(jackson): We'll eventually need a notification pathway for
  // when the image load is complete so that we know to repaint, etc.
  bitmap_ = result;
}

}  // namespace blink