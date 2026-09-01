// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/jni_delegate.h"

#include <cstring>
#include <utility>

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
    std::shared_ptr<WindowMetricsProvider> window_metrics_provider,
    std::shared_ptr<AndroidVsyncWaiter> vsync_waiter,
    std::shared_ptr<AndroidVMInit> vm_init,
    std::shared_ptr<AndroidHardwareBufferProvider> hardware_buffer_provider,
    std::shared_ptr<AndroidVulkanTextureProvider> vulkan_texture_provider,
    std::shared_ptr<AndroidSurfaceControlProvider> surface_control_provider,
    std::shared_ptr<AndroidEngineGroupProvider> engine_group_provider,
    std::shared_ptr<AndroidEngineGroup> engine_group)
    : jvm_invoker_(std::move(jvm_invoker)),
      callback_cache_(std::move(callback_cache)),
      image_decoder_(std::move(image_decoder)),
      platform_views_provider_(std::move(platform_views_provider)),
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
  platform_views_controller_ = std::make_shared<AndroidPlatformViewsController>(
      platform_views_provider_);
}

JniDelegate::~JniDelegate() {
  TRACE_EVENT0("flutter", "JniDelegate::~JniDelegate");
  std::vector<std::pair<VoidCallback, void*>> hw_destruction_callbacks;
  {
    std::lock_guard<std::mutex> lock(hardware_buffer_mutex_);
    for (auto& [id, frame] : hardware_buffer_frames_) {
      if (frame.destruction_callback) {
        hw_destruction_callbacks.emplace_back(frame.destruction_callback,
                                              frame.user_data);
      }
    }
    hardware_buffer_frames_.clear();
    hardware_buffer_objects_.clear();
  }
  for (const auto& [cb, data] : hw_destruction_callbacks) {
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
    vulkan_ycbcr_conversions_.clear();
  }
  for (const auto& [cb, data] : vk_destruction_callbacks) {
    cb(data);
  }

  {
    std::lock_guard<std::mutex> lock(surface_control_mutex_);
    active_transaction_.reset();
    surface_controls_.clear();
    surface_control_states_.clear();
  }
}

std::shared_ptr<JvmInvoker> JniDelegate::GetJvmInvoker() const {
  return jvm_invoker_;
}

bool JniDelegate::HandlePlatformMessage(const std::string& channel,
                                        const std::vector<uint8_t>& message,
                                        int32_t response_id) {
  TRACE_EVENT1("flutter", "JniDelegate::HandlePlatformMessage", "channel",
               channel.c_str());
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("handlePlatformMessage",
                                        "(Ljava/lang/String;[BI)V", message);
}

bool JniDelegate::HandlePlatformMessageResponse(
    int32_t response_id,
    const std::vector<uint8_t>& data) {
  TRACE_EVENT1("flutter", "JniDelegate::HandlePlatformMessageResponse",
               "response_id", std::to_string(response_id).c_str());
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("handlePlatformMessageResponse",
                                        "(I[B)V", data);
}

bool JniDelegate::UpdateSemantics(const std::vector<uint8_t>& buffer,
                                  const std::vector<std::string>& strings) {
  TRACE_EVENT0("flutter", "JniDelegate::UpdateSemantics");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("updateSemantics",
                                        "([B[Ljava/lang/String;)V", buffer);
}

bool JniDelegate::UpdateSemantics(
    const std::vector<uint8_t>& buffer,
    const std::vector<std::string>& strings,
    const std::vector<std::vector<uint8_t>>& string_attribute_args) {
  TRACE_EVENT0("flutter", "JniDelegate::UpdateSemanticsWithAttributes");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("updateSemantics",
                                        "([B[Ljava/lang/String;[[B)V", buffer);
}

bool JniDelegate::UpdateCustomAccessibilityActions(
    const std::vector<uint8_t>& actions_buffer,
    const std::vector<std::string>& action_strings) {
  TRACE_EVENT0("flutter", "JniDelegate::UpdateCustomAccessibilityActions");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("updateCustomAccessibilityActions",
                                        "([B[Ljava/lang/String;)V",
                                        actions_buffer);
}

bool JniDelegate::UpdateSemantics(const FlutterSemanticsUpdate2& update) {
  TRACE_EVENT0("flutter", "JniDelegate::UpdateSemantics2");
  auto batch = AndroidSemanticsMapper::MapSemanticsUpdate(update);
  if (!batch.custom_actions.empty()) {
    UpdateCustomAccessibilityActions(batch.custom_actions.buffer,
                                     batch.custom_actions.strings);
  }
  if (!batch.nodes.empty()) {
    return UpdateSemantics(batch.nodes.buffer, batch.nodes.strings,
                           batch.nodes.string_attribute_args);
  }
  return true;
}

