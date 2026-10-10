// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_IMAGE_GENERATOR_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_IMAGE_GENERATOR_H_

#include <jni.h>

#include <cstddef>
#include <cstdint>
#include <functional>
#include <memory>
#include <optional>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/task_runner.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

namespace testing {
FML_TEST_CLASS(AndroidImageGenerator, HeaderDecodeDimensionMismatch);
}

class AndroidImageGenerator {
 private:
  explicit AndroidImageGenerator(std::vector<uint8_t> buffer);

 public:
  ~AndroidImageGenerator();

  const FlutterImageGeneratorInfo& GetInfo();

  uint32_t GetFrameCount() const;

  uint32_t GetPlayCount() const;

  FlutterImageGeneratorFrameInfo GetFrameInfo(uint32_t frame_index);

  bool GetScaledDimensions(float desired_scale,
                           uint32_t* scaled_width_out,
                           uint32_t* scaled_height_out);

  bool GetPixels(const FlutterImageGeneratorInfo& info,
                 void* pixels,
                 size_t row_bytes,
                 uint32_t frame_index = 0,
                 std::optional<uint32_t> prior_frame = std::nullopt);

  void DecodeImage();

  static bool Register(JNIEnv* env);

  static std::shared_ptr<AndroidImageGenerator> MakeFromData(
      std::vector<uint8_t> data,
      const fml::RefPtr<fml::TaskRunner>& task_runner);

  static FlutterImageGeneratorRegistrationInfo
  MakeFlutterImageGeneratorRegistrationInfo(
      fml::RefPtr<fml::TaskRunner> task_runner,
      int32_t priority);

  static void NativeImageHeaderCallback(JNIEnv* env,
                                        jclass jcaller,
                                        jlong generator_pointer,
                                        int width,
                                        int height);

 private:
  FML_FRIEND_TEST(testing::AndroidImageGenerator,
                  HeaderDecodeDimensionMismatch);

  std::vector<uint8_t> data_;
  const void* software_decoded_data_ = nullptr;
  size_t software_decoded_size_ = 0;
  std::function<void()> software_decoded_release_;

  FlutterImageGeneratorInfo image_info_ = {};
  bool header_valid_ = false;

  /// Blocks until the header of the image has been decoded and the image
  /// dimensions have been determined.
  fml::ManualResetWaitableEvent header_decoded_latch_;

  /// Blocks until the image has been fully decoded.
  fml::ManualResetWaitableEvent fully_decoded_latch_;

  static std::shared_ptr<AndroidImageGenerator> MakeForTesting(
      const FlutterImageGeneratorInfo& header_info,
      std::vector<uint8_t> decoded_data);

  void DoDecodeImage();

  bool IsValidImageData();

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(AndroidImageGenerator);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_IMAGE_GENERATOR_H_
