// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_PLATFORM_MESSAGE_HANDLER_ANDROID_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_PLATFORM_MESSAGE_HANDLER_ANDROID_H_

#include <memory>
#include <mutex>
#include <unordered_map>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      Forwards the platform messages that one engine delivers through
///             `FlutterProjectArgs.platform_message_callback` to Java, and
///             keeps their response handles until Java answers by the
///             response id it was given.
///
///             Messages arrive on the UI thread and on background isolate
///             threads, and Java answers on any thread, so every method is
///             thread safe.
///
class PlatformMessageHandlerAndroid {
 public:
  explicit PlatformMessageHandlerAndroid(
      std::shared_ptr<PlatformViewAndroidJNI> jni_facade);

  ~PlatformMessageHandlerAndroid();

  //----------------------------------------------------------------------------
  /// @brief      Sets the engine that delivers the messages and the embedder
  ///             API to answer them through. A spawned engine can deliver
  ///             messages before its holder has the engine handle; their
  ///             payloads are copied instead of taken.
  ///
  void Attach(FLUTTER_API_SYMBOL(FlutterEngine) engine,
              const FlutterEngineProcTable* embedder_api);

  //----------------------------------------------------------------------------
  /// @brief      Takes the payload of `message`, keeps its response handle and
  ///             hands both to Java.
  ///
  void HandlePlatformMessage(const FlutterPlatformMessage& message);

  //----------------------------------------------------------------------------
  /// @brief      Sends Java's reply to the message with `response_id`. A
  ///             zero-length reply reaches Dart as empty data, not as null.
  ///
  void InvokePlatformMessageResponseCallback(int response_id,
                                             const uint8_t* data,
                                             size_t size);

  //----------------------------------------------------------------------------
  /// @brief      Sends a null reply to the message with `response_id`.
  ///
  void InvokePlatformMessageEmptyResponseCallback(int response_id);

  //----------------------------------------------------------------------------
  /// @brief      Releases the response handles of the messages Java has not
  ///             answered, and releases later messages right away instead of
  ///             forwarding them. Call it before the engine shuts down.
  ///
  void ReleasePendingResponses();

 private:
  const std::shared_ptr<PlatformViewAndroidJNI> jni_facade_;

  std::mutex mutex_;
  FLUTTER_API_SYMBOL(FlutterEngine) engine_ = nullptr;
  const FlutterEngineProcTable* embedder_api_ = nullptr;
  bool released_ = false;
  // Response ids start at 1; Java treats 0 as no response.
  int next_response_id_ = 1;
  std::unordered_map<int, const FlutterPlatformMessageResponseHandle*>
      pending_responses_;

  // Must be called with `mutex_` held.
  UniquePlatformMessagePayload TakePayloadLocked(
      const FlutterPlatformMessage& message);

  // Must be called with `mutex_` held.
  void ReleaseResponseHandleLocked(
      const FlutterPlatformMessageResponseHandle* handle);

  // Removes the handle of `response_id` and returns it with the engine and
  // API to answer it through, or a null handle if there is none.
  struct PendingResponse {
    const FlutterPlatformMessageResponseHandle* handle = nullptr;
    FLUTTER_API_SYMBOL(FlutterEngine) engine = nullptr;
    const FlutterEngineProcTable* embedder_api = nullptr;
  };
  PendingResponse TakePendingResponse(int response_id);

  FML_DISALLOW_COPY_AND_ASSIGN(PlatformMessageHandlerAndroid);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_PLATFORM_MESSAGE_HANDLER_ANDROID_H_
