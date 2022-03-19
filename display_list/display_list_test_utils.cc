// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/display_list_test_utils.h"
#include "flutter/display_list/display_list_builder.h"

#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace flutter {
namespace testing {

sk_sp<SkPicture> GetSamplePicture() {
  SkPictureRecorder recorder;
  recorder.beginRecording(SkRect::MakeWH(150, 100));
  SkPaint paint;
  paint.setColor(SK_ColorRED);
  recorder.getRecordingCanvas()->drawRect(SkRect::MakeXYWH(10, 10, 80, 80),
                                          paint);
  return recorder.finishRecordingAsPicture();
}

sk_sp<DisplayList> GetSampleDisplayList() {
  DisplayListBuilder builder(SkRect::MakeWH(150, 100));
  builder.setColor(SK_ColorRED);
  builder.drawRect(SkRect::MakeXYWH(10, 10, 80, 80));
  return builder.Build();
}

sk_sp<SkPicture> GetSampleNestedPicture() {
  SkPictureRecorder recorder;
  recorder.beginRecording(SkRect::MakeWH(150, 100));
  SkCanvas* canvas = recorder.getRecordingCanvas();
  SkPaint paint;
  for (int y = 10; y <= 60; y += 10) {
    for (int x = 10; x <= 60; x += 10) {
      paint.setColor(((x + y) % 20) == 10 ? SK_ColorRED : SK_ColorBLUE);
      canvas->drawRect(SkRect::MakeXYWH(x, y, 80, 80), paint);
    }
  }
  SkPictureRecorder outer_recorder;
  outer_recorder.beginRecording(SkRect::MakeWH(150, 100));
  canvas = outer_recorder.getRecordingCanvas();
  canvas->drawPicture(recorder.finishRecordingAsPicture());
  return outer_recorder.finishRecordingAsPicture();
}

sk_sp<DisplayList> GetSampleNestedDisplayList() {
  DisplayListBuilder builder(SkRect::MakeWH(150, 100));
  for (int y = 10; y <= 60; y += 10) {
    for (int x = 10; x <= 60; x += 10) {
      builder.setColor(((x + y) % 20) == 10 ? SK_ColorRED : SK_ColorBLUE);
      builder.drawRect(SkRect::MakeXYWH(x, y, 80, 80));
    }
  }
  DisplayListBuilder outer_builder(SkRect::MakeWH(150, 100));
  outer_builder.drawDisplayList(builder.Build());
  return outer_builder.Build();
}

sk_sp<DisplayList> GetSampleDisplayList(int ops) {
  DisplayListBuilder builder(SkRect::MakeWH(150, 100));
  for (int i = 0; i < ops; i++) {
    builder.drawColor(SK_ColorRED, DlBlendMode::kSrc);
  }
  return builder.Build();
}

}  // namespace testing
}  // namespace flutter
