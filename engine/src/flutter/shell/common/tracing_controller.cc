// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/tracing_controller.h"

#include <string>

#include "dart/runtime/include/dart_tools_api.h"
#include "flutter/common/threads.h"
#include "flutter/fml/trace_event.h"
#include "flutter/runtime/dart_init.h"
#include "flutter/shell/common/shell.h"
#include "lib/fxl/logging.h"

namespace shell {

TracingController::TracingController() : tracing_active_(false) {
  blink::SetEmbedderTracingCallbacks(
      std::unique_ptr<blink::EmbedderTracingCallbacks>(
          new blink::EmbedderTracingCallbacks([this]() { StartTracing(); },
                                              [this]() { StopTracing(); })));
}

TracingController::~TracingController() {
  blink::SetEmbedderTracingCallbacks(nullptr);
}

static void AddTraceMetadata() {
  blink::Threads::Gpu()->PostTask([]() { Dart_SetThreadName("gpu_thread"); });
  blink::Threads::UI()->PostTask([]() { Dart_SetThreadName("ui_thread"); });
  blink::Threads::IO()->PostTask([]() { Dart_SetThreadName("io_thread"); });
  blink::Threads::Platform()->PostTask(
      []() { Dart_SetThreadName("platform_thread"); });
}

void TracingController::StartTracing() {
  if (tracing_active_)
    return;
  tracing_active_ = true;
  AddTraceMetadata();
}

void TracingController::StopTracing() {
  if (!tracing_active_) {
    return;
  }
  tracing_active_ = false;
}

}  // namespace shell
