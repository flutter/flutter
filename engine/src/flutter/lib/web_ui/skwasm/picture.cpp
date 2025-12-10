// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "export.h"
#include "helpers.h"
#include "live_objects.h"
#include "wrappers.h"

#include "flutter/display_list/dl_builder.h"

#include <cassert>

using namespace Skwasm;
using namespace flutter;

class PictureRecorder {
 public:
  PictureRecorder() {};

  DisplayListBuilder* beginRecording(const DlRect& cullRect) {
    assert(!_builder);
    _builder = std::make_unique<DisplayListBuilder>(cullRect);
    return _builder.get();
  }

  sk_sp<DisplayList> finishRecordingAsPicture() { return _builder->Build(); }

 private:
  std::unique_ptr<DisplayListBuilder> _builder;
};

SKWASM_EXPORT PictureRecorder* pictureRecorder_create() {
  livePictureRecorderCount++;
  return new PictureRecorder();
}

SKWASM_EXPORT void pictureRecorder_dispose(PictureRecorder* recorder) {
  livePictureRecorderCount--;
  delete recorder;
}

SKWASM_EXPORT DisplayListBuilder* pictureRecorder_beginRecording(
    PictureRecorder* recorder,
    const DlRect* cullRect) {
  return recorder->beginRecording(*cullRect);
}

SKWASM_EXPORT DisplayList* pictureRecorder_endRecording(
    PictureRecorder* recorder) {
  livePictureCount++;
  return recorder->finishRecordingAsPicture().release();
}

SKWASM_EXPORT void picture_getCullRect(DisplayList* picture, DlRect* outRect) {
  *outRect = picture->GetBounds();
}

SKWASM_EXPORT void picture_ref(DisplayList* picture) {
  livePictureCount++;
  picture->ref();
}

SKWASM_EXPORT void picture_dispose(DisplayList* picture) {
  livePictureCount--;
  picture->unref();
}

SKWASM_EXPORT uint32_t picture_approximateBytesUsed(DisplayList* picture) {
  return static_cast<uint32_t>(picture->bytes());
}
