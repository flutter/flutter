// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/jni_delegate.h"

#include <unistd.h>
#include <cstring>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/platform/android/android_vsync_waiter.h"

namespace flutter {
namespace android {

namespace {

struct VulkanStructFrameKeeper {
  FlutterVulkanYcbcrConversionInfo ycbcr_info = {};
  bool has_ycbcr_info = false;
  VoidCallback user_callback = nullptr;
  void* user_data = nullptr;
};

}  // namespace

JniDelegate::JniDelegate(
    std::shared_ptr<JvmInvoker> jvm_invoker,
    std::shared_ptr<CallbackCacheProvider> callback_cache,
    std::shared_ptr<ImageDecoderProvider> image_decoder,
    std::shared_ptr<PlatformViewsProvider> platform_views_provider,
    std::shared_ptr<AndroidPlatformViewsController> platform_views_controller,
    std::shared_ptr<WindowMetricsProvider> window_metrics_provider,
    std::shared_ptr<AndroidVsyncWaiter> vsync_waiter,
    std::shared_ptr<AndroidVMInit> vm_init,
    std::shared_ptr<AndroidHardwareBufferProvider> hardware_buffer_provider,
    std::shared_ptr<AndroidVulkanTextureProvider> vulkan_texture_provider,
    std::shared_ptr<AndroidSurfaceControlProvider> surface_control_provider,
    std::shared_ptr<AndroidEngineGroupProvider> engine_group_provider,
    std::shared_ptr<AndroidEngineGroup> engine_group)
    : jvm_invoker_(std::move(jvm_invoker)),
      callback_cache_(callback_cache
                          ? std::move(callback_cache)
                          : std::make_shared<DefaultCallbackCacheProvider>()),
      image_decoder_(std::move(image_decoder)),
      platform_views_provider_(std::move(platform_views_provider)),
      platform_views_controller_(std::move(platform_views_controller)),
      window_metrics_provider_(std::move(window_metrics_provider)),
      vsync_waiter_(std::move(vsync_waiter)),
      vm_init_(std::move(vm_init)),
      hardware_buffer_provider_(std::move(hardware_buffer_provider)),
      vulkan_texture_provider_(std::move(vulkan_texture_provider)),
      surface_control_provider_(std::move(surface_control_provider)),
      engine_group_provider_(std::move(engine_group_provider)),
      engine_group_(std::move(engine_group)) {
  TRACE_EVENT0("flutter", "JniDelegate::JniDelegate");
  FML_DCHECK(jvm_invoker_ != nullptr);
  if (!platform_views_provider_) {
    platform_views_provider_ =
        std::make_shared<DefaultPlatformViewsProvider>(jvm_invoker_);
  }
  if (!window_metrics_provider_) {
    window_metrics_provider_ =
        std::make_shared<DefaultWindowMetricsProvider>(jvm_invoker_);
  }
  if (!platform_views_controller_) {
    platform_views_controller_ =
        std::make_shared<AndroidPlatformViewsController>(
            platform_views_provider_);
  }
  if (!vm_init_) {
    vm_init_ = std::make_shared<AndroidVMInit>(jvm_invoker_);
  }
  if (!hardware_buffer_provider_) {
    hardware_buffer_provider_ =
        std::make_shared<DefaultAndroidHardwareBufferProvider>();
  }
  if (!vulkan_texture_provider_) {
    vulkan_texture_provider_ =
        std::make_shared<DefaultAndroidVulkanTextureProvider>();
  }
  if (!surface_control_provider_) {
    surface_control_provider_ =
        std::make_shared<DefaultAndroidSurfaceControlProvider>();
  }
  if (!engine_group_provider_) {
    engine_group_provider_ =
        std::make_shared<DefaultAndroidEngineGroupProvider>();
  }
  if (!engine_group_) {
    engine_group_ = std::make_shared<AndroidEngineGroup>(engine_group_provider_,
                                                         jvm_invoker_);
  }
}

JniDelegate::~JniDelegate() {
  TRACE_EVENT0("flutter", "JniDelegate::~JniDelegate");
  std::vector<std::pair<VoidCallback, void*>> callbacks_to_invoke;
  std::vector<int32_t> fences_to_close;
  {
    std::lock_guard<std::mutex> lock(hardware_buffer_mutex_);
    for (auto& [id, frame] : hardware_buffer_frames_) {
      if (frame.destruction_callback) {
        callbacks_to_invoke.emplace_back(frame.destruction_callback,
                                         frame.user_data);
      }
      if (frame.fence_fd >= 0) {
        fences_to_close.push_back(frame.fence_fd);
      }
    }
    hardware_buffer_frames_.clear();
    hardware_buffer_objects_.clear();
    registered_hardware_textures_.clear();
  }
  for (int32_t fd : fences_to_close) {
    close(fd);
  }
  for (const auto& [cb, data] : callbacks_to_invoke) {
    cb(data);
  }

  std::vector<std::pair<VoidCallback, void*>> vk_destruction_callbacks;
  {
    std::lock_guard<std::mutex> lock(vulkan_texture_mutex_);
    for (auto& [id, frame] : vulkan_texture_frames_) {
      if (frame.destruction_callback) {
        vk_destruction_callbacks.emplace_back(frame.destruction_callback,
                                              frame.user_data);
      }
    }
    vulkan_texture_frames_.clear();
    vulkan_texture_objects_.clear();
    registered_vulkan_textures_.clear();
  }
  for (const auto& [cb, data] : vk_destruction_callbacks) {
    cb(data);
  }
}

std::shared_ptr<JvmInvoker> JniDelegate::GetJvmInvoker() const {
  return jvm_invoker_;
}

bool JniDelegate::HandlePlatformMessage(const std::string& channel,
                                        const uint8_t* message,
                                        size_t message_size,
                                        int32_t response_id,
                                        int64_t message_data) {
  TRACE_EVENT1("flutter", "JniDelegate::HandlePlatformMessage", "channel",
               channel.c_str());
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->HandlePlatformMessage(channel, message, message_size,
                                             response_id, message_data);
}

bool JniDelegate::HandlePlatformMessage(const std::string& channel,
                                        const std::vector<uint8_t>& message,
                                        int32_t response_id,
                                        int64_t message_data) {
  return HandlePlatformMessage(channel, message.data(), message.size(),
                               response_id, message_data);
}

bool JniDelegate::HandlePlatformMessageResponse(int32_t response_id,
                                                const uint8_t* data,
                                                size_t data_size) {
  TRACE_EVENT0("flutter", "JniDelegate::HandlePlatformMessageResponse");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->HandlePlatformMessageResponse(response_id, data,
                                                     data_size);
}

bool JniDelegate::HandlePlatformMessageResponse(
    int32_t response_id,
    const std::vector<uint8_t>& data) {
  return HandlePlatformMessageResponse(response_id, data.data(), data.size());
}

bool JniDelegate::UpdateSemantics(
    const std::vector<uint8_t>& buffer,
    const std::vector<std::string>& strings,
    const std::vector<std::vector<uint8_t>>& string_attribute_args) {
  TRACE_EVENT0("flutter", "JniDelegate::UpdateSemantics");
  if (!jvm_invoker_) {
    return false;
  }
  if (buffer.empty()) {
    return true;
  }
  return jvm_invoker_->UpdateSemantics(buffer, strings, string_attribute_args);
}

bool JniDelegate::UpdateCustomAccessibilityActions(
    const std::vector<uint8_t>& actions_buffer,
    const std::vector<std::string>& action_strings) {
  TRACE_EVENT0("flutter", "JniDelegate::UpdateCustomAccessibilityActions");
  if (!jvm_invoker_) {
    return false;
  }
  if (actions_buffer.empty()) {
    return true;
  }
  return jvm_invoker_->UpdateCustomAccessibilityActions(actions_buffer,
                                                        action_strings);
}

bool JniDelegate::UpdateSemantics(const FlutterSemanticsUpdate2& update) {
  TRACE_EVENT0("flutter", "JniDelegate::UpdateSemantics(struct)");
  EncodedSemanticsBatch batch =
      AndroidSemanticsMapper::MapSemanticsUpdate(update);
  bool success = true;
  if (!batch.custom_actions.empty()) {
    success &= UpdateCustomAccessibilityActions(batch.custom_actions.buffer,
                                                batch.custom_actions.strings);
  }
  if (!batch.nodes.empty()) {
    success &= UpdateSemantics(batch.nodes.buffer, batch.nodes.strings,
                               batch.nodes.string_attribute_args);
  }
  return success;
}

bool JniDelegate::SetSemanticsTreeEnabled(bool enabled) {
  TRACE_EVENT0("flutter", "JniDelegate::SetSemanticsTreeEnabled");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->SetSemanticsTreeEnabled(enabled);
}

bool JniDelegate::SetApplicationLocale(const std::string& locale) {
  TRACE_EVENT1("flutter", "JniDelegate::SetApplicationLocale", "locale",
               locale.c_str());
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->SetApplicationLocale(locale);
}

bool JniDelegate::OnFirstFrame() {
  TRACE_EVENT0("flutter", "JniDelegate::OnFirstFrame");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->OnFirstFrame();
}

bool JniDelegate::OnPreEngineRestart() {
  TRACE_EVENT0("flutter", "JniDelegate::OnPreEngineRestart");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->OnPreEngineRestart();
}

bool JniDelegate::OnVsync(int64_t frame_time_nanos,
                          int64_t frame_target_time_nanos) {
  TRACE_EVENT0("flutter", "JniDelegate::OnVsync");
  if (!jvm_invoker_) {
    return false;
  }
  struct PackedVsync {
    int64_t frame_time_nanos;
    int64_t frame_target_time_nanos;
  };
  PackedVsync data = {frame_time_nanos, frame_target_time_nanos};
  std::vector<uint8_t> payload(sizeof(PackedVsync));
  std::memcpy(payload.data(), &data, sizeof(PackedVsync));
  return jvm_invoker_->InvokeVoidMethod("onVsync", "(JJ)V", payload);
}

bool JniDelegate::AsyncWaitForVsync(intptr_t baton) {
  TRACE_EVENT1("flutter", "JniDelegate::AsyncWaitForVsync", "baton",
               std::to_string(baton).c_str());
  std::shared_ptr<AndroidVsyncWaiter> waiter;
  {
    std::scoped_lock lock(vsync_waiter_mutex_);
    waiter = vsync_waiter_;
  }
  if (waiter) {
    return waiter->AsyncWaitForVsync(baton);
  }
  if (!jvm_invoker_) {
    return false;
  }
  int64_t baton_64 = static_cast<int64_t>(baton);
  std::vector<uint8_t> payload(sizeof(int64_t));
  std::memcpy(payload.data(), &baton_64, sizeof(int64_t));
  return jvm_invoker_->InvokeVoidMethod("asyncWaitForVsync", "(J)V", payload);
}

bool JniDelegate::SetViewportMetrics(const AndroidViewportMetrics& metrics) {
  TRACE_EVENT0("flutter", "JniDelegate::SetViewportMetrics");
  std::shared_ptr<WindowMetricsProvider> provider;
  {
    std::scoped_lock lock(window_metrics_provider_mutex_);
    provider = window_metrics_provider_;
  }
  if (provider) {
    return provider->SendViewportMetrics(metrics);
  }
  if (!jvm_invoker_) {
    return false;
  }
  PackedViewportMetrics payload_data = {
      metrics.view_id,
      metrics.physical_width,
      metrics.physical_height,
      metrics.device_pixel_ratio,
  };
  std::vector<uint8_t> payload(sizeof(PackedViewportMetrics));
  std::memcpy(payload.data(), &payload_data, sizeof(PackedViewportMetrics));
  return jvm_invoker_->InvokeVoidMethod("onViewportMetrics", "(JDDD)V",
                                        payload);
}

bool JniDelegate::UpdateDisplayMetrics(const AndroidDisplayMetrics& metrics) {
  TRACE_EVENT0("flutter", "JniDelegate::UpdateDisplayMetrics(struct)");
  std::shared_ptr<WindowMetricsProvider> provider;
  {
    std::scoped_lock lock(window_metrics_provider_mutex_);
    provider = window_metrics_provider_;
  }
  if (provider) {
    return provider->UpdateDisplayMetrics(metrics);
  }
  if (!jvm_invoker_) {
    return false;
  }
  PackedDisplayMetrics payload_data = {
      static_cast<int64_t>(metrics.display_id),
      metrics.refresh_rate,
      metrics.width,
      metrics.height,
      metrics.device_pixel_ratio,
  };
  std::vector<uint8_t> payload(sizeof(PackedDisplayMetrics));
  std::memcpy(payload.data(), &payload_data, sizeof(PackedDisplayMetrics));
  return jvm_invoker_->InvokeVoidMethod("onDisplayMetrics", "(JDDDD)V",
                                        payload);
}

bool JniDelegate::UpdateDisplayMetrics(uint64_t display_id,
                                       double refresh_rate,
                                       double width,
                                       double height,
                                       double device_pixel_ratio) {
  TRACE_EVENT0("flutter", "JniDelegate::UpdateDisplayMetrics(params)");
  AndroidDisplayMetrics metrics;
  metrics.display_id = display_id;
  metrics.single_display = true;
  {
    std::scoped_lock lock(window_metrics_provider_mutex_);
    if (window_metrics_provider_) {
      auto existing_0 = window_metrics_provider_->GetDisplayMetrics(0);
      if (display_id != 0 && existing_0.has_value()) {
        metrics.single_display = false;
      }
    }
  }
  metrics.refresh_rate = refresh_rate;
  metrics.width = width;
  metrics.height = height;
  metrics.device_pixel_ratio = device_pixel_ratio;
  return UpdateDisplayMetrics(metrics);
}

std::optional<AndroidViewportMetrics> JniDelegate::GetViewportMetrics(
    int64_t view_id) const {
  TRACE_EVENT0("flutter", "JniDelegate::GetViewportMetrics");
  std::shared_ptr<WindowMetricsProvider> provider;
  {
    std::scoped_lock lock(window_metrics_provider_mutex_);
    provider = window_metrics_provider_;
  }
  if (provider) {
    return provider->GetViewportMetrics(view_id);
  }
  return std::nullopt;
}

std::optional<AndroidDisplayMetrics> JniDelegate::GetDisplayMetrics(
    uint64_t display_id) const {
  TRACE_EVENT0("flutter", "JniDelegate::GetDisplayMetrics");
  std::shared_ptr<WindowMetricsProvider> provider;
  {
    std::scoped_lock lock(window_metrics_provider_mutex_);
    provider = window_metrics_provider_;
  }
  if (provider) {
    return provider->GetDisplayMetrics(display_id);
  }
  return std::nullopt;
}

bool JniDelegate::DispatchViewportMetrics(int64_t view_id,
                                          double width,
                                          double height,
                                          double pixel_ratio) {
  TRACE_EVENT0("flutter", "JniDelegate::DispatchViewportMetrics");
  AndroidViewportMetrics metrics;
  metrics.view_id = view_id;
  metrics.physical_width = width;
  metrics.physical_height = height;
  metrics.device_pixel_ratio = pixel_ratio;
  return SetViewportMetrics(metrics);
}

bool JniDelegate::RequestDartDeferredLibrary(int loading_unit_id) {
  TRACE_EVENT0("flutter", "JniDelegate::RequestDartDeferredLibrary");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->RequestDartDeferredLibrary(loading_unit_id);
}

static FlutterEngineResult GetCallbackInformationFromEngine(
    int64_t handle,
    FlutterCallbackInformation* info) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.GetCallbackInformation) {
    return s_procs.GetCallbackInformation(handle, info);
  }
  return kInternalInconsistency;
}

