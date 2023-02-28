// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/swapchain_impl_vk.h"

#include "impeller/renderer/backend/vulkan/command_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/command_encoder_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/surface_vk.h"
#include "impeller/renderer/backend/vulkan/swapchain_image_vk.h"

namespace impeller {

static constexpr size_t kMaxFramesInFlight = 3u;

struct FrameSynchronizer {
  vk::UniqueFence acquire;
  vk::UniqueSemaphore render_ready;
  vk::UniqueSemaphore present_ready;
  bool is_valid = false;

  explicit FrameSynchronizer(const vk::Device& device) {
    auto acquire_res = device.createFenceUnique(
        vk::FenceCreateInfo{vk::FenceCreateFlagBits::eSignaled});
    auto render_res = device.createSemaphoreUnique({});
    auto present_res = device.createSemaphoreUnique({});
    if (acquire_res.result != vk::Result::eSuccess ||
        render_res.result != vk::Result::eSuccess ||
        present_res.result != vk::Result::eSuccess) {
      VALIDATION_LOG << "Could not create synchornizer.";
      return;
    }
    acquire = std::move(acquire_res.value);
    render_ready = std::move(render_res.value);
    present_ready = std::move(present_res.value);
    is_valid = true;
  }

  ~FrameSynchronizer() = default;

