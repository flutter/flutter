
#include "flutter/shell/platform/android/hardware_buffer_external_texture_vk.h"

#include "flutter/impeller/renderer/backend/vulkan/android_hardware_buffer_texture_source_vk.h"
#include "flutter/impeller/renderer/backend/vulkan/texture_vk.h"
#include "flutter/shell/platform/android/ndk_helpers.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/display_list/dl_image_impeller.h"

namespace flutter {

HardwareBufferExternalTextureVK::HardwareBufferExternalTextureVK(
    const std::shared_ptr<impeller::ContextVK>& impeller_context,
    int64_t id,
    const fml::jni::ScopedJavaGlobalRef<jobject>& image_texture_entry,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade)
    : HardwareBufferExternalTexture(id, image_texture_entry, jni_facade),
      impeller_context_(impeller_context) {}

HardwareBufferExternalTextureVK::~HardwareBufferExternalTextureVK() {}

void HardwareBufferExternalTextureVK::ProcessFrame(PaintContext& context,
                                                   const SkRect& bounds) {
  if (state_ == AttachmentState::kUninitialized) {
    // First processed frame we are attached.
    state_ = AttachmentState::kAttached;
  }

  AHardwareBuffer* latest_hardware_buffer = GetLatestHardwareBuffer();
  if (latest_hardware_buffer == nullptr) {
    FML_LOG(WARNING) << "GetLatestHardwareBuffer returned null.";
    return;
  }

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

  // GetLatestHardwareBuffer keeps a reference on the hardware buffer, drop it.
  NDKHelpers::AHardwareBuffer_release(latest_hardware_buffer);
}

void HardwareBufferExternalTextureVK::Detach() {}

}  // namespace flutter
