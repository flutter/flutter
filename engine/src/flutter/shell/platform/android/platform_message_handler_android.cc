// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/platform_message_handler_android.h"

#include <cstdlib>
#include <cstring>
#include <utility>

#include "flutter/fml/logging.h"

namespace flutter {

namespace {

// Passed as the data of a zero-length reply, which must reach Dart as empty
// data. A null pointer would make it a null reply.
constexpr uint8_t kEmptyReplyByte = 0;

// Copies the payload of `message` into memory that this file owns.
UniquePlatformMessagePayload CopyPayload(
    const FlutterPlatformMessage& message) {
  if (message.message == nullptr) {
    return nullptr;
  }
  // malloc(0) may return null, and a zero-length payload must not be null.
  void* allocation =
      malloc(message.message_size > 0 ? message.message_size : 1);
  FML_CHECK(allocation != nullptr);
  if (message.message_size > 0) {
    memcpy(allocation, message.message, message.message_size);
  }
  auto payload = UniquePlatformMessagePayload(new FlutterPlatformMessagePayload{
      .struct_size = sizeof(FlutterPlatformMessagePayload),
      .data = static_cast<const uint8_t*>(allocation),
      .data_size = message.message_size,
      .user_data = allocation,
      .destruction_callback = [](void* user_data) { free(user_data); },
  });
  return payload;
}

}  // namespace

PlatformMessageHandlerAndroid::PlatformMessageHandlerAndroid(
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade)
    : jni_facade_(std::move(jni_facade)) {}

PlatformMessageHandlerAndroid::~PlatformMessageHandlerAndroid() {
  // The holder releases pending responses before the engine shuts down.
  FML_DCHECK(pending_responses_.empty());
}

void PlatformMessageHandlerAndroid::Attach(
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    const FlutterEngineProcTable* embedder_api) {
  std::scoped_lock lock(mutex_);
  engine_ = engine;
  embedder_api_ = embedder_api;
}

void PlatformMessageHandlerAndroid::HandlePlatformMessage(
    const FlutterPlatformMessage& message) {
  // Called on the UI thread or a background isolate's thread.
  UniquePlatformMessagePayload payload;
  int response_id = 0;
  {
    std::scoped_lock lock(mutex_);
    if (released_) {
      ReleaseResponseHandleLocked(message.response_handle);
      return;
    }
    payload = TakePayloadLocked(message);
    response_id = next_response_id_++;
    pending_responses_[response_id] = message.response_handle;
  }
  // This call can re-enter in InvokePlatformMessageXxxResponseCallback.
  jni_facade_->FlutterViewHandlePlatformMessage(
      message.channel, std::move(payload), response_id);
}

void PlatformMessageHandlerAndroid::InvokePlatformMessageResponseCallback(
    int response_id,
    const uint8_t* data,
    size_t size) {
  // Called from any thread.
  PendingResponse response = TakePendingResponse(response_id);
  if (response.handle == nullptr) {
    return;
  }
  FlutterEngineResult result =
      response.embedder_api->SendPlatformMessageResponse(
          response.engine, response.handle,
          data != nullptr ? data : &kEmptyReplyByte, size);
  if (result != kSuccess) {
    FML_LOG(ERROR) << "FlutterEngineSendPlatformMessageResponse failed: "
                   << result;
  }
}

void PlatformMessageHandlerAndroid::InvokePlatformMessageEmptyResponseCallback(
    int response_id) {
  // Called from any thread.
  PendingResponse response = TakePendingResponse(response_id);
  if (response.handle == nullptr) {
    return;
  }
  FlutterEngineResult result =
      response.embedder_api->SendPlatformMessageResponse(
          response.engine, response.handle, nullptr, 0);
  if (result != kSuccess) {
    FML_LOG(ERROR) << "FlutterEngineSendPlatformMessageResponse failed: "
                   << result;
  }
}

void PlatformMessageHandlerAndroid::ReleasePendingResponses() {
  std::scoped_lock lock(mutex_);
  released_ = true;
  for (const auto& [response_id, handle] : pending_responses_) {
    ReleaseResponseHandleLocked(handle);
  }
  pending_responses_.clear();
}

UniquePlatformMessagePayload PlatformMessageHandlerAndroid::TakePayloadLocked(
    const FlutterPlatformMessage& message) {
  if (engine_ == nullptr || embedder_api_ == nullptr) {
    // A spawned engine delivered this before its holder had the engine handle.
    return CopyPayload(message);
  }
  FlutterPlatformMessagePayload payload = {
      .struct_size = sizeof(FlutterPlatformMessagePayload),
  };
  FlutterEngineResult result = embedder_api_->PlatformMessageTakePayload(
      engine_, message.response_handle, &payload);
  if (result != kSuccess) {
    FML_LOG(ERROR) << "FlutterPlatformMessageTakePayload failed: " << result;
    return CopyPayload(message);
  }
  if (payload.data == nullptr) {
    return nullptr;
  }
  return UniquePlatformMessagePayload(
      new FlutterPlatformMessagePayload(payload));
}

void PlatformMessageHandlerAndroid::ReleaseResponseHandleLocked(
    const FlutterPlatformMessageResponseHandle* handle) {
  if (engine_ == nullptr || embedder_api_ == nullptr) {
    FML_LOG(ERROR) << "Dropping a platform message response handle without an "
                      "engine to release it through.";
    return;
  }
  FlutterEngineResult result =
      embedder_api_->PlatformMessageReleaseResponseHandle(
          engine_, const_cast<FlutterPlatformMessageResponseHandle*>(handle));
  if (result != kSuccess) {
    FML_LOG(ERROR) << "FlutterPlatformMessageReleaseResponseHandle failed: "
                   << result;
  }
}

PlatformMessageHandlerAndroid::PendingResponse
PlatformMessageHandlerAndroid::TakePendingResponse(int response_id) {
  std::scoped_lock lock(mutex_);
  auto it = pending_responses_.find(response_id);
  if (it == pending_responses_.end()) {
    return {};
  }
  PendingResponse response = {
      .handle = it->second,
      .engine = engine_,
      .embedder_api = embedder_api_,
  };
  pending_responses_.erase(it);
  if (response.engine == nullptr || response.embedder_api == nullptr) {
    // Java can only answer once the holder is attached; see Attach().
    FML_LOG(ERROR) << "Dropping a platform message response without an engine "
                      "to send it through.";
    return {};
  }
  return response;
}

}  // namespace flutter
