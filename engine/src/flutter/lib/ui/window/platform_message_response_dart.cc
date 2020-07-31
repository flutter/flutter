// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/window/platform_message_response_dart.h"

#include <utility>

#include "flutter/common/task_runners.h"
#include "flutter/fml/make_copyable.h"
#include "third_party/tonic/dart_state.h"
#include "third_party/tonic/logging/dart_invoke.h"
#include "third_party/tonic/typed_data/dart_byte_data.h"

namespace flutter {

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
  if (callback_.is_empty()) {
    return;
  }
  FML_DCHECK(!is_complete_);
  is_complete_ = true;
  ui_task_runner_->PostTask(fml::MakeCopyable(
      [callback = std::move(callback_), data = std::move(data)]() mutable {
        std::shared_ptr<tonic::DartState> dart_state =
            callback.dart_state().lock();
        if (!dart_state) {
          return;
        }
        tonic::DartState::Scope scope(dart_state);

        Dart_Handle byte_buffer =
            tonic::DartByteData::Create(data->GetMapping(), data->GetSize());
        tonic::DartInvoke(callback.Release(), {byte_buffer});
      }));
}

void PlatformMessageResponseDart::CompleteEmpty() {
  if (callback_.is_empty()) {
    return;
  }
  FML_DCHECK(!is_complete_);
  is_complete_ = true;
  ui_task_runner_->PostTask(
      fml::MakeCopyable([callback = std::move(callback_)]() mutable {
        std::shared_ptr<tonic::DartState> dart_state =
            callback.dart_state().lock();
        if (!dart_state) {
          return;
        }
        tonic::DartState::Scope scope(dart_state);
        tonic::DartInvoke(callback.Release(), {Dart_Null()});
      }));
}

}  // namespace flutter
