// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/window/platform_message_response_dart.h"

#include <utility>

#include "flutter/common/threads.h"
#include "lib/fxl/functional/make_copyable.h"
#include "lib/tonic/dart_state.h"
#include "lib/tonic/logging/dart_invoke.h"

namespace blink {

PlatformMessageResponseDart::PlatformMessageResponseDart(
    tonic::DartPersistentValue callback)
    : callback_(std::move(callback)) {}

PlatformMessageResponseDart::~PlatformMessageResponseDart() {
  if (!callback_.is_empty()) {
    Threads::UI()->PostTask(fxl::MakeCopyable(
        [callback = std::move(callback_)]() mutable { callback.Clear(); }));
  }
}

void PlatformMessageResponseDart::Complete(std::vector<uint8_t> data) {
  if (callback_.is_empty())
    return;
  FXL_DCHECK(!is_complete_);
  is_complete_ = true;
  Threads::UI()->PostTask(fxl::MakeCopyable(
      [callback = std::move(callback_), data = std::move(data)]() mutable {
        tonic::DartState* dart_state = callback.dart_state().get();
        if (!dart_state)
          return;
        tonic::DartState::Scope scope(dart_state);

        Dart_Handle byte_buffer =
            Dart_NewTypedData(Dart_TypedData_kByteData, data.size());
        DART_CHECK_VALID(byte_buffer);

        void* buffer;
        intptr_t length;
        Dart_TypedData_Type type;
        DART_CHECK_VALID(
            Dart_TypedDataAcquireData(byte_buffer, &type, &buffer, &length));
        FXL_CHECK(type == Dart_TypedData_kByteData);
        FXL_CHECK(static_cast<size_t>(length) == data.size());
        memcpy(buffer, data.data(), length);
        Dart_TypedDataReleaseData(byte_buffer);
        tonic::DartInvoke(callback.Release(), {byte_buffer});
      }));
}

void PlatformMessageResponseDart::CompleteEmpty() {
  if (callback_.is_empty())
    return;
  FXL_DCHECK(!is_complete_);
  is_complete_ = true;
  Threads::UI()->PostTask(
      fxl::MakeCopyable([callback = std::move(callback_)]() mutable {
        tonic::DartState* dart_state = callback.dart_state().get();
        if (!dart_state)
          return;
        tonic::DartState::Scope scope(dart_state);
        tonic::DartInvoke(callback.Release(), {Dart_Null()});
      }));
}

}  // namespace blink
