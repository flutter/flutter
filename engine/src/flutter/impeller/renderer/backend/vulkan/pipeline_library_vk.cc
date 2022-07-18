// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/pipeline_library_vk.h"

#include "flutter/fml/trace_event.h"
#include "impeller/base/promise.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/shader_function_vk.h"

namespace impeller {

PipelineLibraryVK::PipelineLibraryVK(
    const vk::Device& device,
    const std::shared_ptr<const fml::Mapping>& pipeline_cache_data,
    std::shared_ptr<fml::ConcurrentTaskRunner> worker_task_runner)
    : worker_task_runner_(std::move(worker_task_runner)) {
  if (!worker_task_runner_) {
    return;
  }

  vk::PipelineCacheCreateInfo cache_info;

  if (pipeline_cache_data) {
    cache_info.pInitialData = pipeline_cache_data->GetMapping();
    cache_info.initialDataSize = pipeline_cache_data->GetSize();
  }

  auto cache = device.createPipelineCacheUnique(cache_info);

  if (cache.result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create pipeline cache.";
    return;
  }

  device_ = device;
  cache_ = std::move(cache.value);
  is_valid_ = true;
}

PipelineLibraryVK::~PipelineLibraryVK() = default;

// |PipelineLibrary|
bool PipelineLibraryVK::IsValid() const {
  return is_valid_;
}

// |PipelineLibrary|
PipelineFuture PipelineLibraryVK::GetRenderPipeline(
    PipelineDescriptor descriptor) {
  Lock lock(pipelines_mutex_);
  if (auto found = pipelines_.find(descriptor); found != pipelines_.end()) {
    return found->second;
  }

  if (!IsValid()) {
    return RealizedFuture<std::shared_ptr<Pipeline>>(nullptr);
  }

  auto promise = std::make_shared<std::promise<std::shared_ptr<Pipeline>>>();
  auto future = PipelineFuture{promise->get_future()};
  pipelines_[descriptor] = future;

  auto weak_this = weak_from_this();

  worker_task_runner_->PostTask([descriptor, weak_this, promise]() {
    auto thiz = weak_this.lock();
    if (!thiz) {
      promise->set_value(nullptr);
      VALIDATION_LOG << "Pipeline library was collected before the pipeline "
                        "could be created.";
      return;
    }
    promise->set_value(
        PipelineLibraryVK::Cast(thiz.get())->CreatePipeline(descriptor));
  });

  return future;
}

static vk::AttachmentDescription CreatePlaceholderAttachmentDescription(
    vk::Format format,
    SampleCount sample_count) {
  vk::AttachmentDescription desc;

  // See
  // https://www.khronos.org/registry/vulkan/specs/1.3-extensions/html/chap8.html#renderpass-compatibility

  // Format and samples must match for sub-pass compatibility
  desc.setFormat(format);
  desc.setSamples(ToVKSampleCountFlagBits(sample_count));

  // The rest of these are placeholders and the right values will be set when
  // the render-pass to be used with the framebuffer is created.
  desc.setLoadOp(vk::AttachmentLoadOp::eDontCare);
  desc.setStoreOp(vk::AttachmentStoreOp::eDontCare);
  desc.setStencilLoadOp(vk::AttachmentLoadOp::eDontCare);
  desc.setStencilStoreOp(vk::AttachmentStoreOp::eDontCare);
  desc.setInitialLayout(vk::ImageLayout::eUndefined);
  desc.setFinalLayout(vk::ImageLayout::eGeneral);

  return desc;
}

std::shared_ptr<PipelineVK> PipelineLibraryVK::CreatePipeline(
    const PipelineDescriptor& desc) const {
  TRACE_EVENT0("flutter", __FUNCTION__);
  vk::GraphicsPipelineCreateInfo pipeline_info;

  //----------------------------------------------------------------------------
  /// Dynamic States
  ///
  vk::PipelineDynamicStateCreateInfo dynamic_state_info;
  std::vector<vk::DynamicState> dynamic_states = {
      vk::DynamicState::eViewport,
      vk::DynamicState::eScissor,
      vk::DynamicState::eStencilReference,
  };
  dynamic_state_info.setDynamicStates(dynamic_states);
  pipeline_info.setPDynamicState(&dynamic_state_info);

  //----------------------------------------------------------------------------
  /// Viewport State
  ///
  vk::PipelineViewportStateCreateInfo viewport_state;
  viewport_state.setViewportCount(1u);
  viewport_state.setScissorCount(1u);
  // The actual viewport and scissor rects are not set here since they are
  // dynamic as mentioned above in the dynamic state info.
  pipeline_info.setPViewportState(&viewport_state);

  //----------------------------------------------------------------------------
  /// Shader Stages
  ///
  std::vector<vk::PipelineShaderStageCreateInfo> shader_stages;
  for (const auto& entrypoint : desc.GetStageEntrypoints()) {
    auto stage = ToVKShaderStageFlagBits(entrypoint.first);
    if (!stage.has_value()) {
      VALIDATION_LOG << "Unsupported shader type in pipeline: "
                     << desc.GetLabel();
      return nullptr;
    }
    vk::PipelineShaderStageCreateInfo info;
    info.setStage(stage.value());
    info.setPName("main");
    info.setModule(
        ShaderFunctionVK::Cast(entrypoint.second.get())->GetModule());
    shader_stages.push_back(std::move(info));
  }
  pipeline_info.setStages(shader_stages);

  //----------------------------------------------------------------------------
  /// Rasterization State
  /// TODO(106380): Move front face and cull mode to pipeline state instead of
  ///               draw command. These are hard-coded here for now.
  ///
  vk::PipelineRasterizationStateCreateInfo rasterization_state;
  rasterization_state.setFrontFace(vk::FrontFace::eClockwise);
  rasterization_state.setCullMode(vk::CullModeFlagBits::eNone);
  rasterization_state.setPolygonMode(vk::PolygonMode::eFill);
  rasterization_state.setLineWidth(1.0f);
  pipeline_info.setPRasterizationState(&rasterization_state);

  //----------------------------------------------------------------------------
  /// Multi-sample State
  ///
  vk::PipelineMultisampleStateCreateInfo multisample_state;
  multisample_state.setRasterizationSamples(
      ToVKSampleCountFlagBits(desc.GetSampleCount()));
  pipeline_info.setPMultisampleState(&multisample_state);

  //----------------------------------------------------------------------------
  /// Primitive Input Assembly State
  /// TODO(106379): Move primitive topology to the the pipeline instead of it
  ///               being on the draw call. This is hard-coded right now.
  ///
  vk::PipelineInputAssemblyStateCreateInfo input_assembly;
  input_assembly.setTopology(vk::PrimitiveTopology::eTriangleList);
  pipeline_info.setPInputAssemblyState(&input_assembly);

  //----------------------------------------------------------------------------
  /// Color Blend State
  ///
  std::vector<vk::PipelineColorBlendAttachmentState> attachment_blend_state;
  for (const auto& color_desc : desc.GetColorAttachmentDescriptors()) {
    // TODO(csg): The blend states are per color attachment. But it isn't clear
    // how the color attachment indices are specified in the pipeline create
    // info. But, this should always work for one color attachment.
    attachment_blend_state.push_back(
        ToVKPipelineColorBlendAttachmentState(color_desc.second));
  }
  vk::PipelineColorBlendStateCreateInfo blend_state;
  blend_state.setAttachments(attachment_blend_state);
  pipeline_info.setPColorBlendState(&blend_state);

  //----------------------------------------------------------------------------
  /// Render Pass
  /// We are NOT going to use the same render pass with the framebuffer (later)
  /// and the graphics pipeline (here). Instead, we are going to ensure that the
  /// sub-passes are compatible. To see the compatibility rules, see the Vulkan
  /// spec:
  /// https://www.khronos.org/registry/vulkan/specs/1.3-extensions/html/chap8.html#renderpass-compatibility
  /// TODO(106378): Add a format specifier to the ColorAttachmentDescriptor,
  ///               StencilAttachmentDescriptor, and, DepthAttachmentDescriptor.
  ///               Right now, these are placeholders.
  ///
  std::vector<vk::AttachmentReference> color_attachment_references;
  std::vector<vk::AttachmentReference> resolve_attachment_references;
  std::optional<vk::AttachmentReference> depth_stencil_attachment_reference;
  std::vector<vk::AttachmentDescription> render_pass_attachments;
  const auto sample_count = desc.GetSampleCount();
  // Set the color attachment.
  render_pass_attachments.push_back(CreatePlaceholderAttachmentDescription(
      vk::Format::eR8G8B8A8Unorm, sample_count));
  color_attachment_references.push_back(vk::AttachmentReference(
      render_pass_attachments.size() - 1u, vk::ImageLayout::eGeneral));
  // Set the resolve attachment if MSAA is enabled.
  if (sample_count != SampleCount::kCount1) {
    render_pass_attachments.push_back(CreatePlaceholderAttachmentDescription(
        vk::Format::eR8G8B8A8Unorm, SampleCount::kCount1));
    resolve_attachment_references.push_back(vk::AttachmentReference(
        render_pass_attachments.size() - 1u, vk::ImageLayout::eGeneral));
  }
  if (desc.HasStencilAttachmentDescriptors()) {
    render_pass_attachments.push_back(CreatePlaceholderAttachmentDescription(
        vk::Format::eS8Uint, sample_count));
    depth_stencil_attachment_reference = vk::AttachmentReference(
        render_pass_attachments.size() - 1u, vk::ImageLayout::eGeneral);
  }
  vk::SubpassDescription subpass_info;
  subpass_info.setPipelineBindPoint(vk::PipelineBindPoint::eGraphics);
  subpass_info.setColorAttachments(color_attachment_references);
  subpass_info.setResolveAttachments(resolve_attachment_references);
  if (depth_stencil_attachment_reference.has_value()) {
    subpass_info.setPDepthStencilAttachment(
        &depth_stencil_attachment_reference.value());
  }
  vk::RenderPassCreateInfo render_pass_info;
  render_pass_info.setSubpasses(subpass_info);
  render_pass_info.setAttachments(render_pass_attachments);
  auto render_pass = device_.createRenderPassUnique(render_pass_info);
  if (render_pass.result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create render pass for pipeline "
                   << desc.GetLabel() << ": "
                   << vk::to_string(render_pass.result);
    return nullptr;
  }
  pipeline_info.setRenderPass(render_pass.value.get());

  //----------------------------------------------------------------------------
  /// Pipeline Layout a.k.a the descriptor sets and uniforms.
  ///
  std::vector<vk::DescriptorSetLayout> descriptor_set_layouts;
  // TODO(106377): Wire this up from the C++ generated headers.
  vk::PipelineLayoutCreateInfo pipeline_layout_info;
  pipeline_layout_info.setSetLayouts(descriptor_set_layouts);
  auto pipeline_layout =
      device_.createPipelineLayoutUnique(pipeline_layout_info);
  if (pipeline_layout.result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create pipeline layout for pipeline "
                   << desc.GetLabel() << ": "
                   << vk::to_string(pipeline_layout.result);
    return nullptr;
  }
  pipeline_info.setLayout(pipeline_layout.value.get());

  // TODO(WIP)

  // pipeline_info.setPVertexInputState(&vertex_input_state);
  // pipeline_info.setPDepthStencilState(&depth_stencil_state_);
  // pipeline_info.setLayout(pipeline_layout);

  // See the note in the header about why this is a reader lock.
  ReaderLock lock(cache_mutex_);
  auto pipeline =
      device_.createGraphicsPipelineUnique(cache_.get(), pipeline_info);
  if (pipeline.result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create graphics pipeline: " << desc.GetLabel();
    return nullptr;
  }
  FML_UNREACHABLE();
}

}  // namespace impeller
