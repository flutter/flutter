
#include "flutter/shell/platform/android/image_external_texture_vk.h"

#include "flutter/impeller/core/formats.h"
#include "flutter/impeller/core/texture_descriptor.h"
#include "flutter/impeller/display_list/dl_image_impeller.h"
#include "flutter/impeller/renderer/backend/vulkan/android_hardware_buffer_texture_source_vk.h"
#include "flutter/impeller/renderer/backend/vulkan/texture_vk.h"
#include "flutter/shell/platform/android/ndk_helpers.h"

namespace flutter {

ImageExternalTextureVK::ImageExternalTextureVK(
    const std::shared_ptr<impeller::ContextVK>& impeller_context,
    int64_t id,
    const fml::jni::ScopedJavaGlobalRef<jobject>& image_texture_entry,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade)
    : ImageExternalTexture(id, image_texture_entry, jni_facade),
      impeller_context_(impeller_context) {}

ImageExternalTextureVK::~ImageExternalTextureVK() {}

void ImageExternalTextureVK::Attach(PaintContext& context) {
  if (state_ == AttachmentState::kUninitialized) {
    // First processed frame we are attached.
    state_ = AttachmentState::kAttached;
  }
}

void ImageExternalTextureVK::Detach() {}

void ImageExternalTextureVK::ProcessFrame(PaintContext& context,
                                          const SkRect& bounds) {
  JavaLocalRef image = AcquireLatestImage();
  if (image.is_null()) {
    return;
  }
  JavaLocalRef old_android_image(android_image_);
  android_image_.Reset(image);
  JavaLocalRef hardware_buffer = HardwareBufferFor(android_image_);
  AHardwareBuffer* latest_hardware_buffer = AHardwareBufferFor(hardware_buffer);

  AHardwareBuffer_Desc hb_desc = {};
  flutter::NDKHelpers::AHardwareBuffer_describe(latest_hardware_buffer,
                                                &hb_desc);

  impeller::TextureDescriptor desc;
  desc.storage_mode = impeller::StorageMode::kDevicePrivate;
  desc.size = {static_cast<int>(bounds.width()),
               static_cast<int>(bounds.height())};
  // TODO(johnmccutchan): Use hb_desc to compute the correct format at runtime.
  desc.format = impeller::PixelFormat::kR8G8B8A8UNormInt;
  desc.mip_count = 1;

  auto texture_source =
      std::make_shared<impeller::AndroidHardwareBufferTextureSourceVK>(
          desc, impeller_context_->GetDevice(), latest_hardware_buffer,
          hb_desc);

  auto texture =
      std::make_shared<impeller::TextureVK>(impeller_context_, texture_source);

  dl_image_ = impeller::DlImageImpeller::Make(texture);
  CloseHardwareBuffer(hardware_buffer);
  // IMPORTANT: We only close the old image after texture stops referencing
  // it.
  CloseImage(old_android_image);
}

}  // namespace flutter
