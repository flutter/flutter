// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/pipeline_library_vk.h"

#include <optional>

#include "flutter/fml/container.h"
#include "flutter/fml/trace_event.h"
#include "impeller/base/promise.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/pipeline_vk.h"
#include "impeller/renderer/backend/vulkan/shader_function_vk.h"
#include "impeller/renderer/backend/vulkan/vertex_descriptor_vk.h"

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
PipelineFuture<PipelineDescriptor> PipelineLibraryVK::GetPipeline(
    PipelineDescriptor descriptor) {
  Lock lock(pipelines_mutex_);
  if (auto found = pipelines_.find(descriptor); found != pipelines_.end()) {
    return found->second;
  }

  if (!IsValid()) {
    return {
        descriptor,
        RealizedFuture<std::shared_ptr<Pipeline<PipelineDescriptor>>>(nullptr)};
  }

  auto promise = std::make_shared<
      std::promise<std::shared_ptr<Pipeline<PipelineDescriptor>>>>();
  auto pipeline_future =
      PipelineFuture<PipelineDescriptor>{descriptor, promise->get_future()};
  pipelines_[descriptor] = pipeline_future;

  auto weak_this = weak_from_this();

  worker_task_runner_->PostTask([descriptor, weak_this, promise]() {
    auto thiz = weak_this.lock();
    if (!thiz) {
      promise->set_value(nullptr);
      VALIDATION_LOG << "Pipeline library was collected before the pipeline "
                        "could be created.";
      return;
    }
    auto pipeline_create_info =
        PipelineLibraryVK::Cast(thiz.get())->CreatePipeline(descriptor);
    promise->set_value(std::make_shared<PipelineVK>(
        weak_this, descriptor, std::move(pipeline_create_info)));
  });

  return pipeline_future;
}

// |PipelineLibrary|
PipelineFuture<ComputePipelineDescriptor> PipelineLibraryVK::GetPipeline(
    ComputePipelineDescriptor descriptor) {
  auto promise = std::make_shared<
      std::promise<std::shared_ptr<Pipeline<ComputePipelineDescriptor>>>>();
  // TODO(dnfield): implement compute for GLES.
  promise->set_value(nullptr);
  return {descriptor, promise->get_future()};
}

static vk::AttachmentDescription CreatePlaceholderAttachmentDescription(
    vk::Format format,
    SampleCount sample_count,
    bool is_color) {
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

  if (!is_color) {
    desc.setInitialLayout(vk::ImageLayout::eGeneral);
    desc.setFinalLayout(vk::ImageLayout::eGeneral);
  } else {
    desc.setInitialLayout(vk::ImageLayout::eColorAttachmentOptimal);
    desc.setFinalLayout(vk::ImageLayout::ePresentSrcKHR);
  }

  return desc;
}

