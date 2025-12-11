// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cassert>

#include "flutter/display_list/dl_builder.h"
#include "flutter/skwasm/export.h"
#include "flutter/skwasm/helpers.h"
#include "flutter/skwasm/live_objects.h"
#include "flutter/skwasm/wrappers.h"

class PictureRecorder {
 public:
  PictureRecorder() {};

  flutter::DisplayListBuilder* BeginRecording(const flutter::DlRect& cullRect) {
    assert(!builder_);
    builder_ = std::make_unique<flutter::DisplayListBuilder>(cullRect);
    return builder_.get();
  }

  sk_sp<flutter::DisplayList> FinishRecordingAsPicture() {
    return builder_->Build();
  }

 private:
  std::unique_ptr<flutter::DisplayListBuilder> builder_;
};

SKWASM_EXPORT PictureRecorder* pictureRecorder_create() {
  Skwasm::live_picture_recorder_count++;
  return new PictureRecorder();
}

SKWASM_EXPORT void pictureRecorder_dispose(PictureRecorder* recorder) {
  Skwasm::live_picture_recorder_count--;
  delete recorder;
}

SKWASM_EXPORT flutter::DisplayListBuilder* pictureRecorder_beginRecording(
    PictureRecorder* recorder,
    const flutter::DlRect* cullRect) {
  return recorder->BeginRecording(*cullRect);
}

SKWASM_EXPORT flutter::DisplayList* pictureRecorder_endRecording(
    PictureRecorder* recorder) {
  Skwasm::live_picture_count++;
  return recorder->FinishRecordingAsPicture().release();
}

SKWASM_EXPORT void picture_getCullRect(flutter::DisplayList* picture,
                                       flutter::DlRect* outRect) {
  *outRect = picture->GetBounds();
}

SKWASM_EXPORT void picture_ref(flutter::DisplayList* picture) {
  Skwasm::live_picture_count++;
  picture->ref();
}

SKWASM_EXPORT void picture_dispose(flutter::DisplayList* picture) {
  Skwasm::live_picture_count--;
  picture->unref();
}

SKWASM_EXPORT uint32_t
picture_approximateBytesUsed(flutter::DisplayList* picture) {
  return static_cast<uint32_t>(picture->bytes());
}
