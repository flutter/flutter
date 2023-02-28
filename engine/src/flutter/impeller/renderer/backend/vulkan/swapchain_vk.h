// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/surface.h"

namespace impeller {

class SwapchainImplVK;

//------------------------------------------------------------------------------
/// @brief      A swapchain that adapts to the underlying surface going out of
///             date. If the caller cannot acquire the next drawable, it is due
///             to an unrecoverable error and the swapchain must be recreated
///             with a new surface.
///
class SwapchainVK {
 public:
  static std::shared_ptr<SwapchainVK> Create(
      const std::shared_ptr<Context>& context,
      vk::UniqueSurfaceKHR surface);

  ~SwapchainVK();

  bool IsValid() const;

  std::unique_ptr<Surface> AcquireNextDrawable();

  vk::Format GetSurfaceFormat() const;

 private:
  std::shared_ptr<SwapchainImplVK> impl_;

  explicit SwapchainVK(std::shared_ptr<SwapchainImplVK> impl);

  FML_DISALLOW_COPY_AND_ASSIGN(SwapchainVK);
};

}  // namespace impeller
