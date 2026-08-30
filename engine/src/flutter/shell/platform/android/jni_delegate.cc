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

JniDelegate::JniDelegate(
    std::shared_ptr<JvmInvoker> jvm_invoker,
    std::shared_ptr<CallbackCacheProvider> callback_cache,
    std::shared_ptr<ImageDecoderProvider> image_decoder,
    std::shared_ptr<PlatformViewsProvider> platform_views_provider,
    std::shared_ptr<AndroidPlatformViewsController> platform_views_controller,
    std::shared_ptr<WindowMetricsProvider> window_metrics_provider,
    std::shared_ptr<AndroidVsyncWaiter> vsync_waiter,
    std::shared_ptr<AndroidVMInit> vm_init,
    std::shared_ptr<AndroidHardwareBufferProvider> hardware_buffer_provider)
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
      hardware_buffer_provider_(std::move(hardware_buffer_provider)) {
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

bool JniDelegate::CreatePlatformViewTransaction() {
  TRACE_EVENT0("flutter", "JniDelegate::CreatePlatformViewTransaction");
  if (!platform_views_controller_) {
    return false;
  }
  return platform_views_controller_->CreateTransaction();
}

bool JniDelegate::SwapPlatformViewTransactions() {
  TRACE_EVENT0("flutter", "JniDelegate::SwapPlatformViewTransactions");
  if (!platform_views_controller_) {
    return false;
  }
  return platform_views_controller_->SwapTransactions();
}

bool JniDelegate::ApplyPlatformViewTransactions() {
  TRACE_EVENT0("flutter", "JniDelegate::ApplyPlatformViewTransactions");
  if (!platform_views_controller_) {
    return false;
  }
  return platform_views_controller_->ApplyTransactions();
}

bool JniDelegate::IsHcppEnabled() const {
  TRACE_EVENT0("flutter", "JniDelegate::IsHcppEnabled");
  if (!platform_views_controller_) {
    return false;
  }
  return platform_views_controller_->IsHcppEnabled();
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

}  // namespace android
}  // namespace flutter
