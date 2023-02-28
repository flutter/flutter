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
  promise->set_value(nullptr);
  return {descriptor, promise->get_future()};
}

//------------------------------------------------------------------------------
/// @brief      Creates an attachment description that does just enough to
///             ensure render pass compatibility with the pass associated later
///             with the framebuffer.
///
///             See
///             https://www.khronos.org/registry/vulkan/specs/1.3-extensions/html/chap8.html#renderpass-compatibility
///
static vk::AttachmentDescription CreatePlaceholderAttachmentDescription(
    PixelFormat format,
    SampleCount sample_count,
    AttachmentKind kind) {
  // Load store ops are immaterial for pass compatibility. The right ops will be
  // picked up when the pass associated with framebuffer.
  return CreateAttachmentDescription(format,                 //
                                     sample_count,           //
                                     kind,                   //
                                     LoadAction::kDontCare,  //
                                     StoreAction::kDontCare  //
  );
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
vk::UniqueRenderPass PipelineLibraryVK::CreateRenderPass(
    const PipelineDescriptor& desc) {
  std::vector<vk::AttachmentDescription> attachments;

  std::vector<vk::AttachmentReference> color_refs;
  vk::AttachmentReference depth_stencil_ref = kUnusedAttachmentReference;

  color_refs.resize(desc.GetMaxColorAttacmentBindIndex() + 1,
                    kUnusedAttachmentReference);

  const auto sample_count = desc.GetSampleCount();

  for (const auto& [bind_point, color] : desc.GetColorAttachmentDescriptors()) {
    color_refs[bind_point] =
        vk::AttachmentReference{static_cast<uint32_t>(attachments.size()),
                                vk::ImageLayout::eColorAttachmentOptimal};
    attachments.emplace_back(CreatePlaceholderAttachmentDescription(
        color.format, sample_count, AttachmentKind::kColor));
  }

  if (auto depth = desc.GetDepthStencilAttachmentDescriptor();
      depth.has_value()) {
    depth_stencil_ref = vk::AttachmentReference{
        static_cast<uint32_t>(attachments.size()),
        vk::ImageLayout::eDepthStencilAttachmentOptimal};
    attachments.emplace_back(CreatePlaceholderAttachmentDescription(
        desc.GetDepthPixelFormat(), sample_count, AttachmentKind::kDepth));
  } else if (desc.HasStencilAttachmentDescriptors()) {
    depth_stencil_ref = vk::AttachmentReference{
        static_cast<uint32_t>(attachments.size()),
        vk::ImageLayout::eDepthStencilAttachmentOptimal};
    attachments.emplace_back(CreatePlaceholderAttachmentDescription(
        desc.GetStencilPixelFormat(), sample_count, AttachmentKind::kStencil));
  }

  vk::SubpassDescription subpass_desc;
  subpass_desc.pipelineBindPoint = vk::PipelineBindPoint::eGraphics;
  subpass_desc.setColorAttachments(color_refs);
  subpass_desc.setPDepthStencilAttachment(&depth_stencil_ref);

  vk::RenderPassCreateInfo render_pass_desc;
  render_pass_desc.setAttachments(attachments);
  render_pass_desc.setPSubpasses(&subpass_desc);
  render_pass_desc.setSubpassCount(1u);

  auto [result, pass] = device_.createRenderPassUnique(render_pass_desc);
  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to create render pass for pipeline '"
                   << desc.GetLabel() << "'. Error: " << vk::to_string(result);
    return {};
  }

  return std::move(pass);
}

constexpr vk::FrontFace ToVKFrontFace(WindingOrder order) {
  switch (order) {
    case WindingOrder::kClockwise:
      return vk::FrontFace::eClockwise;
    case WindingOrder::kCounterClockwise:
      return vk::FrontFace::eCounterClockwise;
  }
  FML_UNREACHABLE();
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
  ///
  vk::PipelineRasterizationStateCreateInfo rasterization_state;
  rasterization_state.setFrontFace(ToVKFrontFace(desc.GetWindingOrder()));
  rasterization_state.setCullMode(ToVKCullModeFlags(desc.GetCullMode()));
  rasterization_state.setPolygonMode(ToVKPolygonMode(desc.GetPolygonMode()));
  rasterization_state.setLineWidth(1.0f);
  rasterization_state.setDepthClampEnable(false);
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
  if (render_pass) {
    pipeline_info.setBasePipelineHandle(VK_NULL_HANDLE);
    pipeline_info.setSubpass(0);
    pipeline_info.setRenderPass(render_pass.get());
  } else {
    return nullptr;
  }

  //----------------------------------------------------------------------------
  /// Vertex Input Setup
  ///
  vk::VertexInputBindingDescription binding_description;
  // Only 1 stream of data is supported for now.
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
                          "Descriptor Set Layout" + desc.GetLabel());

  //----------------------------------------------------------------------------
  /// Create the pipeline layout.
  ///
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

  //----------------------------------------------------------------------------
  /// Create the depth stencil state.
  ///
  auto depth_stencil_state = ToVKPipelineDepthStencilStateCreateInfo(
      desc.GetDepthStencilAttachmentDescriptor(),
      desc.GetFrontStencilAttachmentDescriptor(),
      desc.GetBackStencilAttachmentDescriptor());
  pipeline_info.setPDepthStencilState(&depth_stencil_state);

  //----------------------------------------------------------------------------
  /// Finally, all done with the setup info. Create the pipeline itself.
  ///

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
                          "Pipeline Layout" + desc.GetLabel());
  ContextVK::SetDebugName(device_, *pipeline.value,
                          "Pipeline" + desc.GetLabel());

  return std::make_unique<PipelineCreateInfoVK>(
      std::move(pipeline.value), std::move(render_pass),
      std::move(pipeline_layout.value), std::move(descriptor_set_layout));
}

}  // namespace impeller
