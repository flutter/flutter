// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/pipeline_library_vk.h"

#include <chrono>
#include <cstdint>
#include <optional>
#include <sstream>

#include "flutter/fml/container.h"
#include "flutter/fml/trace_event.h"
#include "impeller/base/promise.h"
#include "impeller/base/timing.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/pipeline_vk.h"
#include "impeller/renderer/backend/vulkan/shader_function_vk.h"
#include "impeller/renderer/backend/vulkan/vertex_descriptor_vk.h"

namespace impeller {

PipelineLibraryVK::PipelineLibraryVK(
    const std::shared_ptr<DeviceHolder>& device_holder,
    std::shared_ptr<const Capabilities> caps,
    fml::UniqueFD cache_directory,
    std::shared_ptr<fml::ConcurrentTaskRunner> worker_task_runner)
    : device_holder_(device_holder),
      pso_cache_(std::make_shared<PipelineCacheVK>(std::move(caps),
                                                   device_holder,
                                                   std::move(cache_directory))),
      worker_task_runner_(std::move(worker_task_runner)) {
  FML_DCHECK(worker_task_runner_);
  if (!pso_cache_->IsValid() || !worker_task_runner_) {
    return;
  }

  is_valid_ = true;
}

PipelineLibraryVK::~PipelineLibraryVK() = default;

// |PipelineLibrary|
bool PipelineLibraryVK::IsValid() const {
  return is_valid_;
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
    SampleCount sample_count) {
  // Load store ops are immaterial for pass compatibility. The right ops will be
  // picked up when the pass associated with framebuffer.
  return CreateAttachmentDescription(format,                      //
                                     sample_count,                //
                                     LoadAction::kDontCare,       //
                                     StoreAction::kDontCare,      //
                                     vk::ImageLayout::eUndefined  //
  );
}

//----------------------------------------------------------------------------
/// Render Pass
/// We are NOT going to use the same render pass with the framebuffer (later)
/// and the graphics pipeline (here). Instead, we are going to ensure that the
/// sub-passes are compatible. To see the compatibility rules, see the Vulkan
/// spec:
/// https://www.khronos.org/registry/vulkan/specs/1.3-extensions/html/chap8.html#renderpass-compatibility
///
static vk::UniqueRenderPass CreateCompatRenderPassForPipeline(
    const vk::Device& device,
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
    attachments.emplace_back(
        CreatePlaceholderAttachmentDescription(color.format, sample_count));
  }

  if (auto depth = desc.GetDepthStencilAttachmentDescriptor();
      depth.has_value()) {
    depth_stencil_ref = vk::AttachmentReference{
        static_cast<uint32_t>(attachments.size()),
        vk::ImageLayout::eDepthStencilAttachmentOptimal};
    attachments.emplace_back(CreatePlaceholderAttachmentDescription(
        desc.GetDepthPixelFormat(), sample_count));
  }
  if (desc.HasStencilAttachmentDescriptors()) {
    depth_stencil_ref = vk::AttachmentReference{
        static_cast<uint32_t>(attachments.size()),
        vk::ImageLayout::eDepthStencilAttachmentOptimal};
    attachments.emplace_back(CreatePlaceholderAttachmentDescription(
        desc.GetStencilPixelFormat(), sample_count));
  }

  vk::SubpassDescription subpass_desc;
  subpass_desc.pipelineBindPoint = vk::PipelineBindPoint::eGraphics;
  subpass_desc.setColorAttachments(color_refs);
  subpass_desc.setPDepthStencilAttachment(&depth_stencil_ref);

  vk::RenderPassCreateInfo render_pass_desc;
  render_pass_desc.setAttachments(attachments);
  render_pass_desc.setPSubpasses(&subpass_desc);
  render_pass_desc.setSubpassCount(1u);

  auto [result, pass] = device.createRenderPassUnique(render_pass_desc);
  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Failed to create render pass for pipeline '"
                   << desc.GetLabel() << "'. Error: " << vk::to_string(result);
    return {};
  }

  // This pass is not used with the render pass. It is only necessary to tell
  // Vulkan the expected render pass layout. The actual pass will be created
  // later during render pass setup and will need to be compatible with this
  // one.
  ContextVK::SetDebugName(device, pass.get(),
                          "Compat Render Pass: " + desc.GetLabel());

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

