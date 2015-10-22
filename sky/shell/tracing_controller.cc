// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/macros.h"
#include "base/trace_event/trace_config.h"
#include "base/trace_event/trace_event.h"
#include "sky/shell/shell.h"
#include "sky/shell/tracing_controller.h"

#include <string>
#include <sstream>

namespace sky {
namespace shell {

const char kBaseTraceStart[] = "{\"traceEvents\":[";
const char kBaseTraceEnd[] = "]}";

TracingController::TracingController()
    : view_(nullptr), picture_tracing_enabled_(false), weak_factory_(this) {
}

TracingController::~TracingController() {
}

void TracingController::StartTracing() {
  LOG(INFO) << "Starting trace";

  StartDartTracing();
  StartBaseTracing();
}

void TracingController::StopTracing(const base::FilePath& path) {
  LOG(INFO) << "Saving trace to " << path.LossyDisplayName();

  trace_file_ = std::unique_ptr<base::File>(new base::File(
      path, base::File::FLAG_CREATE_ALWAYS | base::File::FLAG_WRITE));
  base::SetPosixFilePermissions(path, base::FILE_PERMISSION_MASK);
  StopBaseTracing();
}

void TracingController::OnDataAvailable(const void* data, size_t size) {
  if (trace_file_)
    trace_file_->WriteAtCurrentPos(reinterpret_cast<const char*>(data), size);
}

void TracingController::OnDataComplete() {
  drainer_ = nullptr;
  FinalizeTraceFile();
  LOG(INFO) << "Trace complete";
}

void TracingController::StartDartTracing() {
  if (view_)
    view_->StartDartTracing();
}

void TracingController::StopDartTracing() {
  if (view_) {
    if (trace_file_)
      trace_file_->WriteAtCurrentPos(",", 1);

    mojo::DataPipe pipe;
    drainer_ = std::unique_ptr<mojo::common::DataPipeDrainer>(
        new mojo::common::DataPipeDrainer(this, pipe.consumer_handle.Pass()));
    view_->StopDartTracing(pipe.producer_handle.Pass());
  } else {
    FinalizeTraceFile();
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

  if (trace_file_) {
    trace_file_->WriteAtCurrentPos(kBaseTraceStart,
                                   sizeof(kBaseTraceStart) - 1);
  }
  log->Flush(base::Bind(
      &TracingController::OnBaseTraceChunk, weak_factory_.GetWeakPtr()));
}

void TracingController::FinalizeTraceFile() {
  if (trace_file_) {
    trace_file_->WriteAtCurrentPos(kBaseTraceEnd, sizeof(kBaseTraceEnd) - 1);
    trace_file_ = nullptr;
  }
}

void TracingController::OnBaseTraceChunk(
    const scoped_refptr<base::RefCountedString>& chunk,
    bool has_more_events) {
  if (trace_file_) {
    std::string& str = chunk->data();
    trace_file_->WriteAtCurrentPos(str.data(), str.size());
    if (has_more_events)
      trace_file_->WriteAtCurrentPos(",", 1);
  }

  if (!has_more_events)
    StopDartTracing();
}

void TracingController::RegisterShellView(ShellView* view) {
  view_ = view;
}

void TracingController::UnregisterShellView(ShellView* view) {
  view_ = nullptr;
}

base::FilePath TracingController::PictureTracingPathForCurrentTime() const {
  base::Time::Exploded exploded;
  base::Time now = base::Time::Now();

  now.LocalExplode(&exploded);

  std::stringstream stream;
  // Example: trace_2015-10-08_at_11.38.25.121_.skp
  stream << "trace_" << exploded.year << "-" << exploded.month << "-"
         << exploded.day_of_month << "_at_" << exploded.hour << "."
         << exploded.minute << "." << exploded.second << "."
         << exploded.millisecond << ".skp";
  return picture_tracing_base_path_.Append(stream.str());
}

}  // namespace shell
}  // namespace sky
