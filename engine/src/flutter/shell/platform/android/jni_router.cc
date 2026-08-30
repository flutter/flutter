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
  TRACE_EVENT0("flutter", "JniRouter::RouteSemanticsUpdate");
  if (IsEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->UpdateSemantics(buffer, strings);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->UpdateSemantics(buffer, strings);
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

}  // namespace android
}  // namespace flutter
