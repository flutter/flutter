// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/mojo/dart_tracing.h"

#include <utility>

#include "base/json/json_reader.h"
#include "base/json/json_writer.h"
#include "dart/runtime/include/dart_tools_api.h"
#include "mojo/public/cpp/application/application_impl.h"

namespace dart {

void DartTimelineController::Enable(const mojo::String& categories) {
  if (categories == mojo::String("Dart")) {
    Dart_GlobalTimelineSetRecordedStreams(DART_TIMELINE_STREAM_DART);
  } else {
    // TODO(johnmccutchan): Respect |categories|.
    EnableAll();
  }
}

void DartTimelineController::EnableAll() {
  Dart_GlobalTimelineSetRecordedStreams(DART_TIMELINE_STREAM_ALL);
}

void DartTimelineController::Disable() {
  Dart_GlobalTimelineSetRecordedStreams(DART_TIMELINE_STREAM_DISABLE);
}

DartTraceProvider::DartTraceProvider()
    : binding_(this) {
}

DartTraceProvider::~DartTraceProvider() {
}

void DartTraceProvider::Bind(
    mojo::InterfaceRequest<tracing::TraceProvider> request) {
  if (!binding_.is_bound()) {
    binding_.Bind(request.Pass());
  } else {
    LOG(ERROR) << "Cannot accept two connections to TraceProvider.";
  }
}

// tracing::TraceProvider implementation:
void DartTraceProvider::StartTracing(
    const mojo::String& categories,
    mojo::InterfaceHandle<tracing::TraceRecorder> recorder) {
  DCHECK(!recorder_.get());
  recorder_ = tracing::TraceRecorderPtr::Create(std::move(recorder));
  DartTimelineController::Enable(categories);
}

static void AppendStreamConsumer(Dart_StreamConsumer_State state,
                                 const char* stream_name,
                                 const uint8_t* buffer,
                                 intptr_t buffer_length,
                                 void* user_data) {
  if (state == Dart_StreamConsumer_kFinish) {
    return;
  }
  std::vector<uint8_t>* data =
      reinterpret_cast<std::vector<uint8_t>*>(user_data);
  DCHECK(data);
  if (state == Dart_StreamConsumer_kStart) {
    data->clear();
    return;
  }
  DCHECK_EQ(state, Dart_StreamConsumer_kData);
  // Append data.
  data->insert(data->end(), buffer, buffer + buffer_length);
}

// recorder_->Record():
// 1. Doesn't like big hunks of data.
//    See: https://github.com/domokit/mojo/issues/564
// 2. Expects to receive one or more complete JSON maps per call.
// Therefore, we parse the recorded data, split it up and send it to trace
// recorder in chunks.
void DartTraceProvider::SplitAndRecord(char* data, size_t length) {
  const size_t kMinChunkLength = 1024 * 1024;  // 1MB.

  // The data from the VM is null-terminated content of a JSON array without its
  // enclosing square brackets. Remove the trailing "\0" and add the enclosing
  // brackets to make JSON parser happy.
  std::string json_data = "[" + std::string(data, length -1) + "]";
  base::JSONReader reader;
  scoped_ptr<base::Value> trace_data = reader.ReadToValue(json_data);
  if (!trace_data) {
    LOG(ERROR) << "Dart tracing failed to parse the JSON string: "
               << reader.GetErrorMessage();
    return;
  }

  base::ListValue* event_list;
  if (!trace_data->GetAsList(&event_list)) {
    LOG(ERROR) << "Dart tracing failed to parse the JSON string: data is not "
               << "a list.";
    return;
  }

  // Iterate over trace events and send over the traces to the recorder each
  // time we accumulate more than |kMinChunkLength| worth of data.
  std::string current_chunk;
  for (base::Value* val : *event_list) {
    base::DictionaryValue* event_dict;
    if (!val->GetAsDictionary(&event_dict)) {
      LOG(WARNING) << "Dart tracing ignoring incorrect trace event: "
                   << "not a dictionary";
      continue;
    }

    std::string event_json;
    if (!base::JSONWriter::Write(*event_dict, &event_json)) {
      LOG(WARNING) << "Dart tracing ignoring trace event: "
                   << "failed to serialize";
      continue;
    }

    if (!current_chunk.empty()) {
      current_chunk += ",";
    }
    current_chunk += event_json;

    if (current_chunk.size() >= kMinChunkLength) {
      mojo::String json(current_chunk.data(), current_chunk.size());
      recorder_->Record(json);
      current_chunk.clear();
    }
  }

  if (!current_chunk.empty()) {
    mojo::String json(current_chunk.data(), current_chunk.size());
    recorder_->Record(json);
  }
}

// tracing::TraceProvider implementation:
void DartTraceProvider::StopTracing() {
  DCHECK(recorder_);
  DartTimelineController::Disable();
  std::vector<uint8_t> data;
  bool got_trace = Dart_GlobalTimelineGetTrace(AppendStreamConsumer, &data);
  if (got_trace) {
    SplitAndRecord(reinterpret_cast<char*>(data.data()), data.size());
  }
  recorder_.reset();
}

DartTracingImpl::DartTracingImpl() {
}

DartTracingImpl::~DartTracingImpl() {
}

void DartTracingImpl::Initialize(mojo::ApplicationImpl* app) {
  auto connection = app->ConnectToApplication("mojo:tracing");
  connection->AddService(this);
}

void DartTracingImpl::Create(
    mojo::ApplicationConnection* connection,
    mojo::InterfaceRequest<tracing::TraceProvider> request) {
  provider_impl_.Bind(request.Pass());
}

}  // namespace dart