bool JniDelegate::SetSemanticsEnabled(bool enabled) {
  TRACE_EVENT1("flutter", "JniDelegate::SetSemanticsEnabled", "enabled",
               enabled ? "true" : "false");
  if (!jvm_invoker_) {
    return false;
  }
  std::vector<uint8_t> payload = {static_cast<uint8_t>(enabled ? 1 : 0)};
  return jvm_invoker_->InvokeVoidMethod("setSemanticsEnabled", "(Z)V", payload);
}

bool JniDelegate::DispatchSemanticsAction(int32_t node_id,
                                          FlutterSemanticsAction action,
                                          const std::vector<uint8_t>& data,
                                          int64_t view_id) {
  TRACE_EVENT1("flutter", "JniDelegate::DispatchSemanticsAction", "node_id",
               std::to_string(node_id).c_str());
  if (!jvm_invoker_) {
    return false;
  }
  std::vector<uint8_t> payload;
  payload.resize(sizeof(int32_t) + sizeof(int32_t) + sizeof(int64_t) +
                 data.size());
  size_t offset = 0;
  std::memcpy(payload.data() + offset, &node_id, sizeof(int32_t));
  offset += sizeof(int32_t);
  int32_t action_val = static_cast<int32_t>(action);
  std::memcpy(payload.data() + offset, &action_val, sizeof(int32_t));
  offset += sizeof(int32_t);
  std::memcpy(payload.data() + offset, &view_id, sizeof(int64_t));
  offset += sizeof(int64_t);
  if (!data.empty()) {
    std::memcpy(payload.data() + offset, data.data(), data.size());
  }
  return jvm_invoker_->InvokeVoidMethod("dispatchSemanticsAction", "(IIJ[B)V",
                                        payload);
}

bool JniDelegate::SetAccessibilityFeatures(int32_t flags) {
  TRACE_EVENT1("flutter", "JniDelegate::SetAccessibilityFeatures", "flags",
               std::to_string(flags).c_str());
  if (!jvm_invoker_) {
    return false;
  }
  std::vector<uint8_t> payload(sizeof(int32_t));
  std::memcpy(payload.data(), &flags, sizeof(int32_t));
  return jvm_invoker_->InvokeVoidMethod("setAccessibilityFeatures", "(I)V",
                                        payload);
}

bool JniDelegate::SetApplicationLocale(const std::string& locale) {
  TRACE_EVENT1("flutter", "JniDelegate::SetApplicationLocale", "locale",
               locale.c_str());
  if (!jvm_invoker_) {
    return false;
  }
  std::vector<uint8_t> payload(locale.begin(), locale.end());
  return jvm_invoker_->InvokeVoidMethod("setApplicationLocale",
                                        "(Ljava/lang/String;)V", payload);
}

bool JniDelegate::OnFirstFrame() {
  TRACE_EVENT0("flutter", "JniDelegate::OnFirstFrame");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("onFirstFrame", "()V");
}

bool JniDelegate::OnPreEngineRestart() {
  TRACE_EVENT0("flutter", "JniDelegate::OnPreEngineRestart");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("onPreEngineRestart", "()V");
}

bool JniDelegate::OnVsync(int64_t frame_time_nanos,
                          int64_t frame_target_time_nanos) {
  TRACE_EVENT0("flutter", "JniDelegate::OnVsync");
  if (!jvm_invoker_) {
    return false;
  }
  std::vector<uint8_t> payload(sizeof(int64_t) * 2);
  std::memcpy(payload.data(), &frame_time_nanos, sizeof(int64_t));
  std::memcpy(payload.data() + sizeof(int64_t), &frame_target_time_nanos,
              sizeof(int64_t));
  return jvm_invoker_->InvokeVoidMethod("onVsync", "(JJ)V", payload);
}

bool JniDelegate::AsyncWaitForVsync(intptr_t baton) {
  TRACE_EVENT0("flutter", "JniDelegate::AsyncWaitForVsync");
  if (vsync_waiter_) {
    return vsync_waiter_->AsyncWaitForVsync(baton);
  }
  return false;
}

bool JniDelegate::SetViewportMetrics(const AndroidViewportMetrics& metrics) {
  TRACE_EVENT0("flutter", "JniDelegate::SetViewportMetrics");
  if (window_metrics_provider_) {
    return window_metrics_provider_->SendViewportMetrics(metrics);
  }
  return false;
}

bool JniDelegate::UpdateDisplayMetrics(const AndroidDisplayMetrics& metrics) {
  TRACE_EVENT0("flutter", "JniDelegate::UpdateDisplayMetrics");
  if (window_metrics_provider_) {
    return window_metrics_provider_->UpdateDisplayMetrics(metrics);
  }
  return false;
}

bool JniDelegate::UpdateDisplayMetrics(uint64_t display_id,
                                       double refresh_rate,
                                       double width,
                                       double height,
                                       double device_pixel_ratio) {
  TRACE_EVENT0("flutter", "JniDelegate::UpdateDisplayMetrics(params)");
  AndroidDisplayMetrics metrics;
  metrics.display_id = display_id;
  metrics.refresh_rate = refresh_rate;
  metrics.width = width;
  metrics.height = height;
  metrics.device_pixel_ratio = device_pixel_ratio;
  if (window_metrics_provider_) {
    return window_metrics_provider_->UpdateDisplayMetrics(metrics);
  }
  return false;
}

