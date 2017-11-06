// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_FRAME_INFO_H_
#define FLUTTER_LIB_UI_PAINTING_FRAME_INFO_H_

#include "flutter/lib/ui/painting/image.h"
#include "lib/tonic/dart_wrappable.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {

// A single animation frame.
class FrameInfo final : public fxl::RefCountedThreadSafe<FrameInfo>,
                        public tonic::DartWrappable {
  DEFINE_WRAPPERTYPEINFO();

 public:
  int durationMillis() { return durationMillis_; }
  fxl::RefPtr<CanvasImage> image() { return image_; }

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  FrameInfo(fxl::RefPtr<CanvasImage> image, int durationMillis)
      : image_(std::move(image)), durationMillis_(durationMillis) {}
  ~FrameInfo(){};

  const fxl::RefPtr<CanvasImage> image_;
  const int durationMillis_;

  FRIEND_MAKE_REF_COUNTED(FrameInfo);
  FRIEND_REF_COUNTED_THREAD_SAFE(FrameInfo);
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_FRAME_INFO_H_
