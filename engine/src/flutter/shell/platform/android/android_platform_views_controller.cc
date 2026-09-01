// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_platform_views_controller.h"

#include <algorithm>
#include <cstring>
#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace flutter {
namespace android {

// =============================================================================
// DefaultPlatformViewsProvider
// =============================================================================

DefaultPlatformViewsProvider::DefaultPlatformViewsProvider(
    std::shared_ptr<JvmInvoker> jvm_invoker)
    : jvm_invoker_(std::move(jvm_invoker)) {
  TRACE_EVENT0("flutter",
               "DefaultPlatformViewsProvider::DefaultPlatformViewsProvider");
}

DefaultPlatformViewsProvider::~DefaultPlatformViewsProvider() {
  TRACE_EVENT0("flutter",
               "DefaultPlatformViewsProvider::~DefaultPlatformViewsProvider");
}

int64_t DefaultPlatformViewsProvider::CreatePlatformView(
    const PlatformViewCreationParams& params,
    PlatformViewCompositionType composition_type) {
  TRACE_EVENT1("flutter", "DefaultPlatformViewsProvider::CreatePlatformView",
               "view_id", std::to_string(params.view_id).c_str());
  if (!jvm_invoker_) {
    return -1;
  }

  std::vector<uint8_t> payload = params.params;

  switch (composition_type) {
    case PlatformViewCompositionType::kTextureLayer: {
      return jvm_invoker_->InvokeIntMethod(
          "createForTextureLayer",
          "(Ljava/lang/String;IDDILjava/nio/ByteBuffer;)J", payload);
    }
    case PlatformViewCompositionType::kHybridComposition: {
      bool success = jvm_invoker_->InvokeVoidMethod(
          "createForPlatformViewLayer",
          "(Ljava/lang/String;IDDILjava/nio/ByteBuffer;)V", payload);
      return success ? 0 : -1;
    }
    case PlatformViewCompositionType::kHybridCompositionPlusPlus: {
      bool success = jvm_invoker_->InvokeVoidMethod(
          "createPlatformViewHcpp",
          "(Ljava/lang/String;IDDILjava/nio/ByteBuffer;)V", payload);
      return success ? 0 : -1;
    }
  }
  return -1;
}

bool DefaultPlatformViewsProvider::DisposePlatformView(int64_t view_id) {
  TRACE_EVENT1("flutter", "DefaultPlatformViewsProvider::DisposePlatformView",
               "view_id", std::to_string(view_id).c_str());
  if (!jvm_invoker_) {
    return false;
  }
  std::vector<uint8_t> payload(sizeof(int64_t));
  std::memcpy(payload.data(), &view_id, sizeof(int64_t));
  return jvm_invoker_->InvokeVoidMethod("disposePlatformView", "(I)V", payload);
}

bool DefaultPlatformViewsProvider::ResizePlatformView(
    const PlatformViewResizeRequest& request) {
  TRACE_EVENT1("flutter", "DefaultPlatformViewsProvider::ResizePlatformView",
               "view_id", std::to_string(request.view_id).c_str());
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("resizePlatformView", "(IDD)V");
}

bool DefaultPlatformViewsProvider::OffsetPlatformView(int64_t view_id,
                                                      double top,
                                                      double left) {
  TRACE_EVENT1("flutter", "DefaultPlatformViewsProvider::OffsetPlatformView",
               "view_id", std::to_string(view_id).c_str());
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("offsetPlatformView", "(IDD)V");
}

bool DefaultPlatformViewsProvider::SetDirection(int64_t view_id,
                                                int32_t direction) {
  TRACE_EVENT1("flutter", "DefaultPlatformViewsProvider::SetDirection",
               "view_id", std::to_string(view_id).c_str());
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("setPlatformViewDirection", "(II)V");
}

bool DefaultPlatformViewsProvider::ClearFocus(int64_t view_id) {
  TRACE_EVENT1("flutter", "DefaultPlatformViewsProvider::ClearFocus", "view_id",
               std::to_string(view_id).c_str());
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("clearPlatformViewFocus", "(I)V");
}

bool DefaultPlatformViewsProvider::DispatchTouchEvent(
    const PlatformViewTouch& touch) {
  TRACE_EVENT1("flutter", "DefaultPlatformViewsProvider::DispatchTouchEvent",
               "view_id", std::to_string(touch.view_id).c_str());
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod(
      "onTouch",
      "(Lio/flutter/embedding/engine/systemchannels/PlatformViewTouch;)V");
}

bool DefaultPlatformViewsProvider::OnDisplayPlatformView(
    const PlatformViewGeometry& geometry) {
  TRACE_EVENT1("flutter", "DefaultPlatformViewsProvider::OnDisplayPlatformView",
               "view_id", std::to_string(geometry.view_id).c_str());
  if (!jvm_invoker_) {
    return false;
  }
  std::vector<uint8_t> payload = geometry.mutators_stack.Serialize();
  return jvm_invoker_->InvokeVoidMethod(
      "onDisplayPlatformView", "(IIIIIIILjava/nio/ByteBuffer;)V", payload);
}

bool DefaultPlatformViewsProvider::HidePlatformView(int64_t view_id) {
  TRACE_EVENT1("flutter", "DefaultPlatformViewsProvider::HidePlatformView",
               "view_id", std::to_string(view_id).c_str());
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("hidePlatformView", "(I)V");
}

bool DefaultPlatformViewsProvider::SynchronizeToNativeViewHierarchy(
    bool synchronize) {
  TRACE_EVENT0("flutter",
               "DefaultPlatformViewsProvider::"
               "SynchronizeToNativeViewHierarchy");
  if (!jvm_invoker_) {
    return false;
  }
  std::vector<uint8_t> payload = {static_cast<uint8_t>(synchronize ? 1 : 0)};
  return jvm_invoker_->InvokeVoidMethod("synchronizeToNativeViewHierarchy",
                                        "(Z)V", payload);
}

bool DefaultPlatformViewsProvider::OnBeginFrame() {
  TRACE_EVENT0("flutter", "DefaultPlatformViewsProvider::OnBeginFrame");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("onBeginFrame", "()V");
}

bool DefaultPlatformViewsProvider::OnEndFrame() {
  TRACE_EVENT0("flutter", "DefaultPlatformViewsProvider::OnEndFrame");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("onEndFrame", "()V");
}

std::optional<int32_t> DefaultPlatformViewsProvider::CreateOverlaySurface() {
  TRACE_EVENT0("flutter", "DefaultPlatformViewsProvider::CreateOverlaySurface");
  if (!jvm_invoker_) {
    return std::nullopt;
  }
  int64_t id = jvm_invoker_->InvokeIntMethod(
      "createOverlaySurface",
      "()Lio/flutter/embedding/engine/FlutterOverlaySurface;");
  if (id < 0) {
    return std::nullopt;
  }
  return static_cast<int32_t>(id);
}

bool DefaultPlatformViewsProvider::DestroyOverlaySurfaces() {
  TRACE_EVENT0("flutter",
               "DefaultPlatformViewsProvider::DestroyOverlaySurfaces");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("destroyOverlaySurfaces", "()V");
}

bool DefaultPlatformViewsProvider::OnDisplayOverlaySurface(
    const PlatformViewOverlay& overlay) {
  TRACE_EVENT1("flutter",
               "DefaultPlatformViewsProvider::OnDisplayOverlaySurface",
               "surface_id", std::to_string(overlay.surface_id).c_str());
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("onDisplayOverlaySurface", "(IIIII)V");
}

bool DefaultPlatformViewsProvider::ShowOverlaySurface(int32_t surface_id) {
  TRACE_EVENT1("flutter", "DefaultPlatformViewsProvider::ShowOverlaySurface",
               "surface_id", std::to_string(surface_id).c_str());
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("showOverlaySurface", "(I)V");
}

bool DefaultPlatformViewsProvider::HideOverlaySurface(int32_t surface_id) {
  TRACE_EVENT1("flutter", "DefaultPlatformViewsProvider::HideOverlaySurface",
               "surface_id", std::to_string(surface_id).c_str());
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("hideOverlaySurface", "(I)V");
}

bool DefaultPlatformViewsProvider::CreateTransaction() {
  TRACE_EVENT0("flutter", "DefaultPlatformViewsProvider::CreateTransaction");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod(
      "createTransaction", "()Landroid/view/SurfaceControl$Transaction;");
}

bool DefaultPlatformViewsProvider::SwapTransactions() {
  TRACE_EVENT0("flutter", "DefaultPlatformViewsProvider::SwapTransactions");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("swapTransactions", "()V");
}

bool DefaultPlatformViewsProvider::ApplyTransactions() {
  TRACE_EVENT0("flutter", "DefaultPlatformViewsProvider::ApplyTransactions");
  if (!jvm_invoker_) {
    return false;
  }
  return jvm_invoker_->InvokeVoidMethod("applyTransactions", "()V");
}

bool DefaultPlatformViewsProvider::IsHcppEnabled() const {
  TRACE_EVENT0("flutter", "DefaultPlatformViewsProvider::IsHcppEnabled");
  return hcpp_enabled_;
}

void DefaultPlatformViewsProvider::SetHcppEnabled(bool enabled) {
  TRACE_EVENT0("flutter", "DefaultPlatformViewsProvider::SetHcppEnabled");
  hcpp_enabled_ = enabled;
}

// =============================================================================
// InMemoryPlatformViewsProvider
// =============================================================================

InMemoryPlatformViewsProvider::InMemoryPlatformViewsProvider() {
  TRACE_EVENT0("flutter",
               "InMemoryPlatformViewsProvider::InMemoryPlatformViewsProvider");
}

InMemoryPlatformViewsProvider::~InMemoryPlatformViewsProvider() {
  TRACE_EVENT0("flutter",
               "InMemoryPlatformViewsProvider::~InMemoryPlatformViewsProvider");
}

int64_t InMemoryPlatformViewsProvider::CreatePlatformView(
    const PlatformViewCreationParams& params,
    PlatformViewCompositionType composition_type) {
  TRACE_EVENT1("flutter", "InMemoryPlatformViewsProvider::CreatePlatformView",
               "view_id", std::to_string(params.view_id).c_str());
  std::lock_guard<std::mutex> lock(mutex_);
  created_views_[params.view_id] = params;
  composition_types_[params.view_id] = composition_type;
  disposed_views_.erase(params.view_id);
  hidden_views_.erase(params.view_id);

  if (composition_type == PlatformViewCompositionType::kTextureLayer) {
    return next_texture_id_++;
  }
  return 0;
}

bool InMemoryPlatformViewsProvider::DisposePlatformView(int64_t view_id) {
  TRACE_EVENT1("flutter", "InMemoryPlatformViewsProvider::DisposePlatformView",
               "view_id", std::to_string(view_id).c_str());
  std::lock_guard<std::mutex> lock(mutex_);
  created_views_.erase(view_id);
  composition_types_.erase(view_id);
  offsets_.erase(view_id);
  directions_.erase(view_id);
  geometries_.erase(view_id);
  hidden_views_.erase(view_id);
  disposed_views_.insert(view_id);
  return true;
}

bool InMemoryPlatformViewsProvider::ResizePlatformView(
    const PlatformViewResizeRequest& request) {
  TRACE_EVENT1("flutter", "InMemoryPlatformViewsProvider::ResizePlatformView",
               "view_id", std::to_string(request.view_id).c_str());
  std::lock_guard<std::mutex> lock(mutex_);
  last_resize_request_ = request;
  return true;
}

bool InMemoryPlatformViewsProvider::OffsetPlatformView(int64_t view_id,
                                                       double top,
                                                       double left) {
  TRACE_EVENT1("flutter", "InMemoryPlatformViewsProvider::OffsetPlatformView",
               "view_id", std::to_string(view_id).c_str());
  std::lock_guard<std::mutex> lock(mutex_);
  offsets_[view_id] = {top, left};
  return true;
}

bool InMemoryPlatformViewsProvider::SetDirection(int64_t view_id,
                                                 int32_t direction) {
  TRACE_EVENT1("flutter", "InMemoryPlatformViewsProvider::SetDirection",
               "view_id", std::to_string(view_id).c_str());
  std::lock_guard<std::mutex> lock(mutex_);
  directions_[view_id] = direction;
  return true;
}

bool InMemoryPlatformViewsProvider::ClearFocus(int64_t view_id) {
  TRACE_EVENT1("flutter", "InMemoryPlatformViewsProvider::ClearFocus",
               "view_id", std::to_string(view_id).c_str());
  std::lock_guard<std::mutex> lock(mutex_);
  clear_focus_counts_[view_id]++;
  return true;
}

bool InMemoryPlatformViewsProvider::DispatchTouchEvent(
    const PlatformViewTouch& touch) {
  TRACE_EVENT1("flutter", "InMemoryPlatformViewsProvider::DispatchTouchEvent",
               "view_id", std::to_string(touch.view_id).c_str());
  std::lock_guard<std::mutex> lock(mutex_);
  dispatched_touches_.push_back(touch);
  return true;
}

bool InMemoryPlatformViewsProvider::OnDisplayPlatformView(
    const PlatformViewGeometry& geometry) {
  TRACE_EVENT1("flutter",
               "InMemoryPlatformViewsProvider::OnDisplayPlatformView",
               "view_id", std::to_string(geometry.view_id).c_str());
  std::lock_guard<std::mutex> lock(mutex_);
  geometries_[geometry.view_id] = geometry;
  hidden_views_.erase(geometry.view_id);
  return true;
}

bool InMemoryPlatformViewsProvider::HidePlatformView(int64_t view_id) {
  TRACE_EVENT1("flutter", "InMemoryPlatformViewsProvider::HidePlatformView",
               "view_id", std::to_string(view_id).c_str());
  std::lock_guard<std::mutex> lock(mutex_);
  hidden_views_.insert(view_id);
  return true;
}

bool InMemoryPlatformViewsProvider::SynchronizeToNativeViewHierarchy(
    bool synchronize) {
  TRACE_EVENT0("flutter",
               "InMemoryPlatformViewsProvider::"
               "SynchronizeToNativeViewHierarchy");
  std::lock_guard<std::mutex> lock(mutex_);
  synchronize_to_native_view_hierarchy_ = synchronize;
  return true;
}

bool InMemoryPlatformViewsProvider::OnBeginFrame() {
  TRACE_EVENT0("flutter", "InMemoryPlatformViewsProvider::OnBeginFrame");
  std::lock_guard<std::mutex> lock(mutex_);
  in_frame_ = true;
  return true;
}

bool InMemoryPlatformViewsProvider::OnEndFrame() {
  TRACE_EVENT0("flutter", "InMemoryPlatformViewsProvider::OnEndFrame");
  std::lock_guard<std::mutex> lock(mutex_);
  in_frame_ = false;
  return true;
}

std::optional<int32_t> InMemoryPlatformViewsProvider::CreateOverlaySurface() {
  TRACE_EVENT0("flutter",
               "InMemoryPlatformViewsProvider::CreateOverlaySurface");
  std::lock_guard<std::mutex> lock(mutex_);
  int32_t id = next_overlay_id_++;
  overlay_surfaces_.insert(id);
  visible_overlays_.insert(id);
  return id;
}

bool InMemoryPlatformViewsProvider::DestroyOverlaySurfaces() {
  TRACE_EVENT0("flutter",
               "InMemoryPlatformViewsProvider::DestroyOverlaySurfaces");
  std::lock_guard<std::mutex> lock(mutex_);
  overlay_surfaces_.clear();
  displayed_overlays_.clear();
  visible_overlays_.clear();
  return true;
}

bool InMemoryPlatformViewsProvider::OnDisplayOverlaySurface(
    const PlatformViewOverlay& overlay) {
  TRACE_EVENT1("flutter",
               "InMemoryPlatformViewsProvider::OnDisplayOverlaySurface",
               "surface_id", std::to_string(overlay.surface_id).c_str());
  std::lock_guard<std::mutex> lock(mutex_);
  displayed_overlays_[overlay.surface_id] = overlay;
  return true;
}

bool InMemoryPlatformViewsProvider::ShowOverlaySurface(int32_t surface_id) {
  TRACE_EVENT1("flutter", "InMemoryPlatformViewsProvider::ShowOverlaySurface",
               "surface_id", std::to_string(surface_id).c_str());
  std::lock_guard<std::mutex> lock(mutex_);
  visible_overlays_.insert(surface_id);
  return true;
}

bool InMemoryPlatformViewsProvider::HideOverlaySurface(int32_t surface_id) {
  TRACE_EVENT1("flutter", "InMemoryPlatformViewsProvider::HideOverlaySurface",
               "surface_id", std::to_string(surface_id).c_str());
  std::lock_guard<std::mutex> lock(mutex_);
  visible_overlays_.erase(surface_id);
  return true;
}

bool InMemoryPlatformViewsProvider::CreateTransaction() {
  TRACE_EVENT0("flutter", "InMemoryPlatformViewsProvider::CreateTransaction");
  std::lock_guard<std::mutex> lock(mutex_);
  transaction_count_++;
  return true;
}

bool InMemoryPlatformViewsProvider::SwapTransactions() {
  TRACE_EVENT0("flutter", "InMemoryPlatformViewsProvider::SwapTransactions");
  std::lock_guard<std::mutex> lock(mutex_);
  transaction_count_++;
  return true;
}

bool InMemoryPlatformViewsProvider::ApplyTransactions() {
  TRACE_EVENT0("flutter", "InMemoryPlatformViewsProvider::ApplyTransactions");
  std::lock_guard<std::mutex> lock(mutex_);
  transaction_count_++;
  return true;
}

bool InMemoryPlatformViewsProvider::IsHcppEnabled() const {
  TRACE_EVENT0("flutter", "InMemoryPlatformViewsProvider::IsHcppEnabled");
  std::lock_guard<std::mutex> lock(mutex_);
  return hcpp_enabled_;
}

void InMemoryPlatformViewsProvider::SetHcppEnabled(bool enabled) {
  TRACE_EVENT0("flutter", "InMemoryPlatformViewsProvider::SetHcppEnabled");
  std::lock_guard<std::mutex> lock(mutex_);
  hcpp_enabled_ = enabled;
}

void InMemoryPlatformViewsProvider::SetNextTextureId(int64_t texture_id) {
  TRACE_EVENT0("flutter", "InMemoryPlatformViewsProvider::SetNextTextureId");
  std::lock_guard<std::mutex> lock(mutex_);
  next_texture_id_ = texture_id;
}

void InMemoryPlatformViewsProvider::Clear() {
  TRACE_EVENT0("flutter", "InMemoryPlatformViewsProvider::Clear");
  std::lock_guard<std::mutex> lock(mutex_);
  created_views_.clear();
  composition_types_.clear();
  disposed_views_.clear();
  last_resize_request_.reset();
  offsets_.clear();
  directions_.clear();
  clear_focus_counts_.clear();
  dispatched_touches_.clear();
  geometries_.clear();
  hidden_views_.clear();
  overlay_surfaces_.clear();
  displayed_overlays_.clear();
  visible_overlays_.clear();
  transaction_count_ = 0;
  in_frame_ = false;
}

size_t InMemoryPlatformViewsProvider::GetCreatedViewsCount() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return created_views_.size();
}

