// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_vulkan_layer_composer.h"

#include <utility>

namespace flutter {
namespace {
// Regenerate each array with glslc -O -mfmt=num <source> -o <source>.inc.
constexpr uint32_t kVertex[] = {
#include "flutter/shell/platform/linux/shaders/fl_vulkan_layer.vert.inc"
};
constexpr uint32_t kFragment[] = {
#include "flutter/shell/platform/linux/shaders/fl_vulkan_layer.frag.inc"
};
constexpr VkFormat kFormat = VK_FORMAT_R8G8B8A8_UNORM;
}  // namespace

struct FlVulkanLayerComposer::Impl {
  FlVulkanDeviceContext context;
  VkDevice device;
#define PROC(name)    \
  PFN_vk##name name = \
      reinterpret_cast<PFN_vk##name>(context.get_proc(device, "vk" #name))
  PROC(CreateRenderPass);
  PROC(DestroyRenderPass);
  PROC(CreateSampler);
  PROC(DestroySampler);
  PROC(CreateDescriptorSetLayout);
  PROC(DestroyDescriptorSetLayout);
  PROC(CreatePipelineLayout);
  PROC(DestroyPipelineLayout);
  PROC(CreateShaderModule);
  PROC(DestroyShaderModule);
  PROC(CreateGraphicsPipelines);
  PROC(DestroyPipeline);
  PROC(CreateCommandPool);
  PROC(DestroyCommandPool);
  PROC(AllocateCommandBuffers);
  PROC(ResetCommandPool);
  PROC(CreateFence);
  PROC(DestroyFence);
  PROC(ResetFences);
  PROC(WaitForFences);
  PROC(CreateImageView);
  PROC(DestroyImageView);
  PROC(CreateFramebuffer);
  PROC(DestroyFramebuffer);
  PROC(CreateDescriptorPool);
  PROC(DestroyDescriptorPool);
  PROC(AllocateDescriptorSets);
  PROC(UpdateDescriptorSets);
  PROC(BeginCommandBuffer);
  PROC(EndCommandBuffer);
  PROC(CmdPipelineBarrier);
  PROC(CmdBeginRenderPass);
  PROC(CmdEndRenderPass);
  PROC(CmdBindPipeline);
  PROC(CmdSetViewport);
  PROC(CmdSetScissor);
  PROC(CmdBindDescriptorSets);
  PROC(CmdPushConstants);
  PROC(CmdDraw);
#undef PROC
  VkRenderPass pass = VK_NULL_HANDLE;
  VkSampler sampler = VK_NULL_HANDLE;
  VkDescriptorSetLayout set_layout = VK_NULL_HANDLE;
  VkPipelineLayout layout = VK_NULL_HANDLE;
  VkPipeline pipeline = VK_NULL_HANDLE;
  VkCommandPool commands = VK_NULL_HANDLE;
  VkCommandBuffer command = VK_NULL_HANDLE;
  VkFence fence = VK_NULL_HANDLE;