// |PipelineLibrary|
void PipelineLibraryVK::RemovePipelinesWithEntryPoint(
    std::shared_ptr<const ShaderFunction> function) {
  Lock lock(pipelines_mutex_);

  fml::erase_if(pipelines_, [&](auto item) {
    return item->first.GetEntrypointForStage(function->GetStage())
        ->IsEqual(*function);
  });
}

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
std::optional<vk::UniqueRenderPass> PipelineLibraryVK::CreateRenderPass(
    const PipelineDescriptor& desc) {
  std::vector<vk::AttachmentDescription> render_pass_attachments;
  const auto sample_count = desc.GetSampleCount();
  // Set the color attachment.
  const auto& format = desc.GetColorAttachmentDescriptor(0)->format;
  render_pass_attachments.push_back(CreatePlaceholderAttachmentDescription(
      ToVKImageFormat(format), sample_count, true));

  std::vector<vk::AttachmentReference> color_attachment_references;
  std::vector<vk::AttachmentReference> resolve_attachment_references;
  std::optional<vk::AttachmentReference> depth_stencil_attachment_reference;

  // TODO (kaushikiska): consider changing the image layout to
  // eColorAttachmentOptimal.
  color_attachment_references.push_back(vk::AttachmentReference(
      render_pass_attachments.size() - 1u, vk::ImageLayout::eGeneral));

#if false
  // see: https://github.com/flutter/flutter/issues/112388
  // Set the resolve attachment if MSAA is enabled.
  if (sample_count != SampleCount::kCount1) {
    render_pass_attachments.push_back(CreatePlaceholderAttachmentDescription(
        vk::Format::eR8G8B8A8Unorm, SampleCount::kCount1, false));
    resolve_attachment_references.push_back(vk::AttachmentReference(
        render_pass_attachments.size() - 1u, vk::ImageLayout::eGeneral));
  }

  if (desc.HasStencilAttachmentDescriptors()) {
    render_pass_attachments.push_back(CreatePlaceholderAttachmentDescription(
        vk::Format::eS8Uint, sample_count, false));
    depth_stencil_attachment_reference = vk::AttachmentReference(
        render_pass_attachments.size() - 1u, vk::ImageLayout::eGeneral);
  }
#endif

  vk::SubpassDescription subpass_info;
  subpass_info.setPipelineBindPoint(vk::PipelineBindPoint::eGraphics);
  subpass_info.setColorAttachments(color_attachment_references);

#if false
  // see: https://github.com/flutter/flutter/issues/112388
  if (sample_count != SampleCount::kCount1) {
    subpass_info.setResolveAttachments(resolve_attachment_references);
  }
  if (depth_stencil_attachment_reference.has_value()) {
    subpass_info.setPDepthStencilAttachment(
        &depth_stencil_attachment_reference.value());
  }
#endif

  vk::RenderPassCreateInfo render_pass_info;
  render_pass_info.setSubpasses(subpass_info);
  render_pass_info.setAttachments(render_pass_attachments);
  auto render_pass = device_.createRenderPassUnique(render_pass_info);
  if (render_pass.result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create render pass for pipeline "
                   << desc.GetLabel() << ": "
                   << vk::to_string(render_pass.result);
    return std::nullopt;
  }

  return std::move(render_pass.value);
}

