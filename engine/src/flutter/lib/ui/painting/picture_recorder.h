// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_PICTURE_RECORDER_H_
#define FLUTTER_LIB_UI_PAINTING_PICTURE_RECORDER_H_

#include "flutter/display_list/display_list_canvas_recorder.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace flutter {
class Canvas;
class Picture;

class PictureRecorder : public RefCountedDartWrappable<PictureRecorder> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(PictureRecorder);

 public:
  static fml::RefPtr<PictureRecorder> Create();

  ~PictureRecorder() override;

  SkCanvas* BeginRecording(SkRect bounds);
  fml::RefPtr<Picture> endRecording(Dart_Handle dart_picture);

  sk_sp<DisplayListCanvasRecorder> display_list_recorder() {
    return display_list_recorder_;
  }

  void set_canvas(fml::RefPtr<Canvas> canvas) { canvas_ = std::move(canvas); }

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  PictureRecorder();

  sk_sp<DisplayListCanvasRecorder> display_list_recorder_;

  fml::RefPtr<Canvas> canvas_;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_PICTURE_RECORDER_H_
