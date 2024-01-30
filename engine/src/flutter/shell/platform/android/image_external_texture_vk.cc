
#include "flutter/shell/platform/android/image_external_texture_vk.h"
#include <cstdint>

#include "flutter/impeller/core/formats.h"
#include "flutter/impeller/core/texture_descriptor.h"
#include "flutter/impeller/display_list/dl_image_impeller.h"
#include "flutter/impeller/renderer/backend/vulkan/android_hardware_buffer_texture_source_vk.h"
#include "flutter/impeller/renderer/backend/vulkan/command_buffer_vk.h"
#include "flutter/impeller/renderer/backend/vulkan/command_encoder_vk.h"
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
  JavaLocalRef old_android_image(latest_android_image_);
  latest_android_image_.Reset(image);
  JavaLocalRef hardware_buffer = HardwareBufferFor(latest_android_image_);
  AHardwareBuffer* latest_hardware_buffer = AHardwareBufferFor(hardware_buffer);

  AHardwareBuffer_Desc hb_desc = {};
  flutter::NDKHelpers::AHardwareBuffer_describe(latest_hardware_buffer,
                                                &hb_desc);
  std::optional<HardwareBufferKey> key =
      flutter::NDKHelpers::AHardwareBuffer_getId(latest_hardware_buffer);
  auto existing_image = image_lru_.FindImage(key);
  if (existing_image != nullptr) {
    dl_image_ = existing_image;

    CloseHardwareBuffer(hardware_buffer);
    // IMPORTANT: We have just received a new frame to display so close the
    // previous Java Image so that it is recycled and used for a future frame.
    CloseImage(old_android_image);
    return;
  }

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
  // Transition the layout to shader read.
  {
    auto buffer = impeller_context_->CreateCommandBuffer();
    impeller::CommandBufferVK& buffer_vk =
        impeller::CommandBufferVK::Cast(*buffer);

    impeller::BarrierVK barrier;
    barrier.cmd_buffer = buffer_vk.GetEncoder()->GetCommandBuffer();
    barrier.src_access = impeller::vk::AccessFlagBits::eColorAttachmentWrite |
                         impeller::vk::AccessFlagBits::eTransferWrite;
    barrier.src_stage =
        impeller::vk::PipelineStageFlagBits::eColorAttachmentOutput |
        impeller::vk::PipelineStageFlagBits::eTransfer;
    barrier.dst_access = impeller::vk::AccessFlagBits::eShaderRead;
    barrier.dst_stage = impeller::vk::PipelineStageFlagBits::eFragmentShader;

    barrier.new_layout = impeller::vk::ImageLayout::eShaderReadOnlyOptimal;

    if (!texture->SetLayout(barrier)) {
      return;
    }
    if (!buffer->SubmitCommands()) {
      return;
    }
  }

  dl_image_ = impeller::DlImageImpeller::Make(texture);
  if (key.has_value()) {
    image_lru_.AddImage(dl_image_, key.value());
  }
  CloseHardwareBuffer(hardware_buffer);
  // IMPORTANT: We have just received a new frame to display so close the
  // previous Java Image so that it is recycled and used for a future frame.
  CloseImage(old_android_image);
}

}  // namespace flutter