DefaultCallbackCacheProvider::DefaultCallbackCacheProvider() {
  TRACE_EVENT0("flutter",
               "DefaultCallbackCacheProvider::DefaultCallbackCacheProvider");
}

DefaultCallbackCacheProvider::~DefaultCallbackCacheProvider() {
  TRACE_EVENT0("flutter",
               "DefaultCallbackCacheProvider::~DefaultCallbackCacheProvider");
}

std::optional<DartCallbackInfo>
DefaultCallbackCacheProvider::GetCallbackInformation(int64_t handle) {
  TRACE_EVENT0("flutter",
               "DefaultCallbackCacheProvider::GetCallbackInformation");
  FlutterCallbackInformation info = {};
  info.struct_size = sizeof(FlutterCallbackInformation);
  if (GetCallbackInformationFromEngine(handle, &info) == kSuccess) {
    DartCallbackInfo result;
    result.name = info.name ? info.name : "";
    result.class_name = info.class_name ? info.class_name : "";
    result.library_path = info.library_path ? info.library_path : "";
    return result;
  }
  return std::nullopt;
}

InMemoryCallbackCacheProvider::InMemoryCallbackCacheProvider() {
  TRACE_EVENT0("flutter",
               "InMemoryCallbackCacheProvider::InMemoryCallbackCacheProvider");
}

InMemoryCallbackCacheProvider::~InMemoryCallbackCacheProvider() {
  TRACE_EVENT0("flutter",
               "InMemoryCallbackCacheProvider::~InMemoryCallbackCacheProvider");
}

void InMemoryCallbackCacheProvider::AddCallback(
    int64_t handle,
    const std::string& name,
    const std::string& class_name,
    const std::string& library_path) {
  TRACE_EVENT0("flutter", "InMemoryCallbackCacheProvider::AddCallback");
  std::unique_lock lock(mutex_);
  cache_[handle] = DartCallbackInfo{name, class_name, library_path};
}

void InMemoryCallbackCacheProvider::RemoveCallback(int64_t handle) {
  TRACE_EVENT0("flutter", "InMemoryCallbackCacheProvider::RemoveCallback");
  std::unique_lock lock(mutex_);
  cache_.erase(handle);
}

void InMemoryCallbackCacheProvider::Clear() {
  TRACE_EVENT0("flutter", "InMemoryCallbackCacheProvider::Clear");
  std::unique_lock lock(mutex_);
  cache_.clear();
}

size_t InMemoryCallbackCacheProvider::GetSize() const {
  std::shared_lock lock(mutex_);
  return cache_.size();
}

