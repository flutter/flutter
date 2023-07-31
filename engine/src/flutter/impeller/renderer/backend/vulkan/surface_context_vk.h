// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "impeller/base/backend_cast.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/context.h"

namespace impeller {

class ContextVK;
class Surface;
class SwapchainVK;

class SurfaceContextVK : public Context,
                         public BackendCast<SurfaceContextVK, Context> {
 public:
  SurfaceContextVK(const std::shared_ptr<ContextVK>& parent);

  // |Context|
  ~SurfaceContextVK() override;

  // |Context|
  BackendType GetBackendType() const override;

  // |Context|
  std::string DescribeGpuModel() const override;

  // |Context|
  bool IsValid() const override;

  // |Context|
  std::shared_ptr<Allocator> GetResourceAllocator() const override;

  // |Context|
  std::shared_ptr<ShaderLibrary> GetShaderLibrary() const override;

  // |Context|
  std::shared_ptr<SamplerLibrary> GetSamplerLibrary() const override;

  // |Context|
  std::shared_ptr<PipelineLibrary> GetPipelineLibrary() const override;

  // |Context|
  std::shared_ptr<CommandBuffer> CreateCommandBuffer() const override;

  // |Context|
  const std::shared_ptr<const Capabilities>& GetCapabilities() const override;

  // |Context|
  void Shutdown() override;

  [[nodiscard]] bool SetWindowSurface(vk::UniqueSurfaceKHR surface);

  std::unique_ptr<Surface> AcquireNextSurface();

#ifdef FML_OS_ANDROID
  vk::UniqueSurfaceKHR CreateAndroidSurface(ANativeWindow* window) const;
#endif  // FML_OS_ANDROID

 private:
  std::shared_ptr<ContextVK> parent_;
  std::shared_ptr<SwapchainVK> swapchain_;
};

}  // namespace impeller
