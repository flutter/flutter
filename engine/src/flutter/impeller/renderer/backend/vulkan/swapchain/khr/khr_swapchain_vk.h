// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_SWAPCHAIN_KHR_KHR_SWAPCHAIN_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_SWAPCHAIN_KHR_KHR_SWAPCHAIN_VK_H_

#include <memory>

#include "impeller/geometry/size.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/surface.h"

namespace impeller {

class KHRSwapchainImplVK;

//------------------------------------------------------------------------------
/// @brief      A swapchain that adapts to the underlying surface going out of
///             date. If the caller cannot acquire the next drawable, it is due
///             to an unrecoverable error and the swapchain must be recreated
///             with a new surface.
///
class KHRSwapchainVK {
 public:
  static std::shared_ptr<KHRSwapchainVK> Create(
      const std::shared_ptr<Context>& context,
      vk::UniqueSurfaceKHR surface,
      const ISize& size,
      bool enable_msaa = true);

  ~KHRSwapchainVK();

  bool IsValid() const;

  std::unique_ptr<Surface> AcquireNextDrawable();

  vk::Format GetSurfaceFormat() const;

  /// @brief Mark the current swapchain configuration as dirty, forcing it to be
  ///        recreated on the next frame.
  void UpdateSurfaceSize(const ISize& size);

 private:
  std::shared_ptr<KHRSwapchainImplVK> impl_;
  ISize size_;
  const bool enable_msaa_;

  KHRSwapchainVK(std::shared_ptr<KHRSwapchainImplVK> impl,
                 const ISize& size,
                 bool enable_msaa);

  KHRSwapchainVK(const KHRSwapchainVK&) = delete;

  KHRSwapchainVK& operator=(const KHRSwapchainVK&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_SWAPCHAIN_KHR_KHR_SWAPCHAIN_VK_H_
