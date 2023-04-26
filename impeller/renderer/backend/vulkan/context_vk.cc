// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/context_vk.h"

#include <map>
#include <memory>
#include <optional>
#include <set>
#include <string>
#include <vector>

#include "flutter/fml/build_config.h"
#include "flutter/fml/string_conversion.h"
#include "flutter/fml/trace_event.h"
#include "impeller/base/validation.h"
#include "impeller/renderer/backend/vulkan/allocator_vk.h"
#include "impeller/renderer/backend/vulkan/capabilities_vk.h"
#include "impeller/renderer/backend/vulkan/command_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/command_encoder_vk.h"
#include "impeller/renderer/backend/vulkan/command_pool_vk.h"
#include "impeller/renderer/backend/vulkan/debug_report_vk.h"
#include "impeller/renderer/backend/vulkan/fence_waiter_vk.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/surface_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/capabilities.h"

VULKAN_HPP_DEFAULT_DISPATCH_LOADER_DYNAMIC_STORAGE

namespace impeller {

// TODO(csg): Fix this after caps are reworked.
static bool gHasValidationLayers = false;

bool HasValidationLayers() {
  return gHasValidationLayers;
}

static std::optional<vk::PhysicalDevice> PickPhysicalDevice(
    const CapabilitiesVK& caps,
    const vk::Instance& instance) {
  for (const auto& device : instance.enumeratePhysicalDevices().value) {
    if (caps.GetRequiredDeviceFeatures(device).has_value()) {
      return device;
    }
  }
  return std::nullopt;
}

static std::vector<vk::DeviceQueueCreateInfo> GetQueueCreateInfos(
    std::initializer_list<QueueIndexVK> queues) {
  std::map<size_t /* family */, size_t /* index */> family_index_map;
  for (const auto& queue : queues) {
    family_index_map[queue.family] = 0;
  }
  for (const auto& queue : queues) {
    auto value = family_index_map[queue.family];
    family_index_map[queue.family] = std::max(value, queue.index);
  }

  static float kQueuePriority = 1.0f;
  std::vector<vk::DeviceQueueCreateInfo> infos;
  for (const auto& item : family_index_map) {
    vk::DeviceQueueCreateInfo info;
    info.setQueueFamilyIndex(item.first);
    info.setQueueCount(item.second + 1);
    info.setQueuePriorities(kQueuePriority);
    infos.push_back(info);
  }
  return infos;
}

static std::optional<QueueIndexVK> PickQueue(const vk::PhysicalDevice& device,
                                             vk::QueueFlagBits flags) {
  // This can be modified to ensure that dedicated queues are returned for each
  // queue type depending on support.
  const auto families = device.getQueueFamilyProperties();
  for (size_t i = 0u; i < families.size(); i++) {
    if (!(families[i].queueFlags & flags)) {
      continue;
    }
    return QueueIndexVK{.family = i, .index = 0};
  }
  return std::nullopt;
}

std::shared_ptr<ContextVK> ContextVK::Create(Settings settings) {
  auto context = std::shared_ptr<ContextVK>(new ContextVK());
  context->Setup(std::move(settings));
  if (!context->IsValid()) {
    return nullptr;
  }
  return context;
}

namespace {
thread_local uint64_t tls_context_count = 0;
uint64_t CalculateHash(void* ptr) {
  // You could make a context once per nanosecond for 584 years on one thread
  // before this overflows.
  return ++tls_context_count;
}
}  // namespace

ContextVK::ContextVK() : hash_(CalculateHash(this)) {}

ContextVK::~ContextVK() {
  if (device_) {
    [[maybe_unused]] auto result = device_->waitIdle();
  }
  CommandPoolVK::ClearAllPools(this);
}

void ContextVK::Setup(Settings settings) {
  TRACE_EVENT0("impeller", "ContextVK::Setup");

  if (!settings.proc_address_callback) {
    return;
  }

  auto& dispatcher = VULKAN_HPP_DEFAULT_DISPATCHER;
  dispatcher.init(settings.proc_address_callback);

  auto caps = std::shared_ptr<CapabilitiesVK>(
      new CapabilitiesVK(settings.enable_validation));

  if (!caps->IsValid()) {
    VALIDATION_LOG << "Could not determine device capabilities.";
    return;
  }

  gHasValidationLayers = caps->AreValidationsEnabled();

  auto enabled_layers = caps->GetRequiredLayers();
  auto enabled_extensions = caps->GetRequiredInstanceExtensions();

  if (!enabled_layers.has_value() || !enabled_extensions.has_value()) {
    VALIDATION_LOG << "Device has insufficient capabilities.";
    return;
  }

  vk::InstanceCreateFlags instance_flags = {};

  if (std::find(enabled_extensions.value().begin(),
                enabled_extensions.value().end(),
                "VK_KHR_portability_enumeration") !=
      enabled_extensions.value().end()) {
    instance_flags |= vk::InstanceCreateFlagBits::eEnumeratePortabilityKHR;
  }

  std::vector<const char*> enabled_layers_c;
  std::vector<const char*> enabled_extensions_c;

  for (const auto& layer : enabled_layers.value()) {
    enabled_layers_c.push_back(layer.c_str());
  }

  for (const auto& ext : enabled_extensions.value()) {
    enabled_extensions_c.push_back(ext.c_str());
  }

  vk::ApplicationInfo application_info;
  application_info.setApplicationVersion(VK_API_VERSION_1_0);
  application_info.setApiVersion(VK_API_VERSION_1_1);
  application_info.setEngineVersion(VK_API_VERSION_1_0);
  application_info.setPEngineName("Impeller");
  application_info.setPApplicationName("Impeller");

  std::vector<vk::ValidationFeatureEnableEXT> enabled_validations = {
      vk::ValidationFeatureEnableEXT::eSynchronizationValidation,
  };

  vk::ValidationFeaturesEXT validation;
  validation.setEnabledValidationFeatures(enabled_validations);

  vk::InstanceCreateInfo instance_info;
  if (caps->AreValidationsEnabled()) {
    instance_info.pNext = &validation;
  }
  instance_info.setPEnabledLayerNames(enabled_layers_c);
  instance_info.setPEnabledExtensionNames(enabled_extensions_c);
  instance_info.setPApplicationInfo(&application_info);
  instance_info.setFlags(instance_flags);

  auto instance = vk::createInstanceUnique(instance_info);
  if (instance.result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create Vulkan instance: "
                   << vk::to_string(instance.result);
    return;
  }

  dispatcher.init(instance.value.get());

  //----------------------------------------------------------------------------
  /// Setup the debug report.
  ///
  /// Do this as early as possible since we could use the debug report from
  /// initialization issues.
  ///
  auto debug_report =
      std::make_unique<DebugReportVK>(*caps, instance.value.get());

  if (!debug_report->IsValid()) {
    VALIDATION_LOG << "Could not setup debug report.";
    return;
  }

  //----------------------------------------------------------------------------
  /// Pick the physical device.
  ///
  auto physical_device = PickPhysicalDevice(*caps, instance.value.get());
  if (!physical_device.has_value()) {
    VALIDATION_LOG << "No valid Vulkan device found.";
    return;
  }

  //----------------------------------------------------------------------------
  /// Pick device queues.
  ///
  auto graphics_queue =
      PickQueue(physical_device.value(), vk::QueueFlagBits::eGraphics);
  auto transfer_queue =
      PickQueue(physical_device.value(), vk::QueueFlagBits::eTransfer);
  auto compute_queue =
      PickQueue(physical_device.value(), vk::QueueFlagBits::eCompute);

  if (!graphics_queue.has_value()) {
    VALIDATION_LOG << "Could not pick graphics queue.";
    return;
  }
  if (!transfer_queue.has_value()) {
    FML_LOG(INFO) << "Dedicated transfer queue not avialable.";
    transfer_queue = graphics_queue.value();
  }
  if (!compute_queue.has_value()) {
    VALIDATION_LOG << "Could not pick compute queue.";
    return;
  }

  //----------------------------------------------------------------------------
  /// Create the logical device.
  ///
  auto enabled_device_extensions =
      caps->GetRequiredDeviceExtensions(physical_device.value());
  if (!enabled_device_extensions.has_value()) {
    // This shouldn't happen since we already did device selection. But doesn't
    // hurt to check again.
    return;
  }

  std::vector<const char*> enabled_device_extensions_c;
  for (const auto& ext : enabled_device_extensions.value()) {
    enabled_device_extensions_c.push_back(ext.c_str());
  }

  const auto queue_create_infos = GetQueueCreateInfos(
      {graphics_queue.value(), compute_queue.value(), transfer_queue.value()});

  const auto required_features =
      caps->GetRequiredDeviceFeatures(physical_device.value());
  if (!required_features.has_value()) {
    // This shouldn't happen since the device can't be picked if this was not
    // true. But doesn't hurt to check.
    return;
  }

  vk::DeviceCreateInfo device_info;

  device_info.setQueueCreateInfos(queue_create_infos);
  device_info.setPEnabledExtensionNames(enabled_device_extensions_c);
  device_info.setPEnabledFeatures(&required_features.value());
  // Device layers are deprecated and ignored.

  auto device = physical_device->createDeviceUnique(device_info);
  if (device.result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create logical device.";
    return;
  }

  if (!caps->SetDevice(physical_device.value())) {
    VALIDATION_LOG << "Capabilities could not be updated.";
    return;
  }

  //----------------------------------------------------------------------------
  /// Create the allocator.
  ///
  auto allocator = std::shared_ptr<AllocatorVK>(new AllocatorVK(
      weak_from_this(),                  //
      application_info.apiVersion,       //
      physical_device.value(),           //
      device.value.get(),                //
      instance.value.get(),              //
      dispatcher.vkGetInstanceProcAddr,  //
      dispatcher.vkGetDeviceProcAddr     //
      ));

  if (!allocator->IsValid()) {
    VALIDATION_LOG << "Could not create memory allocator.";
    return;
  }

  //----------------------------------------------------------------------------
  /// Setup the pipeline library.
  ///
  auto pipeline_library = std::shared_ptr<PipelineLibraryVK>(
      new PipelineLibraryVK(device.value.get(),                   //
                            caps,                                 //
                            std::move(settings.cache_directory),  //
                            settings.worker_task_runner           //
                            ));

  if (!pipeline_library->IsValid()) {
    VALIDATION_LOG << "Could not create pipeline library.";
    return;
  }

  auto sampler_library = std::shared_ptr<SamplerLibraryVK>(
      new SamplerLibraryVK(device.value.get()));

  auto shader_library = std::shared_ptr<ShaderLibraryVK>(
      new ShaderLibraryVK(device.value.get(),              //
                          settings.shader_libraries_data)  //
  );

  if (!shader_library->IsValid()) {
    VALIDATION_LOG << "Could not create shader library.";
    return;
  }

  //----------------------------------------------------------------------------
  /// Create the fence waiter.
  ///
  auto fence_waiter =
      std::shared_ptr<FenceWaiterVK>(new FenceWaiterVK(device.value.get()));
  if (!fence_waiter->IsValid()) {
    VALIDATION_LOG << "Could not create fence waiter.";
    return;
  }

  //----------------------------------------------------------------------------
  /// Fetch the queues.
  ///
  QueuesVK queues(device.value.get(),      //
                  graphics_queue.value(),  //
                  compute_queue.value(),   //
                  transfer_queue.value()   //
  );
  if (!queues.IsValid()) {
    VALIDATION_LOG << "Could not fetch device queues.";
    return;
  }

  VkPhysicalDeviceProperties physical_device_properties;
  dispatcher.vkGetPhysicalDeviceProperties(physical_device.value(),
                                           &physical_device_properties);

  //----------------------------------------------------------------------------
  /// All done!
  ///
  instance_ = std::move(instance.value);
  debug_report_ = std::move(debug_report);
  physical_device_ = physical_device.value();
  device_ = std::move(device.value);
  allocator_ = std::move(allocator);
  shader_library_ = std::move(shader_library);
  sampler_library_ = std::move(sampler_library);
  pipeline_library_ = std::move(pipeline_library);
  queues_ = std::move(queues);
  device_capabilities_ = std::move(caps);
  fence_waiter_ = std::move(fence_waiter);
  device_name_ = std::string(physical_device_properties.deviceName);
  is_valid_ = true;

  //----------------------------------------------------------------------------
  /// Label all the relevant objects. This happens after setup so that the debug
  /// messengers have had a chance to be setup.
  ///
  SetDebugName(device_.get(), device_.get(), "ImpellerDevice");
}

// |Context|
std::string ContextVK::DescribeGpuModel() const {
  return device_name_;
}

bool ContextVK::IsValid() const {
  return is_valid_;
}

std::shared_ptr<Allocator> ContextVK::GetResourceAllocator() const {
  return allocator_;
}

std::shared_ptr<ShaderLibrary> ContextVK::GetShaderLibrary() const {
  return shader_library_;
}

std::shared_ptr<SamplerLibrary> ContextVK::GetSamplerLibrary() const {
  return sampler_library_;
}

std::shared_ptr<PipelineLibrary> ContextVK::GetPipelineLibrary() const {
  return pipeline_library_;
}

std::shared_ptr<CommandBuffer> ContextVK::CreateCommandBuffer() const {
  auto encoder = CreateGraphicsCommandEncoder();
  if (!encoder) {
    return nullptr;
  }
  return std::shared_ptr<CommandBufferVK>(
      new CommandBufferVK(shared_from_this(),  //
                          std::move(encoder))  //
  );
}

vk::Instance ContextVK::GetInstance() const {
  return *instance_;
}

vk::Device ContextVK::GetDevice() const {
  return *device_;
}

std::unique_ptr<Surface> ContextVK::AcquireNextSurface() {
  TRACE_EVENT0("impeller", __FUNCTION__);
  auto surface = swapchain_ ? swapchain_->AcquireNextDrawable() : nullptr;
  if (surface && pipeline_library_) {
    pipeline_library_->DidAcquireSurfaceFrame();
  }
  return surface;
}

#ifdef FML_OS_ANDROID

vk::UniqueSurfaceKHR ContextVK::CreateAndroidSurface(
    ANativeWindow* window) const {
  if (!instance_) {
    return vk::UniqueSurfaceKHR{VK_NULL_HANDLE};
  }

  auto create_info = vk::AndroidSurfaceCreateInfoKHR().setWindow(window);
  auto surface_res = instance_->createAndroidSurfaceKHRUnique(create_info);

  if (surface_res.result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create Android surface, error: "
                   << vk::to_string(surface_res.result);
    return vk::UniqueSurfaceKHR{VK_NULL_HANDLE};
  }

  return std::move(surface_res.value);
}

#endif  // FML_OS_ANDROID

bool ContextVK::SetWindowSurface(vk::UniqueSurfaceKHR surface) {
  auto swapchain = SwapchainVK::Create(shared_from_this(), std::move(surface));
  if (!swapchain) {
    VALIDATION_LOG << "Could not create swapchain.";
    return false;
  }
  swapchain_ = std::move(swapchain);
  return true;
}

const std::shared_ptr<const Capabilities>& ContextVK::GetCapabilities() const {
  return device_capabilities_;
}

const std::shared_ptr<QueueVK>& ContextVK::GetGraphicsQueue() const {
  return queues_.graphics_queue;
}

vk::PhysicalDevice ContextVK::GetPhysicalDevice() const {
  return physical_device_;
}

std::shared_ptr<FenceWaiterVK> ContextVK::GetFenceWaiter() const {
  return fence_waiter_;
}

std::unique_ptr<CommandEncoderVK> ContextVK::CreateGraphicsCommandEncoder()
    const {
  auto tls_pool = CommandPoolVK::GetThreadLocal(this);
  if (!tls_pool) {
    return nullptr;
  }
  auto encoder = std::unique_ptr<CommandEncoderVK>(new CommandEncoderVK(
      *device_,                //
      queues_.graphics_queue,  //
      tls_pool,                //
      fence_waiter_            //
      ));
  if (!encoder->IsValid()) {
    return nullptr;
  }
  return encoder;
}

}  // namespace impeller
