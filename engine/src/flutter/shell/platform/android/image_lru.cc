// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/image_lru.h"

#include "flutter/fml/trace_event.h"

namespace flutter {

sk_sp<flutter::DlImage> ImageLRU::FindImage(
    std::optional<HardwareBufferKey> key) {
  TRACE_EVENT0("flutter", "ImageLRU::FindImage");
  if (!key.has_value() || key.value() == 0u) {
    return nullptr;
  }
  std::scoped_lock lock(mutex_);
  auto key_value = key.value();
  for (size_t i = 0u; i < kImageReaderSwapchainSize; i++) {
    if (images_[i].key == key_value) {
      auto result = images_[i].value;
      UpdateKey(result, key_value);
      return result;
    }
  }
  return nullptr;
}

void ImageLRU::UpdateKey(const sk_sp<flutter::DlImage>& image,
                         HardwareBufferKey key) {
  TRACE_EVENT0("flutter", "ImageLRU::UpdateKey");
  if (images_[0].key == key) {
    images_[0].value = image;
    return;
  }
  size_t i = 1u;
  for (; i < kImageReaderSwapchainSize; i++) {
    if (images_[i].key == key) {
      break;
    }
  }
  if (i >= kImageReaderSwapchainSize) {
    return;
  }
  for (auto j = i; j > 0; j--) {
    images_[j] = images_[j - 1];
  }
  images_[0] = Data{.key = key, .value = image};
}

HardwareBufferKey ImageLRU::AddImage(const sk_sp<flutter::DlImage>& image,
                                     HardwareBufferKey key) {
  TRACE_EVENT0("flutter", "ImageLRU::AddImage");
  if (key == 0u) {
    return 0u;
  }
  std::scoped_lock lock(mutex_);
  for (size_t i = 0u; i < kImageReaderSwapchainSize; i++) {
    if (images_[i].key == key) {
      images_[i].value = image;
      UpdateKey(image, key);
      return 0u;
    }
  }
  HardwareBufferKey lru_key = images_[kImageReaderSwapchainSize - 1].key;
  images_[kImageReaderSwapchainSize - 1] = Data{.key = key, .value = image};
  UpdateKey(image, key);
  return lru_key;
}

void ImageLRU::Clear() {
  TRACE_EVENT0("flutter", "ImageLRU::Clear");
  std::scoped_lock lock(mutex_);
  for (size_t i = 0u; i < kImageReaderSwapchainSize; i++) {
    images_[i] = Data{.key = 0u, .value = nullptr};
  }
}

}  // namespace flutter
