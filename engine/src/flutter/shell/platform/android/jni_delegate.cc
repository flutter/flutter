// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/jni_delegate.h"

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
    std::shared_ptr<WindowMetricsProvider> window_metrics_provider,
    std::shared_ptr<AndroidVsyncWaiter> vsync_waiter)
    : jvm_invoker_(std::move(jvm_invoker)),
      callback_cache_(std::move(callback_cache)),
      image_decoder_(std::move(image_decoder)),
      platform_views_provider_(std::move(platform_views_provider)),
      window_metrics_provider_(std::move(window_metrics_provider)),
      vsync_waiter_(std::move(vsync_waiter)) {
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
  platform_views_controller_ = std::make_shared<AndroidPlatformViewsController>(
      platform_views_provider_);
}

JniDelegate::~JniDelegate() {
  TRACE_EVENT0("flutter", "JniDelegate::~JniDelegate");
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
  TRACE_EVENT0("flutter", "JniDelegate::HandlePlatformMessageResponse");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("handlePlatformMessageResponse",
                                        "(I[B)V", data);
}

bool JniDelegate::UpdateSemantics(const std::vector<uint8_t>& buffer,
                                  const std::vector<std::string>& strings) {
  TRACE_EVENT0("flutter", "JniDelegate::UpdateSemantics(legacy)");
  return UpdateSemantics(buffer, strings, {});
}

bool JniDelegate::UpdateSemantics(
    const std::vector<uint8_t>& buffer,
    const std::vector<std::string>& strings,
    const std::vector<std::vector<uint8_t>>& string_attribute_args) {
  TRACE_EVENT0("flutter", "JniDelegate::UpdateSemantics");
  if (!jvm_invoker_ || buffer.empty()) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod(
      "updateSemantics",
      "(Ljava/nio/ByteBuffer;[Ljava/lang/String;[Ljava/nio/ByteBuffer;)V",
      buffer);
}

