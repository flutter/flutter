// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/skia_event_tracer_impl.h"

#define TRACE_EVENT_HIDE_MACROS
#include <vector>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "third_party/dart/runtime/include/dart_tools_api.h"
#include "third_party/skia/include/utils/SkEventTracer.h"
#include "third_party/skia/include/utils/SkTraceEventPhase.h"

namespace flutter {

class FlutterEventTracer : public SkEventTracer {
 public:
  static constexpr const char* kSkiaTag = "skia";
  static constexpr uint8_t kYes = 1;
  static constexpr uint8_t kNo = 0;

  FlutterEventTracer(bool enabled) : enabled_(enabled ? kYes : kNo){};

  SkEventTracer::Handle addTraceEvent(char phase,
                                      const uint8_t* category_enabled_flag,
                                      const char* name,
                                      uint64_t id,
                                      int num_args,
                                      const char** p_arg_names,
                                      const uint8_t* p_arg_types,
                                      const uint64_t* p_arg_values,
                                      uint8_t flags) override {
#if defined(OS_FUCHSIA)
    // In a manner analogous to "fml/trace_event.h", use Fuchsia's system
    // tracing macros when running on Fuchsia.
    switch (phase) {
      case TRACE_EVENT_PHASE_BEGIN:
      case TRACE_EVENT_PHASE_COMPLETE:
        TRACE_DURATION_BEGIN(kSkiaTag, name);
        break;
      case TRACE_EVENT_PHASE_END:
        TRACE_DURATION_END(kSkiaTag, name);
        break;
      case TRACE_EVENT_PHASE_INSTANT:
        TRACE_INSTANT(kSkiaTag, name, TRACE_SCOPE_THREAD);
        break;
      case TRACE_EVENT_PHASE_ASYNC_BEGIN:
        TRACE_ASYNC_BEGIN(kSkiaTag, name, id);
        break;
      case TRACE_EVENT_PHASE_ASYNC_END:
        TRACE_ASYNC_END(kSkiaTag, name, id);
        break;
      default:
        break;
    }
#else   // defined(OS_FUCHSIA)
    switch (phase) {
      case TRACE_EVENT_PHASE_BEGIN:
      case TRACE_EVENT_PHASE_COMPLETE:
        fml::tracing::TraceEvent0(kSkiaTag, name);
        break;
      case TRACE_EVENT_PHASE_END:
        fml::tracing::TraceEventEnd(name);
        break;
      case TRACE_EVENT_PHASE_INSTANT:
        fml::tracing::TraceEventInstant0(kSkiaTag, name);
        break;
      case TRACE_EVENT_PHASE_ASYNC_BEGIN:
        fml::tracing::TraceEventAsyncBegin0(kSkiaTag, name, id);
        break;
      case TRACE_EVENT_PHASE_ASYNC_END:
        fml::tracing::TraceEventAsyncEnd0(kSkiaTag, name, id);
        break;
      default:
        break;
    }
#endif  // defined(OS_FUCHSIA)
    return 0;
  }

  void updateTraceEventDuration(const uint8_t* category_enabled_flag,
                                const char* name,
                                SkEventTracer::Handle handle) override {
    // This is only ever called from a scoped trace event so we will just end
    // the section.
#if defined(OS_FUCHSIA)
    TRACE_DURATION_END(kSkiaTag, name);
#else
    fml::tracing::TraceEventEnd(name);
#endif
  }

  const uint8_t* getCategoryGroupEnabled(const char* name) override {
    return &enabled_;
  }

  const char* getCategoryGroupName(
      const uint8_t* category_enabled_flag) override {
    return kSkiaTag;
  }

  void enable() { enabled_ = kYes; }

 private:
  uint8_t enabled_;
  FML_DISALLOW_COPY_AND_ASSIGN(FlutterEventTracer);
};

bool enableSkiaTracingCallback(const char* method,
                               const char** param_keys,
                               const char** param_values,
                               intptr_t num_params,
                               void* user_data,
                               const char** json_object) {
  FlutterEventTracer* tracer = static_cast<FlutterEventTracer*>(user_data);
  tracer->enable();
  *json_object = strdup("{\"type\":\"Success\"}");
  return true;
}

void InitSkiaEventTracer(bool enabled) {
  // TODO(chinmaygarde): Leaked https://github.com/flutter/flutter/issues/30808.
  auto tracer = new FlutterEventTracer(enabled);
  Dart_RegisterRootServiceRequestCallback("_flutter.enableSkiaTracing",
                                          enableSkiaTracingCallback,
                                          static_cast<void*>(tracer));
  // Initialize the binding to Skia's tracing events. Skia will
  // take ownership of and clean up the memory allocated here.
  SkEventTracer::SetInstance(tracer);
}

}  // namespace flutter
