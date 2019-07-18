// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/single_frame_codec.h"

#include "flutter/lib/ui/painting/frame_info.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/tonic/logging/dart_invoke.h"

namespace flutter {

SingleFrameCodec::SingleFrameCodec(ImageDecoder::ImageDescriptor descriptor)
    : status_(Status::kNew), descriptor_(std::move(descriptor)) {}

SingleFrameCodec::~SingleFrameCodec() = default;

int SingleFrameCodec::frameCount() const {
  return 1;
}

int SingleFrameCodec::repetitionCount() const {
  return 0;
}

Dart_Handle SingleFrameCodec::getNextFrame(Dart_Handle callback_handle) {
  if (!Dart_IsClosure(callback_handle)) {
    return tonic::ToDart("Callback must be a function");
  }

  if (status_ == Status::kComplete) {
    tonic::DartInvoke(callback_handle, {tonic::ToDart(cached_frame_)});
    return Dart_Null();
  }

  // This has to be valid because this method is called from Dart.
  auto dart_state = UIDartState::Current();

  pending_callbacks_.emplace_back(dart_state, callback_handle);

  if (status_ == Status::kInProgress) {
    // Another call to getNextFrame is in progress and will invoke the
    // pending callbacks when decoding completes.
    return Dart_Null();
  }

  auto decoder = dart_state->GetImageDecoder();

  if (!decoder) {
    return tonic::ToDart("Image decoder not available.");
  }

  auto raw_codec_wrapper = new DartPersistentValue(
      dart_state, Dart_HandleFromWeakPersistent(dart_wrapper()));

  // We dont want to to put the raw codec in a lambda capture because we have
  // to mutate (i.e destroy) it in the callback. Using MakeCopyable will create
  // a shared pointer for the captures which can be destroyed on any thread. But
  // we have to ensure that the DartPersistentValue is only destroyed on the UI
  // thread.
  decoder->Decode(descriptor_, [raw_codec_wrapper](auto image) {
    std::unique_ptr<DartPersistentValue> codec_wrapper(raw_codec_wrapper);

    auto state = codec_wrapper->dart_state().lock();

    if (!state) {
      // This is probably because the isolate has been terminated before the
      // image could be decoded.

      return;
    }

    tonic::DartState::Scope scope(state.get());

    SingleFrameCodec* codec = tonic::DartConverter<SingleFrameCodec*>::FromDart(
        codec_wrapper->value());

    if (image.get()) {
      auto canvas_image = fml::MakeRefCounted<CanvasImage>();
      canvas_image->set_image(std::move(image));

      codec->cached_frame_ = fml::MakeRefCounted<FrameInfo>(
          std::move(canvas_image), 0 /* duration */);
    }

    // The cached frame is now available and should be returned to any future
    // callers.
    codec->status_ = Status::kComplete;

    // Invoke any callbacks that were provided before the frame was decoded.
    Dart_Handle frame = tonic::ToDart(codec->cached_frame_);
    for (const DartPersistentValue& callback : codec->pending_callbacks_) {
      tonic::DartInvoke(callback.value(), {frame});
    }
    codec->pending_callbacks_.clear();
  });

  // The encoded data is no longer needed now that it has been handed off
  // to the decoder.
  descriptor_.data.reset();

  status_ = Status::kInProgress;

  return Dart_Null();
}

size_t SingleFrameCodec::GetAllocationSize() {
  const auto& data = descriptor_.data;
  const auto data_byte_size = data ? data->size() : 0;
  const auto frame_byte_size = (cached_frame_ && cached_frame_->image())
                                   ? cached_frame_->image()->GetAllocationSize()
                                   : 0;
  return data_byte_size + frame_byte_size + sizeof(this);
}

}  // namespace flutter