std::optional<AndroidViewportMetrics> JniDelegate::GetViewportMetrics(
    int64_t view_id) const {
  if (window_metrics_provider_) {
    return window_metrics_provider_->GetViewportMetrics(view_id);
  }
  return std::nullopt;
}

std::optional<AndroidDisplayMetrics> JniDelegate::GetDisplayMetrics(
    uint64_t display_id) const {
  if (window_metrics_provider_) {
    return window_metrics_provider_->GetDisplayMetrics(display_id);
  }
  return std::nullopt;
}

bool JniDelegate::DispatchViewportMetrics(int64_t view_id,
                                          double width,
                                          double height,
                                          double pixel_ratio) {
  TRACE_EVENT1("flutter", "JniDelegate::DispatchViewportMetrics", "view_id",
               std::to_string(view_id).c_str());
  if (window_metrics_provider_) {
    AndroidViewportMetrics metrics;
    metrics.view_id = view_id;
    metrics.physical_width = width;
    metrics.physical_height = height;
    metrics.device_pixel_ratio = pixel_ratio;
    return window_metrics_provider_->SendViewportMetrics(metrics);
  }
  if (!jvm_invoker_) {
    return false;
  }
  std::vector<uint8_t> payload(sizeof(int64_t) + sizeof(double) * 3);
  size_t offset = 0;
  std::memcpy(payload.data() + offset, &view_id, sizeof(int64_t));
  offset += sizeof(int64_t);
  std::memcpy(payload.data() + offset, &width, sizeof(double));
  offset += sizeof(double);
  std::memcpy(payload.data() + offset, &height, sizeof(double));
  offset += sizeof(double);
  std::memcpy(payload.data() + offset, &pixel_ratio, sizeof(double));
  return jvm_invoker_->InvokeVoidMethod("dispatchViewportMetrics", "(JDDD)V",
                                        payload);
}

bool JniDelegate::RequestDartDeferredLibrary(int64_t loading_unit_id) {
  TRACE_EVENT1("flutter", "JniDelegate::RequestDartDeferredLibrary",
               "loading_unit_id", std::to_string(loading_unit_id).c_str());
  if (!jvm_invoker_) {
    return false;
  }
  std::vector<uint8_t> payload(sizeof(int64_t));
  std::memcpy(payload.data(), &loading_unit_id, sizeof(int64_t));
  return jvm_invoker_->InvokeVoidMethod("requestDartDeferredLibrary", "(J)V",
                                        payload);
}

bool JniDelegate::OnAssetManagerChanged() {
  TRACE_EVENT0("flutter", "JniDelegate::OnAssetManagerChanged");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("onAssetManagerChanged", "()V");
}

void JniDelegate::SetCallbackCache(
    std::shared_ptr<CallbackCacheProvider> provider) {
  TRACE_EVENT0("flutter", "JniDelegate::SetCallbackCache");
  callback_cache_ = std::move(provider);
}

std::shared_ptr<CallbackCacheProvider> JniDelegate::GetCallbackCache() const {
  return callback_cache_;
}

std::optional<DartCallbackInfo> JniDelegate::LookupCallbackInformation(
    int64_t handle) {
  TRACE_EVENT1("flutter", "JniDelegate::LookupCallbackInformation", "handle",
               std::to_string(handle).c_str());
  if (callback_cache_) {
    return callback_cache_->GetCallbackInformation(handle);
  }
  if (!jvm_invoker_) {
    return std::nullopt;
  }
  std::vector<uint8_t> payload(sizeof(int64_t));
  std::memcpy(payload.data(), &handle, sizeof(int64_t));
  std::string name = jvm_invoker_->InvokeStringMethod(
      "getCallbackName", "(J)Ljava/lang/String;", payload);
  std::string class_name = jvm_invoker_->InvokeStringMethod(
      "getCallbackClassName", "(J)Ljava/lang/String;", payload);
  std::string library_path = jvm_invoker_->InvokeStringMethod(
      "getCallbackLibraryPath", "(J)Ljava/lang/String;", payload);
  if (name.empty() && class_name.empty() && library_path.empty()) {
    return std::nullopt;
  }
  return DartCallbackInfo{name, class_name, library_path};
}

void JniDelegate::SetImageDecoderProvider(
    std::shared_ptr<ImageDecoderProvider> provider) {
  TRACE_EVENT0("flutter", "JniDelegate::SetImageDecoderProvider");
  image_decoder_ = std::move(provider);
}

std::shared_ptr<ImageDecoderProvider> JniDelegate::GetImageDecoderProvider()
    const {
  return image_decoder_;
}

