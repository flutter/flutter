// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_VULKAN_IMPORTED_IMAGE_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_VULKAN_IMPORTED_IMAGE_H_

#include <windows.h>

#include <cstdint>
#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/windows/vulkan_manager.h"

namespace flutter {

/// A VkImage bound to the memory of a shared Direct3D 11 texture.
///
/// The texture is allocated on the Direct3D side (see
/// |DCompPresenter::CreateSharedTexture|) with a keyed mutex and an NT
/// handle; this class imports that handle into Vulkan so Impeller can render
/// into the same GPU allocation that DirectComposition later presents.
/// Windows drivers expose Direct3D 11 texture memory to Vulkan as
/// import-only, which is why the allocation cannot originate on the Vulkan
/// side.
///
/// The NT handle stays owned by the caller; the import duplicates the
/// underlying reference, so the imported image remains valid independently
/// of when the caller closes the handle.
///
/// One imported image backs one engine backing store.
class VulkanImportedImage {
 public:
  /// Imports the Direct3D texture behind |nt_handle| as a VkImage of the
  /// given size. Returns nullptr on failure. |manager| must outlive the
  /// returned image.
  static std::unique_ptr<VulkanImportedImage> Import(VulkanManager* manager,
                                                     HANDLE nt_handle,
                                                     uint32_t width,
                                                     uint32_t height);

  ~VulkanImportedImage();

  VkImage image() const { return image_; }
  uint32_t width() const { return width_; }
  uint32_t height() const { return height_; }

 private:
  VulkanImportedImage(VulkanManager* manager,
                      VkImage image,
                      VkDeviceMemory memory,
                      uint32_t width,
                      uint32_t height);

  VulkanManager* manager_;
  VkImage image_ = VK_NULL_HANDLE;
  VkDeviceMemory memory_ = VK_NULL_HANDLE;
  uint32_t width_ = 0;
  uint32_t height_ = 0;

  FML_DISALLOW_COPY_AND_ASSIGN(VulkanImportedImage);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_VULKAN_IMPORTED_IMAGE_H_