std::optional<DartCallbackInfo>
InMemoryCallbackCacheProvider::GetCallbackInformation(int64_t handle) {
  TRACE_EVENT0("flutter",
               "InMemoryCallbackCacheProvider::GetCallbackInformation");
  std::shared_lock lock(mutex_);
  auto it = cache_.find(handle);
  if (it != cache_.end()) {
    return it->second;
  }
  return std::nullopt;
}

std::optional<DartCallbackInfo> JniDelegate::LookupCallbackInformation(
    int64_t handle) {
  TRACE_EVENT0("flutter", "JniDelegate::LookupCallbackInformation");
  std::shared_ptr<CallbackCacheProvider> cache;
  {
    std::scoped_lock lock(callback_cache_mutex_);
    cache = callback_cache_;
  }
  if (cache) {
    return cache->GetCallbackInformation(handle);
  }
  return std::nullopt;
}

void JniDelegate::SetCallbackCache(
    std::shared_ptr<CallbackCacheProvider> provider) {
  TRACE_EVENT0("flutter", "JniDelegate::SetCallbackCache");
  std::scoped_lock lock(callback_cache_mutex_);
  callback_cache_ = provider ? std::move(provider)
                             : std::make_shared<DefaultCallbackCacheProvider>();
}

std::shared_ptr<CallbackCacheProvider> JniDelegate::GetCallbackCache() const {
  std::scoped_lock lock(callback_cache_mutex_);
  return callback_cache_;
}

bool JniDelegate::DecodeImage(const uint8_t* data,
                              size_t size,
                              int64_t generator_handle) {
  TRACE_EVENT0("flutter", "JniDelegate::DecodeImage");
  std::shared_ptr<ImageDecoderProvider> decoder;
  {
    std::scoped_lock lock(image_decoder_mutex_);
    decoder = image_decoder_;
  }
  if (decoder) {
    return decoder->DecodeImage(data, size, generator_handle);
  }
  if (!jvm_invoker_ || !data || size == 0) {
    return false;
  }
  return jvm_invoker_->DecodeImage(data, size, generator_handle);
}

void JniDelegate::OnNativeImageHeader(int64_t generator_handle,
                                      int32_t width,
                                      int32_t height) {
  TRACE_EVENT0("flutter", "JniDelegate::OnNativeImageHeader");
  std::shared_ptr<ImageDecoderProvider> decoder;
  {
    std::scoped_lock lock(image_decoder_mutex_);
    decoder = image_decoder_;
  }
  if (decoder) {
    decoder->OnImageHeader(generator_handle, width, height);
  }
}

std::optional<ImageHeaderInfo> JniDelegate::GetImageHeader(
    int64_t generator_handle) {
  TRACE_EVENT0("flutter", "JniDelegate::GetImageHeader");
  std::shared_ptr<ImageDecoderProvider> decoder;
  {
    std::scoped_lock lock(image_decoder_mutex_);
    decoder = image_decoder_;
  }
  if (decoder) {
    return decoder->GetImageHeader(generator_handle);
  }
  return std::nullopt;
}

void JniDelegate::RemoveImageHeader(int64_t generator_handle) {
  TRACE_EVENT0("flutter", "JniDelegate::RemoveImageHeader");
  std::shared_ptr<ImageDecoderProvider> decoder;
  {
    std::scoped_lock lock(image_decoder_mutex_);
    decoder = image_decoder_;
  }
  if (decoder) {
    decoder->RemoveImageHeader(generator_handle);
  }
}

void JniDelegate::SetImageDecoderProvider(
    std::shared_ptr<ImageDecoderProvider> provider) {
  TRACE_EVENT0("flutter", "JniDelegate::SetImageDecoderProvider");
  std::scoped_lock lock(image_decoder_mutex_);
  image_decoder_ = std::move(provider);
}

std::shared_ptr<ImageDecoderProvider> JniDelegate::GetImageDecoderProvider()
    const {
  std::scoped_lock lock(image_decoder_mutex_);
  return image_decoder_;
}

int64_t JniDelegate::CreatePlatformView(
    const PlatformViewCreationParams& params,
    PlatformViewCompositionType composition_type) {
  TRACE_EVENT1("flutter", "JniDelegate::CreatePlatformView", "view_id",
               std::to_string(params.view_id).c_str());
  if (!platform_views_controller_) {
    return -1;
  }
  return platform_views_controller_->CreatePlatformView(params,
                                                        composition_type);
}

bool JniDelegate::DisposePlatformView(int64_t view_id) {
  TRACE_EVENT1("flutter", "JniDelegate::DisposePlatformView", "view_id",
               std::to_string(view_id).c_str());
  if (!platform_views_controller_) {
    return false;
  }
  return platform_views_controller_->DisposePlatformView(view_id);
}

bool JniDelegate::ResizePlatformView(const PlatformViewResizeRequest& request) {
  TRACE_EVENT1("flutter", "JniDelegate::ResizePlatformView", "view_id",
               std::to_string(request.view_id).c_str());
  if (!platform_views_controller_) {
    return false;
  }
  return platform_views_controller_->ResizePlatformView(
      request.view_id, request.width, request.height);
}

bool JniDelegate::OffsetPlatformView(int64_t view_id, double top, double left) {
  TRACE_EVENT1("flutter", "JniDelegate::OffsetPlatformView", "view_id",
               std::to_string(view_id).c_str());
  if (!platform_views_controller_) {
    return false;
  }
  return platform_views_controller_->OffsetPlatformView(view_id, top, left);
}

bool JniDelegate::SetPlatformViewDirection(int64_t view_id, int32_t direction) {
  TRACE_EVENT1("flutter", "JniDelegate::SetPlatformViewDirection", "view_id",
               std::to_string(view_id).c_str());
  if (!platform_views_controller_) {
    return false;
  }
  return platform_views_controller_->SetDirection(view_id, direction);
}

bool JniDelegate::ClearPlatformViewFocus(int64_t view_id) {
  TRACE_EVENT1("flutter", "JniDelegate::ClearPlatformViewFocus", "view_id",
               std::to_string(view_id).c_str());
  if (!platform_views_controller_) {
    return false;
  }
  return platform_views_controller_->ClearFocus(view_id);
}

bool JniDelegate::DispatchPlatformViewTouch(const PlatformViewTouch& touch) {
  TRACE_EVENT1("flutter", "JniDelegate::DispatchPlatformViewTouch", "view_id",
               std::to_string(touch.view_id).c_str());
  if (!platform_views_controller_) {
    return false;
  }
  return platform_views_controller_->DispatchTouchEvent(touch);
}

bool JniDelegate::OnDisplayPlatformView(const PlatformViewGeometry& geometry) {
  TRACE_EVENT1("flutter", "JniDelegate::OnDisplayPlatformView", "view_id",
               std::to_string(geometry.view_id).c_str());
  if (!platform_views_controller_) {
    return false;
  }
  return platform_views_controller_->OnDisplayPlatformView(
      geometry.view_id, geometry.x, geometry.y, geometry.width, geometry.height,
      geometry.view_width, geometry.view_height, geometry.mutators_stack);
}

bool JniDelegate::OnDisplayPlatformView(
    const FlutterPlatformView& platform_view,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    int32_t view_width,
    int32_t view_height) {
  TRACE_EVENT1("flutter", "JniDelegate::OnDisplayPlatformView(struct)",
               "view_id", std::to_string(platform_view.identifier).c_str());
  if (platform_view.struct_size < sizeof(FlutterPlatformView)) {
    return false;
  }
  if (!platform_views_controller_) {
    return false;
  }
  return platform_views_controller_->OnDisplayPlatformView(
      platform_view, x, y, width, height, view_width, view_height);
}

bool JniDelegate::HidePlatformView(int64_t view_id) {
  TRACE_EVENT1("flutter", "JniDelegate::HidePlatformView", "view_id",
               std::to_string(view_id).c_str());
  if (!platform_views_controller_) {
    return false;
  }
  return platform_views_controller_->HidePlatformView(view_id);
}

bool JniDelegate::SynchronizeToNativeViewHierarchy(bool synchronize) {
  TRACE_EVENT0("flutter", "JniDelegate::SynchronizeToNativeViewHierarchy");
  if (!platform_views_controller_) {
    return false;
  }
  return platform_views_controller_->SynchronizeToNativeViewHierarchy(
      synchronize);
}

bool JniDelegate::OnBeginFrame() {
  TRACE_EVENT0("flutter", "JniDelegate::OnBeginFrame");
  if (!platform_views_controller_) {
    return false;
  }
  return platform_views_controller_->OnBeginFrame();
}

bool JniDelegate::OnEndFrame() {
  TRACE_EVENT0("flutter", "JniDelegate::OnEndFrame");
  if (!platform_views_controller_) {
    return false;
  }
  return platform_views_controller_->OnEndFrame();
}

std::optional<int32_t> JniDelegate::CreateOverlaySurface() {
  TRACE_EVENT0("flutter", "JniDelegate::CreateOverlaySurface");
  if (!platform_views_controller_) {
    return std::nullopt;
  }
  return platform_views_controller_->CreateOverlaySurface();
}