std::unique_ptr<PipelineCreateInfoVK> PipelineLibraryVK::CreatePipeline(
    const PipelineDescriptor& desc) {
  TRACE_EVENT0("flutter", __FUNCTION__);
  vk::GraphicsPipelineCreateInfo pipeline_info;

  //----------------------------------------------------------------------------
  /// Dynamic States
  ///
  vk::PipelineDynamicStateCreateInfo dynamic_create_state_info;
  std::vector<vk::DynamicState> dynamic_states = {
      vk::DynamicState::eViewport,
      vk::DynamicState::eScissor,
      vk::DynamicState::eStencilReference,
  };
  dynamic_create_state_info.setDynamicStates(dynamic_states);
  pipeline_info.setPDynamicState(&dynamic_create_state_info);

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
    shader_stages.push_back(info);
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
  rasterization_state.setPolygonMode(ToVKPolygonMode(desc.GetPolygonMode()));
  // requires GPU extensions to change.
  {
    rasterization_state.setLineWidth(1.0f);
    rasterization_state.setDepthClampEnable(false);
  }
  rasterization_state.setRasterizerDiscardEnable(false);
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
  vk::PipelineInputAssemblyStateCreateInfo input_assembly;
  const auto topology = ToVKPrimitiveTopology(desc.GetPrimitiveType());
  input_assembly.setTopology(topology);
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

  auto render_pass = CreateRenderPass(desc);
  if (render_pass.has_value()) {
    pipeline_info.setBasePipelineHandle(VK_NULL_HANDLE);
    pipeline_info.setSubpass(0);
    pipeline_info.setRenderPass((*render_pass).get());
  } else {
    return nullptr;
  }

  // only 1 stream of data is supported for now.
  vk::VertexInputBindingDescription binding_description = {};
  binding_description.setBinding(0);
  binding_description.setInputRate(vk::VertexInputRate::eVertex);

  std::vector<vk::VertexInputAttributeDescription> attr_descs;
  uint32_t offset = 0;
  const auto& stage_inputs = desc.GetVertexDescriptor()->GetStageInputs();
  for (const ShaderStageIOSlot& stage_in : stage_inputs) {
    vk::VertexInputAttributeDescription attr_desc;
    attr_desc.setBinding(stage_in.binding);
    attr_desc.setLocation(stage_in.location);
    attr_desc.setFormat(ToVertexDescriptorFormat(stage_in));
    attr_desc.setOffset(offset);
    attr_descs.push_back(attr_desc);
    uint32_t len = (stage_in.bit_width * stage_in.vec_size) / 8;
    offset += len;
  }

  binding_description.setStride(offset);

  vk::PipelineVertexInputStateCreateInfo vertex_input_state;
  vertex_input_state.setVertexAttributeDescriptions(attr_descs);
  vertex_input_state.setVertexBindingDescriptionCount(1);
  vertex_input_state.setPVertexBindingDescriptions(&binding_description);

  pipeline_info.setPVertexInputState(&vertex_input_state);

  //----------------------------------------------------------------------------
  /// Pipeline Layout a.k.a the descriptor sets and uniforms.
  ///
  std::vector<vk::DescriptorSetLayoutBinding> bindings = {};

  for (auto layout : desc.GetVertexDescriptor()->GetDescriptorSetLayouts()) {
    auto vk_desc_layout = ToVKDescriptorSetLayoutBinding(layout);
    bindings.push_back(vk_desc_layout);
  }

  vk::DescriptorSetLayoutCreateInfo descriptor_set_create;
  descriptor_set_create.setBindings(bindings);

  auto descriptor_set_create_res =
      device_.createDescriptorSetLayoutUnique(descriptor_set_create);
  if (descriptor_set_create_res.result != vk::Result::eSuccess) {
    VALIDATION_LOG << "unable to create uniform descriptors";
    return nullptr;
  }

  vk::UniqueDescriptorSetLayout descriptor_set_layout =
      std::move(descriptor_set_create_res.value);
  ContextVK::SetDebugName(device_, descriptor_set_layout.get(),
                          "descriptor_set_layout_" + desc.GetLabel());

  vk::PipelineLayoutCreateInfo pipeline_layout_info;
  pipeline_layout_info.setSetLayouts(descriptor_set_layout.get());
  auto pipeline_layout =
      device_.createPipelineLayoutUnique(pipeline_layout_info);
  if (pipeline_layout.result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create pipeline layout for pipeline "
                   << desc.GetLabel() << ": "
                   << vk::to_string(pipeline_layout.result);
    return nullptr;
  }
  pipeline_info.setLayout(pipeline_layout.value.get());

  vk::PipelineDepthStencilStateCreateInfo depth_stencil_state;
  depth_stencil_state.setDepthTestEnable(true);
  depth_stencil_state.setDepthWriteEnable(true);
  depth_stencil_state.setDepthCompareOp(vk::CompareOp::eLess);
  depth_stencil_state.setDepthBoundsTestEnable(false);
  depth_stencil_state.setStencilTestEnable(false);
  pipeline_info.setPDepthStencilState(&depth_stencil_state);

  // See the note in the header about why this is a reader lock.
  ReaderLock lock(cache_mutex_);
  auto pipeline =
      device_.createGraphicsPipelineUnique(cache_.get(), pipeline_info);
  if (pipeline.result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create graphics pipeline - " << desc.GetLabel()
                   << ": " << vk::to_string(pipeline.result);
    return nullptr;
  }

  ContextVK::SetDebugName(device_, *pipeline_layout.value,
                          "pipeline_layout_" + desc.GetLabel());
  ContextVK::SetDebugName(device_, *pipeline.value,
                          "pipeline_" + desc.GetLabel());

  return std::make_unique<PipelineCreateInfoVK>(
      std::move(pipeline.value), std::move(render_pass.value()),
      std::move(pipeline_layout.value), std::move(descriptor_set_layout));
}

}  // namespace impeller
