// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/gpu/gpu_surface_vulkan_impeller.h"

#include <memory>

#include "flow/surface_frame.h"
#include "flutter/fml/make_copyable.h"
#include "fml/trace_event.h"
#include "impeller/core/formats.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/display_list/dl_dispatcher.h"
#include "impeller/renderer/backend/vulkan/command_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/pipeline_library_vk.h"
#include "impeller/renderer/backend/vulkan/surface_context_vk.h"
#include "impeller/renderer/backend/vulkan/swapchain/surface_vk.h"
#include "impeller/renderer/render_target.h"
#include "impeller/renderer/surface.h"
#include "impeller/typographer/backends/skia/typographer_context_skia.h"

namespace flutter {

/// Wraps an embedder-provided VkImage/VkImageView pair as a TextureSourceVK
/// for use with Impeller's rendering pipeline. The image view is borrowed;
/// ownership is held by the surface's image view cache, which outlives the
/// wrapper.
class WrappedTextureSourceVK : public impeller::TextureSourceVK {
 public:
  explicit WrappedTextureSourceVK(impeller::vk::Image image,
                                  impeller::vk::ImageView image_view,
                                  impeller::TextureDescriptor desc)
      : TextureSourceVK(desc), image_(image), image_view_(image_view) {}

  ~WrappedTextureSourceVK() override = default;

 private:
  impeller::vk::Image GetImage() const override { return image_; }

  impeller::vk::ImageView GetImageView() const override { return image_view_; }

  impeller::vk::ImageView GetRenderTargetView(
      uint32_t mip_level,
      uint32_t array_layer) const override {
    // Swapchain images are always a single 2D mip and layer.
    return image_view_;
  }

  bool IsSwapchainImage() const override { return true; }