bool JniDelegate::DestroyOverlaySurfaces() {
  TRACE_EVENT0("flutter", "JniDelegate::DestroyOverlaySurfaces");
  if (!platform_views_controller_) {
    return false;
  }
  return platform_views_controller_->DestroyOverlaySurfaces();
}

bool JniDelegate::OnDisplayOverlaySurface(const PlatformViewOverlay& overlay) {
  TRACE_EVENT1("flutter", "JniDelegate::OnDisplayOverlaySurface", "surface_id",
               std::to_string(overlay.surface_id).c_str());
  if (!platform_views_controller_) {
    return false;
  }
  return platform_views_controller_->OnDisplayOverlaySurface(
      overlay.surface_id, overlay.x, overlay.y, overlay.width, overlay.height);
}

bool JniDelegate::ShowOverlaySurface(int32_t surface_id) {
  TRACE_EVENT1("flutter", "JniDelegate::ShowOverlaySurface", "surface_id",
               std::to_string(surface_id).c_str());
  if (!platform_views_controller_) {
    return false;
  }
  return platform_views_controller_->ShowOverlaySurface(surface_id);
}

bool JniDelegate::HideOverlaySurface(int32_t surface_id) {
  TRACE_EVENT1("flutter", "JniDelegate::HideOverlaySurface", "surface_id",
               std::to_string(surface_id).c_str());
  if (!platform_views_controller_) {
    return false;
  }
  return platform_views_controller_->HideOverlaySurface(surface_id);
}

bool JniDelegate::SetHcppEnabled(bool enabled) {
  TRACE_EVENT1("flutter", "JniDelegate::SetHcppEnabled", "enabled",
               enabled ? "true" : "false");
  hcpp_enabled_ = enabled;
  if (platform_views_controller_) {
    platform_views_controller_->SetHcppEnabled(enabled);
  }
  if (platform_views_provider_) {
    platform_views_provider_->SetHcppEnabled(enabled);
  }
  if (jvm_invoker_) {
    std::vector<uint8_t> payload = {static_cast<uint8_t>(enabled ? 1 : 0)};
    jvm_invoker_->InvokeVoidMethod("setHcppEnabled", "(Z)V", payload);
  }
  return true;
}

bool JniDelegate::IsHcppEnabled() const {
  TRACE_EVENT0("flutter", "JniDelegate::IsHcppEnabled");
  if (hcpp_enabled_) {
    return true;
  }
  if (platform_views_controller_) {
    return platform_views_controller_->IsHcppEnabled();
  }
  return false;
}

void JniDelegate::SetNativeWindow(void* window) {
  TRACE_EVENT0("flutter", "JniDelegate::SetNativeWindow");
  std::lock_guard<std::mutex> lock(surface_control_mutex_);
  native_window_ = window;
}

void* JniDelegate::GetNativeWindow() const {
  TRACE_EVENT0("flutter", "JniDelegate::GetNativeWindow");
  std::lock_guard<std::mutex> lock(surface_control_mutex_);
  return native_window_;
}

bool JniDelegate::CreatePlatformViewTransaction() {
  TRACE_EVENT0("flutter", "JniDelegate::CreatePlatformViewTransaction");
  {
    std::lock_guard<std::mutex> lock(surface_control_mutex_);
    if (surface_control_provider_) {
      if (active_transaction_) {
        pending_transactions_.push_back(std::move(active_transaction_));
      }
      active_transaction_ = surface_control_provider_->CreateTransaction();
      committed_surface_control_states_ = surface_control_states_;
    }
  }
  if (platform_views_controller_) {
    return platform_views_controller_->CreateTransaction();
  }
  return true;
}

bool JniDelegate::SwapPlatformViewTransactions() {
  TRACE_EVENT0("flutter", "JniDelegate::SwapPlatformViewTransactions");
  if (platform_views_controller_) {
    return platform_views_controller_->SwapTransactions();
  }
  return true;
}

bool JniDelegate::ApplyPlatformViewTransactions() {
  TRACE_EVENT0("flutter", "JniDelegate::ApplyPlatformViewTransactions");
  bool applied_sc = true;
  {
    std::lock_guard<std::mutex> lock(surface_control_mutex_);
    for (auto& tx : pending_transactions_) {
      if (tx) {
        applied_sc = tx->Apply() && applied_sc;
      }
    }
    pending_transactions_.clear();
    if (active_transaction_) {
      applied_sc = active_transaction_->Apply() && applied_sc;
      active_transaction_.reset();
    }
    if (applied_sc) {
      committed_surface_control_states_ = surface_control_states_;
    } else {
      surface_control_states_ = committed_surface_control_states_;
    }
  }
  bool applied_pv = true;
  if (platform_views_controller_) {
    applied_pv = platform_views_controller_->ApplyTransactions();
  }
  return applied_sc && applied_pv;
}

bool JniDelegate::CreateSurfaceControl(int64_t surface_id,
                                       const std::string& debug_name) {
  return CreateSurfaceControl(surface_id, 0, debug_name);
}

bool JniDelegate::CreateSurfaceControl(int64_t surface_id,
                                       int64_t parent_surface_id,
                                       const std::string& debug_name) {
  TRACE_EVENT1("flutter", "JniDelegate::CreateSurfaceControl", "surface_id",
               std::to_string(surface_id).c_str());
  std::lock_guard<std::mutex> lock(surface_control_mutex_);
  if (!surface_control_provider_) {
    return false;
  }
  std::string name =
      debug_name.empty()
          ? ("FlutterSurfaceControl_" + std::to_string(surface_id))
          : debug_name;
  std::unique_ptr<AndroidSurfaceControl> sc;
  int64_t assigned_parent_id = 0;
  if (surface_controls_.empty() || surface_id == root_surface_id_ ||
      (parent_surface_id == 0 && root_surface_id_ == 0)) {
    sc = surface_control_provider_->CreateFromWindow(native_window_, name);
    if (sc) {
      root_surface_id_ = surface_id;
    }
  } else {
    int64_t actual_parent_id =
        parent_surface_id != 0 ? parent_surface_id : root_surface_id_;
    auto parent_it = surface_controls_.find(actual_parent_id);
    if (parent_it == surface_controls_.end()) {
      parent_it = surface_controls_.begin();
    }
    if (parent_it == surface_controls_.end() || !parent_it->second) {
      return false;
    }
    assigned_parent_id = parent_it->first;
    sc = surface_control_provider_->Create(parent_it->second.get(), name);
  }
  if (!sc) {
    return false;
  }
  AndroidSurfaceControlState state;
  state.id = surface_id;
  state.debug_name = name;
  state.handle = sc->GetHandle();
  state.parent_handle = sc->GetParentHandle();
  state.parent_id = assigned_parent_id;
  state.is_valid = sc->IsValid();
  state.ref_count = 1;

  surface_controls_[surface_id] = std::move(sc);
  surface_control_states_[surface_id] = state;
  committed_surface_control_states_[surface_id] = state;

  if (jvm_invoker_) {
    std::vector<uint8_t> payload;
    jvm_invoker_->InvokeVoidMethod("createSurfaceControl",
                                   "(JLjava/lang/String;)V", payload);
  }
  return true;
}

bool JniDelegate::DestroySurfaceControl(int64_t surface_id) {
  TRACE_EVENT1("flutter", "JniDelegate::DestroySurfaceControl", "surface_id",
               std::to_string(surface_id).c_str());
  std::lock_guard<std::mutex> lock(surface_control_mutex_);
  auto it = surface_controls_.find(surface_id);
  if (it == surface_controls_.end()) {
    return false;
  }
  surface_controls_.erase(it);
  surface_control_states_.erase(surface_id);
  committed_surface_control_states_.erase(surface_id);
  if (surface_id == root_surface_id_) {
    root_surface_id_ = 0;
  }
  if (jvm_invoker_) {
    std::vector<uint8_t> payload;
    jvm_invoker_->InvokeVoidMethod("destroySurfaceControl", "(J)V", payload);
  }
  return true;
}

bool JniDelegate::ReparentSurfaceControl(int64_t surface_id,
                                         int64_t new_parent_id) {
  TRACE_EVENT1("flutter", "JniDelegate::ReparentSurfaceControl", "surface_id",
               std::to_string(surface_id).c_str());
  std::lock_guard<std::mutex> lock(surface_control_mutex_);
  auto it = surface_controls_.find(surface_id);
  if (it == surface_controls_.end()) {
    return false;
  }
  AndroidSurfaceControl* parent_ptr = nullptr;
  void* parent_handle = nullptr;
  if (new_parent_id != 0) {
    auto p_it = surface_controls_.find(new_parent_id);
    if (p_it != surface_controls_.end()) {
      parent_ptr = p_it->second.get();
      parent_handle = parent_ptr->GetHandle();
    }
  }
  if (active_transaction_) {
    if (!active_transaction_->Reparent(it->second.get(), parent_ptr)) {
      return false;
    }
  } else if (surface_control_provider_) {
    auto tx = surface_control_provider_->CreateTransaction();
    if (tx) {
      if (!tx->Reparent(it->second.get(), parent_ptr) || !tx->Apply()) {
        return false;
      }
    }
  }
  surface_control_states_[surface_id].parent_handle = parent_handle;
  surface_control_states_[surface_id].parent_id = new_parent_id;
  if (!active_transaction_) {
    committed_surface_control_states_[surface_id] =
        surface_control_states_[surface_id];
  }
  return true;
}

