// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_IMAGE_LRU_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_IMAGE_LRU_H_

#include <array>
#include <cstddef>
#include <functional>

#include <android/hardware_buffer.h>

#include "display_list/image/dl_image.h"

namespace flutter {

// Android BufferQueue supports at most 64 slots
// (`BufferQueueDefs::NUM_BUFFER_SLOTS`):
// https://android.googlesource.com/platform/frameworks/native/+/refs/heads/main/libs/ui/include/ui/BufferQueueDefs.h
//
// Matching that limit lets a stable producer buffer pool be retained without
// evicting reusable imports. Images are retained only as buffer IDs are
// observed; once all slots are occupied, normal LRU eviction keeps retention
// bounded.
static constexpr size_t kImageReaderSwapchainSize = 64u;

using HardwareBufferKey = uint64_t;

class ImageLRU {
 public:
  ImageLRU() = default;

  ~ImageLRU() = default;

  /// @brief Look up one acquired frame, expiring images unused for twice the
  ///        cache capacity in acquired frames.
  ///        On a miss, a changed buffer size or format invalidates the cache.
  ///        [on_evict] releases any additional resources for removed images.
  sk_sp<flutter::DlImage> FindImage(
      std::optional<HardwareBufferKey> key,
      const AHardwareBuffer_Desc& descriptor,
      const std::function<void(HardwareBufferKey)>& on_evict = {});

  /// @brief Add a new image to the cache with a key, returning the key of the
  ///        LRU entry that was removed.
  ///
  /// The value may be `0`, in which case nothing was removed.
  HardwareBufferKey AddImage(const sk_sp<flutter::DlImage>& image,
                             HardwareBufferKey key);

  /// @brief Remove all entires from the image cache.
  void Clear(const std::function<void(HardwareBufferKey)>& on_evict = {});

 private:
  /// @brief Marks the entry at [index] as the most recently used.
  void UpdateKey(size_t index);

  struct Data {
    HardwareBufferKey key = 0u;
    sk_sp<flutter::DlImage> value;
    uint64_t last_used_frame = 0u;
  };

  std::array<Data, kImageReaderSwapchainSize> images_;
  AHardwareBuffer_Desc descriptor_ = {};
  uint64_t frame_ = 0u;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_IMAGE_LRU_H_
