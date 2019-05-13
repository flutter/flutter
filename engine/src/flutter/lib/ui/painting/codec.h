// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_CODEC_H_
#define FLUTTER_LIB_UI_PAINTING_CODEC_H_

#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/painting/frame_info.h"
#include "third_party/skia/include/codec/SkCodec.h"
#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkImage.h"

using tonic::DartPersistentValue;

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace flutter {

// A handle to an SkCodec object.
//
// Doesn't mirror SkCodec's API but provides a simple sequential access API.
class Codec : public RefCountedDartWrappable<Codec> {
  DEFINE_WRAPPERTYPEINFO();

 public:
  virtual int frameCount() const = 0;
  virtual int repetitionCount() const = 0;
  virtual Dart_Handle getNextFrame(Dart_Handle callback_handle) = 0;
  void dispose();

  static void RegisterNatives(tonic::DartLibraryNatives* natives);
};

class MultiFrameCodec : public Codec {
 public:
  int frameCount() const override;
  int repetitionCount() const override;
  Dart_Handle getNextFrame(Dart_Handle args) override;

 private:
  MultiFrameCodec(std::unique_ptr<SkCodec> codec);

  ~MultiFrameCodec() override;

  sk_sp<SkImage> GetNextFrameImage(fml::WeakPtr<GrContext> resourceContext);

  void GetNextFrameAndInvokeCallback(
      std::unique_ptr<DartPersistentValue> callback,
      fml::RefPtr<fml::TaskRunner> ui_task_runner,
      fml::WeakPtr<GrContext> resourceContext,
      fml::RefPtr<flutter::SkiaUnrefQueue> unref_queue,
      size_t trace_id);

  const std::unique_ptr<SkCodec> codec_;
  const int frameCount_;
  const int repetitionCount_;
  int nextFrameIndex_;

  // The last decoded frame that's required to decode any subsequent frames.
  std::unique_ptr<SkBitmap> lastRequiredFrame_;
  // The index of the last decoded required frame.
  int lastRequiredFrameIndex_ = -1;

  FML_FRIEND_MAKE_REF_COUNTED(MultiFrameCodec);
  FML_FRIEND_REF_COUNTED_THREAD_SAFE(MultiFrameCodec);
};

class SingleFrameCodec : public Codec {
 public:
  int frameCount() const override;
  int repetitionCount() const override;
  Dart_Handle getNextFrame(Dart_Handle args) override;

 private:
  SingleFrameCodec(fml::RefPtr<FrameInfo> frame);
  ~SingleFrameCodec() override;

  fml::RefPtr<FrameInfo> frame_;

  FML_FRIEND_MAKE_REF_COUNTED(SingleFrameCodec);
  FML_FRIEND_REF_COUNTED_THREAD_SAFE(SingleFrameCodec);
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_CODEC_H_
