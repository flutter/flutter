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
                     std::shared_ptr<LegacyJniDelegate> legacy_delegate)
    : embedder_delegate_(std::move(embedder_delegate)),
      legacy_delegate_(std::move(legacy_delegate)) {
  TRACE_EVENT0("flutter", "JniRouter::JniRouter");
}

JniRouter::~JniRouter() {
  TRACE_EVENT0("flutter", "JniRouter::~JniRouter");
}

bool JniRouter::IsGlobalEmbedderEnabled() {
  return embedder_enabled_.load();
}

void JniRouter::SetGlobalEmbedderEnabled(bool enabled) {
  embedder_enabled_.store(enabled);
}

bool JniRouter::IsEmbedderEnabled() {
  return IsGlobalEmbedderEnabled();
}

void JniRouter::SetEmbedderEnabled(bool enabled) {
  SetGlobalEmbedderEnabled(enabled);
}

void JniRouter::SetInstanceEmbedderEnabled(std::optional<bool> enabled) {
  if (!enabled.has_value()) {
    instance_embedder_enabled_.store(InstanceOverride::kUseGlobal);
  } else {
    instance_embedder_enabled_.store(*enabled ? InstanceOverride::kEnabled
                                              : InstanceOverride::kDisabled);
  }
}

bool JniRouter::IsInstanceEmbedderEnabled() const {
  InstanceOverride override_val = instance_embedder_enabled_.load();
  if (override_val == InstanceOverride::kUseGlobal) {
    return IsGlobalEmbedderEnabled();
  }
  return override_val == InstanceOverride::kEnabled;
}

JniRouter::RoutingPath JniRouter::GetActiveRoutingPath() const {
  return IsInstanceEmbedderEnabled() ? RoutingPath::kEmbedder
                                     : RoutingPath::kLegacy;
}

std::shared_ptr<JniDelegate> JniRouter::GetEmbedderDelegate() const {
  return embedder_delegate_;
}

std::shared_ptr<LegacyJniDelegate> JniRouter::GetLegacyDelegate() const {
  return legacy_delegate_;
}

bool JniRouter::RoutePlatformMessage(const std::string& channel,
                                     const uint8_t* message,
                                     size_t message_size,
                                     int32_t response_id,
                                     int64_t message_data) {
  TRACE_EVENT1("flutter", "JniRouter::RoutePlatformMessage", "channel",
               channel.c_str());
  if (IsInstanceEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->HandlePlatformMessage(
          channel, message, message_size, response_id, message_data);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->HandlePlatformMessage(
        channel, message, message_size, response_id, message_data);
  }
  return false;
}

bool JniRouter::RoutePlatformMessage(const std::string& channel,
                                     const std::vector<uint8_t>& message,
                                     int32_t response_id,
                                     int64_t message_data) {
  return RoutePlatformMessage(channel, message.data(), message.size(),
                              response_id, message_data);
}

bool JniRouter::RoutePlatformMessageResponse(int32_t response_id,
                                             const uint8_t* data,
                                             size_t data_size) {
  TRACE_EVENT0("flutter", "JniRouter::RoutePlatformMessageResponse");
  if (IsInstanceEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->HandlePlatformMessageResponse(response_id,
                                                               data, data_size);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->HandlePlatformMessageResponse(response_id, data,
                                                           data_size);
  }
  return false;
}

bool JniRouter::RoutePlatformMessageResponse(int32_t response_id,
                                             const std::vector<uint8_t>& data) {
  return RoutePlatformMessageResponse(response_id, data.data(), data.size());
}

bool JniRouter::RouteSemanticsUpdate(
    const std::vector<uint8_t>& buffer,
    const std::vector<std::string>& strings,
    const std::vector<std::vector<uint8_t>>& string_attribute_args) {
  TRACE_EVENT0("flutter", "JniRouter::RouteSemanticsUpdate");
  if (IsInstanceEmbedderEnabled()) {
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

bool JniRouter::RouteSemanticsTreeEnabled(bool enabled) {
  TRACE_EVENT0("flutter", "JniRouter::RouteSemanticsTreeEnabled");
  if (IsInstanceEmbedderEnabled()) {
    if (embedder_delegate_) {
      return embedder_delegate_->SetSemanticsTreeEnabled(enabled);
    }
    return false;
  }
  if (legacy_delegate_) {
    return legacy_delegate_->SetSemanticsTreeEnabled(enabled);
  }
  return false;
}

bool JniRouter::RouteApplicationLocale(const std::string& locale) {
  TRACE_EVENT1("flutter", "JniRouter::RouteApplicationLocale", "locale",
               locale.c_str());
  if (IsInstanceEmbedderEnabled()) {
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
  if (IsInstanceEmbedderEnabled()) {
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
  if (IsInstanceEmbedderEnabled()) {
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

bool JniRouter::RouteRequestDartDeferredLibrary(int loading_unit_id) {
  TRACE_EVENT0("flutter", "JniRouter::RouteRequestDartDeferredLibrary");
  if (IsInstanceEmbedderEnabled()) {
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

std::optional<DartCallbackInfo> JniRouter::RouteLookupCallbackInformation(
    int64_t handle) {
  TRACE_EVENT0("flutter", "JniRouter::RouteLookupCallbackInformation");
  if (IsInstanceEmbedderEnabled()) {
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
}  // namespace android
}  // namespace flutter
