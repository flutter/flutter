// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/image_lru.h"

#include <utility>

namespace flutter {

sk_sp<flutter::DlImage> ImageLRU::FindImage(
    std::optional<HardwareBufferKey> key,
    const AHardwareBuffer_Desc& descriptor,
    const std::function<void(HardwareBufferKey)>& on_evict) {
  frame_++;
  sk_sp<flutter::DlImage> result;
  if (key.has_value()) {
    for (size_t i = 0u; i < kImageReaderSwapchainSize; i++) {
      const auto& entry = images_[i];
      if (entry.key == key.value()) {
        result = entry.value;
        UpdateKey(i);
        break;
      }
    }
  }
  if (!result) {
    if (descriptor.width != descriptor_.width ||
        descriptor.height != descriptor_.height ||
        descriptor.format != descriptor_.format) {
      Clear(on_evict);
    }
    descriptor_ = descriptor;
  }
  // Entries are ordered from most to least recently used.
  for (auto it = images_.rbegin(); it != images_.rend(); ++it) {
    if (!it->value) {
      continue;
    }
    if (frame_ - it->last_used_frame < 2 * kImageReaderSwapchainSize) {
      break;
    }
    if (on_evict) {
      on_evict(it->key);
    }
    *it = {};
  }
  return result;
}

void ImageLRU::UpdateKey(size_t index) {
  if (index > 0u) {
    auto entry = std::move(images_[index]);
    for (auto j = index; j > 0; j--) {
      images_[j] = std::move(images_[j - 1]);
    }
    images_[0] = std::move(entry);
  }
  images_[0].last_used_frame = frame_;
}

HardwareBufferKey ImageLRU::AddImage(const sk_sp<flutter::DlImage>& image,
                                     HardwareBufferKey key) {
  HardwareBufferKey lru_key = images_.back().key;
  images_.back() = Data{.key = key, .value = image};
  UpdateKey(images_.size() - 1);
  return lru_key;
}

void ImageLRU::Clear(const std::function<void(HardwareBufferKey)>& on_evict) {
  for (auto& entry : images_) {
    if (entry.value && on_evict) {
      on_evict(entry.key);
    }
    entry = {};
  }
  descriptor_ = {};
}

}  // namespace flutter
