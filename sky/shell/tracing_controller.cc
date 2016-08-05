// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/tracing_controller.h"

#include "base/threading/platform_thread.h"
#include "base/trace_event/trace_event.h"
#include "dart/runtime/include/dart_tools_api.h"
#include "sky/engine/core/script/dart_init.h"
#include "sky/engine/wtf/MakeUnique.h"
#include "sky/shell/shell.h"

#include <string>

namespace sky {
namespace shell {

TracingController::TracingController()
    : picture_tracing_enabled_(false), tracing_active_(false) {
  auto start = [this]() { StartTracing(); };
  auto stop = [this]() { StopTracing(); };

  blink::SetEmbedderTracingCallbacks(
      WTF::MakeUnique<blink::EmbedderTracingCallbacks>(start, stop));
}

TracingController::~TracingController() {
  blink::SetEmbedderTracingCallbacks(nullptr);
}

static const char* WARN_UNUSED_RESULT
ConstructDartTimelineValue(std::vector<void*>& free_list,
                           const char* format,
                           ...) {
  static const char* kConversionError = "Argument Conversion Error";
  const char* return_value = nullptr;

  va_list args;
  va_start(args, format);
  char* string;
  if (vasprintf(&string, format, args) != -1) {
    return_value = string;
    free_list.push_back(string);
  } else {
    return_value = kConversionError;
  }
  va_end(args);

  return return_value;
}

static void BaseTraceEventCallback(base::TraceTicks timestamp,
                                   char phase,
                                   const unsigned char* category_group_enabled,
                                   const char* name,
                                   unsigned long long id,
                                   int num_args,
                                   const char* const arg_names[],
                                   const unsigned char arg_types[],
                                   const unsigned long long arg_values[],
                                   unsigned int flags) {
  Dart_Timeline_Event_Type type = Dart_Timeline_Event_Begin;

  switch (phase) {
    case TRACE_EVENT_PHASE_BEGIN:
      type = Dart_Timeline_Event_Begin;
      break;
    case TRACE_EVENT_PHASE_END:
      type = Dart_Timeline_Event_End;
      break;
    case TRACE_EVENT_PHASE_INSTANT:
      type = Dart_Timeline_Event_Instant;
      break;
    case TRACE_EVENT_PHASE_ASYNC_BEGIN:
      type = Dart_Timeline_Event_Async_Begin;
      break;
    case TRACE_EVENT_PHASE_ASYNC_END:
      type = Dart_Timeline_Event_Async_End;
      break;
    case TRACE_EVENT_PHASE_COUNTER:
      type = Dart_Timeline_Event_Counter;
      break;
    default:
      // For TRACE_EVENT_PHASE_COMPLETE events, this callback still receives
      // discrete begin-end pairs. This greatly simplifies things. We dont have
      // to track the second timestamp to pass to the Dart timeline event
      // because we never see a Dart_Timeline_Event_Duration event.
      DCHECK(false) << "Unknown trace event phase";
      return;
  }

  // Try to convert all arguments to strings to pass to the Dart timeline.

  char const* dart_argument_values[num_args];

  std::vector<void*> free_list;

#define CONVERT_VAL(format) \
  dart_argument_values[i] = \
      ConstructDartTimelineValue(free_list, format, arg_values[i])

  for (int i = 0; i < num_args; i++) {
    switch (arg_types[i]) {
      case TRACE_VALUE_TYPE_BOOL:
        CONVERT_VAL("%d");
        break;
      case TRACE_VALUE_TYPE_UINT:
        CONVERT_VAL("%u");
        break;
      case TRACE_VALUE_TYPE_INT:
        CONVERT_VAL("%d");
        break;
      case TRACE_VALUE_TYPE_DOUBLE:
        CONVERT_VAL("%f");
        break;
      case TRACE_VALUE_TYPE_POINTER:
        CONVERT_VAL("%p");
        break;
      case TRACE_VALUE_TYPE_STRING:
      case TRACE_VALUE_TYPE_COPY_STRING:
        // We don't need to reallocate for strings since the string will be
        // used within this scope.
        dart_argument_values[i] = reinterpret_cast<char*>(arg_values[i]);
        break;
      default:
        continue;
    }
  }

#undef CONVERT_VAL

  Dart_TimelineEvent(name,                         // label
                     timestamp.ToInternalValue(),  // timestamp0
                     0,                            // timestamp1_or_async_id
                     type,                         // event type
                     num_args,                     // argument_count
                     (const char**)(arg_names),    // argument_names
                     (const char**)(dart_argument_values)  // argument_values
                     );

  // Free up the items that had to be heap allocated (if any)
  for (void* item : free_list) {
    free(item);
  }
}

static void TraceThreadMetadataToObservatory() {
  const char* name = base::PlatformThread::GetName();
  if (name == nullptr) {
    return;
  }
  Dart_SetThreadName(name);
}

static void AddTraceMetadata() {
  Shell::Shared().gpu_task_runner()->PostTask(
      FROM_HERE, base::Bind(&TraceThreadMetadataToObservatory));
  Shell::Shared().ui_task_runner()->PostTask(
      FROM_HERE, base::Bind(&TraceThreadMetadataToObservatory));
  Shell::Shared().io_task_runner()->PostTask(
      FROM_HERE, base::Bind(&TraceThreadMetadataToObservatory));
}

void TracingController::StartTracing() {
  if (tracing_active_) {
    return;
  }

  tracing_active_ = true;

  StartBaseTracing();

  AddTraceMetadata();
}

void TracingController::StartBaseTracing() {
  namespace TE = base::trace_event;
  auto config =
      TE::TraceConfig("*,disabled-by-default-skia", TE::RECORD_CONTINUOUSLY);

  auto log = TE::TraceLog::GetInstance();

  log->SetEnabled(config, TE::TraceLog::MONITORING_MODE);
  log->SetEventCallbackEnabled(config, &BaseTraceEventCallback);
}

void TracingController::StopTracing() {
  if (!tracing_active_) {
    return;
  }

  tracing_active_ = false;

  StopBaseTracing();
}

void TracingController::StopBaseTracing() {
  auto log = base::trace_event::TraceLog::GetInstance();

  log->SetDisabled();
  log->SetEventCallbackDisabled();
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

}  // namespace shell
}  // namespace sky
