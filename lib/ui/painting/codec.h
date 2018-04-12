// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_CODEC_H_
#define FLUTTER_LIB_UI_PAINTING_CODEC_H_

#include "flutter/lib/ui/painting/frame_info.h"
#include "lib/tonic/dart_wrappable.h"
#include "third_party/skia/include/codec/SkCodec.h"
#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkImage.h"

using tonic::DartPersistentValue;

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {

// A handle to an SkCodec object.
//
// Doesn't mirror SkCodec's API but provides a simple sequential access API.
class Codec : public fxl::RefCountedThreadSafe<Codec>,
              public tonic::DartWrappable {
  DEFINE_WRAPPERTYPEINFO();

 public:
  virtual int frameCount() = 0;
  virtual int repetitionCount() = 0;
  virtual Dart_Handle getNextFrame(Dart_Handle callback_handle) = 0;
  void dispose();

  static void RegisterNatives(tonic::DartLibraryNatives* natives);
};

class MultiFrameCodec : public Codec {
 public:
  int frameCount() { return frameInfos_.size(); }
  int repetitionCount() { return repetitionCount_; }
  Dart_Handle getNextFrame(Dart_Handle args);

 private:
  MultiFrameCodec(std::unique_ptr<SkCodec> codec);
  ~MultiFrameCodec() {}

  sk_sp<SkImage> GetNextFrameImage();
  void GetNextFrameAndInvokeCallback(
      std::unique_ptr<DartPersistentValue> callback,
      size_t trace_id);

  const std::unique_ptr<SkCodec> codec_;
  int repetitionCount_;
  int nextFrameIndex_;

  std::vector<SkCodec::FrameInfo> frameInfos_;
  std::vector<SkBitmap> frameBitmaps_;

  FRIEND_MAKE_REF_COUNTED(MultiFrameCodec);
  FRIEND_REF_COUNTED_THREAD_SAFE(MultiFrameCodec);
};

class SingleFrameCodec : public Codec {
 public:
  int frameCount() { return 1; }
  int repetitionCount() { return 0; }
  Dart_Handle getNextFrame(Dart_Handle args);

 private:
  SingleFrameCodec(fxl::RefPtr<FrameInfo> frame) : frame_(std::move(frame)) {}
  ~SingleFrameCodec() {}

  fxl::RefPtr<FrameInfo> frame_;

  FRIEND_MAKE_REF_COUNTED(SingleFrameCodec);
  FRIEND_REF_COUNTED_THREAD_SAFE(SingleFrameCodec);
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_CODEC_H_