bool InMemoryPlatformViewsProvider::IsViewCreated(int64_t view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  return created_views_.find(view_id) != created_views_.end();
}

bool InMemoryPlatformViewsProvider::IsViewDisposed(int64_t view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  return disposed_views_.find(view_id) != disposed_views_.end();
}

std::optional<PlatformViewCreationParams>
InMemoryPlatformViewsProvider::GetCreationParams(int64_t view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = created_views_.find(view_id);
  if (it != created_views_.end()) {
    return it->second;
  }
  return std::nullopt;
}

std::optional<PlatformViewCompositionType>
InMemoryPlatformViewsProvider::GetCompositionType(int64_t view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = composition_types_.find(view_id);
  if (it != composition_types_.end()) {
    return it->second;
  }
  return std::nullopt;
}

std::optional<PlatformViewResizeRequest>
InMemoryPlatformViewsProvider::GetLastResizeRequest() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return last_resize_request_;
}

std::optional<std::pair<double, double>>
InMemoryPlatformViewsProvider::GetOffsets(int64_t view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = offsets_.find(view_id);
  if (it != offsets_.end()) {
    return it->second;
  }
  return std::nullopt;
}

std::optional<int32_t> InMemoryPlatformViewsProvider::GetDirection(
    int64_t view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = directions_.find(view_id);
  if (it != directions_.end()) {
    return it->second;
  }
  return std::nullopt;
}