bool JniDelegate::DecodeImage(const uint8_t* data,
                              size_t size,
                              int64_t generator_handle) {
  TRACE_EVENT1("flutter", "JniDelegate::DecodeImage", "handle",
               std::to_string(generator_handle).c_str());
  if (image_decoder_) {
    return image_decoder_->DecodeImage(data, size, generator_handle);
  }
  if (!jvm_invoker_) {
    return false;
  }
  std::vector<uint8_t> payload(data, data + size);
  return jvm_invoker_->InvokeBooleanMethod("decodeImage", "([BJ)Z", payload);
}

void JniDelegate::OnNativeImageHeader(int64_t generator_handle,
                                      int32_t width,
                                      int32_t height) {
  TRACE_EVENT1("flutter", "JniDelegate::OnNativeImageHeader", "handle",
               std::to_string(generator_handle).c_str());
  if (image_decoder_) {
    image_decoder_->OnImageHeader(generator_handle, width, height);
  }
}

std::optional<ImageHeaderInfo> JniDelegate::GetImageHeader(
    int64_t generator_handle) {
  TRACE_EVENT1("flutter", "JniDelegate::GetImageHeader", "handle",
               std::to_string(generator_handle).c_str());
  if (image_decoder_) {
    return image_decoder_->GetImageHeader(generator_handle);
  }
  return std::nullopt;
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
  TRACE_EVENT1("flutter", "JniDelegate::OnDisplayPlatformView(view)", "view_id",
               std::to_string(platform_view.identifier).c_str());
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

bool JniDelegate::CreatePlatformViewTransaction() {
  TRACE_EVENT0("flutter", "JniDelegate::CreatePlatformViewTransaction");
  if (surface_control_provider_) {
    std::lock_guard<std::mutex> lock(surface_control_mutex_);
    active_transaction_ = surface_control_provider_->CreateTransaction();
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
    if (active_transaction_) {
      applied_sc = active_transaction_->Apply();
      active_transaction_.reset();
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
  if (surface_controls_.empty()) {
    sc = surface_control_provider_->CreateFromWindow(
        reinterpret_cast<void*>(0x1), name);
  } else {
    auto parent_it = surface_controls_.begin();
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
  state.parent_id = sc->GetParentId();
  state.is_valid = sc->IsValid();
  state.ref_count = 1;

  surface_controls_[surface_id] = std::move(sc);
  surface_control_states_[surface_id] = state;

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
  surface_controls_.erase(surface_id);
  surface_control_states_.erase(surface_id);
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
    active_transaction_->Reparent(it->second.get(), parent_ptr);
  } else if (surface_control_provider_) {
    auto tx = surface_control_provider_->CreateTransaction();
    if (tx) {
      tx->Reparent(it->second.get(), parent_ptr);
      tx->Apply();
    }
  }

  surface_control_states_[surface_id].parent_handle = parent_handle;
  surface_control_states_[surface_id].parent_id = new_parent_id;
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
  if (it != surface_controls_.end()) {
    if (active_transaction_) {
      active_transaction_->SetGeometry(
          it->second.get(), source, destination,
          static_cast<AndroidSurfaceControlTransform>(transform));
    } else if (surface_control_provider_) {
      auto tx = surface_control_provider_->CreateTransaction();
      if (tx) {
        tx->SetGeometry(it->second.get(), source, destination,
                        static_cast<AndroidSurfaceControlTransform>(transform));
        tx->Apply();
      }
    }
  }
  auto state_it = surface_control_states_.find(surface_id);
  if (state_it != surface_control_states_.end()) {
    state_it->second.source_rect = source;
    state_it->second.destination_rect = destination;
    state_it->second.transform =
        static_cast<AndroidSurfaceControlTransform>(transform);
  }
  return true;
}

bool JniDelegate::SetSurfaceControlVisibility(int64_t surface_id,
                                              bool visible) {
  TRACE_EVENT1("flutter", "JniDelegate::SetSurfaceControlVisibility",
               "surface_id", std::to_string(surface_id).c_str());
  std::lock_guard<std::mutex> lock(surface_control_mutex_);
  auto it = surface_controls_.find(surface_id);
  auto vis = visible ? AndroidSurfaceControlVisibility::kShow
                     : AndroidSurfaceControlVisibility::kHide;
  if (it != surface_controls_.end()) {
    if (active_transaction_) {
      active_transaction_->SetVisibility(it->second.get(), vis);
    } else if (surface_control_provider_) {
      auto tx = surface_control_provider_->CreateTransaction();
      if (tx) {
        tx->SetVisibility(it->second.get(), vis);
        tx->Apply();
      }
    }
  }
  auto state_it = surface_control_states_.find(surface_id);
  if (state_it != surface_control_states_.end()) {
    state_it->second.visibility = vis;
  }
  return true;
}

bool JniDelegate::SetSurfaceControlZOrder(int64_t surface_id, int32_t z_order) {
  TRACE_EVENT1("flutter", "JniDelegate::SetSurfaceControlZOrder", "surface_id",
               std::to_string(surface_id).c_str());
  std::lock_guard<std::mutex> lock(surface_control_mutex_);
  auto it = surface_controls_.find(surface_id);
  if (it != surface_controls_.end()) {
    if (active_transaction_) {
      active_transaction_->SetZOrder(it->second.get(), z_order);
    } else if (surface_control_provider_) {
      auto tx = surface_control_provider_->CreateTransaction();
      if (tx) {
        tx->SetZOrder(it->second.get(), z_order);
        tx->Apply();
      }
    }
  }
  auto state_it = surface_control_states_.find(surface_id);
  if (state_it != surface_control_states_.end()) {
    state_it->second.z_order = z_order;
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
  if (it != surface_controls_.end()) {
    if (active_transaction_) {
      active_transaction_->SetDamageRegion(it->second.get(), rects);
    } else if (surface_control_provider_) {
      auto tx = surface_control_provider_->CreateTransaction();
      if (tx) {
        tx->SetDamageRegion(it->second.get(), rects);
        tx->Apply();
      }
    }
  }
  auto state_it = surface_control_states_.find(surface_id);
  if (state_it != surface_control_states_.end()) {
    state_it->second.damage_region = rects;
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
  if (it != surface_controls_.end()) {
    if (active_transaction_) {
      active_transaction_->SetBuffer(it->second.get(), buffer, fence_fd);
    } else if (surface_control_provider_) {
      auto tx = surface_control_provider_->CreateTransaction();
      if (tx) {
        tx->SetBuffer(it->second.get(), buffer, fence_fd);
        tx->Apply();
      }
    }
  }
  auto state_it = surface_control_states_.find(surface_id);
  if (state_it != surface_control_states_.end()) {
    state_it->second.buffer_handle = buffer;
    state_it->second.buffer_fence_fd = fence_fd;
  }
  return true;
}

bool JniDelegate::SetSurfaceControlBufferAlpha(int64_t surface_id,
                                               float alpha) {
  TRACE_EVENT1("flutter", "JniDelegate::SetSurfaceControlBufferAlpha",
               "surface_id", std::to_string(surface_id).c_str());
  std::lock_guard<std::mutex> lock(surface_control_mutex_);
  auto it = surface_controls_.find(surface_id);
  if (it != surface_controls_.end()) {
    if (active_transaction_) {
      active_transaction_->SetBufferAlpha(it->second.get(), alpha);
    } else if (surface_control_provider_) {
      auto tx = surface_control_provider_->CreateTransaction();
      if (tx) {
        tx->SetBufferAlpha(it->second.get(), alpha);
        tx->Apply();
      }
    }
  }
  auto state_it = surface_control_states_.find(surface_id);
  if (state_it != surface_control_states_.end()) {
    state_it->second.alpha = alpha;
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
  if (it != surface_controls_.end()) {
    if (active_transaction_) {
      active_transaction_->SetColor(it->second.get(), r, g, b, alpha);
    } else if (surface_control_provider_) {
      auto tx = surface_control_provider_->CreateTransaction();
      if (tx) {
        tx->SetColor(it->second.get(), r, g, b, alpha);
        tx->Apply();
      }
    }
  }
  auto state_it = surface_control_states_.find(surface_id);
  if (state_it != surface_control_states_.end()) {
    state_it->second.color = AndroidSurfaceControlColor{r, g, b, alpha};
  }
  return true;
}

void JniDelegate::SetSurfaceControlProvider(
    std::shared_ptr<AndroidSurfaceControlProvider> provider) {
  TRACE_EVENT0("flutter", "JniDelegate::SetSurfaceControlProvider");
  surface_control_provider_ = std::move(provider);
}

std::shared_ptr<AndroidSurfaceControlProvider>
JniDelegate::GetSurfaceControlProvider() const {
  TRACE_EVENT0("flutter", "JniDelegate::GetSurfaceControlProvider");
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
  TRACE_EVENT0("flutter", "JniDelegate::PushPlatformViewMutators");
  if (platform_views_controller_) {
    return platform_views_controller_->PushPlatformViewMutators(
        view_id, x, y, width, height, mutators_stack);
  }
  if (!jvm_invoker_) {
    return false;
  }
  std::vector<uint8_t> payload = mutators_stack.Serialize();
  return jvm_invoker_->InvokeVoidMethod("pushPlatformViewMutators",
                                        "(JIIII[B)V", payload);
}

bool JniDelegate::PushPlatformViewMutators(
    const FlutterPlatformView& platform_view,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height) {
  TRACE_EVENT0("flutter", "JniDelegate::PushPlatformViewMutators(view)");
  if (platform_views_controller_) {
    return platform_views_controller_->PushPlatformViewMutators(
        platform_view, x, y, width, height);
  }
  AndroidMutatorsStack stack =
      AndroidMutatorsMapper::MapPlatformView(platform_view);
  return PushPlatformViewMutators(platform_view.identifier, x, y, width, height,
                                  stack);
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
  window_metrics_provider_ =
      provider ? std::move(provider)
               : std::make_shared<DefaultWindowMetricsProvider>(jvm_invoker_);
}

std::shared_ptr<WindowMetricsProvider> JniDelegate::GetWindowMetricsProvider()
    const {
  return window_metrics_provider_;
}

void JniDelegate::SetVsyncWaiter(std::shared_ptr<AndroidVsyncWaiter> provider) {
  TRACE_EVENT0("flutter", "JniDelegate::SetVsyncWaiter");
  vsync_waiter_ = std::move(provider);
}

std::shared_ptr<AndroidVsyncWaiter> JniDelegate::GetVsyncWaiter() const {
  return vsync_waiter_;
}

bool JniDelegate::InitVM(const AndroidVMArgs& args) {
  TRACE_EVENT0("flutter", "JniDelegate::InitVM");
  if (vm_init_) {
    return vm_init_->Init(args);
  }
  return false;
}

bool JniDelegate::PrefetchDefaultFontManager() {
  TRACE_EVENT0("flutter", "JniDelegate::PrefetchDefaultFontManager");
  if (vm_init_) {
    return vm_init_->PrefetchDefaultFontManager();
  }
  return false;
}

bool JniDelegate::SetVmServiceUri(const std::string& uri) {
  TRACE_EVENT1("flutter", "JniDelegate::SetVmServiceUri", "uri", uri.c_str());
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
  if (vm_init_) {
    return vm_init_->GetVmServiceUri();
  }
  return "";
}

bool JniDelegate::IsVMInitialized() const {
  if (vm_init_) {
    return vm_init_->IsInitialized();
  }
  return false;
}

std::optional<AndroidVMArgs> JniDelegate::GetVMArgs() const {
  if (vm_init_) {
    return vm_init_->GetVMArgs();
  }
  return std::nullopt;
}

void JniDelegate::SetVMInit(std::shared_ptr<AndroidVMInit> vm_init) {
  TRACE_EVENT0("flutter", "JniDelegate::SetVMInit");
  vm_init_ = vm_init ? std::move(vm_init)
                     : std::make_shared<AndroidVMInit>(jvm_invoker_);
}

std::shared_ptr<AndroidVMInit> JniDelegate::GetVMInit() const {
  return vm_init_;
}

bool JniDelegate::RegisterHardwareBufferTexture(int64_t texture_id) {
  TRACE_EVENT1("flutter", "JniDelegate::RegisterHardwareBufferTexture",
               "texture_id", std::to_string(texture_id).c_str());
  std::lock_guard<std::mutex> lock(hardware_buffer_mutex_);
  registered_hardware_textures_.insert(texture_id);
  return jvm_invoker_->InvokeBooleanMethod("registerHardwareBufferTexture",
                                           "(J)Z", {});
}

bool JniDelegate::UnregisterHardwareBufferTexture(int64_t texture_id) {
  TRACE_EVENT1("flutter", "JniDelegate::UnregisterHardwareBufferTexture",
               "texture_id", std::to_string(texture_id).c_str());
  VoidCallback destruction_cb = nullptr;
  void* user_data = nullptr;
  {
    std::lock_guard<std::mutex> lock(hardware_buffer_mutex_);
    registered_hardware_textures_.erase(texture_id);
    auto it = hardware_buffer_frames_.find(texture_id);
    if (it != hardware_buffer_frames_.end()) {
      destruction_cb = it->second.destruction_callback;
      user_data = it->second.user_data;
      hardware_buffer_frames_.erase(it);
    }
    hardware_buffer_objects_.erase(texture_id);
  }
  if (destruction_cb) {
    destruction_cb(user_data);
  }
  return jvm_invoker_->InvokeBooleanMethod("unregisterHardwareBufferTexture",
                                           "(J)Z", {});
}

bool JniDelegate::SetHardwareBufferFrame(
    int64_t texture_id,
    const std::shared_ptr<AndroidHardwareBuffer>& buffer) {
  TRACE_EVENT1("flutter", "JniDelegate::SetHardwareBufferFrame(object)",
               "texture_id", std::to_string(texture_id).c_str());
  VoidCallback old_destruction_cb = nullptr;
  void* old_user_data = nullptr;
  {
    std::lock_guard<std::mutex> lock(hardware_buffer_mutex_);
    auto it = hardware_buffer_frames_.find(texture_id);
    if (it != hardware_buffer_frames_.end()) {
      old_destruction_cb = it->second.destruction_callback;
      old_user_data = it->second.user_data;
    }
    if (!buffer || !buffer->IsValid()) {
      hardware_buffer_frames_.erase(texture_id);
      hardware_buffer_objects_.erase(texture_id);
      if (old_destruction_cb) {
        old_destruction_cb(old_user_data);
      }
      return false;
    }
    hardware_buffer_objects_[texture_id] = buffer;
    hardware_buffer_frames_[texture_id] = buffer->ToExternalTexture();
  }
  if (old_destruction_cb) {
    old_destruction_cb(old_user_data);
  }
  return true;
}

bool JniDelegate::SetHardwareBufferFrame(
    int64_t texture_id,
    const FlutterHardwareBufferExternalTexture& texture) {
  TRACE_EVENT1("flutter", "JniDelegate::SetHardwareBufferFrame(struct)",
               "texture_id", std::to_string(texture_id).c_str());
  VoidCallback old_destruction_cb = nullptr;
  void* old_user_data = nullptr;
  {
    std::lock_guard<std::mutex> lock(hardware_buffer_mutex_);
    auto it = hardware_buffer_frames_.find(texture_id);
    if (it != hardware_buffer_frames_.end()) {
      old_destruction_cb = it->second.destruction_callback;
      old_user_data = it->second.user_data;
    }
    hardware_buffer_frames_[texture_id] = texture;
  }
  if (old_destruction_cb) {
    old_destruction_cb(old_user_data);
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
  auto it = hardware_buffer_frames_.find(texture_id);
  if (it != hardware_buffer_frames_.end()) {
    *texture_out = it->second;
    if (texture_out->struct_size == 0) {
      texture_out->struct_size = sizeof(FlutterHardwareBufferExternalTexture);
    }
    return true;
  }
  return false;
}

bool JniDelegate::OnHardwareBufferFrameAvailable(int64_t texture_id) {
  TRACE_EVENT1("flutter", "JniDelegate::OnHardwareBufferFrameAvailable",
               "texture_id", std::to_string(texture_id).c_str());
  return jvm_invoker_->InvokeBooleanMethod("onHardwareBufferFrameAvailable",
                                           "(J)Z", {});
}

void JniDelegate::SetHardwareBufferProvider(
    std::shared_ptr<AndroidHardwareBufferProvider> provider) {
  TRACE_EVENT0("flutter", "JniDelegate::SetHardwareBufferProvider");
  hardware_buffer_provider_ = std::move(provider);
}

std::shared_ptr<AndroidHardwareBufferProvider>
JniDelegate::GetHardwareBufferProvider() const {
  TRACE_EVENT0("flutter", "JniDelegate::GetHardwareBufferProvider");
  return hardware_buffer_provider_;
}

bool JniDelegate::RegisterVulkanTexture(int64_t texture_id) {
  TRACE_EVENT1("flutter", "JniDelegate::RegisterVulkanTexture", "texture_id",
               std::to_string(texture_id).c_str());
  std::lock_guard<std::mutex> lock(vulkan_texture_mutex_);
  registered_vulkan_textures_.insert(texture_id);
  return jvm_invoker_->InvokeBooleanMethod("registerVulkanTexture", "(J)Z", {});
}

bool JniDelegate::UnregisterVulkanTexture(int64_t texture_id) {
  TRACE_EVENT1("flutter", "JniDelegate::UnregisterVulkanTexture", "texture_id",
               std::to_string(texture_id).c_str());
  VoidCallback destruction_cb = nullptr;
  void* user_data = nullptr;
  {
    std::lock_guard<std::mutex> lock(vulkan_texture_mutex_);
    registered_vulkan_textures_.erase(texture_id);
    auto it = vulkan_texture_frames_.find(texture_id);
    if (it != vulkan_texture_frames_.end()) {
      destruction_cb = it->second.destruction_callback;
      user_data = it->second.user_data;
      vulkan_texture_frames_.erase(it);
    }
    vulkan_texture_objects_.erase(texture_id);
    vulkan_ycbcr_conversions_.erase(texture_id);
  }
  if (destruction_cb) {
    destruction_cb(user_data);
  }
  return jvm_invoker_->InvokeBooleanMethod("unregisterVulkanTexture", "(J)Z",
                                           {});
}

bool JniDelegate::SetVulkanTextureFrame(
    int64_t texture_id,
    const std::shared_ptr<AndroidVulkanExternalTexture>& texture) {
  TRACE_EVENT1("flutter", "JniDelegate::SetVulkanTextureFrame(object)",
               "texture_id", std::to_string(texture_id).c_str());
  VoidCallback old_destruction_cb = nullptr;
  void* old_user_data = nullptr;
  {
    std::lock_guard<std::mutex> lock(vulkan_texture_mutex_);
    auto it = vulkan_texture_frames_.find(texture_id);
    if (it != vulkan_texture_frames_.end()) {
      old_destruction_cb = it->second.destruction_callback;
      old_user_data = it->second.user_data;
    }
    if (!texture || !texture->IsValid()) {
      vulkan_texture_frames_.erase(texture_id);
      vulkan_texture_objects_.erase(texture_id);
      vulkan_ycbcr_conversions_.erase(texture_id);
      if (old_destruction_cb) {
        old_destruction_cb(old_user_data);
      }
      return false;
    }
    vulkan_texture_objects_[texture_id] = texture;
    FlutterVulkanExternalTexture ext_texture = texture->ToExternalTexture();
    if (texture->HasYcbcrConversion()) {
      const auto* ycbcr_desc = texture->GetYcbcrConversionDesc();
      if (ycbcr_desc) {
        vulkan_ycbcr_conversions_[texture_id] =
            ycbcr_desc->ToFlutterYcbcrConversionInfo();
        ext_texture.ycbcr_conversion_info =
            &vulkan_ycbcr_conversions_[texture_id];
      }
    } else {
      vulkan_ycbcr_conversions_.erase(texture_id);
    }
    vulkan_texture_frames_[texture_id] = ext_texture;
  }
  if (old_destruction_cb) {
    old_destruction_cb(old_user_data);
  }
  return true;
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
    auto it = vulkan_texture_frames_.find(texture_id);
    if (it != vulkan_texture_frames_.end()) {
      old_destruction_cb = it->second.destruction_callback;
      old_user_data = it->second.user_data;
    }
    FlutterVulkanExternalTexture copied_texture = texture;
    if (texture.ycbcr_conversion_info != nullptr) {
      vulkan_ycbcr_conversions_[texture_id] = *texture.ycbcr_conversion_info;
      copied_texture.ycbcr_conversion_info =
          &vulkan_ycbcr_conversions_[texture_id];
    } else {
      vulkan_ycbcr_conversions_.erase(texture_id);
    }
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
  auto it = vulkan_texture_frames_.find(texture_id);
  if (it != vulkan_texture_frames_.end()) {
    *texture_out = it->second;
    if (texture_out->struct_size == 0) {
      texture_out->struct_size = sizeof(FlutterVulkanExternalTexture);
    }
    return true;
  }
  return false;
}

bool JniDelegate::OnVulkanTextureFrameAvailable(int64_t texture_id) {
  TRACE_EVENT1("flutter", "JniDelegate::OnVulkanTextureFrameAvailable",
               "texture_id", std::to_string(texture_id).c_str());
  return jvm_invoker_->InvokeBooleanMethod("onVulkanTextureFrameAvailable",
                                           "(J)Z", {});
}

void JniDelegate::SetVulkanTextureProvider(
    std::shared_ptr<AndroidVulkanTextureProvider> provider) {
  TRACE_EVENT0("flutter", "JniDelegate::SetVulkanTextureProvider");
  vulkan_texture_provider_ = std::move(provider);
}

std::shared_ptr<AndroidVulkanTextureProvider>
JniDelegate::GetVulkanTextureProvider() const {
  TRACE_EVENT0("flutter", "JniDelegate::GetVulkanTextureProvider");
  return vulkan_texture_provider_;
}

int64_t JniDelegate::SpawnEngine(int64_t parent_engine_id,
                                 const AndroidEngineSpawnArgs& args) {
  TRACE_EVENT1("flutter", "JniDelegate::SpawnEngine", "parent_engine_id",
               std::to_string(parent_engine_id).c_str());
  if (!engine_group_) {
    return 0;
  }
  auto spawned_handle = engine_group_->SpawnEngine(parent_engine_id, args);
  if (spawned_handle == nullptr) {
    return 0;
  }
  auto id_opt = engine_group_->GetEngineId(spawned_handle);
  return id_opt.value_or(args.engine_id != 0 ? args.engine_id : 0);
}

bool JniDelegate::ShutdownSpawnedEngine(int64_t engine_id) {
  TRACE_EVENT1("flutter", "JniDelegate::ShutdownSpawnedEngine", "engine_id",
               std::to_string(engine_id).c_str());
  if (!engine_group_) {
    return false;
  }
  return engine_group_->ShutdownEngine(engine_id);
}

size_t JniDelegate::GetActiveEngineCount() const {
  TRACE_EVENT0("flutter", "JniDelegate::GetActiveEngineCount");
  if (!engine_group_) {
    return 0;
  }
  return engine_group_->GetActiveEngineCount();
}

bool JniDelegate::OnEngineGarbageCollected(int64_t engine_id) {
  TRACE_EVENT1("flutter", "JniDelegate::OnEngineGarbageCollected", "engine_id",
               std::to_string(engine_id).c_str());
  if (!engine_group_) {
    return false;
  }
  return engine_group_->OnEngineGarbageCollected(engine_id);
}

std::shared_ptr<AndroidEngineGroup> JniDelegate::GetEngineGroup() const {
  return engine_group_;
}

void JniDelegate::SetEngineGroup(std::shared_ptr<AndroidEngineGroup> group) {
  TRACE_EVENT0("flutter", "JniDelegate::SetEngineGroup");
  engine_group_ = std::move(group);
}

std::shared_ptr<AndroidEngineGroupProvider>
JniDelegate::GetEngineGroupProvider() const {
  return engine_group_provider_;
}

void JniDelegate::SetEngineGroupProvider(
    std::shared_ptr<AndroidEngineGroupProvider> provider) {
  TRACE_EVENT0("flutter", "JniDelegate::SetEngineGroupProvider");
  engine_group_provider_ = std::move(provider);
  if (engine_group_) {
    engine_group_->SetProvider(engine_group_provider_);
  }
}

}  // namespace android
}  // namespace flutter