  bool WaitForFence(const vk::Device& device) {
    if (device.waitForFences(
            *acquire,                             // fence
            true,                                 // wait all
            std::numeric_limits<uint64_t>::max()  // timeout (ns)
            ) != vk::Result::eSuccess) {
      return false;
    }
    if (device.resetFences(*acquire) != vk::Result::eSuccess) {
      return false;
    }
    return true;
  }
};

static bool ContainsFormat(const std::vector<vk::SurfaceFormatKHR>& formats,
                           vk::SurfaceFormatKHR format) {
  return std::find(formats.begin(), formats.end(), format) != formats.end();
}

static std::optional<vk::SurfaceFormatKHR> ChooseSurfaceFormat(
    const std::vector<vk::SurfaceFormatKHR>& formats,
    PixelFormat preference) {
  const auto colorspace = vk::ColorSpaceKHR::eSrgbNonlinear;
  const auto vk_preference =
      vk::SurfaceFormatKHR{ToVKImageFormat(preference), colorspace};
  if (ContainsFormat(formats, vk_preference)) {
    return vk_preference;
  }

  std::vector<vk::SurfaceFormatKHR> options = {
      {vk::Format::eB8G8R8A8Unorm, colorspace},
      {vk::Format::eR8G8B8A8Unorm, colorspace}};
  for (const auto& format : options) {
    if (ContainsFormat(formats, format)) {
      return format;
    }
  }

  return std::nullopt;
}

static std::optional<vk::CompositeAlphaFlagBitsKHR> ChooseAlphaCompositionMode(
    vk::CompositeAlphaFlagsKHR flags) {
  if (flags & vk::CompositeAlphaFlagBitsKHR::ePreMultiplied) {
    return vk::CompositeAlphaFlagBitsKHR::ePreMultiplied;
  }
  if (flags & vk::CompositeAlphaFlagBitsKHR::eOpaque) {
    return vk::CompositeAlphaFlagBitsKHR::eOpaque;
  }
  return std::nullopt;
}

static std::optional<vk::Queue> ChoosePresentQueue(
    const vk::PhysicalDevice& physical_device,
    const vk::Device& device,
    const vk::SurfaceKHR& surface) {
  const auto families = physical_device.getQueueFamilyProperties();
  for (size_t family_index = 0u; family_index < families.size();
       family_index++) {
    auto [result, supported] =
        physical_device.getSurfaceSupportKHR(family_index, surface);
    if (result == vk::Result::eSuccess && supported) {
      return device.getQueue(family_index, 0u);
    }
  }
  return std::nullopt;
}

std::shared_ptr<SwapchainImplVK> SwapchainImplVK::Create(
    const std::shared_ptr<Context>& context,
    vk::UniqueSurfaceKHR surface,
    vk::SwapchainKHR old_swapchain) {
  return std::shared_ptr<SwapchainImplVK>(
      new SwapchainImplVK(context, std::move(surface), old_swapchain));
}

SwapchainImplVK::SwapchainImplVK(const std::shared_ptr<Context>& context,
                                 vk::UniqueSurfaceKHR surface,
                                 vk::SwapchainKHR old_swapchain) {
  if (!context) {
    return;
  }

  const auto& vk_context = ContextVK::Cast(*context);

  auto [caps_result, caps] =
      vk_context.GetPhysicalDevice().getSurfaceCapabilitiesKHR(*surface);
  if (caps_result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not get surface capabilities: "
                   << vk::to_string(caps_result);
    return;
  }

  auto [formats_result, formats] =
      vk_context.GetPhysicalDevice().getSurfaceFormatsKHR(*surface);
  if (formats_result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not get surface formats: "
                   << vk::to_string(formats_result);
    return;
  }

  const auto format = ChooseSurfaceFormat(
      formats, vk_context.GetDeviceCapabilities().GetDefaultColorFormat());
  if (!format.has_value()) {
    VALIDATION_LOG << "Swapchain has no supported formats.";
    return;
  }

  const auto composite =
      ChooseAlphaCompositionMode(caps.supportedCompositeAlpha);
  if (!composite.has_value()) {
    VALIDATION_LOG << "No composition mode supported.";
    return;
  }

  auto present_queue = ChoosePresentQueue(vk_context.GetPhysicalDevice(),  //
                                          vk_context.GetDevice(),          //
                                          *surface                         //
  );
  if (!present_queue.has_value()) {
    VALIDATION_LOG << "Could not pick present queue.";
    return;
  }

  vk::SwapchainCreateInfoKHR swapchain_info;
  swapchain_info.surface = *surface;
  swapchain_info.imageFormat = format.value().format;
  swapchain_info.imageColorSpace = format.value().colorSpace;
  swapchain_info.presentMode = vk::PresentModeKHR::eFifo;
  swapchain_info.imageExtent = vk::Extent2D{
      std::clamp(caps.currentExtent.width, caps.minImageExtent.width,
                 caps.maxImageExtent.width),
      std::clamp(caps.currentExtent.height, caps.minImageExtent.height,
                 caps.maxImageExtent.height),
  };
  swapchain_info.minImageCount = std::clamp(
      caps.minImageCount + 1u, caps.minImageCount, caps.maxImageCount);
  swapchain_info.imageArrayLayers = 1u;
  swapchain_info.imageUsage = vk::ImageUsageFlagBits::eColorAttachment;
  swapchain_info.preTransform = caps.currentTransform;
  swapchain_info.compositeAlpha = composite.value();
  // If we set the clipped value to true, Vulkan expects we will never read back
  // from the buffer. This is analogous to [CAMetalLayer framebufferOnly] in
  // Metal.
  swapchain_info.clipped = true;
  // Setting queue family indices is irrelevant since the present mode is
  // exclusive.
  swapchain_info.imageSharingMode = vk::SharingMode::eExclusive;
  swapchain_info.oldSwapchain = old_swapchain;

  auto [swapchain_result, swapchain] =
      vk_context.GetDevice().createSwapchainKHRUnique(swapchain_info);
  if (swapchain_result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create swapchain: "
                   << vk::to_string(swapchain_result);
    return;
  }

  auto [images_result, images] =
      vk_context.GetDevice().getSwapchainImagesKHR(*swapchain);
  if (images_result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not get swapchain images.";
    return;
  }

  std::vector<std::shared_ptr<SwapchainImageVK>> swapchain_images;
  for (const auto& image : images) {
    auto swapchain_image = std::make_shared<SwapchainImageVK>(
        vk_context.GetDevice(),                     //
        image,                                      //
        ToPixelFormat(swapchain_info.imageFormat),  //
        ISize::MakeWH(swapchain_info.imageExtent.width,
                      swapchain_info.imageExtent.height)  //
    );
    if (!swapchain_image->IsValid()) {
      VALIDATION_LOG << "Could not create swapchain image.";
      return;
    }
    swapchain_images.emplace_back(swapchain_image);
  }

  std::vector<std::unique_ptr<FrameSynchronizer>> synchronizers;
  for (size_t i = 0u; i < kMaxFramesInFlight; i++) {
    auto sync = std::make_unique<FrameSynchronizer>(vk_context.GetDevice());
    if (!sync->is_valid) {
      VALIDATION_LOG << "Could not create frame synchronizers.";
      return;
    }
    synchronizers.emplace_back(std::move(sync));
  }
  FML_DCHECK(!synchronizers.empty());

  context_ = context;
  surface_ = std::move(surface);
  present_queue_ = present_queue.value();
  surface_format_ = swapchain_info.imageFormat;
  swapchain_ = std::move(swapchain);
  images_ = std::move(swapchain_images);
  synchronizers_ = std::move(synchronizers);
  current_frame_ = synchronizers_.size() - 1u;
  is_valid_ = true;
}

SwapchainImplVK::~SwapchainImplVK() {
  DestroySwapchain();
}

bool SwapchainImplVK::IsValid() const {
  return is_valid_;
}

void SwapchainImplVK::WaitIdle() const {
  if (auto context = context_.lock()) {
    [[maybe_unused]] auto result =
        ContextVK::Cast(*context).GetDevice().waitIdle();
  }
}

std::pair<vk::UniqueSurfaceKHR, vk::UniqueSwapchainKHR>
SwapchainImplVK::DestroySwapchain() {
  WaitIdle();
  is_valid_ = false;
  synchronizers_.clear();
  images_.clear();
  context_.reset();
  return {std::move(surface_), std::move(swapchain_)};
}

vk::Format SwapchainImplVK::GetSurfaceFormat() const {
  return surface_format_;
}

std::shared_ptr<Context> SwapchainImplVK::GetContext() const {
  return context_.lock();
}

SwapchainImplVK::AcquireResult SwapchainImplVK::AcquireNextDrawable() {
  auto context_strong = context_.lock();
  if (!context_strong) {
    return {};
  }

  const auto& context = ContextVK::Cast(*context_strong);

  current_frame_ = (current_frame_ + 1u) % synchronizers_.size();

  const auto& sync = synchronizers_[current_frame_];

  //----------------------------------------------------------------------------
  /// Wait on the host for the synchronizer fence.
  ///
  if (!sync->WaitForFence(context.GetDevice())) {
    VALIDATION_LOG << "Could not wait for fence.";
    return {};
  }

  //----------------------------------------------------------------------------
  /// Get the next image index.
  ///
  auto [acq_result, index] = context.GetDevice().acquireNextImageKHR(
      *swapchain_,                           // swapchain
      std::numeric_limits<uint64_t>::max(),  // timeout (nanoseconds)
      *sync->render_ready,                   // signal semaphore
      nullptr                                // fence
  );

  if (acq_result == vk::Result::eSuboptimalKHR) {
    return AcquireResult{true /* out of date */};
  }

  if (acq_result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not acquire next swapchain image: "
                   << vk::to_string(acq_result);
    return {};
  }

  if (index >= images_.size()) {
    VALIDATION_LOG << "Swapchain returned an invalid image index.";
    return {};
  }

  auto image = images_[index % images_.size()];
  uint32_t image_index = index;
  return AcquireResult{SurfaceVK::WrapSwapchainImage(
      context_strong,  // context
      image,           // swapchain image
      [weak_swapchain = weak_from_this(), image, image_index]() -> bool {
        auto swapchain = weak_swapchain.lock();
        if (!swapchain) {
          return false;
        }
        return swapchain->Present(image, image_index);
      }  // swap callback
      )};
}

bool SwapchainImplVK::Present(const std::shared_ptr<SwapchainImageVK>& image,
                              uint32_t index) {
  auto context_strong = context_.lock();
  if (!context_strong) {
    return false;
  }

  const auto& context = ContextVK::Cast(*context_strong);

  const auto& sync = synchronizers_[current_frame_];

  //----------------------------------------------------------------------------
  /// Transition the image to color-attachment-optimal.
  ///
  {
    auto cmd_buffer = context.CreateCommandBuffer();
    if (!cmd_buffer) {
      return false;
    }

    auto vk_cmd_buffer =
        CommandBufferVK::Cast(*cmd_buffer).GetEncoder()->GetCommandBuffer();
    vk::ImageMemoryBarrier image_barrier;
    image_barrier.srcAccessMask = vk::AccessFlagBits::eColorAttachmentWrite;
    image_barrier.dstAccessMask = vk::AccessFlagBits::eColorAttachmentRead;
    image_barrier.image = image->GetVKImage();
    image_barrier.oldLayout = vk::ImageLayout::eColorAttachmentOptimal;
    image_barrier.newLayout = vk::ImageLayout::ePresentSrcKHR;
    image_barrier.subresourceRange.aspectMask = vk::ImageAspectFlagBits::eColor;
    image_barrier.subresourceRange.baseMipLevel = 0u;
    image_barrier.subresourceRange.levelCount = 1u;
    image_barrier.subresourceRange.baseArrayLayer = 0u;
    image_barrier.subresourceRange.layerCount = 1u;
    vk_cmd_buffer.pipelineBarrier(vk::PipelineStageFlagBits::eAllGraphics,  //
                                  vk::PipelineStageFlagBits::eAllGraphics,  //
                                  {},                                       //
                                  nullptr,                                  //
                                  nullptr,                                  //
                                  image_barrier                             //
    );
    if (!cmd_buffer->SubmitCommands()) {
      return false;
    }
  }

  //----------------------------------------------------------------------------
  /// Signal that the presentation semaphore is ready.
  ///
  {
    vk::SubmitInfo submit_info;
    vk::PipelineStageFlags wait_stage =
        vk::PipelineStageFlagBits::eColorAttachmentOutput;
    submit_info.setWaitDstStageMask(wait_stage);
    submit_info.setWaitSemaphores(*sync->render_ready);
    submit_info.setSignalSemaphores(*sync->present_ready);
    auto result =
        context.GetGraphicsQueue().submit(submit_info, *sync->acquire);
    if (result != vk::Result::eSuccess) {
      VALIDATION_LOG << "Could not wait on render semaphore: "
                     << vk::to_string(result);
      return false;
    }
  }

  //----------------------------------------------------------------------------
  /// Present the image.
  ///
  uint32_t indices[] = {static_cast<uint32_t>(index)};

  vk::PresentInfoKHR present_info;
  present_info.setSwapchains(*swapchain_);
  present_info.setImageIndices(indices);
  present_info.setWaitSemaphores(*sync->present_ready);

  switch (auto result = present_queue_.presentKHR(present_info)) {
    case vk::Result::eErrorOutOfDateKHR:
      // Caller will recreate the impl on acquisition, not submission.
      [[fallthrough]];
    case vk::Result::eErrorSurfaceLostKHR:
      // Vulkan guarantees that the set of queue operations will still complete
      // successfully.
      [[fallthrough]];
    case vk::Result::eSuccess:
      return true;
    default:
      VALIDATION_LOG << "Could not present queue: " << vk::to_string(result);
      return false;
  }
  FML_UNREACHABLE();
  return false;
}

}  // namespace impeller
