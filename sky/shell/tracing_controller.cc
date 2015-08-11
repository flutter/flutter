// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/logging.h"
#include "base/macros.h"
#include "base/trace_event/trace_config.h"
#include "base/trace_event/trace_event.h"
#include "sky/shell/tracing_controller.h"
#include "sky/shell/shell.h"
#include <string>

namespace sky {
namespace shell {

const char kBaseTraceStart[] = "{\"traceEvents\":[";
const char kBaseTraceEnd[] = "]}";
const char kSentinel[] = "\0";

TracingController::TracingController() : view_(nullptr) {}

TracingController::~TracingController() {}

void TracingController::StartTracing() {
  DLOG(INFO) << "Collecting Traces";

  StartDartTracing();
  StartBaseTracing();
}

void TracingController::StopTracing(const base::FilePath& path) {
  DLOG(INFO) << "Stopping trace collection";

  trace_file_ = std::unique_ptr<base::File>(new base::File(
      path, base::File::FLAG_CREATE_ALWAYS | base::File::FLAG_WRITE));

  StopBaseTracing();
}

void TracingController::OnDataAvailable(const void* data, size_t size) {
  if (trace_file_ == nullptr) {
    return;
  }

  trace_file_->WriteAtCurrentPos(reinterpret_cast<const char*>(data), size);
}

void TracingController::OnDataComplete() {
  trace_file_ = nullptr;
  drainer_ = nullptr;
}

void TracingController::StartDartTracing() {
  if (view_ != nullptr) {
    view_->StartDartTracing();
  }
}

void TracingController::StopDartTracing() {
  mojo::DataPipe pipe;
  drainer_ = std::unique_ptr<mojo::common::DataPipeDrainer>(
      new mojo::common::DataPipeDrainer(this, pipe.consumer_handle.Pass()));
  if (view_ != nullptr) {
    view_->StopDartTracing(pipe.producer_handle.Pass());
  }
}

void TracingController::StartBaseTracing() {
  base::trace_event::TraceLog::GetInstance()->SetEnabled(
      base::trace_event::TraceConfig("*", base::trace_event::RECORD_UNTIL_FULL),
      base::trace_event::TraceLog::RECORDING_MODE);
}

void TracingController::StopBaseTracing() {
  base::trace_event::TraceLog* log = base::trace_event::TraceLog::GetInstance();
  log->SetDisabled();

  if (trace_file_ != nullptr) {
    trace_file_->WriteAtCurrentPos(kBaseTraceStart,
                                   sizeof(kBaseTraceStart) - 1);
  }
  log->Flush(base::Bind(&TracingController::OnBaseTraceChunk));
}

void TracingController::OnBaseTraceChunk(
    const scoped_refptr<base::RefCountedString>& chunk,
    bool has_more_events) {
  // Unfortunately, there does not seem to be a way to pass a user args
  // reference to the callback. So we make this static and use the |Shared()|
  // accessor
  TracingController& controller = Shell::Shared().tracing_controller();

  if (controller.trace_file_ != nullptr) {
    std::string& str = chunk->data();
    controller.trace_file_->WriteAtCurrentPos(str.data(), str.size());
    if (has_more_events) {
      controller.trace_file_->WriteAtCurrentPos(",", 1);
    } else {
      controller.trace_file_->WriteAtCurrentPos(kBaseTraceEnd,
                                                sizeof(kBaseTraceEnd) - 1);
      controller.trace_file_->WriteAtCurrentPos(kSentinel,
                                                sizeof(kSentinel) - 1);
    }
  }

  if (!has_more_events) {
    controller.StopDartTracing();
  }
}

void TracingController::RegisterShellView(ShellView* view) {
  view_ = view;
}

void TracingController::UnregisterShellView(ShellView* view) {
  view_ = nullptr;
}

}  // namespace shell
}  // namespace sky
