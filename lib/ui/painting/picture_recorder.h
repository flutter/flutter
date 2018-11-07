// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_PICTURE_RECORDER_H_
#define FLUTTER_LIB_UI_PAINTING_PICTURE_RECORDER_H_

#include "flutter/lib/ui/dart_wrapper.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {
class Canvas;
class Picture;

class PictureRecorder : public RefCountedDartWrappable<PictureRecorder> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(PictureRecorder);

 public:
  static fml::RefPtr<PictureRecorder> Create();

  ~PictureRecorder();

  SkCanvas* BeginRecording(SkRect bounds);
  fml::RefPtr<Picture> endRecording();
  bool isRecording();

  void set_canvas(fml::RefPtr<Canvas> canvas) { canvas_ = std::move(canvas); }

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  PictureRecorder();

  SkRTreeFactory rtree_factory_;
  SkPictureRecorder picture_recorder_;
  fml::RefPtr<Canvas> canvas_;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_PICTURE_RECORDER_H_