bool JniDelegate::SetSurfaceControlGeometry(
    int64_t surface_id,
    const AndroidSurfaceControlRect& source,
    const AndroidSurfaceControlRect& destination,
    int32_t transform) {
  TRACE_EVENT1("flutter", "JniDelegate::SetSurfaceControlGeometry",
               "surface_id", std::to_string(surface_id).c_str());
  std::lock_guard<std::mutex> lock(surface_control_mutex_);
  auto it = surface_controls_.find(surface_id);
  if (it == surface_controls_.end()) {
    return false;
  }
  if (active_transaction_) {
    if (!active_transaction_->SetGeometry(
            it->second.get(), source, destination,
            static_cast<AndroidSurfaceControlTransform>(transform))) {
      return false;
    }
  } else if (surface_control_provider_) {
    auto tx = surface_control_provider_->CreateTransaction();
    if (tx) {
      if (!tx->SetGeometry(
              it->second.get(), source, destination,
              static_cast<AndroidSurfaceControlTransform>(transform)) ||
          !tx->Apply()) {
        return false;
      }
    }
  }
  auto state_it = surface_control_states_.find(surface_id);
  if (state_it != surface_control_states_.end()) {
    state_it->second.source_rect = source;
    state_it->second.destination_rect = destination;
    state_it->second.transform =
        static_cast<AndroidSurfaceControlTransform>(transform);
    if (!active_transaction_) {
      committed_surface_control_states_[surface_id] = state_it->second;
    }
  }
  return true;
}

bool JniDelegate::SetSurfaceControlVisibility(int64_t surface_id,
                                              bool visible) {
  TRACE_EVENT1("flutter", "JniDelegate::SetSurfaceControlVisibility",
               "surface_id", std::to_string(surface_id).c_str());
  std::lock_guard<std::mutex> lock(surface_control_mutex_);
  auto it = surface_controls_.find(surface_id);
  if (it == surface_controls_.end()) {
    return false;
  }
  auto vis = visible ? AndroidSurfaceControlVisibility::kShow
                     : AndroidSurfaceControlVisibility::kHide;
  if (active_transaction_) {
    if (!active_transaction_->SetVisibility(it->second.get(), vis)) {
      return false;
    }
  } else if (surface_control_provider_) {
    auto tx = surface_control_provider_->CreateTransaction();
    if (tx) {
      if (!tx->SetVisibility(it->second.get(), vis) || !tx->Apply()) {
        return false;
      }
    }
  }
  auto state_it = surface_control_states_.find(surface_id);
  if (state_it != surface_control_states_.end()) {
    state_it->second.visibility = vis;
    if (!active_transaction_) {
      committed_surface_control_states_[surface_id] = state_it->second;
    }
  }
  return true;
}

bool JniDelegate::SetSurfaceControlZOrder(int64_t surface_id, int32_t z_order) {
  TRACE_EVENT1("flutter", "JniDelegate::SetSurfaceControlZOrder", "surface_id",
               std::to_string(surface_id).c_str());
  std::lock_guard<std::mutex> lock(surface_control_mutex_);
  auto it = surface_controls_.find(surface_id);
  if (it == surface_controls_.end()) {
    return false;
  }
  if (active_transaction_) {
    if (!active_transaction_->SetZOrder(it->second.get(), z_order)) {
      return false;
    }
  } else if (surface_control_provider_) {
    auto tx = surface_control_provider_->CreateTransaction();
    if (tx) {
      if (!tx->SetZOrder(it->second.get(), z_order) || !tx->Apply()) {
        return false;
      }
    }
  }
  auto state_it = surface_control_states_.find(surface_id);
  if (state_it != surface_control_states_.end()) {
    state_it->second.z_order = z_order;
    if (!active_transaction_) {
      committed_surface_control_states_[surface_id] = state_it->second;
    }
  }
  return true;
}

bool JniDelegate::SetSurfaceControlDamageRegion(
    int64_t surface_id,
    const std::vector<AndroidSurfaceControlRect>& rects) {
  TRACE_EVENT1("flutter", "JniDelegate::SetSurfaceControlDamageRegion",
               "surface_id", std::to_string(surface_id).c_str());
  std::lock_guard<std::mutex> lock(surface_control_mutex_);
  auto it = surface_controls_.find(surface_id);
  if (it == surface_controls_.end()) {
    return false;
  }
  if (active_transaction_) {
    if (!active_transaction_->SetDamageRegion(it->second.get(), rects)) {
      return false;
    }
  } else if (surface_control_provider_) {
    auto tx = surface_control_provider_->CreateTransaction();
    if (tx) {
      if (!tx->SetDamageRegion(it->second.get(), rects) || !tx->Apply()) {
        return false;
      }
    }
  }
  auto state_it = surface_control_states_.find(surface_id);
  if (state_it != surface_control_states_.end()) {
    state_it->second.damage_region = rects;
    if (!active_transaction_) {
      committed_surface_control_states_[surface_id] = state_it->second;
    }
  }
  return true;
}

bool JniDelegate::SetSurfaceControlBuffer(int64_t surface_id,
                                          void* buffer,
                                          int fence_fd) {
  TRACE_EVENT1("flutter", "JniDelegate::SetSurfaceControlBuffer", "surface_id",
               std::to_string(surface_id).c_str());
  std::lock_guard<std::mutex> lock(surface_control_mutex_);
  auto it = surface_controls_.find(surface_id);
  if (it == surface_controls_.end()) {
    return false;
  }
  if (active_transaction_) {
    if (!active_transaction_->SetBuffer(it->second.get(), buffer, fence_fd)) {
      return false;
    }
  } else if (surface_control_provider_) {
    auto tx = surface_control_provider_->CreateTransaction();
    if (tx) {
      if (!tx->SetBuffer(it->second.get(), buffer, fence_fd) || !tx->Apply()) {
        return false;
      }
    }
  }
  auto state_it = surface_control_states_.find(surface_id);
  if (state_it != surface_control_states_.end()) {
    state_it->second.buffer_handle = buffer;
    state_it->second.buffer_fence_fd = fence_fd;
    if (!active_transaction_) {
      committed_surface_control_states_[surface_id] = state_it->second;
    }
  }
  return true;
}

bool JniDelegate::SetSurfaceControlBufferAlpha(int64_t surface_id,
                                               float alpha) {
  TRACE_EVENT1("flutter", "JniDelegate::SetSurfaceControlBufferAlpha",
               "surface_id", std::to_string(surface_id).c_str());
  std::lock_guard<std::mutex> lock(surface_control_mutex_);
  auto it = surface_controls_.find(surface_id);
  if (it == surface_controls_.end()) {
    return false;
  }
  if (active_transaction_) {
    if (!active_transaction_->SetBufferAlpha(it->second.get(), alpha)) {
      return false;
    }
  } else if (surface_control_provider_) {
    auto tx = surface_control_provider_->CreateTransaction();
    if (tx) {
      if (!tx->SetBufferAlpha(it->second.get(), alpha) || !tx->Apply()) {
        return false;
      }
    }
  }
  auto state_it = surface_control_states_.find(surface_id);
  if (state_it != surface_control_states_.end()) {
    state_it->second.alpha = alpha;
    if (!active_transaction_) {
      committed_surface_control_states_[surface_id] = state_it->second;
    }
  }
  return true;
}

bool JniDelegate::SetSurfaceControlColor(int64_t surface_id,
                                         float r,
                                         float g,
                                         float b,
                                         float alpha) {
  TRACE_EVENT1("flutter", "JniDelegate::SetSurfaceControlColor", "surface_id",
               std::to_string(surface_id).c_str());
  std::lock_guard<std::mutex> lock(surface_control_mutex_);
  auto it = surface_controls_.find(surface_id);
  if (it == surface_controls_.end()) {
    return false;
  }
  if (active_transaction_) {
    if (!active_transaction_->SetColor(it->second.get(), r, g, b, alpha)) {
      return false;
    }
  } else if (surface_control_provider_) {
    auto tx = surface_control_provider_->CreateTransaction();
    if (tx) {
      if (!tx->SetColor(it->second.get(), r, g, b, alpha) || !tx->Apply()) {
        return false;
      }
    }
  }
  auto state_it = surface_control_states_.find(surface_id);
  if (state_it != surface_control_states_.end()) {
    state_it->second.color = AndroidSurfaceControlColor{r, g, b, alpha};
    if (!active_transaction_) {
      committed_surface_control_states_[surface_id] = state_it->second;
    }
  }
  return true;
}

void JniDelegate::SetSurfaceControlProvider(
    std::shared_ptr<AndroidSurfaceControlProvider> provider) {
  TRACE_EVENT0("flutter", "JniDelegate::SetSurfaceControlProvider");
  std::lock_guard<std::mutex> lock(surface_control_mutex_);
  surface_control_provider_ = std::move(provider);
}

