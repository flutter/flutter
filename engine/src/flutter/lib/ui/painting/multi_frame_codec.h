// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_MULTI_FRAME_CODEC_H_
#define FLUTTER_LIB_UI_PAINTING_MULTI_FRAME_CODEC_H_

#include "flutter/fml/macros.h"
#include "flutter/lib/ui/painting/codec.h"
#include "flutter/lib/ui/painting/image_generator.h"
#include "third_party/skia/include/core/SkSize.h"

#include <utility>

namespace flutter {

class MultiFrameCodec : public Codec {
 public:
  /// @brief Creates a codec for an animated (multi-frame) image.
  ///
  /// @param[in] generator    The decoder for the encoded image.
  /// @param[in] target_size  The size at which frames are delivered to Dart,
  ///                         as requested through `targetWidth` and
  ///                         `targetHeight`. Frames are always decoded and
  ///                         composited at the intrinsic size of the image,
  ///                         so that blending and disposal stay exact, and
  ///                         only the finished frame is resized.
  MultiFrameCodec(std::shared_ptr<ImageGenerator> generator,
                  SkISize target_size);

  ~MultiFrameCodec() override;

  // |Codec|
  int frameCount() const override;

  // |Codec|
  int repetitionCount() const override;

  // |Codec|
  Dart_Handle getNextFrame(Dart_Handle args) override;

 private:
  // Captures the state shared between the IO and UI task runners.
  //
  // The state is initialized on the UI task runner when the Dart object is
  // created. Decoding occurs on the IO task runner. Since it is possible for
  // the UI object to be collected independently of the IO task runner work,
  // it is not safe for this state to live directly on the MultiFrameCodec.
  // Instead, the MultiFrameCodec creates this object when it is constructed,
  // shares it with the IO task runner's decoding work, and sets the live_
  // member to false when it is destructed.
  struct State {
    State(std::shared_ptr<ImageGenerator> generator, SkISize target_size);

    const std::shared_ptr<ImageGenerator> generator_;
    const int frameCount_;
    const int repetitionCount_;
    bool is_impeller_enabled_ = false;
    // The size of the frames delivered to Dart, as requested through
    // `targetWidth` and `targetHeight`.
    const SkISize target_size_;

    // The non-const members and functions below here are only read or written
    // to on the IO thread. They are not safe to access or write on the UI
    // thread.
    int nextFrameIndex_ = 0;
    // The last decoded frame that's required to decode any subsequent frames.
    std::optional<SkBitmap> lastRequiredFrame_;
    // The index of the last decoded required frame.
    int lastRequiredFrameIndex_ = -1;

    // The rectangle that should be cleared if the previous frame's disposal
    // method was kRestoreBGColor.
    std::optional<SkIRect> restoreBGColorRect_;

    std::pair<sk_sp<DlImage>, std::string> GetNextFrameImage(
        const fml::WeakPtr<GrDirectContext>& resourceContext,
        const std::shared_ptr<const fml::SyncSwitch>& gpu_disable_sync_switch,
        const std::shared_ptr<impeller::Context>& impeller_context,
        const fml::RefPtr<flutter::SkiaUnrefQueue>& unref_queue);

    void GetNextFrameAndInvokeCallback(
        std::unique_ptr<tonic::DartPersistentValue> callback,
        const fml::RefPtr<fml::TaskRunner>& ui_task_runner,
        const fml::WeakPtr<GrDirectContext>& resourceContext,
        const fml::RefPtr<flutter::SkiaUnrefQueue>& unref_queue,
        const std::shared_ptr<const fml::SyncSwitch>& gpu_disable_sync_switch,
        size_t trace_id,
        const std::shared_ptr<impeller::Context>& impeller_context);
  };

  // Shared across the UI and IO task runners.
  std::shared_ptr<State> state_;

  FML_FRIEND_MAKE_REF_COUNTED(MultiFrameCodec);
  FML_FRIEND_REF_COUNTED_THREAD_SAFE(MultiFrameCodec);
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_MULTI_FRAME_CODEC_H_
