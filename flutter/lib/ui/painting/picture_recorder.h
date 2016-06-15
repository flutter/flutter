// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_PICTURE_RECORDER_H_
#define FLUTTER_LIB_UI_PAINTING_PICTURE_RECORDER_H_

#include "base/memory/ref_counted.h"
#include "flutter/tonic/dart_wrappable.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace blink {
class Canvas;
class DartLibraryNatives;
class Picture;

class PictureRecorder : public base::RefCountedThreadSafe<PictureRecorder>,
                        public DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
 public:
  static scoped_refptr<PictureRecorder> Create();

  ~PictureRecorder();

  SkCanvas* BeginRecording(SkRect bounds);
  scoped_refptr<Picture> endRecording();
  bool isRecording();

  void set_canvas(scoped_refptr<Canvas> canvas) {
    canvas_ = std::move(canvas);
  }

  static void RegisterNatives(DartLibraryNatives* natives);

 private:
  PictureRecorder();

  SkRTreeFactory rtree_factory_;
  SkPictureRecorder picture_recorder_;
  scoped_refptr<Canvas> canvas_;
};

} // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_PICTURE_RECORDER_H_