static vk::PipelineCreationFeedbackEXT EmptyFeedback() {
  vk::PipelineCreationFeedbackEXT feedback;
  // If the VK_PIPELINE_CREATION_FEEDBACK_VALID_BIT is not set in flags, an
  // implementation must not set any other bits in flags, and the values of all
  // other VkPipelineCreationFeedback data members are undefined.
  feedback.flags = vk::PipelineCreationFeedbackFlagBits::eValid;
  return feedback;
}

static void ReportPipelineCreationFeedbackToLog(
    std::stringstream& stream,
    const vk::PipelineCreationFeedbackEXT& feedback) {
  const auto pipeline_cache_hit =
      feedback.flags &
      vk::PipelineCreationFeedbackFlagBits::eApplicationPipelineCacheHit;
  const auto base_pipeline_accl =
      feedback.flags &
      vk::PipelineCreationFeedbackFlagBits::eBasePipelineAcceleration;
  auto duration = std::chrono::duration_cast<MillisecondsF>(
      std::chrono::nanoseconds{feedback.duration});
  stream << "Time: " << duration.count() << "ms"
         << " Cache Hit: " << static_cast<bool>(pipeline_cache_hit)
         << " Base Accel: " << static_cast<bool>(base_pipeline_accl)
         << " Thread: " << std::this_thread::get_id();
}

static void ReportPipelineCreationFeedbackToLog(
    const PipelineDescriptor& desc,
    const vk::PipelineCreationFeedbackCreateInfoEXT& feedback) {
  std::stringstream stream;
  stream << std::fixed << std::showpoint << std::setprecision(2);
  stream << std::endl << ">>>>>>" << std::endl;
  stream << "Pipeline '" << desc.GetLabel() << "' ";
  ReportPipelineCreationFeedbackToLog(stream,
                                      *feedback.pPipelineCreationFeedback);
  if (feedback.pipelineStageCreationFeedbackCount != 0) {
    stream << std::endl;
  }
  for (size_t i = 0, count = feedback.pipelineStageCreationFeedbackCount;
       i < count; i++) {
    stream << "\tStage " << i + 1 << ": ";
    ReportPipelineCreationFeedbackToLog(
        stream, feedback.pPipelineStageCreationFeedbacks[i]);
    if (i != count - 1) {
      stream << std::endl;
    }
  }
  stream << std::endl << "<<<<<<" << std::endl;
  FML_LOG(ERROR) << stream.str();
}

static void ReportPipelineCreationFeedbackToTrace(
    const PipelineDescriptor& desc,
    const vk::PipelineCreationFeedbackCreateInfoEXT& feedback) {
  static int64_t gPipelineCacheHits = 0;
  static int64_t gPipelineCacheMisses = 0;
  static int64_t gPipelines = 0;
  if (feedback.pPipelineCreationFeedback->flags &
      vk::PipelineCreationFeedbackFlagBits::eApplicationPipelineCacheHit) {
    gPipelineCacheHits++;
  } else {
    gPipelineCacheMisses++;
  }
  gPipelines++;
  static constexpr int64_t kImpellerPipelineTraceID = 1988;
  FML_TRACE_COUNTER("impeller",                                   //
                    "PipelineCache",                              // series name
                    kImpellerPipelineTraceID,                     // series ID
                    "PipelineCacheHits", gPipelineCacheHits,      //
                    "PipelineCacheMisses", gPipelineCacheMisses,  //
                    "TotalPipelines", gPipelines                  //
  );
}

static void ReportPipelineCreationFeedback(
    const PipelineDescriptor& desc,
    const vk::PipelineCreationFeedbackCreateInfoEXT& feedback) {
  constexpr bool kReportPipelineCreationFeedbackToLogs = false;
  constexpr bool kReportPipelineCreationFeedbackToTraces = true;
  if (kReportPipelineCreationFeedbackToLogs) {
    ReportPipelineCreationFeedbackToLog(desc, feedback);
  }
  if (kReportPipelineCreationFeedbackToTraces) {
    ReportPipelineCreationFeedbackToTrace(desc, feedback);
  }
}

