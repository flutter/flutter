// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/tonic/dart_message_handler.h"

#include "dart/runtime/include/dart_api.h"
#include "dart/runtime/include/dart_native_api.h"
#include "dart/runtime/include/dart_tools_api.h"
#include "lib/ftl/logging.h"
#include "lib/tonic/logging/dart_error.h"
#include "flutter/tonic/dart_state.h"

using tonic::LogIfError;

namespace blink {

DartMessageHandler::DartMessageHandler()
    : handled_first_message_(false),
      isolate_exited_(false),
      isolate_had_uncaught_exception_error_(false),
      task_runner_(nullptr) {}

DartMessageHandler::~DartMessageHandler() {
  task_runner_ = nullptr;
}

void DartMessageHandler::Initialize(
    const ftl::RefPtr<ftl::TaskRunner>& runner) {
  // Only can be called once.
  FTL_CHECK(!task_runner_);
  task_runner_ = runner;
  FTL_CHECK(task_runner_);
  Dart_SetMessageNotifyCallback(MessageNotifyCallback);
}

void DartMessageHandler::OnMessage(DartState* dart_state) {
  auto task_runner = dart_state->message_handler().task_runner();

  // Schedule a task to run on the message loop thread.
  base::WeakPtr<DartState> dart_state_ptr = dart_state->GetWeakPtr();
  task_runner->PostTask([dart_state_ptr]() {
    if (!dart_state_ptr)
      return;
    dart_state_ptr->message_handler().OnHandleMessage(dart_state_ptr.get());
  });
}

void DartMessageHandler::OnHandleMessage(DartState* dart_state) {
  tonic::DartIsolateScope scope(dart_state->isolate());
  tonic::DartApiScope dart_api_scope;

  bool error = false;

  // On the first message, check if we should pause on isolate start.
  if (!handled_first_message()) {
    set_handled_first_message(true);
    if (Dart_ShouldPauseOnStart()) {
      // Mark that we are paused on isolate start.
      Dart_SetPausedOnStart(true);
    }
  }

  if (Dart_IsPausedOnStart()) {
    // We are paused on isolate start. Only handle service messages until we are
    // requested to resume.
    if (Dart_HasServiceMessages()) {
      bool resume = Dart_HandleServiceMessages();
      if (!resume) {
        return;
      }
      Dart_SetPausedOnStart(false);
      // We've resumed, handle *all* normal messages that are in the queue.
      error = LogIfError(Dart_HandleMessages());
    }
  } else if (Dart_IsPausedOnExit()) {
    // We are paused on isolate exit. Only handle service messages until we are
    // requested to resume.
    if (Dart_HasServiceMessages()) {
      bool resume = Dart_HandleServiceMessages();
      if (!resume) {
        return;
      }
      Dart_SetPausedOnExit(false);
    }
  } else {
    // We are processing messages normally.
    error = LogIfError(Dart_HandleMessage());
  }

  if (error) {
    // Remember that we had an uncaught exception error.
    isolate_had_uncaught_exception_error_ = true;
  }

  if (error || !Dart_HasLivePorts()) {
    // The isolate has no live ports and would like to exit.
    if (Dart_ShouldPauseOnExit()) {
      // Mark that we are paused on exit.
      Dart_SetPausedOnExit(true);
    } else {
      isolate_exited_ = true;
    }
  }
}

void DartMessageHandler::MessageNotifyCallback(Dart_Isolate dest_isolate) {
  auto dart_state = DartState::From(dest_isolate);
  if (!dart_state) {
    // The callback data for an isolate can be null if the isolate is in the
    // middle of being shutdown.
    return;
  }
  dart_state->message_handler().OnMessage(dart_state);
}

}  // namespace blink