std::shared_ptr<AndroidSurfaceControlProvider>
JniDelegate::GetSurfaceControlProvider() const {
  TRACE_EVENT0("flutter", "JniDelegate::GetSurfaceControlProvider");
  std::lock_guard<std::mutex> lock(surface_control_mutex_);
  return surface_control_provider_;
}

std::optional<AndroidSurfaceControlState> JniDelegate::GetSurfaceControlState(
    int64_t surface_id) const {
  TRACE_EVENT1("flutter", "JniDelegate::GetSurfaceControlState", "surface_id",
               std::to_string(surface_id).c_str());
  std::lock_guard<std::mutex> lock(surface_control_mutex_);
  auto it = surface_control_states_.find(surface_id);
  if (it != surface_control_states_.end()) {
    return it->second;
  }
  return std::nullopt;
}

std::shared_ptr<AndroidSurfaceControl> JniDelegate::GetSurfaceControl(
    int64_t surface_id) const {
  TRACE_EVENT1("flutter", "JniDelegate::GetSurfaceControl", "surface_id",
               std::to_string(surface_id).c_str());
  std::lock_guard<std::mutex> lock(surface_control_mutex_);
  auto it = surface_controls_.find(surface_id);
  if (it != surface_controls_.end()) {
    return it->second;
  }
  return nullptr;
}

bool JniDelegate::PushPlatformViewMutators(
    int64_t view_id,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    const AndroidMutatorsStack& mutators_stack) {
  return PushPlatformViewMutators(view_id, x, y, width, height, width, height,
                                  mutators_stack);
}

bool JniDelegate::PushPlatformViewMutators(
    int64_t view_id,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    int32_t view_width,
    int32_t view_height,
    const AndroidMutatorsStack& mutators_stack) {
  TRACE_EVENT0("flutter", "JniDelegate::PushPlatformViewMutators");
  if (platform_views_controller_) {
    return platform_views_controller_->PushPlatformViewMutators(
        view_id, x, y, width, height, view_width, view_height, mutators_stack);
  }
  if (!jvm_invoker_) {
    return false;
  }
  std::vector<uint8_t> payload = mutators_stack.Serialize();
  return jvm_invoker_->PushPlatformViewMutators(
      view_id, x, y, width, height, view_width, view_height, payload);
}

bool JniDelegate::PushPlatformViewMutators(
    const FlutterPlatformView& platform_view,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height) {
  return PushPlatformViewMutators(platform_view, x, y, width, height, width,
                                  height);
}

bool JniDelegate::PushPlatformViewMutators(
    const FlutterPlatformView& platform_view,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    int32_t view_width,
    int32_t view_height) {
  TRACE_EVENT0("flutter", "JniDelegate::PushPlatformViewMutators(view)");
  if (platform_view.struct_size < sizeof(FlutterPlatformView)) {
    return false;
  }
  if (platform_views_controller_) {
    return platform_views_controller_->PushPlatformViewMutators(
        platform_view, x, y, width, height, view_width, view_height);
  }
  AndroidMutatorsStack stack =
      AndroidMutatorsMapper::MapPlatformView(platform_view);
  return PushPlatformViewMutators(platform_view.identifier, x, y, width, height,
                                  view_width, view_height, stack);
}

void JniDelegate::SetPlatformViewsProvider(
    std::shared_ptr<PlatformViewsProvider> provider) {
  TRACE_EVENT0("flutter", "JniDelegate::SetPlatformViewsProvider");
  platform_views_provider_ =
      provider ? std::move(provider)
               : std::make_shared<DefaultPlatformViewsProvider>(jvm_invoker_);
  if (platform_views_controller_) {
    platform_views_controller_->SetProvider(platform_views_provider_);
  }
}

std::shared_ptr<PlatformViewsProvider> JniDelegate::GetPlatformViewsProvider()
    const {
  return platform_views_provider_;
}

std::shared_ptr<AndroidPlatformViewsController>
JniDelegate::GetPlatformViewsController() const {
  return platform_views_controller_;
}

void JniDelegate::SetWindowMetricsProvider(
    std::shared_ptr<WindowMetricsProvider> provider) {
  TRACE_EVENT0("flutter", "JniDelegate::SetWindowMetricsProvider");
  std::scoped_lock lock(window_metrics_provider_mutex_);
  window_metrics_provider_ =
      provider ? std::move(provider)
               : std::make_shared<DefaultWindowMetricsProvider>(jvm_invoker_);
}

std::shared_ptr<WindowMetricsProvider> JniDelegate::GetWindowMetricsProvider()
    const {
  std::scoped_lock lock(window_metrics_provider_mutex_);
  return window_metrics_provider_;
}

void JniDelegate::SetVsyncWaiter(std::shared_ptr<AndroidVsyncWaiter> provider) {
  TRACE_EVENT0("flutter", "JniDelegate::SetVsyncWaiter");
  std::scoped_lock lock(vsync_waiter_mutex_);
  vsync_waiter_ = std::move(provider);
}

std::shared_ptr<AndroidVsyncWaiter> JniDelegate::GetVsyncWaiter() const {
  std::scoped_lock lock(vsync_waiter_mutex_);
  return vsync_waiter_;
}

bool JniDelegate::InitVM(const AndroidVMArgs& args) {
  TRACE_EVENT0("flutter", "JniDelegate::InitVM");
  std::scoped_lock lock(vm_init_mutex_);
  if (vm_init_) {
    return vm_init_->Init(args);
  }
  return false;
}

bool JniDelegate::PrefetchDefaultFontManager() {
  TRACE_EVENT0("flutter", "JniDelegate::PrefetchDefaultFontManager");
  std::scoped_lock lock(vm_init_mutex_);
  if (vm_init_) {
    return vm_init_->PrefetchDefaultFontManager();
  }
  return false;
}

bool JniDelegate::SetVmServiceUri(const std::string& uri) {
  TRACE_EVENT1("flutter", "JniDelegate::SetVmServiceUri", "uri", uri.c_str());
  std::scoped_lock lock(vm_init_mutex_);
  if (vm_init_) {
    return vm_init_->SetVmServiceUri(uri);
  }
  if (jvm_invoker_) {
    std::vector<uint8_t> payload(uri.begin(), uri.end());
    return jvm_invoker_->InvokeVoidMethod("setVmServiceUri",
                                          "(Ljava/lang/String;)V", payload);
  }
  return false;
}

std::string JniDelegate::GetVmServiceUri() const {
  std::scoped_lock lock(vm_init_mutex_);
  if (vm_init_) {
    return vm_init_->GetVmServiceUri();
  }
  return "";
}

bool JniDelegate::IsVMInitialized() const {
  std::scoped_lock lock(vm_init_mutex_);
  if (vm_init_) {
    return vm_init_->IsInitialized();
  }
  return false;
}

std::optional<AndroidVMArgs> JniDelegate::GetVMArgs() const {
  std::scoped_lock lock(vm_init_mutex_);
  if (vm_init_) {
    return vm_init_->GetVMArgs();
  }
  return std::nullopt;
}

void JniDelegate::SetVMInit(std::shared_ptr<AndroidVMInit> vm_init) {
  TRACE_EVENT0("flutter", "JniDelegate::SetVMInit");
  std::scoped_lock lock(vm_init_mutex_);
  vm_init_ = vm_init ? std::move(vm_init)
                     : std::make_shared<AndroidVMInit>(jvm_invoker_);
}

std::shared_ptr<AndroidVMInit> JniDelegate::GetVMInit() const {
  std::scoped_lock lock(vm_init_mutex_);
  return vm_init_;
}

bool JniDelegate::RegisterHardwareBufferTexture(int64_t texture_id) {
  TRACE_EVENT1("flutter", "JniDelegate::RegisterHardwareBufferTexture",
               "texture_id", std::to_string(texture_id).c_str());
  std::vector<uint8_t> payload(sizeof(int64_t));
  std::memcpy(payload.data(), &texture_id, sizeof(int64_t));
  bool success = jvm_invoker_->InvokeBooleanMethod(
      "registerHardwareBufferTexture", "(J)Z", payload);
  if (!success) {
    return false;
  }
  std::lock_guard<std::mutex> lock(hardware_buffer_mutex_);
  registered_hardware_textures_.insert(texture_id);
  return true;
}

bool JniDelegate::UnregisterHardwareBufferTexture(int64_t texture_id) {
  TRACE_EVENT1("flutter", "JniDelegate::UnregisterHardwareBufferTexture",
               "texture_id", std::to_string(texture_id).c_str());
  VoidCallback callback_to_invoke = nullptr;
  void* user_data_to_invoke = nullptr;
  int32_t fence_to_close = -1;
  {
    std::lock_guard<std::mutex> lock(hardware_buffer_mutex_);
    registered_hardware_textures_.erase(texture_id);
    auto it = hardware_buffer_frames_.find(texture_id);
    if (it != hardware_buffer_frames_.end()) {
      callback_to_invoke = it->second.destruction_callback;
      user_data_to_invoke = it->second.user_data;
      fence_to_close = it->second.fence_fd;
      it->second.destruction_callback = nullptr;
      it->second.fence_fd = -1;
      hardware_buffer_frames_.erase(it);
    }
    hardware_buffer_objects_.erase(texture_id);
  }
  if (fence_to_close >= 0) {
    close(fence_to_close);
  }
  if (callback_to_invoke) {
    callback_to_invoke(user_data_to_invoke);
  }
  std::vector<uint8_t> payload(sizeof(int64_t));
  std::memcpy(payload.data(), &texture_id, sizeof(int64_t));
  return jvm_invoker_->InvokeBooleanMethod("unregisterHardwareBufferTexture",
                                           "(J)Z", payload);
}

