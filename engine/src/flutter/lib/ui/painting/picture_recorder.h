// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_PICTURE_RECORDER_H_
#define FLUTTER_LIB_UI_PAINTING_PICTURE_RECORDER_H_

#include "lib/tonic/dart_wrappable.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {
class Canvas;
class Picture;

class PictureRecorder : public fxl::RefCountedThreadSafe<PictureRecorder>,
                        public tonic::DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
  FRIEND_MAKE_REF_COUNTED(PictureRecorder);

 public:
  static fxl::RefPtr<PictureRecorder> Create();

  ~PictureRecorder();

  SkCanvas* BeginRecording(SkRect bounds);
  fxl::RefPtr<Picture> endRecording();
  bool isRecording();

  void set_canvas(fxl::RefPtr<Canvas> canvas) { canvas_ = std::move(canvas); }

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  PictureRecorder();

  SkRTreeFactory rtree_factory_;
  SkPictureRecorder picture_recorder_;
  fxl::RefPtr<Canvas> canvas_;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_PICTURE_RECORDER_H_