size_t InMemoryPlatformViewsProvider::GetFocusClearedCount(
    int64_t view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = clear_focus_counts_.find(view_id);
  if (it != clear_focus_counts_.end()) {
    return it->second;
  }
  return 0;
}

const std::vector<PlatformViewTouch>&
InMemoryPlatformViewsProvider::GetDispatchedTouches() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return dispatched_touches_;
}

std::optional<PlatformViewGeometry>
InMemoryPlatformViewsProvider::GetLastGeometry(int64_t view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = geometries_.find(view_id);
  if (it != geometries_.end()) {
    return it->second;
  }
  return std::nullopt;
}

bool InMemoryPlatformViewsProvider::IsViewHidden(int64_t view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  return hidden_views_.find(view_id) != hidden_views_.end();
}

bool InMemoryPlatformViewsProvider::GetSynchronizeToNativeViewHierarchy()
    const {
  std::lock_guard<std::mutex> lock(mutex_);
  return synchronize_to_native_view_hierarchy_;
}

bool InMemoryPlatformViewsProvider::IsInFrame() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return in_frame_;
}

size_t InMemoryPlatformViewsProvider::GetOverlaySurfacesCount() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return overlay_surfaces_.size();
}

const std::map<int32_t, PlatformViewOverlay>&
InMemoryPlatformViewsProvider::GetDisplayedOverlays() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return displayed_overlays_;
}

