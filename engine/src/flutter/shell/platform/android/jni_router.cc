// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/jni_router.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace flutter {
namespace android {

std::atomic<bool> JniRouter::embedder_enabled_{false};

JniRouter::JniRouter(std::shared_ptr<JniDelegate> embedder_delegate,
                     const std::shared_ptr<LegacyJniDelegate>& legacy_delegate)
    : embedder_delegate_(std::move(embedder_delegate)),
      legacy_delegate_(std::move(legacy_delegate)) {
  TRACE_EVENT0("flutter", "JniRouter::JniRouter");
}

JniRouter::~JniRouter() {
  TRACE_EVENT0("flutter", "JniRouter::~JniRouter");
}

bool JniRouter::IsEmbedderEnabled() {
  return embedder_enabled_.load();
}

void JniRouter::SetEmbedderEnabled(bool enabled) {
  embedder_enabled_.store(enabled);
}

JniRouter::RoutingPath JniRouter::GetActiveRoutingPath() const {
  return IsEmbedderEnabled() ? RoutingPath::kEmbedder : RoutingPath::kLegacy;
}

std::shared_ptr<JniDelegate> JniRouter::GetEmbedderDelegate() const {
  return embedder_delegate_;
}

std::shared_ptr<LegacyJniDelegate> JniRouter::GetLegacyDelegate() const {
  return legacy_delegate_;
}

bool JniRouter::RoutePlatformMessage(const std::string& channel,
                                     const std::vector<uint8_t>& message,
                                     int32_t response_id) {
  TRACE_EVENT1("flutter", "JniRouter::RoutePlatformMessage", "channel",
               channel.c_str());
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->HandlePlatformMessage(channel, message,
                                                       response_id);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->HandlePlatformMessage(channel, message,
                                                   response_id);
  }
  return false;
}

bool JniRouter::RoutePlatformMessageResponse(int32_t response_id,
                                             const std::vector<uint8_t>& data) {
  TRACE_EVENT0("flutter", "JniRouter::RoutePlatformMessageResponse");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->HandlePlatformMessageResponse(response_id,
                                                               data);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->HandlePlatformMessageResponse(response_id, data);
  }
  return false;
}

bool JniRouter::RouteSemanticsUpdate(const std::vector<uint8_t>& buffer,
                                     const std::vector<std::string>& strings) {
  TRACE_EVENT0("flutter", "JniRouter::RouteSemanticsUpdate(legacy)");
  return RouteSemanticsUpdate(buffer, strings, {});
}

bool JniRouter::RouteSemanticsUpdate(
    const std::vector<uint8_t>& buffer,
    const std::vector<std::string>& strings,
    const std::vector<std::vector<uint8_t>>& string_attribute_args) {
  TRACE_EVENT0("flutter", "JniRouter::RouteSemanticsUpdate");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->UpdateSemantics(buffer, strings,
                                                 string_attribute_args);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->UpdateSemantics(buffer, strings,
                                             string_attribute_args);
  }
  return false;
}

bool JniRouter::RouteCustomAccessibilityActions(
    const std::vector<uint8_t>& actions_buffer,
    const std::vector<std::string>& action_strings) {
  TRACE_EVENT0("flutter", "JniRouter::RouteCustomAccessibilityActions");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->UpdateCustomAccessibilityActions(
          actions_buffer, action_strings);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->UpdateCustomAccessibilityActions(actions_buffer,
                                                              action_strings);
  }
  return false;
}

bool JniRouter::RouteSemanticsUpdate(const FlutterSemanticsUpdate2& update) {
  TRACE_EVENT0("flutter", "JniRouter::RouteSemanticsUpdate(struct)");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->UpdateSemantics(update);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->UpdateSemantics(update);
  }
  return false;
}

bool JniRouter::RouteSemanticsEnabled(bool enabled) {
  TRACE_EVENT0("flutter", "JniRouter::RouteSemanticsEnabled");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->SetSemanticsEnabled(enabled);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->SetSemanticsEnabled(enabled);
  }
  return false;
}

bool JniRouter::RouteDispatchSemanticsAction(int32_t node_id,
                                             FlutterSemanticsAction action,
                                             const std::vector<uint8_t>& data,
                                             int64_t view_id) {
  TRACE_EVENT0("flutter", "JniRouter::RouteDispatchSemanticsAction");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->DispatchSemanticsAction(node_id, action, data,
                                                         view_id);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->DispatchSemanticsAction(node_id, action, data,
                                                     view_id);
  }
  return false;
}

