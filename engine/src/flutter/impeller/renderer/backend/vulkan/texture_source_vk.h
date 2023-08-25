// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "flutter/fml/status.h"
#include "impeller/base/thread.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/renderer/backend/vulkan/barrier_vk.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

/// Abstract base class that represents a vkImage and an vkImageView.
///
/// This is intended to be used with an impeller::TextureVK. Example
/// implementations represent swapchain images or uploaded textures.
class TextureSourceVK {
 public:
  virtual ~TextureSourceVK();

  const TextureDescriptor& GetTextureDescriptor() const;

  virtual vk::Image GetImage() const = 0;

  virtual vk::ImageView GetImageView() const = 0;

  /// Encodes the layout transition `barrier` to `barrier.cmd_buffer` for the
  /// image.
  ///
  /// The transition is from the layout stored via `SetLayoutWithoutEncoding` to
  /// `barrier.new_layout`.
  fml::Status SetLayout(const BarrierVK& barrier) const;

  /// Store the layout of the image.
  ///
  /// This just is bookkeeping on the CPU, to actually set the layout use
  /// `SetLayout`.
  ///
  /// @param layout The new layout.
  /// @return The old layout.
  vk::ImageLayout SetLayoutWithoutEncoding(vk::ImageLayout layout) const;

  /// Get the last layout assigned to the TextureSourceVK.
  ///
  /// This value is synchronized with the GPU via SetLayout so it may not
  /// reflect the actual layout.
  vk::ImageLayout GetLayout() const;

 protected:
  const TextureDescriptor desc_;

  explicit TextureSourceVK(TextureDescriptor desc);

 private:
  mutable RWMutex layout_mutex_;
  mutable vk::ImageLayout layout_ IPLR_GUARDED_BY(layout_mutex_) =
      vk::ImageLayout::eUndefined;
};

}  // namespace impeller