bool InMemoryPlatformViewsProvider::IsOverlayVisible(int32_t surface_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  return visible_overlays_.find(surface_id) != visible_overlays_.end();
}

size_t InMemoryPlatformViewsProvider::GetTransactionCount() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return transaction_count_;
}

// =============================================================================
// AndroidPlatformViewsController
// =============================================================================

AndroidPlatformViewsController::AndroidPlatformViewsController(
    std::shared_ptr<PlatformViewsProvider> provider)
    : provider_(provider ? std::move(provider)
                         : std::make_shared<DefaultPlatformViewsProvider>()) {
  TRACE_EVENT0(
      "flutter",
      "AndroidPlatformViewsController::AndroidPlatformViewsController");
}

AndroidPlatformViewsController::~AndroidPlatformViewsController() {
  TRACE_EVENT0(
      "flutter",
      "AndroidPlatformViewsController::~AndroidPlatformViewsController");
}

int64_t AndroidPlatformViewsController::CreatePlatformView(
    const PlatformViewCreationParams& params,
    PlatformViewCompositionType composition_type) {
  TRACE_EVENT1("flutter", "AndroidPlatformViewsController::CreatePlatformView",
               "view_id", std::to_string(params.view_id).c_str());
  if (!provider_) {
    return -1;
  }
  int64_t result = provider_->CreatePlatformView(params, composition_type);
  if (result >= 0) {
    std::lock_guard<std::mutex> lock(mutex_);
    active_composition_types_[params.view_id] = composition_type;
  }
  return result;
}