bool JniRouter::RouteSetAccessibilityFeatures(int32_t flags) {
  TRACE_EVENT0("flutter", "JniRouter::RouteSetAccessibilityFeatures");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->SetAccessibilityFeatures(flags);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->SetAccessibilityFeatures(flags);
  }
  return false;
}

bool JniRouter::RouteApplicationLocale(const std::string& locale) {
  TRACE_EVENT1("flutter", "JniRouter::RouteApplicationLocale", "locale",
               locale.c_str());
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->SetApplicationLocale(locale);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->SetApplicationLocale(locale);
  }
  return false;
}

bool JniRouter::RouteFirstFrame() {
  TRACE_EVENT0("flutter", "JniRouter::RouteFirstFrame");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->OnFirstFrame();
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->OnFirstFrame();
  }
  return false;
}

bool JniRouter::RoutePreEngineRestart() {
  TRACE_EVENT0("flutter", "JniRouter::RoutePreEngineRestart");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->OnPreEngineRestart();
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->OnPreEngineRestart();
  }
  return false;
}

bool JniRouter::RouteVsync(int64_t frame_time_nanos,
                           int64_t frame_target_time_nanos) {
  TRACE_EVENT0("flutter", "JniRouter::RouteVsync");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->OnVsync(frame_time_nanos,
                                         frame_target_time_nanos);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->OnVsync(frame_time_nanos, frame_target_time_nanos);
  }
  return false;
}

bool JniRouter::RouteAsyncWaitForVsync(intptr_t baton) {
  TRACE_EVENT1("flutter", "JniRouter::RouteAsyncWaitForVsync", "baton",
               std::to_string(baton).c_str());
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->AsyncWaitForVsync(baton);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->AsyncWaitForVsync(baton);
  }
  return false;
}

bool JniRouter::RouteSetViewportMetrics(const AndroidViewportMetrics& metrics) {
  TRACE_EVENT0("flutter", "JniRouter::RouteSetViewportMetrics");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->SetViewportMetrics(metrics);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->SetViewportMetrics(metrics);
  }
  return false;
}

bool JniRouter::RouteUpdateDisplayMetrics(
    const AndroidDisplayMetrics& metrics) {
  TRACE_EVENT0("flutter", "JniRouter::RouteUpdateDisplayMetrics(struct)");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->UpdateDisplayMetrics(metrics);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->UpdateDisplayMetrics(metrics);
  }
  return false;
}

bool JniRouter::RouteUpdateDisplayMetrics(uint64_t display_id,
                                          double refresh_rate,
                                          double width,
                                          double height,
                                          double device_pixel_ratio) {
  TRACE_EVENT0("flutter", "JniRouter::RouteUpdateDisplayMetrics(params)");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->UpdateDisplayMetrics(
          display_id, refresh_rate, width, height, device_pixel_ratio);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->UpdateDisplayMetrics(
        display_id, refresh_rate, width, height, device_pixel_ratio);
  }
  return false;
}

bool JniRouter::RouteViewportMetrics(int64_t view_id,
                                     double width,
                                     double height,
                                     double pixel_ratio) {
  TRACE_EVENT0("flutter", "JniRouter::RouteViewportMetrics");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->DispatchViewportMetrics(view_id, width, height,
                                                         pixel_ratio);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->DispatchViewportMetrics(view_id, width, height,
                                                     pixel_ratio);
  }
  return false;
}

bool JniRouter::RouteRequestDartDeferredLibrary(int64_t loading_unit_id) {
  TRACE_EVENT0("flutter", "JniRouter::RouteRequestDartDeferredLibrary");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->RequestDartDeferredLibrary(loading_unit_id);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->RequestDartDeferredLibrary(loading_unit_id);
  }
  return false;
}

bool JniRouter::RouteAssetManagerChanged() {
  TRACE_EVENT0("flutter", "JniRouter::RouteAssetManagerChanged");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->OnAssetManagerChanged();
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->OnAssetManagerChanged();
  }
  return false;
}

std::optional<DartCallbackInfo> JniRouter::RouteLookupCallbackInformation(
    int64_t handle) {
  TRACE_EVENT0("flutter", "JniRouter::RouteLookupCallbackInformation");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->LookupCallbackInformation(handle);
    }
    return std::nullopt;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->LookupCallbackInformation(handle);
  }
  return std::nullopt;
}