std::unique_ptr<PipelineVK> PipelineLibraryVK::CreatePipeline(
    const PipelineDescriptor& desc) {
  TRACE_EVENT0("flutter", __FUNCTION__);
  vk::StructureChain<vk::GraphicsPipelineCreateInfo,
                     vk::PipelineCreationFeedbackCreateInfoEXT>
      chain;

  const auto& supports_pipeline_creation_feedback =
      pso_cache_->GetCapabilities()->HasOptionalDeviceExtension(
          OptionalDeviceExtensionVK::kEXTPipelineCreationFeedback);
  if (!supports_pipeline_creation_feedback) {
    chain.unlink<vk::PipelineCreationFeedbackCreateInfoEXT>();
  }

  auto& pipeline_info = chain.get<vk::GraphicsPipelineCreateInfo>();

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

  std::shared_ptr<DeviceHolder> strong_device = device_holder_.lock();
  if (!strong_device) {
    return nullptr;
  }

  auto render_pass =
      CreateCompatRenderPassForPipeline(strong_device->GetDevice(), desc);
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
  std::vector<vk::VertexInputAttributeDescription> attr_descs;
  std::vector<vk::VertexInputBindingDescription> buffer_descs;

  const auto& stage_inputs = desc.GetVertexDescriptor()->GetStageInputs();
  const auto& stage_buffer_layouts =
      desc.GetVertexDescriptor()->GetStageLayouts();
  for (const ShaderStageIOSlot& stage_in : stage_inputs) {
    vk::VertexInputAttributeDescription attr_desc;
    attr_desc.setBinding(stage_in.binding);
    attr_desc.setLocation(stage_in.location);
    attr_desc.setFormat(ToVertexDescriptorFormat(stage_in));
    attr_desc.setOffset(stage_in.offset);
    attr_descs.push_back(attr_desc);
  }
  for (const ShaderStageBufferLayout& layout : stage_buffer_layouts) {
    vk::VertexInputBindingDescription binding_description;
    binding_description.setBinding(layout.binding);
    binding_description.setInputRate(vk::VertexInputRate::eVertex);
    binding_description.setStride(layout.stride);
    buffer_descs.push_back(binding_description);
  }

  vk::PipelineVertexInputStateCreateInfo vertex_input_state;
  vertex_input_state.setVertexAttributeDescriptions(attr_descs);
  vertex_input_state.setVertexBindingDescriptions(buffer_descs);

  pipeline_info.setPVertexInputState(&vertex_input_state);

  //----------------------------------------------------------------------------
  /// Pipeline Layout a.k.a the descriptor sets and uniforms.
  ///
  std::vector<vk::DescriptorSetLayoutBinding> desc_bindings;

  for (auto layout : desc.GetVertexDescriptor()->GetDescriptorSetLayouts()) {
    auto vk_desc_layout = ToVKDescriptorSetLayoutBinding(layout);
    desc_bindings.push_back(vk_desc_layout);
  }

  vk::DescriptorSetLayoutCreateInfo descs_layout_info;
  descs_layout_info.setBindings(desc_bindings);

  auto [descs_result, descs_layout] =
      strong_device->GetDevice().createDescriptorSetLayoutUnique(
          descs_layout_info);
  if (descs_result != vk::Result::eSuccess) {
    VALIDATION_LOG << "unable to create uniform descriptors";
    return nullptr;
  }

  ContextVK::SetDebugName(strong_device->GetDevice(), descs_layout.get(),
                          "Descriptor Set Layout " + desc.GetLabel());

  //----------------------------------------------------------------------------
  /// Create the pipeline layout.
  ///
  vk::PipelineLayoutCreateInfo pipeline_layout_info;
  pipeline_layout_info.setSetLayouts(descs_layout.get());
  auto pipeline_layout = strong_device->GetDevice().createPipelineLayoutUnique(
      pipeline_layout_info);
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
  /// Setup the optional pipeline creation feedback struct so we can understand
  /// how Vulkan created the PSO.
  ///
  auto& feedback = chain.get<vk::PipelineCreationFeedbackCreateInfoEXT>();
  auto pipeline_feedback = EmptyFeedback();
  std::vector<vk::PipelineCreationFeedbackEXT> stage_feedbacks(
      pipeline_info.stageCount, EmptyFeedback());
  feedback.setPPipelineCreationFeedback(&pipeline_feedback);
  feedback.setPipelineStageCreationFeedbacks(stage_feedbacks);

  //----------------------------------------------------------------------------
  /// Finally, all done with the setup info. Create the pipeline itself.
  ///
  auto pipeline = pso_cache_->CreatePipeline(pipeline_info);
  if (!pipeline) {
    VALIDATION_LOG << "Could not create graphics pipeline: " << desc.GetLabel();
    return nullptr;
  }

  if (supports_pipeline_creation_feedback) {
    ReportPipelineCreationFeedback(desc, feedback);
  }

  ContextVK::SetDebugName(strong_device->GetDevice(), *pipeline_layout.value,
                          "Pipeline Layout " + desc.GetLabel());
  ContextVK::SetDebugName(strong_device->GetDevice(), *pipeline,
                          "Pipeline " + desc.GetLabel());

  return std::make_unique<PipelineVK>(device_holder_,
                                      weak_from_this(),                  //
                                      desc,                              //
                                      std::move(pipeline),               //
                                      std::move(render_pass),            //
                                      std::move(pipeline_layout.value),  //
                                      std::move(descs_layout)            //
  );
}

