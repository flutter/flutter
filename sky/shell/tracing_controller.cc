// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/tracing_controller.h"

#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/macros.h"
#include "base/trace_event/trace_config.h"
#include "base/trace_event/trace_event.h"
#include "dart/runtime/include/dart_tools_api.h"
#include "sky/shell/shell.h"

#include <string>
#include <sstream>

namespace sky {
namespace shell {

const char kBaseTraceStart[] = "{\"traceEvents\":[";
const char kBaseTraceEnd[] = "]}";

const char kObservatoryMethodStartTracing[] = "ext.flutter_startTracing";
const char kObservatoryMethodStopTracing[] = "ext.flutter_stopTracing";
const char kObservatoryMethodDownloadTraceData[] = "ext.flutter_downloadTraceData";
const char kTraceFilePathParamName[] = "trace_file_path";
const char kObservatoryResultOk[] = "{\"success\" : true}";
const char kObservatoryResultFail[] = "{\"success\" : false}";
const char kTraceDataNotReady[] = "{\"status\" : \"not ready\"}";

static const char* ObservatoryInvoke(const char* method,
                                     const char** param_keys,
                                     const char** param_values,
                                     intptr_t num_params,
                                     void* user_data) {
  if (user_data == nullptr) {
    // During the destruction of the tracing controller, the user data is
    // cleared. Make sure that observatory requests to service calls are not
    // attempted after tracing controller destruction.
    return strdup(kObservatoryResultFail);
  }

  auto tracing_controller = reinterpret_cast<TracingController*>(user_data);

  if (strncmp(method, kObservatoryMethodStartTracing,
              sizeof(kObservatoryMethodStartTracing)) == 0) {
    if (!tracing_controller->tracing_active()) {
      tracing_controller->StartTracing();
      return strdup(kObservatoryResultOk);
    }
  }

  if (strncmp(method, kObservatoryMethodStopTracing,
              sizeof(kObservatoryMethodStopTracing)) == 0) {
    if (tracing_controller->tracing_active()) {
      base::FilePath temp_dir;
      bool temp_access = base::GetTempDir(&temp_dir);
      DCHECK(temp_access) << "Must be able to access the temp directory";

      base::FilePath path =
          tracing_controller->TracePathForCurrentTime(temp_dir);

      tracing_controller->StopTracing(path);

      // Calling path.AsUTF8Unsafe() should be safe as we're in charge of
      // generating the file name.
      std::stringstream result;
      result << "{\"" << kTraceFilePathParamName << "\": \""
             << path.AsUTF8Unsafe() << "\"}";
      return strdup(result.str().c_str());
    }
  }

  if (strncmp(method, kObservatoryMethodDownloadTraceData,
              sizeof(kObservatoryMethodDownloadTraceData)) == 0) {
    if (tracing_controller->tracing_active()) {
      return strdup(kTraceDataNotReady);
    }

    for (int i = 0; i < num_params; i++) {
      if (strncmp(param_keys[i], kTraceFilePathParamName, sizeof(kTraceFilePathParamName)) == 0) {
        base::FilePath path(param_values[i]);
        base::File file(
            path, base::File::Flags::FLAG_OPEN | base::File::Flags::FLAG_READ);
        int64 length = file.GetLength();

        if (length == 0) {
          LOG(ERROR) << "Tracing file is empty: " << param_values[i];
          return strdup(kObservatoryResultFail);
        }

        char* data = reinterpret_cast<char*>(malloc(length + 1));
        int length_read = file.Read(0, data, length);

        DCHECK(length == length_read);

        data[length] = '\0';
        base::DeleteFile(path, false);

        LOG(INFO) << "Downloading " << length << " bytes of tracing data";
        return data;
      }
    }

    LOG(ERROR) << "Parameter " << kTraceFilePathParamName << " not found";
    return strdup(kObservatoryResultFail);
  }

  return strdup(kObservatoryResultFail);
}

TracingController::TracingController()
    : picture_tracing_enabled_(false),
      dart_initialized_(false),
      tracing_active_(false),
      weak_factory_(this) {
  ManageObservatoryCallbacks(true);
}

TracingController::~TracingController() {
  ManageObservatoryCallbacks(false);
}

void TracingController::SetDartInitialized() {
  DCHECK(!dart_initialized_);
  dart_initialized_ = true;

  // In case early lifecycle is being traced, base tracing has already begun
  // but we have just been notified of initialization of the Dart VM. Start
  // collecting traces in Dart.
  if (tracing_active_) {
    StartDartTracing();
  }
}

void TracingController::ManageObservatoryCallbacks(bool add) {
  void* baton = add ? this : nullptr;
  Dart_RegisterRootServiceRequestCallback(kObservatoryMethodStartTracing,
                                          &ObservatoryInvoke, baton);
  Dart_RegisterRootServiceRequestCallback(kObservatoryMethodStopTracing,
                                          &ObservatoryInvoke, baton);
  Dart_RegisterRootServiceRequestCallback(kObservatoryMethodDownloadTraceData,
                                          &ObservatoryInvoke, baton);
}

void TracingController::StartTracing() {
  DCHECK(!tracing_active_);

  LOG(INFO) << "Starting trace";

  tracing_active_ = true;

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

void TracingController::StartDartTracing() {
  if (!dart_initialized_) {
    return;
  }

  Dart_GlobalTimelineSetRecordedStreams(~0);
}

static void TracingController_DartStreamConsumer(
    Dart_StreamConsumer_State state,
    const char* stream_name,
    uint8_t* buffer,
    intptr_t buffer_length,
    base::File* traceFile) {
  if (state == Dart_StreamConsumer_kData) {
    // Trim trailing null characters.
    if (buffer[buffer_length - 1] == 0)
      --buffer_length;
    if (buffer_length) {
      if (traceFile != nullptr) {
        traceFile->WriteAtCurrentPos(reinterpret_cast<char*>(buffer),
                                     buffer_length);
      }
    }
  }
}

void TracingController::StopDartTracing() {
  if (!dart_initialized_) {
    // This is checking for the highly unlikely case where the user starts and
    // stops tracing before the dart VM is initialized.
    FinalizeTraceFile();
    return;
  }

  if (trace_file_){
    trace_file_->WriteAtCurrentPos(",", 1);
  }

  Dart_GlobalTimelineSetRecordedStreams(DART_TIMELINE_STREAM_DISABLE);

  auto callback = reinterpret_cast<Dart_StreamConsumer>(
      &TracingController_DartStreamConsumer);
  Dart_GlobalTimelineGetTrace(callback, trace_file_.get());

  FinalizeTraceFile();
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

  log->Flush(base::Bind(&TracingController::OnBaseTraceChunk,
                        weak_factory_.GetWeakPtr()));
}

void TracingController::FinalizeTraceFile() {
  if (trace_file_) {
    trace_file_->WriteAtCurrentPos(kBaseTraceEnd, sizeof(kBaseTraceEnd) - 1);
    trace_file_ = nullptr;
  }

  tracing_active_ = false;

  LOG(INFO) << "Trace complete";
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

  if (!has_more_events) {
    StopDartTracing();
  }
}

base::FilePath TracingController::TracePathWithExtension(
    base::FilePath dir,
    std::string extension) const {
  base::Time::Exploded exploded;
  base::Time now = base::Time::Now();

  now.LocalExplode(&exploded);

  std::stringstream stream;
  // Example: trace_2015-10-08_at_11.38.25.121_.extension
  stream << "trace_" << exploded.year << "-" << exploded.month << "-"
         << exploded.day_of_month << "_at_" << exploded.hour << "."
         << exploded.minute << "." << exploded.second << "."
         << exploded.millisecond << "." << extension;
  return dir.Append(stream.str());
}

base::FilePath TracingController::PictureTracingPathForCurrentTime() const {
  return PictureTracingPathForCurrentTime(traces_base_path_);
}

base::FilePath TracingController::PictureTracingPathForCurrentTime(
    base::FilePath dir) const {
  return TracePathWithExtension(dir, "skp");
}

base::FilePath TracingController::TracePathForCurrentTime(
    base::FilePath dir) const {
  return TracePathWithExtension(dir, "json");
}

}  // namespace shell
}  // namespace sky
