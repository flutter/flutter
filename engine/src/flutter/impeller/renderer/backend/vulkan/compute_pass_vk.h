// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_COMPUTE_PASS_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_COMPUTE_PASS_VK_H_

#include <optional>

#include "impeller/renderer/backend/vulkan/pipeline_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/compute_pass.h"
#include "third_party/abseil-cpp/absl/container/flat_hash_map.h"

namespace impeller {

class CommandBufferVK;

/// A compute pass that records dispatches into a Vulkan command buffer.
///
/// The first dispatch waits on the writes of earlier render and blit passes,
/// each later dispatch waits on the one before it, and encoding the pass makes
/// its writes visible to later work, so callers need no manual barriers.
class ComputePassVK final : public ComputePass {
 public:
  // |ComputePass|
  ~ComputePassVK() override;

 private:
  friend class CommandBufferVK;

  /// A resource bound to one binding index of the pass.
  struct BoundResource {
    /// The descriptor type the resource is bound as.
    DescriptorType type;
    /// Set for a uniform or storage buffer.
    std::optional<vk::DescriptorBufferInfo> buffer_info;
    /// Set for a sampled image.
    std::optional<vk::DescriptorImageInfo> image_info;
  };

  /// The command buffer the pass records into.
  std::shared_ptr<CommandBufferVK> command_buffer_;
  std::string label_;
  bool is_valid_ = false;

  /// The pipeline of later dispatches. It persists across dispatches in the
  /// pass until replaced.
  std::shared_ptr<Pipeline<ComputePipelineDescriptor>> pipeline_;
  /// The resources of later dispatches, keyed by binding index. They persist
  /// across dispatches in the pass until replaced.
  absl::flat_hash_map<uint32_t, BoundResource> bindings_;
  /// Whether the pipeline or a binding changed since the last dispatch, so the
  /// next dispatch needs a new descriptor set. A descriptor set that an earlier
  /// dispatch in this command buffer uses is never rewritten.
  bool descriptor_set_dirty_ = true;
  /// Whether a dispatch was recorded. The first dispatch waits on earlier
  /// render and blit passes, and each later one on the dispatch before it.
  bool has_dispatched_ = false;
  /// Whether `SetCommandLabel` pushed a debug group that the next dispatch
  /// pops.
  bool has_label_ = false;

  ComputePassVK(std::shared_ptr<const Context> context,
                std::shared_ptr<CommandBufferVK> command_buffer);

  // |ComputePass|
  bool IsValid() const override;

  // |ComputePass|
  void OnSetLabel(const std::string& label) override;

  // |ComputePass|
  bool EncodeCommands() const override;

  // |ComputePass|
  void SetCommandLabel(std::string_view label) override;

  // |ComputePass|
  void SetPipeline(const std::shared_ptr<Pipeline<ComputePipelineDescriptor>>&
                       pipeline) override;

  // |ComputePass|
  void AddBufferMemoryBarrier() override;

  // |ComputePass|
  void AddTextureMemoryBarrier() override;

  // |ComputePass|
  fml::Status Compute(std::array<uint32_t, 3> workgroup_count) override;

  // |ResourceBinder|
  bool BindResource(ShaderStage stage,
                    DescriptorType type,
                    const ShaderUniformSlot& slot,
                    const ShaderMetadata* metadata,
                    BufferView view) override;

  // |ResourceBinder|
  bool BindResource(ShaderStage stage,
                    DescriptorType type,
                    const SampledImageSlot& slot,
                    const ShaderMetadata* metadata,
                    std::shared_ptr<const Texture> texture,
                    raw_ptr<const Sampler> sampler) override;

  /// Binds a uniform or storage buffer view at `binding` for later
  /// dispatches. Returns false if the view has no buffer.
  bool BindResource(size_t binding, DescriptorType type, BufferView view);

  /// Allocates, writes and binds a descriptor set for the current pipeline and
  /// bindings.
  fml::Status BindDescriptorSet();

  /// Pops the debug group pushed by `SetCommandLabel`, if any.
  void PopCommandLabel();
};

}  // namespace impeller
#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_COMPUTE_PASS_VK_H_