std::unique_ptr<ComputePipelineVK> PipelineLibraryVK::CreateComputePipeline(
    const ComputePipelineDescriptor& desc) {
  TRACE_EVENT0("flutter", __FUNCTION__);
  vk::ComputePipelineCreateInfo pipeline_info;

  //----------------------------------------------------------------------------
  /// Shader Stage
  ///
  const auto entrypoint = desc.GetStageEntrypoint();
  if (!entrypoint) {
    VALIDATION_LOG << "Compute shader is missing an entrypoint.";
    return nullptr;
  }

  std::shared_ptr<DeviceHolder> strong_device = device_holder_.lock();
  if (!strong_device) {
    return nullptr;
  }
  auto device_properties = strong_device->GetPhysicalDevice().getProperties();
  auto max_wg_size = device_properties.limits.maxComputeWorkGroupSize;

  // Give all compute shaders a specialization constant entry for the
  // workgroup/threadgroup size.
  vk::SpecializationMapEntry specialization_map_entry[1];

  uint32_t workgroup_size_x = max_wg_size[0];
  specialization_map_entry[0].constantID = 0;
  specialization_map_entry[0].offset = 0;
  specialization_map_entry[0].size = sizeof(uint32_t);

  vk::SpecializationInfo specialization_info;
  specialization_info.mapEntryCount = 1;
  specialization_info.pMapEntries = &specialization_map_entry[0];
  specialization_info.dataSize = sizeof(uint32_t);
  specialization_info.pData = &workgroup_size_x;

  vk::PipelineShaderStageCreateInfo info;
  info.setStage(vk::ShaderStageFlagBits::eCompute);
  info.setPName("main");
  info.setModule(ShaderFunctionVK::Cast(entrypoint.get())->GetModule());
  info.setPSpecializationInfo(&specialization_info);
  pipeline_info.setStage(info);

  //----------------------------------------------------------------------------
  /// Pipeline Layout a.k.a the descriptor sets and uniforms.
  ///
  std::vector<vk::DescriptorSetLayoutBinding> desc_bindings;

  for (auto layout : desc.GetDescriptorSetLayouts()) {
    auto vk_desc_layout = ToVKDescriptorSetLayoutBinding(layout);
    desc_bindings.push_back(vk_desc_layout);
  }

  vk::DescriptorSetLayoutCreateInfo descs_layout_info;
  descs_layout_info.setBindings(desc_bindings);

  auto [descs_result, descs_layout] =
      strong_device->GetDevice().createDescriptorSetLayoutUnique(
          descs_layout_info);
  if (descs_result != vk::Result::eSuccess) {
    VALIDATION_LOG << "unable to create uniform descriptors";
    return nullptr;
  }

  ContextVK::SetDebugName(strong_device->GetDevice(), descs_layout.get(),
                          "Descriptor Set Layout " + desc.GetLabel());

  //----------------------------------------------------------------------------
  /// Create the pipeline layout.
  ///
  vk::PipelineLayoutCreateInfo pipeline_layout_info;
  pipeline_layout_info.setSetLayouts(descs_layout.get());
  auto pipeline_layout = strong_device->GetDevice().createPipelineLayoutUnique(
      pipeline_layout_info);
  if (pipeline_layout.result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create pipeline layout for pipeline "
                   << desc.GetLabel() << ": "
                   << vk::to_string(pipeline_layout.result);
    return nullptr;
  }
  pipeline_info.setLayout(pipeline_layout.value.get());

  //----------------------------------------------------------------------------
  /// Finally, all done with the setup info. Create the pipeline itself.
  ///
  auto pipeline = pso_cache_->CreatePipeline(pipeline_info);
  if (!pipeline) {
    VALIDATION_LOG << "Could not create graphics pipeline: " << desc.GetLabel();
    return nullptr;
  }

  ContextVK::SetDebugName(strong_device->GetDevice(), *pipeline_layout.value,
                          "Pipeline Layout " + desc.GetLabel());
  ContextVK::SetDebugName(strong_device->GetDevice(), *pipeline,
                          "Pipeline " + desc.GetLabel());

  return std::make_unique<ComputePipelineVK>(
      device_holder_,
      weak_from_this(),                  //
      desc,                              //
      std::move(pipeline),               //
      std::move(pipeline_layout.value),  //
      std::move(descs_layout)            //
  );
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

    auto pipeline = PipelineLibraryVK::Cast(*thiz).CreatePipeline(descriptor);
    if (!pipeline) {
      promise->set_value(nullptr);
      VALIDATION_LOG << "Could not create pipeline: " << descriptor.GetLabel();
      return;
    }

    promise->set_value(std::move(pipeline));
  });

  return pipeline_future;
}