bool JniDelegate::SetHardwareBufferFrame(
    int64_t texture_id,
    const std::shared_ptr<AndroidHardwareBuffer>& buffer) {
  TRACE_EVENT1("flutter", "JniDelegate::SetHardwareBufferFrame(object)",
               "texture_id", std::to_string(texture_id).c_str());
  VoidCallback callback_to_invoke = nullptr;
  void* user_data_to_invoke = nullptr;
  int32_t fence_to_close = -1;
  bool is_valid = false;
  {
    std::lock_guard<std::mutex> lock(hardware_buffer_mutex_);
    if (registered_hardware_textures_.find(texture_id) ==
        registered_hardware_textures_.end()) {
      return false;
    }
    auto it = hardware_buffer_frames_.find(texture_id);
    if (it != hardware_buffer_frames_.end()) {
      callback_to_invoke = it->second.destruction_callback;
      user_data_to_invoke = it->second.user_data;
      fence_to_close = it->second.fence_fd;
      it->second.destruction_callback = nullptr;
      it->second.fence_fd = -1;
      hardware_buffer_frames_.erase(it);
    }
    hardware_buffer_objects_.erase(texture_id);

    if (buffer && buffer->IsValid()) {
      is_valid = true;
      hardware_buffer_objects_[texture_id] = buffer;
      // Attach destruction callback holding a heap keeper of the shared_ptr to
      // ensure the GPU does not encounter use-after-free when sampling the
      // frame.
      auto* keeper = new std::shared_ptr<AndroidHardwareBuffer>(buffer);
      FlutterHardwareBufferExternalTexture ext =
          buffer->ToExternalTexture(keeper, [](void* user_data) {
            delete static_cast<std::shared_ptr<AndroidHardwareBuffer>*>(
                user_data);
          });
      hardware_buffer_frames_[texture_id] = ext;
    }
  }
  if (fence_to_close >= 0) {
    close(fence_to_close);
  }
  if (callback_to_invoke) {
    callback_to_invoke(user_data_to_invoke);
  }
  return is_valid;
}

bool JniDelegate::SetHardwareBufferFrame(
    int64_t texture_id,
    const FlutterHardwareBufferExternalTexture& texture) {
  TRACE_EVENT1("flutter", "JniDelegate::SetHardwareBufferFrame(struct)",
               "texture_id", std::to_string(texture_id).c_str());
  VoidCallback callback_to_invoke = nullptr;
  void* user_data_to_invoke = nullptr;
  int32_t fence_to_close = -1;
  {
    std::lock_guard<std::mutex> lock(hardware_buffer_mutex_);
    if (registered_hardware_textures_.find(texture_id) ==
        registered_hardware_textures_.end()) {
      return false;
    }
    auto it = hardware_buffer_frames_.find(texture_id);
    if (it != hardware_buffer_frames_.end()) {
      callback_to_invoke = it->second.destruction_callback;
      user_data_to_invoke = it->second.user_data;
      fence_to_close = it->second.fence_fd;
      it->second.destruction_callback = nullptr;
      it->second.fence_fd = -1;
    }
    // Release any previous C++ buffer object to prevent memory leaks
    hardware_buffer_objects_.erase(texture_id);
    hardware_buffer_frames_[texture_id] = texture;
  }
  if (fence_to_close >= 0) {
    close(fence_to_close);
  }
  if (callback_to_invoke) {
    callback_to_invoke(user_data_to_invoke);
  }
  return true;
}

bool JniDelegate::GetHardwareBufferTextureFrame(
    int64_t texture_id,
    size_t width,
    size_t height,
    FlutterHardwareBufferExternalTexture* texture_out) {
  TRACE_EVENT1("flutter", "JniDelegate::GetHardwareBufferTextureFrame",
               "texture_id", std::to_string(texture_id).c_str());
  if (!texture_out) {
    return false;
  }
  std::lock_guard<std::mutex> lock(hardware_buffer_mutex_);
  if (registered_hardware_textures_.find(texture_id) ==
      registered_hardware_textures_.end()) {
    return false;
  }
  auto it = hardware_buffer_frames_.find(texture_id);
  if (it != hardware_buffer_frames_.end()) {
    *texture_out = it->second;
    if (texture_out->struct_size == 0) {
      texture_out->struct_size = sizeof(FlutterHardwareBufferExternalTexture);
    }
    // Hand ownership of fence_fd and destruction_callback to the engine caller.
    // This prevents double close of fence_fd and duplicate invocation of
    // destruction_callback.
    it->second.destruction_callback = nullptr;
    it->second.fence_fd = -1;
    return true;
  }
  return false;
}

bool JniDelegate::OnHardwareBufferFrameAvailable(int64_t texture_id) {
  TRACE_EVENT1("flutter", "JniDelegate::OnHardwareBufferFrameAvailable",
               "texture_id", std::to_string(texture_id).c_str());
  {
    std::lock_guard<std::mutex> lock(hardware_buffer_mutex_);
    if (registered_hardware_textures_.find(texture_id) ==
        registered_hardware_textures_.end()) {
      return false;
    }
  }
  std::vector<uint8_t> payload(sizeof(int64_t));
  std::memcpy(payload.data(), &texture_id, sizeof(int64_t));
  return jvm_invoker_->InvokeBooleanMethod("onHardwareBufferFrameAvailable",
                                           "(J)Z", payload);
}

void JniDelegate::SetHardwareBufferProvider(
    std::shared_ptr<AndroidHardwareBufferProvider> provider) {
  TRACE_EVENT0("flutter", "JniDelegate::SetHardwareBufferProvider");
  std::lock_guard<std::mutex> lock(hardware_buffer_mutex_);
  hardware_buffer_provider_ = std::move(provider);
}

std::shared_ptr<AndroidHardwareBufferProvider>
JniDelegate::GetHardwareBufferProvider() const {
  TRACE_EVENT0("flutter", "JniDelegate::GetHardwareBufferProvider");
  std::lock_guard<std::mutex> lock(hardware_buffer_mutex_);
  return hardware_buffer_provider_;
}

bool JniDelegate::RegisterVulkanTexture(int64_t texture_id) {
  TRACE_EVENT1("flutter", "JniDelegate::RegisterVulkanTexture", "texture_id",
               std::to_string(texture_id).c_str());
  std::vector<uint8_t> payload(sizeof(int64_t));
  std::memcpy(payload.data(), &texture_id, sizeof(int64_t));
  bool success = jvm_invoker_->InvokeBooleanMethod("registerVulkanTexture",
                                                   "(J)Z", payload);
  if (!success) {
    return false;
  }
  std::lock_guard<std::mutex> lock(vulkan_texture_mutex_);
  registered_vulkan_textures_.insert(texture_id);
  return true;
}

bool JniDelegate::UnregisterVulkanTexture(int64_t texture_id) {
  TRACE_EVENT1("flutter", "JniDelegate::UnregisterVulkanTexture", "texture_id",
               std::to_string(texture_id).c_str());
  VoidCallback destruction_cb = nullptr;
  void* user_data = nullptr;
  {
    std::lock_guard<std::mutex> lock(vulkan_texture_mutex_);
    if (registered_vulkan_textures_.find(texture_id) ==
        registered_vulkan_textures_.end()) {
      return false;
    }
    registered_vulkan_textures_.erase(texture_id);
    auto it = vulkan_texture_frames_.find(texture_id);
    if (it != vulkan_texture_frames_.end()) {
      destruction_cb = it->second.destruction_callback;
      user_data = it->second.user_data;
      it->second.destruction_callback = nullptr;
      it->second.user_data = nullptr;
      vulkan_texture_frames_.erase(it);
    }
    vulkan_texture_objects_.erase(texture_id);
  }
  if (destruction_cb) {
    destruction_cb(user_data);
  }
  std::vector<uint8_t> payload(sizeof(int64_t));
  std::memcpy(payload.data(), &texture_id, sizeof(int64_t));
  return jvm_invoker_->InvokeBooleanMethod("unregisterVulkanTexture", "(J)Z",
                                           payload);
}

