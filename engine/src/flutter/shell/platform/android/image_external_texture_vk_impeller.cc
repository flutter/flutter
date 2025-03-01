// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/image_external_texture_vk_impeller.h"

#include <cstdint>

#include "flutter/impeller/core/formats.h"
#include "flutter/impeller/core/texture_descriptor.h"
#include "flutter/impeller/display_list/dl_image_impeller.h"
#include "flutter/impeller/renderer/backend/vulkan/android/ahb_texture_source_vk.h"
#include "flutter/impeller/renderer/backend/vulkan/command_buffer_vk.h"
#include "flutter/impeller/renderer/backend/vulkan/texture_vk.h"
#include "flutter/impeller/toolkit/android/hardware_buffer.h"

namespace flutter {

ImageExternalTextureVKImpeller::ImageExternalTextureVKImpeller(
    const std::shared_ptr<impeller::ContextVK>& impeller_context,
    int64_t id,
    const fml::jni::ScopedJavaGlobalRef<jobject>& image_texture_entry,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade)
    : ImageExternalTexture(id, image_texture_entry, jni_facade),
      impeller_context_(impeller_context) {}

ImageExternalTextureVKImpeller::~ImageExternalTextureVKImpeller() {}

void ImageExternalTextureVKImpeller::Attach(PaintContext& context) {
  if (state_ == AttachmentState::kUninitialized) {
    // First processed frame we are attached.
    state_ = AttachmentState::kAttached;
  }
}

void ImageExternalTextureVKImpeller::Detach() {}

void ImageExternalTextureVKImpeller::ProcessFrame(PaintContext& context,
                                                  const SkRect& bounds) {
  JavaLocalRef image = AcquireLatestImage();
  if (image.is_null()) {
    return;
  }
  JavaLocalRef hardware_buffer = HardwareBufferFor(image);
  AHardwareBuffer* latest_hardware_buffer = AHardwareBufferFor(hardware_buffer);

  auto hb_desc =
      impeller::android::HardwareBuffer::Describe(latest_hardware_buffer);
  std::optional<HardwareBufferKey> key =
      impeller::android::HardwareBuffer::GetSystemUniqueID(
          latest_hardware_buffer);
  auto existing_image = image_lru_.FindImage(key);
  if (existing_image != nullptr || !hb_desc.has_value()) {
    dl_image_ = existing_image;
    CloseHardwareBuffer(hardware_buffer);
    return;
  }

  auto texture_source = std::make_shared<impeller::AHBTextureSourceVK>(
      impeller_context_, latest_hardware_buffer, hb_desc.value());
  if (!texture_source->IsValid()) {
    CloseHardwareBuffer(hardware_buffer);
    return;
  }

  auto texture = std::make_shared<impeller::TextureVK>(
      impeller_context_, texture_source, /*is_external_texture=*/true);

  dl_image_ = impeller::DlImageImpeller::Make(texture);
  if (key.has_value()) {
    image_lru_.AddImage(dl_image_, key.value());
  }
  CloseHardwareBuffer(hardware_buffer);
}

}  // namespace flutter
