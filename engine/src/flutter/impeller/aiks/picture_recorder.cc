// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/aiks/picture_recorder.h"

#include "flutter/impeller/aiks/canvas.h"

namespace impeller {

PictureRecorder::PictureRecorder() : canvas_(std::make_shared<Canvas>()) {}

PictureRecorder::~PictureRecorder() = default;

std::shared_ptr<Canvas> PictureRecorder::GetCanvas() const {
  return canvas_;
}

std::shared_ptr<Picture> PictureRecorder::EndRecordingAsPicture() {
  return canvas_->EndRecordingAsPicture();
}

}  // namespace impeller