  impeller::vk::Image image_;
  impeller::vk::ImageView image_view_;
};

GPUSurfaceVulkanImpeller::GPUSurfaceVulkanImpeller(
    GPUSurfaceVulkanDelegate* delegate,
    std::shared_ptr<impeller::Context> context)
    : delegate_(delegate) {
  if (!context || !context->IsValid()) {
    return;
  }

  auto aiks_context = std::make_shared<impeller::AiksContext>(
      context, impeller::TypographerContextSkia::Make());
  if (!aiks_context->IsValid()) {
    return;
  }

  impeller_context_ = std::move(context);
  aiks_context_ = std::move(aiks_context);

  // Create frame-throttling fences (signaled initially so the first
  // kMaxFramesInFlight frames do not block). Only the embedder-managed image
  // path uses these; the KHR swapchain enforces its own backpressure.
  if (delegate_) {
    auto& context_vk = impeller::ContextVK::Cast(*impeller_context_);
    impeller::vk::FenceCreateInfo fence_ci;
    fence_ci.flags = impeller::vk::FenceCreateFlagBits::eSignaled;
    for (size_t i = 0; i < kMaxFramesInFlight; i++) {
      auto [result, fence] = context_vk.GetDevice().createFenceUnique(fence_ci);
      if (result != impeller::vk::Result::eSuccess) {
        FML_LOG(ERROR) << "Failed to create frame throttle fence: "
                       << impeller::vk::to_string(result);
        return;
      }
      frame_fences_[i] = std::move(fence);
    }
  }

  is_valid_ = !!aiks_context_;
}

// |Surface|
GPUSurfaceVulkanImpeller::~GPUSurfaceVulkanImpeller() {
  // Wait for in-flight frames before destroying cached image views, so a
  // VkImageView still referenced by the GPU is not destroyed
  // (VUID-vkDestroyImageView-imageView-01026). Individual frame fences are
  // used instead of vkDeviceWaitIdle: some drivers (Samsung Xclipse, Mali)
  // segfault inside vkDeviceWaitIdle when the underlying native window has
  // already been destroyed by the platform, which happens routinely during
  // Android activity transitions.
  if (impeller_context_) {
    auto& context_vk = impeller::ContextVK::Cast(*impeller_context_);
    if (!context_vk.IsDeviceLost()) {
      for (auto& fence : frame_fences_) {
        if (fence) {
          auto wait_result = context_vk.GetDevice().waitForFences(
              {*fence}, VK_TRUE, kFenceDrainTimeoutNs);
          if (wait_result != impeller::vk::Result::eSuccess) {
            FML_LOG(ERROR) << "Frame fence wait failed during teardown: "
                           << impeller::vk::to_string(wait_result);
          }
        }
      }
    }
  }
  cached_image_views_.clear();
}

// |Surface|
bool GPUSurfaceVulkanImpeller::IsValid() {
  return is_valid_;
}

// |Surface|
std::unique_ptr<SurfaceFrame> GPUSurfaceVulkanImpeller::AcquireFrame(
    const DlISize& size) {
  if (!IsValid()) {
    FML_LOG(ERROR) << "Vulkan surface was invalid.";
    return nullptr;
  }

  if (size.IsEmpty()) {
    FML_LOG(ERROR) << "Vulkan surface was asked for an empty frame.";
    return nullptr;
  }

  if (delegate_ == nullptr) {
    auto& context_vk = impeller::SurfaceContextVK::Cast(*impeller_context_);
    std::unique_ptr<impeller::Surface> surface =
        context_vk.AcquireNextSurface();

    if (!surface) {
      FML_LOG(ERROR) << "No surface available.";
      return nullptr;
    }

    impeller::RenderTarget render_target = surface->GetRenderTarget();
    auto cull_rect =
        impeller::Rect::MakeSize(render_target.GetRenderTargetSize());

    SurfaceFrame::EncodeCallback encode_callback = [aiks_context =
                                                        aiks_context_,  //
                                                    render_target,
                                                    cull_rect  //
    ](SurfaceFrame& surface_frame, DlCanvas* canvas) mutable -> bool {
      if (!aiks_context) {
        return false;
      }

      auto display_list = surface_frame.BuildDisplayList();
      if (!display_list) {
        FML_LOG(ERROR) << "Could not build display list for surface frame.";
        return false;
      }

      return impeller::RenderToTarget(
          aiks_context->GetContentContext(),                                //
          render_target,                                                    //
          display_list,                                                     //
          cull_rect,                                                        //
          /*reset_host_buffer=*/surface_frame.submit_info().frame_boundary  //
      );
    };

    return std::make_unique<SurfaceFrame>(
        nullptr,                          // surface
        SurfaceFrame::FramebufferInfo{},  // framebuffer info
        encode_callback,                  // encode callback
        fml::MakeCopyable([surface = std::move(surface)](const SurfaceFrame&) {
          return surface->Present();
        }),       // submit callback
        size,     // frame size
        nullptr,  // context result
        true      // display list fallback
    );
  } else {
    //------------------------------------------------------------------
    // Frame throttle: wait for the oldest in-flight frame's fence.
    //
    // The KHR swapchain path enforces back-pressure via WaitForFence()
    // in AcquireNextDrawable. Without an equivalent here, the CPU queues
    // frames unboundedly; fences, tracked resources, and driver objects
    // accumulate until VK_ERROR_OUT_OF_HOST_MEMORY.
    //
    // A ring of kMaxFramesInFlight fences throttles the CPU. Before
    // starting frame N, the fence from frame N-2 is awaited, guaranteeing
    // at most 2 frames in flight at any time.
    //
    // If the GPU cannot complete within kFrameSkipTimeoutNs, the frame is
    // skipped entirely. This prevents unbounded resource accumulation
    // under extreme GPU pressure while maintaining rendering correctness.
    //------------------------------------------------------------------
    {
      auto& context_vk = impeller::ContextVK::Cast(*impeller_context_);
      size_t fence_idx = current_fence_index_ % kMaxFramesInFlight;

      if (frame_fences_[fence_idx]) {
        // Wait with a bounded timeout. Under extreme load the GPU may fall
        // behind; skipping the frame preserves correct rendering.
        auto wait_result = context_vk.GetDevice().waitForFences(
            {*frame_fences_[fence_idx]}, VK_TRUE, kFrameSkipTimeoutNs);
        if (wait_result == impeller::vk::Result::eTimeout) {
          // The GPU is under extreme pressure. Returning nullptr tells the
          // rasterizer to drop this frame, which maintains rendering
          // correctness at the expense of frame rate.
          FML_LOG(WARNING)
              << "Frame skipped: GPU did not complete within timeout.";
          return nullptr;
        }
        if (wait_result != impeller::vk::Result::eSuccess) {
          FML_LOG(ERROR) << "Frame throttle fence wait failed: "
                         << impeller::vk::to_string(wait_result);
          return nullptr;
        }
        // The fence is deliberately NOT reset here. A frame can be acquired
        // and then dropped without ever being submitted (the rasterizer
        // discards frames routinely); resetting on acquire would leave the
        // fence unsignaled forever in that case, deadlocking the teardown
        // and resize drains. The submit callback resets the fence
        // immediately before queueing the signal, so a fence is only ever
        // unsignaled while submitted work is actually in flight.
      }
    }

    // Mark the end of the previous frame. In the KHR swapchain path this is
    // done by SurfaceContextVK::AcquireNextSurface(); the embedder-managed
    // image path bypasses that, so it must be done here. This lets the
    // pipeline library schedule deferred operations, matching
    // SurfaceContextVK::MarkFrameEnd().
    if (auto pipeline_library = impeller_context_->GetPipelineLibrary()) {
      impeller::PipelineLibraryVK::Cast(*pipeline_library)
          .DidAcquireSurfaceFrame();
    }
    impeller_context_->GetResourceAllocator()->DebugTraceMemoryStatistics();

    FlutterVulkanImage flutter_image = delegate_->AcquireImage(size);
    if (!flutter_image.image) {
      FML_LOG(ERROR) << "Invalid VkImage given by the embedder.";
      return nullptr;
    }
    impeller::vk::Format vk_format =
        static_cast<impeller::vk::Format>(flutter_image.format);
    std::optional<impeller::PixelFormat> format =
        impeller::VkFormatToImpellerFormat(vk_format);
    if (!format.has_value()) {
      FML_LOG(ERROR) << "Unsupported pixel format: "
                     << impeller::vk::to_string(vk_format);
      return nullptr;
    }

    impeller::ContextVK& context_vk =
        impeller::ContextVK::Cast(*impeller_context_);

    context_vk.DisposeThreadLocalCachedResources();

    impeller::vk::Image vk_image =
        impeller::vk::Image(reinterpret_cast<VkImage>(flutter_image.image));

    impeller::TextureDescriptor desc;
    desc.format = format.value();
    desc.size = impeller::ISize{size.width, size.height};
    desc.storage_mode = impeller::StorageMode::kDevicePrivate;
    desc.mip_count = 1;
    desc.compression_type = impeller::CompressionType::kLossless;
    desc.usage = impeller::TextureUsage::kRenderTarget;

    impeller::ISize frame_size{size.width, size.height};
    if (transients_ == nullptr || transients_size_ != frame_size) {
      // The embedder's images were recreated, so the old VkImages are
      // invalid and their cached views must be destroyed. Wait for all
      // in-flight frames to complete first to avoid destroying a
      // VkImageView the GPU may still reference
      // (VUID-vkDestroyImageView-imageView-01026).
      for (size_t i = 0; i < kMaxFramesInFlight; i++) {
        if (frame_fences_[i]) {
          auto wait = context_vk.GetDevice().waitForFences(
              {*frame_fences_[i]}, VK_TRUE, kFenceDrainTimeoutNs);
          if (wait != impeller::vk::Result::eSuccess) {
            FML_LOG(ERROR) << "Failed to wait for in-flight fence on resize: "
                           << impeller::vk::to_string(wait);
          }
        }
      }
      cached_image_views_.clear();
      transients_ = std::make_shared<impeller::SwapchainTransientsVK>(
          impeller_context_, desc,
          /*enable_msaa=*/true);
      transients_size_ = frame_size;
    }

    // Cache image views per embedder image to avoid a per-frame VkImageView
    // allocation (which leaks one view per frame, since nothing destroyed
    // them until surface teardown). The KHR swapchain path creates one view
    // per swapchain image; this cache replicates that pattern. Ownership is
    // held by cached_image_views_; WrappedTextureSourceVK borrows the raw
    // handle, which stays valid as long as the cache entry exists.
    impeller::vk::ImageView image_view;
    auto cache_key = flutter_image.image;
    auto it = cached_image_views_.find(cache_key);
    if (it != cached_image_views_.end()) {
      image_view = *it->second;
    } else {
      impeller::vk::ImageViewCreateInfo view_info = {};
      view_info.viewType = impeller::vk::ImageViewType::e2D;
      view_info.format = ToVKImageFormat(desc.format);
      view_info.subresourceRange.aspectMask =
          impeller::vk::ImageAspectFlagBits::eColor;
      view_info.subresourceRange.baseMipLevel = 0u;
      view_info.subresourceRange.baseArrayLayer = 0u;
      view_info.subresourceRange.levelCount = 1;
      view_info.subresourceRange.layerCount = 1;
      view_info.image = vk_image;

      auto [result, unique_view] =
          context_vk.GetDevice().createImageViewUnique(view_info);
      if (result != impeller::vk::Result::eSuccess) {
        FML_LOG(ERROR) << "Failed to create image view for provided image: "
                       << impeller::vk::to_string(result);
        return nullptr;
      }
      image_view = *unique_view;
      cached_image_views_[cache_key] = std::move(unique_view);
    }

    auto wrapped_onscreen =
        std::make_shared<WrappedTextureSourceVK>(vk_image, image_view, desc);
    auto surface = impeller::SurfaceVK::WrapSwapchainImage(
        transients_, wrapped_onscreen, [&]() -> bool { return true; });
    impeller::RenderTarget render_target = surface->GetRenderTarget();
    auto cull_rect =
        impeller::Rect::MakeSize(render_target.GetRenderTargetSize());

    SurfaceFrame::EncodeCallback encode_callback = [aiks_context =
                                                        aiks_context_,  //
                                                    render_target,
                                                    cull_rect  //
    ](SurfaceFrame& surface_frame, DlCanvas* canvas) mutable -> bool {
      if (!aiks_context) {
        return false;
      }

      auto display_list = surface_frame.BuildDisplayList();
      if (!display_list) {
        FML_LOG(ERROR) << "Could not build display list for surface frame.";
        return false;
      }

      return impeller::RenderToTarget(aiks_context->GetContentContext(),  //
                                      render_target,                      //
                                      display_list,                       //
                                      cull_rect,                          //
                                      /*reset_host_buffer=*/true          //
      );
    };

    // Raw handle of this frame's throttle fence, signaled by the submit
    // callback after presentation. The unique handle stays owned by
    // frame_fences_, which outlives the frame.
    impeller::vk::Fence frame_fence;
    if (frame_fences_[current_fence_index_ % kMaxFramesInFlight]) {
      frame_fence = *frame_fences_[current_fence_index_ % kMaxFramesInFlight];
    }

    SurfaceFrame::SubmitCallback submit_callback =
        [image = flutter_image, delegate = delegate_,
         impeller_context = impeller_context_, wrapped_onscreen,
         frame_fence](const SurfaceFrame&) -> bool {
      TRACE_EVENT0("flutter", "GPUSurfaceVulkan::PresentImage");

      {
        const auto& context = impeller::ContextVK::Cast(*impeller_context);

        //----------------------------------------------------------------------------
        /// Transition the image to color-attachment-optimal.
        ///
        auto cmd_buffer = context.CreateCommandBuffer();
        if (!cmd_buffer) {
          // Command buffer creation short-circuits when the device is lost.
          FML_LOG(ERROR) << "Failed to create command buffer for layout "
                            "transition before present.";
          return false;
        }

        auto vk_final_cmd_buffer =
            impeller::CommandBufferVK::Cast(*cmd_buffer).GetCommandBuffer();
        {
          impeller::BarrierVK barrier;
          barrier.new_layout =
              impeller::vk::ImageLayout::eColorAttachmentOptimal;
          barrier.cmd_buffer = vk_final_cmd_buffer;
          barrier.src_access =
              impeller::vk::AccessFlagBits::eColorAttachmentWrite;
          barrier.src_stage =
              impeller::vk::PipelineStageFlagBits::eColorAttachmentOutput;
          barrier.dst_access = {};
          barrier.dst_stage =
              impeller::vk::PipelineStageFlagBits::eBottomOfPipe;

          if (!wrapped_onscreen->SetLayout(barrier).ok()) {
            return false;
          }
        }
        if (!context.GetCommandQueue()->Submit({cmd_buffer}).ok()) {
          return false;
        }
      }

      bool present_ok =
          delegate->PresentImage(reinterpret_cast<VkImage>(image.image),
                                 static_cast<VkFormat>(image.format));

      //--------------------------------------------------------------------
      // Signal this frame's throttle fence.
      //
      // An empty vkQueueSubmit with just a fence signals it once all
      // previously submitted command buffers on the queue have completed
      // execution. Both the frame's rendering commands and the layout
      // transition above are therefore finished before the fence signals.
      //
      // This goes through QueueVK's submission path (which serializes all
      // access to the VkQueue behind a single mutex) rather than a direct
      // vkQueueSubmit, since unsynchronized access to the queue from two
      // lock domains is a validation violation.
      //
      // AcquireFrame waits on this fence kMaxFramesInFlight frames later,
      // capping in-flight work, matching the KHR swapchain's backpressure.
      //--------------------------------------------------------------------
      if (frame_fence) {
        const auto& context = impeller::ContextVK::Cast(*impeller_context);
        // Reset immediately before queueing the signal, not in AcquireFrame:
        // this keeps the fence signaled for frames that are acquired but
        // never submitted, so the teardown and resize drains cannot wait on
        // a fence that nothing will signal.
        auto reset_result = context.GetDevice().resetFences({frame_fence});
        if (reset_result != impeller::vk::Result::eSuccess) {
          FML_LOG(ERROR) << "Failed to reset frame throttle fence: "
                         << impeller::vk::to_string(reset_result);
          return present_ok;
        }
        auto signal_result = context.GetGraphicsQueue()->Submit(frame_fence);
        if (signal_result != impeller::vk::Result::eSuccess) {
          FML_LOG(ERROR) << "Failed to signal frame throttle fence: "
                         << impeller::vk::to_string(signal_result);
        }
      }

      return present_ok;
    };

    SurfaceFrame::FramebufferInfo framebuffer_info{.supports_readback = true};

    // Advance the fence ring so the next frame uses the next slot.
    current_fence_index_ = (current_fence_index_ + 1) % kMaxFramesInFlight;

    return std::make_unique<SurfaceFrame>(nullptr,           // surface
                                          framebuffer_info,  // framebuffer info
                                          encode_callback,   // encode callback
                                          submit_callback,
                                          size,     // frame size
                                          nullptr,  // context result
                                          true      // display list fallback
    );
  }
}

// |Surface|
DlMatrix GPUSurfaceVulkanImpeller::GetRootTransformation() const {
  // This backend does not currently support root surface transformations. Just
  // return identity.
  return {};
}

// |Surface|
GrDirectContext* GPUSurfaceVulkanImpeller::GetContext() {
  // Impeller != Skia.
  return nullptr;
}

// |Surface|
std::unique_ptr<GLContextResult>
GPUSurfaceVulkanImpeller::MakeRenderContextCurrent() {
  // This backend has no such concept.
  return std::make_unique<GLContextDefaultResult>(true);
}

// |Surface|
bool GPUSurfaceVulkanImpeller::EnableRasterCache() const {
  return false;
}

// |Surface|
std::shared_ptr<impeller::AiksContext>
GPUSurfaceVulkanImpeller::GetAiksContext() const {
  return aiks_context_;
}

}  // namespace flutter
