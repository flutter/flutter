// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/shell/tracing_controller.h"

#include "base/trace_event/trace_event.h"
#include "dart/runtime/include/dart_tools_api.h"
#include "flutter/common/threads.h"
#include "flutter/sky/engine/core/script/dart_init.h"
#include "flutter/sky/engine/wtf/MakeUnique.h"
#include "flutter/sky/shell/shell.h"
#include "lib/ftl/logging.h"

#include <string>

namespace sky {
namespace shell {

TracingController::TracingController()
    : picture_tracing_enabled_(false), tracing_active_(false) {
  blink::SetEmbedderTracingCallbacks(
      WTF::MakeUnique<blink::EmbedderTracingCallbacks>(
          [this]() { StartTracing(); }, [this]() { StopTracing(); }));
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
      FTL_DCHECK(false) << "Unknown trace event phase";
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

static void AddTraceMetadata() {
  blink::Threads::Gpu()->PostTask([]() { Dart_SetThreadName("gpu_thread"); });
  blink::Threads::UI()->PostTask([]() { Dart_SetThreadName("ui_thread"); });
  blink::Threads::IO()->PostTask([]() { Dart_SetThreadName("io_thread"); });
}

void TracingController::StartTracing() {
  if (tracing_active_)
    return;
  tracing_active_ = true;
  StartBaseTracing();
  AddTraceMetadata();
}

void TracingController::StartBaseTracing() {
  auto config = base::trace_event::TraceConfig(
      "*,disabled-by-default-skia", base::trace_event::RECORD_CONTINUOUSLY);

  auto log = base::trace_event::TraceLog::GetInstance();

  log->SetEnabled(config, base::trace_event::TraceLog::MONITORING_MODE);
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
  auto trace_log = base::trace_event::TraceLog::GetInstance();
  trace_log->SetDisabled();
  trace_log->SetEventCallbackDisabled();
}

std::string TracingController::TracePathWithExtension(
    const std::string& directory,
    const std::string& extension) const {
  base::Time::Exploded exploded;
  base::Time now = base::Time::Now();

  now.LocalExplode(&exploded);

  std::stringstream stream;
  // Example: trace_2015-10-08_at_11.38.25.121_.extension
  stream << directory << "/trace_" << exploded.year << "-" << exploded.month
         << "-" << exploded.day_of_month << "_at_" << exploded.hour << "."
         << exploded.minute << "." << exploded.second << "."
         << exploded.millisecond << "." << extension;
  return stream.str();
}

std::string TracingController::PictureTracingPathForCurrentTime() const {
  return PictureTracingPathForCurrentTime(traces_base_path_);
}

std::string TracingController::PictureTracingPathForCurrentTime(
    const std::string& directory) const {
  return TracePathWithExtension(directory, "skp");
}

}  // namespace shell
}  // namespace sky