  explicit Impl(FlVulkanDeviceContext ctx)
      : context(std::move(ctx)), device(context.device) {}
  ~Impl() {
    DestroyFence(device, fence, nullptr);
    DestroyCommandPool(device, commands, nullptr);
    DestroyPipeline(device, pipeline, nullptr);
    DestroyPipelineLayout(device, layout, nullptr);
    DestroyDescriptorSetLayout(device, set_layout, nullptr);
    DestroySampler(device, sampler, nullptr);
    DestroyRenderPass(device, pass, nullptr);
  }
  bool Initialize() {
    VkAttachmentDescription attachment = {};
    attachment.format = kFormat;
    attachment.samples = VK_SAMPLE_COUNT_1_BIT;
    attachment.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR;
    attachment.storeOp = VK_ATTACHMENT_STORE_OP_STORE;
    attachment.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
    attachment.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
    attachment.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
    attachment.finalLayout = VK_IMAGE_LAYOUT_GENERAL;
    VkAttachmentReference color = {0, VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL};
    VkSubpassDescription subpass = {};
    subpass.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
    subpass.colorAttachmentCount = 1;
    subpass.pColorAttachments = &color;
    VkRenderPassCreateInfo rp = {VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO};
    rp.attachmentCount = 1;
    rp.pAttachments = &attachment;
    rp.subpassCount = 1;
    rp.pSubpasses = &subpass;
    if (CreateRenderPass(device, &rp, nullptr, &pass) != VK_SUCCESS)
      return false;
    VkSamplerCreateInfo sampling = {VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO};
    if (CreateSampler(device, &sampling, nullptr, &sampler) != VK_SUCCESS)
      return false;
    VkDescriptorSetLayoutBinding binding = {
        0, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1,
        VK_SHADER_STAGE_FRAGMENT_BIT, &sampler};
    VkDescriptorSetLayoutCreateInfo sets = {
        VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO};
    sets.bindingCount = 1;
    sets.pBindings = &binding;
    if (CreateDescriptorSetLayout(device, &sets, nullptr, &set_layout) !=
        VK_SUCCESS)
      return false;
    VkPushConstantRange origin = {VK_SHADER_STAGE_FRAGMENT_BIT, 0,
                                  sizeof(VkOffset2D)};
    VkPipelineLayoutCreateInfo pl = {
        VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO};
    pl.setLayoutCount = 1;
    pl.pSetLayouts = &set_layout;
    pl.pushConstantRangeCount = 1;
    pl.pPushConstantRanges = &origin;
    if (CreatePipelineLayout(device, &pl, nullptr, &layout) != VK_SUCCESS ||
        !CreatePipeline())
      return false;
    VkCommandPoolCreateInfo cp = {VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO};
    cp.queueFamilyIndex = context.queue_family;
    if (CreateCommandPool(device, &cp, nullptr, &commands) != VK_SUCCESS)
      return false;
    VkCommandBufferAllocateInfo alloc = {
        VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO};
    alloc.commandPool = commands;
    alloc.commandBufferCount = 1;
    VkFenceCreateInfo fi = {VK_STRUCTURE_TYPE_FENCE_CREATE_INFO};
    return AllocateCommandBuffers(device, &alloc, &command) == VK_SUCCESS &&
           CreateFence(device, &fi, nullptr, &fence) == VK_SUCCESS;
  }

  bool CreatePipeline() {
    VkPipelineShaderStageCreateInfo stages[2] = {};
    VkShaderModuleCreateInfo shader = {
        VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO};
    for (size_t i = 0; i < 2; i++) {
      shader.pCode = i == 0 ? kVertex : kFragment;
      shader.codeSize = i == 0 ? sizeof(kVertex) : sizeof(kFragment);
      stages[i].sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
      stages[i].stage =
          i == 0 ? VK_SHADER_STAGE_VERTEX_BIT : VK_SHADER_STAGE_FRAGMENT_BIT;
      stages[i].pName = "main";
      if (CreateShaderModule(device, &shader, nullptr, &stages[i].module) !=
          VK_SUCCESS) {
        DestroyShaderModule(device, stages[0].module, nullptr);
        return false;
      }
    }
    VkPipelineVertexInputStateCreateInfo vertex = {
        VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO};
    VkPipelineInputAssemblyStateCreateInfo assembly = {
        VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO};
    assembly.topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
    VkPipelineViewportStateCreateInfo viewport = {
        VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO};
    viewport.viewportCount = viewport.scissorCount = 1;
    VkPipelineRasterizationStateCreateInfo raster = {
        VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO};
    raster.lineWidth = 1;
    VkPipelineMultisampleStateCreateInfo samples = {
        VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO};
    samples.rasterizationSamples = VK_SAMPLE_COUNT_1_BIT;
    VkPipelineColorBlendAttachmentState blend = {};
    blend.blendEnable = VK_TRUE;
    blend.srcColorBlendFactor = blend.srcAlphaBlendFactor = VK_BLEND_FACTOR_ONE;
    blend.dstColorBlendFactor = blend.dstAlphaBlendFactor =
        VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA;
    blend.colorWriteMask = VK_COLOR_COMPONENT_R_BIT | VK_COLOR_COMPONENT_G_BIT |
                           VK_COLOR_COMPONENT_B_BIT | VK_COLOR_COMPONENT_A_BIT;
    VkPipelineColorBlendStateCreateInfo blending = {
        VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO};
    blending.attachmentCount = 1;
    blending.pAttachments = &blend;
    VkDynamicState dynamic_states[] = {VK_DYNAMIC_STATE_VIEWPORT,
                                       VK_DYNAMIC_STATE_SCISSOR};
    VkPipelineDynamicStateCreateInfo dynamic = {
        VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO};
    dynamic.dynamicStateCount = 2;
    dynamic.pDynamicStates = dynamic_states;
    VkGraphicsPipelineCreateInfo info = {
        VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO};
    info.stageCount = 2;
    info.pStages = stages;
    info.pVertexInputState = &vertex;
    info.pInputAssemblyState = &assembly;
    info.pViewportState = &viewport;
    info.pRasterizationState = &raster;
    info.pMultisampleState = &samples;
    info.pColorBlendState = &blending;
    info.pDynamicState = &dynamic;
    info.layout = layout;
    info.renderPass = pass;
    auto result = CreateGraphicsPipelines(device, VK_NULL_HANDLE, 1, &info,
                                          nullptr, &pipeline);
    for (auto& stage : stages)
      DestroyShaderModule(device, stage.module, nullptr);
    return result == VK_SUCCESS;
  }

