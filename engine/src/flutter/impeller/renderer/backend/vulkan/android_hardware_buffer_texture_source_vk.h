// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/build_config.h"
#include "vulkan/vulkan_core.h"

#ifdef FML_OS_ANDROID

#include "flutter/fml/macros.h"
#include "impeller/geometry/size.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/texture_source_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"

#include <android/hardware_buffer.h>
#include <android/hardware_buffer_jni.h>

namespace impeller {

class AndroidHardwareBufferTextureSourceVK final : public TextureSourceVK {
 public:
  AndroidHardwareBufferTextureSourceVK(
      TextureDescriptor desc,
      const vk::Device& device,
      struct AHardwareBuffer* hardware_buffer,
      const AHardwareBuffer_Desc& hardware_buffer_desc);

  // |TextureSourceVK|
  ~AndroidHardwareBufferTextureSourceVK() override;

  // |TextureSourceVK|
  vk::Image GetImage() const override;

  // |TextureSourceVK|
  vk::ImageView GetImageView() const override;

  bool IsValid() const;

 private:
  const vk::Device& device_;
  vk::Image image_ = VK_NULL_HANDLE;
  vk::UniqueImageView image_view_ = {};
  vk::DeviceMemory device_memory_ = VK_NULL_HANDLE;

  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidHardwareBufferTextureSourceVK);
};

}  // namespace impeller

#endif