bool JniRouter::RouteDecodeImage(const uint8_t* data,
                                 size_t size,
                                 int64_t generator_handle) {
  TRACE_EVENT0("flutter", "JniRouter::RouteDecodeImage");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->DecodeImage(data, size, generator_handle);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->DecodeImage(data, size, generator_handle);
  }
  return false;
}

void JniRouter::RouteNativeImageHeader(int64_t generator_handle,
                                       int32_t width,
                                       int32_t height) {
  TRACE_EVENT0("flutter", "JniRouter::RouteNativeImageHeader");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      embedder_delegate_->OnNativeImageHeader(generator_handle, width, height);
    }
    return;
  }
  if (legacy_delegate_) {
    legacy_delegate_->OnNativeImageHeader(generator_handle, width, height);
  }
}

std::optional<ImageHeaderInfo> JniRouter::RouteGetImageHeader(
    int64_t generator_handle) {
  TRACE_EVENT0("flutter", "JniRouter::RouteGetImageHeader");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->GetImageHeader(generator_handle);
    }
    return std::nullopt;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->GetImageHeader(generator_handle);
  }
  return std::nullopt;
}

int64_t JniRouter::RouteCreatePlatformView(
    const PlatformViewCreationParams& params,
    PlatformViewCompositionType composition_type) {
  TRACE_EVENT1("flutter", "JniRouter::RouteCreatePlatformView", "view_id",
               std::to_string(params.view_id).c_str());
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->CreatePlatformView(params, composition_type);
    }
    return -1;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->CreatePlatformView(params, composition_type);
  }
  return -1;
}

bool JniRouter::RouteDisposePlatformView(int64_t view_id) {
  TRACE_EVENT1("flutter", "JniRouter::RouteDisposePlatformView", "view_id",
               std::to_string(view_id).c_str());
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->DisposePlatformView(view_id);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->DisposePlatformView(view_id);
  }
  return false;
}

bool JniRouter::RouteResizePlatformView(
    const PlatformViewResizeRequest& request) {
  TRACE_EVENT1("flutter", "JniRouter::RouteResizePlatformView", "view_id",
               std::to_string(request.view_id).c_str());
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->ResizePlatformView(request);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->ResizePlatformView(request);
  }
  return false;
}

bool JniRouter::RouteOffsetPlatformView(int64_t view_id,
                                        double top,
                                        double left) {
  TRACE_EVENT1("flutter", "JniRouter::RouteOffsetPlatformView", "view_id",
               std::to_string(view_id).c_str());
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->OffsetPlatformView(view_id, top, left);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->OffsetPlatformView(view_id, top, left);
  }
  return false;
}

bool JniRouter::RouteSetPlatformViewDirection(int64_t view_id,
                                              int32_t direction) {
  TRACE_EVENT1("flutter", "JniRouter::RouteSetPlatformViewDirection", "view_id",
               std::to_string(view_id).c_str());
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->SetPlatformViewDirection(view_id, direction);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->SetPlatformViewDirection(view_id, direction);
  }
  return false;
}

bool JniRouter::RouteClearPlatformViewFocus(int64_t view_id) {
  TRACE_EVENT1("flutter", "JniRouter::RouteClearPlatformViewFocus", "view_id",
               std::to_string(view_id).c_str());
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->ClearPlatformViewFocus(view_id);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->ClearPlatformViewFocus(view_id);
  }
  return false;
}

bool JniRouter::RouteDispatchPlatformViewTouch(const PlatformViewTouch& touch) {
  TRACE_EVENT1("flutter", "JniRouter::RouteDispatchPlatformViewTouch",
               "view_id", std::to_string(touch.view_id).c_str());
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->DispatchPlatformViewTouch(touch);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->DispatchPlatformViewTouch(touch);
  }
  return false;
}

bool JniRouter::RouteOnDisplayPlatformView(
    const PlatformViewGeometry& geometry) {
  TRACE_EVENT1("flutter", "JniRouter::RouteOnDisplayPlatformView", "view_id",
               std::to_string(geometry.view_id).c_str());
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->OnDisplayPlatformView(geometry);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->OnDisplayPlatformView(geometry);
  }
  return false;
}

