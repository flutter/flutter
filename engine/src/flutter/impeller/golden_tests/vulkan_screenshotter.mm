// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/golden_tests/vulkan_screenshotter.h"

#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/impeller/golden_tests/metal_screenshot.h"
#include "impeller/renderer/backend/vulkan/surface_context_vk.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"
#define GLFW_INCLUDE_NONE
#include "third_party/glfw/include/GLFW/glfw3.h"

namespace impeller {
namespace testing {

namespace {
std::unique_ptr<Screenshot> ReadTexture(
    const std::shared_ptr<Context>& surface_context,
    const std::shared_ptr<Texture>& texture) {
  DeviceBufferDescriptor buffer_desc;
  buffer_desc.storage_mode = StorageMode::kHostVisible;
  buffer_desc.size =
      texture->GetTextureDescriptor().GetByteSizeOfBaseMipLevel();
  std::shared_ptr<DeviceBuffer> device_buffer =
      surface_context->GetResourceAllocator()->CreateBuffer(buffer_desc);
  FML_CHECK(device_buffer);

  auto command_buffer = surface_context->CreateCommandBuffer();
  auto blit_pass = command_buffer->CreateBlitPass();
  bool success = blit_pass->AddCopy(texture, device_buffer);
  FML_CHECK(success);

  success = blit_pass->EncodeCommands(surface_context->GetResourceAllocator());
  FML_CHECK(success);

  fml::AutoResetWaitableEvent latch;
  success =
      command_buffer->SubmitCommands([&latch](CommandBuffer::Status status) {
        FML_CHECK(status == CommandBuffer::Status::kCompleted);
        latch.Signal();
      });
  FML_CHECK(success);
  latch.Wait();

  // TODO(gaaclarke): Replace CoreImage requirement with something
  // crossplatform.

  CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
  CGBitmapInfo bitmap_info =
      kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little;
  CGContextRef context = CGBitmapContextCreate(
      device_buffer->OnGetContents(), texture->GetSize().width,
      texture->GetSize().height,
      /*bitsPerComponent=*/8,
      /*bytesPerRow=*/texture->GetTextureDescriptor().GetBytesPerRow(),
      color_space, bitmap_info);
  FML_CHECK(context);
  CGImageRef image_ref = CGBitmapContextCreateImage(context);
  FML_CHECK(image_ref);
  CGContextRelease(context);
  CGColorSpaceRelease(color_space);
  return std::make_unique<MetalScreenshot>(image_ref);
}
}  // namespace

VulkanScreenshotter::VulkanScreenshotter() {
  FML_CHECK(::glfwInit() == GLFW_TRUE);
  playground_ =
      PlaygroundImpl::Create(PlaygroundBackend::kVulkan, PlaygroundSwitches{});
}

std::unique_ptr<Screenshot> VulkanScreenshotter::MakeScreenshot(
    AiksContext& aiks_context,
    const Picture& picture,
    const ISize& size,
    bool scale_content) {
  Vector2 content_scale =
      scale_content ? playground_->GetContentScale() : Vector2{1, 1};
  std::shared_ptr<Image> image = picture.ToImage(
      aiks_context,
      ISize(size.width * content_scale.x, size.height * content_scale.y));
  std::shared_ptr<Texture> texture = image->GetTexture();
  FML_CHECK(aiks_context.GetContext()->GetBackendType() ==
            Context::BackendType::kVulkan);
  return ReadTexture(aiks_context.GetContext(), texture);
}

}  // namespace testing
}  // namespace impeller
