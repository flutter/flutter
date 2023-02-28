// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <variant>

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

class Context;
class SwapchainImageVK;
class Surface;
struct FrameSynchronizer;

//------------------------------------------------------------------------------
/// @brief      An instance of a swapchain that does NOT adapt to going out of
///             date with the underlying surface. Errors will be indicated when
///             the next drawable is acquired from this implementation of the
///             swapchain. If the error is due the swapchain going out of date,
///             the caller must recreate another instance by optionally
///             stealing this implementations guts.
///
class SwapchainImplVK final
    : public std::enable_shared_from_this<SwapchainImplVK> {
 public:
  static std::shared_ptr<SwapchainImplVK> Create(
      const std::shared_ptr<Context>& context,
      vk::UniqueSurfaceKHR surface,
      vk::SwapchainKHR old_swapchain = VK_NULL_HANDLE);

  ~SwapchainImplVK();

  bool IsValid() const;

  struct AcquireResult {
    std::unique_ptr<Surface> surface;
    bool out_of_date = false;

    AcquireResult(bool p_out_of_date = false) : out_of_date(p_out_of_date) {}

    AcquireResult(std::unique_ptr<Surface> p_surface)
        : surface(std::move(p_surface)) {}
  };

  AcquireResult AcquireNextDrawable();

  vk::Format GetSurfaceFormat() const;

  std::shared_ptr<Context> GetContext() const;

  std::pair<vk::UniqueSurfaceKHR, vk::UniqueSwapchainKHR> DestroySwapchain();

 private:
  std::weak_ptr<Context> context_;
  vk::UniqueSurfaceKHR surface_;
  vk::Queue present_queue_ = {};
  vk::Format surface_format_ = vk::Format::eUndefined;
  vk::UniqueSwapchainKHR swapchain_;
  std::vector<std::shared_ptr<SwapchainImageVK>> images_;
  std::vector<std::unique_ptr<FrameSynchronizer>> synchronizers_;
  size_t current_frame_ = 0u;
  bool is_valid_ = false;

  SwapchainImplVK(const std::shared_ptr<Context>& context,
                  vk::UniqueSurfaceKHR surface,
                  vk::SwapchainKHR old_swapchain);

  bool Present(const std::shared_ptr<SwapchainImageVK>& image, uint32_t index);

  void WaitIdle() const;

  FML_DISALLOW_COPY_AND_ASSIGN(SwapchainImplVK);
};

}  // namespace impeller