bool AndroidPlatformViewsController::DisposePlatformView(int64_t view_id) {
  TRACE_EVENT1("flutter", "AndroidPlatformViewsController::DisposePlatformView",
               "view_id", std::to_string(view_id).c_str());
  if (!provider_) {
    return false;
  }
  bool result = provider_->DisposePlatformView(view_id);
  if (result) {
    std::lock_guard<std::mutex> lock(mutex_);
    active_geometries_.erase(view_id);
    active_composition_types_.erase(view_id);
  }
  return result;
}

bool AndroidPlatformViewsController::ResizePlatformView(int64_t view_id,
                                                        double width,
                                                        double height) {
  TRACE_EVENT1("flutter", "AndroidPlatformViewsController::ResizePlatformView",
               "view_id", std::to_string(view_id).c_str());
  if (!provider_) {
    return false;
  }
  PlatformViewResizeRequest req;
  req.view_id = view_id;
  req.width = width;
  req.height = height;
  return provider_->ResizePlatformView(req);
}

bool AndroidPlatformViewsController::OffsetPlatformView(int64_t view_id,
                                                        double top,
                                                        double left) {
  TRACE_EVENT1("flutter", "AndroidPlatformViewsController::OffsetPlatformView",
               "view_id", std::to_string(view_id).c_str());
  if (!provider_) {
    return false;
  }
  return provider_->OffsetPlatformView(view_id, top, left);
}

