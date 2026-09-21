// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/platform_message_handler_android.h"

#include "flutter/shell/platform/embedder/embedder_engine.h"

namespace flutter {

PlatformMessageHandlerAndroid::PlatformMessageHandlerAndroid(
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade)
    : jni_facade_(jni_facade) {}

void PlatformMessageHandlerAndroid::SetEmbedderEngine(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    const FlutterEngineProcTable& proc_table) {
  std::lock_guard lock(embedder_engine_mutex_);
  embedder_engine_ = engine;
  proc_table_ = proc_table;
}

void PlatformMessageHandlerAndroid::InvokePlatformMessageResponseCallback(
    int response_id,
    std::unique_ptr<fml::Mapping> mapping) {
  // Called from any thread.
  if (!response_id) {
    return;
  }
  // TODO(gaaclarke): Move the jump to the ui thread here from
  // PlatformMessageResponseDart so we won't need to use a mutex anymore.
  fml::RefPtr<flutter::PlatformMessageResponse> message_response;
  {
    std::lock_guard lock(pending_responses_mutex_);
    auto it = pending_responses_.find(response_id);
    if (it == pending_responses_.end()) {
      return;
    }
    message_response = std::move(it->second);
    pending_responses_.erase(it);
  }

  FLUTTER_API_SYMBOL(FlutterEngine) engine = nullptr;
  FlutterEngineSendPlatformMessageResponseFnPtr send_response_fn = nullptr;
  {
    std::lock_guard lock(embedder_engine_mutex_);
    engine = embedder_engine_;
    send_response_fn = proc_table_.SendPlatformMessageResponse;
  }
  if (send_response_fn != nullptr) {
    auto* handle = new FlutterPlatformMessageResponseHandle{
        std::make_unique<flutter::PlatformMessage>(
            "", std::move(message_response))};
    const uint8_t* data =
        (mapping && mapping->GetSize() > 0) ? mapping->GetMapping() : nullptr;
    size_t size = (data != nullptr) ? mapping->GetSize() : 0;
    send_response_fn(engine, handle, data, size);
    return;
  }

  message_response->Complete(std::move(mapping));
}

void PlatformMessageHandlerAndroid::InvokePlatformMessageEmptyResponseCallback(
    int response_id) {
  // Called from any thread.
  if (!response_id) {
    return;
  }
  fml::RefPtr<flutter::PlatformMessageResponse> message_response;
  {
    std::lock_guard lock(pending_responses_mutex_);
    auto it = pending_responses_.find(response_id);
    if (it == pending_responses_.end()) {
      return;
    }
    message_response = std::move(it->second);
    pending_responses_.erase(it);
  }

  FLUTTER_API_SYMBOL(FlutterEngine) engine = nullptr;
  FlutterEngineSendPlatformMessageResponseFnPtr send_response_fn = nullptr;
  {
    std::lock_guard lock(embedder_engine_mutex_);
    engine = embedder_engine_;
    send_response_fn = proc_table_.SendPlatformMessageResponse;
  }
  if (send_response_fn != nullptr) {
    auto* handle = new FlutterPlatformMessageResponseHandle{
        std::make_unique<flutter::PlatformMessage>(
            "", std::move(message_response))};
    send_response_fn(engine, handle, nullptr, 0);
    return;
  }

  message_response->CompleteEmpty();
}

// |PlatformView|
void PlatformMessageHandlerAndroid::HandlePlatformMessage(
    std::unique_ptr<flutter::PlatformMessage> message) {
  // Called from any thread.
  int response_id = next_response_id_.fetch_add(1);
  if (auto response = message->response()) {
    std::lock_guard lock(pending_responses_mutex_);
    pending_responses_[response_id] = response;
  }
  // This call can re-enter in InvokePlatformMessageXxxResponseCallback.
  jni_facade_->FlutterViewHandlePlatformMessage(std::move(message),
                                                response_id);
}

}  // namespace flutter
