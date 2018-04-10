// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/window/platform_message_response_dart.h"

#include <utility>

#include "flutter/common/task_runners.h"
#include "flutter/lib/ui/window/window.h"
#include "lib/fxl/functional/make_copyable.h"
#include "lib/tonic/dart_state.h"
#include "lib/tonic/logging/dart_invoke.h"

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
    Dart_Handle data_handle = Dart_NewExternalTypedData(
        Dart_TypedData_kByteData, heap_data->data(), heap_data->size());
    DART_CHECK_VALID(data_handle);
    Dart_NewWeakPersistentHandle(data_handle, heap_data, heap_data->size(),
                                 MessageDataFinalizer);
    return data_handle;
  }
}

}  // anonymous namespace

PlatformMessageResponseDart::PlatformMessageResponseDart(
    tonic::DartPersistentValue callback,
    fxl::RefPtr<fxl::TaskRunner> ui_task_runner)
    : callback_(std::move(callback)),
      ui_task_runner_(std::move(ui_task_runner)) {}

PlatformMessageResponseDart::~PlatformMessageResponseDart() {
  if (!callback_.is_empty()) {
    ui_task_runner_->PostTask(
        fxl::MakeCopyable([callback = std::move(callback_)]() mutable {
          callback.Clear();
        }));
  }
}

void PlatformMessageResponseDart::Complete(std::vector<uint8_t> data) {
  if (callback_.is_empty())
    return;
  FXL_DCHECK(!is_complete_);
  is_complete_ = true;
  ui_task_runner_->PostTask(fxl::MakeCopyable(
      [ callback = std::move(callback_), data = std::move(data) ]() mutable {
        tonic::DartState* dart_state = callback.dart_state().get();
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
  FXL_DCHECK(!is_complete_);
  is_complete_ = true;
  ui_task_runner_->PostTask(
      fxl::MakeCopyable([callback = std::move(callback_)]() mutable {
        tonic::DartState* dart_state = callback.dart_state().get();
        if (!dart_state)
          return;
        tonic::DartState::Scope scope(dart_state);
        tonic::DartInvoke(callback.Release(), {Dart_Null()});
      }));
}

}  // namespace blink