bool AndroidPlatformViewsController::SetDirection(int64_t view_id,
                                                  int32_t direction) {
  TRACE_EVENT1("flutter", "AndroidPlatformViewsController::SetDirection",
               "view_id", std::to_string(view_id).c_str());
  if (!provider_) {
    return false;
  }
  return provider_->SetDirection(view_id, direction);
}

bool AndroidPlatformViewsController::ClearFocus(int64_t view_id) {
  TRACE_EVENT1("flutter", "AndroidPlatformViewsController::ClearFocus",
               "view_id", std::to_string(view_id).c_str());
  if (!provider_) {
    return false;
  }
  return provider_->ClearFocus(view_id);
}

bool AndroidPlatformViewsController::DispatchTouchEvent(
    const PlatformViewTouch& touch) {
  TRACE_EVENT1("flutter", "AndroidPlatformViewsController::DispatchTouchEvent",
               "view_id", std::to_string(touch.view_id).c_str());
  if (!provider_) {
    return false;
  }
  return provider_->DispatchTouchEvent(touch);
}

bool AndroidPlatformViewsController::OnDisplayPlatformView(
    int64_t view_id,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    int32_t view_width,
    int32_t view_height,
    const AndroidMutatorsStack& mutators_stack) {
  TRACE_EVENT1("flutter",
               "AndroidPlatformViewsController::OnDisplayPlatformView",
               "view_id", std::to_string(view_id).c_str());
  if (!provider_) {
    return false;
  }
  PlatformViewGeometry geometry;
  geometry.view_id = view_id;
  geometry.x = x;
  geometry.y = y;
  geometry.width = width;
  geometry.height = height;
  geometry.view_width = view_width;
  geometry.view_height = view_height;
  geometry.mutators_stack = mutators_stack;

  bool result = provider_->OnDisplayPlatformView(geometry);
  if (result) {
    std::lock_guard<std::mutex> lock(mutex_);
    active_geometries_[view_id] = geometry;
  }
  return result;
}

