// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_SINGLE_FRAME_CODEC_H_
#define FLUTTER_LIB_UI_PAINTING_SINGLE_FRAME_CODEC_H_

#include "flutter/fml/macros.h"
#include "flutter/lib/ui/painting/codec.h"
#include "flutter/lib/ui/painting/image.h"
#include "flutter/lib/ui/painting/image_decoder.h"

namespace flutter {

class SingleFrameCodec : public Codec {
 public:
  static fml::RefPtr<SingleFrameCodec> Create(
      Dart_Handle codec_handle,
      ImageDecoder::ImageDescriptor descriptor) {
    auto codec = fml::MakeRefCounted<SingleFrameCodec>(std::move(descriptor));
    codec->AssociateWithDartWrapper(codec_handle);
    return codec;
  }
  ~SingleFrameCodec() override;

  // |Codec|
  int frameCount() const override;

  // |Codec|
  int repetitionCount() const override;

  // |Codec|
  Dart_Handle getNextFrame(Dart_Handle image_handle,
                           Dart_Handle callback_handle) override;

  // |DartWrappable|
  size_t GetAllocationSize() override;

 private:
  SingleFrameCodec(ImageDecoder::ImageDescriptor descriptor);
  enum class Status { kNew, kInProgress, kComplete };
  Status status_;
  ImageDecoder::ImageDescriptor descriptor_;
  size_t cached_frame_image_size_;
  std::vector<DartPersistentValue> pending_callbacks_;

  FML_FRIEND_MAKE_REF_COUNTED(SingleFrameCodec);
  FML_FRIEND_REF_COUNTED_THREAD_SAFE(SingleFrameCodec);
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_SINGLE_FRAME_CODEC_H_
