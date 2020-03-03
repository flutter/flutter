// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_MUTLI_FRAME_CODEC_H_
#define FLUTTER_LIB_UI_PAINTING_MUTLI_FRAME_CODEC_H_

#include "flutter/flow/skia_gpu_object.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/lib/ui/painting/codec.h"
#include "flutter/lib/ui/painting/image.h"

namespace flutter {

class MultiFrameCodec : public Codec {
 public:
  static fml::RefPtr<MultiFrameCodec> Create(Dart_Handle codec_handle,
                                             std::unique_ptr<SkCodec> codec) {
    auto multi_frame_codec =
        fml::MakeRefCounted<MultiFrameCodec>(std::move(codec));
    multi_frame_codec->AssociateWithDartWrapper(codec_handle);
    return multi_frame_codec;
  }
  ~MultiFrameCodec() override;

  // |Codec|
  int frameCount() const override;

  // |Codec|
  int repetitionCount() const override;

  // |Codec|
  Dart_Handle getNextFrame(Dart_Handle image_handle, Dart_Handle args) override;

 private:
  MultiFrameCodec(std::unique_ptr<SkCodec> codec);
  const std::unique_ptr<SkCodec> codec_;
  const int frameCount_;
  const int repetitionCount_;
  int nextFrameIndex_;

  // The last decoded frame that's required to decode any subsequent frames.
  std::unique_ptr<SkBitmap> lastRequiredFrame_;
  // The index of the last decoded required frame.
  int lastRequiredFrameIndex_ = -1;

  sk_sp<SkImage> GetNextFrameImage(fml::WeakPtr<GrContext> resourceContext);

  void GetNextFrameAndInvokeCallback(
      fml::RefPtr<CanvasImage> canvas_image,
      std::unique_ptr<DartPersistentValue> callback,
      fml::RefPtr<fml::TaskRunner> ui_task_runner,
      fml::WeakPtr<GrContext> resourceContext,
      fml::RefPtr<flutter::SkiaUnrefQueue> unref_queue,
      size_t trace_id);

  FML_FRIEND_MAKE_REF_COUNTED(MultiFrameCodec);
  FML_FRIEND_REF_COUNTED_THREAD_SAFE(MultiFrameCodec);
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_MUTLI_FRAME_CODEC_H_