bool AndroidPlatformViewsController::OnDisplayPlatformView(
    const FlutterPlatformView& platform_view,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    int32_t view_width,
    int32_t view_height) {
  TRACE_EVENT1("flutter",
               "AndroidPlatformViewsController::OnDisplayPlatformView(struct)",
               "view_id", std::to_string(platform_view.identifier).c_str());
  AndroidMutatorsStack stack =
      AndroidMutatorsMapper::MapPlatformView(platform_view);
  return OnDisplayPlatformView(platform_view.identifier, x, y, width, height,
                               view_width, view_height, stack);
}

bool AndroidPlatformViewsController::HidePlatformView(int64_t view_id) {
  TRACE_EVENT1("flutter", "AndroidPlatformViewsController::HidePlatformView",
               "view_id", std::to_string(view_id).c_str());
  if (!provider_) {
    return false;
  }
  return provider_->HidePlatformView(view_id);
}

bool AndroidPlatformViewsController::PushPlatformViewMutators(
    int64_t view_id,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    const AndroidMutatorsStack& mutators_stack) {
  TRACE_EVENT1("flutter",
               "AndroidPlatformViewsController::PushPlatformViewMutators",
               "view_id", std::to_string(view_id).c_str());
  return OnDisplayPlatformView(view_id, x, y, width, height, width, height,
                               mutators_stack);
}

bool AndroidPlatformViewsController::PushPlatformViewMutators(
    const FlutterPlatformView& platform_view,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height) {
  TRACE_EVENT1(
      "flutter",
      "AndroidPlatformViewsController::PushPlatformViewMutators(struct)",
      "view_id", std::to_string(platform_view.identifier).c_str());
  AndroidMutatorsStack stack =
      AndroidMutatorsMapper::MapPlatformView(platform_view);
  return PushPlatformViewMutators(platform_view.identifier, x, y, width, height,
                                  stack);
}

bool AndroidPlatformViewsController::SynchronizeToNativeViewHierarchy(
    bool synchronize) {
  TRACE_EVENT0(
      "flutter",
      "AndroidPlatformViewsController::SynchronizeToNativeViewHierarchy");
  if (!provider_) {
    return false;
  }
  return provider_->SynchronizeToNativeViewHierarchy(synchronize);
}

bool AndroidPlatformViewsController::OnBeginFrame() {
  TRACE_EVENT0("flutter", "AndroidPlatformViewsController::OnBeginFrame");
  if (!provider_) {
    return false;
  }
  return provider_->OnBeginFrame();
}

bool AndroidPlatformViewsController::OnEndFrame() {
  TRACE_EVENT0("flutter", "AndroidPlatformViewsController::OnEndFrame");
  if (!provider_) {
    return false;
  }
  return provider_->OnEndFrame();
}

