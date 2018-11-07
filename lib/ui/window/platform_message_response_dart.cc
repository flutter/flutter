// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/window/platform_message_response_dart.h"

#include <utility>

#include "flutter/common/task_runners.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/lib/ui/window/window.h"
#include "third_party/tonic/dart_state.h"
#include "third_party/tonic/logging/dart_invoke.h"

namespace blink {

namespace {

// Avoid copying the contents of messages beyond a certain size.
const int kMessageCopyThreshold = 1000;

void MessageDataFinalizer(void* isolate_callback_data,
                          Dart_WeakPersistentHandle handle,
                          void* peer) {
  std::vector<uint8_t>* data = reinterpret_cast<std::vector<uint8_t>*>(peer);
  delete data;
}

Dart_Handle WrapByteData(std::vector<uint8_t> data) {
  if (data.size() < kMessageCopyThreshold) {
    return ToByteData(data);
  } else {
    std::vector<uint8_t>* heap_data = new std::vector<uint8_t>(std::move(data));
    Dart_Handle data_handle = Dart_NewExternalTypedDataWithFinalizer(
        Dart_TypedData_kByteData, heap_data->data(), heap_data->size(),
        heap_data, heap_data->size(), MessageDataFinalizer);
    DART_CHECK_VALID(data_handle);
    return data_handle;
  }
}

Dart_Handle WrapByteData(std::unique_ptr<fml::Mapping> mapping) {
  std::vector<uint8_t> data(mapping->GetSize());
  memcpy(data.data(), mapping->GetMapping(), mapping->GetSize());
  return WrapByteData(std::move(data));
}

}  // anonymous namespace

PlatformMessageResponseDart::PlatformMessageResponseDart(
    tonic::DartPersistentValue callback,
    fml::RefPtr<fml::TaskRunner> ui_task_runner)
    : callback_(std::move(callback)),
      ui_task_runner_(std::move(ui_task_runner)) {}

PlatformMessageResponseDart::~PlatformMessageResponseDart() {
  if (!callback_.is_empty()) {
    ui_task_runner_->PostTask(fml::MakeCopyable(
        [callback = std::move(callback_)]() mutable { callback.Clear(); }));
  }
}

void PlatformMessageResponseDart::Complete(std::unique_ptr<fml::Mapping> data) {
  if (callback_.is_empty())
    return;
  FML_DCHECK(!is_complete_);
  is_complete_ = true;
  ui_task_runner_->PostTask(fml::MakeCopyable(
      [callback = std::move(callback_), data = std::move(data)]() mutable {
        std::shared_ptr<tonic::DartState> dart_state =
            callback.dart_state().lock();
        if (!dart_state)
          return;
        tonic::DartState::Scope scope(dart_state);

        Dart_Handle byte_buffer = WrapByteData(std::move(data));
        tonic::DartInvoke(callback.Release(), {byte_buffer});
      }));
}

void PlatformMessageResponseDart::CompleteEmpty() {
  if (callback_.is_empty())
    return;
  FML_DCHECK(!is_complete_);
  is_complete_ = true;
  ui_task_runner_->PostTask(
      fml::MakeCopyable([callback = std::move(callback_)]() mutable {
        std::shared_ptr<tonic::DartState> dart_state =
            callback.dart_state().lock();
        if (!dart_state)
          return;
        tonic::DartState::Scope scope(dart_state);
        tonic::DartInvoke(callback.Release(), {Dart_Null()});
      }));
}

}  // namespace blink