bool JniDelegate::UpdateCustomAccessibilityActions(
    const std::vector<uint8_t>& actions_buffer,
    const std::vector<std::string>& action_strings) {
  TRACE_EVENT0("flutter", "JniDelegate::UpdateCustomAccessibilityActions");
  if (!jvm_invoker_ || actions_buffer.empty()) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod(
      "updateCustomAccessibilityActions",
      "(Ljava/nio/ByteBuffer;[Ljava/lang/String;)V", actions_buffer);
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

bool JniDelegate::SetSemanticsEnabled(bool enabled) {
  TRACE_EVENT0("flutter", "JniDelegate::SetSemanticsEnabled");
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
  TRACE_EVENT0("flutter", "JniDelegate::DispatchSemanticsAction");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("dispatchSemanticsAction", "(II[BI)V",
                                        data);
}

bool JniDelegate::SetAccessibilityFeatures(int32_t flags) {
  TRACE_EVENT0("flutter", "JniDelegate::SetAccessibilityFeatures");
  if (!jvm_invoker_) {
    return false;
  }
  std::vector<uint8_t> payload = {
      static_cast<uint8_t>(flags & 0xFF),
      static_cast<uint8_t>((flags >> 8) & 0xFF),
      static_cast<uint8_t>((flags >> 16) & 0xFF),
      static_cast<uint8_t>((flags >> 24) & 0xFF),
  };
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
  return jvm_invoker_->InvokeVoidMethod("onVsync", "(JJ)V");
}

bool JniDelegate::AsyncWaitForVsync(intptr_t baton) {
  TRACE_EVENT1("flutter", "JniDelegate::AsyncWaitForVsync", "baton",
               std::to_string(baton).c_str());
  if (vsync_waiter_) {
    return vsync_waiter_->AsyncWaitForVsync(baton);
  }
  if (!jvm_invoker_) {
    return false;
  }
  std::vector<uint8_t> payload(sizeof(intptr_t));
  std::memcpy(payload.data(), &baton, sizeof(intptr_t));
  return jvm_invoker_->InvokeVoidMethod("asyncWaitForVsync", "(J)V", payload);
}

bool JniDelegate::SetViewportMetrics(const AndroidViewportMetrics& metrics) {
  TRACE_EVENT0("flutter", "JniDelegate::SetViewportMetrics");
  if (window_metrics_provider_) {
    return window_metrics_provider_->SendViewportMetrics(metrics);
  }
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("onViewportMetrics", "(IDDD)V");
}

bool JniDelegate::UpdateDisplayMetrics(const AndroidDisplayMetrics& metrics) {
  TRACE_EVENT0("flutter", "JniDelegate::UpdateDisplayMetrics(struct)");
  if (window_metrics_provider_) {
    return window_metrics_provider_->UpdateDisplayMetrics(metrics);
  }
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("onDisplayMetrics", "(JDDDF)V");
}

bool JniDelegate::UpdateDisplayMetrics(uint64_t display_id,
                                       double refresh_rate,
                                       double width,
                                       double height,
                                       double device_pixel_ratio) {
  TRACE_EVENT0("flutter", "JniDelegate::UpdateDisplayMetrics(params)");
  AndroidDisplayMetrics metrics;
  metrics.display_id = display_id;
  metrics.single_display = (display_id == 0);
  metrics.refresh_rate = refresh_rate;
  metrics.width = width;
  metrics.height = height;
  metrics.device_pixel_ratio = device_pixel_ratio;
  return UpdateDisplayMetrics(metrics);
}

std::optional<AndroidViewportMetrics> JniDelegate::GetViewportMetrics(
    int64_t view_id) const {
  TRACE_EVENT0("flutter", "JniDelegate::GetViewportMetrics");
  if (window_metrics_provider_) {
    return window_metrics_provider_->GetViewportMetrics(view_id);
  }
  return std::nullopt;
}

std::optional<AndroidDisplayMetrics> JniDelegate::GetDisplayMetrics(
    uint64_t display_id) const {
  TRACE_EVENT0("flutter", "JniDelegate::GetDisplayMetrics");
  if (window_metrics_provider_) {
    return window_metrics_provider_->GetDisplayMetrics(display_id);
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

bool JniDelegate::RequestDartDeferredLibrary(int64_t loading_unit_id) {
  TRACE_EVENT0("flutter", "JniDelegate::RequestDartDeferredLibrary");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeBooleanMethod("requestDartDeferredLibrary",
                                           "(I)Z");
}

bool JniDelegate::OnAssetManagerChanged() {
  TRACE_EVENT0("flutter", "JniDelegate::OnAssetManagerChanged");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("onAssetManagerChanged", "()V");
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

std::optional<DartCallbackInfo> JniDelegate::LookupCallbackInformation(
    int64_t handle) {
  TRACE_EVENT0("flutter", "JniDelegate::LookupCallbackInformation");
  if (callback_cache_) {
    return callback_cache_->GetCallbackInformation(handle);
  }

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

void JniDelegate::SetCallbackCache(
    std::shared_ptr<CallbackCacheProvider> provider) {
  TRACE_EVENT0("flutter", "JniDelegate::SetCallbackCache");
  callback_cache_ = std::move(provider);
}

std::shared_ptr<CallbackCacheProvider> JniDelegate::GetCallbackCache() const {
  return callback_cache_;
}

bool JniDelegate::DecodeImage(const uint8_t* data,
                              size_t size,
                              int64_t generator_handle) {
  TRACE_EVENT0("flutter", "JniDelegate::DecodeImage");
  if (image_decoder_) {
    return image_decoder_->DecodeImage(data, size, generator_handle);
  }
  if (!jvm_invoker_ || !data || size == 0) {
    return false;
  }
  std::vector<uint8_t> payload(data, data + size);
  return jvm_invoker_->InvokeBooleanMethod(
      "decodeImage", "(Ljava/nio/ByteBuffer;J)Landroid/graphics/Bitmap;",
      payload);
}

void JniDelegate::OnNativeImageHeader(int64_t generator_handle,
                                      int32_t width,
                                      int32_t height) {
  TRACE_EVENT0("flutter", "JniDelegate::OnNativeImageHeader");
  if (image_decoder_) {
    image_decoder_->OnImageHeader(generator_handle, width, height);
  }
}

std::optional<ImageHeaderInfo> JniDelegate::GetImageHeader(
    int64_t generator_handle) {
  TRACE_EVENT0("flutter", "JniDelegate::GetImageHeader");
  if (image_decoder_) {
    return image_decoder_->GetImageHeader(generator_handle);
  }
  return std::nullopt;
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

}  // namespace android
}  // namespace flutter