std::optional<int32_t> AndroidPlatformViewsController::CreateOverlaySurface() {
  TRACE_EVENT0("flutter",
               "AndroidPlatformViewsController::CreateOverlaySurface");
  if (!provider_) {
    return std::nullopt;
  }
  return provider_->CreateOverlaySurface();
}

bool AndroidPlatformViewsController::DestroyOverlaySurfaces() {
  TRACE_EVENT0("flutter",
               "AndroidPlatformViewsController::DestroyOverlaySurfaces");
  if (!provider_) {
    return false;
  }
  return provider_->DestroyOverlaySurfaces();
}

bool AndroidPlatformViewsController::OnDisplayOverlaySurface(int32_t surface_id,
                                                             int32_t x,
                                                             int32_t y,
                                                             int32_t width,
                                                             int32_t height) {
  TRACE_EVENT1("flutter",
               "AndroidPlatformViewsController::OnDisplayOverlaySurface",
               "surface_id", std::to_string(surface_id).c_str());
  if (!provider_) {
    return false;
  }
  PlatformViewOverlay overlay;
  overlay.surface_id = surface_id;
  overlay.x = x;
  overlay.y = y;
  overlay.width = width;
  overlay.height = height;
  return provider_->OnDisplayOverlaySurface(overlay);
}

bool AndroidPlatformViewsController::ShowOverlaySurface(int32_t surface_id) {
  TRACE_EVENT1("flutter", "AndroidPlatformViewsController::ShowOverlaySurface",
               "surface_id", std::to_string(surface_id).c_str());
  if (!provider_) {
    return false;
  }
  return provider_->ShowOverlaySurface(surface_id);
}

bool AndroidPlatformViewsController::HideOverlaySurface(int32_t surface_id) {
  TRACE_EVENT1("flutter", "AndroidPlatformViewsController::HideOverlaySurface",
               "surface_id", std::to_string(surface_id).c_str());
  if (!provider_) {
    return false;
  }
  return provider_->HideOverlaySurface(surface_id);
}

bool AndroidPlatformViewsController::CreateTransaction() {
  TRACE_EVENT0("flutter", "AndroidPlatformViewsController::CreateTransaction");
  if (!provider_) {
    return false;
  }
  return provider_->CreateTransaction();
}

bool AndroidPlatformViewsController::SwapTransactions() {
  TRACE_EVENT0("flutter", "AndroidPlatformViewsController::SwapTransactions");
  if (!provider_) {
    return false;
  }
  return provider_->SwapTransactions();
}

bool AndroidPlatformViewsController::ApplyTransactions() {
  TRACE_EVENT0("flutter", "AndroidPlatformViewsController::ApplyTransactions");
  if (!provider_) {
    return false;
  }
  return provider_->ApplyTransactions();
}

bool AndroidPlatformViewsController::IsHcppEnabled() const {
  TRACE_EVENT0("flutter", "AndroidPlatformViewsController::IsHcppEnabled");
  if (!provider_) {
    return false;
  }
  return provider_->IsHcppEnabled();
}

size_t AndroidPlatformViewsController::GetActiveViewsCount() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return active_composition_types_.size();
}

bool AndroidPlatformViewsController::HasPlatformView(int64_t view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  return active_composition_types_.find(view_id) !=
         active_composition_types_.end();
}

std::optional<PlatformViewGeometry>
AndroidPlatformViewsController::GetPlatformViewGeometry(int64_t view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = active_geometries_.find(view_id);
  if (it != active_geometries_.end()) {
    return it->second;
  }
  return std::nullopt;
}

std::optional<PlatformViewCompositionType>
AndroidPlatformViewsController::GetCompositionType(int64_t view_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = active_composition_types_.find(view_id);
  if (it != active_composition_types_.end()) {
    return it->second;
  }
  return std::nullopt;
}

std::shared_ptr<PlatformViewsProvider>
AndroidPlatformViewsController::GetProvider() const {
  return provider_;
}

void AndroidPlatformViewsController::SetProvider(
    std::shared_ptr<PlatformViewsProvider> provider) {
  TRACE_EVENT0("flutter", "AndroidPlatformViewsController::SetProvider");
  provider_ = provider ? std::move(provider)
                       : std::make_shared<DefaultPlatformViewsProvider>();
}

}  // namespace android
}  // namespace flutter