bool JniRouter::RouteOnDisplayPlatformView(
    const FlutterPlatformView& platform_view,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    int32_t view_width,
    int32_t view_height) {
  TRACE_EVENT1("flutter", "JniRouter::RouteOnDisplayPlatformView(struct)",
               "view_id", std::to_string(platform_view.identifier).c_str());
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->OnDisplayPlatformView(
          platform_view, x, y, width, height, view_width, view_height);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->OnDisplayPlatformView(
        platform_view, x, y, width, height, view_width, view_height);
  }
  return false;
}

bool JniRouter::RouteHidePlatformView(int64_t view_id) {
  TRACE_EVENT1("flutter", "JniRouter::RouteHidePlatformView", "view_id",
               std::to_string(view_id).c_str());
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->HidePlatformView(view_id);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->HidePlatformView(view_id);
  }
  return false;
}

bool JniRouter::RouteSynchronizeToNativeViewHierarchy(bool synchronize) {
  TRACE_EVENT0("flutter", "JniRouter::RouteSynchronizeToNativeViewHierarchy");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->SynchronizeToNativeViewHierarchy(synchronize);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->SynchronizeToNativeViewHierarchy(synchronize);
  }
  return false;
}

bool JniRouter::RouteBeginFrame() {
  TRACE_EVENT0("flutter", "JniRouter::RouteBeginFrame");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->OnBeginFrame();
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->OnBeginFrame();
  }
  return false;
}

bool JniRouter::RouteEndFrame() {
  TRACE_EVENT0("flutter", "JniRouter::RouteEndFrame");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->OnEndFrame();
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->OnEndFrame();
  }
  return false;
}

std::optional<int32_t> JniRouter::RouteCreateOverlaySurface() {
  TRACE_EVENT0("flutter", "JniRouter::RouteCreateOverlaySurface");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->CreateOverlaySurface();
    }
    return std::nullopt;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->CreateOverlaySurface();
  }
  return std::nullopt;
}

bool JniRouter::RouteDestroyOverlaySurfaces() {
  TRACE_EVENT0("flutter", "JniRouter::RouteDestroyOverlaySurfaces");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->DestroyOverlaySurfaces();
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->DestroyOverlaySurfaces();
  }
  return false;
}

bool JniRouter::RouteOnDisplayOverlaySurface(
    const PlatformViewOverlay& overlay) {
  TRACE_EVENT1("flutter", "JniRouter::RouteOnDisplayOverlaySurface",
               "surface_id", std::to_string(overlay.surface_id).c_str());
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->OnDisplayOverlaySurface(overlay);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->OnDisplayOverlaySurface(overlay);
  }
  return false;
}

bool JniRouter::RouteShowOverlaySurface(int32_t surface_id) {
  TRACE_EVENT1("flutter", "JniRouter::RouteShowOverlaySurface", "surface_id",
               std::to_string(surface_id).c_str());
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->ShowOverlaySurface(surface_id);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->ShowOverlaySurface(surface_id);
  }
  return false;
}

bool JniRouter::RouteHideOverlaySurface(int32_t surface_id) {
  TRACE_EVENT1("flutter", "JniRouter::RouteHideOverlaySurface", "surface_id",
               std::to_string(surface_id).c_str());
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->HideOverlaySurface(surface_id);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->HideOverlaySurface(surface_id);
  }
  return false;
}

bool JniRouter::RouteCreatePlatformViewTransaction() {
  TRACE_EVENT0("flutter", "JniRouter::RouteCreatePlatformViewTransaction");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->CreatePlatformViewTransaction();
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->CreatePlatformViewTransaction();
  }
  return false;
}

bool JniRouter::RouteSwapPlatformViewTransactions() {
  TRACE_EVENT0("flutter", "JniRouter::RouteSwapPlatformViewTransactions");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->SwapPlatformViewTransactions();
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->SwapPlatformViewTransactions();
  }
  return false;
}

bool JniRouter::RouteApplyPlatformViewTransactions() {
  TRACE_EVENT0("flutter", "JniRouter::RouteApplyPlatformViewTransactions");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->ApplyPlatformViewTransactions();
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->ApplyPlatformViewTransactions();
  }
  return false;
}

bool JniRouter::RouteIsHcppEnabled() const {
  TRACE_EVENT0("flutter", "JniRouter::RouteIsHcppEnabled");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->IsHcppEnabled();
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->IsHcppEnabled();
  }
  return false;
}