bool JniDelegate::SetVulkanTextureFrame(
    int64_t texture_id,
    const std::shared_ptr<AndroidVulkanExternalTexture>& texture) {
  TRACE_EVENT1("flutter", "JniDelegate::SetVulkanTextureFrame(object)",
               "texture_id", std::to_string(texture_id).c_str());
  VoidCallback old_destruction_cb = nullptr;
  void* old_user_data = nullptr;
  bool is_valid = false;
  {
    std::lock_guard<std::mutex> lock(vulkan_texture_mutex_);
    if (registered_vulkan_textures_.find(texture_id) ==
        registered_vulkan_textures_.end()) {
      return false;
    }
    auto it = vulkan_texture_frames_.find(texture_id);
    if (it != vulkan_texture_frames_.end()) {
      old_destruction_cb = it->second.destruction_callback;
      old_user_data = it->second.user_data;
      it->second.destruction_callback = nullptr;
      it->second.user_data = nullptr;
      vulkan_texture_frames_.erase(it);
    }
    vulkan_texture_objects_.erase(texture_id);

    if (texture && texture->IsValid()) {
      is_valid = true;
      vulkan_texture_objects_[texture_id] = texture;
      // Attach destruction callback holding a heap keeper of the shared_ptr to
      // ensure the GPU does not encounter use-after-free when sampling the
      // frame. The texture's cached YCbCr info is safely kept alive as part of
      // the texture object itself.
      auto* keeper = new std::shared_ptr<AndroidVulkanExternalTexture>(texture);
      FlutterVulkanExternalTexture ext_texture =
          texture->ToExternalTexture(keeper, [](void* user_data) {
            delete static_cast<std::shared_ptr<AndroidVulkanExternalTexture>*>(
                user_data);
          });
      vulkan_texture_frames_[texture_id] = ext_texture;
    }
  }
  if (old_destruction_cb) {
    old_destruction_cb(old_user_data);
  }
  return is_valid;
}

bool JniDelegate::SetVulkanTextureFrame(
    int64_t texture_id,
    const FlutterVulkanExternalTexture& texture) {
  TRACE_EVENT1("flutter", "JniDelegate::SetVulkanTextureFrame(struct)",
               "texture_id", std::to_string(texture_id).c_str());
  VoidCallback old_destruction_cb = nullptr;
  void* old_user_data = nullptr;
  {
    std::lock_guard<std::mutex> lock(vulkan_texture_mutex_);
    if (registered_vulkan_textures_.find(texture_id) ==
        registered_vulkan_textures_.end()) {
      return false;
    }
    auto it = vulkan_texture_frames_.find(texture_id);
    if (it != vulkan_texture_frames_.end()) {
      old_destruction_cb = it->second.destruction_callback;
      old_user_data = it->second.user_data;
      it->second.destruction_callback = nullptr;
      it->second.user_data = nullptr;
      vulkan_texture_frames_.erase(it);
    }
    // Erase any previous C++ object to prevent memory leaks
    vulkan_texture_objects_.erase(texture_id);

    auto* keeper = new VulkanStructFrameKeeper();
    if (texture.ycbcr_conversion_info != nullptr) {
      keeper->ycbcr_info = *texture.ycbcr_conversion_info;
      keeper->has_ycbcr_info = true;
    }
    keeper->user_callback = texture.destruction_callback;
    keeper->user_data = texture.user_data;

    FlutterVulkanExternalTexture copied_texture = texture;
    if (keeper->has_ycbcr_info) {
      copied_texture.ycbcr_conversion_info = &keeper->ycbcr_info;
    } else {
      copied_texture.ycbcr_conversion_info = nullptr;
    }
    copied_texture.user_data = keeper;
    copied_texture.destruction_callback = [](void* user_data) {
      auto* keeper = static_cast<VulkanStructFrameKeeper*>(user_data);
      if (keeper->user_callback) {
        keeper->user_callback(keeper->user_data);
      }
      delete keeper;
    };
    vulkan_texture_frames_[texture_id] = copied_texture;
  }
  if (old_destruction_cb) {
    old_destruction_cb(old_user_data);
  }
  return true;
}

bool JniDelegate::GetVulkanTextureFrame(
    int64_t texture_id,
    size_t width,
    size_t height,
    FlutterVulkanExternalTexture* texture_out) {
  TRACE_EVENT1("flutter", "JniDelegate::GetVulkanTextureFrame", "texture_id",
               std::to_string(texture_id).c_str());
  if (!texture_out) {
    return false;
  }
  std::lock_guard<std::mutex> lock(vulkan_texture_mutex_);
  if (registered_vulkan_textures_.find(texture_id) ==
      registered_vulkan_textures_.end()) {
    return false;
  }
  auto it = vulkan_texture_frames_.find(texture_id);
  if (it != vulkan_texture_frames_.end()) {
    *texture_out = it->second;
    if (texture_out->struct_size == 0) {
      texture_out->struct_size = sizeof(FlutterVulkanExternalTexture);
    }
    // Hand ownership of destruction_callback to the engine caller.
    // This prevents duplicate invocation of destruction_callback.
    it->second.destruction_callback = nullptr;
    it->second.user_data = nullptr;
    return true;
  }
  return false;
}

bool JniDelegate::OnVulkanTextureFrameAvailable(int64_t texture_id) {
  TRACE_EVENT1("flutter", "JniDelegate::OnVulkanTextureFrameAvailable",
               "texture_id", std::to_string(texture_id).c_str());
  {
    std::lock_guard<std::mutex> lock(vulkan_texture_mutex_);
    if (registered_vulkan_textures_.find(texture_id) ==
        registered_vulkan_textures_.end()) {
      return false;
    }
  }
  std::vector<uint8_t> payload(sizeof(int64_t));
  std::memcpy(payload.data(), &texture_id, sizeof(int64_t));
  return jvm_invoker_->InvokeBooleanMethod("onVulkanTextureFrameAvailable",
                                           "(J)Z", payload);
}

void JniDelegate::SetVulkanTextureProvider(
    std::shared_ptr<AndroidVulkanTextureProvider> provider) {
  TRACE_EVENT0("flutter", "JniDelegate::SetVulkanTextureProvider");
  std::lock_guard<std::mutex> lock(vulkan_texture_mutex_);
  vulkan_texture_provider_ = std::move(provider);
}

std::shared_ptr<AndroidVulkanTextureProvider>
JniDelegate::GetVulkanTextureProvider() const {
  TRACE_EVENT0("flutter", "JniDelegate::GetVulkanTextureProvider");
  std::lock_guard<std::mutex> lock(vulkan_texture_mutex_);
  return vulkan_texture_provider_;
}

int64_t JniDelegate::SpawnEngine(int64_t parent_engine_id,
                                 const AndroidEngineSpawnArgs& args) {
  TRACE_EVENT1("flutter", "JniDelegate::SpawnEngine", "parent_engine_id",
               std::to_string(parent_engine_id).c_str());
  std::shared_ptr<AndroidEngineGroup> group;
  {
    std::scoped_lock lock(engine_group_mutex_);
    group = engine_group_;
  }
  if (!group) {
    return 0;
  }
  auto spawned_handle = group->SpawnEngine(parent_engine_id, args);
  if (spawned_handle == nullptr) {
    return 0;
  }
  auto id_opt = group->GetEngineId(spawned_handle);
  return id_opt.value_or(args.engine_id != 0 ? args.engine_id : 0);
}

bool JniDelegate::ShutdownSpawnedEngine(int64_t engine_id) {
  TRACE_EVENT1("flutter", "JniDelegate::ShutdownSpawnedEngine", "engine_id",
               std::to_string(engine_id).c_str());
  std::shared_ptr<AndroidEngineGroup> group;
  {
    std::scoped_lock lock(engine_group_mutex_);
    group = engine_group_;
  }
  if (!group) {
    return false;
  }
  return group->ShutdownEngine(engine_id);
}

size_t JniDelegate::GetActiveEngineCount() const {
  TRACE_EVENT0("flutter", "JniDelegate::GetActiveEngineCount");
  std::shared_ptr<AndroidEngineGroup> group;
  {
    std::scoped_lock lock(engine_group_mutex_);
    group = engine_group_;
  }
  if (!group) {
    return 0;
  }
  return group->GetActiveEngineCount();
}

bool JniDelegate::OnEngineGarbageCollected(int64_t engine_id) {
  TRACE_EVENT1("flutter", "JniDelegate::OnEngineGarbageCollected", "engine_id",
               std::to_string(engine_id).c_str());
  std::shared_ptr<AndroidEngineGroup> group;
  {
    std::scoped_lock lock(engine_group_mutex_);
    group = engine_group_;
  }
  if (!group) {
    return false;
  }
  return group->OnEngineGarbageCollected(engine_id);
}

std::shared_ptr<AndroidEngineGroup> JniDelegate::GetEngineGroup() const {
  std::scoped_lock lock(engine_group_mutex_);
  return engine_group_;
}

void JniDelegate::SetEngineGroup(std::shared_ptr<AndroidEngineGroup> group) {
  TRACE_EVENT0("flutter", "JniDelegate::SetEngineGroup");
  std::scoped_lock lock(engine_group_mutex_);
  engine_group_ = std::move(group);
}

std::shared_ptr<AndroidEngineGroupProvider>
JniDelegate::GetEngineGroupProvider() const {
  std::scoped_lock lock(engine_group_mutex_);
  return engine_group_provider_;
}

void JniDelegate::SetEngineGroupProvider(
    std::shared_ptr<AndroidEngineGroupProvider> provider) {
  TRACE_EVENT0("flutter", "JniDelegate::SetEngineGroupProvider");
  std::scoped_lock lock(engine_group_mutex_);
  engine_group_provider_ = std::move(provider);
  if (engine_group_) {
    engine_group_->SetProvider(engine_group_provider_);
  }
}

}  // namespace android
}  // namespace flutter