// |PipelineLibrary|
PipelineFuture<ComputePipelineDescriptor> PipelineLibraryVK::GetPipeline(
    ComputePipelineDescriptor descriptor) {
  Lock lock(compute_pipelines_mutex_);
  if (auto found = compute_pipelines_.find(descriptor);
      found != compute_pipelines_.end()) {
    return found->second;
  }

  if (!IsValid()) {
    return {
        descriptor,
        RealizedFuture<std::shared_ptr<Pipeline<ComputePipelineDescriptor>>>(
            nullptr)};
  }

  auto promise = std::make_shared<
      std::promise<std::shared_ptr<Pipeline<ComputePipelineDescriptor>>>>();
  auto pipeline_future = PipelineFuture<ComputePipelineDescriptor>{
      descriptor, promise->get_future()};
  compute_pipelines_[descriptor] = pipeline_future;

  auto weak_this = weak_from_this();

  worker_task_runner_->PostTask([descriptor, weak_this, promise]() {
    auto self = weak_this.lock();
    if (!self) {
      promise->set_value(nullptr);
      VALIDATION_LOG << "Pipeline library was collected before the pipeline "
                        "could be created.";
      return;
    }

    auto pipeline =
        PipelineLibraryVK::Cast(*self).CreateComputePipeline(descriptor);
    if (!pipeline) {
      promise->set_value(nullptr);
      VALIDATION_LOG << "Could not create pipeline: " << descriptor.GetLabel();
      return;
    }

    promise->set_value(std::move(pipeline));
  });

  return pipeline_future;
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

void PipelineLibraryVK::DidAcquireSurfaceFrame() {
  if (++frames_acquired_ == 50u) {
    PersistPipelineCacheToDisk();
  }
}

void PipelineLibraryVK::PersistPipelineCacheToDisk() {
  worker_task_runner_->PostTask(
      [weak_cache = decltype(pso_cache_)::weak_type(pso_cache_)]() {
        auto cache = weak_cache.lock();
        if (!cache) {
          return;
        }
        cache->PersistCacheToDisk();
      });
}

}  // namespace impeller