bool JniRouter::RoutePlatformViewMutators(
    int64_t view_id,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    const AndroidMutatorsStack& mutators_stack) {
  TRACE_EVENT0("flutter", "JniRouter::RoutePlatformViewMutators");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->PushPlatformViewMutators(
          view_id, x, y, width, height, mutators_stack);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->PushPlatformViewMutators(view_id, x, y, width,
                                                      height, mutators_stack);
  }
  return false;
}

bool JniRouter::RoutePlatformViewMutators(
    const FlutterPlatformView& platform_view,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height) {
  TRACE_EVENT0("flutter", "JniRouter::RoutePlatformViewMutators(view)");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->PushPlatformViewMutators(platform_view, x, y,
                                                          width, height);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->PushPlatformViewMutators(platform_view, x, y,
                                                      width, height);
  }
  return false;
}

bool JniRouter::RouteInitVM(const AndroidVMArgs& args) {
  TRACE_EVENT0("flutter", "JniRouter::RouteInitVM");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->InitVM(args);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->InitVM(args);
  }
  return false;
}

bool JniRouter::RoutePrefetchDefaultFontManager() {
  TRACE_EVENT0("flutter", "JniRouter::RoutePrefetchDefaultFontManager");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->PrefetchDefaultFontManager();
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->PrefetchDefaultFontManager();
  }
  return false;
}

bool JniRouter::RouteSetVmServiceUri(const std::string& uri) {
  TRACE_EVENT1("flutter", "JniRouter::RouteSetVmServiceUri", "uri",
               uri.c_str());
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->SetVmServiceUri(uri);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->SetVmServiceUri(uri);
  }
  return false;
}

bool JniRouter::RouteRegisterHardwareBufferTexture(int64_t texture_id) {
  TRACE_EVENT1("flutter", "JniRouter::RouteRegisterHardwareBufferTexture",
               "texture_id", std::to_string(texture_id).c_str());
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->RegisterHardwareBufferTexture(texture_id);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->RegisterHardwareBufferTexture(texture_id);
  }
  return false;
}

bool JniRouter::RouteUnregisterHardwareBufferTexture(int64_t texture_id) {
  TRACE_EVENT1("flutter", "JniRouter::RouteUnregisterHardwareBufferTexture",
               "texture_id", std::to_string(texture_id).c_str());
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->UnregisterHardwareBufferTexture(texture_id);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->UnregisterHardwareBufferTexture(texture_id);
  }
  return false;
}

bool JniRouter::RouteSetHardwareBufferFrame(
    int64_t texture_id,
    const std::shared_ptr<AndroidHardwareBuffer>& buffer) {
  TRACE_EVENT1("flutter", "JniRouter::RouteSetHardwareBufferFrame(object)",
               "texture_id", std::to_string(texture_id).c_str());
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->SetHardwareBufferFrame(texture_id,
                                                        std::move(buffer));
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->SetHardwareBufferFrame(texture_id,
                                                    std::move(buffer));
  }
  return false;
}

bool JniRouter::RouteSetHardwareBufferFrame(
    int64_t texture_id,
    const FlutterHardwareBufferExternalTexture& texture) {
  TRACE_EVENT1("flutter", "JniRouter::RouteSetHardwareBufferFrame(struct)",
               "texture_id", std::to_string(texture_id).c_str());
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->SetHardwareBufferFrame(texture_id, texture);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->SetHardwareBufferFrame(texture_id, texture);
  }
  return false;
}

bool JniRouter::RouteGetHardwareBufferTextureFrame(
    int64_t texture_id,
    size_t width,
    size_t height,
    FlutterHardwareBufferExternalTexture* texture_out) {
  TRACE_EVENT1("flutter", "JniRouter::RouteGetHardwareBufferTextureFrame",
               "texture_id", std::to_string(texture_id).c_str());
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->GetHardwareBufferTextureFrame(
          texture_id, width, height, texture_out);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->GetHardwareBufferTextureFrame(texture_id, width,
                                                           height, texture_out);
  }
  return false;
}

bool JniRouter::RouteOnHardwareBufferFrameAvailable(int64_t texture_id) {
  TRACE_EVENT1("flutter", "JniRouter::RouteOnHardwareBufferFrameAvailable",
               "texture_id", std::to_string(texture_id).c_str());
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->OnHardwareBufferFrameAvailable(texture_id);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->OnHardwareBufferFrameAvailable(texture_id);
  }
  return false;
}

}  // namespace android
}  // namespace flutter
