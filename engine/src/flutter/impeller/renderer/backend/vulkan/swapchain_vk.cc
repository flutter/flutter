// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/swapchain_vk.h"

#include "flutter/fml/trace_event.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/backend/vulkan/swapchain_impl_vk.h"

namespace impeller {

std::shared_ptr<SwapchainVK> SwapchainVK::Create(
    const std::shared_ptr<Context>& context,
    vk::UniqueSurfaceKHR surface) {
  auto impl = SwapchainImplVK::Create(context, std::move(surface));
  if (!impl || !impl->IsValid()) {
    VALIDATION_LOG << "Failed to create SwapchainVK implementation.";
    return nullptr;
  }
  return std::shared_ptr<SwapchainVK>(new SwapchainVK(std::move(impl)));
}

SwapchainVK::SwapchainVK(std::shared_ptr<SwapchainImplVK> impl)
    : impl_(std::move(impl)) {}

SwapchainVK::~SwapchainVK() = default;

bool SwapchainVK::IsValid() const {
  return impl_ ? impl_->IsValid() : false;
}

std::unique_ptr<Surface> SwapchainVK::AcquireNextDrawable() {
  if (!IsValid()) {
    return nullptr;
  }

  TRACE_EVENT0("impeller", __FUNCTION__);

  auto result = impl_->AcquireNextDrawable();
  if (!result.out_of_date) {
    return std::move(result.surface);
  }

  TRACE_EVENT0("impeller", "RecreateSwapchain");

  // This swapchain implementation indicates that it is out of date. Tear it
  // down and make a new one.
  auto context = impl_->GetContext();
  auto [surface, old_swapchain] = impl_->DestroySwapchain();

  auto new_impl = SwapchainImplVK::Create(context,                   //
                                          std::move(surface),        //
                                          *old_swapchain,            //
                                          impl_->GetLastTransform()  //
  );
  if (!new_impl || !new_impl->IsValid()) {
    VALIDATION_LOG << "Could not update swapchain.";
    // The old swapchain is dead because we took its surface. This is
    // unrecoverable.
    impl_.reset();
    return nullptr;
  }
  impl_ = std::move(new_impl);

  //----------------------------------------------------------------------------
  /// We managed to recreate the swapchain in the new configuration. Try again.
  ///
  return AcquireNextDrawable();
}

vk::Format SwapchainVK::GetSurfaceFormat() const {
  return IsValid() ? impl_->GetSurfaceFormat() : vk::Format::eUndefined;
}

}  // namespace impeller
