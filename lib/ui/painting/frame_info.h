// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_FRAME_INFO_H_
#define FLUTTER_LIB_UI_PAINTING_FRAME_INFO_H_

#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/painting/image.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {

// A single animation frame.
class FrameInfo final : public RefCountedDartWrappable<FrameInfo> {
  DEFINE_WRAPPERTYPEINFO();

 public:
  int durationMillis() { return durationMillis_; }
  fml::RefPtr<CanvasImage> image() { return image_; }

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  FrameInfo(fml::RefPtr<CanvasImage> image, int durationMillis);

  ~FrameInfo() override;

  const fml::RefPtr<CanvasImage> image_;
  const int durationMillis_;

  FML_FRIEND_MAKE_REF_COUNTED(FrameInfo);
  FML_FRIEND_REF_COUNTED_THREAD_SAFE(FrameInfo);
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_FRAME_INFO_H_