  VkImageView View(VkImage image) {
    VkImageViewCreateInfo info = {VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO};
    info.image = image;
    info.viewType = VK_IMAGE_VIEW_TYPE_2D;
    info.format = kFormat;
    info.subresourceRange = {VK_IMAGE_ASPECT_COLOR_BIT, 0, 1, 0, 1};
    VkImageView view = VK_NULL_HANDLE;
    return CreateImageView(device, &info, nullptr, &view) == VK_SUCCESS
               ? view
               : VK_NULL_HANDLE;
  }
  struct Resources {
    Impl& impl;
    VkFramebuffer framebuffer = VK_NULL_HANDLE;
    VkDescriptorPool pool = VK_NULL_HANDLE;
    std::vector<VkImageView> views;
    ~Resources() {
      impl.DestroyFramebuffer(impl.device, framebuffer, nullptr);
      impl.DestroyDescriptorPool(impl.device, pool, nullptr);
      for (auto view : views)
        impl.DestroyImageView(impl.device, view, nullptr);
    }
  };
  bool Draw(VkImage target,
            VkExtent2D size,
            const std::vector<FlVulkanLayer>& layers) {
    Resources frame{*this};
    frame.views.push_back(View(target));
    if (!frame.views.back())
      return false;
    VkFramebufferCreateInfo fb = {VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO};
    fb.renderPass = pass;
    fb.attachmentCount = 1;
    fb.pAttachments = frame.views.data();
    fb.width = size.width;
    fb.height = size.height;
    fb.layers = 1;
    if (CreateFramebuffer(device, &fb, nullptr, &frame.framebuffer) !=
        VK_SUCCESS)
      return false;
    uint32_t count = static_cast<uint32_t>(layers.size());
    VkDescriptorPoolSize pool_size = {VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                                      count};
    VkDescriptorPoolCreateInfo pool_info = {
        VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO};
    pool_info.maxSets = count;
    pool_info.poolSizeCount = 1;
    pool_info.pPoolSizes = &pool_size;
    if (CreateDescriptorPool(device, &pool_info, nullptr, &frame.pool) !=
        VK_SUCCESS)
      return false;
    std::vector<VkDescriptorSetLayout> layouts(count, set_layout);
    std::vector<VkDescriptorSet> sets(count);
    VkDescriptorSetAllocateInfo allocate = {
        VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO};
    allocate.descriptorPool = frame.pool;
    allocate.descriptorSetCount = count;
    allocate.pSetLayouts = layouts.data();
    if (AllocateDescriptorSets(device, &allocate, sets.data()) != VK_SUCCESS)
      return false;
    for (size_t i = 0; i < layers.size(); i++) {
      frame.views.push_back(View(layers[i].image));
      if (!frame.views.back())
        return false;
      VkDescriptorImageInfo image = {sampler, frame.views.back(),
                                     VK_IMAGE_LAYOUT_GENERAL};
      VkWriteDescriptorSet write = {VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET};
      write.dstSet = sets[i];
      write.descriptorCount = 1;
      write.descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
      write.pImageInfo = &image;
      UpdateDescriptorSets(device, 1, &write, 0, nullptr);
    }
    VkCommandBufferBeginInfo begin = {
        VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO};
    begin.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
    if (ResetCommandPool(device, commands, 0) != VK_SUCCESS ||
        BeginCommandBuffer(command, &begin) != VK_SUCCESS)
      return false;
    // Impeller leaves the input images in GENERAL. Keep that layout so even
    // repeated references to the same backing store remain valid.
    VkMemoryBarrier inputs = {VK_STRUCTURE_TYPE_MEMORY_BARRIER};
    inputs.srcAccessMask = VK_ACCESS_MEMORY_WRITE_BIT;
    inputs.dstAccessMask = VK_ACCESS_SHADER_READ_BIT;
    CmdPipelineBarrier(command, VK_PIPELINE_STAGE_ALL_COMMANDS_BIT,
                       VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, 0, 1, &inputs, 0,
                       nullptr, 0, nullptr);
    VkClearValue clear = {};
    VkRenderPassBeginInfo render = {VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO};
    render.renderPass = pass;
    render.framebuffer = frame.framebuffer;
    render.renderArea.extent = size;
    render.clearValueCount = 1;
    render.pClearValues = &clear;
    CmdBeginRenderPass(command, &render, VK_SUBPASS_CONTENTS_INLINE);
    CmdBindPipeline(command, VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline);
    VkViewport viewport = {
        0, 0, static_cast<float>(size.width), static_cast<float>(size.height),
        0, 1};
    CmdSetViewport(command, 0, 1, &viewport);
    for (size_t i = 0; i < layers.size(); i++) {
      const auto& rect = layers[i].bounds;
      CmdSetScissor(command, 0, 1, &rect);
      CmdPushConstants(command, layout, VK_SHADER_STAGE_FRAGMENT_BIT, 0,
                       sizeof(rect.offset), &rect.offset);
      CmdBindDescriptorSets(command, VK_PIPELINE_BIND_POINT_GRAPHICS, layout, 0,
                            1, &sets[i], 0, nullptr);
      CmdDraw(command, 3, 1, 0, 0);
    }
    CmdEndRenderPass(command);
    if (EndCommandBuffer(command) != VK_SUCCESS ||
        ResetFences(device, 1, &fence) != VK_SUCCESS)
      return false;
    VkSubmitInfo submit = {VK_STRUCTURE_TYPE_SUBMIT_INFO};
    submit.commandBufferCount = 1;
    submit.pCommandBuffers = &command;
    return context.submit(context.queue, 1, &submit, fence) == VK_SUCCESS &&
           WaitForFences(device, 1, &fence, VK_TRUE, UINT64_MAX) == VK_SUCCESS;
  }
};

FlVulkanLayerComposer::FlVulkanLayerComposer(FlVulkanDeviceContext context)
    : impl_(std::make_unique<Impl>(std::move(context))) {
  if (!impl_->Initialize())
    impl_.reset();
}
FlVulkanLayerComposer::~FlVulkanLayerComposer() = default;
bool FlVulkanLayerComposer::Draw(VkImage target,
                                 VkExtent2D size,
                                 const std::vector<FlVulkanLayer>& layers) {
  return impl_ && impl_->Draw(target, size, layers);
}
}  // namespace flutter
